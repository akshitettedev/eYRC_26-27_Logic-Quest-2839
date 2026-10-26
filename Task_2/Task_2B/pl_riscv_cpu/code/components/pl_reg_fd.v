
// pl_reg_fd.v - pipeline register: Fetch | Decode  (IF/ID)
// en  = stall (active-high, holds the register)   clr = flush (inserts a NOP)

module pl_reg_fd (
    input             clk, en, clr,
    input      [31:0] InstrF, PCF, PCPlus4F,
    output reg [31:0] InstrD, PCD, PCPlus4D
);

localparam NOP = 32'h00000013;   // addi x0, x0, 0

initial begin
    InstrD = NOP; PCD = 0; PCPlus4D = 0;
end

always @(posedge clk) begin
    if (clr) begin
        InstrD <= NOP; PCD <= 0; PCPlus4D <= 0;
    end else if (!en) begin
        InstrD <= InstrF; PCD <= PCF;
        PCPlus4D <= PCPlus4F;
    end
end

endmodule
