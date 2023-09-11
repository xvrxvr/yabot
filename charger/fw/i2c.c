#include "common.h"

uint8_t mcp_current_value = 127;

static uint8_t noack;

static void delay(void)
{
    __asm__("nop");
}

static void start(void)
{
    MDE = 1; // enable SDATA pin as an output
    noack = 0;
    MDO = 0; // low O/P on SDATA 
    delay();
    MCO = 0; // start bit
}

static void stop(void)
{
    MDE = 1; // to enable SDATA pin as an output
    MDO = 0; // get SDATA ready for stop
    delay();
    MCO = 1; // set clock for stop
    delay();
    MDO = 1; // this is the stop bit
}

static void send_byte(uint8_t data)
{
    (void)data;
    MDE = 1;  // to enable SDATA pin as an output
    MCO = 0;  // make sure that the clock line is low

    __asm
        MOV     B,#8            // 8 bits in a byte
        MOV     A, dpl
1$:
        RLC     A               // put data bit to be sent into carry
        MOV     _MDO,C           // put data bit on SDATA line
        acall _delay
        SETB    _MCO             // clock to send bit
        acall _delay
        CLR     _MCO             // clear clock 
        nop
        nop
        DJNZ    B,1$            // jump back and send all eight bits

        CLR     _MDE             // release data line for acknowledge
        SETB    _MCO             // send clock for acknowledge
        acall _delay
        JNB     _MDI,$2          // this is a check for acknowledge
        //SETB    _noack           // no acknowledge, set flag
        mov _noack, #1
$2:     CLR     _MCO             // clear clock 
    __endasm;
}

uint8_t mcp_set(void)
{
    start();
    send_byte(0x78);
    send_byte(0);
    send_byte(mcp_current_value);
    stop();
    return noack;
}
