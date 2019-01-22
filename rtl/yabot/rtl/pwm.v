`timescale 1ns / 1ps
`default_nettype none

module PulseWidthModulator #(parameter PREDIV=2, TOP=1024)
(
    input wire clk,
    input wire [$clog2(TOP)-1:0] value,
    output wire out
);

parameter CNT_W = $clog2(TOP);

reg [CNT_W-1:0] counter = 0;
reg [CNT_W-1:0] value_latch = 0;
reg out_reg = 0;

wire prediv_pulse;

Divider #(PREDIV) pre_div(.clk(clk), .reset(1'b0), .out(prediv_pulse));

always @(posedge clk)
	if (prediv_pulse)
	begin
		if (counter != TOP-1) counter <= counter + 1'b1; else
		begin
			counter <= 0;
			value_latch <= value;
		end
	end

always @(posedge clk)
	if (value_latch == counter) out_reg <= 0; else
	if (counter == 0) out_reg <= 1;
	
assign out = out_reg;

endmodule
`default_nettype wire
