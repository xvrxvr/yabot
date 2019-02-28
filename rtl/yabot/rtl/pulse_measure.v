`timescale 1ns / 1ps
`default_nettype none

module PulseMeasure #(parameter PREDIV=2, MAXV=1024)
(
    input wire clk,
    input wire pulse_in,
    output wire [$clog2(MAXV)-1:0] pulse_length,
	output wire ready,
	 
	output wire out_stb
);

parameter CNT_W = $clog2(MAXV);

reg [CNT_W-1:0] counter = 0;
reg [CNT_W-1:0] out_value = 0;
reg out_rdy = 0;
reg pulse_pipeline = 0;
reg out_strobe = 0;

assign out_stb = out_strobe;

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
	if (counter == MAXV-1 && pre_div_pulse) begin out_rdy <= 1'b0; out_value <= 0; end

assign pulse_length = out_value;
assign ready = out_rdy;

always @(posedge clk)
	if (pulse_end || (counter == MAXV-1 && pre_div_pulse)) out_strobe <= 1'b1;
	else out_strobe <= 1'b0;

endmodule

/*
module RCPulseMeasure(input wire clk, input wire pulse_in, output wire [9:0] pulse_length, output wire ready);


localparam DELTA = 10;

wire [$clog2(100000)-1:0] p_length;
wire rdy;

PulseMeasure #(50, 100000) pm(.clk(clk), .pulse_in(pulse_in), .pulse_length(p_length), .ready(rdy), .out_stb());

reg [9:0] out_pulse_length = 0;
reg rdy1 = 0;

wire [11:0] based_pulse_len = p_length[11:0]-12'd1500;

always @(posedge clk)
	if (p_length<(1500-1024)) out_pulse_length <= 10'h200; else
	if (p_length>(1500+1024)) out_pulse_length <= 10'h1FF; else
	if ((p_length>1500-DELTA) && (p_length<1500+DELTA)) out_pulse_length <= 0;
	else out_pulse_length <= based_pulse_len[9:0];

always @(posedge clk)
	rdy1 <= rdy;
	
assign ready = rdy1;
assign pulse_length = out_pulse_length;

endmodule
*/

`default_nettype wire 
