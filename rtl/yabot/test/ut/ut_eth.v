`timescale 1ns / 1ps

`include "rtl/eth.inc"

module ut_eth;

reg clk = 1'b0;
reg clk4 = 1'b0;

initial begin
 #10;
 forever #20 clk <= ~clk;
end

initial begin
 #25;
 forever #5 clk4 <= ~clk4;
end

wire rx_clk;
wire rx_er;
wire rx_dv;
wire [3:0] rxd;

wire tx_en;
wire [3:0] txd;

///// Stat interface (rxd)
wire rx_pkt_ok;     // Pkt recieved Ok
wire rx_pkt_err;    // Err pkt recieved
wire rx_eth_active; // Pkt recieve in progress

wire [3:0] pkt_stat1; // Statistics output (group 1)
wire [3:0] pkt_stat2; // Statistics output (group 2)
wire [2:0] pkt_fatal_err; // Fatal error bits (sticky bits)

// Stat txd
wire tx_pkt_ok;     // Pkt sent Ok
wire tx_eth_active; // Pkt sending in progress
wire [3:0] pkt_stat3; // Statistics output

wire [15:0] bus_addr;      // address of RAM/Registers 
wire [31:0] bus_data;      // data for RAM/Registers

// Selector output
wire sel_register;         // Write to Eth_SelType_Generic/Reg
wire sel_fifo;             // Write to Eth_SelType_FIFO

wire [5:0] sel_index;      // index of active selector

wire wr_stb;

// Control
wire [`CTRL_REG_SIZE*32-1:0] ctrl_out; // Output control vector

reg  [`STATUS_SCALE_LENGTH*8-1:0] bg_img = 0;

/////// ModifChk connect
  // Single Signals - 1 per ModifChk module
wire [`MEM_TOTAL-1:0] in_send;
wire [`MEM_TOTAL-1:0] is_modif;

  // Bus signals - for all ModifChk modules in parallel
wire is_modif2;
wire [8:0] modif_start;
wire [8:0] modif_end;

/////// Arbiter2 connect
  // Bus signals
wire [8:0] erd_addr;
wire [3:0] erd_data;
wire erd_read;
wire [8:0] ewr_addr;
wire [31:0] ewr_data;

  // Single signal
wire [`MEM_TOTAL-1:0] erd_read_en;
wire [`MEM_TOTAL-1:0] ewr_write;


// MCH control
reg [`MEM_TOTAL-1:0] mc_wr_stb = 0;
reg [8:0] mc_wr_addr;

Eth eth
(
 .clk(clk),
 .clk4(clk4),        // 100 MHz clock 

///// PHY interface
 .rx_clk(rx_clk),
 .rx_er_i(rx_er),
 .rx_dv_i(rx_dv),
 .rxd_i(rxd),

 .tx_en_o(tx_en),
 .txd_o(txd),

///// Stat interface (rxd)
 .rx_pkt_ok(rx_pkt_ok),     // Pkt recieved Ok
 .rx_pkt_err(rx_pkt_err),    // Err pkt recieved
 .rx_eth_active(rx_eth_active), // Pkt recieve in progress

 .pkt_stat1(pkt_stat1), // Statistics output (group 1)
 .pkt_stat2(pkt_stat2), // Statistics output (group 2)
 .pkt_fatal_err(pkt_fatal_err), // Fatal error bits (sticky bits)

// Stat txd
 .tx_pkt_ok(tx_pkt_ok),     // Pkt sent Ok
 .tx_eth_active(tx_eth_active), // Pkt sending in progress
 .pkt_stat3(pkt_stat3), // Statistics output

////// Input data - BG pkt
 .bg_img_i(bg_img),

////// Output data

// Bus interface
 .bus_addr_o(bus_addr),      // address of RAM/Registers 
 .bus_data_o(bus_data),      // data for RAM/Registers

// Selector output
 .sel_register_o(sel_register),         // Write to Eth_SelType_Generic/Reg
 .sel_fifo_o(sel_fifo),             // Write to Eth_SelType_FIFO

 .sel_index_o(sel_index),      // index of active selector

 .wr_stb_o(wr_stb),

// Control
 .ctrl_out_o(ctrl_out), // Output control vector

/////// ModifChk connect
  // Single Signals - 1 per ModifChk module
 .in_send_o(in_send),
 .is_modif_i(is_modif),

  // Bus signals - for all ModifChk modules in parallel
 .is_modif2_i(is_modif2),
 .modif_start_i(modif_start),
 .modif_end_i(modif_end),

/////// Arbiter2 connect
  // Bus signals
 .erd_addr_o(erd_addr),
 .erd_data_i(erd_data),
 .erd_read_o(erd_read),
 .ewr_addr_o(ewr_addr),
 .ewr_data_o(ewr_data),

  // Single signal
 .erd_read_en_o(erd_read_en),
 .ewr_write_o(ewr_write)
);

BEthTx snd_drv (.clk_o(rx_clk),.dout_o(rxd),.dv_o(rx_dv),.derr_o(rx_er));

BEthRx #(1) rcv_drv (.clk(clk), .rxd(txd), .rx_en(tx_en));


genvar i;
generate for(i=0;i<`MEM_TOTAL;i=i+1) begin :mset

