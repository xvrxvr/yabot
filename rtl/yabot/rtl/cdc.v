`timescale 1ns / 1ps
`default_nettype none

module CDCSync #(parameter STAGES=2)
(
    input wire clk,
    input wire in_data,
    output wire out_data
);

reg [STAGES-1:0] dly_reg = 0;

always @(posedge clk)
	dly_reg <= (dly_reg<<1) | in_data;
	
assign out_data = dly_reg[STAGES-1];

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
