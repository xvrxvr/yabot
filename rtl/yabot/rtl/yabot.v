`timescale 1ns / 1ps
`include "common.vh"

`define INOUT input

module yabot_top(
    input wire clk_in,

    // On board resources
    output wire [1:0] bi_led,
    input  wire [1:0] bi_key,

    // DAC control lines
    output wire dac_flt,
    output wire dac_demp,
    output wire dac_mute,

    // Interface to jetson
    input  wire jetson_spi_mosi,
    output wire jetson_spi_miso,
    input wire jetson_spi_clk,
    input wire jetson_spi_cs,
    // Universal GPIO
    `INOUT wire jetson_io20,
    `INOUT wire jetson_io19,
    input wire jetson_io11,
    // Output only GPIO
    output wire jetson_io16,
    output wire jetson_io9,
    output wire jetson_io8,
	
    // SI4432 interface
    input wire radio_mirq,
    output wire radio_msel,
    output wire radio_sclk,
    output wire radio_sdi,
    input wire radio_sdo,
	
    //AMP	
    output wire amp_stby,
    output wire amp_mute,

    // Power off switch
    output wire pwr_off,
	
    // ExtIN	Remote Control
    input  wire [7:0] rc,
	
    // Voltage/Curreent sence ADC	
    output wire adc_clk,
    input  wire adc_do,
    output wire adc_di,
    output wire adc_cs,
	
    // Motors control board
    input  wire motor1_en_diag,
    output wire motor1_inb,
    output wire motor1_ina,
    output wire motor1_pwm,
    input  wire motor2_en_diag,
    output wire motor2_inb,
    output wire motor2_ina,
    output wire motor2_pwm,
	
    // Buttons	
    input wire [3:0] btn,
	
    // LEDS	
    output wire [3:0] ledp,
    output wire [3:0] ledm,
	
    // Sonars control
    output wire xt_trig,
    input  wire xt_echo,
    output wire xr1_trig,
    input  wire xr1_echo,
    output wire xr23_trig,
    input  wire xr23_echo,
    output wire xb_trig,
    input  wire xb_echo,
    output wire xl12_trig,
    input  wire xl12_echo,
    output wire xl3_trig,
    input  wire xl3_echo,

    // Motors rotation sensors
    input wire [1:0] ppr_m,
	
    // Head servo control
    output wire [1:0] serv

);
wire clk_200;
wire clk;

dcm dcm200(clk_in, clk_200, clk);

assign bi_led = 0;

// Jetson -> core buses
wire [3:0]  wr_addr;
wire [3:0]  wr_ctrl;
wire [23:0] wr_data;
wire wr_stb;

// Core -> Jetson buses
wire [3:0]  rd_addr;
wire [27:0] rd_data;
wire rd_stb;

SPIJetson spi_jetson(
    .clk(clk), 
	 .clk_200(clk_200),

	// SPI (Jetson) interface
   .spi_clk(jetson_spi_clk),
   .spi_mosi(jetson_spi_mosi),
   .spi_miso(jetson_spi_miso),
   .spi_cs(jetson_spi_cs),


	.gpio_rd_valid(jetson_io8),
	.gpio_rd_urgent(jetson_io9),
	.gpio_rd_cntreq(jetson_io11),
	 
	// Internal connection
	// Write side (core -> jetson)
	.wr_en(rd_stb),
	.wr_din({rd_addr, rd_data}),
	
	// Read side (jetson -> core)
	.rd_en(1'b1),
	.rd_rdy(wr_stb),
	.rd_dout({wr_addr, wr_ctrl, wr_data})
);

localparam MAX_OUT_CHS = 6; // Total modules with write output capability

// Packs of readback (core -> Jetson) buses
wire [MAX_OUT_CHS*28-1 : 0] rb_data;
wire [MAX_OUT_CHS-1    : 0] rb_reqs;
wire [MAX_OUT_CHS-1    : 0] rb_busy;

ArbiterPulse #(MAX_OUT_CHS, 28) arb(.clk(clk), .rdy(rb_reqs), .bus_in(rb_data), .bus_out(rd_data), .out_stb(rd_stb), .out_rdy(1'b1), .out_selected(rd_addr[2:0]), .busy(rb_busy));
assign rd_addr[3] = 0;

// Connection helpers
`define IN(idx)     .clk(clk), .in_data(wr_data), .in_wr(wr_stb && wr_addr == idx)
`define IN_C(idx)   `IN(idx), .in_ctrl(wr_ctrl)
`define OUT(idx)    .out_data(rb_data[idx*28 +: 24]), .out_wr(rb_reqs[idx])
`define OUT_C(idx)  `OUT(idx), .out_ctrl(rb_data[idx*28+24 +: 4])
`define OUT_CA(idx) `OUT_C(idx), .out_wr_rdy(~rb_busy[idx])
`define OUT_IDX(idx) assign rb_data[idx*28+24 +: 4] = 4'b0;
`define OUT_IDX1(idx, data) assign rb_data[idx*28+24 +: 4] = data;

// Direct control
wire direct_disable;
wire [16:0] direct_rc1, direct_rc2;
wire direct_rc_active;
wire direct_active = direct_rc_active & ~direct_disable;
wire [11:0] direct_motor1, direct_motor2;
wire [1:0] local_serv;
wire direct_l1;
assign serv = direct_active ? rc[3:2] : local_serv;

DC dc(.rc1(direct_rc1), .rc2(direct_rc2), .motor1(direct_motor1), .motor2(direct_motor2));

// Modules
Status  status(.clk(clk), `OUT(0),  .keys(btn), .locks({motor1_en_diag, motor2_en_diag}));
`OUT_IDX1(0, 4'b1)
Sonar   sonar(`IN_C(1),   `OUT_CA(1), .hc04_echo({xt_echo,xr1_echo,xr23_echo,xb_echo,xl12_echo,xl3_echo}), .hc04_trigger({xt_trig,xr1_trig,xr23_trig,xb_trig,xl12_trig,xl3_trig}));
Motor   motor(`IN_C(2),   `OUT_C(2),  .motor_inb({motor2_inb,motor1_inb}), .motor_ina({motor2_ina,motor1_ina}), .motor_pwm({motor2_pwm,motor1_pwm}), 
              .ppr_sence(ppr_m), .direct_m1(direct_motor1), .direct_m2(direct_motor2), .direct_enable(direct_active));
ADC       adc(`IN_C(3),   `OUT(3),    .adc_cs(adc_cs), .adc_clk(adc_clk), .adc_di(adc_di), .adc_do(adc_do));
`OUT_IDX(3)
Radio   radio(`IN_C(4),   `OUT(4),    .radio_cs(radio_msel), .radio_clk(radio_sclk), .radio_di(radio_sdi), .radio_do(radio_sdo));
`OUT_IDX(4)
RemoteCtl rct(`IN(5),     `OUT_CA(5), .rc(rc[5:0]), .direct_ch1(direct_rc1), .direct_ch2(direct_rc2), .direct_active(direct_rc_active));
Servo   servo(`IN(13),  .servo_out(local_serv));
GPIO     gpio(`IN(14),  .gpio_out({direct_disable,amp_mute,amp_stby,dac_mute,dac_demp,dac_flt,ledm[3],ledp[3],ledm[2],ledp[2],ledm[1],ledp[1],ledm[0],direct_l1}));
PowerOff poff(`IN(15),  .pwr_off(pwr_off));

