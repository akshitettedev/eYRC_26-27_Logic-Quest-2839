// hazard_unit.v - combinational hazard detection / resolution
//
// No clock, no state. Handles all three hazard classes:
//   1. data hazards     -> forward ALUResultM / ResultW to the ALU inputs
//   2. load-use hazards -> stall Fetch + Decode one cycle, bubble Execute
//   3. control hazards  -> a taken branch/jump (known in Execute) flushes
//                          the two younger instructions in Fetch/Decode
//
// Forward encodings (select the ALU operand):
//   2'b00 : value read from the register file (ID/EX)
//   2'b01 : ResultW   (instruction in Writeback)
//   2'b10 : ALUResultM (instruction in Memory)

module hazard_unit (
    input  [4:0] Rs1D, Rs2D,
    input  [4:0] Rs1E, Rs2E, RdE,
    input  [4:0] RdM, RdW,
    input        RegWriteM, RegWriteW,
    input        ResultSrcE0,           // ResultSrcE[0]: instruction in Execute is a load
    input        PCSrcE,                // branch taken / jump in Execute
    output reg [1:0] ForwardAE, ForwardBE,
    output       StallF, StallD,
    output       FlushD, FlushE
);

// ---------------- forwarding (Memory has priority: it is the younger result)
always @(*) begin
    if      (RegWriteM && (RdM != 5'd0) && (RdM == Rs1E)) ForwardAE = 2'b10;
    else if (RegWriteW && (RdW != 5'd0) && (RdW == Rs1E)) ForwardAE = 2'b01;
    else                                                  ForwardAE = 2'b00;

    if      (RegWriteM && (RdM != 5'd0) && (RdM == Rs2E)) ForwardBE = 2'b10;
    else if (RegWriteW && (RdW != 5'd0) && (RdW == Rs2E)) ForwardBE = 2'b01;
    else                                                  ForwardBE = 2'b00;
end

// ---------------- load-use stall (a load's data only exists after Memory)
wire lwStall = ResultSrcE0 && (RdE != 5'd0) && ((Rs1D == RdE) || (Rs2D == RdE));

assign StallF = lwStall;
assign StallD = lwStall;

// ---------------- control hazard / bubble insertion
assign FlushD = PCSrcE;
assign FlushE = lwStall || PCSrcE;

endmodule
