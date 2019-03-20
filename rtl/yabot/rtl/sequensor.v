`timescale 1ns / 1ps
`include "common.vh"

module Sequensor #(parameter DIV = 50000, WIDTH = 8, DLY_WIDTH = 8) (
    input wire clk,
    input wire run,

    input wire [DLY_WIDTH-1:0] dly1,
    input wire [DLY_WIDTH-1:0] dly2,
    input wire [WIDTH-1:0] max_cnt,
    
    output wire [WIDTH-1:0] index,
    output wire pulse
);

reg [DLY_WIDTH-1:0] dly_count = 0;
reg [WIDTH-1:0] idx = 0;
wire stb;

wire last_idx = idx == max_cnt;
wire switch_index = dly_count >= (last_idx ? dly2 : dly1);

assign index = idx;
assign pulse = stb && (dly_count == 0);

Divider #(DIV) prediv(.clk(clk), .reset(~run || ((dly1|dly2) == 0)), .out(stb));

always @(posedge clk)
    if (~run) dly_count <= 0; else
    if (stb) begin
        if (switch_index) begin
            if (last_idx) idx <= 0; 
            else idx <= idx + 1'b1;
            dly_count <= 0;
        end else begin
            dly_count <= dly_count + 1'b1;
        end
    end

endmodule

