# pl_riscv_cpu.sdc - timing constraints
# 25 MHz clock. The register file writes on the falling edge, so Decode<->Writeback
# paths get half a period; 40 ns leaves comfortable margin.
create_clock -name clk -period 40.000 [get_ports clk]
derive_clock_uncertainty
