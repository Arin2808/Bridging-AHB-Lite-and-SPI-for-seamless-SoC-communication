`timescale 1ns / 1ps

module AHB_slave (
    input         rst,            // Active-high reset
    input         HCLK,
    input  [7:0]  HADDR,
    input  [1:0]  HTRANS,
    input         HWRITE,
    input  [2:0]  HSIZE,
    input  [2:0]  HBURST,
    input  [31:0] HWDATA,
    output reg [40:0] DATA_to_TxFIFO,
    output reg        TxFIFO_wr_en,
    input             TxFIFO_full,
    input      [31:0] DATA_from_RxFIFO,
    output reg        RxFIFO_rd_en,
    input             RxFIFO_empty,
    output wire [31:0] HRDATA,
    output wire        HRESP,
    output wire        HREADY
);

    localparam IDLE = 2'b00, NONSEQ = 2'b10, SEQ = 2'b11;

    reg [1:0]  state;
    reg [31:0] fifo_data_fetch;
    reg        fifo_rd_en_d;
    reg        error;

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

    always @(posedge HCLK or posedge rst) begin
        if (rst) begin
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