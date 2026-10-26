// branching_unit.v - branch condition evaluation in the Execute stage
//
// SrcA / SrcB are the *forwarded* rs1 / rs2 values, so a branch that
// depends on the instruction just above it sees the right operands.
// One subtraction gives both the unsigned and (with the sign bits) the
// signed "less than"; equality uses its own comparator.

module branching_unit (
    input  [2:0]  funct3,
    input  [31:0] SrcA, SrcB,
    output reg    TakeBranch
);

wire [32:0] diff = {1'b0, SrcA} - {1'b0, SrcB};
wire        Eq   = (SrcA == SrcB);
wire        Ltu  = diff[32];
wire        Lt   = (SrcA[31] == SrcB[31]) ? diff[32] : SrcA[31];

always @(*) begin
    case (funct3)
        3'b000:  TakeBranch =  Eq;   // beq
        3'b001:  TakeBranch = ~Eq;   // bne
        3'b100:  TakeBranch =  Lt;   // blt
        3'b101:  TakeBranch = ~Lt;   // bge
        3'b110:  TakeBranch =  Ltu;  // bltu
        3'b111:  TakeBranch = ~Ltu;  // bgeu
        default: TakeBranch = 1'b0;
    endcase
end

endmodule
