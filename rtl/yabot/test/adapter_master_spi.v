`timescale 1ns / 1ps
`default_nettype none

module adapter_master_spi(
   output reg spi_clk,
   output wire spi_mosi,
   input wire spi_miso,
   output reg spi_cs
);

localparam BUF_SIZE = 128*1024;
reg [31:0] spi_data_out = 0;
reg [28:0] status_reg  = 0;

assign spi_mosi = spi_data_out[31];

initial begin
	spi_clk = 1'b0;
	spi_cs = 1'b1;
end

genvar i;
generate for(i=0; i<16; i=i+1)
begin :block
queue #("MASTER-SPI-EXPECTED", BUF_SIZE, 28) expected_queue();
end
endgenerate

task expect(input integer index, input integer data);
    block[index].expected_queue.write(data);
endtask

task send(input integer index, input integer data);
    integer acc;
    integer i;

    begin
    spi_data_out = data | (index << 28);
    spi_cs = 1'b0;
	 acc = 0;
    #50;

    for(i=0; i<32; i=i+1)
    begin
        #25;
        spi_clk = 1'b1;
        #25;
        acc = (acc<<1) | spi_miso;
    end

    #50;
    spi_cs = 1'b1;

    index = (acc >> 28) & 15;
    acc = acc & 32'h0FFFFFFF;

    if (index==0 && !block[0].expected_queue.can_read())
    begin
        if (status_reg != acc)
        begin
            $display("(%0t) Jetson SPI #0: Unexpected - shadow reg is %h, got %h",$time,status_reg,acc);
            $stop();
        end
    end
    else if (!block[index].expected_queue.can_read())
    begin
        $display("(%0t) Jetson SPI #%d: Underflow (got data %h)",$time,index,acc);
        $stop();
    end
    else
    begin
        i = block[index].expected_queue.read();
        if (i != acc)
        begin
            $display("(%0t) Jetson SPI #%d: Unexpected - expected %h, got %h",$time,index,i,acc);
            $stop();
        end
    end

    if (index==0) status_reg = acc;
	 end
endtask


endmodule
