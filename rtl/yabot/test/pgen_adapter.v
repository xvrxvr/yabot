`timescale 1ns / 1ps
`default_nettype none

module pgen_adapter #(parameter NAME="")
(
   output wire pulse
);
reg pl = 0;
assign pulse = pl;

task run_pulses(input integer p_width, input integer freq, input integer total);
integer i;
begin
    $display("(%0t) %s Pulse: Generate %0d pulses of %0d width (%0d period)", $time, NAME, total, p_width, freq);
	 for(i=0; i<total; i=i+1)
	 begin
		pl = 1'b1;
		#p_width;
		pl = 1'b0;
		#(freq-p_width);
	 end
    $display("(%0t) %s Pulse: Done", $time, NAME);
end
endtask

task run_pwm(input integer duty_cycle, input integer freq, input integer total);
begin
    $display("(%0t) %s PWM: Duty cycle = %0d", $time, NAME, duty_cycle);
	run_pulses(freq*duty_cycle/100, freq, total);
end	
endtask


endmodule
