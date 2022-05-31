`timescale 1ns / 1ps

module ut_chk_modif;


reg clk=1; // Clock

reg wr_stb =0;
reg [7:0] wr_addr =0;

reg in_send = 0;

wire is_modif;
wire is_modif2;

wire [7:0] modif_start;
wire [7:0] modif_end;


ModifChk #(8) dut (.clk(clk), .wr_stb(wr_stb), .wr_addr(wr_addr), .in_send(in_send), .is_modif(is_modif),  
                   .is_modif2(is_modif2), .modif_start(modif_start), .modif_end(modif_end));


initial forever #50 clk <= ~clk;

integer error_cnt =0;

integer min_addr =-1;
integer max_addr =-1;

integer sv_min_addr =-1;
integer sv_max_addr =-1;

always @(posedge in_send)
begin
 sv_min_addr = min_addr;
 sv_max_addr = max_addr;
end

always @(posedge clk)
if (in_send && (sv_min_addr!=modif_start || sv_max_addr!=modif_end))
begin
 error("Latched/real modification addresses missmatch");
 $display(">>> From module %0h-%0h, Latched/Real %0h-%0h",modif_start,modif_end,sv_min_addr,sv_max_addr);
end
task error(input [1203:0] msg);
begin
 $display("(%0t) Chk Modif ERROR: %0s",$time,msg);
 error_cnt = error_cnt+1;
end
endtask


always @(posedge in_send) $display("(%0t) Chk Modif: Send started (%0h-%0h)",$time,modif_start,modif_end);
always @(negedge in_send) $display("(%0t) Chk Modif: Send done",$time);

always @(posedge is_modif) 
 $display("(%0t) Chk Modif: Modif flag asserted (%0h-%0h)",$time,modif_start,modif_end);

always @(negedge is_modif) $display("(%0t) Chk Modif: Modif flag deasserted",$time);
always @(posedge is_modif2) $display("(%0t) Chk Modif: Modif2 flag asserted",$time);
always @(negedge is_modif2) $display("(%0t) Chk Modif: Modif2 flag deasserted",$time);

task WR;
begin
 wr_addr = $random();
 $display("(%0t) Chk Modif: Write to %0h",$time,wr_addr);
 if (min_addr == -1 || min_addr>wr_addr) min_addr=wr_addr;
 if (max_addr == -1 || max_addr<wr_addr) max_addr=wr_addr;
 wr_stb = 1;
 @(negedge clk);
 if (!is_modif) error("Modif line not asserted after WR strobe");
 wr_stb = 0;
 @(negedge clk);
end
endtask

task WRs;
integer i,j;
begin
 i=1+($unsigned($random())%20);
 for(j=0;j<i;j=j+1)
  WR;
end
endtask

task CLR;
begin
 sv_min_addr = -1;
 min_addr    = -1;
 sv_max_addr = -1;
 max_addr    = -1;
end
endtask

task CHK(input reg md, input reg md2);
begin
 if (md!=is_modif) error("Wrong Modif flag");
 if (md2!=is_modif2) error("Wrong Modif2 flag");
end
endtask

initial
begin
 $timeformat ( -9,0," ns",15);
 #2000;

 @(negedge clk);

 WRs;
 CHK(1'b1,1'b0);
 in_send = 1;
 @(negedge clk);
 @(negedge clk);
 @(negedge clk);
 in_send = 0;
 @(negedge clk);
 CHK(1'b0,1'b0);
 @(negedge clk);
 CLR;

 WRs;
 CHK(1'b1,1'b0);
 in_send = 1;
 @(negedge clk);
 @(negedge clk);
 @(negedge clk);
 in_send = 0;
 CLR;

 WRs;
 in_send = 1;
 @(negedge clk);
 @(negedge clk);
 WRs;
 @(negedge clk);
 CHK(1'b1,1'b1);
 @(negedge clk);
 in_send = 0;

 @(negedge clk);
 CHK(1'b1,1'b0);
 @(negedge clk);
 in_send = 1;
 @(negedge clk);
 @(negedge clk);
 @(negedge clk);
 in_send = 0;
 @(negedge clk);
 CHK(1'b0,1'b0);
 CLR;

 #2000;
 if (error_cnt) $display("*** Total errors - %0d",error_cnt);
 $stop;

end


endmodule
