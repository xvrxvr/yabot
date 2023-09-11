#include "common.h"
#include "scr_script.h"

// Max V value is ~70 (17.0-10)*10
// So max buddy is 256+70
#define MAX_BUDDY 356

static __xdata uint16_t cc_cv_data[512];
//    uint16_t cc_voltage[256];   // 1024 bytes  - organized in one array
//    uint16_t cv_current[256];   // contains time stamp + 1 (in 1sec granularity)
static __xdata uint16_t cc_cv_buddy[MAX_BUDDY]; // Opposite to cc_cv_data (for graph drawing)


static uint8_t eeprom_idx; // Where to place new ETM values (valid - 0-2)


static __idata uint8_t eeprom_cache[4]; // Place to read data from EEPROM

////////////

static void read_eeprom_page(uint16_t page)
{
    EADRH = page >> 8;
    EADRL = (uint8_t)page;
    ECON = 1;
    eeprom_cache[0] = EDATA1;
    eeprom_cache[1] = EDATA2;
    eeprom_cache[2] = EDATA3;
    eeprom_cache[3] = EDATA4;
}

static void write_eeprom_page(uint16_t page)
{
    EADRH = page >> 8;
    EADRL = (uint8_t)page;
    ECON = 5;
    EDATA1 = eeprom_cache[0];
    EDATA2 = eeprom_cache[1];
    EDATA3 = eeprom_cache[2];
    EDATA4 = eeprom_cache[3];
    ECON = 2;
}

static uint8_t get_value(uint16_t page)
{
    uint8_t tmp;
#define SWAP(a, b) if (a > b) {tmp=a; a=b; b=tmp;}
#define X eeprom_cache[0]
#define Y eeprom_cache[1]
#define Z eeprom_cache[2]
    read_eeprom_page(page);
    // bubble sort unrolled
    SWAP(X, Y);
    SWAP(Y, Z)
    SWAP(X, Y);
#undef SWAP
    if (Y == 0xFF) return X; // Only 1 data entry or no data (X is FF in this case)
    if (Z != 0xFF) return Y; // Median
    return (X+Y) >> 1; // Average
#undef X
#undef Y
#undef Z
}

static void put_value(uint16_t page, uint8_t value)
{
    uint8_t i;
    read_eeprom_page(page);
    for(i=0; i<3; ++i) if (eeprom_cache[i] == 0xFF) {eeprom_cache[i] = value; break;}
    if (i==3) eeprom_cache[eeprom_idx] = value;
    write_eeprom_page(page);
}
////////////


static void abt_charge(char* message)
{
    charge_off();
    FAN_OFF();
    abort_message = message;
    lcd_draw_script(screen_charge_abort);
    lcd_text(abort_message, SEC_CHARGE_ABORT_MSG);
    eeprom_idx = 0xFF; // SIgnal to suppress storing of ETA time update
}

static uint8_t vadj_backoff;

static void update_vadj(void)
{
    vadj_backoff = CSI_VAdjBackoff;
    mcp_set();
    /*
    if (mcp_set())
    {
        current_mode = MD_Online;
        abt_charge("V Charge adjust failure");
        return;
    }
    */
    // 320-255 = 65
    lcd_box(65, (uint8_t)(MSG_TOP_Y-1), mcp_current_value, 1, COLOR_VADJ_COLOR_1);
    if (mcp_current_value!=0xFF)
    {
        lcd_box(65+mcp_current_value, (uint8_t)(MSG_TOP_Y-1), mcp_current_value^0xFF, 1, COLOR_VADJ_COLOR_2);
    }
}

static __idata char eta_timer[5]; // h:mm

