// controller.v - controller for RISC-V CPU

module controller (
    input [6:0]  op,
    input [2:0]  funct3,
    input        funct7b5,
    input        Eq, Lt, Ltu,       // comparison flags from the datapath
    output       [1:0] ResultSrc,
    output       MemWrite,
    output       PCSrc, ALUSrc,
    output       [1:0] ALUSrcA,
    output       RegWrite, Jump, Jalr,
    output       [2:0] ImmSrc,
    output       [3:0] ALUControl
);

wire [1:0] ALUOp;
wire       Branch;
reg        BranchTaken;

main_decoder md (
    op, ResultSrc, MemWrite, Branch, ALUSrc, ALUSrcA,
    RegWrite, Jump, ImmSrc, ALUOp
);

alu_decoder ad (
    op[5], funct3, funct7b5, ALUOp, ALUControl
);

// branch condition selected by funct3
always @(*) begin
    case (funct3)
        3'b000:  BranchTaken = Eq;     // beq
        3'b001:  BranchTaken = ~Eq;    // bne
        3'b100:  BranchTaken = Lt;     // blt
        3'b101:  BranchTaken = ~Lt;    // bge
        3'b110:  BranchTaken = Ltu;    // bltu
        3'b111:  BranchTaken = ~Ltu;   // bgeu
        default: BranchTaken = 1'b0;
    endcase
end

// PC source for branch/jal; JALR uses its own source in the datapath.
assign PCSrc = (Branch & BranchTaken) | Jump;
assign Jalr  = (op == 7'b1100111);

endmodule
