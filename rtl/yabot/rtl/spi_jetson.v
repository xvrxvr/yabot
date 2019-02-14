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
	input wire clk_200,
	
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
reg [31:0] input_reg_l = 0; // Input data register
wire spi_cs_to_clk; // Resync of spi_cs to clk domain


always @(posedge spi_clk)
	input_reg <= (input_reg<<1) | spi_mosi;

always @(posedge spi_cs)
	input_reg_l <= input_reg;

CDCSync spi_cs_sync(clk, spi_cs, spi_cs_to_clk);

reg sctc_dly = 0; // spi_cs_to_clk delayed by 1 clock
always @(posedge clk)
	sctc_dly <= spi_cs_to_clk;
	
fifo32short spi2core_fifo(.wr_clk(clk), .rd_clk(clk), .din(input_reg_l), .wr_en(spi_cs_to_clk & ~sctc_dly & (input_reg_l[31:28]!=0)),
  .rd_en(rd_en), .dout(rd_dout), .valid(rd_rdy),
  .full(), .empty()
);


///////////// core -> SPI ////////////////////////////////////////////
wire data_send_done; // Done data sending wia SPI (last bit now sent)
wire data_send_latched; // Data to send was successfully latched into send register

//////////////////////////////
// 200 MHz domain

// Signals reflected to this domain from others:
wire spi_cs_200;
wire req_word_200;
wire data_send_done_200;
wire data_send_latched_200;

// This domain local signals

// FIFO interface
wire fifo_empty_200; // Is FIFO empty?
wire [31:0] fifo_data_200; // data from fifo
wire [12:0] fifo_data_cnt_200; // data count

reg req_word_ff_200 = 1'b0;

// Select data to output to SPI
reg outsel_stat_200 = 1'b0; // Select ShadowStatus+FifoCounter
reg outsel_fifo_200 = 1'b0; // Select FIFO Data to output
wire stb_stat_200 = (req_word_ff_200 ^ req_word_200) & spi_cs_200; // Strobe to latch 1 -> outsel_stat_200

wire rd_en_200 = data_send_done_200 & ~outsel_fifo_200 & ~fifo_empty_200; // Allow read from FIFO

// Shadow status register
reg [10:0] shadow_status_reg_200 = 0; // Shadow Status register value
reg status_reg_ok_200 = 1'b0;

// Output data path for SPI
reg [12:0] shadow_cnt_reg_200 = 0; // Shadow FIFO Counter value
wire [31:0] output_mux_200 = // Output data
	outsel_stat_200 ? {4'b0, 1'b1, 1'b1, !outsel_fifo_200, status_reg_ok_200, shadow_cnt_reg_200, shadow_status_reg_200} :
	outsel_fifo_200 ? fifo_data_200 : {4'b0, 1'b1, 1'b0, !outsel_fifo_200, status_reg_ok_200, shadow_cnt_reg_200, shadow_status_reg_200};
	
reg [31:0] output_reg_200 = 0;

always @(posedge clk_200)
	output_reg_200 <= output_mux_200;

// Cross domain sync and clocks
CDCSync sync_cs(clk_200, spi_cs, spi_cs_200);
CDCSync sync_req_word(clk_200, gpio_rd_cntreq, req_word_200);
CDCSyncPulse sync_ds_done(clk_200, data_send_done, data_send_done_200);
CDCSyncPulse sync_ds_latched(clk_200, data_send_latched, data_send_latched_200);

always @(posedge clk_200)
	if (stb_stat_200)
		req_word_ff_200 <= req_word_200;

// Manage Status read request
always @(posedge clk_200)
	if (stb_stat_200)
	begin
		outsel_stat_200 <= 1'b1;
		shadow_cnt_reg_200 <= fifo_data_cnt_200;
	end
	else if (data_send_latched_200)
		outsel_stat_200 <= 1'b0;

// Manage FIFO read request
always @(posedge clk_200)
	if (rd_en_200)	outsel_fifo_200 <= 1'b1; else 
	if (data_send_latched_200 & ~outsel_stat_200) outsel_fifo_200 <= 1'b0;

fifo32 core2spi_fifo(.wr_clk(clk), .rd_clk(clk_200), .din(wr_din), .wr_en(wr_en),
  .rd_en(rd_en_200), .dout(fifo_data_200),
  .full(), .empty(fifo_empty_200), .prog_full(gpio_rd_urgent),
  .rd_data_count(fifo_data_cnt_200)
);
assign gpio_rd_valid = ~fifo_empty_200;

// Manage Shadow status register
always @(posedge clk_200)
	if (rd_en_200 && fifo_data_200[31:28]==0)
	begin
		shadow_status_reg_200 <= fifo_data_200[12:0];
		status_reg_ok_200 <= 1'b1;
	end

/////////////////////////////////////////
// SPI output clock domain
reg [30:0] output_reg = 0; // Output reg
reg first_bit = 1'b1; // Set to 1 for first bit of SPI transaction
reg first_bit2 = 1'b0; // Set to 1 for first bit of SPI transaction
reg [4:0] out_bits_cnt = 0; // Count of in/out SPI clocks

// Set 'first_bit' only for first spi_cs clock (after first falling edge) after leading endge of spi_cs
always @(negedge spi_clk or posedge spi_cs)
	if (spi_cs) first_bit <= 1'b1; 
	else first_bit <= 1'b0;

// Latch/shift output register
always @(negedge spi_clk)
	if (first_bit) output_reg <= output_reg_200[30:0]; 
	else output_reg <= output_reg << 1;
	
assign spi_miso = first_bit ? output_reg_200[31] : output_reg[30];

always @(negedge spi_clk)
	if (first_bit) out_bits_cnt <= 0; else 
	if (!spi_cs) out_bits_cnt <= out_bits_cnt + 1'b1;
	
assign data_send_done = out_bits_cnt == 5'd30;

always @(negedge spi_clk)
	first_bit2 <= first_bit;
	
assign data_send_latched = first_bit2;


endmodule
`default_nettype wire 
