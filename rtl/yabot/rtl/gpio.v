`timescale 1ns / 1ps
`include "common.vh"

module GPIO(
    input wire clk,
	 
    output wire [23:0] gpio_out,
	 
	 // Write chanel
    input wire [23:0] in_data,
    input wire in_wr
);

reg [23:0] gpio = 0;

always @(posedge clk)
    if (in_wr) gpio <= in_data;

assign gpio_out = gpio;

endmodule
`default_nettype wire

