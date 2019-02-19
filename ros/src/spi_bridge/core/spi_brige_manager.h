#pragma once

#include <linux/spi/spidev.h>
#include "spi_integrator.h"

class SPIBrigeManager {
    struct LatencyDef {
        spi_integrator::SpiDevices dev;
        int latency;
    };
    constexpr static LatencyDef latencies[]={
        {spi_integrator::SD_ADC, 3}, 
        {spi_integrator::SD_Radio, 3}
    };
    constexpr static int total_latencies  = sizeof(latencies)/sizeof(latencies[0]);

    std::deque<uint32_t> to_spi_data[1+total_latencies], from_spi_data;
    int channel_encoder[spi_integrator::TOTAL_SPI_DEVICES];
    std::vector<uint32_t> spi_exchange_buffer, spi_exchange_int_buffer;
    std::thread overflow_thread;
    std::mutex overflow_queue_guard;

    int spi_handle;
    int gpio_data_valid, gpio_almost_full, gpio_get_sizes, gpio_radio_int;
    uint8_t prev_gpio_get_sizes;

    spi_ioc_transfer spi_xfer, spi_xfer_int;

    int status_register;

    void hw_activate();
    void hw_deactivate();

    void overflow_thread_handle();

    bool spi_exchange_loop(bool first_entry);

    void low_level_spi_exchange(int size, bool do_send);
    void low_level_spi_exchange_int();

    int open_gpio(int pin_idx, const char* setup, const char* int_edge=NULL);

    void flip_get_size();

public:
    SPIBrigeManager();
    ~SPIBrigeManager() {hw_deactivate();}

    void spi_exchange()
    {
        spi_exchange_loop(true);
        while(spi_exchange_loop(false)) {;}
    }

    void on_data_arrived(uint32_t data, uint32_t channel);
};
