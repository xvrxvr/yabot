`timescale 1ns / 1ps

`define INPUT output
`define INOUT output

module test_top(
    input sys_clk,

    // On board resources
    output led_1,
    output led_2,
    input  key_1,
    input  key_2,

    // DAC control lines
    output dac_flt,
    output dac_demp,
    output dac_mute,

    // Interface to jetson
    `INPUT  jetson_spi_mosi,
    output jetson_spi_miso,
    `INPUT jetson_spi_clk,
    `INPUT jetson_spi_cs,
    // Universal GPIO
    `INOUT jetson_io20,
    `INOUT jetson_io19,
    `INOUT jetson_io11,
    // Output only GPIO
    output jetson_io16,
    output jetson_io9,
    output jetson_io8,
	
    // SI4432 interface
    `INPUT radio_mirq,
    output radio_msel,
    output radio_sclk,
    output radio_sdi,
    `INPUT radio_sdo,
	
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
    `INPUT motor1_en_diag,
    output motor1_inb,
    output motor1_ina,
    output motor1_pwm,
    `INPUT motor2_en_diag,
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
    output [1:0] serv,
	 
	 output clk_out

);

parameter DLY_CNT = 32'd50000000;
parameter HALF_DLY_CNT = 32'd25000000;

reg r_led;
reg l_led;
reg [31:0]count = 0;

//counter control
always@(posedge sys_clk)
begin
   if(count == DLY_CNT)
		begin
			count <= 32'd0;
		end
	else
		begin
			count <= count+32'd1;
		end
end

//led output register control
always@(posedge sys_clk)
begin
   if(count < HALF_DLY_CNT)
		begin
			r_led <= 1'b1;
			l_led <= 1'b0;
		end
	else
		begin
			r_led <= 1'b0;
			l_led <= 1'b1;
		end
end

assign led_1 = r_led;
assign led_2 = l_led;

/*
assign ledp[1] = btn[0];
assign ledm[2] = btn[0];

assign ledp[2] = btn[1];
assign ledm[3] = btn[1];

assign ledp[3] = btn[2];
assign ledm[0] = btn[2];

assign ledp[0] = btn[3];
assign ledm[1] = btn[3];
*/

wire [7:0] inp1 = {xt_echo, xr1_echo, xr23_echo, xb_echo, xl12_echo, xl3_echo, ppr_m};

wire [7:0] all_inps = rc ^ inp1;

assign ledp = all_inps[3:0];
assign ledm = all_inps[7:4];

// assign led_1 = ^ inp1;
// assign led_2 = ^ rc;

reg [127:0] shift_reg = 0;

wire bit0 = ~(|shift_reg);

always @(posedge sys_clk)
	if (count[15:0] == 0) shift_reg <= (shift_reg<<1) | bit0;

assign dac_flt = shift_reg[0];
assign dac_demp = shift_reg[1];
assign dac_mute = shift_reg[2];

    // Interface to jetson
assign jetson_spi_mosi = shift_reg[3];
assign jetson_spi_miso = shift_reg[4];
assign jetson_spi_clk = shift_reg[5];
assign jetson_spi_cs = shift_reg[6];
assign jetson_io20 = shift_reg[7];
assign jetson_io19 = shift_reg[8];
assign jetson_io11 = shift_reg[9];
assign jetson_io16 = shift_reg[10];
assign jetson_io9 = shift_reg[11];
assign jetson_io8 = shift_reg[12];
	
assign radio_mirq = shift_reg[13];
assign radio_msel = shift_reg[14];
assign radio_sclk = shift_reg[15];
assign radio_sdi = shift_reg[16];
assign radio_sdo = shift_reg[17];
	
assign amp_stby = 1; //shift_reg[18];
assign amp_mute = 1; //shift_reg[19];

assign pwr_off = ~key_1; // Power off switch
	
   
assign adc_clk = 0;
assign adc_di = 0;
assign adc_cs = 1;
	
assign motor1_en_diag = shift_reg[23];
assign motor1_inb = shift_reg[24];
assign motor1_ina = shift_reg[25];
assign motor1_pwm = shift_reg[26];
assign motor2_en_diag = shift_reg[27];
assign motor2_inb = shift_reg[28];
assign motor2_ina = shift_reg[29];
assign motor2_pwm = shift_reg[30];
	
assign xt_trig = r_led; //shift_reg[31];
assign xr1_trig = shift_reg[32];
assign xr23_trig = shift_reg[33];
assign xb_trig = shift_reg[34];
assign xl12_trig = shift_reg[35];
assign xl3_trig = shift_reg[36];

assign serv[0] = shift_reg[37];
assign serv[1] = shift_reg[38];

reg [18:0] cnt_10ms = 0;

always @(posedge sys_clk)
	if (cnt_10ms == 500000) cnt_10ms <= 0;
	else cnt_10ms <= cnt_10ms  + 1'b1;
	
reg clk_out_reg = 0;

always @(posedge sys_clk)
	if (cnt_10ms == 0) clk_out_reg <= 1'b1; else
	if (cnt_10ms == 75000) clk_out_reg <= 1'b0;
	
assign clk_out = clk_out_reg;

endmodule
