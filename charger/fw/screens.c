#include "common.h"
#include "scr_script.h"

uint8_t current_mode;

void wait_screen()
{
    //lcd_draw_script(screen_wait);
    lcd_logo();
    wait_for(WM_ADC);
    wait_for(WM_ADC);
}

uint8_t detect_current_mode()
{
    if (ext_adc_values[VI_FullBat] < LIM_MinVoltage_101) return MD_NoBat;
    if (ext_adc_values[VI_Input] < LIM_MinVoltage_10) return MD_Offline;
    return MD_Online;
}

/////////////////////////////////////////////////////////////////////////////
static __code uint8_t bat_offline[] = {SEC_OFFLINE_C1_NC, SEC_OFFLINE_C2_NC, SEC_OFFLINE_C3_NC, SEC_OFFLINE_C4, COLOR2_BAT_UDF, COLOR2_BAT_OVF, COLOR2_BAT_BAL};
static __code uint8_t bat_online[]  = {SEC_ONLINE_C1_NC,  SEC_ONLINE_C2_NC,  SEC_ONLINE_C3_NC,  SEC_ONLINE_C4,  COLOR2_BAT_UDF, COLOR2_BAT_OVF, COLOR2_BAT_BAL};
__code uint8_t bat_charge[]  = {SEC_CHARGE_C1_NC,  SEC_CHARGE_C2_NC,  SEC_CHARGE_C3_NC,  SEC_CHARGE_C4,  COLOR2_BAT_UDF, COLOR2_BAT_OVF, COLOR2_BAT_BAL};

__idata struct ADCInfo adc_info;

void fill_adc_info()
{
    adc_info.adc_flags = ext_adc_flags & ~EF_MASK;
    adc_info.full_bat_v = vc_20_01v(ext_adc_values[VI_FullBat]);
    adc_info.charge_bat_i = ext_adc_flags & AF_ChargeOn ? ic(ext_adc_values[VI_CurrentSence]) : 0;

    uint8_t idx=4;
    __idata uint16_t* adc = ext_adc_values + VI_B1;
    __idata uint8_t* dst = adc_info.bat_v;
    do {
        uint16_t val = *adc++;
        uint8_t bat_value = vc_4v(val);
        if (bat_value >= LIM_BatOverflow) adc_info.adc_flags |= EF_Overflow;
        *dst++ = bat_value;
        if (!bat_value) {dst[3] = vc_2v(val); adc_info.adc_flags |= EF_Underflow;}
    } while(--idx);
}

void draw_bat_cells(const __code uint8_t* script)
{
    uint8_t idx=4;
    uint8_t adc_status = adc_info.adc_flags;
    __code uint8_t* setup = script+8;
    __idata uint8_t* adc = adc_info.bat_v;
    do {
        char* str;
        uint8_t val = *adc++;
        uint8_t color = SI_Normal;
        if (adc_status & AF_BL1) color = SI_Bal;
        if (val >= LIM_BatOverflow) color = SI_Ovf;
        if (val) str = str_4v(val);
        else {color = SI_Udf; str = str_2v(adc[3]);}
        lcd_text2(str, script[0], script[1], setup[color]);
        script+=2;
        adc_status >>= 1;
    } while(--idx);
}

/////////////////////////////////////////////////////////////////////////////
char* abort_message = NULL;
__idata char ch_timer[8];

void run_nobat_mode()
{
    lcd_draw_script(screen_nobat);
    while(current_mode == MD_NoBat)
    {
        wait_for(WM_ADC);
        current_mode = detect_current_mode();
    }
    wait_for(WM_ADC);
}


static __bit draw_xline_messages(__bit is_online)
{
    if (adc_info.adc_flags & EF_Underflow) {lcd_draw_script(screen_offline_dead); return 0;}
    if (adc_info.adc_flags & EF_Overflow) {lcd_draw_script(screen_offline_overcharge); return 0;}
    if (abort_message) {lcd_draw_script(screen_offline_abort); lcd_text(abort_message, SEC_OFFLINE_ABORT_MSG); return 1;}
    if (ch_timer[0]) {ch_timer[4]=0; lcd_draw_script(screen_offline_last_ch_msg); lcd_text(ch_timer, SEC_OFFLINE_LAST_CH_MSG_TIME); return 1;}
    if (is_online) lcd_draw_script(screen_online_start);
    else lcd_box(0, MSG_TOP_Y, 320, 16, COLOR_BLACK);
    return 1;
}

void run_offline_mode()
{
    lcd_draw_script(screen_offline);
    while(current_mode == MD_Offline)
    {
        fill_adc_info();
        draw_bat_cells(bat_offline);
        lcd_text2(str_20v(adc_info.full_bat_v), SEC_OFFLINE_BAT);
        draw_xline_messages(0);
        wait_for(WM_ADC);
        current_mode = detect_current_mode();
    }
    wait_for(WM_ADC);
}

void run_online_mode()
{
    lcd_draw_script(screen_online);
    while(current_mode == MD_Online)
    {
        fill_adc_info();
        draw_bat_cells(bat_online);
        lcd_text2(str_20v(adc_info.full_bat_v), SEC_ONLINE_BAT);
        lcd_text2(str_20v(vc_20v(ext_adc_values[VI_Input])), SEC_ONLINE_INP);
        __bit can_be_activated = draw_xline_messages(1);
        uint8_t key;
        if (draw_xline_messages(1)) key = wait_for(WM_ADC|BT_Hit);
        else {key=0; wait_for(WM_ADC);}
        current_mode = detect_current_mode();
        if ((key&BT_Hit) && current_mode == MD_Online) 
        {
            current_mode = MD_Charging;
            return;
        }
    }
    wait_for(WM_ADC);
}

