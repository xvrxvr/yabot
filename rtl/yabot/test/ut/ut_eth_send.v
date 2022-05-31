`timescale 1ns / 1ps

module ut_eth_send;

reg clk = 1;

initial forever #50 clk <= ~clk;

wire tx_en;
wire [3:0] txd;

reg start =0;
reg reset_sn =0;

wire busy_o;
wire done_o;

reg [3:0] sn = 0;
reg [7:0] sel = 0;

reg [8:0] modif_start = 0;
reg [8:0] modif_end = 0;

wire [8:0] erd_addr;
wire erd_read;
wire  [3:0] erd_data;
wire erd_read_en;

reg [319:0] bg_img = 0;

reg [13999:0] data_buf = 0;

EthSend eth
(
 .clk(clk),

 .start_i(start), // Start pkt send. All selected ModifChk & Arbiter2 should be enabled (to turn on thier bus signals)

 .reset_sn_i(reset_sn), // Reset 'll' field of S/N

 .busy_o(busy),
 .done_o(done),

 .sn_i(sn),
 .sel_i(sel),

 ////// Attach to ModifChk (bus signals)
 .modif_start_i(modif_start),
 .modif_end_i(modif_end),

 ////// Attach to Arbiter2
  // Bus signals (for all Arbiter2 in parallel)
 .erd_addr_o(erd_addr),
 .erd_read_o(erd_read),
 .erd_data_i(erd_data),
  // Single signals - for each selected Arbiter in separate
 .erd_read_en_o(erd_read_en),


 .bg_img_i(bg_img),

// PHY interface
 .tx_en(tx_en),
 .txd(txd)
);

integer data_in_read = 0;
integer data_ptr = 0;

always @(posedge clk)
 begin
  if (erd_read_en && !data_in_read)
   begin
    data_in_read <= 1;
    data_ptr <= 3;
   end
  if (erd_read)
   begin
    data_ptr <= data_ptr+4;
   end
 end

assign erd_data = data_buf[ data_ptr -: 4];

BEthRx beth (
 .clk(clk),
 .rxd(txd),
 .rx_en(tx_en)
);


task SET_DATA(input integer sel_i, input integer addr_i, input integer len_i);
begin
 beth.E_DATA(addr_i,len_i<10?10:len_i,data_buf);
 beth.E_SEL(sel_i);
 sel = sel_i;
 modif_start = addr_i;
 modif_end = addr_i+len_i-1;
 bg_img = data_buf[319:0];
end
endtask

task SET_SN(input integer sn_i, input integer dup_i);
begin
 sn = {dup_i[1:0], sn_i[1:0]};
 beth.E_SN(sn_i);
 beth.E_DUP(dup_i);
end
endtask

task RESET_LL;
begin
 beth.E_LL(0);
 @(posedge clk);
 reset_sn <= 1;
 @(posedge clk);
 reset_sn <= 0;
 @(posedge clk);
end
endtask

task START;
begin
 data_in_read = 0;

 @(posedge clk);
 start <= 1'b1;
 @(posedge clk);
 start <= 1'b0;

 beth.WAIT;

 sn[3:2] = sn[3:2]+1;

end
endtask

always @(posedge busy) $display("(%0t) Eth Send: Start cycle",$time);
always @(negedge busy) $display("(%0t) Eth Send: End cycle",$time);
always @(posedge clk) if (done) $display("(%0t) Eth Send: Done pulse",$time);

task SEND_BG_SN(input integer sn_i, input integer dup_i);
begin
 $display("(%0t) Eth Send: Sending BG pkt",$time);
 SET_SN(sn_i,dup_i);
 SET_DATA(0,0,10);
 START;
end
endtask

task SEND_BG;
begin
 SEND_BG_SN(0,0);
end
endtask

task SEND_MEM(input integer sn_i, input integer dup_i, input integer mem_idx, input integer addr, input integer cnt);
begin
 $display("(%0t) Eth Send: Sending MEM pkt",$time);
 SET_SN(sn_i,dup_i);
 SET_DATA({2'b10,mem_idx[5:0]},addr,cnt);
 START;
 if (!data_in_read) beth.error("No data was read from RAM!");
end
endtask

integer ii;
integer my_sn=0;

function [1:0] gsn(input integer i);
begin
 gsn=my_sn;
 my_sn=my_sn+1;
 if (my_sn>3) my_sn=1;
end
endfunction

initial begin

 $timeformat ( -9,0," ns",15);
 #2000;

 SEND_BG;
 SEND_BG;
 SEND_BG_SN(1,1);
 SEND_BG_SN(1,2);

 SEND_MEM(1,1,0,0,5);
 SEND_MEM(2,1,0,0,10);
 SEND_MEM(3,1,0,0,15);
 SEND_MEM(1,1,1,123,10);
 START;
 START;

 for(ii=0;ii<10000;ii=ii+1)
 begin
  case ($random() & 3)
   0: SEND_BG;
   1: begin SEND_BG_SN(my_sn,1); SEND_BG_SN(my_sn,2); SEND_BG_SN(gsn(1),3); end
   2, 3: SEND_MEM(gsn(1),1,$random()&3,$random()&15,1+($unsigned($random())%100));
  endcase
 end
 
 #1000;
 
 if (beth.err_cnt) $display("Total errors: %0d",beth.err_cnt);
 
 $stop;
end

endmodule
