`timescale 1 ns/1 ns

module tb_1b;

reg clk;
reg reset;
reg Ext_MemWrite;
reg [31:0] Ext_WriteData, Ext_DataAdr;

wire [31:0] WriteData, DataAdr, ReadData;
wire MemWrite;
wire [31:0] PC, Result;

t1_riscv_cpu uut (clk, reset, Ext_MemWrite, Ext_WriteData, Ext_DataAdr,
                  MemWrite, WriteData, DataAdr, ReadData, PC, Result);

integer fault_instrs = 0, i = 0, fw = 0;
localparam TOTAL_CHECKS = 15;

always begin
    clk <= 1; #5; clk <= 0; #5;
end

initial begin
    reset = 1;
    Ext_MemWrite = 0;
    Ext_DataAdr = 32'b0;
    Ext_WriteData = 32'b0;
    #10;
    reset = 0;
end

task report_result;
    begin
        $display("Faulty Instructions => %d", fault_instrs);
        fw = $fopen("results.txt", "w");
        if (fault_instrs !== 0) begin
            $fdisplay(fw, "%02h", "Errors");
            $display("Error(s) encountered, please check your design!");
        end
        else begin
            $fdisplay(fw, "%02h", "No Errors");
            $display("No errors encountered, congratulations!");
        end
        $fclose(fw);
        $stop;
    end
endtask

task report_early;
    begin
        $display("%0d of %0d checks were reached, the remaining %0d are counted as faulty",
                 i, TOTAL_CHECKS, TOTAL_CHECKS - i);
        fault_instrs = fault_instrs + (TOTAL_CHECKS - i);
        report_result;
    end
endtask

localparam ADDI_CHK  = 32'h0C;
localparam ANDI_CHK  = 32'h10;
localparam ORI_CHK   = 32'h14;
localparam SLTI_CHK  = 32'h18;
localparam ADD_CHK   = 32'h1C;
localparam SUB_CHK   = 32'h20;
localparam SLT_CHK   = 32'h24;
localparam OR_CHK    = 32'h28;
localparam AND_CHK   = 32'h2C;
localparam SW_CHK    = 32'h30;
localparam LW_CHK    = 32'h34;
localparam BEQ_IN    = 32'h44;
localparam BEQ_CHK   = 32'h50;
localparam LUI_CHK   = 32'h54;
localparam AUIPC_CHK = 32'h58;
localparam JALR_CHK  = 32'h5C;

always @(negedge clk) begin
    case (PC)
        ADDI_CHK: begin
            i = i + 1'b1;
            if (Result === 9) $display("1. addi implementation is correct");
            else begin $display("1. addi implementation is incorrect"); fault_instrs = fault_instrs + 1'b1; end
        end
        ANDI_CHK: begin
            i = i + 1'b1;
            if (Result === 1) $display("2. andi implementation is correct");
            else begin $display("2. andi implementation is incorrect"); fault_instrs = fault_instrs + 1'b1; end
        end
        ORI_CHK: begin
            i = i + 1'b1;
            if (Result === -1) $display("3. ori implementation is correct");
            else begin $display("3. ori implementation is incorrect"); fault_instrs = fault_instrs + 1'b1; end
        end
        SLTI_CHK: begin
            i = i + 1'b1;
            if (Result === 1) $display("4. slti implementation is correct");
            else begin $display("4. slti implementation is incorrect"); fault_instrs = fault_instrs + 1'b1; end
        end
        ADD_CHK: begin
            i = i + 1'b1;
            if (Result === 17) $display("5. add implementation is correct");
            else begin $display("5. add implementation is incorrect"); fault_instrs = fault_instrs + 1'b1; end
        end
        SUB_CHK: begin
            i = i + 1'b1;
            if (Result === 15) $display("6. sub implementation is correct");
            else begin $display("6. sub implementation is incorrect"); fault_instrs = fault_instrs + 1'b1; end
        end
        SLT_CHK: begin
            i = i + 1'b1;
            if (Result === 1) $display("7. slt implementation is correct");
            else begin $display("7. slt implementation is incorrect"); fault_instrs = fault_instrs + 1'b1; end
        end
        OR_CHK: begin
            i = i + 1'b1;
            if (Result === 17) $display("8. or implementation is correct");
            else begin $display("8. or implementation is incorrect"); fault_instrs = fault_instrs + 1'b1; end
        end
        AND_CHK: begin
            i = i + 1'b1;
            if (Result === 0) $display("9. and implementation is correct");
            else begin $display("9. and implementation is incorrect"); fault_instrs = fault_instrs + 1'b1; end
        end
        SW_CHK: begin
            i = i + 1'b1;
            if (MemWrite && !reset && DataAdr === 40 && WriteData === 16)
                $display("10. sw implementation is correct");
            else begin $display("10. sw implementation is incorrect"); fault_instrs = fault_instrs + 1'b1; end
        end
        LW_CHK: begin
            i = i + 1'b1;
            if (DataAdr === 40 && Result === 16) $display("11. lw implementation is correct");
            else begin $display("11. lw implementation is incorrect"); fault_instrs = fault_instrs + 1'b1; end
        end
        BEQ_IN: begin
            if (Result <= 2) $display("12. beq is executing");
            else begin $display("beq struck in loop"); report_early; end
        end
        BEQ_CHK: begin
            i = i + 1'b1;
            if (Result === 4) $display("12. beq implementation is correct");
            else begin $display("12. beq implementation is incorrect"); fault_instrs = fault_instrs + 1'b1; end
        end
        LUI_CHK: begin
            i = i + 1'b1;
            if (Result === 32'h02000000) $display("13. lui implementation is correct");
            else begin $display("13. lui implementation is incorrect"); fault_instrs = fault_instrs + 1'b1; end
        end
        AUIPC_CHK: begin
            i = i + 1'b1;
            if (Result === 32'h02000058) $display("14. auipc implementation is correct");
            else begin $display("14. auipc implementation is incorrect"); fault_instrs = fault_instrs + 1'b1; end
        end
        JALR_CHK: begin
            i = i + 1'b1;
            if (Result === 32'h60) $display("15. jalr implementation is correct");
            else begin $display("15. jalr implementation is incorrect"); fault_instrs = fault_instrs + 1'b1; end
        end
    endcase
end

always @(negedge clk) begin
    if (i >= TOTAL_CHECKS) report_result;
end

initial begin
    #1000;
    $display("Simulation stopped early, the CPU is no longer fetching (PC = %h)", PC);
    report_early;
end

endmodule
