`timescale 1ns / 1ps

`define INOUT input

module yabot_top(
    input clk,

    // On board resources
    output [1:0] bi_led,
    input  [1:0] bi_key,

    // DAC control lines
    output dac_flt,
    output dac_demp,
    output dac_mute,

    // Interface to jetson
    input  jetson_spi_mosi,
    output jetson_spi_miso,
    input jetson_spi_clk,
    input jetson_spi_cs,
    // Universal GPIO
    `INOUT jetson_io20,
    `INOUT jetson_io19,
    `INOUT jetson_io11,
    // Output only GPIO
    output jetson_io16,
    output jetson_io9,
    output jetson_io8,
	
    // SI4432 interface
    input radio_mirq,
    output radio_msel,
    output radio_sclk,
    output radio_sdi,
    input radio_sdo,
	
    //AMP	
    output amp_stby,
    output amp_mute,

    // Power off switch
    output pwr_off,
	
    // ExtIN	Remote Control
    input  [7:0] rc,
	
    // Voltage/Curreent sence ADC	
    output adc_clk,
    input  adc_do,
    output adc_di,
    output adc_cs,
	
    // Motors control board
    input  motor1_en_diag,
    output motor1_inb,
    output motor1_ina,
    output motor1_pwm,
    input  motor2_en_diag,
    output motor2_inb,
    output motor2_ina,
    output motor2_pwm,
	
    // Buttons	
    input [3:0] btn,
	
    // LEDS	
    output [3:0] ledp,
    output [3:0] ledm,
	
    // Sonars control
    output xt_trig,
    input  xt_echo,
    output xr1_trig,
    input  xr1_echo,
    output xr23_trig,
    input  xr23_echo,
    output xb_trig,
    input  xb_echo,
    output xl12_trig,
    input  xl12_echo,
    output xl3_trig,
    input  xl3_echo,

    // Motors rotation sensors
    input [1:0] ppr_m,
	
    // Head servo control
    output [1:0] serv

);


assign bi_led= 2'b11;

assign ledp = 0;
assign ledm = 0;

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

CDCSyncN #(4) cync(.clk(clk), .in_data(rc[3:0]), .out_data(rc2));

assign serv = rc2[3:2];

wire [9:0] plen1;
wire prdy1;

wire [9:0] plen2;
wire prdy2;

RCPulseMeasure pmsr1(.clk(clk), .pulse_in(rc2[0]), .pulse_length(plen1), .ready(prdy1));
RCPulseMeasure pmsr2(.clk(clk), .pulse_in(rc2[1]), .pulse_length(plen2), .ready(prdy2));

wire [10:0] sum1 = {plen1[9],plen1} + {plen2[9],plen2};
wire [10:0] sum2 = {plen1[9],plen1} - {plen2[9],plen2};

wire [9:0] mod1 = sum1[10] ? -sum1[9:0] : sum1[9:0];
wire [9:0] mod2 = sum2[10] ? -sum2[9:0] : sum2[9:0];

PulseWidthModulator #(2, 1593) pwm1(.clk(clk), .value({1'b0,mod1}), .out(motor1_pwm));
PulseWidthModulator #(2, 1593) pwm2(.clk(clk), .value({1'b0,mod2}), .out(motor2_pwm));

wire global_enable = prdy1 & prdy2;

assign motor1_inb = global_enable & sum1[10];
assign motor1_ina = global_enable & ~sum1[10];
assign motor2_inb = global_enable & sum2[10];
assign motor2_ina = global_enable & ~sum2[10];

endmodule
