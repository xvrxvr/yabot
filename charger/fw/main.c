#include "common.h"
#include "scr_script.h"

// #include <stdio.h>

void delay_ms(uint8_t dly)
{
    (void)dly;
__asm
        mov     acc,dpl      ; 100 * 1ms = 100ms
1$:     mov     b,#65        ; 65 * 15.26us = 1ms
        djnz    b,.          ; sit here for 1ms
        djnz    acc,1$       ; repeat 100 times (100ms delay)
__endasm;
}

///////////////////////////////////////////////////////////////////////////////////
// Int processing
#define R(v) RNG_##v
#define U(v) (R(v) | UNI)
#define C(v) (CHSEL_##v|XREF_RefIn)
#define S(v) (VS_##v)
#define FAST 0x45
#define SLOW 255

static __code uint8_t int_adc_sequensor[] = {
    // Range, Channel,   VSel         Speed
//    R(20mV),  C(1_2),    S(Zero),     SLOW,
    U(2_56V), C(1_2),    S(FullBat),  SLOW,
    U(640mV), C(1_2),    S(B1),       SLOW,
    U(640mV), C(1_2),    S(B2),       SLOW,
    U(640mV), C(1_2),    S(B3),       SLOW,
    U(640mV), C(1_2),    S(B4),       SLOW,
    U(2_56V), C(3_4),    S(Zero),     SLOW, // Current sence AD8553
    U(2_56V), C(5_COM),  S(Zero),     SLOW, // Vinput sence (div by 2K/18K)

    U(640mV), C(1_2),    S(BL1),      FAST,
    U(640mV), C(1_2),    S(BL2),      FAST,
    U(640mV), C(1_2),    S(BL3),      FAST,
    U(640mV), C(1_2),    S(BL4),      FAST,
    R(2_56V), C(6_COM),  S(Zero),     FAST  // CC/CV sence
//    R(2_56V), C(1_2),    S(Charge),   FAST
};
#undef R
#undef U
#undef C
#undef S

volatile __idata uint16_t ext_adc_values[VI_BL1];
volatile uint8_t ext_adc_flags;

static volatile int16_t qenc_value;

uint8_t get_qenc(void)
{
    uint8_t result;
    __critical {result = qenc_value; qenc_value=0;}
    return result;
}

// Backoff time interrupt + QENCB int
void t2_int(void) __interrupt(5) __using(1) __critical
{
    static uint8_t qenc_debouncer;

    if (TF2)
    {
        TF2 = 0;
        if (!--qenc_debouncer)
        {
            TR2 = 0;
            EXEN2 = 1;
        }
    }
    else if (EXF2)
    {
        EXF2 = 0;
        if (P3_2) ++qenc_value; else --qenc_value;
        TR2 = 0;
        TH2 = 0;
        TL2 = 0;
        EXEN2 = 0;
        TF2 = 0;
        TR2 = 1;
        qenc_debouncer = 10;
    }
}

uint8_t button_status(void)
{
    static uint8_t btn_debouncer;
    static uint8_t long_btn_count;
    static uint8_t ext_buttons_status;
    static uint8_t one_hz_div;

    uint8_t result = ext_buttons_status;
    if (TF0) 
    {
        TF0 = 0;
        result |= BT_5ms; 
        if (++one_hz_div >= 192)
        {
            result |= BT_1Hz;
            one_hz_div = 0;
        }

    }
    if (btn_debouncer)
    {
        if (result&BT_5ms) --btn_debouncer;
        return result;
    }
    if (P0_6 == (result&BT_Press))
    {
        ext_buttons_status ^= BT_Press;
        result ^= BT_Press;
        btn_debouncer = 6;
        if (result&BT_Press) result |= BT_Hit;
        long_btn_count = 0;
    }
    if ((result&(BT_Press|BT_5ms)) == (BT_Press|BT_5ms))
    {
        if (long_btn_count == 0x80) result |= BT_Long;
        if (long_btn_count <= 0x80) ++long_btn_count;
    }
    return result;
}

void adc_int(void) __interrupt(6) __using(1)  __critical
{
    static __idata uint16_t int_adc_values[VITotal];
    static uint8_t int_adc_index = 0xFF;

    if (!RDY0) return;

    if (int_adc_index == 0xFF) int_adc_index=0; else
    {
        ByteWord acc;
        acc.h = ADC0H; acc.l = ADC0M;
        int_adc_values[int_adc_index++] = acc.w;
        if (int_adc_index >= VITotal)
        {
            int_adc_index = 0;
            if (!(ext_adc_flags & AF_Rdy))
            {
                uint8_t idx = VI_BL1*2;
                __idata uint8_t* s=int_adc_values;
                __idata uint8_t* d=ext_adc_values;
                do {*d++=*s++;} while(--idx);
                
                idx=4;
                uint8_t tmp = AF_BL1;
                uint16_t v;
                do {
                    v = *(__idata uint16_t*)s;
                    s+=2;
                    if (v<43690) ext_adc_flags &= ~tmp; else
                    if (v>48684) ext_adc_flags |= tmp; 
                    tmp <<= 1;
                } while(--idx);

                v = int_adc_values[VI_CC_CV];
                if (v<40000) ext_adc_flags |= AF_CV; else
                if (v>64000) ext_adc_flags &= ~AF_CV;

                ext_adc_flags |= AF_Rdy;
            }
        }
    }
    RDY0=0;
    {
        uint8_t tmp = int_adc_index<<2;
        SET_RNG(int_adc_sequensor[tmp]);
        SEL_CHp(int_adc_sequensor[++tmp]);
        uint8_t tmp2 = int_adc_sequensor[++tmp];
        SEL_VSEL(tmp2);
        P0_7 = (tmp2 >> 3) & 1; // Bit 0 of MUX are burned out :( Switch it to P0.7
        SF = int_adc_sequensor[++tmp];
        START_ADC();
    }
}

