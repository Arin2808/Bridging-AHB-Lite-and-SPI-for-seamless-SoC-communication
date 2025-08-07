// -----------------------------------------------------------------------------
// spi_master: SPI Master Controller with FIFO Interface
// -----------------------------------------------------------------------------
// This module implements an SPI master that interfaces with transmit (Tx) and
// receive (Rx) FIFOs. It reads 41-bit data from the Tx FIFO, transmits it over
// SPI, and writes received 32-bit data to the Rx FIFO. The design manages SPI
// clock, chip select, and MOSI/MISO signals, and supports both read and write
// operations as indicated by the FIFO data.
// -----------------------------------------------------------------------------

`timescale 1ns / 1ps

module spi_master (
    input         SCLK,                     // SPI system clock
    input         SRESET,                   // Active-high SPI reset
    output reg    spi_clk,                  // SPI clock to slave
    output reg    spi_mosi,                 // Master Out Slave In
    input         spi_miso,                 // Master In Slave Out
    output reg    spi_cs,                   // Chip select (active low)
    input  [40:0] Tx_FIFO_data_in,          // 41-bit data from TX FIFO
    output reg    Tx_FIFO_read_en,          // TX FIFO read enable
    input         Tx_FIFO_empty,            // TX FIFO empty flag
    output reg [31:0]  Rx_FIFO_data_out,    // 32-bit data to RX FIFO
    output reg    Rx_FIFO_write_en,         // RX FIFO write enable
    input         Rx_FIFO_full              // RX FIFO full flag
);

    reg [40:0] shift_reg;      // Shift register for SPI data transmission
    reg [5:0]  bit_count;      // Bit counter for SPI transfer
    reg [31:0] rx_data;        // Temporary storage for received data
    reg        rx_valid;       // Indicates valid received data
    reg        wr_rd_en;       // Write/Read enable from FIFO data

    reg [1:0]  state;          // SPI master state machine
    localparam IDLE      = 2'd0,
               LOAD      = 2'd1,
               SEND      = 2'd2,
               WRITE_RX  = 2'd3;

    always @(posedge SCLK or posedge SRESET) begin
        if (SRESET) begin
            // Reset all outputs and internal registers
            state             <= IDLE;
            spi_clk           <= 1'b0;
            spi_mosi          <= 1'b0;
            spi_cs            <= 1'b1;
            Tx_FIFO_read_en   <= 1'b0;
            Rx_FIFO_write_en  <= 1'b0;
            Rx_FIFO_data_out  <= 32'd0;
            shift_reg         <= 41'd0;
            bit_count         <= 6'd0;
            rx_data           <= 32'd0;
            rx_valid          <= 1'b0;
            wr_rd_en          <= 1'b0;
        end else begin
            // Default disables for FIFO enables
            Tx_FIFO_read_en   <= 1'b0;
            Rx_FIFO_write_en  <= 1'b0;

            case (state)
                IDLE: begin
                    // Wait for data in Tx FIFO
                    spi_clk  <= 1'b0;
                    spi_cs   <= 1'b1;
                    if (!Tx_FIFO_empty) begin
                        Tx_FIFO_read_en <= 1'b1;
                        state <= LOAD;
                    end
                end

                LOAD: begin
                    // Load data from FIFO into shift register
                    if(Tx_FIFO_read_en) begin
                        @(posedge SCLK)
                        shift_reg       <= Tx_FIFO_data_in;
                        wr_rd_en        <= Tx_FIFO_data_in[40]; // MSB: 1=write, 0=read
                        spi_cs          <= 1'b0;
                        bit_count       <= 6'd0;
                        rx_data         <= 32'd0;
                        rx_valid        <= 1'b0;
                        state           <= SEND;
                    end
                    else state <= LOAD;
                end

                SEND: begin
                    // SPI transfer: toggle clock, shift out data, capture MISO
                    spi_clk <= ~spi_clk;
                    if (!spi_clk) begin
                        spi_mosi <= shift_reg[40 - bit_count];
                    end else if (bit_count <= 6'd40) begin
                        if (!wr_rd_en && bit_count >= 6'd9 && bit_count <= 6'd40) begin
                            rx_data[40 - bit_count] <= spi_miso;
                        end
                        bit_count <= bit_count + 1;
                        if (bit_count == 6'd40) begin
                            spi_cs   <= 1'b1;
                            rx_valid <= !wr_rd_en;
                            state    <= (!wr_rd_en) ? WRITE_RX : IDLE;
                        end
                    end
                end

                WRITE_RX: begin
                    // Write received data to Rx FIFO if valid and not full
                    if (!Rx_FIFO_full && rx_valid) begin
                        Rx_FIFO_data_out <= rx_data;
                        Rx_FIFO_write_en <= 1'b1;
                        rx_valid         <= 1'b0;
                        state            <= IDLE;
                    end
                end
            endcase
        end
    end

endmodule