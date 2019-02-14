﻿#include "spi_brige_common.h"
#include "spi_brige_manager.h"

#include <unistd.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <linux/types.h>
#include <poll.h>

#define SPI_FILE "/dev/spidev0.0"  // <Bus>.<CS>

static SPIBrigeManager* root;

namespace spi_integrator {
    SPIDevInterface* SPIDevInterface::all_spi_interfaces[TOTAL_SPI_DEVICES];

    void SPIDevInterface::send_data(uint32_t data)
    {
        if (root) root->on_data_arrived(data, self_device_id);
    }
}


SPIBrigeManager::SPIBrigeManager() : spi_exchange(SPI_QUEUE_SIZE), spi_exchange_int(SPI_INT_QUEUE_SIZE)
{
    int idx=1;
    memset(channel_encoder, 0, sizeof(channel_encoder));
    for(auto& def: latencies) channel_encoder[def.dev] = idx++;
    status_register = -1;
    gpio_handle = spi_handle = gpio_data_valid = gpio_almost_full = gpio_get_sizes = gpio_radio_int = -1;
    prev_gpio_get_sizes = 0;
    hw_activate();
    overflow_thread = std::thread([this] {this->overflow_thread_handle();});
    spi_integrator::SPIDevInterface::init_all();
    root = this;
}


enum TegraPorts {
    PortA, PortB, PortC, PortD, PortE, PortF, PortG, PortH, 
    PortI, PortJ, PortK, PortL, PortM, PortN, PortO, PortP, 
    PortQ, PortR, PortT, PortX, PortY, PortBB, PortCC, PortDD
};

inline constexpr int port_to_index(TegraPorts port, int index) {return 320 + port*8 + index;}

enum {
 GPIO_DATA_VALID = port_to_index(PortX, 3),   // IO8
 GPIO_ALMOST_FULL = port_to_index(PortX, 2),  // IO9
 GPIO_GET_SIZES = port_to_index(PortE, 4),    // IO11
 GPIO_RADIO_INT = port_to_index(PortX, 0)   // IO16
};

constexpr int max_spi_freq = 20 * 1000 * 1000;  // 20 MHz

#define CHK(code) ({auto err = (code); if (err<0) throw std::exception("SPI Error: " #code); err})
#define IOCTL(id, val) CHK(mode=val, ::ioctl(spi_handle, id, &mode))

void SPIBrigeManager::hw_activate()
{
    root = NULL;
    int mode;
    spi_handle = CHK(::open(SPI_FILE, O_RDWR));
    IOCTL(SPI_IOC_WR_MODE, 0);
    IOCTL(SPI_IOC_WR_LSB_FIRST, 0);
    IOCTL(SPI_IOC_WR_BITS_PER_WORD, 32);
    IOCTL(SPI_IOC_WR_MAX_SPEED_HZ, max_spi_freq);

    memset(&xref, 0, sizeof(xref));
	xref.speed_hz = max_spi_freq;
	xref.bits_per_word = 32;

    spi_xfer_int = xref;
    xref.rx_buf = (uint64_t)spi_exchange.data();
    spi_xfer_int.rx_buf  = (uint64_t)spi_exchange_int.data();
    spi_xfer_int.len = SPI_INT_QUEUE_SIZE;

    gpio_data_valid  = open_gpio(GPIO_DATA_VALID, "in");
    gpio_almost_full = open_gpio(GPIO_ALMOST_FULL, "in", "rising");
    gpio_get_sizes   = open_gpio(GPIO_GET_SIZES, "low");
    gpio_radio_int   = open_gpio(GPIO_RADIO_INT, "in", "rising");
}


int SPIBrigeManager::open_gpio(int pin_idx, const char* setup, const char* int_edge)
{
    auto base_path = "/sys/class/gpio/gpio" + std::to_string(pin_idx);

    struct stat st;

    // Check if /sys/class/gpio/gpio<pin_idx>/ exists 
    if (stat(base_path.c_str(), &st) != -1)
    {
        CHK(st.st_mode & S_IFDIR ? 0:-1);
    }
    else
    {
        //  if not - write "<pin_idx>" to /sys/class/gpio/export, recheck
        std::ofstream stream("/sys/class/gpio/export");
        stream.exceptions(std::ofstream::failbit);
        stream << pin_idx;
        CHK(stat(base_path.c_str(), &st));
    }

    base_path += "/";

    auto write = [&] (char* dst, char* cmd) {
        std::ofstream stream((base_path + dst).c_str());
        stream.exceptions(std::ofstream::failbit);
        stream << cmd;
    };

    // write <setup> to /sys/class/gpio/gpio<pin_idx>/direction
    write("direction", setup);

    // write <edge> (if not NULL) to /sys/class/gpio/gpio<pin_idx>/edge
    if (edge) write("edge", edge);

    // open /sys/class/gpio/gpio<pin_idx>/value and return handle
    return CHK(::open((base_path + "value").c_str(), O_RDWR));
}

