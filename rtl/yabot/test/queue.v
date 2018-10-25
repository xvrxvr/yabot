`timescale 1ns / 1ps
`default_nettype none

module queue #(parameter NAME="", SIZE = 128*1024, WIDTH = 32) ();

reg [WIDTH-1:0] buffer[SIZE-1:0];

integer wr_ptr = 0;
integer rd_ptr = 0;

function can_read(input integer i);
    can_read = wr_ptr != rd_ptr;
endfunction

function [WIDTH-1:0] read(input integer i);
    begin
    if (! can_read(0))
    begin
        $display("(%0t) %s: Queue undeflow",$time,NAME);
        $stop();
    end
    read = buffer[rd_ptr];
    rd_ptr = (rd_ptr+1) % SIZE;
	 end
endfunction;

task write(input integer data);
    begin
    if ((wr_ptr+1) % SIZE == rd_ptr)
    begin
        $display("(%0t) %s: Queue overflow",$time,NAME);
        $stop();
    end
    buffer[wr_ptr] = data;
    wr_ptr = (wr_ptr+1) % SIZE;
	 end
endtask

endmodule
