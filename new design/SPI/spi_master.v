`timescale 1ns / 1ps

module spi_master (
    input  wire        clk,                // SPI clock
    input  wire        rst,                // Active-high reset
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

    reg [40:0] shift_reg;
    reg [5:0]  bit_count;
    reg [31:0] rx_data;
    reg        rx_valid;
    reg        wr_rd_en;
    reg        chip_sel;
    reg [6:0]  addr;
    reg [31:0] data;

    reg [1:0]  state;
    localparam IDLE      = 2'd0,
               LOAD      = 2'd1,
               SEND      = 2'd2,
               WRITE_RX  = 2'd3;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state             <= IDLE;
            spi_clk           <= 1'b0;
            spi_mosi          <= 1'b0;
            spi_cs0           <= 1'b1;
            spi_cs1           <= 1'b1;
            Tx_FIFO_read_en   <= 1'b0;
            Rx_FIFO_write_en  <= 1'b0;
            Rx_FIFO_data_out  <= 32'd0;
            shift_reg         <= 41'd0;
            bit_count         <= 6'd0;
            rx_data           <= 32'd0;
            rx_valid          <= 1'b0;
            wr_rd_en          <= 1'b0;
            chip_sel          <= 1'b0;
            addr              <= 7'd0;
            data              <= 32'd0;
        end else begin
            Tx_FIFO_read_en   <= 1'b0;
            Rx_FIFO_write_en  <= 1'b0;

            case (state)
                IDLE: begin
                    spi_clk  <= 1'b0;
                    spi_cs0  <= 1'b1;
                    spi_cs1  <= 1'b1;
                    if (!Tx_FIFO_empty) begin
                        state <= LOAD;
                    end
                end

                LOAD: begin
                    shift_reg       <= Tx_FIFO_data_in;
                    wr_rd_en        <= Tx_FIFO_data_in[40];
                    chip_sel        <= Tx_FIFO_data_in[39];
                    addr            <= Tx_FIFO_data_in[38:32];
                    data            <= Tx_FIFO_data_in[31:0];
                    spi_cs0         <= (Tx_FIFO_data_in[39] == 1'b0) ? 1'b0 : 1'b1;
                    spi_cs1         <= (Tx_FIFO_data_in[39] == 1'b1) ? 1'b0 : 1'b1;
                    bit_count       <= 6'd0;
                    rx_data         <= 32'd0;
                    rx_valid        <= 1'b0;
                    Tx_FIFO_read_en <= 1'b1;
                    state           <= SEND;
                end

                SEND: begin
                    spi_clk <= ~spi_clk;
                    if (!spi_clk) begin
                        spi_mosi <= shift_reg[40 - bit_count];
                    end else begin
                        if (!wr_rd_en && bit_count >= 6'd9 && bit_count <= 6'd40) begin
                            rx_data[40 - bit_count] <= spi_miso;
                        end
                        bit_count <= bit_count + 1;
                        if (bit_count == 6'd40) begin
                            spi_cs0   <= 1'b1;
                            spi_cs1   <= 1'b1;
                            rx_valid  <= !wr_rd_en;
                            state     <= (!wr_rd_en) ? WRITE_RX : IDLE;
                        end
                    end
                end

                WRITE_RX: begin
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