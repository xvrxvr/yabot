`timescale 1ns / 1ps
`default_nettype none

module PowerOff(
    input wire clk,
	 
    output wire pwr_off,
	 
	 // Write chanel
    input wire [23:0] in_data,
    input wire in_wr
);

reg [15:0] downcounter =0;
reg power_off = 1'b0;
wire stb;

assign pwr_off = power_off;

Divider #(5000000) div(clk, 1'b0, stb);

always @(posedge clk)
    if (in_wr) downcounter <= in_data[15:0]; else
    if (stb && downcounter != 0) begin
        downcounter <= downcounter - 1'b1;
        if (downcounter == 1) power_off <= 1'b1;
    end

endmodule
`default_nettype wire 
