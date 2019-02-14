#include "StdAfx.h"

HANDLE h;

uint8_t send_spi(uint8_t cmd1, uint8_t cmd2=0xFF)
{
    uint8_t cmd[]={cmd1, cmd2};
    if (!CH341StreamSPI4(0,0x80,2,cmd))
    {
        printf("SPI error\n");
        exit(1);
    }
    return cmd[1];
}

inline uint8_t spi_read(uint8_t address) {return send_spi(address);}
inline void spi_write(uint8_t address, uint8_t data) {send_spi(address|0x80, data);}

struct SI_Status {
    uint8_t raw;

    SI_Status() {raw=spi_read(2);}
    SI_Status(int v) {raw=v;}

    bool ffovfl() const {return (raw & 0x80)!=0;}
    bool ffunfl() const {return (raw & 0x40)!=0;}
    bool rxffem() const {return (raw & 0x20)!=0;}
    bool headerr() const {return (raw & 0x10)!=0;} 
    int cps() const {return raw&3;}
}; 

struct SI_Ints {
    uint8_t raw1, raw2;

    SI_Ints() {raw1=spi_read(3); raw2=spi_read(4);}
    SI_Ints(int v1, int v2) {raw1=v1; raw2=v2;}

    bool ifferr()      const {return (raw1 & 0x80)!=0;}
    bool itxffafull()  const {return (raw1 & 0x40)!=0;}
    bool itxffaem()    const {return (raw1 & 0x20)!=0;}
    bool irxffafull()  const {return (raw1 & 0x10)!=0;}
    bool iext()        const {return (raw1 & 0x08)!=0;}
    bool ipksent()     const {return (raw1 & 0x04)!=0;}
    bool ipkvalid()    const {return (raw1 & 0x02)!=0;}
    bool icrcerror()   const {return (raw1 & 0x01)!=0;}

    bool iswdet()      const {return (raw2 & 0x80)!=0;}
    bool ipreaval()    const {return (raw2 & 0x40)!=0;}
    bool ipreainval()  const {return (raw2 & 0x20)!=0;}
    bool irssi()       const {return (raw2 & 0x10)!=0;}
    bool iwut()        const {return (raw2 & 0x08)!=0;}
    bool ilbd()        const {return (raw2 & 0x04)!=0;}
    bool ichiprdy()    const {return (raw2 & 0x02)!=0;}
    bool ipor()        const {return (raw2 & 0x01)!=0;}

    operator bool() const {return (raw1|raw2)!=0;}
};

inline void si_reset()
{
    //SW reset   
    spi_write(0x07, 0x80);															//write 0x80 to the Operating & Function Control1 register 

    for(int i=0;;++i)
    {
        SI_Ints sint;
        if (!sint) 
        {
            if (i>10)  
            {
                printf("Timeout in POR interrupt!\n");
                exit(1);
            }
            Sleep(100); 
            continue;
        }
        if (!sint.ipor())
        {
            printf("POR int not detected! (%02X, %02X)\n", sint.raw1, sint.raw2);
            exit(1);
        }
        if (sint.ichiprdy()) return;
        break;
    }

    for(int i=0;;++i)
    {
        SI_Ints sint;
        if (!sint) 
        {
            if (i>10)  
            {
                printf("Timeout in ChipReady interrupt!\n");
                exit(1);
            }
            Sleep(100); 
            continue;
        }
        if (!sint.ichiprdy())
        {
            printf("ChipReady int not detected! (%02X, %02X)\n", sint.raw1, sint.raw2);
            exit(1);
        }
        break;
    }
}

