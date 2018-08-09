`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:29:53 08/09/2018 
// Design Name: 
// Module Name:    Divider 
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
module Divider #(parameter N=2) 
(
    input clk,
    input reset,
    output out
);

generate 
if (N<=1)
begin :bypass
assign out = 1'b1;
end
else
begin :div

reg [$clog2(N)-1:0] div = 0;

wire top = (div == (N-1));
assign out = top;

always @(posedge clk)
	if (reset || top) div <= 0;
	else div <= div + 1'b1;
end
endgenerate
endmodule
