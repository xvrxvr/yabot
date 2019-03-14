`timescale 1ns / 1ps
`include "common.vh"

module PulseMeasure #(parameter PREDIV=2, MAXV=1024)
(
    input wire clk,
    input wire pulse_in,
    output wire [$clog2(MAXV)-1:0] pulse_length,
	 
	output wire out_stb
);

parameter CNT_W = $clog2(MAXV);

reg [CNT_W-1:0] counter = 0;
reg [CNT_W-1:0] out_value = 0;
reg pulse_pipeline = 0;
reg out_strobe = 0;

assign out_stb = out_strobe;
assign pulse_length = out_value;

wire pre_div_pulse;
wire pulse_start = pulse_in & ~pulse_pipeline;
wire pulse_end = ~pulse_in & pulse_pipeline;

Divider #(PREDIV) pre_div(.clk(clk), .reset(~pulse_in), .out(pre_div_pulse));
	
always @(posedge clk)
	pulse_pipeline <= pulse_in;
	
always @(posedge clk)
	if (pulse_start) counter <= 0; else
	if (pre_div_pulse && counter != MAXV-1) counter <= counter + 1'b1;
	
always @(posedge clk)
	if (pulse_end) out_value <= counter;

always @(posedge clk)
	out_strobe <= pulse_end;

endmodule

`default_nettype wire 
