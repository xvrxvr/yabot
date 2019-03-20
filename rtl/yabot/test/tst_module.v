`timescale 1ns / 1ps

`default_nettype none

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


`define MKS *1000
`define MS *1000000

localparam ID_Nop = 0;

localparam ID_Sonars = 1;
localparam ID_Motor = 2;
localparam ID_ADC = 3;
localparam ID_Radio = 4;
localparam ID_RemoteCtrl = 5;

localparam ID_Servo = 13;
localparam ID_OutGPIO = 14;
localparam ID_PowerOff = 15;

	// Inputs
	reg clk = 0;
	reg [1:0] bi_key = 0;
	
	wire jetson_spi_mosi;
	wire jetson_spi_clk;
	wire jetson_spi_cs;
	wire jetson_io20;
	wire jetson_io19;
	reg jetson_io11 = 0;
	wire radio_mirq;
	wire radio_sdo;
	wire [7:0] rc;
	wire adc_do;
	reg motor1_en_diag = 0;
	reg motor2_en_diag = 0;
	wire [3:0] btn;
	wire xt_echo;
	wire xr1_echo;
	wire xr23_echo;
	wire xb_echo;
	wire xl12_echo;
	wire xl3_echo;
	wire [1:0] ppr_m;

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
		.clk_in(clk), 
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
		.btn(~btn), 
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

	always begin
		$timeformat ( -9,0," ns",15);
		forever
			#10 clk <= ~clk;
	end

	initial begin
		// Initialize Inputs

		// Wait 100 ns for global reset to finish
		#500;
		
		// Add stimulus here

      check_wire("dac_flt", dac_flt, 0);
		check_wire("dac_demp", dac_demp, 0);
		check_wire("dac_mute", dac_mute, 0);
		check_wire("amp_stby", amp_stby, 0);
		check_wire("amp_mute", amp_mute, 0);
		check_wire("pwr_off", pwr_off, 0);
		check_wire("jetson_io9", jetson_io9, 0);
		check_wire("jetson_io8", jetson_io8, 1);
		check_wire("motor1_inb", motor1_inb, 0);
		check_wire("motor1_ina", motor1_ina, 0);
		check_wire("motor2_inb", motor2_inb, 0);
		check_wire("motor2_ina", motor2_ina, 0);
		
		check_wire("ledp", ledp, 0);
		check_wire("ledm", ledm, 0);

