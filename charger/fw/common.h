#pragma once

#include <stdint.h>
#include <string.h>

#include <8052.h>
#include <ADuC84x.h>

SFR(ADCMODE,  0xD1);
    #define REJ60   0x40
    #define ADC0EN  0x20
    #define CHOP    0x08
    #define MD_Off     0
    #define MD_Idle    1
    #define MD_Single  2
    #define MD_Contns  3
    #define MD_IntZero 4
    #define MD_IntFullSc 5
    #define MD_SysZero 6
    #define MD_SysFullSc 7

SFR(ADC0CON1, 0xD2);
    #define BUF_ON     0x00
    #define BUF_OFF    0x40
    #define UNI        0x20
    #define RNG_20mV      0
    #define RNG_40mV      1
    #define RNG_80mV      2
    #define RNG_160mV     3
    #define RNG_320mV     4
    #define RNG_640mV     5
    #define RNG_1_28V     6
    #define RNG_2_56V     7

SFR(ADC0CON2, 0xE6);
    #define XREF_Int     0x00
    #define XREF_RefIn   0x40
    #define XREF_RefIn2  0x80
    #define CHSEL_1_COM  0
    #define CHSEL_2_COM  1
    #define CHSEL_3_COM  2
    #define CHSEL_4_COM  3
    #define CHSEL_5_COM  4
    #define CHSEL_6_COM  5
    #define CHSEL_7_COM  6
    #define CHSEL_8_COM  7
    #define CHSEL_1_2    10
    #define CHSEL_3_4    11
    #define CHSEL_5_6    12
    #define CHSEL_7_8    13
    #define CHSEL_ZERO   15

SFR(SF, 0xD4);

SBIT(RDY0, 0xD8, 7);
SFR(ADC0M, 0xDA);
SFR(ADC0H, 0xDB);

SFR(CFG848, 0xAF);

#define START_ADC()         (ADCMODE = REJ60|ADC0EN|MD_Single)
#define SET_RNG(rng)        (ADC0CON1 = (rng))
#define SET_RNG_UNI(rng)    (ADC0CON1 = (rng)|UNI)
#define SEL_CH(ch)          (ADC0CON2 = (ch)|XREF_RefIn)
#define SEL_CHp(ch)         (ADC0CON2 = (ch))

#define LCD_Reset_n     P0_0
#define LCD_CS_n        P0_1
#define LCD_DC          P0_2   // 1 for Data, 0 for Comand
#define ChargeEn        P0_3
#define FAN             P0_4

#define FAN_ON() (FAN=0)
#define FAN_OFF() (FAN=1)


#define VS(v) (7|(uint8_t)((uint8_t)(v)<<3))
enum VSel {
    VS_FullBat   = VS(0x08),    // Full battery voltage            
    VS_Charge    = VS(0x10),    // Charge state                    
                                                                   
    VS_B1        = VS(0x00),    // Cell 1 voltage                  
    VS_B2        = VS(0x04),    // Cell 2 voltage                  
    VS_B3        = VS(0x0E),    // Cell 3 voltage                  
    VS_B4        = VS(0x0A),    // Cell 4 voltage                  
                                                                   
    VS_BL1       = VS(0x01),    // Cell 1 Balance voltage          
    VS_BL2       = VS(0x05),    // Cell 2 Balance voltage          
    VS_BL3       = VS(0x0F),    // Cell 3 Balance voltage          
    VS_BL4       = VS(0x0B),    // Cell 4 Balance voltage          
                                                                   
    VS_Zero      = VS(0x06)     // Shot cat                        
};
#undef VS
#define SEL_VSEL(vsel) (P3 = (vsel))

void delay_ms(uint8_t dly);

typedef union {
    struct {uint8_t l, h;};
    uint16_t w;
} ByteWord;

enum VIndex {
//    VI_Zero,
    VI_FullBat,
    VI_B1,
    VI_B2,
    VI_B3,
    VI_B4,
    VI_CurrentSence,
    VI_Input,

    VI_BL1,
    VI_BL2,
    VI_BL3,
    VI_BL4,
    VI_CC_CV,
//    VI_Charge,

    VITotal
};

enum Limits {
    LIM_MinVoltage_10 = 31207,   // Min input voltage
    LIM_MinVoltage_101 = 30913,  // Min Battery voltage
    LIM_BatOverflow = 428-250,   // 4.28V - Battery overcharge
    LIM_MinCharge = 40           // Battery off current (zero error)
};

