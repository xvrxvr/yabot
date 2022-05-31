`timescale 1ns / 1ps

`include "rtl/eth.inc"

module ut_eth_recv;

reg clk =0;
reg clk4 =0;

wire rx_clk;
wire rx_er;
wire rx_dv;
wire [3:0] rxd;

wire pkt_ok;     // Pkt recieved Ok
wire pkt_err;    // Err pkt recieved
wire eth_active; // Pkt recieve in progress

wire [3:0] pkt_stat1; // Statistics output (group 1)
wire [3:0] pkt_stat2; // Statistics output (group 2)
wire [2:0] pkt_fatal_err; // Fatal error bits (sticky bits)

wire [15:0] bus_addr;      // address of RAM/Registers 
wire [31:0] bus_data;      // data for RAM/Registers

wire sel_register;         // Write to Eth_SelType_Generic/Reg
wire sel_fifo;             // Write to Eth_SelType_FIFO
wire sel_ram;              // Write to RAM

wire [5:0] sel_index;      // index of active selector

wire wr_stb;

wire [127:0] ctrl_out; // Output control vector

EthRecv dut (
 .clk(clk), .clk4(clk4), 

 .pkt_ok(pkt_ok),     // Pkt recieved Ok
 .pkt_err(pkt_err),    // Err pkt recieved
 .eth_active(eth_active), // Pkt recieve in progress

 .pkt_stat1(pkt_stat1), // Statistics output (group 1)
 .pkt_stat2(pkt_stat2), // Statistics output (group 2)
 .pkt_fatal_err(pkt_fatal_err), // Fatal error bits (sticky bits)

// PHY interface
 .rx_clk(rx_clk),
 .rx_er_i(rx_er),
 .rx_dv_i(rx_dv),
 .rxd_i(rxd),

// Bus interface
 .bus_addr(bus_addr),      // address of RAM/Registers 
 .bus_data(bus_data),      // data for RAM/Registers

// Selector output
 .sel_register(sel_register),         // Write to Eth_SelType_Generic/Reg
 .sel_fifo(sel_fifo),             // Write to Eth_SelType_FIFO
 .sel_ram(sel_ram),              // Write to RAM

 .sel_index(sel_index),      // index of active selector

 .wr_stb(wr_stb),

// Control
 .ctrl_out(ctrl_out) // Output control vector
);

BEthTx drv (.clk_o(rx_clk),.dout_o(rxd),.dv_o(rx_dv),.derr_o(rx_er));

initial begin
 #10;
 forever #20 clk <= ~clk;
end

initial begin
 #25;
 forever #5 clk4 <= ~clk4;
end

`define E_RAM   4'd0
`define E_FIFO  4'd1
`define E_REG   4'd2
`define E_OK    4'd3
`define E_ERR   4'd4
`define E_BG    4'd5

`define E_START 4'd6
`define E_END   4'd7

`define E_STA   4'd8
`define E_FATAL 4'd9

task e_name(input integer code, output reg [128:0] name);
begin
 case(code)
  `E_RAM:  name="Ram";
  `E_FIFO: name="Fifo";
  `E_REG:  name="Reg";
  `E_OK:   name="PktOk";
  `E_ERR:  name="PktErr";
  `E_BG:   name="BG";

  `E_START: name="Start";
  `E_END:   name="End";

  `E_STA:   name="Status";
  `E_FATAL: name="Fatal";
 endcase
end
endtask


// sta_1: main actions: code(4)+sel(6)+addr(16)+data(32)
//  for bg: code(4)+bg(54)
reg [57:0] sta_1 [0:1000];

// sta_2: stat processing: code(4)+sta1(4)+sta2(4)+fatal(3)
reg [14:0] sta_2 [0:1000];

integer sta_ptr_w1 = 0;
integer sta_ptr_r1 = 0;
integer sta_ptr_w2 = 0;
integer sta_ptr_r2 = 0;

task E_AT_RESET;
begin
 sta_ptr_w1=0;
 sta_ptr_r1=0;
 sta_ptr_w2=0;
 sta_ptr_r2=0;
