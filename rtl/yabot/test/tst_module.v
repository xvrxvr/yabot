`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   17:53:48 08/13/2018
// Design Name:   yabot_top
// Module Name:   C:/Users/romankh/home/yabot/github/rtl/yabot/test/tst_module.v
// Project Name:  yabot
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: yabot_top
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tst_module;

	// Inputs
	reg clk = 0;
	reg [1:0] bi_key;
	reg jetson_spi_mosi;
	reg jetson_spi_clk;
	reg jetson_spi_cs;
	reg jetson_io20;
	reg jetson_io19;
	reg jetson_io11;
	reg radio_mirq;
	reg radio_sdo;
	reg [7:0] rc;
	reg adc_do;
	reg motor1_en_diag;
	reg motor2_en_diag;
	reg [3:0] btn;
	reg xt_echo;
	reg xr1_echo;
	reg xr23_echo;
	reg xb_echo;
	reg xl12_echo;
	reg xl3_echo;
	reg [1:0] ppr_m;

	// Outputs
	wire [1:0] bi_led;
	wire dac_flt;
	wire dac_demp;
	wire dac_mute;
	wire jetson_spi_miso;
	wire jetson_io16;
	wire jetson_io9;
	wire jetson_io8;
	wire radio_msel;
	wire radio_sclk;
	wire radio_sdi;
	wire amp_stby;
	wire amp_mute;
	wire pwr_off;
	wire adc_clk;
	wire adc_di;
	wire adc_cs;
	wire motor1_inb;
	wire motor1_ina;
	wire motor1_pwm;
	wire motor2_inb;
	wire motor2_ina;
	wire motor2_pwm;
	wire [3:0] ledp;
	wire [3:0] ledm;
	wire xt_trig;
	wire xr1_trig;
	wire xr23_trig;
	wire xb_trig;
	wire xl12_trig;
	wire xl3_trig;
	wire [1:0] serv;

	// Instantiate the Unit Under Test (UUT)
	yabot_top uut (
		.clk(clk), 
		.bi_led(bi_led), 
		.bi_key(bi_key), 
		.dac_flt(dac_flt), 
		.dac_demp(dac_demp), 
		.dac_mute(dac_mute), 
		.jetson_spi_mosi(jetson_spi_mosi), 
		.jetson_spi_miso(jetson_spi_miso), 
		.jetson_spi_clk(jetson_spi_clk), 
		.jetson_spi_cs(jetson_spi_cs), 
		.jetson_io20(jetson_io20), 
		.jetson_io19(jetson_io19), 
		.jetson_io11(jetson_io11), 
		.jetson_io16(jetson_io16), 
		.jetson_io9(jetson_io9), 
		.jetson_io8(jetson_io8), 
		.radio_mirq(radio_mirq), 
		.radio_msel(radio_msel), 
		.radio_sclk(radio_sclk), 
		.radio_sdi(radio_sdi), 
		.radio_sdo(radio_sdo), 
		.amp_stby(amp_stby), 
		.amp_mute(amp_mute), 
		.pwr_off(pwr_off), 
		.rc(rc), 
		.adc_clk(adc_clk), 
		.adc_do(adc_do), 
		.adc_di(adc_di), 
		.adc_cs(adc_cs), 
		.motor1_en_diag(motor1_en_diag), 
		.motor1_inb(motor1_inb), 
		.motor1_ina(motor1_ina), 
		.motor1_pwm(motor1_pwm), 
		.motor2_en_diag(motor2_en_diag), 
		.motor2_inb(motor2_inb), 
		.motor2_ina(motor2_ina), 
		.motor2_pwm(motor2_pwm), 
		.btn(btn), 
		.ledp(ledp), 
		.ledm(ledm), 
		.xt_trig(xt_trig), 
		.xt_echo(xt_echo), 
		.xr1_trig(xr1_trig), 
		.xr1_echo(xr1_echo), 
		.xr23_trig(xr23_trig), 
		.xr23_echo(xr23_echo), 
		.xb_trig(xb_trig), 
		.xb_echo(xb_echo), 
		.xl12_trig(xl12_trig), 
		.xl12_echo(xl12_echo), 
		.xl3_trig(xl3_trig), 
		.xl3_echo(xl3_echo), 
		.ppr_m(ppr_m), 
		.serv(serv)
	);

	always #10 clk <= ~clk;

	initial begin
		// Initialize Inputs
		bi_key = 0;
		jetson_spi_mosi = 0;
		jetson_spi_clk = 0;
		jetson_spi_cs = 0;
		jetson_io20 = 0;
		jetson_io19 = 0;
		jetson_io11 = 0;
		radio_mirq = 0;
		radio_sdo = 0;
		rc = 0;
		adc_do = 0;
		motor1_en_diag = 0;
		motor2_en_diag = 0;
		btn = 0;
		xt_echo = 0;
		xr1_echo = 0;
		xr23_echo = 0;
		xb_echo = 0;
		xl12_echo = 0;
		xl3_echo = 0;
		ppr_m = 0;

		// Wait 100 ns for global reset to finish
		#100;
		
		// Add stimulus here
	
	end


        
      
endmodule

