`timescale 1ns / 1ps

module ut_resync;
 wire s_dv;
 wire [4:0] s_rxd;
 wire ph_ovr;

reg clk = 0, clk4 = 0;

reg rx_clk =0;

reg rx_dv = 0;
reg [4:0] rxd = 0;

// Test bench vars
integer err_count = 0;
reg [4:0] data_buf [3000:0];
integer wr_ptr = 0;
integer rd_ptr = 0;
reg [4:0] last_data;
reg [4:0] last_pump_read, last_pump_write;

// Data pump
always @(negedge rx_clk) 
begin
 last_data = $random();
 rxd = last_data;
end

always @(posedge rx_clk)
if (rx_dv)
begin
 last_pump_write = last_data;
 data_buf[wr_ptr]=last_data;
 wr_ptr=wr_ptr+1;
 if (wr_ptr<=rd_ptr)
 begin
   $display("*** (%0t) Error: Data pump overwrite: WR_PTR=%0d, RD_PTR=%0d",$time,wr_ptr,rd_ptr);
   err_count=err_count+1;
 end
end

always @(posedge clk)
if (s_dv)
begin
 last_pump_read = data_buf[rd_ptr];
 if (last_pump_read!=s_rxd)
  begin
   $display("*** (%0t) Error: Data integrity error: Wrong byte at %0d: %h (should be %h)",$time,rd_ptr,s_rxd,last_pump_read);
   err_count=err_count+1;   
  end
 if (ph_ovr)
  begin
   $display("*** (%0t) Error: Phase error (at byte %0d)",$time,rd_ptr);
   err_count=err_count+1;   
  end
 rd_ptr = rd_ptr+1;
end

task RunTest;
integer len;
begin
 rd_ptr=0;
 wr_ptr=0;
 len = 100+($unsigned($random) % 2900);
 $display("(%0t) - Run for %0d nibbles",$time,len); 
 @(negedge rx_clk);
 rx_dv <= 1;
 repeat(len) @(negedge rx_clk);
 rx_dv <= 0;
 @(negedge s_dv);
 @(posedge clk);
 if (rd_ptr!=wr_ptr)
  begin
   $display("*** (%0t) Error: Read/Write counters missmatch: WR_PTR=%0d (%h), RD_PTR=%0d (%h)",$time,wr_ptr,last_pump_write,rd_ptr,last_pump_read);
   
   err_count=err_count+1;   
  end 
end
endtask

always
 #5 clk4 <= ~clk4;
 
always begin
 @(posedge clk4);
 clk <= 1;
 repeat(2) @(posedge clk4);
 clk <= 0;
 @(posedge clk4);
end

always //@* rx_clk <= clk;
 #20.01 rx_clk <= ~rx_clk;

initial begin
 $timeformat ( -9,0," ns",15);

 #2000;

 repeat(100000) begin
  RunTest;
  #1000;
 end
 
 #2000;

 $display("Total errors - %0d", err_count);
 
 $stop;
 
end


ResyncBlock resync(
 .clk(clk),
 .clk4(clk4), // clk*4

 // Input section
 .clk_in(rx_clk),
 .en_in(rx_dv), // Enable signal
 .d_in(rxd), // Input data

 // Output section
 .en_out(s_dv), // Enable signal
 .d_out(s_rxd), // Data

 // Error indicator
 .phase_overflow_err(ph_ovr) // Phase lock lost (not enough phase marging)

);

endmodule
