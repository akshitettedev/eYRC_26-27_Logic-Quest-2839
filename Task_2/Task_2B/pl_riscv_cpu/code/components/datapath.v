
// datapath.v - 5-stage pipelined datapath (Fetch | Decode | Execute | Memory | Writeback)
// Control signals are generated in Decode (controller.v) and travel with the instruction.

module datapath (
    input         clk, reset,
    // control signals from the controller (Decode stage)
    input  [1:0]  ResultSrcD,
    input         MemWriteD, ALUSrcD,
    input  [1:0]  ALUSrcAD,
    input         RegWriteD, BranchD, JumpD, JalrD,
    input  [2:0]  ImmSrcD,
    input  [3:0]  ALUControlD,
    output [31:0] InstrD,
    // instruction memory
    output [31:0] PC,
    input  [31:0] Instr,
    // data memory (Memory stage)
    output        MemWrite,
    output [31:0] Mem_WrAddr, Mem_WrData,
    input  [31:0] ReadData,
    output [ 2:0] funct3,
    // Writeback stage observation points
    output [31:0] Result,
    output [31:0] PCW, ALUResultW, WriteDataW
);

// ------------------------------------------------------------------
// hazard unit wires
// ------------------------------------------------------------------
wire [1:0] ForwardAE, ForwardBE;
wire       StallF, StallD, FlushD, FlushE, PCSrcE;

// ------------------------------------------------------------------
// FETCH
// ------------------------------------------------------------------
wire [31:0] PCPlus4F, PCNext, PCJalr, PCTargetE, ALUResultE;
wire        JalrE;

