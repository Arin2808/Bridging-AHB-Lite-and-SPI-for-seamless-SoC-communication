// -----------------------------------------------------------------------------
// AHB_slave: AMBA AHB Slave Interface with FIFO Integration
// -----------------------------------------------------------------------------
// This module implements an AHB (Advanced High-performance Bus) slave interface
// that connects to transmit (Tx) and receive (Rx) FIFOs. It handles AHB read and
// write transactions, packs/unpacks data for FIFO communication, and manages
// error signaling for FIFO full/empty conditions. The design assumes a simple
// always-ready interface (no wait states) and supports byte, half-word, and word
// transfers as per the AHB protocol.
// -----------------------------------------------------------------------------

`timescale 1ns / 1ps

module AHB_slave (
    input         HRESET,               // Active-high AHB reset signal
    input         HCLK,                 // AHB clock signal
    input  [7:0]  HADDR,                // AHB address bus 8 bits
    input  [1:0]  HTRANS,               // AHB transfer type
    input         HWRITE,               // AHB write control
    input  [2:0]  HSIZE,                // AHB transfer size
    input  [2:0]  HBURST,               // AHB burst type
    input  [31:0] HWDATA,               // AHB write data bus 32 bits
    // FIFO interface signals
    output reg [40:0] DATA_to_TxFIFO,   // Data to transmit FIFO
    output reg        TxFIFO_wr_en,     // Write enable for transmit FIFO
    input             TxFIFO_full,      // Status from transmit FIFO
    input      [31:0] DATA_from_RxFIFO, // Data from receive FIFO
    output reg        RxFIFO_rd_en,     // Read enable for receive FIFO
    input             RxFIFO_empty,     // Status from receive FIFO
    // AHB response signals
    output [31:0] HRDATA,               // AHB read data bus 32 bits
    output        HRESP,                // AHB response signal
    output        HREADY                // AHB ready signal
);

    // State encoding for AHB transfer protocol
    localparam IDLE = 2'b00, NONSEQ = 2'b10, SEQ = 2'b11;

    reg [1:0]  state;              // Tracks current state of AHB transfer
    reg [31:0] fifo_data_fetch;    // Holds data fetched from RxFIFO for read
    reg        fifo_rd_en_d;       // Delayed read enable for RxFIFO (to sync data fetch)
    reg        error;              // Indicates error condition (e.g., FIFO full/empty)

    // Data alignment function: aligns HWDATA based on HSIZE (byte, half-word, word)
    function [31:0] align_data;
        input [31:0] HWDATA;
        input [2:0]  HSIZE;
        begin
            case (HSIZE)
                3'b000: align_data = {24'b0, HWDATA[7:0]};  // Byte
                3'b001: align_data = {16'b0, HWDATA[15:0]}; // Half-word
                3'b010: align_data = HWDATA;                // Word
                default: align_data = 32'h0;                // Default zero
            endcase
        end
    endfunction

    // Always ready for simplicity (no wait states)
    assign HREADY = 1'b1;
    // Error response signal
    assign HRESP = error;

    // Write enable: when write, ready, and in NONSEQ/SEQ state
    wire wr_en = (HWRITE && HREADY && (state == NONSEQ || state == SEQ));
    // Read enable: when read, ready, and in NONSEQ/SEQ state
    wire rd_en = (!HWRITE && HREADY && (state == NONSEQ || state == SEQ));

    // Main sequential logic: handles state transitions, FIFO operations, and error signaling
    always @(posedge HCLK or posedge HRESET) begin
        if (HRESET) begin
            // Reset all registers and outputs
            state <= IDLE;
            DATA_to_TxFIFO <= 41'h0;
            TxFIFO_wr_en <= 1'b0;
            RxFIFO_rd_en <= 1'b0;
            fifo_data_fetch <= 32'h0;
            fifo_rd_en_d <= 1'b0;
            error <= 1'b0;
        end else begin
            // Default disables for FIFO enables and error
            TxFIFO_wr_en <= 1'b0;
            RxFIFO_rd_en <= 1'b0;
            error <= 1'b0;

            // State machine for AHB transfer protocol
            case (state)
                IDLE: begin
                    // Move to NONSEQ on valid transfer
                    if (HTRANS == NONSEQ && HREADY)
                        state <= NONSEQ;
                    else
                        state <= IDLE;
                end
                NONSEQ: begin
                    // SEQ for burst, IDLE for end, else stay
                    case (HTRANS)
                        SEQ: state <= SEQ;
                        IDLE: state <= IDLE;
                        default: state <= NONSEQ;
                    endcase
                end
                SEQ: begin
                    // Back to IDLE if transfer ends
                    if (HTRANS == IDLE)
                        state <= IDLE;
                    else
                        state <= SEQ;
                end
                default: state <= IDLE;
            endcase

            // Write operation to TxFIFO
            if (wr_en) begin
                if (!TxFIFO_full) begin
                    // Pack write: {write_flag, address, aligned data}
                    DATA_to_TxFIFO <= {1'b1,HADDR, align_data(HWDATA, HSIZE)};
                    TxFIFO_wr_en <= 1'b1;
                end else begin
                    // Set error if FIFO full
                    error <= 1'b1;
                end
            end

            // Read operation: request from RxFIFO and log address to TxFIFO
            if (rd_en) begin
                if (!TxFIFO_full && !RxFIFO_empty) begin
                    // Pack read: {read_flag, address, zero data}
                    DATA_to_TxFIFO <= {1'b0, HADDR, 32'b0};
                    TxFIFO_wr_en <= 1'b1;
                    RxFIFO_rd_en <= 1'b1;
                    fifo_rd_en_d <= 1'b1; // Set delayed fetch flag
                end else begin
                    // Set error if FIFO full or empty
                    error <= 1'b1;
                end
            end

            // Fetch read data from RxFIFO on delayed enable
            if (fifo_rd_en_d) begin
                fifo_data_fetch <= DATA_from_RxFIFO;
                fifo_rd_en_d <= 1'b0;
            end
        end
    end

    // Output read data to AHB bus
    assign HRDATA = fifo_data_fetch;

endmodule