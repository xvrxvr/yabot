`timescale 1ns / 1ps
`include "common.vh"

module CDCSync #(parameter STAGES=2, DEF=0)
(
    input wire clk,
    input wire in_data,
    output wire out_data
);

reg [STAGES-1:0] dly_reg = DEF;

always @(posedge clk)
	dly_reg <= (dly_reg<<1) | in_data;
	
assign out_data = dly_reg[STAGES-1];

endmodule

module CDCSyncPulse #(parameter STAGES=2)
(
    input wire clk,
    input wire in_data,
    output wire out_data
);

wire d1;
reg d2 = 1'b1;
reg out_d = 1'b0;

CDCSync #(STAGES) cdc(clk, in_data, d1);

always @(posedge clk)
	d2 <= d1;

always @(posedge clk)
    out_d <= d1 & ~d2;

assign out_data = out_d;

endmodule


/*
module CDCSyncN #(parameter N=1, STAGES=2)
(
    input wire clk,
    input wire [N-1:0] in_data,
    output wire [N-1:0] out_data
);
`default_nettype none

genvar i;
generate for(i=0; i<N; i=i+1)
begin :body
	CDCSync #(STAGES) sync(.clk(clk), .in_data(in_data[i]), .out_data(out_data[i]));
end
endgenerate

endmodule
*/
`default_nettype wire
