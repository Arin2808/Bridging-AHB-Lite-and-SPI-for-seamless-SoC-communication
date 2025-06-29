module spi_master (
    input  wire        clk,                // System clock
    input  wire        reset_n,            // Active-low reset

    output reg         spi_clk,            // SPI clock
    output reg         spi_mosi,           // SPI MOSI
    input  wire        spi_miso,           // SPI MISO
    output reg         spi_cs0,            // SPI chip select 0 (active low)
    output reg         spi_cs1,            // SPI chip select 1 (active low)

    input  wire [40:0] Tx_FIFO_data_in,    // 41-bit data from TX FIFO
    output reg         Tx_FIFO_read_en,    // TX FIFO read enable
    input  wire        Tx_FIFO_empty,      // TX FIFO empty flag

    output reg [31:0]  Rx_FIFO_data_out,   // 32-bit data to RX FIFO
    output reg         Rx_FIFO_write_en,   // RX FIFO write enable
    input  wire        Rx_FIFO_full        // RX FIFO full flag
);

    // Internal registers
    reg [40:0] shift_reg;                  // Shift register for SPI transmission
    reg [5:0]  bit_count;                  // Bit counter (0-40)
    reg [31:0] rx_data;                    // Received 32-bit data for RX FIFO
    reg        rx_valid;                   // Indicates valid received data

    // Decoded fields from FIFO data
    reg        wr_rd_en;                   // Write/Read enable (0 = read, 1 = write)
    reg        chip_sel;                   // Chip select bit
    reg [6:0]  addr;                       // Address field
    reg [31:0] data;                       // Data field

    // FSM states
    reg [1:0]  state;                      // FSM state register
    localparam IDLE      = 2'd0,           // Wait for new transaction
               LOAD      = 2'd1,           // Load data from Tx_FIFO
               SEND      = 2'd2,           // Send/receive SPI data
               WRITE_RX  = 2'd3;           // Write to Rx_FIFO for read operations

    // SPI clock divider
    parameter SPI_CLK_DIV = 4; // Adjust as needed
    reg [2:0] clk_div_cnt;
    reg spi_clk_en;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            clk_div_cnt <= 0;
            spi_clk_en  <= 0;
        end else if (state == SEND) begin
            if (clk_div_cnt == (SPI_CLK_DIV-1)) begin
                clk_div_cnt <= 0;
                spi_clk_en  <= 1;
            end else begin
                clk_div_cnt <= clk_div_cnt + 1;
                spi_clk_en  <= 0;
            end
        end else begin
            clk_div_cnt <= 0;
            spi_clk_en  <= 0;
        end
    end

    // SPI Master FSM
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            // Asynchronous reset: set all outputs and registers to default
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
            // Default outputs
            Tx_FIFO_read_en  <= 1'b0;
            Rx_FIFO_write_en <= 1'b0;

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
                    // Load data from Tx_FIFO
                    shift_reg       <= Tx_FIFO_data_in;
                    wr_rd_en        <= Tx_FIFO_data_in[40];
                    chip_sel        <= Tx_FIFO_data_in[39];
                    addr            <= Tx_FIFO_data_in[38:32];
                    data            <= Tx_FIFO_data_in[31:0];
                    spi_cs0         <= (Tx_FIFO_data_in[39] == 1'b0) ? 1'b0 : 1'b1;
                    spi_cs1         <= (Tx_FIFO_data_in[39] == 1'b1) ? 1'b0 : 1'b1;
                    bit_count       <= 6'd0;
                    rx_valid        <= 1'b0;
                    rx_data         <= 32'd0;
                    Tx_FIFO_read_en <= 1'b1;
                    spi_clk         <= 1'b0;
                    state           <= SEND;
                end

                SEND: begin
                    if (spi_clk_en) begin
                        spi_clk <= ~spi_clk;

                        if (!spi_clk) begin
                            // On falling edge: output MOSI
                            spi_mosi <= shift_reg[40 - bit_count];
                        end else begin
                            // On rising edge: sample MISO
                            if (!wr_rd_en && bit_count >= 6'd9 && bit_count <= 6'd40) begin
                                rx_data[40 - bit_count] <= spi_miso; // Correct bit mapping
                            end

                            // Increment bit counter after each full SPI clock cycle
                            bit_count <= bit_count + 1'b1;

                            if (bit_count == 6'd40) begin
                                spi_cs0 <= 1'b1; // Deactivate chip selects
                                spi_cs1 <= 1'b1;
                                rx_valid <= !wr_rd_en; // Set rx_valid only for read
                                state <= (!wr_rd_en) ? WRITE_RX : IDLE;
                            end
                        end
                    end
                end

                WRITE_RX: begin
                    if (!Rx_FIFO_full && rx_valid) begin
                        Rx_FIFO_data_out <= rx_data;
                        Rx_FIFO_write_en <= 1'b1;
                        rx_valid <= 1'b0;
                        state <= IDLE;
                    end
                end
            endcase
        end
    end

endmodule