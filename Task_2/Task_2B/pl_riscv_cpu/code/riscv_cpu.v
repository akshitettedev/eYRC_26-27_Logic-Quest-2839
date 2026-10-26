// riscv_cpu.v - 5-stage pipelined RISC-V CPU Processor

module riscv_cpu (
    input         clk, reset,
    output [31:0] PC,
    input  [31:0] Instr,
    output        MemWrite,
    output [31:0] Mem_WrAddr, Mem_WrData,
    input  [31:0] ReadData,
    output [31:0] Result,
    output [ 2:0] funct3,
    output [31:0] PCW, ALUResultW, WriteDataW
);

// control signals produced in Decode from the instruction held in IF/ID
wire [31:0] InstrD;
wire        ALUSrcD, RegWriteD, MemWriteD, BranchD, JumpD, JalrD;
wire [1:0]  ResultSrcD, ALUSrcAD;
wire [2:0]  ImmSrcD;
wire [3:0]  ALUControlD;

controller  c   (InstrD[6:0], InstrD[14:12], InstrD[30],
                 ResultSrcD, MemWriteD, ALUSrcD, ALUSrcAD,
                 RegWriteD, BranchD, JumpD, JalrD, ImmSrcD, ALUControlD);

datapath    dp  (.clk(clk), .reset(reset),
                 .ResultSrcD(ResultSrcD), .MemWriteD(MemWriteD),
                 .ALUSrcD(ALUSrcD), .ALUSrcAD(ALUSrcAD),
                 .RegWriteD(RegWriteD), .BranchD(BranchD),
                 .JumpD(JumpD), .JalrD(JalrD),
                 .ImmSrcD(ImmSrcD), .ALUControlD(ALUControlD),
                 .InstrD(InstrD),
                 .PC(PC), .Instr(Instr),
                 .MemWrite(MemWrite), .Mem_WrAddr(Mem_WrAddr),
                 .Mem_WrData(Mem_WrData), .ReadData(ReadData),
                 .Result(Result), .PCW(PCW),
                 .ALUResultW(ALUResultW), .WriteDataW(WriteDataW));

// data_mem is always accessed as a full word (010): the datapath does the
// byte / half-word alignment and the read-modify-write of sub-word stores.
assign funct3 = 3'b010;

endmodule
