#include "spi_brige_common.h"
#include "spi_brige_manager.h"
#include "spi_integrator.h"

#include <unistd.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <linux/types.h>

#define SPI_FILE "/dev/spidev1.0"  // 1 - Bus, 0 - CS

namespace spi_integrator {
    SPIDevInterface* SPIDevInterface::all_spi_interfaces[TOTAL_SPI_DEVICES];
}


SPIBrigeManager::SPIBrigeManager() : spi_exchange(SPI_QUEUE_SIZE), spi_exchange_int(SPI_INT_QUEUE_SIZE)
{
    gpio_handle = spi_handle = gpio_data_valid = gpio_almost_full = gpio_get_sizes = gpio_radio_int = -1;
    prev_gpio_get_sizes = 0;
    hw_activate();
    overflow_thread = std::thread([this] {this->overflow_thread_handle();});
    spi_integrator::SPIDevInterface::init_all();
}

#define CHK(code) ({auto err = (code); if (err<0) throw std::exception("SPI Error: " #code); err})
#define IOCTL(id, val) CHK(mode=val, ioctl(spi_handle, id, &mode))

enum {
 GPIO_DATA_VALID = 22,   // IO8
 GPIO_ALMOST_FULL = 23,  // IO9
 GPIO_GET_SIZES = 24,    // IO11
 GPIO_RADIO_INT = 25   // IO16
};

void SPIBrigeManager::hw_activate()
{
    constexpr int max_spi_freq = 20 * 1000 * 1000;  // 20 MHz

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
    xref.tx_buf = xref.rx_buf = (uint64_t)spi_exchange.data();
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


void SPIBrigeManager::low_level_spi_exchange(int size)
{
    xref.len = size;
    CHK(ioctl(spi_handle, SPI_IOC_MESSAGE(1), &xfer));
}

void SPIBrigeManager::low_level_spi_exchange_int()
{
    CHK(ioctl(spi_handle, SPI_IOC_MESSAGE(1), &xfer_int));
}


void SPIBrigeManager::overflow_thread_handle()
{
}

bool SPIBrigeManager::spi_exchange_loop()
{
}