inline void si_init()
{
    // 433.92Mhz

    spi_write(0x1C,0x88);
    spi_write(0x1D,0x44);
    spi_write(0x1E,0x02);
    spi_write(0x1F,0x03);
    spi_write(0x20,0x3C);
    spi_write(0x21,0x01);
    spi_write(0x22,0x11);
    spi_write(0x23,0x11);
    spi_write(0x24,0x07);
    spi_write(0x25,0xFF);
    spi_write(0x2A,0x50);
    spi_write(0x30,0xAC);
    spi_write(0x32,0x8C);
    spi_write(0x33,0x02);
    spi_write(0x34,0x40);
    spi_write(0x35,0x2A);
    spi_write(0x36,0x2D);
    spi_write(0x37,0xD4);
    spi_write(0x38,0x00);
    spi_write(0x39,0x00);
    spi_write(0x3A,0x00);
    spi_write(0x3B,0x00);
    spi_write(0x3C,0x00);
    spi_write(0x3D,0x00);
    spi_write(0x3E,0x00);
    spi_write(0x3F,0x00);
    spi_write(0x40,0x00);
    spi_write(0x41,0x00);
    spi_write(0x42,0x00);
    spi_write(0x43,0xFF);
    spi_write(0x44,0xFF);
    spi_write(0x45,0xFF);
    spi_write(0x46,0xFF);
    spi_write(0x58,0xED);
    spi_write(0x69,0x60);
    spi_write(0x6E,0x19);
    spi_write(0x6F,0x9A);
    spi_write(0x70,0x0E);
    spi_write(0x71,0x23);
    spi_write(0x72,0x50);
    spi_write(0x75,0x53);
    spi_write(0x76,0x62);
    spi_write(0x77,0x00);

    /*set the GPIO's according the testcard type*/
    spi_write(0x0C, 0x12);															//write 0x12 to the GPIO1 Configuration(set the TX state)
    spi_write(0x0D, 0x15);															//write 0x15 to the GPIO2 Configuration(set the RX state) 

                                                                                            /*set the non-default Si443x registers*/
                                                                                            //set Crystal Oscillator Load Capacitance register
    // spi_write(0x09, 0xD7);															//write 0xD7 to the CrystalOscillatorLoadCapacitance register

    spi_write(0x6D, 0x1F); // Set max TX power
}

inline void si_ie(uint8_t mask1=0, uint8_t mask2=0)
{
    spi_write(5, mask1);
    spi_write(6, mask2);
}

void si_send(uint8_t length, const void* buffer)
{
    /*SET THE CONTENT OF THE PACKET*/
    //write length to the Transmit Packet Length register
    spi_write(0x3E, length);														
    
    //fill the payload into the transmit FIFO
    const uint8_t* p=(const uint8_t*)buffer;
    while(length--)
        spi_write(0x7F, *p++);

    //Disable all other interrupts and enable the packet sent interrupt only.
    si_ie(4);  //This will be used for indicating the successfull packet transmission for the MCU
    SI_Ints(); //Read interrupt status regsiters. It clear all pending interrupts and the nIRQ pin goes back to high.

    /*enable transmitter*/
    //The radio forms the packet and send it automatically.
    spi_write(0x07, 0x09); //write 0x09 to the Operating Function Control 1 register

    /*wait for the packet sent interrupt*/
    //The MCU just needs to wait for the 'ipksent' interrupt.
    for(int i=0;i<10;++i)
    {
        SI_Ints sint;
        if (sint.ipksent()) return;
        Sleep(100); 
    }
    printf("Timeout in TX interrupt!\n");
    exit(1);
}

// Returns AGC data in high byte, RSSI data in low
uint16_t si_rssi_info()
{
    uint16_t agc = spi_read(0x69) & 0x1F;
    return (agc<<8) | spi_read(0x26);
}


struct SI_Recv {
    uint8_t buffer[64];
    uint16_t rssi_info;

    enum Status {
        S_None = 0, // No data, no errors
        S_CRC_Error = -1, // CRC error occure
        S_LenError = -2 // Invalid packet length
    };

    SI_Recv();
    ~SI_Recv();
    int chk_status();
};

