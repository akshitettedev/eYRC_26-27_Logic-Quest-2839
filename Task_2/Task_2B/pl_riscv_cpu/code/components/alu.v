// alu.v - ALU module (full RV32I arithmetic/logic set)

module alu #(parameter WIDTH = 32) (
    input       [WIDTH-1:0] a, b,       // operands
    input       [3:0] alu_ctrl,         // ALU control
    output reg  [WIDTH-1:0] alu_out     // ALU output
);

wire [4:0] shamt = b[4:0];

always @(*) begin
    case (alu_ctrl)
        4'b0000: alu_out = a + b;                              // ADD
        4'b0001: alu_out = a - b;                              // SUB
        4'b0010: alu_out = a & b;                              // AND
        4'b0011: alu_out = a | b;                              // OR
        4'b0100: alu_out = a ^ b;                              // XOR
        4'b0101: alu_out = {{(WIDTH-1){1'b0}}, ($signed(a) < $signed(b))}; // SLT
        4'b0110: alu_out = {{(WIDTH-1){1'b0}}, (a < b)};       // SLTU
        4'b0111: alu_out = a << shamt;                         // SLL
        4'b1000: alu_out = a >> shamt;                         // SRL
        4'b1001: alu_out = $signed(a) >>> shamt;               // SRA
        default: alu_out = {WIDTH{1'b0}};
    endcase
end

endmodule
