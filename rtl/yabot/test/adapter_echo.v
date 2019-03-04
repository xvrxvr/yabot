`timescale 1ns / 1ps
`default_nettype none

module adapter_echo #(parameter NAME="", DELAY=1000)
(
   output wire hc04_echo,
   input wire hc04_trigger
);

reg echo = 0;
assign hc04_echo = echo;
integer start;

always @(posedge hc04_trigger)
begin
	 start = $time;
    @(negedge hc04_trigger);
    if ($time-start < 10000)
    begin
        $display("Error (%0t) %s Echo: Strobe too short (%0d)", $time, NAME, $time-start);
        $stop();                
    end
    #1000;
    $display("(%0t) %s Echo: Start", $time, NAME);
    echo = 1'b1;
    #DELAY;
    echo = 1'b0;
    $display("(%0t) %s Echo: End", $time, NAME);
end

endmodule
