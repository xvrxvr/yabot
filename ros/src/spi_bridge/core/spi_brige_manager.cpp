#include "spi_brige_common.h"
#include "spi_brige_manager.h"

#include <unistd.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <linux/types.h>
#include <poll.h>

#define SPI_FILE "/dev/spidev0.0"  // <Bus>.<CS>

struct LatencyDef {
    spi_integrator::SpiDevices dev;
    int latency;
};

constexpr static LatencyDef latencies[]={
    {spi_integrator::SD_ADC, 3}, 
    {spi_integrator::SD_Radio, 3}
};

static SPIBrigeManager* root;

namespace spi_integrator {
    SPIDevInterface* SPIDevInterface::all_spi_interfaces[TOTAL_SPI_DEVICES];

    void SPIDevInterface::send_data(uint32_t data)
    {
        if (root) root->on_data_arrived(data, self_device_id);
    }
}

SPIBrigeManager::SPIBrigeManager() : spi_exchange_buffer(SPI_QUEUE_SIZE), spi_exchange_int_buffer(SPI_INT_QUEUE_SIZE)
{
    memset(channel_latency, 0, sizeof(channel_latency));
    for(auto& def: latencies) channel_latency[def.dev] = def.latency;
    status_register = -1;
    spi_handle = gpio_data_valid = gpio_almost_full = gpio_get_sizes = gpio_radio_int = -1;
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

class HWException: public std::exception {
    const char* msg;
public:
    HWException(const char* m) : msg(m) {}

    virtual const char* what() const noexcept {return msg;}
};

#define CHK(code) ({auto err = (code); if (err<0) throw HWException("SPI Error: " #code); err;})
#define IOCTL(id, val) CHK((mode=val, ::ioctl(spi_handle, id, &mode)))

void SPIBrigeManager::hw_activate()
{
    root = NULL;
    int mode;
    spi_handle = CHK(::open(SPI_FILE, O_RDWR));
    IOCTL(SPI_IOC_WR_MODE, 0);
    IOCTL(SPI_IOC_WR_LSB_FIRST, 0);
    IOCTL(SPI_IOC_WR_BITS_PER_WORD, 32);
    IOCTL(SPI_IOC_WR_MAX_SPEED_HZ, max_spi_freq);

    memset(&spi_xfer, 0, sizeof(spi_xfer));
	spi_xfer.speed_hz = max_spi_freq;
	spi_xfer.bits_per_word = 32;

    spi_xfer_int = spi_xfer;
    spi_xfer.rx_buf = (uint64_t)spi_exchange_buffer.data();
    spi_xfer_int.rx_buf  = (uint64_t)spi_exchange_int_buffer.data();
    spi_xfer_int.len = SPI_INT_QUEUE_SIZE;

    gpio_data_valid  = open_gpio(GPIO_DATA_VALID, "in");
    gpio_almost_full = open_gpio(GPIO_ALMOST_FULL, "in", "rising");
    gpio_get_sizes   = open_gpio(GPIO_GET_SIZES, "low");
    gpio_radio_int   = open_gpio(GPIO_RADIO_INT, "in", "rising");
}


int SPIBrigeManager::open_gpio(int pin_idx, const char* setup, const char* int_edge)
{
    auto base_path = "/sys/class/gpio/gpio" + std::to_string(pin_idx);

    struct ::stat st;

    // Check if /sys/class/gpio/gpio<pin_idx>/ exists 
    if (::stat(base_path.c_str(), &st) != -1)
    {
        CHK(st.st_mode & S_IFDIR ? 0:-1);
    }
    else
    {
        //  if not - write "<pin_idx>" to /sys/class/gpio/export, recheck
        std::ofstream stream("/sys/class/gpio/export");
        stream.exceptions(std::ofstream::failbit);
        stream << pin_idx;
        CHK(::stat(base_path.c_str(), &st));
    }

    base_path += "/";

    auto write = [&] (const char* dst, const char* cmd) {
        std::ofstream stream((base_path + dst).c_str());
        stream.exceptions(std::ofstream::failbit);
        stream << cmd;
    };

    // write <setup> to /sys/class/gpio/gpio<pin_idx>/direction
    write("direction", setup);

    // write <edge> (if not NULL) to /sys/class/gpio/gpio<pin_idx>/edge
    if (int_edge) write("edge", int_edge);

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
    spi_xfer.len = size;
    spi_xfer.tx_buf = do_send ? (uint64_t)spi_exchange_buffer.data() : 0;
    CHK(ioctl(spi_handle, SPI_IOC_MESSAGE(1), &spi_xfer));
}

void SPIBrigeManager::low_level_spi_exchange_int()
{
    flip_get_size();
    CHK(ioctl(spi_handle, SPI_IOC_MESSAGE(1), &spi_xfer_int));
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
        from_spi_data.insert(from_spi_data.end(), spi_exchange_int_buffer.begin(), spi_exchange_int_buffer.end());
    }

}

void SPIBrigeManager::on_data_arrived(uint32_t data, uint32_t channel)
{
    uint32_t data_and_channel = (data&0x0FFFFFFF) | (channel << 28);
    auto delay = data & (1<<27) ? 0 : channel_latency[channel]; // High bit of CTRL denote Seq based operation - no need to delay after OP
    to_spi_data.push_back(data_and_channel);
    while(delay--) to_spi_data.push_back(0);
}

bool SPIBrigeManager::spi_exchange_loop(bool first_entry)
{
    auto first = to_spi_data.begin();
    auto counter = std::min(to_spi_data.size(), SPI_QUEUE_SIZE);

    std::copy_n(first, counter, spi_exchange_buffer.begin());
    to_spi_data.erase(first, first + counter);

    if (!counter)
    {
        if (!first_entry) return false;
        counter = 16;
        std::fill_n(spi_exchange_buffer.begin(), counter, 0);
    }
    low_level_spi_exchange(counter, true);

    int new_status_register = status_register;

    enum {
        Valid   = 0x01000000,
        Empty   = 0x02000000,
        SizeReq = 0x04000000,
        Shadow  = 0x08000000
    };

    for(;;)
    {
        uint32_t counter_value = 0;
        int counter_index = -1;
        for(size_t idx = 0; idx < counter; ++idx)
        {
            uint32_t value = spi_exchange_buffer[idx];
            uint32_t channel = value >> 28;
            if (channel) spi_integrator::SPIDevInterface::dispatch_input_data(value); else
            {
                if (value & SizeReq) {counter_value = (value >> 11) & 0x1FFF; counter_index = idx + 1;} else
                if (value & Valid) new_status_register = value;
            }
        }

        if (counter_index == -1) break;
        int total_read = counter_value - counter + counter_index;
        if (total_read <= 0)
        {
            if (new_status_register & Empty) break;
            total_read = 1024 - 16;
        }
        counter = total_read + 16;
        low_level_spi_exchange(counter, false);
    }

    if (new_status_register != -1) new_status_register &= 0x00FFFFFF;
    if (new_status_register != status_register) 
    {
        status_register = new_status_register;
        spi_integrator::SPIDevInterface::dispatch_input_data(status_register);
    }

    return counter != 0;
}
