#pragma once

#include <linux/spi/spidev.h>

class SPIBrigeManager {
    std::deque<uint32_t> to_spi_data, from_spi_data;
    std::vector<uint32_t> spi_exchange;
    std::thread overflow_thread;
    std::mutex overflow_queue_guard;

    int spi_handle;
    int gpio_data_valid, gpio_almost_full, gpio_get_sizes, gpio_radio_int;

    spi_ioc_transfer spi_xref;

    void hw_activate();
    void hw_deactivate();

    void overflow_thread_handle();

    bool spi_exchange_loop();

    void low_level_spi_exchange(int size);
    int open_gpio(int pin_idx, const char* setup, const char* int_edge=NULL);

public:
    SPIBrigeManager();
    ~SPIBrigeManager() {hw_deactivate();}

    void spi_exchange()
    {
        spi_exchange_loop();
        while(spi_exchange_loop()) {;}
    }

    void on_data_arrived(uint32_t data_and_channel)
    {
        to_spi_data.push_back(data_and_channel);
    }
};
