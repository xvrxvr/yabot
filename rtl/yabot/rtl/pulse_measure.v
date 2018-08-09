`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:55:42 08/08/2018 
// Design Name: 
// Module Name:    PulseMeasure 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module PulseMeasure #(parameter PREDIV=2, MAXV=1024)
(
    input clk,
    input pulse_in,
    output [$clog2(MAXV)-1:0] pulse_length,
	 output ready
);

parameter CNT_W = $clog2(MAXV);

reg [CNT_W-1:0] counter = 0;
reg [CNT_W-1:0] out_value = 0;
reg out_rdy = 0;
reg pulse_pipeline = 0;

wire pre_div_pulse;
wire pulse_start = pulse_in & ~pulse_pipeline;
wire pulse_end = ~pulse_in & pulse_pipeline;

Divider #(PREDIV) pre_div(.clk(clk), .reset(pulse_start), .out(pre_div_pulse));
	
always @(posedge clk)
	pulse_pipeline <= pulse_in;
	
always @(posedge clk)
	if (pulse_start) counter <= 0; else
	if (pre_div_pulse)
	begin
		if (counter != MAXV-1) counter <= counter + 1'b1;
		else counter <= 0;
	end	
	
always @(posedge clk)
	if (pulse_end) begin out_value <= counter; out_rdy <= 1'b1; end else
	if (counter == MAXV-1) out_rdy <= 1'b0;

assign pulse_length = out_value;
assign ready = out_rdy;

endmodule

module RCPulseMeasure(input clk, input pulse_in, output [9:0] pulse_length, output ready);


localparam DELTA = 10;

wire [$clog2(100000)-1:0] p_length;
wire rdy;

PulseMeasure #(50, 100000) pm(.clk(clk), .pulse_in(pulse_in), .pulse_length(p_length), .ready(rdy));

reg [9:0] out_pulse_length = 0;
reg rdy1 = 0;

always @(posedge clk)
	if (p_length<(1500-1024)) out_pulse_length <= 10'h200; else
	if (p_length>(1500+1024)) out_pulse_length <= 10'h1FF; else
	if ((p_length>1500-DELTA) && (p_length<1500+DELTA)) out_pulse_length <= 0;
	else out_pulse_length <= {(p_length[11:0]-12'd1500)}[9:0];

always @(posedge clk)
	rdy1 <= rdy;
	
assign ready = rdy1;
assign pulse_length = out_pulse_length;

endmodule
