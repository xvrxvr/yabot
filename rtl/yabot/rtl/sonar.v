`timescale 1ns / 1ps
`include "common.vh"

module Sonar(
    input wire clk,
	 
	 // Connect to HC04 modules
    input wire [5:0] hc04_echo,
    output wire [5:0] hc04_trigger,
	 
	 // Write chanel
    input wire [3:0] in_ctrl,
    input wire [23:0] in_data,
    input wire in_wr,
	 
	 // Read chanel
    output wire [3:0] out_ctrl,
    output wire [23:0] out_data,
    output wire out_wr, // Request to send data
    input wire out_wr_rdy // Answer - data accepted
);

wire [5:0] ll_triggers; // Trigger wires to HC04 low level blocks
wire [6:0] ll_req; // Requests to send data back from HC04 low level blocks
wire [(7*12-1) : 0] ll_data; // Data from HC04 low level blocks (packed in 6 12bits strings)
wire start;  // Start measure cycle

// Generate 6 instancies of block
genvar i;
generate for(i=0; i<6; i=i+1)
begin :block
	sonar_hc04 sonar(.clk(clk), 
		.hc04_echo(hc04_echo[i]), .hc04_trigger(hc04_trigger[i]),
		.trigger(ll_triggers[i]), .data_rdy(ll_req[i]),
		.data(ll_data[ i*12 +: 12 ])
	);
end
endgenerate

Timeout tout(.clk(clk), .start_stb(start), .enabled(in_data[5:0]), .done(ll_req[5:0]), .data(ll_data[6*12 +: 12]), .data_rdy(ll_req[6]));

assign out_data[23:12] = 0;
assign out_ctrl[3] = 0;

ArbiterPulse #(.TOTAL(7), .WIDTH(12)) arbiter (.clk(clk), .rdy(ll_req), .bus_in(ll_data), .bus_out(out_data[11:0]), .out_stb(out_wr), .out_rdy(out_wr_rdy), .out_selected(out_ctrl[2:0]), .busy());

////////////// Sequensor support
reg [19:0] seq_times = 0;
reg [1:0]  seq_total = 0;
reg [23:0] seq_scale = 0;
reg seq_running = 1'b0;
wire [1:0] seq_index;
wire seq_pulse;

always @(posedge clk)
    if (in_wr)
        if (in_ctrl == 4'hF) begin seq_times <= in_data[19:0]; seq_running <= 1'b1; end else
        begin
            seq_running <= 1'b0;
            if (in_ctrl >= 1 && in_ctrl <= 4) begin seq_total <= in_ctrl-1'b1; seq_scale <= in_data; end
        end

Sequensor #(50000, 2, 10) seq(.clk(clk), .run(seq_running), .dly1(seq_times[9:0]), .dly2(seq_times[19:10]), .max_cnt(seq_total), .index(seq_index), .pulse(seq_pulse));

// Only single mesure implemented for now
wire signle_run = in_wr && in_ctrl == 0;
assign ll_triggers = signle_run ? in_data[5:0] : seq_pulse ? seq_scale[seq_index*6 +: 6] :  6'b0;
assign start = signle_run | seq_pulse;


endmodule


module sonar_hc04(
	input wire hc04_echo,
	output wire hc04_trigger,
	
	input wire clk,
	input wire trigger,
	output wire [11:0] data,
	output wire data_rdy
);

reg [9:0] trig_counter = 0;

assign hc04_trigger = trig_counter != 0;

always @(posedge clk)
	if (trigger) trig_counter <= -1; else
	if (trig_counter) trig_counter <= trig_counter - 1'b1;
	
wire hc04_e;
CDCSync cdc(clk, hc04_echo, hc04_e);

PulseMeasure #(.PREDIV(5), .MAXV(4096)) pm(.clk(clk), .pulse_in(hc04_e), .pulse_length(data), .out_stb(data_rdy));

endmodule

module Timeout(
    input wire clk,

    input wire start_stb,
    input wire [5:0] enabled,
    input wire [5:0] done,

    output wire [11:0] data,
    output wire data_rdy
);

reg [5:0] active_waits = 0;
wire tout;

assign data = {6'b0, active_waits};
assign data_rdy = tout;

Divider #(21000) prediv(.clk(clk), .reset(active_waits == 6'b0), .out(tout));

always @(posedge clk)
    if (start_stb) active_waits <= enabled; else
    if (tout) active_waits <= 6'b0;
    else active_waits <= active_waits & ~done;

endmodule

`default_nettype wire
