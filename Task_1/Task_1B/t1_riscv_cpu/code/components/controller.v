// controller.v - controller for RISC-V CPU

module controller (
    input [6:0]  op,
    input [2:0]  funct3,
    input        funct7b5,
    input        Zero,
    output       [1:0] ResultSrc,
    output       MemWrite,
    output       PCSrc, ALUSrc,
    output       [1:0] ALUSrcA,
    output       RegWrite, Jump, Jalr,
    output       [2:0] ImmSrc,
    output       [2:0] ALUControl
);

wire [1:0] ALUOp;
wire       Branch;

main_decoder md (
    op, ResultSrc, MemWrite, Branch, ALUSrc, ALUSrcA,
    RegWrite, Jump, ImmSrc, ALUOp
);

alu_decoder ad (
    op[5], funct3, funct7b5, ALUOp, ALUControl
);

// PC source for branch/jal; JALR uses its own source in the datapath.
assign PCSrc = (Branch & Zero) | Jump;
assign Jalr  = (op == 7'b1100111);

endmodule
