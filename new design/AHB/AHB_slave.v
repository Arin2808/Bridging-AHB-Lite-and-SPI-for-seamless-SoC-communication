`timescale 1ns / 1ps

module AHB_slave (
    input         HRESET,         // Active-high AHB reset signal, used to initialize or clear all internal states and outputs
    input         HCLK,           // AHB clock signal, synchronizes all operations
    input  [7:0]  HADDR,          // AHB address bus, specifies the target address for read/write
    input  [1:0]  HTRANS,         // AHB transfer type, controls state transitions (IDLE, NONSEQ, SEQ)
    input         HWRITE,         // AHB write control, high for write, low for read
    input  [2:0]  HSIZE,          // AHB transfer size, determines byte/half-word/word access
    input  [2:0]  HBURST,         // AHB burst type, not used in this design but reserved for future burst support
    input  [31:0] HWDATA,         // AHB write data bus, carries data to be written
    output reg [40:0] DATA_to_TxFIFO, // Data sent to transmit FIFO, includes control and aligned data
    output reg        TxFIFO_wr_en,   // Write enable for transmit FIFO, triggers data push
    input             TxFIFO_full,    // Status from transmit FIFO, prevents overflow
    input      [31:0] DATA_from_RxFIFO, // Data received from receive FIFO, used for read operations
    output reg        RxFIFO_rd_en,   // Read enable for receive FIFO, triggers data fetch
    input             RxFIFO_empty,   // Status from receive FIFO, prevents underflow
    output wire [31:0] HRDATA,        // AHB read data bus, provides data to AHB master
    output wire        HRESP,         // AHB response signal, indicates error status
    output wire        HREADY         // AHB ready signal, indicates slave is ready for next transfer
);

    localparam IDLE = 2'b00, NONSEQ = 2'b10, SEQ = 2'b11;

    reg [1:0]  state;              // Tracks current state of AHB transaction (IDLE, NONSEQ, SEQ)
    reg [31:0] fifo_data_fetch;    // Holds data fetched from RxFIFO for AHB read response
    reg        fifo_rd_en_d;       // Delayed read enable for RxFIFO, ensures proper timing for data fetch
    reg        error;              // Indicates error condition (FIFO full/empty during access)

    // Data alignment function
    function [31:0] align_data;
        input [31:0] HWDATA;
        input [2:0]  HSIZE;
        begin
            case (HSIZE)
                3'b000: align_data = {24'b0, HWDATA[7:0]};  // Byte
                3'b001: align_data = {16'b0, HWDATA[15:0]}; // Half-word
                3'b010: align_data = HWDATA;                // Word
                default: align_data = 32'h0;
            endcase
        end
    endfunction

    assign HREADY = !(TxFIFO_full && HWRITE) && !(RxFIFO_empty && !HWRITE);
    assign HRESP = error;

    wire wr_en = (HWRITE && HREADY && (state == NONSEQ || state == SEQ));
    wire rd_en = (!HWRITE && HREADY && (state == NONSEQ || state == SEQ));

    always @(posedge HCLK or posedge HRESET) begin
        if (HRESET) begin
            state <= IDLE;
            DATA_to_TxFIFO <= 41'h0;
            TxFIFO_wr_en <= 1'b0;
            RxFIFO_rd_en <= 1'b0;
            fifo_data_fetch <= 32'h0;
            fifo_rd_en_d <= 1'b0;
            error <= 1'b0;
        end else begin
            TxFIFO_wr_en <= 1'b0;
            RxFIFO_rd_en <= 1'b0;
            error <= 1'b0;

            // State transitions
            case (state)
                IDLE: begin
                    if (HTRANS == NONSEQ && HREADY)
                        state <= NONSEQ;
                    else
                        state <= IDLE;
                end
                NONSEQ: begin
                    case (HTRANS)
                        SEQ: state <= SEQ;
                        IDLE: state <= IDLE;
                        default: state <= NONSEQ;
                    endcase
                end
                SEQ: begin
                    if (HTRANS == IDLE)
                        state <= IDLE;
                    else
                        state <= SEQ;
                end
                default: state <= IDLE;
            endcase

            // Write operation
            if (wr_en) begin
                if (!TxFIFO_full) begin
                    DATA_to_TxFIFO <= {1'b1, HADDR[0], HADDR[7:1], align_data(HWDATA, HSIZE)};
                    TxFIFO_wr_en <= 1'b1;
                end else begin
                    error <= 1'b1;
                end
            end

            // Read operation
            if (rd_en) begin
                if (!TxFIFO_full && !RxFIFO_empty) begin
                    DATA_to_TxFIFO <= {1'b0, HADDR[0], HADDR[7:1], 32'b0};
                    TxFIFO_wr_en <= 1'b1;
                    RxFIFO_rd_en <= 1'b1;
                    fifo_rd_en_d <= 1'b1;
                end else begin
                    error <= 1'b1;
                end
            end

            // Fetch read data
            if (fifo_rd_en_d) begin
                fifo_data_fetch <= DATA_from_RxFIFO;
                fifo_rd_en_d <= 1'b0;
            end
        end
    end

    assign HRDATA = fifo_data_fetch;

endmodule