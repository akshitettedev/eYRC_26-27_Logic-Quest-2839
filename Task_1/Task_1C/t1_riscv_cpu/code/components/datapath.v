// datapath.v
module datapath (
    input         clk, reset,
    input [1:0]   ResultSrc,
    input         PCSrc, Jalr,
    input         ALUSrc,
    input [1:0]   ALUSrcA,
    input         RegWrite,
    input [2:0]   ImmSrc,
    input [3:0]   ALUControl,
    output        Eq, Lt, Ltu,
    output [31:0] PC,
    input  [31:0] Instr,
    output [31:0] Mem_WrAddr, Mem_WrData, Mem_WrDataRMW,
    input  [31:0] ReadData,
    output [31:0] Result
);

wire [31:0] PCNext, PCNextBase, PCPlus4, PCTarget, JALRTarget;
wire [31:0] ImmExt, SrcA, SrcASelected, SrcB, WriteData, ALUResult;
wire [31:0] LoadData;

wire [2:0] funct3 = Instr[14:12];

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

alu            alu (SrcASelected, SrcB, ALUControl, ALUResult);

// branch comparison flags (rs1 vs rs2)
assign Eq  = (SrcA == WriteData);
assign Lt  = ($signed(SrcA) < $signed(WriteData));
assign Ltu = (SrcA < WriteData);

// ---------------------------------------------------------------
// Load path: select byte / half-word from the word read from memory
// and sign- or zero-extend (LB, LBU, LH, LHU, LW)
// ---------------------------------------------------------------
wire [1:0]  byte_off = ALUResult[1:0];
wire [31:0] rd_shift = ReadData >> {byte_off, 3'b000};
reg  [31:0] load_val;

always @(*) begin
    case (funct3)
        3'b000:  load_val = {{24{rd_shift[7]}},  rd_shift[7:0]};   // lb
        3'b001:  load_val = {{16{rd_shift[15]}}, rd_shift[15:0]};  // lh
        3'b100:  load_val = {24'b0, rd_shift[7:0]};                // lbu
        3'b101:  load_val = {16'b0, rd_shift[15:0]};               // lhu
        default: load_val = ReadData;                              // lw
    endcase
end
assign LoadData = load_val;

mux3 #(32)     resultmux(ALUResult, LoadData, PCPlus4, ResultSrc, Result);

// ---------------------------------------------------------------
// Store path: read-modify-write so that SB/SH only change their own
// bytes inside the 32-bit word (data_mem.v only writes whole words)
// ---------------------------------------------------------------
reg [31:0] store_word;

always @(*) begin
    case (funct3[1:0])
        2'b00: begin                                               // sb
            case (byte_off)
                2'd0:    store_word = {ReadData[31:8],  WriteData[7:0]};
                2'd1:    store_word = {ReadData[31:16], WriteData[7:0], ReadData[7:0]};
                2'd2:    store_word = {ReadData[31:24], WriteData[7:0], ReadData[15:0]};
                default: store_word = {WriteData[7:0],  ReadData[23:0]};
            endcase
        end
        2'b01: begin                                               // sh
            if (byte_off[1]) store_word = {WriteData[15:0], ReadData[15:0]};
            else             store_word = {ReadData[31:16], WriteData[15:0]};
        end
        default: store_word = WriteData;                           // sw
    endcase
end

assign Mem_WrData    = WriteData;   // raw rs2 (what the testbench observes)
assign Mem_WrDataRMW = store_word;  // merged word actually written to data memory
assign Mem_WrAddr = ALUResult;

endmodule
