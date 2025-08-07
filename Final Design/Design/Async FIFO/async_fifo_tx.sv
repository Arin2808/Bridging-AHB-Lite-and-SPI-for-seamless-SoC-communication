// -----------------------------------------------------------------------------
// async_fifo_tx: Asynchronous FIFO Wrapper for Transmit Path
// -----------------------------------------------------------------------------
// This module wraps an asynchronous FIFO (async_fifo_top) for the transmit (Tx)
// path. It allows data to be written from the AHB clock domain and read from the
// SPI clock domain, safely transferring 41-bit data across clock domains. The
// module exposes FIFO full and empty flags for flow control.
// -----------------------------------------------------------------------------

`timescale 1ns / 1ps
`include "async_fifo_top.sv"

module async_fifo_tx (
    input  wire                   wr_clk,      // Write clock (AHB domain)
    input  wire                   wr_rst,      // Write domain reset (active-high)
    input  wire                   wr_en,       // Write enable signal
    input  wire [40:0]            wr_data,     // 41-bit input data to FIFO
    input  wire                   rd_clk,      // Read clock (SPI domain)
    input  wire                   rd_rst,      // Read domain reset (active-high)
    input  wire                   rd_en,       // Read enable signal
    output wire [40:0]            rd_data,     // 41-bit output data from FIFO
    output wire                   full,        // FIFO full flag (cannot write)
    output wire                   empty        // FIFO empty flag (cannot read)
);

    // Instantiates the asynchronous FIFO with parameterized data and address width.
    async_fifo_top #(
        .DATA_WIDTH(41),          // Data width set to 41 bits
        .ADDR_WIDTH(4)            // Address width (FIFO depth = 2^4 = 16)
    ) u_async_fifo_tx (
        .wr_clk(wr_clk),          // Write clock input
        .wr_rst(wr_rst),          // Write reset input
        .wr_en(wr_en),            // Write enable input
        .wr_data(wr_data),        // Data input for write
        .rd_clk(rd_clk),          // Read clock input
        .rd_rst(rd_rst),          // Read reset input
        .rd_en(rd_en),            // Read enable input
        .full(full),              // FIFO full output
        .empty(empty),            // FIFO empty output
        .rd_data(rd_data)         // Data output for read
    );

endmodule