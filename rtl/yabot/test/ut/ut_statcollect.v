`timescale 1ns / 1ps
`default_nettype none

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    20:53:00 04/02/2010 
// Design Name: 
// Module Name:    ut_statcollect 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module ut_statcollect();

reg clk =0;
reg clk4 =0;

initial begin
 #10;
 forever #20 clk <= ~clk;
end

initial begin
 #25;
 forever #5 clk4 <= ~clk4;
end

reg [61:0] stat = 1'b0;
reg ram_blk_sel = 1'b0;

StatCollect dut(.clk(clk), .clk4(clk4),
 .stat_i(stat),
 .ram_blk_sel_i(ram_blk_sel),          // Selector of working block for statistics accumulator

// Interface to internal RAM 
 .ram_addr_i(9'b0),
 .ram_data_i(32'b0),
 .ram_data_o(),
 .ram_cs_i(1'b0),
 .ram_we_i(1'b0)
);

task automatic gen_burst(input wire [31:0] min_len, input wire [31:0] max_len);
integer blen;
integer i;
reg [61:0] dat;
begin
 blen=min_len+($unsigned($random())%(max_len-min_len+1));
 @(posedge clk);
 for(i=0;i<blen;i=i+1)
  begin
   dat[30:0] = $random();
   dat[61:31] = $random();
   stat <= dat;
   $display("(%0t) Stat: %h",$time(),dat);
   collect_dat(dat);
   @(posedge clk); 
  end
 stat <= 32'h0;
end
endtask


reg [31:0] acc_img [0:255];

task automatic CLR_ACC;
integer i;
begin
for(i=0;i<256;i=i+1) acc_img[i] = 0;
for(i=0;i<512;i=i+1) dut.pram.mem[i] = 0;
end
endtask


task automatic collect_dat(input wire [61:0] data);
integer j;
reg [3:0] i;
begin
for(i=0;i<15;i=i+1)
 if (data[i*4 +: 4] != 0)
  begin
   j={i,data[i*4 +: 4]};
   acc_img[j]=acc_img[j]+1;
  end
end
endtask

integer errors = 0;

task automatic error(input wire [1023:0] msg);
begin
 $display("(%0t) ***Error***: %0s",$time(),msg);
 errors=errors+1;
end
endtask

task automatic CHK_MEM(input wire [1:0] mode);
reg [8:0] i;
reg tr=1'b0;
integer acc =0, l_min=0, l_max=0;

begin
if (dut.pram.mem[9'hf4] || dut.pram.mem[9'h1f4])
 $display("(%0t) Semi Overflow Detected: %0d/%0d",$time(),dut.pram.mem[9'hf4],dut.pram.mem[9'h1f4]);
if (dut.pram.mem[9'hfc] || dut.pram.mem[9'h1fc])
begin
$display("(%0t) Overflow detected: %0d/%0d",$time(),dut.pram.mem[9'hfc],dut.pram.mem[9'h1fc]);
for(i=0;i<240;i=i+1)
 case(mode)
  0: if (acc_img[i] < dut.pram.mem[i])
      begin
       if (!tr) begin error("Reversed memory count detected:"); tr=1'b1; end
       $display(" * Org[%h] = %0d, Mem[%h] = %0d",i[7:0],acc_img[i],i,dut.pram.mem[i]);
      end
     else acc=acc+(acc_img[i]-dut.pram.mem[i]);
  1: if (acc_img[i] < dut.pram.mem[256+i])
      begin
       if (!tr) begin error("Reversed memory count detected:"); tr=1'b1; end
       $display(" * Org[%h] = %0d, Mem[1%h] = %0d",i[7:0],acc_img[i],i,dut.pram.mem[i+256]);
      end
     else acc=acc+(acc_img[i]-dut.pram.mem[i+256]);  
  2: if (acc_img[i] < (dut.pram.mem[256+i]+dut.pram.mem[i])) 
       begin
        if (!tr) begin error("Reversed memory count detected:"); tr=1'b1; end
        $display(" * Org[%h] = %0d, Mem[%h/1%h] = %0d/%0d",i[7:0],acc_img[i],
         i,dut.pram.mem[i],
         i,dut.pram.mem[i+256]);
       end
     else acc=acc+(acc_img[i]-(dut.pram.mem[i+256]+dut.pram.mem[i]));
 endcase        
$display(" * Real Drop=%0d",acc);
for(i=240;i<256;i=i+1)
 $display("Mem[%h/1%h] = %0d/%0d",i,i,dut.pram.mem[i],dut.pram.mem[i+256]);
tr=1'b1;
end
else
for(i=0;i<240;i=i+1)
 case(mode)
  0: if (acc_img[i] !== dut.pram.mem[i]) 
       begin
        if (!tr) begin error("Memory not matched:"); tr=1'b1; end
        $display(" * Org[%h] = %0d, Mem[%h] = %0d",i[7:0],acc_img[i],i,dut.pram.mem[i]);
       end
  1: if (acc_img[i] !== dut.pram.mem[256+i]) 
       begin
        if (!tr) begin error("Memory not matched:"); tr=1'b1; end
        $display(" * Org[%h] = %0d, Mem[%h] = %0d",i[7:0],acc_img[i],i+256,dut.pram.mem[i+256]);
       end
  2: if (acc_img[i] !== (dut.pram.mem[256+i]+dut.pram.mem[i])) 
       begin
        if (!tr) begin error("Memory not matched:"); tr=1'b1; end
        $display(" * Org[%h] = %0d, Mem[%h/1%h] = %0d/%0d",i[7:0],acc_img[i],
         i,dut.pram.mem[i],
         i,dut.pram.mem[i+256]);
       end
 endcase
if (tr) $display;
end
endtask


integer bc=0;
initial begin
 $timeformat ( -9,0," ns",15);
 CLR_ACC;
 #2000;


 repeat(100) begin
  $display("Burst #%0d (%0d errors)",bc,errors);
  gen_burst(1,10);
  #10000;
  CHK_MEM(0);
  bc = bc+1;
 end

 CLR_ACC;
 ram_blk_sel <= 1'b1;
 
 $display("Filling up part ...");
 repeat(100) begin
  $display("Burst #%0d (%0d errors)",bc,errors);
  gen_burst(1,10);
  #10000;
  CHK_MEM(1);
  bc = bc+1;
 end

 CLR_ACC;
 $display("Filling both part ...");
 repeat(100) begin
  $display("Burst #%0d (%0d errors)",bc,errors);
  gen_burst(10,20);
  ram_blk_sel <= ~ram_blk_sel;
  gen_burst(10,20);
  #15000;
  CHK_MEM(2);
  bc = bc+1;
 end
 ram_blk_sel <= 1'b0;
   
 #1000;
 gen_burst(4000,8000);
  #100000;
  CHK_MEM(0);
 
 if (errors!=0) $display("Done: Total %0d error(s)",errors);
 else $display("Done: No errors");
 
 $stop;
end

endmodule
