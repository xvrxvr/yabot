`timescale 1ns / 1ps
`include "common.vh"

module Sonar(
    input wire clk,
	 
	 // Connect to HC04 modules
    input wire [5:0] hc04_echo,
    output wire [5:0] hc04_trigger,
	 
	 // Write chanel
    input wire [3:0] in_ctrl,
    input wire [23:0] in_data,
    input wire in_wr,
	 
	 // Read chanel
    output wire [3:0] out_ctrl,
    output wire [23:0] out_data,
    output wire out_wr, // Request to send data
    input wire out_wr_rdy // Answer - data accepted
);

wire [5:0] ll_triggers; // Trigger wires to HC04 low level blocks
wire [5:0] ll_req; // Requests to send data back from HC04 low level blocks
wire [(6*12-1) : 0] ll_data; // Data from HC04 low level blocks (packed in 6 12bits strings)
reg  [5:0] ch_enable = 0; // Enable each separate channel

// Generate 6 instancies of block
genvar i;
generate for(i=0; i<6; i=i+1)
begin :block
	sonar_hc04 sonar(.clk(clk), 
		.hc04_echo(hc04_echo[i]), .hc04_trigger(hc04_trigger[i]),
		.trigger(ll_triggers[i]), .data_rdy(ll_req[i]),
		.data(ll_data[ i*12 +: 12 ])
	);
end
endgenerate

assign out_data[23:12] = 0;
assign out_ctrl[3] = 0;

ArbiterPulse #(.TOTAL(6), .WIDTH(12)) arbiter (.clk(clk), .rdy(ll_req & ch_enable), .bus_in(ll_data), .bus_out(out_data[11:0]), .out_stb(out_wr), .out_rdy(out_wr_rdy), .out_selected(out_ctrl[2:0]), .busy());

// Only single mesure implemented for now
assign ll_triggers = in_wr ? in_data[5:0] : 6'b0;

always @(posedge clk)
	if (in_wr) ch_enable <= in_data[5:0];
	

endmodule


module sonar_hc04(
	input wire hc04_echo,
	output wire hc04_trigger,
	
	input wire clk,

	
	input wire trigger,
	
	output wire [11:0] data,
	
	output wire data_rdy
);

reg [9:0] trig_counter = 0;

assign hc04_trigger = trig_counter != 0;

always @(posedge clk)
	if (trigger) trig_counter <= -1; else
	if (trig_counter) trig_counter <= trig_counter - 1'b1;
	
wire hc04_e;
CDCSync cdc(clk, hc04_echo, hc04_e);

PulseMeasure #(.PREDIV(5), .MAXV(4096)) pm(.clk(clk), .pulse_in(hc04_e), .pulse_length(data), .ready(), .out_stb(data_rdy));

endmodule

`default_nettype wire
