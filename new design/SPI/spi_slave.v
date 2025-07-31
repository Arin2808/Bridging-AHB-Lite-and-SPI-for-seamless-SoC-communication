`timescale 1ns / 1ps

module spi_slave (
    input wire SCLK,          // System clock for SPI slave, synchronizes all internal operations
    input wire SRESET,        // Active-high reset for SPI slave, initializes or clears all internal states and outputs
    input wire spi_clk,       // SPI clock from master, synchronizes SPI data transfers
    input wire cs,            // Chip select from master (active low)
    input wire mosi,          // Master Out Slave In
    output reg miso           // Master In Slave Out
);

    reg [5:0]  bit_cnt;           // Counts SPI bits received/transmitted
    reg [40:0] shift_reg_in;      // Shift register for incoming SPI data
    reg [31:0] shift_reg_out;     // Shift register for outgoing SPI data
    reg [31:0] rx_data;           // Stores received data
    reg [31:0] tx_data;           // Stores data to transmit
    reg [6:0]  addr;              // Address field from SPI data
    reg        wr_rd_en;          // Write/Read enable decoded from SPI data
    reg        spi_clk_prev;      // Previous value of SPI clock for edge detection
    reg        active;            // Indicates active SPI transaction

    reg [31:0] mem [0:127];       // Internal memory array

    always @(posedge SCLK) begin
        // On reset, clear all internal states and outputs
        if (SRESET) begin
            shift_reg_in  <= 41'b0;    
            shift_reg_out <= 32'b0;    
            rx_data       <= 32'b0;    
            tx_data       <= 32'b0;    
            addr          <= 7'b0;     
            wr_rd_en      <= 1'b0;     
            miso          <= 1'b0;     
            bit_cnt       <= 6'd0;     
            spi_clk_prev  <= 1'b0;     
            active        <= 1'b0;     
        end else begin
            spi_clk_prev <= spi_clk;   // Store previous SPI clock for edge detection

            // Detect start of SPI transaction (chip select active low)
            if (!cs && !active) begin
                active       <= 1'b1;      // Mark transaction as active
                bit_cnt      <= 6'd40;     // Initialize bit counter for 41 bits
                shift_reg_in <= 41'b0;     // Clear input shift register
                shift_reg_out <= 32'b0;    // Clear output shift register
                miso         <= 1'b0;      // Clear MISO output
            end

            // Detect end of SPI transaction (chip select inactive high)
            if (cs) begin
                active    <= 1'b0;
                miso      <= 1'b0;         
                bit_cnt   <= 6'd0;         
                // Latch received data and decode command when transaction ends
                if (bit_cnt == 6'd0 && active) begin
                    wr_rd_en <= shift_reg_in[40];           // Decode write/read enable
                    addr     <= shift_reg_in[39:33];        // Decode address
                    rx_data  <= shift_reg_in[32:1];         // Latch received data
                    if (shift_reg_in[40]) begin
                        mem[shift_reg_in[39:33]] <= shift_reg_in[32:1]; // Write to memory
                    end else begin
                        tx_data <= mem[shift_reg_in[39:33]];            // Prepare data for read
                    end
                end
            end

            // SPI transaction active and chip select low
            if (active && !cs) begin
                // On rising edge of SPI clock, shift in MOSI data
                if (!spi_clk_prev && spi_clk) begin
                    shift_reg_in <= {shift_reg_in[39:0], mosi}; // Shift in MOSI bit
                    // When address bits are received, decode command and prepare output data
                    if (bit_cnt == 6'd33) begin
                        wr_rd_en <= shift_reg_in[40];
                        addr     <= shift_reg_in[39:33];
                        if (!shift_reg_in[40]) begin
                            shift_reg_out <= mem[shift_reg_in[39:33]]; // Load data for read
                        end
                    end
                    if (bit_cnt > 6'd0) begin
                        bit_cnt <= bit_cnt - 1; // Decrement bit counter
                    end
                end

                // On falling edge of SPI clock, drive MISO data
                if (spi_clk_prev && !spi_clk) begin
                    if (wr_rd_en) begin
                        miso <= 1'b0; // For write, MISO stays low
                    end else if (bit_cnt >= 6'd9 && bit_cnt <= 6'd40) begin
                        miso <= shift_reg_out[40 - bit_cnt]; // Output data bits on MISO
                    end else begin
                        miso <= 1'b0; // Otherwise, MISO stays low
                    end
                end
            end
        end
    end

endmodule