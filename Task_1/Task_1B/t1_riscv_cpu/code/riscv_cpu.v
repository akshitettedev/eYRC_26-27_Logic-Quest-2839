// riscv_cpu.v - single-cycle RISC-V CPU Processor

module riscv_cpu (
    input         clk, reset,
    output [31:0] PC,
    input  [31:0] Instr,
    output        MemWrite,
    output [31:0] Mem_WrAddr, Mem_WrData,
    input  [31:0] ReadData,
    output [31:0] Result
);

wire        ALUSrc, RegWrite, Jump, Jalr, Zero;
wire        PCSrc;
wire [1:0]  ResultSrc, ALUSrcA;
wire [2:0]  ImmSrc;
wire [2:0]  ALUControl;

controller c (
    Instr[6:0], Instr[14:12], Instr[30], Zero,
    ResultSrc, MemWrite, PCSrc, ALUSrc, ALUSrcA,
    RegWrite, Jump, Jalr, ImmSrc, ALUControl
);

datapath dp (
    clk, reset, ResultSrc, PCSrc, Jalr, ALUSrc, ALUSrcA,
    RegWrite, ImmSrc, ALUControl, Zero, PC, Instr,
    Mem_WrAddr, Mem_WrData, ReadData, Result
);

endmodule