void SPIBrigeManager::hw_deactivate()
{
    auto close = [](int& handle) {if (handle!=-1) {::close(handle); handle=-1;}};
    close(spi_handle);
    close(gpio_data_valid);
    close(gpio_almost_full);
    close(gpio_get_sizes);
    close(gpio_radio_int);
    // ??? Signal via FD to all running threads (overflow and radio int) if closing 'value' fd is not enough
    overflow_thread.join();
}


void SPIBrigeManager::low_level_spi_exchange(int size, bool do_send)
{
    flip_get_size();
    xref.len = size;
    xref.tx_buf = do_send ? (uint64_t)spi_exchange.data() : 0;
    CHK(ioctl(spi_handle, SPI_IOC_MESSAGE(1), &xfer));
}

void SPIBrigeManager::low_level_spi_exchange_int()
{
    flip_get_size();
    CHK(ioctl(spi_handle, SPI_IOC_MESSAGE(1), &xfer_int));
}


static int read1(int fd)
{
    uint8_t result;
    ::lseek(fd, 0, SEEK_SET);
    if (::read(fd, &result, 1) <= 0) return -1;
    return result;
}

static void write1(int fd, uint8_t value)
{
    ::write(fd, &value, 1);
}

void SPIBrigeManager::flip_get_size()
{
    prev_gpio_get_sizes ^= 1;
    write1(gpio_get_sizes, prev_gpio_get_sizes);
}

void SPIBrigeManager::overflow_thread_handle()
{
    pollfd pfd;
    pfd.fd = gpio_almost_full;
    pfd.events = POLLPRI|POLLERR|POLLIN;
    for(;;)
    {
        pfd.revents = 0;
        if (::poll(&pfd, 1, -1) <= 0) return;
        if (pfd.revents & POLLERR) return;
        switch(read1(gpio_almost_full))
        {
            case 0: continue;
            case 1: break;
            default: return;
        }
        std::unique_lock<std::mutex> lock(overflow_queue_guard, std::try_to_lock);
        if (!lock) continue;
        low_level_spi_exchange_int();
        from_spi_data.insert(from_spi_data.back(), spi_exchange_int.begin(), spi_exchange_int.end());
    }

}

void SPIBrigeManager::on_data_arrived(uint32_t data, uint32 channel)
{
    uint32_t data_and_channel = (data&0x0FFFFFFF) | (channel << 28);
    to_spi_data[channel_encoder[channel]].push_back(data_and_channel);
}

bool SPIBrigeManager::spi_exchange_loop(bool first_entry)
{
    int idx = 1;
    int start = 0;
    int max = 0;

    memset(spi_exchange.data(), 0, sizeof(uint32_t)*SPI_QUEUE_SIZE);

    for(auto& ref: latencies)
    {
        auto& queue = to_spi_data[idx++];
        int base = start++;
        if (base>=spi_exchange.size()) break;
        while(!queue.empty())
        {
            while(base<SPI_QUEUE_SIZE && spi_exchange[base]) ++base;
            if (base>=SPI_QUEUE_SIZE) break;
            spi_exchange[base] = queue.front(); queue.pop_front();
            if (base>max) max=base;
            base += ref.letency;
        }
    }

    while(!to_spi_data[0].empty())
    {
        while(start<SPI_QUEUE_SIZE && spi_exchange[start]) ++start;
        if (start>=SPI_QUEUE_SIZE) break;
        if (start>max) max=start;
        spi_exchange[start++] = to_spi_data[0].front(); to_spi_data[0].pop_front();
    }

    if (!start && !first_entry) return false;
    low_level_spi_exchange(++max, true);

    int new_status_register = status_register;

    enum {
        Valid   = 0x01000000,
        Empty   = 0x02000000,
        SizeReq = 0x04000000,
        Shadow  = 0x08000000
    };

    for(;;)
    {
        int counter_value = 0;
        int counter_index = -1;
        for(idx = 0; idx < max; ++idx)
        {
            uint32_t value = spi_exchange[idx];
            int channel = value >> 28;
            if (channel) spi_integrator::SPIDevInterface::dispatch_input_data(value); else
            {
                if (value & SizeReq) {counter_value = (value >> 11) & 0x1FFF; counter_index = idx + 1;} else
                if (value & Valid) new_status_register = value;
            }
        }

        if (counter_index == -1) break;
        int total_read = counter_value - max + counter_index;
        if (total_read <= 0)
        {
            if (new_status_register & Empty) break;
            total_read = 1024 - 16;
        }
        max = total_read + 16;
        low_level_spi_exchange(max, false);
    }

    if (new_status_register != -1) new_status_register &= 0x00FFFFFF;
    if (new_status_register != status_register) 
        spi_integrator::SPIDevInterface::dispatch_input_data(status_register);

    return start != 0;
}