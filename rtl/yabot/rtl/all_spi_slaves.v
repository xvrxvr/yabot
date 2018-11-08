`timescale 1ns / 1ps
`default_nettype none

module ADC(
    input wire clk,
	 
    // ADC spi
    output wire adc_cs,
    output wire adc_clk,
    output wire adc_di,
    input  wire adc_do,
    	 
	// Write chanel
    input wire [23:0] in_data,
    input wire in_wr,
	 
	 // Read channel
    output wire [23:0] out_data,
    output wire out_wr // Request to send data
);

wire stb_rdy;
reg stb_out = 0;

wire [11:0] data;
reg [7:0] in_addr = 0;
assign out_data = {in_addr, 6'b0, data[9:0]};

always @(posedge clk)
    if (in_wr) in_addr <= in_data[7:0];

SPIMaster #(.DIV(5), .TO_SPI_BITS(6), .FROM_SPI_BITS(12)) adc(.clk(clk),
    .spi_miso(adc_do), .spi_mosi(adc_di), .spi_clk(adc_clk), .spi_cs(adc_cs),
    .stb_wr(in_wr), .stb_rdy(out_wr),
    .to_spi_data({3'b010, in_data[2:0]}), . from_spi_data(data),
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
reg [3:0] ctl_img = 0;

wire [11:0] data;

always @(posedge clk)
    if (in_wr) ctl_img <= in_ctrl;

SPIMaster #(.DIV(5), .TO_SPI_BITS(24), .FROM_SPI_BITS(24)) radio(.clk(clk),
    .spi_miso(radio_do), .spi_mosi(radio_di), .spi_clk(radio_clk), .spi_cs(radio_cs),
    .stb_wr(in_wr), .stb_rdy(out_wr),
    .to_spi_data(in_data), . from_spi_data(out_data),
    .total_len( {ctl_img[2], ~ctl_img[2], ctl_img[1], 3'b0})
);

endmodule
`default_nettype wire
