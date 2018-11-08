`timescale 1ns / 1ps
`default_nettype none

module queue #(SIZE = 128*1024, WIDTH = 32) ();

reg [WIDTH-1:0] buffer[SIZE-1:0][15:0];

integer wr_ptr [15:0]; //= {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
integer rd_ptr [15:0]; //= {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};

integer i;

initial
begin
	for(i=0;i<16;i=i+1) 
	begin
		wr_ptr[i] = 0;
		rd_ptr[i] = 0;
	end
end

function can_read(input integer idx);
    can_read = wr_ptr[idx] != rd_ptr[idx];
endfunction

function [WIDTH-1:0] read(input integer idx);
    begin
    if (! can_read(idx))
    begin
        $display("(%0t) Queue #%d: Queue undeflow",$time,idx);
        $stop();
    end
    read = buffer[rd_ptr[idx]][idx];
    rd_ptr[idx] = (rd_ptr[idx]+1) % SIZE;
	 end
endfunction;

task write(input integer data, input integer idx);
    begin
    if ((wr_ptr[idx]+1) % SIZE == rd_ptr[idx])
    begin
        $display("(%0t) Queue #%d: Queue overflow",$time,idx);
        $stop();
    end
    buffer[wr_ptr[idx]][idx] = data;
    wr_ptr[idx] = (wr_ptr[idx]+1) % SIZE;
	 end
endtask

endmodule
