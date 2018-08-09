`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:48:42 08/09/2018 
// Design Name: 
// Module Name:    CDCSync 
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
module CDCSync #(parameter STAGES=2)
(
    input clk,
    input in_data,
    output out_data
);

reg [STAGES-1:0] dly_reg = 0;

always @(posedge clk)
	dly_reg <= (dly_reg<<1) | in_data;
	
assign out_data = dly_reg[STAGES-1];

endmodule

module CDCSyncN #(parameter N=1, STAGES=2)
(
    input clk,
    input [N-1:0] in_data,
    output [N-1:0] out_data
);
genvar i;
generate for(i=0; i<N; i=i+1)
begin :body
	CDCSync #(STAGES) sync(.clk(clk), .in_data(in_data[i]), .out_data(out_data[i]));
end
endgenerate

endmodule
