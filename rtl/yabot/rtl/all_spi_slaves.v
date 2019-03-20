`timescale 1ns / 1ps
`include "common.vh"

module ADC(
    input wire clk,
	 
    // ADC spi
    output wire adc_cs,
    output wire adc_clk,
    output wire adc_di,
    input  wire adc_do,
    	 
	// Write chanel
    input wire [23:0] in_data,
    input wire [3:0] in_ctrl,
    input wire in_wr,
	 
	 // Read channel
    output wire [23:0] out_data,
    output wire out_wr // Request to send data
);

wire stb_rdy;
reg stb_out = 0;

// Direct run controls
wire [11:0] data;
reg [7:0] in_addr = 0;

// Sequensor
reg [9:0] dly1 = 0;
reg [9:0] dly2 = 0;
reg [5:0] max_cnt = 0;

reg seq_is_active = 1'b0;
reg seq_stb_dly = 1'b0;

wire [5:0] seq_idx;
wire seq_stb;

Sequensor #(50, 6, 10) seq(.clk(clk), .run(seq_is_active), .dly1(dly1), .dly2(dly2), .max_cnt(max_cnt), .index(seq_idx), .pulse(seq_stb));

always @(posedge clk)
    seq_stb_dly <= seq_stb;

assign out_data = {in_addr, 6'b0, data[9:0]};

always @(posedge clk)
    if (seq_is_active) 
    begin
        if (seq_stb && (seq_idx==6'd0)) in_addr <= in_addr + 1'b1;
    end 
    else 
    begin
        if (in_wr && (in_ctrl==4'd0)) in_addr <= in_data[7:0]; else
        if (in_wr && (in_ctrl==4'd9)) in_addr <= 8'hFF;
    end

always @(posedge clk)
    if (in_wr)
        case(in_ctrl)
            4'd8: {dly2, dly1} <= in_data[19:0];
            4'd9: max_cnt <= in_data[5:0];
        endcase

always @(posedge clk)
    if (in_wr) seq_is_active <= (in_ctrl == 4'd9);

SPIMaster #(.DIV(5), .TO_SPI_BITS(6), .FROM_SPI_BITS(12)) adc(.clk(clk),
    .spi_miso(adc_do), .spi_mosi(adc_di), .spi_clk(adc_clk), .spi_cs(adc_cs),
    .stb_wr(in_wr && (in_ctrl==4'd0) || seq_stb_dly), .stb_rdy(out_wr),
    .to_spi_data({3'b011, seq_is_active ? in_addr[2:0] : in_data[2:0]}), . from_spi_data(data),
    .total_len(5'd18)
);

endmodule

module Radio(
    input wire clk,
	 
    // ADC spi
    output wire radio_cs,
    output wire radio_clk,
    output wire radio_di,
    input wire radio_do,
    	 
	// Write chanel
    input wire [23:0] in_data,
    input wire [3:0] in_ctrl,
    input wire in_wr,
	 
	 // Read channel
    output wire [23:0] out_data,
    output wire out_wr // Request to send data
);

wire stb_rdy;
reg stb_out = 0;
reg ctl_img = 1'b0;

wire [11:0] data;
wire stb_wr;

assign out_wr = stb_wr & ctl_img;

always @(posedge clk)
    if (in_wr) ctl_img <= in_ctrl[0];

SPIMaster #(.DIV(5), .TO_SPI_BITS(24), .FROM_SPI_BITS(24)) radio(.clk(clk),
    .spi_miso(radio_do), .spi_mosi(radio_di), .spi_clk(radio_clk), .spi_cs(radio_cs),
    .stb_wr(in_wr), .stb_rdy(stb_wr),
    .to_spi_data(in_data), . from_spi_data(out_data),
    .total_len( {in_ctrl[2], ~in_ctrl[2], in_ctrl[1], 3'b0})
);

endmodule
`default_nettype wire
