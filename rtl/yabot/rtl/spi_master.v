`timescale 1ns / 1ps
`default_nettype none

module SPIMaster #(parameter DIV=50, TO_SPI_BITS=8, FROM_SPI_BITS=8)
(
    input wire clk,

    input wire spi_miso,
    output wire spi_mosi,
    output wire spi_clk,
    output wire spi_cs,

    input wire stb_wr,
    output wire stb_rdy,

    input wire [TO_SPI_BITS-1:0] to_spi_data,
    output wire [FROM_SPI_BITS-1:0] from_spi_data,

    input wire [$clog2(TO_SPI_BITS+FROM_SPI_BITS)-1:0] total_len
);

reg [TO_SPI_BITS-1:0] to_spi = 0;
reg [(TO_SPI_BITS+FROM_SPI_BITS)-1:0] from_spi = 0;
wire clk_ff; // SPI 2CLK
reg clk_out = 1'b0; // SPI clock
reg cs = 1'b0; // SPI CS (reclocked to SPI SLK)
reg cs_raw = 1'b0; // SPI CS not reclocked to SPI CLK
reg rdy = 1'b0;
reg [$clog2(TO_SPI_BITS+FROM_SPI_BITS)-1: 0] bit_counter = 0; // SPI bit counter

wire leading_edge = ~cs & ~clk_out & clk_ff; // Tick before leading edge
wire falling_edge = ~cs & clk_out & clk_ff; // Tick before falling edge

Divider #(DIV/2) divider(.clk(clk), .reset(1'b0), .out(clk_ff));

// SPI clock
always @(posedge clk)
    if (clk_ff) clk_out <= ~clk_out;

// Module -> SPI datapath
always @(posedge clk)
    if (stb_wr) to_spi <= to_spi_data; else
    if (falling_edge) to_spi <= to_spi << 1;

// Module <- SPI datapath
always @(posedge clk)
    if (leading_edge) from_spi <= (from_spi<<1) | spi_miso;

// SPI CS
always @(posedge clk)
    if (stb_wr) cs_raw <= 1'b1; else
    if (!bit_counter) cs_raw <= 1'b0;

always @(posedge clk)
    if (clk_ff & clk_out) cs <= cs_raw; 

// bit counter
always @(posedge clk)
    if (stb_wr) bit_counter <= total_len; else
    if (falling_edge) bit_counter <= bit_counter - 1'b1;

// output data strobe
always @(posedge clk)
    if (falling_edge & (bit_counter == 1)) rdy <= 1'b1;
    else rdy <= 1'b0;

// Output
assign spi_clk = !cs & clk_out;
assign spi_cs = !cs;
assign spi_mosi = to_spi[TO_SPI_BITS-1];
assign from_spi_data = from_spi[TO_SPI_BITS +: FROM_SPI_BITS];
assign stb_rdy = rdy;

endmodule
`default_nettype wire
