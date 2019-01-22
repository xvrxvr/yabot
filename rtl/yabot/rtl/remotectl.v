`timescale 1ns / 1ps
`default_nettype none

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

wire [LEN*6-1:0] data_bus;
wire [5:0] rdy;

reg [5:0] enable = 0;

always @(posedge clk)
    if (in_wr) enable <= in_data[5:0];

genvar i;
generate for(i=0; i<6; i=i+1)
begin :body
    wire pulse_in;
    CDCSync cdc(clk, rc[i], pulse_in);
    PulseMeasure #(50, 100000) pm(.clk(clk), .pulse_in(pulse_in), .pulse_length(data_bus[LEN*i +: LEN]), .ready(), .out_stb(rdy[i]));
end
endgenerate

ArbiterPulse #(.TOTAL(6), .WIDTH(LEN)) arbiter(.clk(clk), .rdy(rdy & enable), .bus_in(data_bus), .bus_out(out_data[LEN-1:0]), .out_stb(out_wr), .out_rdy(out_wr_rdy), .out_selected(out_ctrl[2:0]), .busy());

assign out_data[23:LEN] = 0;
assign out_ctrl[3] = 0;

endmodule
`default_nettype wire
