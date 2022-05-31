`timescale 1ns / 1ps

module ut_arbiter2;

reg clk=1; // Clock

initial forever #50 clk <= ~clk;

reg [6:0] erd_addr_i =0;
reg erd_read_i =0;
reg erd_read_en_i =0;
wire [3:0] erd_data_o;

reg [6:0] ewr_addr_i =0;
reg ewr_write_i =0;

reg [6:0] cpu_addr_i =0;
reg cpu_write_i=0;
reg cpu_read_i=0;
reg cpu_read_en_i=0;
reg [31:0] cpu_data_i=0;
wire cpu_data_o;

wire [8:0] ram_addr_o;
wire ram_cs_o;
wire ram_we_o;
wire [31:0] ram_data_o;
reg [31:0] ram_data_i=0;

Arbiter2 arb
(
 .clk(clk), 
 .erd_addr_i({2'b00,erd_addr_i}), .erd_read_i(erd_read_i), .erd_read_en_i(erd_read_en_i), .erd_data_o(erd_data_o), 

 .ewr_addr_i({2'b01,ewr_addr_i}), .ewr_write_i(ewr_write_i), .ewr_data_i(addr2data({2'b01,ewr_addr_i})), 

 .cpu_addr_i({2'b10,cpu_addr_i}), 
  .cpu_write_i(cpu_write_i), .cpu_data_i(addr2data({2'b10,cpu_addr_i})), 
  .cpu_read_i(cpu_read_i), .cpu_read_en_i(cpu_read_en_i), .cpu_data_o(cpu_data_o), 

 .ram_addr_o(ram_addr_o), .ram_data_o(ram_data_o), .ram_data_i(ram_data_i), .ram_we_o(ram_we_o), .ram_cs_o(ram_cs_o)
);

always @(posedge clk)
if (ram_cs_o)
 if (ram_we_o)
  begin
   $display("(%0t) Arb2 RAM: Write [%0h] <= %0h",$time,ram_addr_o,ram_data_o);
   if (ram_data_o != addr2data(ram_addr_o))
    begin
     error("RAM write data/addr missmatch");
     $display("  Addr=%0h, Data=%0h, Should be=%0h",ram_addr_o,ram_data_o,addr2data(ram_addr_o));
    end
  end
 else
  begin
   ram_data_i <= addr2data(ram_addr_o);
   $display("(%0t) Arb2 RAM: Read [%0h] => %0h",$time,ram_addr_o,addr2data(ram_addr_o));
  end

function [31:0] addr2data(input wire [8:0] addr);
begin
 addr2data = addr*32'h243BCA56+32'h098FCBF9;
end
endfunction

task wr_eth;
begin
 ewr_addr_i = $random();
 ewr_write_i = 1'b1;
 $display("(%0t) Arb2 Eth: Write [%0h] <= %0h",$time,{2'b01,ewr_addr_i},addr2data({2'b01,ewr_addr_i}));
 @(negedge clk);
 ewr_write_i = 1'b0;
end
endtask

task wr_cpu;
begin
 cpu_addr_i = $random();
 $display("(%0t) Arb2 Cpu: Write [%0h] <= %0h",$time,{2'b10,cpu_addr_i},addr2data({2'b10,cpu_addr_i}));
 cpu_write_i = 1'b1;
 @(negedge clk);
 cpu_write_i = 1'b0;
end
endtask

task rd_eth;
integer start_dly;
integer total_data;
reg [6:0] addr;
integer cnt;
reg [31:0] data;

begin
 start_dly = 8+($unsigned($random())%8);
 total_data = 1+($unsigned($random())%8);
 addr = $random & 7'h3F;
 $display("(%0t) Arb2 Eth: Start read %0d words (delay is %0d clocks) to %0h",$time,total_data,start_dly,addr);
 erd_addr_i = addr;
 erd_read_en_i = 1'b1;
 repeat(start_dly) @(negedge clk);
 $display("(%0t) Arb2 Eth: Read activated",$time);
 erd_read_i = 1'b1;
 repeat(total_data)
 begin
  for(cnt=0;cnt<8;cnt=cnt+1)
   begin
    @(posedge clk);
    $display("(%0t) Arb2 Eth: Read Nibble %0h",$time,erd_data_o);
    data = {erd_data_o,data[31:4]};
   end
  if (data != addr2data({2'b00,addr}))
  begin
   error("Wrong Eth data on read");
   $display("  Addr=%0h, Data=%0h, Should be=%0h",{2'b00,addr},data,addr2data({2'b00,addr}));
  end
  else
   $display("(%0t) Arb2 Eth: Read - Got %0h from %0h",$time,data,{2'b00,addr});
  addr = addr+1;
 end
 @(negedge clk);
 erd_read_i = 1'b0;
 erd_read_en_i = 1'b0;
 $display("(%0t) Arb2 Eth: Read done",$time);
end
endtask

task rd_cpu;
integer start_dly;
integer total_data;
reg [6:0] addr;
integer cnt;
reg [31:0] data;

begin
 start_dly = 16+($unsigned($random())%8);
 total_data = 1+($unsigned($random())%8);
 addr = $random & 7'h3F;
 $display("(%0t) Arb2 CPU: Start read %0d words (delay is %0d clocks) to %0h",$time,total_data,start_dly,{2'b10,addr});
 cpu_addr_i = addr;
 cpu_read_en_i = 1'b1;
 repeat(start_dly) @(negedge clk);
 $display("(%0t) Arb2 CPU: Read activated",$time);
 cpu_read_i = 1'b1;
 repeat(total_data)
 begin
  for(cnt=0;cnt<32;cnt=cnt+1)
   begin
    @(posedge clk);
    $display("(%0t) Arb2 CPU: Read bit %0h",$time,cpu_data_o);
    data = {data[30:0],cpu_data_o};
   end
  if (data != addr2data({2'b10,addr}))
  begin
   error("Wrong CPU data on read");
   $display("  Addr=%0h, Data=%0h, Should be=%0h",{2'b10,addr},data,addr2data({2'b10,addr}));
  end
  else
   $display("(%0t) Arb2 CPU: Read - Got %0h from %0h",$time,data,{2'b10,addr});
  addr = addr+1;
 end
 @(negedge clk);
 cpu_read_i = 1'b0;
 cpu_read_en_i = 1'b0;
 $display("(%0t) Arb2 CPU: Read done",$time);
 @(negedge clk);
end
endtask

integer err_cnt = 0;

task error(input [10239:0] msg);
begin
 $display("(%0t) Arb2 ***ERROR***: %0s",$time,msg);
 err_cnt = err_cnt+1;
end
endtask

integer done = 0;

integer i1;

initial begin
 #3000;
 @(negedge clk);
 for(i1=0;i1<100000;i1=i1+1)
 begin
  repeat(8+$unsigned($random)%20) @(negedge clk);
  rd_eth;
 end
 done = done+1;
end

integer i2;

initial begin
 #3000;
 @(negedge clk);
 for(i2=0;i2<100000;i2=i2+1)
 begin
  repeat(8+$unsigned($random)%20) @(negedge clk);
  wr_eth;
 end
 done = done+1;
end

integer i3;

initial begin
 #3000;
 @(negedge clk);
 for(i3=0;i3<100000;i3=i3+1)
 begin
  repeat(8+$unsigned($random)%20) @(negedge clk);
  if ($random()&1) wr_cpu; else rd_cpu;
 end
 done = done+1;
end


initial begin

 $timeformat ( -9,0," ns",15);
 #2000;
 
// rd_eth;
// #100;
// rd_cpu;
 
 #1000;

 while(done<3) @(negedge clk); 
 
 if (err_cnt) $display("Total errors - %0d",err_cnt);
 
 $stop;
end

   
endmodule
