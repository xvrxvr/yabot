`timescale 1ns / 1ps
`default_nettype none

module adapter_pwm #(parameter NAME="", TIME=10000)
(
    input wire data
);

task check_level(input level);
event term;
begin
    if (level != data)
    begin
        $display("Error (%0t) %s PWM: Unexpected level (%0d)", $time, NAME, data);
        $stop();                
    end
    fork
    begin
        #TIME;
        -> term;
    end
    @(data or term)
        if (term)
        begin
            $display("Error (%0t) %s PWM: Not stable", $time, NAME);
            $stop();                
        end
    join
    $display("(%0t) %s PWM: Level %0d", $time, NAME, level);
end
endtask


task check_pwm(input integer min_value, input integer max_value);
integer i, j, k, val;
begin
    @(posedge data);
    i = $time;
    @(negedge data);
    j = $time;
    @(posedge data);
    k = $time;
    val = (j-i)*100/(k-i);
    if (val < min_value || val > max_value)
    begin
        $display("Error (%0t) %s PWM: Duty cycle value (%0d) out of range (%0d-%0d)", $time, NAME, val, min_value, max_value);
        $stop();                
    end
    $display("(%0t) %s PWM: Duty cycle value = %0d (%0d-%0d)", $time, NAME, val, min_value, max_value);
end
endtask

task check_pulse(input integer min_value, input integer max_value);
integer i, j, val;
begin
    @(posedge data);
    i = $time;
    @(negedge data);
    j = $time;
    val = (j-i);
    if (val < min_value || val > max_value)
    begin
        $display("Error (%0t) %s PWM: Pulse value (%0d) out of range (%0d-%0d)", $time, NAME, val, min_value, max_value);
        $stop();                
    end
    $display("(%0t) %s PWM: Pulse value = %0d (%0d-%0d)", $time, NAME, val, min_value, max_value);
end
endtask

endmodule
