
// pl_reg_em.v - pipeline register: Execute | Memory  (EX/MEM)

module pl_reg_em (
    input             clk,
    input      [31:0] ALUResultE, WriteDataE, PCPlus4E,
    input      [ 4:0] RdE,
    input      [ 2:0] Funct3E,
    input             RegWriteE, MemWriteE,
    input      [ 1:0] ResultSrcE,
    output reg [31:0] ALUResultM, WriteDataM, PCPlus4M,
    output reg [ 4:0] RdM,
    output reg [ 2:0] Funct3M,
    output reg        RegWriteM, MemWriteM,
    output reg [ 1:0] ResultSrcM
);

initial begin
    ALUResultM = 0; WriteDataM = 0; PCPlus4M = 0; RdM = 0; Funct3M = 0;
    RegWriteM = 0; MemWriteM = 0; ResultSrcM = 0;
end

always @(posedge clk) begin
    ALUResultM <= ALUResultE; WriteDataM <= WriteDataE; PCPlus4M <= PCPlus4E;
    RdM <= RdE; Funct3M <= Funct3E;
    RegWriteM <= RegWriteE; MemWriteM <= MemWriteE; ResultSrcM <= ResultSrcE;
end

endmodule
