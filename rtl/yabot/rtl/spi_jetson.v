`timescale 1ns / 1ps
`default_nettype none

module SPIJetson(
	// SPI (Jetson) interface
   input wire spi_clk,
   input wire spi_mosi,
   output wire spi_miso,
   input wire spi_cs,
	
	output wire gpio_rd_valid, // SPI -> Host status
	output wire gpio_rd_urgent,
	input wire gpio_rd_cntreq, // Host->SPI - request CNT value
	 
	// Internal connection
	input wire clk,
	
	// Write side (core -> jetson)
	input wire wr_en,
	input wire [31:0] wr_din,
	
	// Read side (jetson -> core)
	input wire rd_en,
	output wire rd_rdy,
	output wire [31:0] rd_dout
);

/////////////// SPI -> core part /////////////////////////////////////

reg [31:0] input_reg = 0; // Input data register
wire spi_cs_to_clk; // Resync of spi_cs to clk domain


always @(posedge spi_clk)
	input_reg <= (input_reg<<1) | spi_mosi;

CDCSync spi_cs_sync(clk, spi_cs, spi_cs_to_clk);

reg sctc_dly = 0; // spi_cs_to_clk delayed by 1 clock
always @(posedge clk)
	sctc_dly <= spi_cs_to_clk;
	
fifo32short spi2core_fifo(.wr_clk(clk), .rd_clk(clk), .din(input_reg), .wr_en(spi_cs_to_clk & ~sctc_dly & (input_reg[31:28]!=0)),
  .rd_en(rd_en), .dout(rd_dout), .valid(rd_rdy),
  .full(), .empty()
);


///////////// core -> SPI ////////////////////////////////////////////

reg [31:0] output_reg = 0; // Output reg
reg [10:0] status_reg = 0; // Shadow Status register value
reg first_bit = 1'b1; // Set to 1 for first bit of SPI transaction
reg req_words_ff = 1'b0;

wire has_data; // Do we have something to read?
wire fifo_empty; // Is FIFO empty?
wire [31:0] fifo_data; // data from fifo
wire [12:0] fifo_data_cnt; // data count

wire req_words = req_words_ff ^ gpio_rd_cntreq;

always @(posedge spi_clk)
	req_words_ff <= gpio_rd_cntreq;

// Set 'first_bit' only for first spi_cs clock after leading endge of spi_cs
always @(posedge spi_clk or negedge spi_cs)
	if (!spi_cs) first_bit <= 1'b1; 
	else first_bit <= 1'b0;

fifo32 core2spi_fifo(.wr_clk(clk), .rd_clk(spi_clk), .din(wr_din), .wr_en(wr_en),
  .rd_en(first_bit), .dout(fifo_data), .valid(has_data),
  .full(), .empty(fifo_empty), .prog_full(gpio_rd_urgent),
  .rd_data_count(fifo_data_cnt)  
);
assign gpio_rd_valid = ~fifo_empty;

// manage SPI data register
always @(posedge spi_clk)
	if (!first_bit) output_reg <= output_reg << 1; else // Shift register (not first spi clock)
	if (!has_data || req_words) output_reg <= {4'b0, 3'b111, has_data , fifo_data_cnt, status_reg}; // Load register - shadow status (because no data in FIFO)
	else output_reg <= fifo_data; // Data from FIFO

assign spi_miso = output_reg[31];

// Manage Shadow status register
always @(posedge spi_clk)
	if (!first_bit && fifo_data[31:28]==0)
		status_reg <= fifo_data[12:0];

endmodule
`default_nettype wire 
