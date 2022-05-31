`timescale 1ns / 1ps

module ut_arbiter;

reg clk=1; // Clock

wire [6:0] erd_addr_i;
wire erd_read_i;
wire [31:0] erd_data_o;

wire [6:0] ewr_addr_i;
wire ewr_write_i;
wire [31:0] ewr_data_i;

wire [6:0] cpu_addr_i;
wire cpu_stb_i;
wire cpu_we_i;
wire [31:0] cpu_data_i;
wire [31:0] cpu_data_o;

wire [8:0] ram_addr_o;
wire ram_cs_o;
wire ram_we_o;
wire [31:0] ram_data_o;
wire [31:0] ram_data_i;

Arbiter arb
(
 .clk(clk), 
 .erd_addr_i({2'b00,erd_addr_i}), .erd_read_i(erd_read_i), .erd_data_o(erd_data_o), 
 .ewr_addr_i({2'b01,ewr_addr_i}), .ewr_write_i(ewr_write_i), .ewr_data_i(ewr_data_i), 
 .cpu_addr_i({2'b10,cpu_addr_i}), .cpu_stb_i(cpu_stb_i), .cpu_we_i(cpu_we_i), 
   .cpu_data_i(cpu_data_i), .cpu_data_o(cpu_data_o), 
 .ram_addr_o(ram_addr_o), .ram_data_o(ram_data_o), .ram_data_i(ram_data_i), .ram_we_o(ram_we_o), .ram_cs_o(ram_cs_o)
);

wire [31:0] error1;
wire [31:0] error2;
wire [31:0] error3;
wire [31:0] error4;

wire [31:0] error = error1+error2+error3+error4;

reg s_eth_rd = 1'b0;
reg s_eth_wr = 1'b0;
reg s_cpu_rd = 1'b0;
reg s_cpu_wr = 1'b0;

ReadPipe #("Eth") eth_read(
 .clk(clk), .start(s_eth_rd), 
 .addr_o(erd_addr_i), .rd_stb_o(erd_read_i), .data_i(erd_data_o),
 .ram_addr_i(ram_addr_o[6:0]), .ram_cs_i(ram_cs_o & ram_addr_o[8:7]==2'b00), .ram_we_i(ram_we_o), .ram_data_o(ram_data_i),
 .err(error1)
);

WritePipe #("Eth") eth_write(
 .clk(clk), .start(s_eth_wr), 
 .addr_o(ewr_addr_i), .data_o(ewr_data_i), .wr_stb_o(ewr_write_i),
 .ram_addr_i(ram_addr_o[6:0]), .ram_cs_i(ram_cs_o & ram_addr_o[8:7]==2'b01), .ram_we_i(ram_we_o), .ram_data_i(ram_data_o),
 .err(error2) 
);

wire cpu_read_i, cpu_write_i;
assign cpu_stb_i = cpu_read_i | cpu_write_i;
assign cpu_we_i = cpu_write_i;

wire [6:0] cpu_addr_1;
wire [6:0] cpu_addr_2;

assign cpu_addr_i = cpu_read_i?cpu_addr_1:cpu_addr_2;

ReadPipe #("CPU") cpu_read(
 .clk(clk), .start(s_cpu_rd), 
 .addr_o(cpu_addr_1), .rd_stb_o(cpu_read_i), .data_i(cpu_data_o),
 .ram_addr_i(ram_addr_o[6:0]), .ram_cs_i(ram_cs_o & ram_addr_o[8:7]==2'b10 & ~ram_we_o), .ram_we_i(ram_we_o), .ram_data_o(ram_data_i),
 .err(error3) 
);

WritePipe #("CPU") cpu_write(
 .clk(clk), .start(s_cpu_wr), 
 .addr_o(cpu_addr_2), .data_o(cpu_data_i), .wr_stb_o(cpu_write_i),
 .ram_addr_i(ram_addr_o[6:0]), .ram_cs_i(ram_cs_o & ram_addr_o[8:7]==2'b10 & ram_we_o), .ram_we_i(ram_we_o), .ram_data_i(ram_data_o),
 .err(error4) 
);

initial forever #50 clk <= ~clk;

integer t_eth_w, t_eth_r, t_cpu;

integer tclk;

initial begin
 t_eth_w = 8+($unsigned($random())%10);
 t_eth_r = 8+($unsigned($random())%10);
 t_cpu   = 8+($unsigned($random())%10);
 
 $timeformat ( -9,0," ns",15);
 #2000;
 
 for(tclk=0;tclk<1000000;tclk=tclk+1)
 begin
  @(posedge clk);
  s_eth_rd = 1'b0;
  s_eth_wr = 1'b0;
  s_cpu_rd = 1'b0;
  s_cpu_wr = 1'b0;
  
  if (t_eth_w==0)
  begin
   t_eth_w = 8+($unsigned($random())%10);
   s_eth_wr=1'b1;
  end
  else
   t_eth_w = t_eth_w -1;
   
  if (t_eth_r==0)
  begin
   t_eth_r = 8+($unsigned($random())%10);
   s_eth_rd=1'b1;
  end
  else
   t_eth_r = t_eth_r -1;
  
  if (t_cpu==0)
  begin
   t_cpu = 8+($unsigned($random())%10);
   if ($random()&1) s_cpu_wr=1'b1; else s_cpu_rd=1'b1;
  end
  else
   t_cpu = t_cpu -1;
  
 end
 
 if (error) $display("Total errors - %0d",error);
 
 $stop;
end

   
endmodule


// Pipe to Eth -> Arbiter -> RAM write pipe
module ReadPipe #(parameter NAME="") (
 input clk, 
 input start,

 output [6:0] addr_o,
 input  [31:0] data_i,
 output rd_stb_o,

 input  wire [6:0] ram_addr_i,
 input  wire ram_cs_i,
 input  wire ram_we_i,
 output wire [31:0] ram_data_o,
 
 output reg [31:0] err
);

initial err = 0;

reg [31:0] b_data = 1'b0;
reg [6:0] b_addr = 1'b0;
reg stb = 1'b0;

reg stb2 = 0;
always @(posedge clk) stb2 <= ram_cs_i;

assign addr_o = b_addr;
assign ram_data_o = stb2?b_data:32'bz;
assign rd_stb_o = stb;

always @(posedge clk)
 if (start) DoRead;

task DoRead;
integer i;
begin
 b_data = $random();
 b_addr = $random();
 @(posedge clk);
 stb=1'b1;
 $display("(%0t) ReadPipe %0s: Pass %0h at address %0h",$time,NAME,b_data,b_addr);
 @(posedge clk);
 stb=1'b0;

 for(i=0;i<10;i=i+1)
  begin
   if (ram_cs_i)
    begin
     if (ram_we_i) begin $display("(%0t) ReadPipe %0s ERROR: Unexpected write to RAM",$time,NAME); err=err+1; end else
     if (ram_addr_i!=b_addr) begin $display("(%0t) ReadPipe %0s ERROR: Wrong RAM read address %0h (expected %0h)",$time,NAME,ram_addr_i,b_addr); err=err+1; end
     i=100;
     @(posedge clk);
     if (ram_cs_i) begin $display("(%0t) ReadPipe %0s ERROR: RAM read stall",$time,NAME); err=err+1; end
    end
   @(posedge clk);
  end
 if (i<100) begin $display("(%0t) ReadPipe %0s ERROR: No RAM access in 10 ticks",$time,NAME); err=err+1; end else
 begin
  for(i=0;i<3;i=i+1)
   begin
    if (data_i==b_data) 
     begin
      i=100;
      $display("(%0t) ReadPipe %0s: Got %0h",$time,NAME,data_i);
     end
    @(posedge clk);
   end
  if (i<100) begin $display("(%0t) ReadPipe %0s ERROR: No output from arbiter in 3 ticks (%0h read, expected %0h)",$time,NAME,data_i,b_data); err=err+1; end
 end
end
endtask

endmodule

// Pipe to write to Arbiter (Eth <- Arbiter <- RAM)
module WritePipe #(parameter NAME="") (
 input clk, 
 input start,

 output [6:0] addr_o,
 output [31:0] data_o,
 output wr_stb_o,

 input  wire [6:0] ram_addr_i,
 input  wire ram_cs_i,
 input  wire ram_we_i,
 input  wire [31:0] ram_data_i,
 
 output reg [31:0] err 
);

initial err = 0;

reg [31:0] b_data = 1'b0;
reg [6:0] b_addr = 1'b0;
reg stb = 1'b0;

assign addr_o = b_addr;
assign data_o = b_data;
assign wr_stb_o = stb;

always @(posedge clk)
 if (start) DoWrite;

task DoWrite;
integer i;
begin
 b_data = $random();
 b_addr = $random();
 @(posedge clk);
 stb=1'b1;
 $display("(%0t) WritePipe %0s: Write %0h at address %0h",$time,NAME,b_data,b_addr);
 @(posedge clk);
 stb=1'b0;

 for(i=0;i<10;i=i+1)
  begin
   if (ram_cs_i)
    begin
     if (!ram_we_i) begin $display("(%0t) WritePipe %0s ERROR: Unexpected read from RAM",$time,NAME); err=err+1; end else
     if (ram_addr_i!=b_addr) begin $display("(%0t) WritePipe %0s ERROR: Wrong RAM write address %0h (expected %0h)",$time,NAME,ram_addr_i,b_addr); err=err+1; end else
     if (b_data!=ram_data_i) begin $display("(%0t) WritePipe %0s ERROR: Wrong RAM write data: %0h (expected %0h)",$time,NAME,b_data,ram_data_i); err=err+1; end
     i=100;
     @(posedge clk);
     if (ram_cs_i) begin $display("(%0t) WritePipe %0s ERROR: RAM write stall",$time,NAME); err=err+1; end
    end
   @(posedge clk);
  end
 if (i<100) begin $display("(%0t) WritePipe %0s ERROR: No RAM access in 10 ticks",$time,NAME); err=err+1; end
end
endtask

endmodule
