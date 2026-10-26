// reg_file.v - register file for the 5-stage pipelined RISC-V CPU
//              (32 registers, each of 32 bits)
//              two read ports (combinational), one write port
//              register 0 is hardwired to 0
//
// The write happens on the FALLING clock edge. Decode reads this file in the
// same cycle Writeback writes it: the write lands in the first half of the
// cycle and the (combinational) read picks it up in the second half, so no
// third forwarding path (Writeback -> Decode) is needed.

module reg_file #(parameter DATA_WIDTH = 32) (
    input       clk,
    input       wr_en,
    input       [4:0] rd_addr1, rd_addr2, wr_addr,
    input       [DATA_WIDTH-1:0] wr_data,
    output      [DATA_WIDTH-1:0] rd_data1, rd_data2
);

reg [DATA_WIDTH-1:0] reg_file_arr [0:31];

integer i;
initial begin
    for (i = 0; i < 32; i = i + 1) reg_file_arr[i] = 0;
end

// register file write logic (falling edge; x0 is never written)
always @(negedge clk) begin
    if (wr_en && (wr_addr != 5'd0)) reg_file_arr[wr_addr] <= wr_data;
end

// register file read logic (combinational)
assign rd_data1 = ( rd_addr1 != 0 ) ? reg_file_arr[rd_addr1] : 0;
assign rd_data2 = ( rd_addr2 != 0 ) ? reg_file_arr[rd_addr2] : 0;

endmodule
