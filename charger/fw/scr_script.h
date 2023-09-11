#pragma once
#define MSG_TOP_Y 224
#define COLOR_BLACK 0
#define COLOR2_BG 2
#define COLOR2_BAT_UDF 4
#define COLOR2_BAT_OVF 6
#define COLOR2_BAT_BAL 10
#define COLOR_VADJ_COLOR_1 14
#define COLOR_VADJ_COLOR_2 6
extern __code uint8_t screen_wait[];
extern __code uint8_t screen_nobat[];
#define SEC_OFFLINE_BAT 192, 30, 2
#define SEC_OFFLINE_BAT_NC 192, 30
#define SEC_OFFLINE_C1 152, 67, 2
#define SEC_OFFLINE_C1_NC 152, 67
#define SEC_OFFLINE_C2 152, 100, 2
#define SEC_OFFLINE_C2_NC 152, 100
#define SEC_OFFLINE_C3 152, 133, 2
#define SEC_OFFLINE_C3_NC 152, 133
#define SEC_OFFLINE_C4 152, 166, 2
#define SEC_OFFLINE_C4_NC 152, 166
extern __code uint8_t screen_offline[];
#define SEC_OFFLINE_LAST_CH_MSG_TIME 224, 224, 24
#define SEC_OFFLINE_LAST_CH_MSG_TIME_NC 224, 224
extern __code uint8_t screen_offline_last_ch_msg[];
#define SEC_OFFLINE_ABORT_MSG 149, 224, 24
#define SEC_OFFLINE_ABORT_MSG_NC 149, 224
extern __code uint8_t screen_offline_abort[];
extern __code uint8_t screen_offline_dead[];
extern __code uint8_t screen_offline_overcharge[];
#define SEC_ONLINE_INP 192, 17, 2
#define SEC_ONLINE_INP_NC 192, 17
#define SEC_ONLINE_BAT 192, 50, 2
#define SEC_ONLINE_BAT_NC 192, 50
#define SEC_ONLINE_C1 152, 87, 2
#define SEC_ONLINE_C1_NC 152, 87
#define SEC_ONLINE_C2 152, 120, 2
#define SEC_ONLINE_C2_NC 152, 120
#define SEC_ONLINE_C3 152, 153, 2
#define SEC_ONLINE_C3_NC 152, 153
#define SEC_ONLINE_C4 152, 186, 2
#define SEC_ONLINE_C4_NC 152, 186
extern __code uint8_t screen_online[];
extern __code uint8_t screen_online_start[];
#define SEC_ONLINE_LAST_CH_MSG_TIME 224, 224, 24
#define SEC_ONLINE_LAST_CH_MSG_TIME_NC 224, 224
#define screen_online_last_ch_msg screen_offline_last_ch_msg
#define SEC_ONLINE_ABORT_MSG 149, 224, 24
#define SEC_ONLINE_ABORT_MSG_NC 149, 224
#define screen_online_abort screen_offline_abort
#define screen_online_dead screen_offline_dead
#define screen_online_overcharge screen_offline_overcharge
#define SEC_CHARGE_ELAPSED 109, 224, 24
#define SEC_CHARGE_ELAPSED_NC 109, 224
#define SEC_CHARGE_INP 176, 20, 2
#define SEC_CHARGE_INP_NC 176, 20
#define SEC_CHARGE_CH_I 232, 67, 2
#define SEC_CHARGE_CH_I_NC 232, 67
#define SEC_CHARGE_CH_V 136, 67, 2
#define SEC_CHARGE_CH_V_NC 136, 67
#define SEC_CHARGE_C1 72, 109, 2
#define SEC_CHARGE_C1_NC 72, 109
#define SEC_CHARGE_C2 233, 109, 2
#define SEC_CHARGE_C2_NC 233, 109
#define SEC_CHARGE_C3 72, 144, 2
#define SEC_CHARGE_C3_NC 72, 144
#define SEC_CHARGE_C4 233, 144, 2
#define SEC_CHARGE_C4_NC 233, 144
#define PB_CHARGE 10, 186, 300, 28, 10
extern __code uint8_t screen_charge[];
#define SEC_CHARGE_ABORT_MSG 77, 224, 24
#define SEC_CHARGE_ABORT_MSG_NC 77, 224
extern __code uint8_t screen_charge_abort[];
#define SEC_CHARGE_DONE_DONE 176, 224, 24
#define SEC_CHARGE_DONE_DONE_NC 176, 224
extern __code uint8_t screen_charge_done[];
extern __code uint8_t screen_charge_cc[];
extern __code uint8_t screen_charge_cv[];
#define SEC_CHARGE_ETA_ETA_TIME 283, 224, 24
#define SEC_CHARGE_ETA_ETA_TIME_NC 283, 224
extern __code uint8_t screen_charge_eta[];
