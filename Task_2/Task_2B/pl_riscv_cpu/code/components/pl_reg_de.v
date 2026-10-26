
// pl_reg_de.v - pipeline register: Decode | Execute  (ID/EX)
// clr = flush: turns the stage into a bubble (every control signal = 0)

module pl_reg_de (
    input             clk, clr,
    input      [31:0] RD1D, RD2D, ImmExtD, PCD, PCPlus4D,
    input      [ 4:0] Rs1D, Rs2D, RdD,
    input             RegWriteD, MemWriteD, JumpD, BranchD, ALUSrcD, JalrD,
    input      [ 1:0] ResultSrcD, ALUSrcAD,
    input      [ 3:0] ALUControlD,
    input      [ 2:0] Funct3D,
    output reg [31:0] RD1E, RD2E, ImmExtE, PCE, PCPlus4E,
    output reg [ 4:0] Rs1E, Rs2E, RdE,
    output reg        RegWriteE, MemWriteE, JumpE, BranchE, ALUSrcE, JalrE,
    output reg [ 1:0] ResultSrcE, ALUSrcAE,
    output reg [ 3:0] ALUControlE,
    output reg [ 2:0] Funct3E
);

initial begin
    RD1E = 0; RD2E = 0; ImmExtE = 0; PCE = 0; PCPlus4E = 0;
    Rs1E = 0; Rs2E = 0; RdE = 0;
    RegWriteE = 0; MemWriteE = 0; JumpE = 0; BranchE = 0; ALUSrcE = 0; JalrE = 0;
    ResultSrcE = 0; ALUSrcAE = 0; ALUControlE = 0; Funct3E = 0;
end

always @(posedge clk) begin
    if (clr) begin
        RD1E <= 0; RD2E <= 0; ImmExtE <= 0; PCE <= 0; PCPlus4E <= 0;
        Rs1E <= 0; Rs2E <= 0; RdE <= 0;
        RegWriteE <= 0; MemWriteE <= 0; JumpE <= 0; BranchE <= 0; ALUSrcE <= 0; JalrE <= 0;
        ResultSrcE <= 0; ALUSrcAE <= 0; ALUControlE <= 0; Funct3E <= 0;
    end else begin
        RD1E <= RD1D; RD2E <= RD2D; ImmExtE <= ImmExtD; PCE <= PCD; PCPlus4E <= PCPlus4D;
        Rs1E <= Rs1D; Rs2E <= Rs2D; RdE <= RdD;
        RegWriteE <= RegWriteD; MemWriteE <= MemWriteD; JumpE <= JumpD; BranchE <= BranchD;
        ALUSrcE <= ALUSrcD; JalrE <= JalrD;
        ResultSrcE <= ResultSrcD; ALUSrcAE <= ALUSrcAD; ALUControlE <= ALUControlD; Funct3E <= Funct3D;
    end
end

endmodule
