`timescale 1ns/1ps

`default_nettype none


module ut_uart_simple();

reg clk = 0;

reg reg_cs = 0;
reg [31:0] reg_data =0;

wire empty;
wire data_in_stb;
wire [9:0] data_in_data;
  // hi bit - CONTROL signal
  // low bits - kind of control
  //  [0] - Send BREAK state

wire data_out_stb;
wire [11:0] data_out_data;
  // hi bit - CONTROL change (low bits)
  //  [0] - BREAK detected

wire rx;
wire tx;

always #5 clk <= ~clk;

UART1_Simple dut (
 .clk(clk),
 .reg_cs(reg_cs),
 .reg_data(reg_data),
 .empty(empty),
 .data_in_stb(data_in_stb),
 .data_in_data(data_in_data),
 .data_out_stb(data_out_stb),
 .data_out_data(data_out_data),
 .rx(rx),
 .tx(tx)
);

BenchUART bu //#(parameter bits=10, divider=2*16) 
(
 .clk(clk),
 .uart_tx(tx),
 .uart_rx(rx),
 .uart_indata_stb(data_out_stb),
 .uart_indata_data(data_out_data),
 .uart_outdata_stb(data_in_stb),
 .uart_outdata_data(data_in_data),
 .uart_outdata_empty(empty)
);

task REG(input reg [31:0] d);
begin
 reg_data = d;
 @(posedge clk);
 reg_cs <= 1'b1;
 @(posedge clk);
 reg_cs <= 1'b0;
end
endtask

task automatic gen_send_pack;
integer total,i, val;
begin
 total=$unsigned($random())%40+1;
 if (bu.error_cnt) $display("(%0t) Send %0d bytes (*** %0d errors so far ***)",$time,total,bu.error_cnt);
 else $display("(%0t) Send %0d bytes",$time,total);
 for(i=0;i<total;i=i+1)
  begin
   if (!($random()&15)) // send break
    begin
     #5000;
     bu.UART_SEND({1'b1,9'b1});
     #20000;
     bu.UART_SEND({1'b1,9'b0});    
    end
   else 
    begin   
     val=$random()&16'hFF;
     bu.UART_SEND(val);
    end
   val=$unsigned($random())%2000;
   repeat(val) @(posedge clk);
  end
 #200000;
 bu.CHK_SEND;
`ifdef VERBOUSE    
 $display;
`endif 
end
endtask

task automatic gen_recv_pack;
integer total,i, val;
begin
 total=$unsigned($random())%40+1;
 if (bu.error_cnt) $display("(%0t) Recv %0d bytes(*** %0d errors so far ***)",$time,total,bu.error_cnt);
 else $display("(%0t) Recv %0d bytes",$time,total);
 for(i=0;i<total;i=i+1)
  begin
   if (!($random()&15)) // send break
    begin
     #5000;
     bu.UART_RECV({1'b1,11'b1});
     #20000;
     bu.UART_RECV({1'b1,11'b0});    
    end
   else 
    begin   
     val=$random()&16'hFF;
     bu.UART_RECV(val);
    end
   val=$unsigned($random())%2000;
   repeat(val) @(posedge clk);
  end
 #200000;
 bu.CHK_RECV;
`ifdef VERBOUSE    
 $display;
`endif
end
endtask


initial begin
 $timeformat ( -9,0," ns",15); 
 #2000;
 REG({4'd10,13'd1});
 #2000;

 fork
  begin repeat(1000) gen_send_pack; end
  begin repeat(1000) gen_recv_pack; end
 join

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
 
 $display("Total errors - %0d",bu.error_cnt);
 $stop();

end



endmodule