adder          pcadd4 (PC, 32'd4, PCPlus4F);
mux2 #(32)     pcmux  (PCPlus4F, PCTargetE, PCSrcE & ~JalrE, PCNext);
mux2 #(32)     jalrmux(PCNext, {ALUResultE[31:1], 1'b0}, JalrE, PCJalr);
// StallF holds the PC
reset_ff #(32) pcreg  (clk, reset, StallF, PCJalr, PC);

// ------------------------------------------------------------------
// Pipeline Register 1 -> Fetch | Decode
// ------------------------------------------------------------------
wire [31:0] PCD, PCPlus4D;
pl_reg_fd plfd (clk, StallD, FlushD | reset, Instr, PC, PCPlus4F,
                InstrD, PCD, PCPlus4D);

// ------------------------------------------------------------------
// DECODE
// ------------------------------------------------------------------
wire [31:0] RD1D, RD2D, ImmExtD;
wire [31:0] ResultW;
wire [ 4:0] RdW;
wire        RegWriteW;

reg_file       rf  (clk, RegWriteW, InstrD[19:15], InstrD[24:20], RdW, ResultW, RD1D, RD2D);
imm_extend     ext (InstrD[31:7], ImmSrcD, ImmExtD);

// ------------------------------------------------------------------
// Pipeline Register 2 -> Decode | Execute
// ------------------------------------------------------------------
wire [31:0] RD1E, RD2E, ImmExtE, PCE, PCPlus4E;
wire [ 4:0] Rs1E, Rs2E, RdE;
wire        RegWriteE, MemWriteE, JumpE, BranchE, ALUSrcE;
wire [ 1:0] ResultSrcE, ALUSrcAE;
wire [ 3:0] ALUControlE;
wire [ 2:0] Funct3E;

pl_reg_de plde (clk, FlushE | reset,
                RD1D, RD2D, ImmExtD, PCD, PCPlus4D,
                InstrD[19:15], InstrD[24:20], InstrD[11:7],
                RegWriteD, MemWriteD, JumpD, BranchD, ALUSrcD, JalrD,
                ResultSrcD, ALUSrcAD, ALUControlD, InstrD[14:12],
                RD1E, RD2E, ImmExtE, PCE, PCPlus4E,
                Rs1E, Rs2E, RdE,
                RegWriteE, MemWriteE, JumpE, BranchE, ALUSrcE, JalrE,
                ResultSrcE, ALUSrcAE, ALUControlE, Funct3E);

// ------------------------------------------------------------------
// EXECUTE
// ------------------------------------------------------------------
wire [31:0] ALUResultM, PCPlus4M;
wire [ 1:0] ResultSrcM;
wire [ 4:0] RdM;
wire        RegWriteM;
// value forwarded from the Memory stage (jal/jalr write PC+4, not the ALU result)
wire [31:0] FwdValM = (ResultSrcM == 2'b10) ? PCPlus4M : ALUResultM;

wire [31:0] RS1fwdE, RS2fwdE, SrcAE, SrcBE;
mux3 #(32)     fwdamux (RD1E, ResultW, FwdValM, ForwardAE, RS1fwdE);
mux3 #(32)     fwdbmux (RD2E, ResultW, FwdValM, ForwardBE, RS2fwdE);

// ALU operand A: 00 = rs1, 01 = PC (auipc), 10 = 0 (lui)
mux4 #(32)     srcamux (RS1fwdE, PCE, 32'b0, 32'b0, ALUSrcAE, SrcAE);
mux2 #(32)     srcbmux (RS2fwdE, ImmExtE, ALUSrcE, SrcBE);
alu            alu0    (SrcAE, SrcBE, ALUControlE, ALUResultE);

// branch decision (resolved in Execute)
wire Eq  = (RS1fwdE == RS2fwdE);
wire Lt  = ($signed(RS1fwdE) < $signed(RS2fwdE));
wire Ltu = (RS1fwdE < RS2fwdE);
wire TakeBranch;
branching_unit bu (Funct3E, Eq, Lt, Ltu, TakeBranch);

assign PCSrcE = (BranchE & TakeBranch) | JumpE | JalrE;
adder          pcaddbranch (PCE, ImmExtE, PCTargetE);

// ------------------------------------------------------------------
// Pipeline Register 3 -> Execute | Memory
// ------------------------------------------------------------------
wire [31:0] WriteDataM;
wire [ 2:0] Funct3M;

pl_reg_em plem (clk, ALUResultE, RS2fwdE, PCPlus4E, RdE, Funct3E,
                RegWriteE, MemWriteE, ResultSrcE,
                ALUResultM, WriteDataM, PCPlus4M, RdM, Funct3M,
                RegWriteM, MemWrite, ResultSrcM);

assign Mem_WrAddr = ALUResultM;
assign Mem_WrData = WriteDataM;
assign funct3     = Funct3M;

// ------------------------------------------------------------------
// Pipeline Register 4 -> Memory | Writeback
// ------------------------------------------------------------------
wire [31:0] ReadDataW, PCPlus4W;
wire [ 1:0] ResultSrcW;

pl_reg_mw plmw (clk, ALUResultM, ReadData, PCPlus4M, WriteDataM, RdM, RegWriteM, ResultSrcM,
                ALUResultW, ReadDataW, PCPlus4W, WriteDataW, RdW, RegWriteW, ResultSrcW);

// ------------------------------------------------------------------
// WRITEBACK
// ------------------------------------------------------------------
mux3 #(32)     resultmux (ALUResultW, ReadDataW, PCPlus4W, ResultSrcW, ResultW);
assign Result = ResultW;
// PC of the instruction in Writeback (a bubble gives 32'hFFFFFFFC, which matches no test PC)
assign PCW    = PCPlus4W - 32'd4;

// ------------------------------------------------------------------
// hazard unit
// ------------------------------------------------------------------
hazard_unit hu (InstrD[19:15], InstrD[24:20], Rs1E, Rs2E, RdE,
                RdM, RegWriteM, RdW, RegWriteW,
                ResultSrcE[0], PCSrcE,
                ForwardAE, ForwardBE, StallF, StallD, FlushD, FlushE);

endmodule
