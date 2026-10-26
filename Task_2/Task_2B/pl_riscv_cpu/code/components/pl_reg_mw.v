// pl_reg_mw.v - pipeline register MEM/WB (Memory | Writeback)
//
// ReadDataW is the already aligned / sign-extended load value.
// WriteDataW (the raw rs2 of a store) only travels on to Writeback so the
// testbench can observe it; nothing in the CPU consumes it.

module pl_reg_mw (
    input             clk, clr,
    input      [31:0] ALUResultM, ReadDataM, PCPlus4M, WriteDataM,
    input      [ 4:0] RdM,
    input             RegWriteM,
    input      [ 1:0] ResultSrcM,

    output reg [31:0] ALUResultW, ReadDataW, PCPlus4W, WriteDataW,
    output reg [ 4:0] RdW,
    output reg        RegWriteW,
    output reg [ 1:0] ResultSrcW
);

initial begin
    ALUResultW = 0; ReadDataW = 0; PCPlus4W = 0; WriteDataW = 0;
    RdW = 0; RegWriteW = 0; ResultSrcW = 0;
end

always @(posedge clk) begin
    if (clr) begin
        ALUResultW <= 0; ReadDataW <= 0; PCPlus4W <= 0; WriteDataW <= 0;
        RdW <= 0; RegWriteW <= 0; ResultSrcW <= 0;
    end else begin
        ALUResultW <= ALUResultM; ReadDataW <= ReadDataM;
        PCPlus4W <= PCPlus4M; WriteDataW <= WriteDataM;
        RdW <= RdM; RegWriteW <= RegWriteM; ResultSrcW <= ResultSrcM;
    end
end

endmodule
