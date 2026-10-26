
// hazard_unit.v - combinational hazard unit: forwarding, load-use stall, branch flush
// ForwardAE/BE: 2'b00 = register file value, 2'b10 = from Memory stage, 2'b01 = from Writeback stage

module hazard_unit (
    input      [4:0] Rs1D, Rs2D,
    input      [4:0] Rs1E, Rs2E, RdE,
    input      [4:0] RdM, input RegWriteM,
    input      [4:0] RdW, input RegWriteW,
    input            ResultSrcE0,        // instruction in Execute is a load
    input            PCSrcE,             // branch / jump taken in Execute
    output reg [1:0] ForwardAE, ForwardBE,
    output           StallF, StallD,
    output           FlushD, FlushE
);

always @(*) begin
    if      (RegWriteM && (RdM != 5'd0) && (RdM == Rs1E)) ForwardAE = 2'b10;
    else if (RegWriteW && (RdW != 5'd0) && (RdW == Rs1E)) ForwardAE = 2'b01;
    else                                                   ForwardAE = 2'b00;

    if      (RegWriteM && (RdM != 5'd0) && (RdM == Rs2E)) ForwardBE = 2'b10;
    else if (RegWriteW && (RdW != 5'd0) && (RdW == Rs2E)) ForwardBE = 2'b01;
    else                                                   ForwardBE = 2'b00;
end

// load in Execute whose destination is a source of the instruction in Decode
wire lwStall = ResultSrcE0 && (RdE != 5'd0) && ((RdE == Rs1D) || (RdE == Rs2D));

assign StallF = lwStall;
assign StallD = lwStall;
assign FlushD = PCSrcE;
assign FlushE = lwStall | PCSrcE;

endmodule
