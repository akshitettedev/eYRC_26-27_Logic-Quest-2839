
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

reg [SPI_WORD_LENGTH-1:0] tx_shift;
reg [SPI_WORD_LENGTH-1:0] rx_shift;

reg [31:0] half_count;
reg [31:0] bit_count;

always @(posedge clk_50MHz or negedge rst_n) begin
    if (!rst_n) begin
        tx_shift    <= {SPI_WORD_LENGTH{1'b0}};
        rx_shift    <= {SPI_WORD_LENGTH{1'b0}};

        half_count  <= 32'd0;
        bit_count   <= 32'd0;

        sclk_out    <= CPOL;
        cs_out      <= 1'b1;
        mosi_output <= 1'b0;

        rx_data     <= {SPI_WORD_LENGTH{1'b0}};
        busy        <= 1'b0;
    end
    else begin

        // IDLE state
        if (!busy) begin
            sclk_out   <= CPOL;
            cs_out     <= 1'b1;
            half_count <= 32'd0;
            bit_count  <= 32'd0;

            // Start a transfer only when idle
            if (start) begin
                tx_shift    <= tx_data;
                rx_shift    <= {SPI_WORD_LENGTH{1'b0}};

                half_count  <= 32'd0;
                bit_count   <= 32'd0;

                // SPI Mode 0: clock idles low
                sclk_out    <= 1'b0;

                // Assert chip select and busy together
                cs_out      <= 1'b0;
                busy        <= 1'b1;

                // Present the MSB immediately
                mosi_output <= tx_data[SPI_WORD_LENGTH-1];
            end
            else begin
                busy <= 1'b0;
            end
        end

        // TRANSFER state
        else begin

            // Generate SCLK edges at the required intervals
            if (half_count == HALF_PERIOD) begin

                // Start counting toward the next edge.
                // Setting the count to 1 makes subsequent
                // edges exactly HALF_PERIOD clocks apart.
                half_count <= 32'd1;

                // Rising SCLK edge: sample MISO
                if (sclk_out == 1'b0) begin
                    sclk_out <= 1'b1;

                    rx_shift <= (rx_shift << 1) |
                                {{(SPI_WORD_LENGTH-1){1'b0}},
                                  miso_input};

                    bit_count <= bit_count + 1'b1;
                end

                // Falling SCLK edge
                else begin
                    sclk_out <= 1'b0;

                    // Finish on the falling edge after the
                    // final rising edge has sampled MISO.
                    if (bit_count == SPI_WORD_LENGTH) begin
                        cs_out     <= 1'b1;
                        busy       <= 1'b0;
                        rx_data    <= rx_shift;
                        half_count <= 32'd0;
                        sclk_out   <= 1'b0;
                    end
                    else begin
                        // Prepare the next MOSI bit.
                        mosi_output <=
                            tx_shift[SPI_WORD_LENGTH-1-bit_count];
                    end
                end
            end
            else begin
                half_count <= half_count + 1'b1;
            end
        end
    end
end

//////////////////DO NOT MAKE ANY CHANGES BELOW THIS LINE //////////////////

endmodule