void charge_on() 
{
    __critical {ext_adc_flags |= AF_ChargeOn;}
    ChargeEn = 1;
}

void charge_off()
{
    __critical {ext_adc_flags &= ~AF_ChargeOn;}
    ChargeEn = 0;
}

uint8_t wait_for(uint8_t mask)
{
    for(;;)
    {
        if ((ext_adc_flags&AF_Rdy) && (mask&WM_ADC))
        {
            uart_send_data();
            __critical {ext_adc_flags &= ~AF_Rdy;}
            return WM_ADC;
        }
        if (qenc_value && (mask&WM_QEnc)) return WM_QEnc;
        if (mask&BT_All)
        {
            uint8_t tmp = button_status();
            if (tmp&mask&BT_All) return tmp;
        }
    }
}

char _sdcc_external_startup(void)
{
    CFG848 = XRAMEN;
    return 0;
}

void on_init(void);

void main()
{
    IE = 0;
//    CFG842 = XRAMEN|EXSP;
    PLLCON = 0;
    ADCMODE = REJ60;
    SET_RNG(RNG_2_56V);
    SEL_CH(CHSEL_ZERO);
    SF = 0xFF;  // Fadc select
    I2CCON = 0x08; // I2CM
    SPICON = 0x30; // SPE|SPIM

    T3CON = 0x82;
    T3FD = 0x2D;

    SCON = 0b01010000;

    P0 = 0x52; // Reset, not CS, not Charge, FAN off
    //FAN_ON();
    P1 = 0xFF;
    P2 = 0xFF;
    SEL_VSEL(VS_Zero);

    TMOD = 0x01; // T0 - 16 bit counter
    TCON = 0x10; // Run T0

    RCAP2L = 0; 
    RCAP2H = 0; 
    T2CON = 8; // TR2 - Stop, EXEN2
    IE = 0xE0; // EA, EADC, ET2

    START_ADC();

    lcd_init();

    current_mode = 0xFF;

    on_init();  // !!!

    for(;;)
        switch(current_mode)
        {
            case MD_NoBat: run_nobat_mode(); break;
            case MD_Offline: run_offline_mode(); break;
            case MD_Online: run_online_mode(); break;
            case MD_Charging: run_charge_mode(); break;
            default: wait_screen(); // FALL THROUGH
            case MD_Auto: current_mode = detect_current_mode(); break;
        }

#if 0
    // ChargeEn = 1;

    //    lcd_box(0,0,320,240,0);
    // lcd_text(10, 0, "Test", 0);
    // lcd_text2(10, 40, "Test", 0);
    // lcd_draw_script(screen_charge);

    static __xdata char b[30];

    uint8_t __idata acc = 0;
    __bit on = 0;
    int8_t __idata prev_mcp = 0;

    for(;;)
    {
        if (ext_adc_flags)
        {
            uint8_t __idata cnt;
            uint16_t __idata v;
            for(cnt=0; cnt!=VITotal; ++cnt)
            {
                v= ext_adc_values[cnt];
                sprintf (b,"%04X", v);
                lcd_text(b, (cnt&7)*40, (cnt>>3)*16, 0);
                printf("%u,", v);
            }

            sprintf(b, "%d  ", qenc_value);
            lcd_text(b, 0, 130, 0);
            if (prev_mcp!=qenc_value)
            {
                prev_mcp=qenc_value;
                if (mcp_set(prev_mcp+0x7f)) lcd_text("Fail", 320, 130, 0);
            }
            printf("%d,%c\r\n", qenc_value, on?'+':'-');

            //lcd_text(str_20v(vc_20v(ext_adc_values[VI_Input])), 0, 40, 0);
            v = (525 * (long)ext_adc_values[VI_Input]) >> 14;
            sprintf(b, "I %2d.%02d", v/100, v%100);
            lcd_text(b, 0, 40, 0);
            v = (525 * (long)ext_adc_values[VI_FullBat]) >> 14;
            sprintf(b, "O: %2d.%02d", v/100, v%100);
            lcd_text(b, 160, 40, 0);

            ext_adc_flags=0;
        }
        /*
        uint8_t tmp = buttons_hits();
        if (tmp)
        {
            sprintf(b, "%02X %02X %3d", tmp, ext_buttons_status, cnt++);
            lcd_text(b, 0, 130, 0);
        }
        */

        uint8_t btn = button_status();
        acc |= btn;
        if (!(btn&1)) acc=0;
        sprintf(b, "%02X %02X", acc, btn);
        lcd_text(b, 0, 150, 0);

        if (btn&BT_Hit)
        {
            on = !on;
            ChargeEn = on;
            lcd_text(on?"ON ":"OFF", 0, 80, 0);
        }

    }
#endif

}
