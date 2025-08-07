// -----------------------------------------------------------------------------
// spi_slave: SPI Slave Controller with Internal Memory
// -----------------------------------------------------------------------------
// This module implements an SPI slave that receives 41-bit packets from the SPI
// master and either writes to or reads from an internal memory array. The packet
// format includes a write/read flag, address, and data. The slave supports both
// write and read operations, shifting data in and out according to SPI protocol.
// ----------------------------------------------------------------------------

`timescale 1ns / 1ps

module spi_slave (
    input      SCLK,           // SPI system clock
    input      SRESET,         // Active-high SPI reset
    input      spi_clk,        // SPI clock from master
    input      cs,             // Chip select (active low)
    input      mosi,           // Master Out Slave In
    output reg miso            // Master In Slave Out
);

    localparam IDLE      = 2'd0,
               RECEIVE   = 2'd1,
               WRITE     = 2'd2,
               PREP_READ = 2'd3,
               SEND      = 3'd4;

    reg[2:0] state, next_state;         // FSM state and next state

    reg [5:0]  bit_cnt;                 // Bit counter for SPI transfer
    reg [40:0] shift_reg_in;            // Shift register for incoming SPI data
    reg [31:0] shift_reg_out;           // Shift register for outgoing SPI data
    reg [31:0] rx_data;                 // Received data
    reg [31:0] tx_data;                 // Data to transmit
    reg [7:0]  addr;                    // Address field from packet
    reg        wr_rd_en;                // Write/Read enable flag
    reg [31:0] spi_memory [0:255];      // Internal memory array

    // FSM state transition
    always @(posedge SCLK or posedge SRESET) begin
        if (SRESET) begin
            state         = IDLE;
            bit_cnt       = 6'd0;
            shift_reg_in  = 41'b0;
            shift_reg_out = 32'b0;
            rx_data       = 32'b0;
            tx_data       = 32'b0;
            addr          = 8'b0;
            wr_rd_en      = 1'b0;
            miso          = 1'b0;
        end else begin
            state        = next_state;
        end
    end

    // FSM next state and output logic
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (!cs) next_state = RECEIVE; // Start receiving when CS is low
                else next_state = IDLE;
            end
            RECEIVE: begin
                if (bit_cnt == 0) begin
                    if (shift_reg_in[40]) // Write operation
                        next_state = WRITE;
                    else
                        next_state = PREP_READ; // Read operation
                end
                else if (cs) next_state = IDLE;
                else next_state = RECEIVE;
            end
            WRITE: begin
                next_state = IDLE;
            end
            PREP_READ: begin
                next_state = SEND;
            end
            SEND: begin
                if (bit_cnt == 0 || cs)
                    next_state = IDLE;
                else next_state = SEND;
            end
        endcase
    end

    // FSM output and data path
    always @(posedge SCLK) begin
        if (SRESET) begin
            // Already handled above
        end else begin
            case (state)
                IDLE: begin
                    bit_cnt       = 6'd41;
                    shift_reg_in  = 41'b0;
                    shift_reg_out = 32'b0;
                    miso          = 1'b0;
                end
                RECEIVE: begin
                    // Sample on rising edge of spi_clk
                    if (spi_clk && bit_cnt > 0) begin
                        shift_reg_in = {shift_reg_in[39:0], mosi}; // Shift in MOSI data
                        bit_cnt      = bit_cnt - 1;
                    end
                end
                WRITE: begin
                    wr_rd_en = shift_reg_in[40];         // Write/Read flag
                    addr     = shift_reg_in[39:32];      // Address field
                    rx_data  = shift_reg_in[31:0];       // Data field
                    spi_memory[addr] = rx_data;          // Write to memory
                end
                PREP_READ: begin
                    wr_rd_en      = shift_reg_in[40];    // Write/Read flag
                    addr          = shift_reg_in[39:32]; // Address field
                    tx_data       = spi_memory[addr];    // Read from memory
                    shift_reg_out = spi_memory[addr];    // Prepare data for sending
                    bit_cnt       = 6'd32;
                end
                SEND: begin
                    // Shift out on falling edge of spi_clk
                    if (!spi_clk && bit_cnt > 0) begin
                        miso    = shift_reg_out[bit_cnt-1]; // Shift out MISO data
                        bit_cnt = bit_cnt - 1;
                    end
                    if (bit_cnt == 0 || cs) begin
                        miso = 1'b0;
                    end
                end
            endcase
        end
    end

endmodule