void run_charge_mode()
{
    uint8_t backoff = CSI_StartBackoff;
    uint8_t h=0, m=0, s=0;
    uint16_t total_time = 0;
    uint16_t tmp2, tmp3;
    uint8_t last_eta = 0xFF;

    ch_timer[7] = ch_timer[0] = 0;
    ch_timer[4] = '.';
    eta_timer[1] = ':';

    memset(cc_cv_data, 0, sizeof(cc_cv_data));
    memset(cc_cv_buddy, 0, sizeof(cc_cv_buddy));

    read_eeprom_page(0);
    eeprom_idx = eeprom_cache[3];
    if (eeprom_idx > 2) eeprom_idx = 0;

    charge_on();
    abort_message = NULL;
    lcd_draw_script(screen_charge);
    update_vadj();
    while(current_mode == MD_Charging)
    {
        fill_adc_info();
        draw_bat_cells(bat_charge);
        lcd_text2(str_20v(adc_info.full_bat_v), SEC_CHARGE_CH_V);
        lcd_text2(str_20v(vc_20v(ext_adc_values[VI_Input])), SEC_CHARGE_INP);
        lcd_text2(str_2v(adc_info.charge_bat_i), SEC_CHARGE_CH_I);

        uint8_t tmp = detect_current_mode();
        if (tmp!=MD_Online)
        {
            current_mode=tmp;
            abt_charge("Power off");
            break;
        }

        uint8_t keys = wait_for(WM_ADC|BT_Keys|BT_1Hz);
        // Charge time
        if (keys&BT_1Hz)
        {
            ++total_time;
            ++s;
            if (s>=60)
            {
                ++m; s=0;
                if (m>=60) {++h; m=0;}
            }
            ch_timer[6] = (s%10) + '0';
            ch_timer[5] = (s/10) + '0';
            ch_timer[3] = (m%10) + '0';
            ch_timer[2] = m>=10 || h ? (m/10) + '0' : ' ';
            if (h)
            {
                ch_timer[1] = ':';
                ch_timer[0] = h + '0';
            }
            else
            {
                ch_timer[1] = ' ';
                ch_timer[0] = ' ';
            }
            lcd_text(ch_timer, SEC_CHARGE_ELAPSED);
        }
        // Track data for future ETM analyse
        if (adc_info.adc_flags&AF_CV)
        {
            tmp2 = 0x100 | adc_info.charge_bat_i;
            tmp3 = 0x100 | adc_info.full_bat_v;
            if (tmp3 >= MAX_BUDDY) tmp3 = MAX_BUDDY - 1;
        }
        else
        {
            tmp3 = adc_info.charge_bat_i;
            tmp2 = adc_info.full_bat_v;
        }
        if (!cc_cv_data[tmp2]) 
        {
            cc_cv_data[tmp2] = cc_cv_buddy[tmp3] = total_time + 1;

            // Write ETA
            tmp = get_value(tmp2);
            if (tmp != 0xFF && last_eta != tmp)
            {
                if (last_eta == 0xFF) lcd_draw_script(screen_charge_eta);
                eta_timer[0] = (tmp/60) + '0'; tmp %= 60;
                eta_timer[2] = (tmp/10) + '0';
                eta_timer[3] = (tmp%10) + '0';
                lcd_text(eta_timer, SEC_CHARGE_ETA_ETA_TIME);
                last_eta = tmp;

                //!!! Emit Progress Bar
            }
        }
        if (total_time >= 254*60) // timeout
        {
            current_mode=MD_Online;
            abt_charge("Timeout");
            break;
        }

        // Handle long key press (-> Abort charging)
        if (keys&BT_Long)
        {
            current_mode=MD_Online;
            abt_charge("Aborted by user");
            break;
        }
        //!!! Handle key press (-> Graph mode)

        if (!(keys&WM_ADC)) continue;

        if (backoff) --backoff;
        if (backoff) continue;

        if (ext_adc_values[VI_CurrentSence] < LIM_MinCharge)
        {
            current_mode=MD_NoBat;
            abt_charge("Battery decsonnected");
            break;
        }

        // Detect Charge done
        if (adc_info.charge_bat_i <= CST_IOff)
        {
            lcd_draw_script(screen_charge_done);
            lcd_text(ch_timer, SEC_CHARGE_DONE_DONE);
            current_mode=MD_Online;
            break;
        }

        // FAN on/off
        if (adc_info.charge_bat_i >= CSI_FanOn) FAN_ON(); else
        if (adc_info.charge_bat_i <= CSI_FanOff) FAN_OFF();

        // Draw CC/CV flag
        if (adc_info.adc_flags&AF_CV)
        {
            lcd_draw_script(screen_charge_cv);

            // Adjust V Charge to be 16.8V
            if (vadj_backoff) --vadj_backoff; else
            if (ext_adc_values[VI_FullBat] >= CSI_MaxVAdjRAW && mcp_current_value) {--mcp_current_value; update_vadj();} else
            if (ext_adc_values[VI_FullBat] <= CSI_BigMinVAdjRAW) {if (mcp_current_value<0xF0) mcp_current_value+=0x10; else mcp_current_value=0xFF; update_vadj();} else
            if (ext_adc_values[VI_FullBat] <= CSI_MinVAdjRAW && mcp_current_value!=0xFF) {++mcp_current_value; update_vadj();}
        }
        else
        {
            lcd_draw_script(screen_charge_cc);
            vadj_backoff = CSI_VAdjBackoff;
        }
    }
    charge_off();
    FAN_OFF();

    //Store current charge info for future estimates
    if (eeprom_idx != 0xFF)
    {
        uint16_t cnt;
        if (++eeprom_idx > 2) eeprom_idx = 0;
        for(cnt = 0; cnt < 512; ++cnt)
            if (cc_cv_data[cnt])
            {
                read_eeprom_page(cnt);
                if (cnt == 0) eeprom_cache[3] = eeprom_idx;
                put_value(cnt, (total_time - cc_cv_data[cnt] + 31) / 60);
            }
        if (cc_cv_data[0] == 0)
        {
            read_eeprom_page(0);
            eeprom_cache[3] = eeprom_idx;
            write_eeprom_page(0);
        }
    }
    wait_for(WM_ADC);
    wait_for(WM_ADC);
}

void on_init()
{
    uint16_t i;
    for(i=0; i<512; ++i)
    {
        read_eeprom_page(i);
        send_raw(eeprom_cache[0]);
        send_raw(eeprom_cache[1]);
        send_raw(eeprom_cache[2]);
        send_raw(eeprom_cache[3]);
    }
}
