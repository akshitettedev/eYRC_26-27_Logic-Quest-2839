
// pl_reg_mw.v - pipeline register: Memory | Writeback  (MEM/WB)

module pl_reg_mw (
    input             clk,
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
    ALUResultW = 0; ReadDataW = 0; PCPlus4W = 0; WriteDataW = 0; RdW = 0;
    RegWriteW = 0; ResultSrcW = 0;
end

always @(posedge clk) begin
    ALUResultW <= ALUResultM; ReadDataW <= ReadDataM; PCPlus4W <= PCPlus4M;
    WriteDataW <= WriteDataM; RdW <= RdM;
    RegWriteW <= RegWriteM; ResultSrcW <= ResultSrcM;
end

endmodule
