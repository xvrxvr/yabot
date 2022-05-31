`timescale 1ns / 1ps

`define TOTAL 8
`define ST_SCALE 64'h0202020202020202

module ut_qenc;

integer error_cnt=0;

reg clk = 0;
reg clk2 = 0;

initial begin
 #10;
 forever #20 clk <= ~clk;
end

initial begin
 #10;
 forever #10 clk2 <= ~clk2;
end

reg reg_cs =0;           // QEncoder register select
reg [7:0]  reg_addr =0;  // QEncoder register address
reg [31:0] reg_data =0;  // QEncoder register data

wire z_hit;           // Setup if Z index of active QEnc hits. Cleared by write to QE control register

wire fatal_ovl;        // Overflow flag (setup until reset by 'enable_fe' deassertion)
wire fatal_inv_trans;  // Invalid transition flag (setup until reset by 'enable_fe' deassertion)
wire [4:0] fatal_idx;  // Index of failed QE

wire [4:0] wr_addr;  // RAM address of modification
wire wr_hit;        // RAM modified

reg qenc_enable = 0;

// Monitor of outputs
wire any_err  = fatal_ovl|fatal_inv_trans;
always @(posedge any_err)
begin
 $display("(%0t) *** Fatal error asserted ***: On ch %0d",$time,fatal_idx);
 $write(" *");
 if (fatal_ovl) $write(" Overflow");
 if (fatal_inv_trans) $write(" Invalid trans");
 $display;
end

always @(negedge any_err)
begin
 $display("(%0t) Fatal error deasserted",$time);
end

always @(posedge z_hit) $display("(%0t) Z Hit asserted",$time);
always @(negedge z_hit) $display("(%0t) Z Hit deasserted",$time);

reg [`TOTAL-1:0] written = 0;

always @(posedge clk)
if (wr_hit)
 begin
  $display("(%0t) QEnc RAM Modification: [%0d]",$time,wr_addr);
  written[wr_addr]=1'b1;
 end

wire [`TOTAL-1:0] a_out;
wire [`TOTAL-1:0] b_out;
wire [`TOTAL-1:0] z_out;

QEncBench #(`TOTAL) bn(.a_out(a_out), .b_out(b_out), .z_out(z_out));

QEnc #(.SETUP(`ST_SCALE),.NUM_ENCS(`TOTAL)) qenc
(
 .clk(clk),.clk2(clk2),

 .a_inp(a_out), .b_inp(b_out), .z_inp(z_out),

 .reg_cs(reg_cs), .reg_addr(reg_addr), .reg_data(reg_data),

// Output stat signals
 .z_hit(z_hit),           // Setup if Z index of active QEnc hits. Cleared by write to QE control register

 .fatal_ovl(fatal_ovl),        // Overflow flag (setup until reset by 'enable_fe' deassertion)
 .fatal_inv_trans(fatal_inv_trans),  // Invalid transition flag (setup until reset by 'enable_fe' deassertion)
 .fatal_idx(fatal_idx),  // Index of failed QE
 
 .wr_addr(wr_addr),  // RAM address of modification
 .wr_hit(wr_hit),         // RAM modified

// RAM (second port) interface
 .ram_di(0),
 .ram_do(),
 .ram_addr(0),
 .ram_clk(0),
 .ram_en(0),
 .ram_we(0),
 
 .qenc_enable(qenc_enable)       // Control signal - enable whole QEnc processor
);

task WR_REG(input integer addr, input integer data);
begin
 reg_cs <= 1'b0;
 reg_data <= data;
 reg_addr <= addr;
 @(posedge clk);
 reg_cs <= 1'b1;
 @(posedge clk);
 reg_cs <= 1'b0;
end
endtask

