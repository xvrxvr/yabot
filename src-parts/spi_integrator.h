#pragma once

namespace spi_integrator {

enum SpiDevices {
    SD_NOP = 0,
    SD_Sonars = 1,
    SD_Motor = 2,
    SD_ADC = 3,
    SD_Radio = 4,
    SD_RemoteCtrl = 5,

    SD_Servo   = 13,
    SD_OutGPIO = 14,
    SD_PowerOff = 15
};

static int TOTAL_SPI_DEVICES = 16;

class SPIDevInterface {
    static SPIDevInterface* all_spi_interfaces[TOTAL_SPI_DEVICES];
    SpiDevices self_device_id;

public:
    SPIDevInterface(SpiDevices id) :self_device_id(id) {assert(all_spi_interfaces[id] == NULL); all_spi_interfaces[id]=this;}

    ///////// Callbacks for DevInterface implementators /////////////////////////////////////
    virtual void init() {}
    // This method will be called after all initialization passed. Create ROS chanels here

    virtual void on_data_arrived(uint32_t data) {}
    // Process one word on data arrived on SPI interface. You can send ROS messages here

    virtual void on_tick() {}
    // Called on every tick after ALL incoming data processed. Can be used to implement watchdogs and periodic counters

    ////////// Interface for DevInterface implementators /////////////////////////////////////
    void send_data(uint32_t data);
    // Send one word of data to SPI interface
    // This method should be called from ROS callback methods of input chanel(s)

    //////////////////////////// Interfaces for core module //////////////////////////////////////////
    static void init_all()
    {
        for(auto me: all_spi_interfaces)
            if (me) me->init();
    }

    static void dispatch_input_data(uint32_t data)
    {
        if (auto me = all_spi_interfaces[data>>28]) me->on_data_arrived(data & 0x0FFFFFFF);
    }
};



}
