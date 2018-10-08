`timescale 1ns / 1ps
`default_nettype none

module Motor(
    input wire clk,
	 
	 // Connect to motors
    output wire [1:0] motor_inb,
    output wire [1:0] motor_ina,
    output wire [1:0] motor_pwm,
    input  wire [1:0] ppr_sence,
	 
	 // Write chanel
    input wire [3:0] in_ctrl,
    input wire [23:0] in_data,
    input wire in_wr,
	 
	 // Read chanel
    output wire [3:0] out_ctrl,
    output wire [23:0] out_data,
    output wire out_wr // Request to send data
);

reg [3:0] in_tag =0; // Latched input tag (in_ctrl)
reg [1:0] motor_dir =0; // Direction for Motors
reg [10:0] motor_pwm1 = 0;
reg [10:0] motor_pwm2 = 0;

assign motor_ina = motor_dir;
assign motor_inb = ~motor_dir;

reg [11:0] ppr_1 = 0; // Distance counter for Motor1
reg [11:0] ppr_2 = 0; // Distance counter for Motor2

reg [23:0] out_data_reg = 0; // Latch here output data
reg [3:0] out_tag = 0; // Latch here output 'ctrl' field
reg out_data_filled = 1'b0;

assign out_data = out_data_reg;
assign out_ctrl = out_tag;

wire [1:0] ppr; // ppr_sence after debouncer

Debouncer #(.DELAY(50000), .MODE("POSEDGE")) deb1(clk, ppr_sence[0], ppr[0]);
Debouncer #(.DELAY(50000), .MODE("POSEDGE")) deb2(clk, ppr_sence[1], ppr[1]);

// Distance counters
always @(posedge clk)
    if (in_wr) ppr_1 <= 0; else
    if (ppr[0]) ppr_1 <= ppr_1 + 1'b1;

always @(posedge clk)
    if (in_wr) ppr_2 <= 0; else
    if (ppr[1]) ppr_2 <= ppr_2 + 1'b1;

// Send accumulated counters to read channel
assign out_wr = in_wr || ppr_1 == 12'hFFF || ppr_2 == 12'hFFF;

always @(posedge clk)
    if (out_wr) begin
        out_data_reg <= {ppr_2, ppr_1};
        out_tag <= in_wr ? in_tag : 4'hF;
    end

// Motor PWM control
always @(posedge clk)
    if (in_wr) begin
        in_tag <= in_ctrl;
        {motor_dir[1], motor_pwm2, motor_dir[0], motor_pwm1} <=  in_data;
    end

PulseWidthModulator #(2, 2048) pwm1(clk, motor_pwm1, motor_pwm[0]);
PulseWidthModulator #(2, 2048) pwm2(clk, motor_pwm2, motor_pwm[1]);

endmodule
`default_nettype wire 