task automatic CLR;
integer i;
begin
 bn.CLR;
 for(i=0;i<`TOTAL;i=i+1) qenc.qe_be.qenc_ram.mem[i]=0;
end
endtask

task automatic error(input wire [1023:0] msg);
begin
 $display("(%0t) ***Error***: %0s",$time,msg);
 error_cnt=error_cnt+1;
end
endtask

task automatic CHK;
integer i,j;
begin
 for(i=0;i<`TOTAL;i=i+1)
  begin
   j=0;
   case((`ST_SCALE >> i*8)&3)
     2: j=bn.cnts[i];
     1: j=$signed(bn.cnts[i])/2;
     0: j=$signed(bn.cnts[i])/4;
     default: ;
   endcase
   if (j!=qenc.qe_be.qenc_ram.mem[i])
    begin
     error("Wrong QEnc count");
     $display("* Chanel - %0d, QEnc - %0d, Real - %0d",i,qenc.qe_be.qenc_ram.mem[i],j);
    end
  end
end
endtask

task automatic run_test;
reg [`TOTAL-1:0] used_chs;
integer i,sp,dir,st;
begin
 used_chs = $random();
 $display("(%0t) Run test on %b",$time,used_chs);
 written = 0;
 for(i=0;i<`TOTAL;i=i+1)
  if (used_chs[i])
   begin
    sp=($unsigned($random())%5+1)*20;
    dir=$random()&1?1:-1;
    st=$unsigned($random())%10+1;
    $display("Ch [%0d]: Dir=%0d, Speed=%0d, Steps=%0d",i,dir,sp,st);
    bn.RUN(i,dir,sp,st);
   end
 bn.WAIT(-1);
 #1000;
 CHK;
 if (written!==used_chs)
 begin
  error("Expected modification scale not observed");
  $display("* Got - %b, Expected - %b",written,used_chs);
 end
 $display;
end
endtask


initial
begin
 $timeformat ( -9,0," ns",15);
 CLR;
 #2000;
 
 $display("(%0t) Check for reset",$time);
 bn.RUN(0,1,20,10);
 bn.WAIT(-1);
 bn.CLR;
 CHK;
 #1000;
 
 qenc_enable <= 1'b1;
 #1000;

 run_test;
 #1000;
 
 $display("(%0t) Check for fatal error (trans)",$time);
 bn.RUN(0,2,20,10);
 bn.WAIT(-1);
 if (!fatal_inv_trans) error("Fatal error 'invalid transition' was expected");
 if (fatal_idx!=0) begin error("Wrong index of 'invalid transition'"); $display(" * Ch %0d (expectd 0)",fatal_idx); end
 qenc_enable <= 1'b0;
 repeat(10) @(posedge clk);
 qenc_enable <= 1'b1;
 #1000;
 if (fatal_inv_trans || fatal_ovl) error("'Fatal' flag stick");
 
 $display("(%0t) Check for fatal error (overflow)",$time);
 bn.RUN(0,1,1,100);
 bn.RUN(1,1,1,100);
 bn.RUN(2,1,1,100);
 bn.RUN(3,1,1,100);
 bn.RUN(4,1,1,100);
 bn.WAIT(-1);
 #1000;
 if (!fatal_ovl) error("Fatal error 'overflow' was expected");
 qenc_enable <= 1'b0;
 repeat(10) @(posedge clk);
 qenc_enable <= 1'b1;
 #1000;
 if (fatal_inv_trans || fatal_ovl) error("'Fatal' flag stick");
 
 CLR;

 $display("(%0t) Z index check",$time);
 bn.RUN(0,1,20,10);
 bn.WAIT(-1);
 WR_REG(1,-1);
 if (z_hit) error("Unexpected z_hit");
 bn.ZINDEX(0,10);
 bn.RUN(0,1,20,10);
 bn.WAIT(-1);
 if (!z_hit) error("Expected z_hit");
 bn.CLR;
 CHK;
 WR_REG(1,0);
 if (z_hit) error("Stuck z_hit");
 #1000;

 repeat(1000) run_test;

 #2000;

 $display("Total errors - %0d", error_cnt);
 
 $stop;

end

endmodule
