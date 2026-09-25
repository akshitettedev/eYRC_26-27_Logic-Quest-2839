// datapath.v
module datapath (
    input         clk, reset,
    input [1:0]   ResultSrc,
    input         PCSrc, Jalr,
    input         ALUSrc,
    input [1:0]   ALUSrcA,
    input         RegWrite,
    input [2:0]   ImmSrc,
    input [2:0]   ALUControl,
    output        Zero,
    output [31:0] PC,
    input  [31:0] Instr,
    output [31:0] Mem_WrAddr, Mem_WrData,
    input  [31:0] ReadData,
    output [31:0] Result
);

wire [31:0] PCNext, PCNextBase, PCPlus4, PCTarget, JALRTarget;
wire [31:0] ImmExt, SrcA, SrcASelected, SrcB, WriteData, ALUResult;

// next PC logic
reset_ff #(32) pcreg(clk, reset, PCNext, PC);
adder          pcadd4(PC, 32'd4, PCPlus4);
adder          pcaddbranch(PC, ImmExt, PCTarget);
assign JALRTarget = {ALUResult[31:1], 1'b0};
mux2 #(32)     pcmux(PCPlus4, PCTarget, PCSrc, PCNextBase);
mux2 #(32)     jalrmux(PCNextBase, JALRTarget, Jalr, PCNext);

// register file logic
reg_file       rf (clk, RegWrite, Instr[19:15], Instr[24:20], Instr[11:7], Result, SrcA, WriteData);
imm_extend     ext (Instr[31:7], ImmSrc, ImmExt);

// ALU first operand:
//   00 = rs1, 01 = PC (AUIPC), 10 = 0 (LUI)
mux4 #(32)     srcamux(SrcA, PC, 32'b0, 32'b0, ALUSrcA, SrcASelected);

// ALU second operand:
//   0 = rs2, 1 = immediate
mux2 #(32)     srcbmux(WriteData, ImmExt, ALUSrc, SrcB);

alu            alu (SrcASelected, SrcB, ALUControl, ALUResult, Zero);
mux3 #(32)     resultmux(ALUResult, ReadData, PCPlus4, ResultSrc, Result);

assign Mem_WrData = WriteData;
assign Mem_WrAddr = ALUResult;

endmodule
