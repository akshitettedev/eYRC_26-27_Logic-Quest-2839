// Logic Quest Bot : Task 1A : Frequency Scaling
/*
Instructions
-------------------
Students are not allowed to make any changes in the Module declaration.
This file is used to design a module which will scale down the 50MHz Clock Frequency to clk_5MHz

Recommended Quartus Version : 20.1
The submitted project file must be 20.1 compatible as the evaluation will be done on Quartus Prime Lite 20.1.

Warning: The error due to compatibility will not be entertained.
-------------------
*/

//Frequency Scaling
//Inputs : clk_50MHz
//Output : 5MHz


module frequency_scaling (
    input clk_50MHz,
    input reset_n,
    output reg clk_5MHz
);

//////////////////DO NOT MAKE ANY CHANGES ABOVE THIS LINE //////////////////


/*
 add your code here 
 */

    // Counts DOWN to 0. Reset holds the counter at 0 (as required) -
    // and since 0 is also the toggle condition, the very first clock
    // edge after reset releases fires a toggle immediately, instead of
    // needing several cycles to count up to a trigger value first.
    reg [2:0] count;

    always @(posedge clk_50MHz or negedge reset_n) begin
        if (!reset_n) begin
            count    <= 3'd0;
            clk_5MHz <= 1'b0;
        end else if (count == 3'd0) begin
            clk_5MHz <= ~clk_5MHz;
            count    <= 3'd4;
        end else begin
            count <= count - 3'd1;
        end
    end

//////////////////DO NOT MAKE ANY CHANGES BELOW THIS LINE //////////////////

endmodule