wire [8:0] ram_addr;
wire ram_cs;
wire ram_we;
wire [31:0] ram_data_o;
wire [31:0] ram_data_i;

Arbiter2 arb
(
 .clk(clk), // Clock

// Eth read domen
// Data available on next clock, can be registered after one clk (on 3d clock)
// Read strobes interval should be not less than 8
 .erd_addr_i(erd_addr),
 .erd_read_i(erd_read),        // Real 'read' op, should be issued on every nibble consumption
 .erd_read_en_i(erd_read_en[i]),     // Enable signal - all 'eth_read_i' should be nested in active state of this signal
 .erd_data_o(erd_data), // Current read nibble (3-state)

// Eth write domen (mid priority)
// Data and address latched on input clock
// Write strobes interval should be not less than 8
 .ewr_addr_i(ewr_addr),
 .ewr_write_i(ewr_write[i]),
 .ewr_data_i(ewr_data),

// CPU r/w domen (low priority)
// Rata readed will be available after 8 clocks after read strobe
// R/W strobes interval should be not less than 16
 .cpu_addr_i(0),
 .cpu_write_i(0),
 .cpu_read_i(0),
 .cpu_read_en_i(0),
 .cpu_data_i(0),
 .cpu_data_o(), // Current read bit (3-state)

// RAM interface
 .ram_addr_o(ram_addr),
 .ram_cs_o(ram_cs),
 .ram_we_o(ram_we),
 .ram_data_o(ram_data_o),
 .ram_data_i(ram_data_i)
);

RamEmu #(i) ram_mod
(
 .clk(clk),

 .ram_addr_i(ram_addr),
 .ram_cs_i(ram_cs),
 .ram_we_i(ram_we),
 .ram_data_i(ram_data_o),
 .ram_data_o(ram_data_i)
);


ModifChk #(9) mc
(
 .clk(clk),

 .wr_stb(mc_wr_stb[i]),
 .wr_addr(mc_wr_addr),

 .in_send(in_send[i]),
 .is_modif(is_modif[i]),
 .is_modif2(is_modif2), // 3-state signal, can be bused for all ModifChk instancies
 .modif_start(modif_start), // 3-state signal, can be bused for all ModifChk instancies
 .modif_end(modif_end) // 3-state signal, can be bused for all ModifChk instancies
);

end
endgenerate

integer err_cnt =0;

task error(input [10249:0] msg);
begin
 $display("(%0t) Eth ***Error***: %0s",$time,msg);
 err_cnt = err_cnt+1;
end
endtask

////////////////// Count of pkt_stat?, pkt_fatal //////////////////////

always @(posedge clk)
begin
 if (pkt_stat1[1:0] != 0) $display("(%0t) Stat1: Error %0d",$time,pkt_stat1);
 if (pkt_stat2 == 1) $display("(%0t) Stat2: BG recieved",$time); else 
 if (pkt_stat2 != 0) $display("(%0t) Stat2: Error %0d",$time,pkt_stat2);
 if (pkt_fatal_err != 0) begin $display("(%0t) Fatal: Error %0d",$time,pkt_fatal_err); $stop; end 
end