SI_Recv::SI_Recv()
{
    si_ie(3); // ipkval & icrcerror
    SI_Ints(); // Read ints

    /*enable receiver chain*/
    spi_write(0x07, 0x05);
}

SI_Recv::~SI_Recv()
{
    si_ie(0); // Disable ints
    SI_Ints(); // Read ints
    spi_write(0x07, 0x01);
}

int SI_Recv::chk_status()
{
    SI_Ints ints;
    if (!ints) return 0;
    int result;
    if (ints.icrcerror()) 
    {
        //disable the receiver chain 
        spi_write(0x07, 0x01);
        result=S_CRC_Error; 
    }
    else if (ints.ipkvalid())
    {
        rssi_info = si_rssi_info();
        //disable the receiver chain 
        spi_write(0x07, 0x01);
        result = spi_read(0x4B); // Pkt length
        if (result>=64) result=S_LenError; else
        {
            for(int i=0;i<result;++i)
                buffer[i]=spi_read(0x7F);
        }
    }
    else return 0;
    //reset the RX FIFO
    spi_write(0x08, 0x02); //write 0x02 to the Operating Function Control 2 register
    spi_write(0x08, 0x00);	//write 0x00 to the Operating Function Control 2 register
    //enable the receiver chain again
    spi_write(0x07, 0x05); //write 0x05 to the Operating Function Control 1 register
    return result;
}

int main(int argc, char** argv)
{
    printf("Driver version is %d\n", CH341GetVersion());
    h = CH341OpenDevice(0);
    if (h==INVALID_HANDLE_VALUE)
    {
        printf("Can't open device\n");
        return 1;
    }
    CH341SetExclusive( 0, TRUE );
    int CH341ChipVer = CH341GetVerIC( 0 );
    printf("Chip version is %X\n", CH341ChipVer);
    BOOL CH341SPIBit = FALSE;
    if( CH341ChipVer >= 0x30 )
    {
        CH341SPIBit = TRUE;
        CH341SetStream( 0, 0x81 );
    }

#if 0
    for(;;)
    {
        unsigned char buf[] = {0x55, 0xAA};
        if (!CH341StreamSPI4( // Processing SPI data stream, 4-wire interface, clock line is DCK/D3 pin, output data line is DOUT/D5 pin, input data line is DIN/D7 pin, chip select line is D0/ D1/D2, speed about 68K bytes
                                     /* SPI timing: DCK/D3 pin is clock output, default is low level, DOUT/D5 pin is output during low period before clock rising edge, DIN/D7 pin is high power before falling clock edge During the flat input */
                                    0, // Specify CH341 device serial number
                                    0x80, // Chip select control. Bit 7 is 0 to ignore chip select control. Bit 7 is 1 and the parameter is valid: Bit 1 Bit 0 is 00/01/10 Select D0/D1/D2 pin as low level respectively Effective chip selection
                                    2, // The number of bytes of data to be transferred
                                    buf)) // Point to a buffer, place the data to be written out from DOUT, and return the data read from DIN
        {
            printf("SPI error");
            return 1;
        }
        printf("%02X %02X\n", buf[0], buf[1]);

    }
#endif

    printf("Device type:    %02X\n", spi_read(0));
    printf("Device Version: %02X\n", spi_read(1));
    printf("Device status:  %02X\n", spi_read(2));

    si_reset();
    si_init();

    if (argc<2) return 0;

    if (argv[1][0]=='s')
    {
        for (;;)
        {
            si_send(4,"1234");
            printf ("Data sent\n");
            Sleep(1000);
        }
    }
    else
    {
        SI_Recv rcv;
        for(;;Sleep(100))
        {
            int s=rcv.chk_status();
            if (s==0) continue;
            if (s>0)
            {
                printf("Recv:");
                for(int i=0;i<s;++i) printf(" %02X",rcv.buffer[i]);
                printf(" - %04X\n",rcv.rssi_info);
            }
            else
                printf("Error in recieve: %d\n",-s);
        }
    }

    return 0;
}