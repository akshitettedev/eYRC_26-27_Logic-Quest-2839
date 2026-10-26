
// controller.v - controller for RISC-V CPU (works on the instruction in the Decode stage)

module controller (
    input  [6:0] op,
    input  [2:0] funct3,
    input        funct7b5,
    output [1:0] ResultSrc,
    output       MemWrite,
    output       ALUSrc,
    output [1:0] ALUSrcA,
    output       RegWrite, Branch, Jump, Jalr,
    output [2:0] ImmSrc,
    output [3:0] ALUControl
);

wire [1:0] ALUOp;

main_decoder    md (op, ResultSrc, MemWrite, Branch, ALUSrc, ALUSrcA,
                    RegWrite, Jump, ImmSrc, ALUOp);

alu_decoder     ad (op[5], funct3, funct7b5, ALUOp, ALUControl);

assign Jalr = (op == 7'b1100111);

endmodule
