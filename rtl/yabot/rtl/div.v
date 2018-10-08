`timescale 1ns / 1ps
`default_nettype none

module Divider #(parameter N=2) 
(
    input wire clk,
    input wire reset,
    output wire out
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
`default_nettype wire