assign jetson_io16 = radio_mirq;
assign ledp[0] = direct_l1 | direct_active;

endmodule

module DC(input wire [16:0] rc1, input wire [16:0] rc2, output wire [11:0] motor1, output wire [11:0] motor2);

wire [9:0] rc1_p = PulseLenCvt(rc1);
wire [9:0] rc2_p = PulseLenCvt(rc2);

/*                                rc2
   rc1            <0 (left)        |      >0 (right)
>0 (forw)   m1=rc1+rc2; m2=rc1     |   m1=rc1; m2=rc1-rc2
=0 (stall)  m1=rc1+rc2; m2=rc1-rc2 |   m1=rc2; m2=rc1-rc2
<0 (back)   m1=rc1-rc2; m2=rc1     |   m1=rc1; m2=rc1+rc2
*/

wire [9:0] rc_add = Add(rc1_p, rc2_p);
wire [9:0] rc_sub = Add(rc1_p, -rc2_p);

wire rc2_sign = rc2_p[9];
wire rc1_sign = rc1_p[9];
wire rc1_zero = rc1_p == 0;

wire [9:0] m1 = rc2_sign ? (rc1_sign ? rc_sub : rc_add ) : (rc1_zero ? rc2_p : rc1_p);
wire [9:0] m2 = rc2_sign ? (rc1_zero ? rc_sub : rc1_p) : (rc1_sign ? rc_add : rc_sub);

