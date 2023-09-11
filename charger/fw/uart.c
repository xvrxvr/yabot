#include "common.h"

enum EscCodes {
    ESC = 0x5A,
    ESC_EOF = 0,
    ESC_EOF_NO_CRC = 1,
    ESC_ESC = 2,
    ESC_SOF0 = 0x80,
    ESC_DBG0 = 0x40,
};

/*

Serial protocol:

<ESC> <ESC_SOFn> <data...> <ESC> ( <ESC_EOF> crc | <ESC_EOF_NO_CRC>)

Any data byte with value of ESC replaced by <ESC> <ESC_ESC>

CRC evaluated as sum of all data bytes (before escaping)
If CRC equal to ESC it not emited, but sequence <ESC> <ESC_EOF> replaced by <ESC> <ESC_EOF_NO_CRC>

ESC_SOFn is a start marker. 'n' defines 'data' version.

Version 0:

FullBat, B1, B2, B3, B4, CurrentSence, Input (all of them 2 bytes in LSB order), ext_adc_flags (Byte), mcp_current_value (Byte)

*/

static uint8_t crc;

void send_raw(uint8_t c) 
{
    SBUF = c;
    while (!TI);
    TI = 0;
}

#define SEND_ESC(v) do {send_raw(ESC); send_raw(ESC_##v);} while(0)

static void send_data(uint8_t c)
{
    crc += c;
    if (c == ESC) SEND_ESC(ESC); else send_raw(c);
}

static void _finish()
{
    if (crc == ESC) SEND_ESC(EOF_NO_CRC);
    else {SEND_ESC(EOF); send_raw(crc);}
}

void uart_send_data()
{
    __idata uint8_t* adc_vals = (__idata uint8_t*)ext_adc_values;
    uint8_t count = VI_BL1*2;
    crc = 0;

    SEND_ESC(SOF0); 

    do {send_data(*adc_vals++);} while(--count);
    send_data(ext_adc_flags);
    send_data(mcp_current_value);

    _finish();
}

void dbg(uint16_t data)
{
    SEND_ESC(DBG0); 
    crc = 0;

    send_data(data);
    send_data(data>>8);

    _finish();
}
