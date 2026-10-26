// pl_reg_fd.v - pipeline register IF/ID (Fetch | Decode)
//
//   stall : hold the current contents (StallD)
//   clr   : blank the register to a bubble (FlushD); wins over stall

module pl_reg_fd (
    input             clk, stall, clr,
    input      [31:0] InstrF, PCF, PCPlus4F,
    output reg [31:0] InstrD, PCD, PCPlus4D
);

initial begin
    InstrD = 0; PCD = 0; PCPlus4D = 0;
end

always @(posedge clk) begin
    if (clr) begin
        InstrD <= 0; PCD <= 0; PCPlus4D <= 0;
    end else if (!stall) begin
        InstrD <= InstrF; PCD <= PCF; PCPlus4D <= PCPlus4F;
    end
end

endmodule
