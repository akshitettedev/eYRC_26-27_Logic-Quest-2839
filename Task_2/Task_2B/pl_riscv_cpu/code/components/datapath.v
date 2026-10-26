// datapath.v - 5-stage pipelined datapath
//
//   IF  -> [IF/ID]  -> ID -> [ID/EX] -> EX -> [EX/MEM] -> MEM -> [MEM/WB] -> WB
//
// Signal suffixes name the stage a signal belongs to: F, D, E, M, W.

module datapath (
    input         clk, reset,
    // control signals generated (once) in Decode by the controller
    input  [1:0]  ResultSrcD,
    input         MemWriteD, ALUSrcD,
    input  [1:0]  ALUSrcAD,
    input         RegWriteD, BranchD, JumpD, JalrD,
    input  [2:0]  ImmSrcD,
    input  [3:0]  ALUControlD,
    output [31:0] InstrD,                       // to the controller
    // instruction memory
    output [31:0] PC,
    input  [31:0] Instr,
    // data memory (Memory stage)
    output        MemWrite,
    output [31:0] Mem_WrAddr, Mem_WrData,
    input  [31:0] ReadData,
    // observation points
    output [31:0] Result,
    output [31:0] PCW, ALUResultW, WriteDataW
);

// ------------------------------------------------------------------ wires
// Fetch
wire [31:0] PCPlus4F, PCNextF;
// Decode
wire [31:0] PCD, PCPlus4D, RD1D, RD2D, ImmExtD;
wire [ 4:0] Rs1D, Rs2D, RdD;
// Execute
wire [31:0] RD1E, RD2E, ImmExtE, PCE, PCPlus4E;
wire [ 4:0] Rs1E, Rs2E, RdE;
wire        RegWriteE, MemWriteE, JumpE, JalrE, BranchE, ALUSrcE;
wire [ 1:0] ResultSrcE, ALUSrcAE;
wire [ 3:0] ALUControlE;
wire [ 2:0] funct3E;
wire [31:0] SrcAFwdE, WriteDataE, SrcAE, SrcBE, ALUResultE;
wire [31:0] PCTargetE, JumpTargetE;
wire        TakeBranchE, PCSrcE;
// Memory
wire [31:0] ALUResultM, WriteDataM, PCPlus4M;
wire [ 4:0] RdM;
wire        RegWriteM, MemWriteM;
wire [ 1:0] ResultSrcM;
wire [ 2:0] funct3M;
// Writeback
wire [31:0] ReadDataW, PCPlus4W, ResultW;
wire [ 4:0] RdW;
wire        RegWriteW;
wire [ 1:0] ResultSrcW;
// Hazard unit
wire [ 1:0] ForwardAE, ForwardBE;
wire        StallF, StallD, FlushD, FlushE;

// ================================================================= FETCH
// PC is held by StallF; a taken branch / jump (resolved in Execute) redirects it.
reset_ff #(32) pcreg   (clk, reset, StallF, PCNextF, PC);
adder    #(32) pcadd4  (PC, 32'd4, PCPlus4F);
mux2     #(32) pcmux   (PCPlus4F, JumpTargetE, PCSrcE, PCNextF);

// ---------------------------------------------------- Pipeline reg 1: IF/ID
pl_reg_fd plfd (
    .clk(clk), .stall(StallD), .clr(FlushD | reset),
    .InstrF(Instr), .PCF(PC), .PCPlus4F(PCPlus4F),
    .InstrD(InstrD), .PCD(PCD), .PCPlus4D(PCPlus4D)
);

// ================================================================ DECODE
assign Rs1D = InstrD[19:15];
assign Rs2D = InstrD[24:20];
assign RdD  = InstrD[11:7];

// register file: written by Writeback (falling edge), read here
reg_file   rf  (clk, RegWriteW, Rs1D, Rs2D, RdW, ResultW, RD1D, RD2D);
imm_extend ext (InstrD[31:7], ImmSrcD, ImmExtD);

// ---------------------------------------------------- Pipeline reg 2: ID/EX
pl_reg_de plde (
    .clk(clk), .clr(FlushE | reset),
    .RD1D(RD1D), .RD2D(RD2D), .ImmExtD(ImmExtD), .PCD(PCD), .PCPlus4D(PCPlus4D),
    .Rs1D(Rs1D), .Rs2D(Rs2D), .RdD(RdD),
    .RegWriteD(RegWriteD), .MemWriteD(MemWriteD), .JumpD(JumpD), .JalrD(JalrD),
    .BranchD(BranchD), .ALUSrcD(ALUSrcD),
    .ResultSrcD(ResultSrcD), .ALUSrcAD(ALUSrcAD), .ALUControlD(ALUControlD),
    .funct3D(InstrD[14:12]),
    .RD1E(RD1E), .RD2E(RD2E), .ImmExtE(ImmExtE), .PCE(PCE), .PCPlus4E(PCPlus4E),
    .Rs1E(Rs1E), .Rs2E(Rs2E), .RdE(RdE),
    .RegWriteE(RegWriteE), .MemWriteE(MemWriteE), .JumpE(JumpE), .JalrE(JalrE),
    .BranchE(BranchE), .ALUSrcE(ALUSrcE),
    .ResultSrcE(ResultSrcE), .ALUSrcAE(ALUSrcAE), .ALUControlE(ALUControlE),
    .funct3E(funct3E)
);

// =============================================================== EXECUTE
// operand forwarding: 00 = register file, 01 = ResultW, 10 = ALUResultM
mux3 #(32) fwdamux (RD1E, ResultW, ALUResultM, ForwardAE, SrcAFwdE);
mux3 #(32) fwdbmux (RD2E, ResultW, ALUResultM, ForwardBE, WriteDataE);

