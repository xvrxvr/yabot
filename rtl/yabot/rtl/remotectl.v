`timescale 1ns / 1ps
`include "common.vh"

module RemoteCtl(
    input wire clk,
	 
	 // Connect to RC modules
    input wire [5:0] rc,
	 
	 // Write chanel
    input wire [23:0] in_data,
    input wire in_wr,
	 
	 // Read chanel
    output wire [3:0] out_ctrl,
    output wire [23:0] out_data,
    output wire out_wr, // Request to send data
    input wire out_wr_rdy // Answer - data accepted
);

localparam LEN = 17;

wire [LEN*7-1:0] data_bus;
wire [6:0] rdy;
wire [5:0] pulse_in;

reg [5:0] enable = 0;

always @(posedge clk)
    if (in_wr) enable <= in_data[5:0];

genvar i;
generate for(i=0; i<6; i=i+1)
begin :body
    CDCSync cdc(clk, rc[i], pulse_in[i]);
`ifdef SIN
    PulseMeasure #(50, 100000) pm(.clk(clk), .pulse_in(pulse_in[i]), .pulse_length(data_bus[LEN*i +: LEN]), .out_stb(rdy[i]));
`else
    PulseMeasure #(50, 900) pm(.clk(clk), .pulse_in(pulse_in[i]), .pulse_length(data_bus[LEN*i +: LEN]), .out_stb(rdy[i]));
`endif
end
endgenerate

TimeoutRC tout(.clk(clk), .enabled(enable), .signal_stb(rdy[5:0]), .data(data_bus[LEN*6 +: 6]), .data_rdy(rdy[6]));

assign data_bus[LEN*6+6 +: LEN-6] = 0;

ArbiterPulse #(.TOTAL(7), .WIDTH(LEN)) arbiter(.clk(clk), .rdy(rdy & enable), .bus_in(data_bus), .bus_out(out_data[LEN-1:0]), .out_stb(out_wr), .out_rdy(out_wr_rdy), .out_selected(out_ctrl[2:0]), .busy());

assign out_data[23:LEN] = 0;
assign out_ctrl[3] = 0;

endmodule

module TimeoutRC(
    input wire clk,

    input wire [5:0] enabled,
    input wire [5:0] signal_stb,

    output wire [5:0] data,
    output wire data_rdy
);

wire pulse;
wire [5:0] data_out;
wire data_stb = data_out != 0;

assign data = data_out;
assign data_rdy = data_stb;

Divider #(50_000_00) pre_div(.clk(clk), .reset(1'b0), .out(pulse));

genvar i;
generate for(i=0; i<6; i=i+1)
begin :body
    reg [1:0] dly = 0;
    always @(posedge clk)
        if (data_stb | signal_stb[i] | ~enabled[i]) dly <= 2'b0; else
        if (pulse) dly <= (dly<<1) | 1'b1;
    assign data_out[i] = dly[1];
end
endgenerate

endmodule

`default_nettype wire
