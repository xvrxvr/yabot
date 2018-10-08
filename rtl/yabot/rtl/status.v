`timescale 1ns / 1ps
`default_nettype none

module Status(
    input wire clk,
	 
	input wire [3:0] keys, 
    input wire [1:0] locks,

	 // Read chanel
    output wire [3:0] out_ctrl,
    output wire [23:0] out_data,
    output wire out_wr // Request to send data
);

wire [5:0] data;
reg [5:0] data_latch = -1;

assign out_data = {18'b0, data};
assign out_ctrl = 4'b001;

genvar i;
generate for(i=0; i<4; i=i+1)
begin :block1
    Debouncer deb(clk, ~keys[i], data[i]);
end
endgenerate

Debouncer deb2(clk, ~locks[0], data[4]);
Debouncer deb3(clk, ~locks[1], data[5]);

always @(posedge clk)
    data_latch <= data;

wire stb = data_latch != data;
wire force_stb;

Divider #(5000000) div(clk, stb, force_stb);

assign out_wr = stb | force_stb;

endmodule
`default_nettype wire 
