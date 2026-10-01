// riscv_cpu.v - single-cycle RISC-V CPU Processor

module riscv_cpu (
    input         clk, reset,
    output [31:0] PC,
    input  [31:0] Instr,
    output        MemWrite,
    output [31:0] Mem_WrAddr, Mem_WrData, Mem_WrDataRMW,
    input  [31:0] ReadData,
    output [31:0] Result
);

wire        ALUSrc, RegWrite, Jump, Jalr;
wire        Eq, Lt, Ltu;
wire        PCSrc;
wire [1:0]  ResultSrc, ALUSrcA;
wire [2:0]  ImmSrc;
wire [3:0]  ALUControl;

controller c (
    Instr[6:0], Instr[14:12], Instr[30], Eq, Lt, Ltu,
    ResultSrc, MemWrite, PCSrc, ALUSrc, ALUSrcA,
    RegWrite, Jump, Jalr, ImmSrc, ALUControl
);

datapath dp (
    clk, reset, ResultSrc, PCSrc, Jalr, ALUSrc, ALUSrcA,
    RegWrite, ImmSrc, ALUControl, Eq, Lt, Ltu, PC, Instr,
    Mem_WrAddr, Mem_WrData, Mem_WrDataRMW, ReadData, Result
);

endmodule
