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

queue #(BUF_SIZE, 28) expected_queue();

task expect(input integer index, input integer data);
    expected_queue.write(data, index);
endtask

task send(input integer index, input integer data);
    integer acc;
    integer i;
	 realtime time_start;
	 integer data2send;

    begin
	 time_start = $realtime;
	 data2send = data | (index << 28);
    spi_data_out = data2send;
    spi_cs = 1'b0;
	 acc = 0;
    #50;

    for(i=0; i<32; i=i+1)
    begin
        #25;
        spi_clk = 1'b1;
        #25;
        acc = (acc<<1) | spi_miso;
		  spi_clk = 1'b0;
		  spi_data_out = spi_data_out << 1;
    end

    #50;
    spi_cs = 1'b1;
	 #100;

    $write("(%0t - %0t) Jetson: %h => [SPI] => %h", time_start, $realtime, data2send, acc);
    index = (acc >> 28) & 15;
    acc = acc & 32'h0FFFFFFF;
	 
	 if (index==0)
	 begin
		$write("      CTRL Decode: ");
		if (acc[27]) $write("Shadow, ");
		if (acc[26]) $write("CntReq, ");
		if (acc[25]) $write("Empty, ");
		if (acc[24]) $write("Valid, ");
		$write("%0d words in FIFO", acc[23:11]);
	 end
    $display("");

    if (index==0 && !expected_queue.can_read(0))
    begin
        if (status_reg != acc)
        begin
            $display("Error (%0t) Jetson SPI #0: Unexpected - shadow reg is %0h, got %0h",$time,status_reg,acc);
            $stop();
        end
    end
    else if (!expected_queue.can_read(index))
    begin
        $display("Error (%0t) Jetson SPI #%d: Underflow (got data %0h)",$time,index,acc);
        $stop();
    end
    else
    begin
        i = expected_queue.read(index);
        if (i != acc)
        begin
            $display("Error (%0t) Jetson SPI #%0d: Unexpected - expected %0h, got %0h",$time,index,i,acc);
            $stop();
        end
    end

    if (index==0) status_reg = acc;
    end
endtask


endmodule
