`timescale 1ns / 1ps
`default_nettype none

module adapter_slave_spi #(parameter NAME="", MAX_WIDTH=8)
(
   input wire spi_clk,
   input wire spi_mosi,
   output wire spi_miso,
   input wire spi_cs
);

localparam MAX_DEPTH = 16;

integer total_patterns = 0;
integer cur_pattern = 0;
integer i;

reg [MAX_WIDTH-1:0] inp_patterns [MAX_DEPTH-1:0];
reg [MAX_WIDTH-1:0] out_patterns [MAX_DEPTH-1:0];
integer pat_width [MAX_DEPTH-1:0];
reg [MAX_WIDTH-1:0] out_reg = 0;
reg [MAX_WIDTH-1:0] inp_reg = 0;

assign spi_miso = out_reg[MAX_WIDTH-1];


always @(negedge spi_cs)
begin
    i = 0;
    out_reg = out_patterns[cur_pattern];
    inp_reg = 0;

    $display("(%0t) %s SPI: Started (%0h)", $time, NAME, out_reg);

    while (~spi_cs)
    begin
        @(posedge spi_clk or posedge spi_cs);
        if (~spi_cs)
        begin
            inp_reg = (inp_reg << 1) | spi_mosi;
            @(negedge spi_clk);
            out_reg = out_reg << 1;
            i = i + 1;
        end
    end
    $display("(%0t) %s SPI: Got %0h (in %0d bits)", $time, NAME, inp_reg, i);
    if (i != pat_width[cur_pattern])
    begin
        $display("Error (%0t) %s SPI: Wrong bit length of data - got %0d, expected %0d", $time, NAME, i, pat_width[cur_pattern]);
        $stop();        
    end
    if (inp_reg != inp_patterns[cur_pattern])
    begin
        $display("Error (%0t) %s SPI: Wrong recieved data - got %0h, expected %0h", $time, NAME, inp_reg, inp_patterns[cur_pattern]);
        $stop();        
    end
    cur_pattern = (cur_pattern + 1) % total_patterns;
end

task expect(input [MAX_WIDTH-1:0] inp_pat, input [MAX_WIDTH-1:0] out_pat, input integer len);
begin
    inp_patterns[total_patterns] = inp_pat;
    out_patterns[total_patterns] = out_pat;
    pat_width[total_patterns] = len;
    total_patterns = total_patterns + 1;
end
endtask

endmodule
