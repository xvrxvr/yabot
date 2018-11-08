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
        $display("Error (%0t) %s PWM: Unexpected level (%d)", $time, NAME, data);
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
    $display("(%0t) %s PWM: Level %d", $time, NAME, level);
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
        $display("Error (%0t) %s PWM: Duty cycle value (%d) out of range (%d-%d)", $time, NAME, val, min_value, max_value);
        $stop();                
    end
    $display("(%0t) %s PWM: Duty cycle value = %d (%d-%d)", $time, NAME, val, min_value, max_value);
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
        $display("Error (%0t) %s PWM: Pulse value (%d) out of range (%d-%d)", $time, NAME, val, min_value, max_value);
        $stop();                
    end
    $display("(%0t) %s PWM: Pulse value = %d (%d-%d)", $time, NAME, val, min_value, max_value);
end
endtask

endmodule
