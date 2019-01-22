`timescale 1ns / 1ps
`default_nettype none

module ArbiterPulse #(parameter TOTAL=1, WIDTH=1)
(
    input  wire clk,
    input  wire [TOTAL-1:0] rdy,
    input  wire [TOTAL*WIDTH-1:0] bus_in,
    output wire [WIDTH-1:0] bus_out,
    output wire out_stb,
    input  wire out_rdy,
    output wire [$clog2(TOTAL)-1:0] out_selected,
    output wire [TOTAL-1:0] busy
);

reg [TOTAL*WIDTH-1:0] common_latch = 0; // Registers to latch bus_in values
reg [TOTAL-1:0] reg_latched = 0;        // Registers to latch requests (from rdy bus)
reg [$clog2(TOTAL)-1:0] selected;       // Latch from priority encoder
reg selected_some = 1'b0;               // Is something selected ?

assign out_selected = selected;
assign busy = reg_latched;

integer i, j;

always @(posedge clk)
    for(i=0; i<TOTAL; i=i+1) begin
        if (rdy[i]) common_latch[WIDTH*i +: WIDTH] <= bus_in[WIDTH*i +: WIDTH];
    end

always @(posedge clk)
    for(j=0; j<TOTAL; j=j+1) begin
        if (rdy[j]) reg_latched[j] <= 1'b1;
		  if (out_rdy & selected_some) begin
            selected_some <= 1'b0;
            reg_latched[selected] <= 1'b0;
        end
        if (reg_latched[j] & ~selected_some) begin
            selected_some <= 1'b1;
            selected <= j;
        end
    end

assign out_stb = selected_some & out_rdy;

assign bus_out = common_latch[WIDTH*selected +: WIDTH];

endmodule
`default_nettype wire
