`timescale 1ns/1ps

`default_nettype none


module ut_uart_complex();

reg clk = 0;
reg clk2 = 0;

reg reg_cs = 0;
reg [31:0] reg_data =0;

wire empty;
wire data_in_stb;
wire [14:0] data_in_data;
  // hi bit - CONTROL signal
  // low bits - kind of control
  //  [0] - Send BREAK state

wire data_out_stb;
wire [16:0] data_out_data;
  // hi bit - CONTROL change (low bits)
  //  [0] - BREAK detected

wire [31:0] rx;
wire [31:0] tx;

always #5 clk2 <= ~clk2;
always #10 clk <= ~clk;

UARTS_Complex dut (

 .clk(clk2),
 .fifo_cs(data_in_stb),
 .fifo_data({17'b0,data_in_data}),
 .ram_stb(data_out_stb),
 .ram_data(data_out_data),
 .rx(rx),
 .tx(tx),

 .fatal_ovr(),
 .stat_semi_ovr()
);

initial begin
 #1;
 $readmemh("uartc.img",dut.st1_ram.mem);
end

wire [31:0] all_in_stb;
assign data_in_stb = |all_in_stb;

genvar i;
generate for(i=0;i<32;i=i+1) begin :bu
 wire l_in_stb;
 wire [9:0] l_in_data;

 assign all_in_stb[i]=l_in_stb;
 assign data_in_data = l_in_stb?{i[4:0],l_in_data}:'bz;

 BenchUART bu //#(parameter bits=10, divider=2*16) 
 (
  .clk(clk),
  .uart_tx(tx[i]),
  .uart_rx(rx[i]),

  .uart_indata_stb(data_out_stb && data_out_data[16:12]==i),
  .uart_indata_data(data_out_data[11:0]),

  .uart_outdata_stb(l_in_stb /*data_in_stb*/),
  .uart_outdata_data(l_in_data /*data_in_data*/),
  .uart_outdata_empty(1'b1 /*empty*/)
 );
end
endgenerate

function automatic toterr(input wire j);
begin
 toterr=bu[0].bu.error_cnt+bu[1].bu.error_cnt+bu[2].bu.error_cnt+bu[3].bu.error_cnt+
        bu[4].bu.error_cnt+bu[5].bu.error_cnt+bu[6].bu.error_cnt+bu[7].bu.error_cnt+
        bu[8].bu.error_cnt+bu[9].bu.error_cnt+bu[10].bu.error_cnt+bu[11].bu.error_cnt+
        bu[12].bu.error_cnt+bu[13].bu.error_cnt+bu[14].bu.error_cnt+bu[15].bu.error_cnt+
        bu[16].bu.error_cnt+bu[17].bu.error_cnt+bu[18].bu.error_cnt+bu[19].bu.error_cnt+
        bu[20].bu.error_cnt+bu[21].bu.error_cnt+bu[22].bu.error_cnt+bu[23].bu.error_cnt+
        bu[24].bu.error_cnt+bu[25].bu.error_cnt+bu[26].bu.error_cnt+bu[27].bu.error_cnt+
        bu[28].bu.error_cnt+bu[29].bu.error_cnt+bu[30].bu.error_cnt+bu[31].bu.error_cnt;
end
endfunction


task automatic UART_SEND(input wire [31:0] n, input wire [31:0] data);
begin
 case(n)
`define D(T) T: if (T==n) bu[T].bu.UART_SEND(data);
 `D(0) `D(1) `D(2) `D(3) `D(4) `D(5) `D(6) `D(7) `D(8) `D(9)
 `D(10) `D(11) `D(12) `D(13) `D(14) `D(15) `D(16) `D(17) `D(18) `D(19)
 `D(20) `D(21) `D(22) `D(23) `D(24) `D(25) `D(26) `D(27) `D(28) `D(29)
 `D(30) `D(31)
`undef D
 endcase
end
endtask

task automatic CHK_SEND(input wire [31:0] n);
begin
 case(n)
`define D(T) T: if (T==n) bu[T].bu.CHK_SEND;
 `D(0) `D(1) `D(2) `D(3) `D(4) `D(5) `D(6) `D(7) `D(8) `D(9)
 `D(10) `D(11) `D(12) `D(13) `D(14) `D(15) `D(16) `D(17) `D(18) `D(19)
 `D(20) `D(21) `D(22) `D(23) `D(24) `D(25) `D(26) `D(27) `D(28) `D(29)
 `D(30) `D(31)
`undef D
 endcase
end
endtask


task automatic gen_send_pack;
integer total,i, val, n;
begin
 total=$unsigned($random())%40+1;
 n=$random() & 1;

 $display("(%0t) Send %0d bytes",$time,total);
 for(i=0;i<total;i=i+1)
  begin
   if (!($random()&15)) // send break
    begin
     #5000;
     UART_SEND(n,{1'b1,9'b1});
     #20000;
     UART_SEND(n,{1'b1,9'b0});    
    end
   else 
    begin   
     val=$random()&16'hFF;
     UART_SEND(n,val);
    end
   val=$unsigned($random())%2000;
   repeat(val) @(posedge clk);
  end
 #200000;
 CHK_SEND(n);
`ifdef VERBOUSE    
 $display;
`endif 
end
endtask

task automatic UART_RECV(input wire [31:0] n, input wire [31:0] data);
begin
 case(n)
`define D(T) T: if (T==n) bu[T].bu.UART_RECV(data);
 `D(0) `D(1) `D(2) `D(3) `D(4) `D(5) `D(6) `D(7) `D(8) `D(9)
 `D(10) `D(11) `D(12) `D(13) `D(14) `D(15) `D(16) `D(17) `D(18) `D(19)
 `D(20) `D(21) `D(22) `D(23) `D(24) `D(25) `D(26) `D(27) `D(28) `D(29)
 `D(30) `D(31)
`undef D
 endcase
end
endtask

task automatic CHK_RECV(input wire [31:0] n);
begin
 case(n)
`define D(T) T: if (T==n) bu[T].bu.CHK_RECV;
 `D(0) `D(1) `D(2) `D(3) `D(4) `D(5) `D(6) `D(7) `D(8) `D(9)
 `D(10) `D(11) `D(12) `D(13) `D(14) `D(15) `D(16) `D(17) `D(18) `D(19)
 `D(20) `D(21) `D(22) `D(23) `D(24) `D(25) `D(26) `D(27) `D(28) `D(29)
 `D(30) `D(31)
`undef D
 endcase
end
endtask

task automatic gen_recv_pack;
integer total,i, val, n;
begin
 total=$unsigned($random())%40+1;
 n=$random() & 1;

 $display("(%0t) Recv %0d bytes",$time,total);
 for(i=0;i<total;i=i+1)
  begin
   if (!($random()&15)) // send break
    begin
     #5000;
     UART_RECV(n,{1'b1,11'b1});
     #20000;
     UART_RECV(n,{1'b1,11'b0});    
    end
   else 
    begin   
     val=$random()&16'hFF;
     UART_RECV(n,val);
    end
   val=$unsigned($random())%2000;
   repeat(val) @(posedge clk);
  end
 #200000;
 CHK_RECV(n);
`ifdef VERBOUSE    
 $display;
`endif
end
endtask


initial begin
 $timeformat ( -9,0," ns",15); 
 #2000;
 
 UART_SEND(0,32'h5555);
 
/*
 fork
  begin repeat(1000) gen_send_pack; end
  begin repeat(1000) gen_recv_pack; end
 join
*/

/* 
 bu.UART_SEND(16'h005A);
 #20000;
 bu.CHK;
 bu.UART_RECV(16'h5A);
 #20000;
 bu.CHK;
 #20000;
 bu.UART_SEND(10'b1000000001);
 #20000;
 bu.CHK;
 bu.UART_SEND(10'b1000000000);
 #20000;
 bu.CHK;

 bu.UART_RECV(12'b100000000001);
 #20000;
 bu.CHK;
 bu.UART_RECV(12'b100000000000);
 #20000;
 bu.CHK;
*/
 
// $display("Total errors - %0d",toterr(0));
// $stop();

end



endmodule
