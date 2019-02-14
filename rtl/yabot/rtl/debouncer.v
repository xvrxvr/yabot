`timescale 1ns / 1ps
`default_nettype none

//module Debouncer #(parameter DELAY=1_500_000, MODE="LEVEL") 
module Debouncer #(parameter DELAY=1500, MODE="LEVEL") 
(
    input wire clk,
    input wire in_data,
    output wire out_data
);

wire inp;
reg reset = 1'b1;
reg out_d = 1'b0;
wire stb;

CDCSync cdc(clk, in_data, inp);
Divider #(DELAY) div(clk, reset, stb);

always @(posedge clk)
    if (stb) reset <= 1'b1; else
    if (reset && inp != out_d) 
    begin
        reset <= 1'b0;
        out_d <= inp;
    end

generate if (MODE == "LEVEL") 
begin :block1
    assign out_data = out_d;
end 
if (MODE == "POSEDGE") 
begin :block2    
    reg out_dly = 1'b0;

    always @(posedge clk)
        out_dly <= out_d;
    assign out_data = out_d & ~out_dly;
end
if (MODE == "NEGEDGE")
begin :block3
    reg out_dly = 1'b0;

    always @(posedge clk)
        out_dly <= out_d;
    assign out_data = ~out_d & out_dly;
end
endgenerate

endmodule
`default_nettype wire