//	.gpio_rd_cntreq(jetson_io11),

    		req_count(28'hC00_0000);
			jetson.expect(ID_Nop, 28'h100_0000);
         jetson.send(ID_OutGPIO, 1);
    		jetson.send(ID_Nop, 0);

			#300;
			check_wire("ledp", ledp, 1);

			# (40 `MKS);
    		req_count(28'hF00_0000);
			jetson.expect(ID_Nop, 28'hB00_0000);
			jetson.send(ID_Nop, 0);
    		jetson.send(ID_Nop, 0);

			btn1.pulse(30 `MKS + 500);
			
			# (40 `MKS);
			
    		req_count(28'hD00_0000);
			jetson.expect(ID_Nop, 28'h100_0001);
			jetson.expect(ID_Nop, 28'h100_0000);
			jetson.send(ID_Nop, 0);
			jetson.send(ID_Nop, 0);
    		jetson.send(ID_Nop, 0);
		

			// ADC
			spi_adc.expect(18'b011010_000000000000, 18'b000000_000000000101, 18);
			req_count(28'hF00_0000);
			jetson.expect(ID_Nop, 28'hB00_0000);
			jetson.expect(ID_ADC, 28'h002_0005);
			jetson.send(ID_ADC, 2);
			#200;
			jetson.send(ID_Nop, 0);
			#200;
			jetson.send(ID_Nop, 0);

            // !!! Verify ADC sequensor
			
			// RC
			jetson.expect(ID_Nop, 28'hB00_0000);
			jetson.send(ID_RemoteCtrl, 3);
			rc_gen0.run_pulses(150 `MKS + 100, 200 `MKS, 1);
			# (5 `MKS);
			req_count(28'hD00_0000);
			jetson.expect(ID_RemoteCtrl, 28'h000_0096); // 150
			jetson.send(ID_Nop, 0);
			jetson.send(ID_Nop, 0);
			jetson.expect(ID_Nop, 28'hB00_0000);
			jetson.send(ID_RemoteCtrl, 0);
			#100;
			
			// !!! Verify RC timeout
			
			
			// Sonar
			req_count(28'hF00_0000);
			#100;
			jetson.send(ID_Sonars, 63);
			# (100 `MKS);
			req_count(28'hD00_2000);
			jetson.send(ID_Nop, 0);			
			jetson.expect(ID_Sonars, 28'h500_000a);
			jetson.expect(ID_Sonars, 28'h400_000a);
			jetson.expect(ID_Sonars, 28'h300_000a);
			jetson.expect(ID_Sonars, 28'h200_000a);
			jetson.expect(ID_Sonars, 28'h100_000a);
			jetson.expect(ID_Sonars, 28'h000_000a);
			jetson.send(ID_Sonars, 0);
			jetson.send(ID_Nop, 0);
			jetson.send(ID_Nop, 0);
			jetson.send(ID_Nop, 0);
			jetson.send(ID_Nop, 0);
			jetson.send(ID_Nop, 0);
			
			// !!! Verify sonar timeout
            // !!! Verify sonar sequensor

			// Servo
			req_count(28'hF00_0000);
			jetson.send(ID_Servo, 28'h0_00A_00A);
			#200;
			srv1.check_pulse(10 `MKS - 100, 10 `MKS + 100);
			srv2.check_pulse(10 `MKS - 100, 10 `MKS + 100);
			jetson.expect(ID_Nop, 28'hB00_0000);
			jetson.send(ID_Servo, 28'h0_00A_000);
			srv1.check_level(0);
			srv2.check_pulse(10 `MKS - 100, 10 `MKS + 100);
			
			// Motor + PPR
			req_count(28'hF00_0000);			
			jetson.send(ID_Motor, 28'h1_8FF_4FF);
			#200;
			fork
				check_wire("motor1_inb", motor1_inb, 1);
				check_wire("motor1_ina", motor1_ina, 0);
				check_wire("motor2_inb", motor2_inb, 0);
				check_wire("motor2_ina", motor2_ina, 1);
				ppr_gen1.run_pulses(1 `MKS, 2 `MKS, 10);
				ppr_gen2.run_pulses(1 `MKS, 2 `MKS, 20);
				motor1.check_pwm(61,63);
				motor2.check_pwm(11,13);
			join
			#200;
			req_count(28'hD00_0000);			
			jetson.expect(ID_Motor, 28'h0_000_000);
			jetson.send(ID_Nop, 0);
			jetson.send(ID_Motor, 28'h2_000_000);
			#200;
			req_count(28'hD00_0000);			
			jetson.expect(ID_Motor, 28'h1_014_00A);
			jetson.send(ID_Nop, 0);
			jetson.send(ID_Nop, 0);
			
						
			// Radio
			req_count(28'hF00_0000);
			spi_radio.expect(32'h0000_55AA, 32'h1234_5678, 16);
			jetson.send(ID_Radio, 28'h1_55_AA_00);
			#400;
			req_count(28'hF00_0000);
			jetson.expect(ID_Radio, 28'h0_00_12_34);
			jetson.send(ID_Nop, 0);
			jetson.send(ID_Nop, 0);

			req_count(28'hF00_0000);
			spi_radio.expect(32'h0000_55AA, 32'h1234_5678, 16);
			jetson.send(ID_Radio, 28'h0_55_AA_00);
			#400;
			req_count(28'hF00_0000);
			jetson.expect(ID_Nop, 28'hB_00_00_00);
			jetson.send(ID_Nop, 0);
			jetson.send(ID_Nop, 0);
			

			req_count(28'hF00_0000);
			spi_radio.expect(32'h005A5AEE, 32'h9ABC_DEF0, 24);
			jetson.send(ID_Radio, 28'h3_5A_5A_EE);
			#800;
			req_count(28'hF00_0000);
			jetson.expect(ID_Radio, 28'h0_9A_BC_DE);
			jetson.send(ID_Nop, 0);
			jetson.send(ID_Nop, 0);

			req_count(28'hF00_0000);
			spi_radio.expect(32'h005A5AEE, 32'h9ABC_DEF0, 24);
			jetson.send(ID_Radio, 28'h2_5A_5A_EE);
			#800;
			req_count(28'hF00_0000);
			jetson.expect(ID_Nop, 28'hB_00_00_00);
			jetson.send(ID_Nop, 0);
			jetson.send(ID_Nop, 0);


			req_count(28'hF00_0000);
			spi_radio.expect(32'hDEAD_BE00, 32'h1020_3040, 32);
			jetson.send(ID_Radio, 28'h5_DE_AD_BE);
			#1200;
			req_count(28'hF00_0000);
			jetson.expect(ID_Radio, 28'h0_20_30_40);
			jetson.send(ID_Nop, 0);
			jetson.send(ID_Nop, 0);

			req_count(28'hF00_0000);
			spi_radio.expect(32'hDEAD_BE00, 32'h1020_3040, 32);
			jetson.send(ID_Radio, 28'h4_DE_AD_BE);
			#1200;
			req_count(28'hF00_0000);
			jetson.expect(ID_Nop, 28'hB_00_00_00);
			jetson.send(ID_Nop, 0);
			jetson.send(ID_Nop, 0);
			
			
			// PWR off
			check_wire("PWR OFF", pwr_off, 0);
			jetson.expect(ID_Nop, 28'hB_00_00_00);
			jetson.send(ID_PowerOff, 2);
			#900;
			check_wire("PWR OFF", pwr_off, 0);
			jetson.expect(ID_Nop, 28'hB_00_00_00);
			jetson.send(ID_PowerOff, 2);
			#1100;
			check_wire("PWR OFF", pwr_off, 1);
			
			
		$stop();
	
	end

adapter_btn #("BTN1") btn1 (btn[0]);
adapter_btn #("BTN2") btn2 (btn[1]);
adapter_btn #("BTN3") btn3 (btn[2]);
adapter_btn #("BTN4") btn4 (btn[3]);

adapter_echo #("XT") echo_xt(xt_echo, xt_trig);
adapter_echo #("XR1") echo_xr1(xr1_echo, xr1_trig);
adapter_echo #("XR23") echo_xr23(xr23_echo, xr23_trig);
adapter_echo #("XB") echo_xb(xb_echo, xb_trig);
adapter_echo #("XL12") echo_xl12(xl12_echo, xl12_trig);
adapter_echo #("XL3") echo_xl3(xl3_echo, xl3_trig);

adapter_master_spi jetson(jetson_spi_clk,jetson_spi_mosi,jetson_spi_miso,jetson_spi_cs);

adapter_pwm #("SERV1") srv1(serv[0]);
adapter_pwm #("SERV2") srv2(serv[1]);
adapter_pwm #("MOTOR1") motor1(motor1_pwm);
adapter_pwm #("MOTOR2") motor2(motor2_pwm);

adapter_slave_spi #("RADIO", 32) spi_radio(radio_sclk, radio_sdi, radio_sdo, radio_msel);
adapter_slave_spi #("ADC", 18) spi_adc(adc_clk, adc_di, adc_do, adc_cs);

pgen_adapter #("RC1") rc_gen0(rc[0]);
pgen_adapter #("RC2") rc_gen1(rc[1]);
pgen_adapter #("RC3") rc_gen2(rc[2]);
pgen_adapter #("RC4") rc_gen3(rc[3]);
pgen_adapter #("RC5") rc_gen4(rc[4]);
pgen_adapter #("RC6") rc_gen5(rc[5]);

pgen_adapter #("PPR1") ppr_gen1(ppr_m[0]);
pgen_adapter #("PPR2") ppr_gen2(ppr_m[1]);

task check_wire(input [87:0] name, input bit_val, input org_val);
begin
if (bit_val!==org_val)
begin
	$display("Error (%0t) %s: Wrong value %0h (%0h expected)", $time, name, bit_val, org_val);
	$stop();
end
$display("(%0t) %s: %0h", $time, name, bit_val);
end
endtask


task req_count(input [27:0] data);
begin
    jetson_io11 <= ~jetson_io11;
    #100;
    jetson.expect(ID_Nop, data);
end
endtask
      
endmodule