assign motor1 = Ext(m1);
assign motor2 = Ext(m2);

localparam DELTA = 10;

function automatic [9:0] PulseLenCvt(input [16:0] p_length);
begin
   if (p_length<990) PulseLenCvt = 10'h201; else
	if (p_length>2011) PulseLenCvt = 10'h1FF; else
	if ((p_length>1500-DELTA) && (p_length<1500+DELTA)) PulseLenCvt = 0;
	else PulseLenCvt = {(p_length[9:0]-10'd1500)};
end    
endfunction;

function automatic [9:0] Add(input [9:0] a, b);
reg [10:0] add;
begin
    add = {a[9], a} + {b[9], b};
    if (add[10] == add[9]) Add = add[9:0];
    else Add = {9 {add[10]}};
end
endfunction;

function automatic [11:0] Ext(input [9:0] data);
begin
    Ext[11] = data[9];
	 Ext[1:0] = {2 {data[0]}};
	 Ext[10:2] = data[9] ? -(data[8:0]) : data[8:0];
end
endfunction;



endmodule


/*
assign bi_led= 2'b11;

assign dac_flt = 0;
assign dac_demp = 0;
assign dac_mute = 1;

    // Interface to jetson
assign jetson_spi_miso = 0;

assign jetson_io16 = 0;
assign jetson_io9 = 0;
assign jetson_io8 = 0;
	
assign radio_msel = 1;
assign radio_sclk = 0;
assign radio_sdi = 0;
	
assign amp_stby = 0;
assign amp_mute = 0;

assign pwr_off = ~bi_key[0]; // Power off switch
	
   
assign adc_clk = 0;
assign adc_di = 0;
assign adc_cs = 1;
	
// assign motor1_inb = 0;
// assign motor1_ina = 0;
// assign motor1_pwm = 0;
// assign motor2_inb = 0;
// assign motor2_ina = 0;
// assign motor2_pwm = 0;
	
assign xt_trig = 0;
assign xr1_trig = 0;
assign xr23_trig = 0;
assign xb_trig = 0;
assign xl12_trig = 0;
assign xl3_trig = 0;

wire [3:0] rc2;

CDCSyncN #(4) cync(.clk(clk), .in_data({rc[3:2], rc[5], rc[4]}), .out_data(rc2));

assign serv = rc2[3:2];

wire [9:0] plen1;
wire prdy1;

wire [9:0] plen2;
wire prdy2;

RCPulseMeasure pmsr1(.clk(clk), .pulse_in(rc2[0]), .pulse_length(plen1), .ready(prdy1));
RCPulseMeasure pmsr2(.clk(clk), .pulse_in(rc2[1]), .pulse_length(plen2), .ready(prdy2));

wire [10:0] plen1_ext = {plen1[9],plen1};
wire [10:0] plen2_ext = {plen2[9],plen2};

wire [10:0] sum1 = plen1_ext + plen2_ext;
wire [10:0] sum2 = plen1_ext - plen2_ext;

wire [9:0] mod1 = sum1[10] ? (-sum1[9:0]) : sum1[9:0];
wire [9:0] mod2 = sum2[10] ? (-sum2[9:0]) : sum2[9:0];

wire m1_pwm, m2_pwm;

PulseWidthModulator #(2, 1593) pwm1(.clk(clk), .value({1'b0,mod1}), .out(m1_pwm));
PulseWidthModulator #(2, 1593) pwm2(.clk(clk), .value({1'b0,mod2}), .out(m2_pwm));

assign motor1_pwm = m1_pwm;
assign motor2_pwm = m2_pwm;

wire global_enable = prdy1 & prdy2;

assign m1_inb = global_enable & sum1[10];
assign m1_ina = global_enable & ~sum1[10];
assign m2_inb = global_enable & sum2[10];
assign m2_ina = global_enable & ~sum2[10];

assign motor1_inb = m1_ina;
assign motor1_ina = m1_inb;
assign motor2_inb = m2_ina;
assign motor2_ina = m2_inb;

assign ledp = {mod2!=0, mod1!=0, m2_ina & m2_pwm, m1_ina & m1_pwm};
assign ledm = {1'b0, 1'b0, m2_inb & m2_pwm, m1_inb & m1_pwm};

*/
`default_nettype wire 
