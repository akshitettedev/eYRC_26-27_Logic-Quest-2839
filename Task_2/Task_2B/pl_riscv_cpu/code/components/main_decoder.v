// main_decoder.v - logic for RISC-V CPU

module main_decoder (
    input  [6:0]  op,
    output [1:0]  ResultSrc,
    output       MemWrite, Branch, ALUSrc,
    output [1:0]  ALUSrcA,
    output       RegWrite, Jump,
    output [2:0]  ImmSrc,
    output [1:0]  ALUOp
);

// RegWrite_ImmSrc_ALUSrc_ALUSrcA_MemWrite_ResultSrc_Branch_ALUOp_Jump
// Width = 1 + 3 + 1 + 2 + 1 + 2 + 1 + 2 + 1 = 14 bits
reg [13:0] controls;

always @(*) begin
    case (op)
        7'b0000011: controls = 14'b1_000_1_00_0_01_0_00_0; // lw
        7'b0100011: controls = 14'b0_001_1_00_1_00_0_00_0; // sw
        7'b0110011: controls = 14'b1_xxx_0_00_0_00_0_10_0; // R-type
        7'b1100011: controls = 14'b0_010_0_00_0_00_1_01_0; // beq
        7'b0010011: controls = 14'b1_000_1_00_0_00_0_10_0; // I-type ALU
        7'b1101111: controls = 14'b1_011_0_00_0_10_0_00_1; // jal
        7'b0110111: controls = 14'b1_100_1_10_0_00_0_00_0; // lui
        7'b0010111: controls = 14'b1_100_1_01_0_00_0_00_0; // auipc
        7'b1100111: controls = 14'b1_000_1_00_0_10_0_00_0; // jalr
        default:    controls = 14'bx_xxx_x_xx_x_xx_x_xx_x;
    endcase
end

assign {RegWrite, ImmSrc, ALUSrc, ALUSrcA, MemWrite,
        ResultSrc, Branch, ALUOp, Jump} = controls;

endmodule