// ALU first operand:  00 = rs1, 01 = PC (auipc), 10 = 0 (lui)
mux4 #(32) srcamux (SrcAFwdE, PCE, 32'b0, 32'b0, ALUSrcAE, SrcAE);
// ALU second operand: 0 = rs2, 1 = immediate
mux2 #(32) srcbmux (WriteDataE, ImmExtE, ALUSrcE, SrcBE);

alu        alu0    (SrcAE, SrcBE, ALUControlE, ALUResultE);

// branch / jump resolution (the only place PCSrc is decided)
branching_unit bu  (funct3E, SrcAFwdE, WriteDataE, TakeBranchE);
adder #(32) pcaddbranch (PCE, ImmExtE, PCTargetE);
mux2  #(32) jumptgtmux  (PCTargetE, {ALUResultE[31:1], 1'b0}, JalrE, JumpTargetE);
assign PCSrcE = (BranchE & TakeBranchE) | JumpE | JalrE;

// --------------------------------------------------- Pipeline reg 3: EX/MEM
pl_reg_em plem (
    .clk(clk), .clr(reset),
    .ALUResultE(ALUResultE), .WriteDataE(WriteDataE), .PCPlus4E(PCPlus4E),
    .RdE(RdE), .RegWriteE(RegWriteE), .MemWriteE(MemWriteE),
    .ResultSrcE(ResultSrcE), .funct3E(funct3E),
    .ALUResultM(ALUResultM), .WriteDataM(WriteDataM), .PCPlus4M(PCPlus4M),
    .RdM(RdM), .RegWriteM(RegWriteM), .MemWriteM(MemWriteM),
    .ResultSrcM(ResultSrcM), .funct3M(funct3M)
);

// ================================================================ MEMORY
// data_mem is always accessed as a full word. Byte / half-word loads are
// aligned and extended here, and byte / half-word stores are done as a
// read-modify-write of the word (ReadData is the current word at the address).
wire [ 1:0] byte_off = ALUResultM[1:0];
wire [31:0] rd_shift = ReadData >> {byte_off, 3'b000};
reg  [31:0] LoadDataM;
reg  [31:0] store_word;

always @(*) begin
    case (funct3M)
        3'b000:  LoadDataM = {{24{rd_shift[7]}},  rd_shift[7:0]};   // lb
        3'b001:  LoadDataM = {{16{rd_shift[15]}}, rd_shift[15:0]};  // lh
        3'b100:  LoadDataM = {24'b0, rd_shift[7:0]};                // lbu
        3'b101:  LoadDataM = {16'b0, rd_shift[15:0]};               // lhu
        default: LoadDataM = ReadData;                              // lw
    endcase
end

always @(*) begin
    case (funct3M[1:0])
        2'b00: begin                                                // sb
            case (byte_off)
                2'd0:    store_word = {ReadData[31:8],  WriteDataM[7:0]};
                2'd1:    store_word = {ReadData[31:16], WriteDataM[7:0], ReadData[7:0]};
                2'd2:    store_word = {ReadData[31:24], WriteDataM[7:0], ReadData[15:0]};
                default: store_word = {WriteDataM[7:0], ReadData[23:0]};
            endcase
        end
        2'b01: begin                                                // sh
            if (byte_off[1]) store_word = {WriteDataM[15:0], ReadData[15:0]};
            else             store_word = {ReadData[31:16], WriteDataM[15:0]};
        end
        default: store_word = WriteDataM;                           // sw
    endcase
end

assign MemWrite   = MemWriteM;
assign Mem_WrAddr = ALUResultM;
assign Mem_WrData = store_word;

// --------------------------------------------------- Pipeline reg 4: MEM/WB
pl_reg_mw plmw (
    .clk(clk), .clr(reset),
    .ALUResultM(ALUResultM), .ReadDataM(LoadDataM), .PCPlus4M(PCPlus4M),
    .WriteDataM(WriteDataM), .RdM(RdM), .RegWriteM(RegWriteM),
    .ResultSrcM(ResultSrcM),
    .ALUResultW(ALUResultW), .ReadDataW(ReadDataW), .PCPlus4W(PCPlus4W),
    .WriteDataW(WriteDataW), .RdW(RdW), .RegWriteW(RegWriteW),
    .ResultSrcW(ResultSrcW)
);

// ============================================================== WRITEBACK
// 00 = ALU result, 01 = load data, 10 = PC+4 (jal / jalr link)
mux3 #(32) resultmux (ALUResultW, ReadDataW, PCPlus4W, ResultSrcW, ResultW);
assign Result = ResultW;

// PC of the instruction in Writeback (observation only): PC+4 minus 4
adder #(32) pcwadd (PCPlus4W, 32'hFFFFFFFC, PCW);

// ======================================================== HAZARD UNIT
hazard_unit hu (
    .Rs1D(Rs1D), .Rs2D(Rs2D),
    .Rs1E(Rs1E), .Rs2E(Rs2E), .RdE(RdE),
    .RdM(RdM), .RdW(RdW),
    .RegWriteM(RegWriteM), .RegWriteW(RegWriteW),
    .ResultSrcE0(ResultSrcE[0]),
    .PCSrcE(PCSrcE),
    .ForwardAE(ForwardAE), .ForwardBE(ForwardBE),
    .StallF(StallF), .StallD(StallD),
    .FlushD(FlushD), .FlushE(FlushE)
);

endmodule