////////////////// Low level primitives ///////////////////////////////
integer inp_sn = 1;
integer rep_cnt =3;

// Send primitives
task LL_SEND_RESET(input integer rep_count);
begin
 snd_drv.RESET_SN(rep_count);
 inp_sn=1;
 rep_cnt=rep_count;
end
endtask

// Send pack with duplicates and s/n increment
task ll_send_any(input wire [7:0] sel, input wire [15:0] addr, input wire [1500*8-1:0] data, input integer items);
begin
 snd_drv.SET_ADDR(addr);
 snd_drv.SENDP(data,items,sel);
end
endtask

// Real send primitives
task LL_SEND_CTRL(input wire [`CTRL_REG_SIZE*32-1:0] ctrl_image);
begin
 ll_send_any(`Eth_SelGen_BG,0,ctrl_image,`CTRL_REG_SIZE);
end
endtask

task LL_SEND_REG(input wire [7:0] addr, input wire [7:0] subaddr, input wire [31:0] data);
begin
 ll_send_any(`Eth_SelGen_Reg,{subaddr,addr},data,1);
end
endtask

task LL_SEND_RAM(input wire [5:0] ram_sel, input wire [15:0] addr, input integer items);
 reg [13999:0] lbuf;
begin
 rcv_drv.E_DATA(addr[8:0],items,lbuf);
 rcv_drv.E_NONE;
 ll_send_any({`Eth_SelType_RAM,ram_sel},addr,lbuf,items);
end
endtask

task LL_SEND_FIFO(input wire [5:0] fifo_sel, input wire [15:0] addr, input integer items);
 reg [13999:0] lbuf;
begin
 rcv_drv.E_DATA(addr,items,lbuf);
 rcv_drv.E_NONE;
 ll_send_any({`Eth_SelType_FIFO,fifo_sel},addr,lbuf,items);
end
endtask

// Internal expects
task LL_EXP_CTRL(input wire [`CTRL_REG_SIZE*32-1:0] ctrl_image);
begin
 @(posedge rx_pkt_ok);
 @(negedge rx_pkt_ok);
 if (ctrl_image !== ctrl_out)
 begin
  error("Wrong CTRL");
  $display(" * Got = %0h, Expected = %0h",ctrl_out,ctrl_image);
 end
end
endtask

task LL_EXP_REG(input wire [7:0] addr, input wire [7:0] subaddr, input wire [31:0] data);
 integer dn;
begin
 dn=0;
 while(!dn)
 begin
  @(posedge clk);
  if (wr_stb && sel_register)
  begin
   dn=1;
   if (bus_addr !== {subaddr,addr} )
    begin
     error("Wrong address in REG write");
     $display(" * Expected %0h, Got %0h",{subaddr,addr},bus_addr);
    end
   if (bus_data !== data)
    begin
     error("Wrong data in REG write");
     $display(" * Expected %0h, Got %0h",data,bus_data);
    end
  end
 end
end
endtask

task LL_EXP_RAM(input wire [5:0] ram_sel, input wire [15:0] addr, input integer items);
 integer cnt;
begin
 cnt=0;
 while(cnt<items)
 begin
  @(posedge clk);
  if (wr_stb && ewr_write[ram_sel]) cnt=cnt+1;
 end
end
endtask

task LL_EXP_FIFO(input wire [5:0] fifo_sel, input reg [15:0] addr, input integer items);
 integer cnt;
begin
 cnt=0;
 while(cnt<items)
 begin
  @(posedge clk);
  if (wr_stb && sel_fifo)
  begin
   if (bus_addr !== addr )
    begin
     error("Wrong address in FIFO write");
     $display(" * Expected %0h, Got %0h",addr,bus_addr);
    end
   if (bus_data !== hash(addr))
    begin
     error("Wrong data in FIFO write");
     $display(" * Expected %0h, Got %0h",hash(addr),bus_data);
    end
   if (fifo_sel !== sel_index)
    begin
     error("Wrong selector in FIFO write");
     $display(" * Expected %0d, Got %0d",sel_index,fifo_sel);
    end
   cnt = cnt+1;
   addr = addr+1;
  end
 end
end
endtask

// Recv primitives
task LL_RECV_SET_TIMEOUT(input integer timeout_fast, input integer timeout_normal);
begin
//!!!
end
endtask

task LL_RECV_BG(input wire [`STATUS_SCALE_LENGTH*8-1:0] bg_image, input wire is_fast);
 reg [13999:0] lbuf;
begin
 rcv_drv.E_SEL(`Eth_SelGen_BG);
 rcv_drv.E_DUP(0);
 rcv_drv.E_SN(0);
 rcv_drv.E_DATA(0,`STATUS_SCALE_LENGTH/4,lbuf);
 rcv_drv.WAIT;
end
endtask

task LL_RECV_RAM(input wire [5:0] ram_sel, input wire [15:0] addr, input integer items, input integer valid_it);
 reg [13999:0] lbuf;
 integer i;
begin
 rcv_drv.E_SEL({`Eth_SelType_RAM,ram_sel});
 rcv_drv.E_DUP(1);
 rcv_drv.E_SN(inp_sn);
 rcv_drv.E_DATA(addr,items,lbuf);
 for(i=0;i<rep_cnt;i=i+1)
  begin
   if (i>valid_it)
    begin
     rcv_drv.E_SEL(0);
     rcv_drv.E_DATA(0,`STATUS_SCALE_LENGTH/4,lbuf);
    end
   rcv_drv.WAIT;
  end

 inp_sn = inp_sn>=3?1:inp_sn+1;

 rcv_drv.E_NONE;
end
endtask

// Internal manipulations (outgoing)
task LL_INT_BG(input wire [`STATUS_SCALE_LENGTH*8-1:0] bg_image);
begin
 bg_img = bg_image;
end
endtask

task LL_INT_MARK_MODIF(input integer modif_sc, input wire [8:0] addr);
begin
 mc_wr_addr = addr;
 @(posedge clk);
 mc_wr_stb <= modif_sc;
 @(posedge clk);
 mc_wr_stb <= 0;
end
endtask

//////////////////////////// Hi level primitives /////////////////////////////////
task HL_WRITE_MEMORY;
 reg ram_sel;
 reg [15:0] addr;
 integer items;
begin
 ram_sel=$random();
 addr=$random();
 items=1+($unsigned($random())%20);
 $display("(%0t) Eth: Write Memory: Sel=%b, Addr=%h, Items=%0d",$time,ram_sel,addr,items);
 fork
  LL_SEND_RAM({4'b0,ram_sel},addr,items);
  LL_EXP_RAM({4'b0,ram_sel},addr,items);
 join
 $display("(%0t) Eth: Write Memory Done",$time);
end
endtask

task HL_READ_MEMORY;
 reg ram_sel;
 reg [15:0] addr;
 reg [15:0] addr2;
 integer items;
begin
 ram_sel=$random();
 addr=$random()&16'h01FF;
 items=1+($unsigned($random())%20);
 $display("(%0t) Eth: Read Memory: Sel=%b, Addr=%h, Items=%0d",$time,ram_sel,addr,items);
 addr2 = addr+items-1;
 LL_SEND_REG(`REG_SIDX_ETH_REQ,{7'b0,ram_sel},{addr2,addr});
 LL_RECV_RAM({4'b0,ram_sel},addr,items,10000);
 $display("(%0t) Eth: Read Memory Done",$time);
end
endtask

task HL_WRITE_REG;
 reg [7:0] addr;
 reg [7:0] saddr;
 reg [31:0] data;
begin

 addr=2+($unsigned($random())%120);
 saddr=$random();
 data=$random();
 $display("(%0t) Eth: Write REG: [%0h.%0h] <= %0h",$time,addr,saddr,data);
 fork
  LL_SEND_REG(addr,saddr,data);
  LL_EXP_REG(addr,saddr,data);
 join
 $display("(%0t) Eth: Write REG Done",$time);
end
endtask

task HL_WRITE_FIFO;
 reg [4:0] fifo_sel;
 reg [15:0] addr;
 integer items;
begin
 fifo_sel=$random();
 addr=$random();
 items=1+($unsigned($random())%20);
 $display("(%0t) Eth: Write FIFO: Sel=%0h, Addr=%h, Items=%0d",$time,fifo_sel,addr,items);
 fork
  LL_SEND_FIFO(fifo_sel,addr,items);
  LL_EXP_FIFO(fifo_sel,addr,items);
 join
 $display("(%0t) Eth: Write FIFO Done",$time);
end
endtask

task HL_CHNG_CTRL(input wire clr_ferr);
 reg [31:0] c;
begin
 c=$random();
 $display("(%0t) Eth: Change CTRL %0h",$time,{c,clr_ferr});
 fork
  LL_SEND_CTRL({c,clr_ferr});
  LL_EXP_CTRL({c,clr_ferr});
 join
 $display("(%0t) Eth: Change CTRL Done",$time);
end
endtask

task HL_CHNG_BG;
 reg [13999:0] lbuf;
begin
 rcv_drv.E_DATA(0,`STATUS_SCALE_LENGTH/4,lbuf);
 $display("(%0t) Eth: Set BG %0h",$time,lbuf);
 LL_INT_BG(lbuf);
 LL_RECV_BG(lbuf,1'b0); 
end
endtask

task HL_CHNG_MEM;
 reg [8:0] min1_addr;
 reg [8:0] max1_addr;
 reg use1;

 reg [8:0] min2_addr;
 reg [8:0] max2_addr;
 reg use2;

 reg [8:0] min_rg_addr;
 reg [8:0] max_rg_addr;
 reg use_rg;
 
 reg lock_sel;

 integer i;
 reg [8:0] j;

 integer exp_sel;
 integer exp_cnt;
 reg exp_abt;

 reg [13999:0] lbuf;

begin
 use1 = 1'b0;
 use2 = 1'b0;
 use_rg = 1'b0;
 exp_sel = 0;
 exp_cnt = 1;
 exp_abt = 1'b0;
 lock_sel = 1'b0;
 
 for(i=0;i<1000;i=i+1)
 begin
  @(negedge tx_en);
  if (!lock_sel)
  case($random()&7)
   2'd1:
    begin
     j=$random()&32'hFF;
     if (!use1) begin use1=1'b1; min1_addr=j; max1_addr=j; end else
      begin
       if (j<min1_addr) min1_addr=j;
       if (j>max1_addr) max1_addr=j;
       if (exp_sel==1) exp_abt=1'b1;
      end
     $display("(%0t) SeqTest: Modif RAM0 at %0h",$time,j);
     LL_INT_MARK_MODIF(2'b1,j);
     lock_sel = 1'b1;
    end

   2'd2:
    begin
     j=$random()&32'hFF;
     if (!use2) begin use2=1'b1; min2_addr=j; max2_addr=j; end else
      begin
       if (j<min2_addr) min2_addr=j;
       if (j>max2_addr) max2_addr=j;
       if (exp_sel==2) exp_abt=1'b1;
      end
     $display("(%0t) SeqTest: Modif RAM1 at %0h",$time,j);
     LL_INT_MARK_MODIF(2'd2,j);
     lock_sel = 1'b1;
    end

   2'd3:
    if (!use_rg)
     begin
      j=$random()&9'h0FF;
      min_rg_addr = j;
      j=$random()&9'h0FF;
      max_rg_addr = min_rg_addr + j;
      use_rg=1'b1;
      $display("(%0t) SeqTest: Read RAM0 at %0h-%0h",$time,min_rg_addr,max_rg_addr);
      LL_SEND_REG(`REG_SIDX_ETH_REQ,8'b0,{7'b0,max_rg_addr,7'b0,min_rg_addr});
      lock_sel = 1'b1;
     end
  endcase

  if (exp_sel==0) // try to shedule new request
   begin
    if (use1) exp_sel=1; else
    if (use2) exp_sel=2; else
    if (use_rg) exp_sel=3;
    if (exp_sel) $display("(%0t) SeqTest: Start recv %0s",$time,DecSel(exp_sel));
    exp_abt=1'b0;
    exp_cnt=1;
    lock_sel = 1'b0;
   end

  if (exp_sel!=0) // we still expect some data from prev request
   begin
    rcv_drv.E_SN(inp_sn);
    rcv_drv.E_DUP(exp_cnt);
    $display("(%0t) SeqTest: Expected %0s SN=%0d, Dup=%0d",$time,DecSel(exp_sel),inp_sn,exp_cnt);
    if (exp_abt) 
     begin
      $display("(%0t) SeqTest: Expected aborted BG",$time);
      rcv_drv.E_SEL(0);
      rcv_drv.E_DATA(0,`STATUS_SCALE_LENGTH/4,lbuf);
     end
    else if (exp_sel==1)
     begin
      rcv_drv.E_SEL({`Eth_SelType_RAM,6'b0});
      rcv_drv.E_DATA(min1_addr,max1_addr-min1_addr+1,lbuf);
     end
    else if (exp_sel==2)
     begin
      rcv_drv.E_SEL({`Eth_SelType_RAM,6'b1});
      rcv_drv.E_DATA(min2_addr,max2_addr-min2_addr+1,lbuf);
     end
    else if (exp_sel==3)
     begin
      rcv_drv.E_SEL({`Eth_SelType_RAM,6'b0});
      rcv_drv.E_DATA(min_rg_addr,max_rg_addr-min_rg_addr+1,lbuf);
     end
    exp_cnt = exp_cnt+1;
    if (exp_cnt>rep_cnt) // done input pkt sequence
     begin
      if (!exp_abt)
       case(exp_sel)
        1: use1 = 1'b0;
        2: use2 = 1'b0;
        3: use_rg = 1'b0;
       endcase
      exp_sel=0;
      exp_abt=1'b0;
      exp_cnt=1;
      inp_sn = inp_sn>=3?1:inp_sn+1;
     end
   end
  else
   begin
     $display("(%0t) SeqTest: Nothing special Expected",$time);
     rcv_drv.E_SEL(`Eth_SelGen_BG);
     rcv_drv.E_DUP(0);
     rcv_drv.E_SN(0);
     rcv_drv.E_DATA(0,`STATUS_SCALE_LENGTH/4,lbuf);
    end

 end

end
endtask

function [31:0] hash(input wire [31:0] data);
begin
 hash = data*32'h243BCA56+32'h098FCBF9;
end
endfunction

function [127:0] DecSel(input integer sel);
begin
 case(sel)
  0: DecSel = "None";
  1: DecSel = "RAM0";
  2: DecSel = "RAM1";
  3: DecSel = "RAM0 Req";
 endcase
end
endfunction

initial
begin
 $timeformat ( -9,0," ns",15);
 #2000;
 LL_SEND_REG(`REG_SIDX_ETH_TIMES,3,32'h0064_0064);
 @(negedge tx_en);
 HL_WRITE_MEMORY;
 HL_READ_MEMORY;
 #100000;
 HL_WRITE_REG;
 HL_WRITE_FIFO;
 HL_CHNG_CTRL(1'b0);
 HL_CHNG_BG;
 HL_CHNG_MEM;
 
     rcv_drv.E_SEL(`Eth_SelGen_BG);
     rcv_drv.E_DUP(0);
     rcv_drv.E_SN(0);
 #10000;
 $stop(); 
end

endmodule

////////////////////////////////////////////////////////////////
module RamEmu #(parameter IDX=0)
(
 input wire clk,

 input wire [8:0] ram_addr_i,
 input wire ram_cs_i,
 input wire ram_we_i,
 input wire [31:0] ram_data_i,
 output wire [31:0] ram_data_o
);

reg [31:0] outv = 0;
assign ram_data_o = outv;

always @(posedge clk)
if (ram_cs_i)
 if (!ram_we_i)
  begin
   $display("(%0t) RAM#%0d: Read %0h => %0h",$time,IDX,ram_addr_i,hash(ram_addr_i));
   outv <= hash(ram_addr_i);
  end
 else if (ram_data_i !== hash(ram_addr_i))
  begin
   $display("(%0t) RAM#%0d: *** Error ***: Invalid write data %0h <= %0h (should be %0h)",$time,IDX,ram_addr_i,ram_data_i,hash(ram_addr_i));
  end
 else
  begin
   $display("(%0t) RAM#%0d: Write %0h <= %0h",$time,IDX,ram_addr_i,ram_data_i);
  end
  
function [31:0] hash(input wire [31:0] data);
begin
 hash = data*32'h243BCA56+32'h098FCBF9;
end
endfunction

endmodule
