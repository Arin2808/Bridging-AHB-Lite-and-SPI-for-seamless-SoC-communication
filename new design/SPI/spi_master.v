`timescale 1ns / 1ps

module spi_master (
    input  wire        SCLK,               // SPI system clock, synchronizes all SPI operations
    input  wire        SRESET,             // Active-high SPI reset, initializes or clears all internal states and outputs
    output reg         spi_clk,            // SPI clock to slaves
    output reg         spi_mosi,           // Master Out Slave In
    input  wire        spi_miso,           // Master In Slave Out
    output reg         spi_cs0,            // Chip select 0 (active low)
    output reg         spi_cs1,            // Chip select 1 (active low)
    input  wire [40:0] Tx_FIFO_data_in,    // 41-bit data from TX FIFO
    output reg         Tx_FIFO_read_en,    // TX FIFO read enable
    input  wire        Tx_FIFO_empty,      // TX FIFO empty flag
    output reg [31:0]  Rx_FIFO_data_out,   // 32-bit data to RX FIFO
    output reg         Rx_FIFO_write_en,   // RX FIFO write enable
    input  wire        Rx_FIFO_full        // RX FIFO full flag
);

    reg [40:0] shift_reg;      // Shift register for SPI data transmission
    reg [5:0]  bit_count;      // Bit counter for SPI transfer
    reg [31:0] rx_data;        // Temporary storage for received data
    reg        rx_valid;       // Indicates valid received data
    reg        wr_rd_en;       // Write/Read enable from FIFO data
    reg        chip_sel;       // Chip select decoded from FIFO data
    reg [6:0]  addr;           // Address field from FIFO data
    reg [31:0] data;           // Data field from FIFO data

    reg [1:0]  state;          // SPI master state machine
    localparam IDLE      = 2'd0,
               LOAD      = 2'd1,
               SEND      = 2'd2,
               WRITE_RX  = 2'd3;

    always @(posedge SCLK or posedge SRESET) begin
        // On reset, clear all internal states and outputs
        if (SRESET) begin
            state             <= IDLE;         // Set state machine to IDLE
            spi_clk           <= 1'b0;         // Clear SPI clock output
            spi_mosi          <= 1'b0;         // Clear MOSI output
            spi_cs0           <= 1'b1;         // Deactivate chip select 0
            spi_cs1           <= 1'b1;         // Deactivate chip select 1
            Tx_FIFO_read_en   <= 1'b0;         // Clear TX FIFO read enable
            Rx_FIFO_write_en  <= 1'b0;         // Clear RX FIFO write enable
            Rx_FIFO_data_out  <= 32'd0;        // Clear RX FIFO data output
            shift_reg         <= 41'd0;        // Clear shift register
            bit_count         <= 6'd0;         // Clear bit counter
            rx_data           <= 32'd0;        // Clear received data
            rx_valid          <= 1'b0;         // Clear receive valid flag
            wr_rd_en          <= 1'b0;         // Clear write/read enable
            chip_sel          <= 1'b0;         // Clear chip select decode
            addr              <= 7'd0;         // Clear address field
            data              <= 32'd0;        // Clear data field
        end else begin
            Tx_FIFO_read_en   <= 1'b0;         // Default: no TX FIFO read
            Rx_FIFO_write_en  <= 1'b0;         // Default: no RX FIFO write

            case (state)
                IDLE: begin
                    spi_clk  <= 1'b0;         // SPI clock low in IDLE
                    spi_cs0  <= 1'b1;         // Deactivate chip select 0
                    spi_cs1  <= 1'b1;         // Deactivate chip select 1
                    // If TX FIFO has data, move to LOAD state
                    if (!Tx_FIFO_empty) begin
                        state <= LOAD;
                    end
                end

                LOAD: begin
                    // Load data from TX FIFO into local registers
                    shift_reg       <= Tx_FIFO_data_in;
                    wr_rd_en        <= Tx_FIFO_data_in[40];
                    chip_sel        <= Tx_FIFO_data_in[39];
                    addr            <= Tx_FIFO_data_in[38:32];
                    data            <= Tx_FIFO_data_in[31:0];
                    // Activate appropriate chip select
                    spi_cs0         <= (Tx_FIFO_data_in[39] == 1'b0) ? 1'b0 : 1'b1;
                    spi_cs1         <= (Tx_FIFO_data_in[39] == 1'b1) ? 1'b0 : 1'b1;
                    bit_count       <= 6'd0;         // Reset bit counter
                    rx_data         <= 32'd0;        // Clear receive buffer
                    rx_valid        <= 1'b0;         // Clear receive valid flag
                    Tx_FIFO_read_en <= 1'b1;         // Trigger TX FIFO read
                    state           <= SEND;         // Move to SEND state
                end

                SEND: begin
                    spi_clk <= ~spi_clk;             // Toggle SPI clock
                    if (!spi_clk) begin
                        // On SPI clock low, drive MOSI with next bit
                        spi_mosi <= shift_reg[40 - bit_count];
                    end else begin
                        // On SPI clock high, sample MISO for read operations
                        if (!wr_rd_en && bit_count >= 6'd9 && bit_count <= 6'd40) begin
                            rx_data[40 - bit_count] <= spi_miso;
                        end
                        bit_count <= bit_count + 1; // Increment bit counter
                        // If all bits sent, finish transaction
                        if (bit_count == 6'd40) begin
                            spi_cs0   <= 1'b1;      // Deactivate chip select 0
                            spi_cs1   <= 1'b1;      // Deactivate chip select 1
                            rx_valid  <= !wr_rd_en; // Set receive valid if read
                            state     <= (!wr_rd_en) ? WRITE_RX : IDLE; // Next state
                        end
                    end
                end

                WRITE_RX: begin
                    // Write received data to RX FIFO if valid and not full
                    if (!Rx_FIFO_full && rx_valid) begin
                        Rx_FIFO_data_out <= rx_data;
                        Rx_FIFO_write_en <= 1'b1;
                        rx_valid         <= 1'b0;   // Clear receive valid flag
                        state            <= IDLE;   // Return to IDLE
                    end
                end
            endcase
        end
    end

endmodule