enum ChargeSetup {
    CST_IOff = 20 /* 200mA */,   // End of charge
    CSI_FanOn = 150 /* 1.5A */,  // Fan on
    CSI_FanOff = 100 /* 1A */,   // Fan off
    CSI_TargetVAdjRAW = 51929,    // 16.8V - Charge voltage
    CSI_MinVAdjRAW = CSI_TargetVAdjRAW - 155, // Histeresis: -0.05V
    CSI_MaxVAdjRAW = CSI_TargetVAdjRAW + 93, //              +0.03V
    CSI_BigMinVAdjRAW = CSI_TargetVAdjRAW - 310, // Fast adjust: -0.1V
    CSI_VAdjBackoff = 2,         // Backoff ticks for voltage adjust
    CSI_StartBackoff = 4         // Backoff ticks on start charging
};

enum ADCFlags {
    AF_BL1  = 0x01,
    AF_BL2  = 0x02,
    AF_BL3  = 0x04,
    AF_BL4  = 0x08,
    AF_CV   = 0x10,
    AF_ChargeOn = 0x20,
    AF_Rdy  = 0x80
}; // -> ext_adc_flags

enum Buttons {
    BT_Press = 0x01, // Sticky bit
    BT_Hit   = 0x02, // Auto clear bit
    BT_Long  = 0x04, // Auto clear bit
    BT_1Hz   = 0x40, // 1 Hz tick
    BT_5ms   = 0x80, // Timer tick (5.208 ms)

    BT_Keys  = BT_Hit|BT_Long,
    BT_Time  = BT_1Hz|BT_5ms,
    BT_All   = BT_Keys|BT_Time|BT_Press
}; // -> button_status()

///// Int subsystem (main.c)
extern volatile __idata uint16_t ext_adc_values[/* VI_BL1 */];
extern volatile uint8_t ext_adc_flags;
uint8_t button_status(void);

uint8_t get_qenc(void);

///
void charge_on(void);
void charge_off(void);

enum WaitMode {
    WM_ADC = 0x10,
    WM_QEnc = 0x20
};

uint8_t wait_for(uint8_t);
// Input - bitmask of WaitMode & Buttons, output - bitmask of Buttons & WaitMode

///////////////////////////////////////////////////////
// lcd.c
extern __code uint8_t colors_map[]; // In autogenerated file scr_script.c
void lcd_init(void);
void lcd_box(uint16_t x, uint8_t y, uint16_t dx, uint8_t dy, uint8_t color);
void lcd_text(const char* text, uint16_t x, uint8_t y, uint8_t color);
void lcd_text2(const char* text, uint16_t x, uint8_t y, uint8_t color);
void lcd_draw_script(__code uint8_t *script);
void lcd_logo(void);

///////////////////////////////////////////////////////
// m.c
enum VoltageError {
    VE_Overflow = 0xFF
};

uint8_t vc_20v(uint16_t voltage);
uint8_t vc_20_01v(uint16_t voltage);
uint8_t vc_4v(uint16_t voltage);
uint8_t vc_2v(uint16_t voltage);
uint8_t ic(uint16_t current);

char* str_20v(uint8_t voltage);
char* str_4v(uint8_t voltage);
char* str_2v(uint16_t voltage);
char* str_ic(uint8_t current);

///////////////////////////////////////////////////////
// i2c.c
extern uint8_t mcp_current_value;
uint8_t mcp_set(void);

///////////////////////////////////////////////////////
// screens.c
enum Mode {
    MD_Auto, // Autodetect
    MD_NoBat,   // Power on, no battery connected
    MD_Offline, // Power off, battery connected
    MD_Online,  // Power on, battery connected
    MD_Charging // Charging on
}; // -> current_mode
extern uint8_t current_mode;
uint8_t detect_current_mode(void);

void wait_screen(void);
void run_nobat_mode(void);
void run_offline_mode(void);
void run_online_mode(void);
void run_charge_mode(void);

enum CellStatus {
    CS_Udf,
    CS_Ovf,
    CS_Bal
};

enum ScrIndexes {
    SI_Normal,
    SI_Udf,
    SI_Ovf,
    SI_Bal
};

struct ADCInfo {
    uint8_t adc_flags;
    uint8_t full_bat_v;
    uint8_t charge_bat_i;
    uint8_t bat_v[8]; // 4 x 2-4V + 4 x 0-2V
};

extern __idata struct ADCInfo adc_info;

enum ExtFlags {
    EF_Overflow = 0x20,
    EF_Underflow = 0x40,

    EF_MASK = 0xE0
};

extern char* abort_message;
extern __idata char ch_timer[8];

void fill_adc_info();
void draw_bat_cells(const __code uint8_t*);
extern __code uint8_t bat_charge[];

//////////////////////////////////////////////////////
// uart.c
void uart_send_data(void);
void dbg(uint16_t);
void send_raw(uint8_t);

//////////////////////////////////////////////////////
// logo_data.c
extern __code uint8_t start_logo_data[];
extern __code uint8_t logo_rainbow[];
extern __code uint8_t logo_sin[];
