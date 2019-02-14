`timescale 1ns / 1ps
`default_nettype none

module adapter_btn #(parameter NAME="")
(
   output wire sig
);

reg sig_out = 0;
assign sig = sig_out;


task set(input value);
integer i;
begin
    $display("(%0t) %s Button: Press started", $time, NAME);

    sig_out = value;
    for(i=0;i<10;i=i+1)
        #1000 sig_out = ~sig_out;
    sig_out = value;
    $display("(%0t) %s Button: Press done", $time, NAME);
end
endtask


task pulse(input integer width);
begin
    set(~sig_out);
    #width;
    set(~sig_out);
end
endtask

endmodule
