// pl_reg_em.v - pipeline register EX/MEM (Execute | Memory)

module pl_reg_em (
    input             clk, clr,
    input      [31:0] ALUResultE, WriteDataE, PCPlus4E,
    input      [ 4:0] RdE,
    input             RegWriteE, MemWriteE,
    input      [ 1:0] ResultSrcE,
    input      [ 2:0] funct3E,

    output reg [31:0] ALUResultM, WriteDataM, PCPlus4M,
    output reg [ 4:0] RdM,
    output reg        RegWriteM, MemWriteM,
    output reg [ 1:0] ResultSrcM,
    output reg [ 2:0] funct3M
);

initial begin
    ALUResultM = 0; WriteDataM = 0; PCPlus4M = 0; RdM = 0;
    RegWriteM = 0; MemWriteM = 0; ResultSrcM = 0; funct3M = 0;
end

always @(posedge clk) begin
    if (clr) begin
        ALUResultM <= 0; WriteDataM <= 0; PCPlus4M <= 0; RdM <= 0;
        RegWriteM <= 0; MemWriteM <= 0; ResultSrcM <= 0; funct3M <= 0;
    end else begin
        ALUResultM <= ALUResultE; WriteDataM <= WriteDataE;
        PCPlus4M <= PCPlus4E; RdM <= RdE;
        RegWriteM <= RegWriteE; MemWriteM <= MemWriteE;
        ResultSrcM <= ResultSrcE; funct3M <= funct3E;
    end
end

endmodule
