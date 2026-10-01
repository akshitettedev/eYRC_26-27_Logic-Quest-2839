// t1_riscv_cpu.v - Top Module to test riscv_cpu

module t1_riscv_cpu (
    input         clk, reset,
    input         Ext_MemWrite,
    input  [31:0] Ext_WriteData, Ext_DataAdr,
    output        MemWrite,
    output [31:0] WriteData, DataAdr, ReadData,
    output [31:0] PC, Result
);

wire [31:0] Instr;
wire [31:0] DataAdr_rv32, WriteData_rv32, WriteData_rmw;
wire        MemWrite_rv32;
wire [31:0] MemWriteData;

// instantiate processor and memories
riscv_cpu rvcpu    (clk, reset, PC, Instr,
                    MemWrite_rv32, DataAdr_rv32,
                    WriteData_rv32, WriteData_rmw, ReadData, Result);
instr_mem instrmem (PC, Instr);
data_mem  datamem  (clk, MemWrite, DataAdr, MemWriteData, ReadData);

// word written into data memory: merged (read-modify-write) data from the CPU,
// or the external word when the testbench preloads memory during reset
assign MemWriteData = (Ext_MemWrite && reset) ? Ext_WriteData : WriteData_rmw;

assign MemWrite  = (Ext_MemWrite && reset) ? 1 : MemWrite_rv32;
assign WriteData = (Ext_MemWrite && reset) ? Ext_WriteData : WriteData_rv32;
assign DataAdr   = reset ? Ext_DataAdr : DataAdr_rv32;

endmodule

