
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

wire [31:0] InstrD;
wire        ALUSrc, RegWrite, Branch, Jump, Jalr, MemWriteD;
wire [1:0]  ResultSrc, ALUSrcA;
wire [2:0]  ImmSrc;
wire [3:0]  ALUControl;

// control signals are generated in Decode
controller  c   (InstrD[6:0], InstrD[14:12], InstrD[30],
                ResultSrc, MemWriteD, ALUSrc, ALUSrcA,
                RegWrite, Branch, Jump, Jalr, ImmSrc, ALUControl);

datapath    dp  (clk, reset,
                ResultSrc, MemWriteD, ALUSrc, ALUSrcA,
                RegWrite, Branch, Jump, Jalr, ImmSrc, ALUControl,
                InstrD,
                PC, Instr,
                MemWrite, Mem_WrAddr, Mem_WrData, ReadData, funct3,
                Result, PCW, ALUResultW, WriteDataW);

endmodule
