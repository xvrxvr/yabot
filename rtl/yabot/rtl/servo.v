`timescale 1ns / 1ps
`default_nettype none

module Servo(
    input wire clk,
	 
	 // Connect to Servo
    output wire [1:0] servo_out,
	 
	 // Write chanel
    input wire [23:0] in_data,
    input wire in_wr
);

reg [11:0] rg1 = 0;
reg [11:0] rg2 = 0;

always @(posedge clk)
    if (in_wr) {rg2, rg1} <= in_data;

//!!! PulseWidthModulator #(50, 10000) srv1(.clk(clk), .value({2'b0, rg1}), .out(servo_out[0]));
//!!! PulseWidthModulator #(50, 10000) srv2(.clk(clk), .value({2'b0, rg2}), .out(servo_out[1]));

PulseWidthModulator #(50, 100) srv1(.clk(clk), .value({2'b0, rg1}), .out(servo_out[0]));
PulseWidthModulator #(50, 100) srv2(.clk(clk), .value({2'b0, rg2}), .out(servo_out[1]));

endmodule

`default_nettype wire
