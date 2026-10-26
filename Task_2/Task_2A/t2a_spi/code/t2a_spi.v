
/*
eYRC26-27: Logic Quest
Task 2A: SPI Master Module
SPI Mode 0, MSB first.
*/

module t2a_spi
#(
    parameter CPOL             = 1'b0,
    parameter CPHA             = 1'b0,
    parameter LSB_FIRST        = 1'b0,
    parameter SPI_WORD_LENGTH  = 8,
    parameter HALF_PERIOD      = 25
)
(
    input wire clk_50MHz,
    input wire rst_n,

    input wire start,
    input wire [SPI_WORD_LENGTH-1:0] tx_data,
    input wire miso_input,

    output reg sclk_out,
    output reg cs_out,
    output reg mosi_output,

    output reg [SPI_WORD_LENGTH-1:0] rx_data,
    output reg busy
);

//////////////////DO NOT MAKE ANY CHANGES ABOVE THIS LINE //////////////////

// ---------------------------------------------------------------------
// Minimal-resource SPI master, Mode 0, MSB first.
//
// Registers used:
//   sh        : one shift register. It holds the bits still to be sent
//               (MSB = current MOSI bit) and the bits already received.
//   miso_s    : MISO sampled on the rising SCLK edge, moved into sh on
//               the next falling edge.
//   cnt       : counts clock cycles inside one half SCLK period.
//   pair_cnt  : counts completed SCLK pulses (rise + fall).
//   sclk_out, cs_out, rx_data : outputs.
// busy and mosi_output are plain wires of existing registers
// (busy = ~cs_out, mosi_output = sh MSB), so they cost no flip-flops.
// ---------------------------------------------------------------------

// Smallest number of bits that can hold values 0 .. (value-1)
function integer clog2;
    input integer value;
    integer v;
    begin
        v = value - 1;
        for (clog2 = 0; v > 0; clog2 = clog2 + 1)
            v = v >> 1;
    end
endfunction

localparam CNT_W  = clog2(HALF_PERIOD + 1);
localparam [CNT_W-1:0] CNT_ONE = 1;
localparam PAIR_W = clog2(SPI_WORD_LENGTH);

// If the word length is not a power of two the pulse counter does not
// wrap to 0 on its own, so it must be cleared explicitly at the end.
localparam NEED_CLEAR = ((SPI_WORD_LENGTH & (SPI_WORD_LENGTH - 1)) != 0);

reg [SPI_WORD_LENGTH-1:0] sh;
reg                       miso_s;
reg [CNT_W-1:0]           cnt;
reg [PAIR_W-1:0]          pair_cnt;

// An SCLK edge is generated when the cycle counter reaches HALF_PERIOD
wire tick    = (cnt == HALF_PERIOD);
wire rising  = tick & ~sclk_out;
wire falling = tick &  sclk_out;
wire last    = falling & (pair_cnt == SPI_WORD_LENGTH - 1);

// Outputs derived directly from registers
always @(*) begin
    busy        = ~cs_out;
    mosi_output = sh[SPI_WORD_LENGTH-1];
end

always @(posedge clk_50MHz or negedge rst_n) begin
    if (!rst_n) begin
        cs_out   <= 1'b1;
        sclk_out <= 1'b0;
        cnt      <= {CNT_W{1'b0}};
        pair_cnt <= {PAIR_W{1'b0}};
        sh       <= {SPI_WORD_LENGTH{1'b0}};
        miso_s   <= 1'b0;
        rx_data  <= {SPI_WORD_LENGTH{1'b0}};
    end
    else begin
        if (cs_out) begin
            // IDLE: keep the counter cleared, wait for start
            cnt <= {CNT_W{1'b0}};
            if (start) begin
                cs_out <= 1'b0;      // busy rises with it (busy = ~cs_out)
                sh     <= tx_data;   // capture data, MSB is now on MOSI
            end
        end
        else begin
            // TRANSFER
            // cnt counts 0,1,..,HALF_PERIOD for the first half bit and
            // 1,..,HALF_PERIOD afterwards, so every edge is exactly
            // HALF_PERIOD cycles after the previous one (the first one
            // is HALF_PERIOD+1 cycles after cs_out falls).
            if (tick)
                cnt <= CNT_ONE;
            else
                cnt <= cnt + 1'b1;

            if (tick)
                sclk_out <= ~sclk_out;

            if (rising)
                miso_s <= miso_input;

            if (falling) begin
                if (last) begin
                    cs_out  <= 1'b1;
                    rx_data <= {sh[SPI_WORD_LENGTH-2:0], miso_s};
                end
                else
                    sh <= {sh[SPI_WORD_LENGTH-2:0], miso_s};

                if (NEED_CLEAR && last)
                    pair_cnt <= {PAIR_W{1'b0}};
                else
                    pair_cnt <= pair_cnt + 1'b1;
            end
        end
    end
end

//////////////////DO NOT MAKE ANY CHANGES BELOW THIS LINE //////////////////

endmodule