end
endtask

task dmp_sta_1(input [1280:0] msg, input [57:0] sta);
reg [128:0] nm;
begin
 e_name(sta[57 -: 4],nm);
 $display("%0s %0s: Sel=%0d, Addr=%0h, Data=%0h",msg,nm,sta[53 -: 6], sta[47 -: 16], sta[31:0]);
end
endtask

task dmp_sta_2(input [1280:0] msg, input [14:0] sta);
reg [128:0] nm;
begin
 e_name(sta[14 -: 4],nm);
 $display("%0s %0s: Sta1=%0d, Sta2=%0d, Fatal=%0d",msg,nm,sta[10 -: 4], sta[6 -: 4], sta[2:0]);
end
endtask

task E_AT_END;
begin
 if (sta_ptr_w1>sta_ptr_r1 || sta_ptr_w2>sta_ptr_r2)
  error("Not all expected actions hits!");
end
endtask

task e_exp(input [3:0] type, input [5:0] sel, input [15:0] addr, input [31:0] data);
begin
 sta_1[sta_ptr_w1] = {type,sel,addr,data};
 sta_ptr_w1=sta_ptr_w1+1;
 if (type>=`E_START)
 begin
  sta_2[sta_ptr_w2] = {type,11'b0};
  sta_ptr_w2=sta_ptr_w2+1;
 end
end
endtask

task e_exp2(input [3:0] type, input [3:0] sta1, input [3:0] sta2, input [2:0] s_fatal);
begin
  sta_2[sta_ptr_w2] = {type,sta1,sta2,s_fatal};
  sta_ptr_w2=sta_ptr_w2+1;
end
endtask

task e_hit(input [3:0] type, input [5:0] sel, input [15:0] addr, input [31:0] data);
begin
 if (sta_ptr_r1>=sta_ptr_w1)
  begin
   error("Unexpected events recorded on CH1");
  end
 else if (type!==sta_1[sta_ptr_r1][57 -: 4])
  begin
   error("Unexpected event type on CH1");
   dmp_sta_1("* Expected:",sta_1[sta_ptr_r1]);
   dmp_sta_1("* Recieved:",{type,sel,addr,data});
  end
 else if ({type,sel,addr,data} !== sta_1[sta_ptr_r1])
  begin
   error("Arguments missmatch on CH1");
   dmp_sta_1("* Expected:",sta_1[sta_ptr_r1]);
   dmp_sta_1("* Recieved:",{type,sel,addr,data});
  end
 sta_ptr_r1=sta_ptr_r1+1;
end
endtask

task e_hit_bg(input [53:0] data);
begin
 if (sta_ptr_r1>=sta_ptr_w1)
  begin
   error("Unexpected events recorded on CH1");
  end
 else if (`E_BG!==sta_1[sta_ptr_r1][57 -: 4])
  begin
   error("Unexpected event type on CH1");
   dmp_sta_1("* Expected:",sta_1[sta_ptr_r1]);
   dmp_sta_1("* Recieved:",{`E_BG,data});
  end
 else if ({`E_BG,data} !== sta_1[sta_ptr_r1])
  begin
   error("Arguments missmatch on CH1");
   dmp_sta_1("* Expected:",sta_1[sta_ptr_r1]);
   dmp_sta_1("* Recieved:",{`E_BG,data});
  end
 sta_ptr_r1=sta_ptr_r1+1;
end
endtask

task e_hit2(input [3:0] type, input [3:0] sta1, input [3:0] sta2, input [2:0] s_fatal);
begin
 if (sta_ptr_r2>=sta_ptr_w2)
  begin
   error("Unexpected events recorded on CH2");
  end
 else if (type!==sta_2[sta_ptr_r2][14 -: 4])
  begin
   error("Unexpected event type on CH2");
   dmp_sta_2("* Expected:",sta_2[sta_ptr_r2]);
   dmp_sta_2("* Recieved:",{type,sta1,sta2,s_fatal});
  end
 else if ({type,sta1,sta2,s_fatal} !== sta_2[sta_ptr_r2])
  begin
   error("Arguments missmatch on CH2");
   dmp_sta_2("* Expected:",sta_2[sta_ptr_r2]);
   dmp_sta_2("* Recieved:",{type,sta1,sta2,s_fatal});
  end
 sta_ptr_r2=sta_ptr_r2+1;
end
endtask

/////////////
task EXP_START;
begin
 e_exp(`E_START,0,0,0);
end
endtask

task EXP_DONE_OK(input [2:0] sn);
begin
 if (sn) e_exp2(`E_STA,{sn,2'b0},0,0);
 else e_exp2(`E_STA,0,`Eth_PKT2_BG_SUCCESS,0);
 e_exp(`E_OK,0,0,0);
 e_exp(`E_END,0,0,0);
end
endtask

task EXP_DONE_ERR(input [3:0] sta1, input [3:0] sta2);
begin
 e_exp2(`E_STA,sta1,sta2,0);
 e_exp(`E_ERR,0,0,0);
 e_exp(`E_END,0,0,0);
end
endtask

task EXP_DONE_ERR_PURE;
begin
 e_exp(`E_ERR,0,0,0);
 e_exp(`E_END,0,0,0);
end
endtask

task EXP_DONE_FATAL(input [2:0] sta);
begin
 e_exp2(`E_FATAL,0,0,sta);
 e_exp(`E_ERR,0,0,0);
 e_exp(`E_END,0,0,0);
end
endtask

task EXP_FATAL(input [2:0] sta);
begin
 e_exp2(`E_FATAL,0,0,sta);
end
endtask

task EXP_BG(input [53:0] data);
begin
 sta_1[sta_ptr_w1] = {`E_BG,data};
 sta_ptr_w1=sta_ptr_w1+1;
end
endtask

task EXP_RAM(input [5:0] sel, input [15:0] addr, input [31:0] data);
begin
 e_exp(`E_RAM,sel,addr,data);
end
endtask

task EXP_FIFO(input [5:0] sel, input integer addr, input [31:0] data);
begin
 e_exp(`E_FIFO,sel,addr,data);
end
endtask
////////////////////

always @(posedge clk)
begin
 if (wr_stb && (sel_register||sel_fifo||sel_ram))
 begin
  if (sel_register+sel_fifo+sel_ram>1) error("More than 1 CS active"); else
  begin
   $display("(%0t) UT EthRecv: Write stb %0s (idx %0d) [%0h] <= %0h",
    $time,sel_register?"Reg":sel_fifo?"Fifo":"RAM",
    sel_index,bus_addr,bus_data);
   e_hit(sel_register?`E_REG:sel_fifo?`E_FIFO:`E_RAM,sel_index,bus_addr,bus_data);
  end 
 end

 if (pkt_ok) 
  begin
   $display("(%0t) UT EthRecv: Pkt OK",$time);
   e_hit(`E_OK,0,0,0);
  end
  
 if (pkt_err) 
  begin
   $display("(%0t) UT EthRecv: Pkt Error recieved",$time);
   e_hit(`E_ERR,0,0,0);
  end

 if (pkt_stat1!=0) $display("(%0t) EthRecv: Status1 is %0h",$time,pkt_stat1);
 if (pkt_stat2!=0) $display("(%0t) EthRecv: Status2 is %0h",$time,pkt_stat2);
 if (pkt_stat1 || pkt_stat2) e_hit2(`E_STA,pkt_stat1,pkt_stat2,0);
end

reg prev_eth_act = 0;
always @(posedge clk)
if (eth_active!==prev_eth_act)
begin
 if (eth_active)
  begin
   $display("(%0t) EthRecv: Eth is on",$time);
   e_hit(`E_START,0,0,0);
   e_hit2(`E_START,0,0,0);
  end
 else
  begin
   $display("(%0t) EthRecv: Eth is off",$time);
   e_hit(`E_END,0,0,0);
   e_hit2(`E_END,0,0,0);
  end
 prev_eth_act=eth_active;
end

reg [2:0] prev_fatal_err = 0;
always @(posedge clk)
if (prev_fatal_err !== pkt_fatal_err)
begin
 $display("(%0t) EthRecv: PktFatalErr = %0d",$time,pkt_fatal_err);
 e_hit2(`E_FATAL,0,0,pkt_fatal_err);
 prev_fatal_err = pkt_fatal_err;
end

reg [127:0] prev_bg = 0;
always @(posedge clk)
if (prev_bg!==ctrl_out)
begin
 $display("(%0t) EthRecv: BG = %0b",$time,ctrl_out);
 e_hit_bg(ctrl_out);
 prev_bg=ctrl_out;
end

integer err_count = 0;

task error(input [8191:0] msg);
begin
 $display("(%0t) UT EthRecv ERROR: %0s",$time,msg);
 err_count = err_count+1;
end
endtask

task exp(input [8191:0] msg);
begin
 E_AT_END;
 $display("\n(%0t) UT EthRecv Test: %0s",$time,msg);
 E_AT_RESET;
 EXP_START;
end
endtask

initial
begin
 $timeformat ( -9,0," ns",15);
 #2000;

 exp("Send zero 2w BG pkt");
 EXP_DONE_OK(0);
 drv.SENDP(64'd0,2,0);
 
 exp("Send 55AA 1w BG pkt");
 EXP_BG(32'h55AA);
 EXP_DONE_OK(0);
 drv.SENDP(32'h55AA,1,0);
 
 exp("Send 5A5A 55AA 2w memory to sel 2");
 drv.SET_ADDR(10);
 EXP_RAM(2,10,32'h5A5A);
 EXP_RAM(2,11,32'h55AA);
 EXP_DONE_OK(1);
 drv.SENDP(64'h000055AA_00005A5A,2,8'h82);
 
 exp("send 12345678 87654321 2w FIFO to sel 0");
 EXP_FIFO(0,0,32'h12345678);
 EXP_FIFO(0,1,32'h87654321);
 EXP_DONE_OK(1); 
 drv.SENDP(64'h87654321_12345678,2,8'h40);

 drv.RESET_SN(2);

 exp("Send 55AA 1w memory to sel 0 (2 pkt) - wrong SN expected");
 EXP_DONE_FATAL(`Eth_FATAL_SN_GAP);
 EXP_START;
 EXP_DONE_ERR_PURE;
 drv.SENDP(32'h00005A5A,1,8'h80);

 drv.RESET_SN(2);
 
 exp("Send 01 1w BG pkt (reset error state)");
 EXP_BG(1);
 EXP_FATAL(0);
 EXP_DONE_OK(0);
 drv.SENDP(31'd1,1,0);

 exp("Send 00 1w BG pkt (reset error state)");
 EXP_BG(0);
 EXP_DONE_OK(0);
 drv.SENDP(31'd0,1,0);

 exp("Send 5A5A 1w memory to sel 0 (2 pkt)");
 EXP_RAM(0,0,32'h5A5A);
 EXP_DONE_OK(1);
 
 EXP_START;
 EXP_DONE_OK(2);
 
 drv.SENDP(32'h00005A5A,1,8'h80);

`define SERR_B2B_TRANS 512

 exp("Send 5A5A 1w memory to sel 0 (2 pkt) B2B trans");
 drv.SET_ERR_SC(`SERR_B2B_TRANS);
 EXP_RAM(0,0,32'h5A5A);
 EXP_DONE_OK(1);
 
 drv.SENDP(32'h00005A5A,1,8'h80);
 drv.WAIT;
 #1000;

`define SERR_ETYPE 1
 exp("Send 00 1w BG pkt: ETYPE");
 drv.SET_ERR_SC(`SERR_ETYPE);
 EXP_DONE_ERR(0,`Eth_ERR2_PKT_ALIEN);
 drv.SENDP(31'd0,1,0);

`define SERR_HCRC  2
 exp("Send 00 1w BG pkt: HCRC");
 drv.SET_ERR_SC(`SERR_HCRC);
 EXP_DONE_ERR(0,`Eth_ERR2_CRC_HDR);
 drv.SENDP(31'd0,1,0);

`define SERR_BCRC  16
 exp("Send 00 1w BG pkt: BCRC");
 drv.SET_ERR_SC(`SERR_BCRC);
 EXP_DONE_ERR(`Eth_ERR1_CRC_DATA,0);
 drv.SENDP(31'd0,1,0);

`define SERR_FCRC  32
 exp("Send 01 1w BG pkt: FCRC");
 drv.SET_ERR_SC(`SERR_FCRC);
 EXP_BG(1);
 EXP_DONE_ERR(`Eth_ERR1_CRC_FTR,0);
 drv.SENDP(31'd1,1,0);

`define SERR_NOPAD 64
 exp("Send 00 1w BG pkt: NOPAD");
 drv.SET_ERR_SC(`SERR_NOPAD);
 EXP_BG(0);
 EXP_DONE_ERR(`Eth_ERR1_PHY_ERROR,`Eth_ERR2_TOO_SHORT);
 drv.SENDP(31'd0,1,0);

// RAM checks (SN of 1 expected)
 drv.RESET_SN(1);
 exp("Send 5555 to FIFO: BCRC");
 drv.SET_ERR_SC(`SERR_BCRC);
 EXP_DONE_ERR({2'b01,`Eth_ERR1_CRC_DATA},0);
 drv.SENDP(32'h5555,1,8'h40);

 drv.RESET_SN(1);
 exp("Send 5555 to RAM: FCRC");
 drv.SET_ERR_SC(`SERR_FCRC);
 EXP_RAM(0,0,32'h5555);
 EXP_DONE_ERR({2'b01,`Eth_ERR1_CRC_FTR},0);
 drv.SENDP(32'h00005555,1,8'h80);

 drv.RESET_SN(1);
 exp("Send 5555 to RAM: NOPAD");
 drv.SET_ERR_SC(`SERR_NOPAD);
 EXP_RAM(0,0,32'h5555);
 EXP_DONE_ERR({2'b01,`Eth_ERR1_PHY_ERROR},`Eth_ERR2_TOO_SHORT);
 drv.SENDP(32'h00005555,1,8'h80);

// FIFO check
 drv.RESET_SN(1);
 exp("Send 5555 to FIFO: FCRC");
 drv.SET_ERR_SC(`SERR_FCRC);
 EXP_FIFO(0,0,32'h5555);
 EXP_DONE_ERR({2'b01,`Eth_ERR1_CRC_FTR},0);
 drv.SENDP(32'h5555,1,8'h40);

 drv.RESET_SN(1);
 exp("Send 5555 to FIFO: NOPAD");
 drv.SET_ERR_SC(`SERR_NOPAD);
 EXP_FIFO(0,0,32'h5555);
 EXP_DONE_ERR({2'b01,`Eth_ERR1_PHY_ERROR},`Eth_ERR2_TOO_SHORT);
 drv.SENDP(32'h5555,1,8'h40);

`define SERR_LEN1   4
`define SERR_LEN2   8
`define SERR_LEN3  12

// Length check
 exp("Send 01 20w BG pkt: LEN1");
 drv.SET_ERR_SC(`SERR_LEN1);
 EXP_BG(1);
 EXP_DONE_ERR(`Eth_ERR1_PHY_ERROR,`Eth_ERR2_TOO_SHORT);
 drv.SENDP(31'd1,20,0);

 exp("Send 00 20w BG pkt: LEN2");
 drv.SET_ERR_SC(`SERR_LEN2);
 EXP_BG(0);
 EXP_DONE_ERR(`Eth_ERR1_PHY_ERROR,`Eth_ERR2_TOO_LONG);
 drv.SENDP(31'd0,20,0);

 exp("Send 01 20w BG pkt: LEN3");
 drv.SET_ERR_SC(`SERR_LEN3);
 EXP_DONE_FATAL(`Eth_FATAL_LEN_WRONG);
 drv.SENDP(31'd1,20,0);

 E_AT_END;
 
 #20000;

 if (err_count==0) $display("\nNo errors found!");
 else $display("\nFound %0d error(s)!",err_count);

 $stop;
end


endmodule
