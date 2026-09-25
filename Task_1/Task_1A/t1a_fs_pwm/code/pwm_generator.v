// Logic Quest Bot : Task 1A : PWM Generator
/*
Instructions
-------------------
Students are not allowed to make any changes in the Module declaration.
This file is used to design a module which will scale down the clk_5MHz Clock Frequency to 500Hz and perform Pulse Width Modulation on it.

Recommended Quartus Version : 20.1
The submitted project file must be 20.1 compatible as the evaluation will be done on Quartus Prime Lite 20.1.

Warning: The error due to compatibility will not be entertained.
-------------------
*/

//PWM Generator
//Inputs : clk_5MHz, pulse_width
//Output : clk_500Hz, pwm_signal

module pwm_generator(
    input clk_5MHz,
    input reset_n,
    input [4:0] pulse_width,
    output reg clk_500Hz, pwm_signal
);

//////////////////DO NOT MAKE ANY CHANGES ABOVE THIS LINE //////////////////

/*
 add your code here 
 */

    // At 5 MHz, one clk_5MHz cycle is 200 ns. A 500 Hz period is
    // 2 ms = 10000 clk_5MHz cycles. A single free-running counter spans
    // that period, and both outputs come from comparing the counter
    // against a threshold ("counter-and-compare"):
    //   - clk_500Hz is high for the first half of the count (5000 cycles
    //     = 1 ms) and low for the second half -> a 50% duty 500 Hz clock.
    //   - pwm_signal is high while the counter is below a threshold set
    //     by pulse_width. The period splits into 20 slices of 500 cycles
    //     each (10000 / 20 = 500), so threshold = pulse_width * 500.
    //       pulse_width = 0  -> threshold = 0     -> always low  (0%)
    //       pulse_width = 20 -> threshold = 10000 -> always high (100%,
    //                            since the counter only reaches 0..9999)
    localparam [13:0] PERIOD = 14'd10000; // cycles per 2 ms period
    localparam [13:0] HALF   = 14'd5000;  // 50% point, for clk_500Hz
    localparam [13:0] SLICE  = 14'd500;   // PERIOD / 20, per pulse_width count

    reg  [13:0] period_count;                        // 0 .. 9999
    wire [13:0] pwm_threshold = pulse_width * SLICE;  // 0 .. 10000

    always @(posedge clk_5MHz or negedge reset_n) begin
        if (!reset_n) begin
            // Active-low reset: hold both outputs low, clear the counter
            period_count <= 14'd0;
            clk_500Hz    <= 1'b0;
            pwm_signal   <= 1'b0;
        end else begin
            if (period_count == PERIOD - 14'd1)
                period_count <= 14'd0;
            else
                period_count <= period_count + 14'd1;

            clk_500Hz  <= (period_count < HALF);
            pwm_signal <= (period_count < pwm_threshold);
        end
    end

//////////////////DO NOT MAKE ANY CHANGES BELOW THIS LINE//////////////////

endmodule

