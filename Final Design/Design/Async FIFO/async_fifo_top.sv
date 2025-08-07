// -----------------------------------------------------------------------------
// async_fifo_top: Parameterized Asynchronous FIFO Top Module
// -----------------------------------------------------------------------------
// This module serves as a wrapper for the asynchronous FIFO controller (async_fifo_ctrl).
// It is parameterized for data width and address width, allowing flexible FIFO sizing.
// The module safely transfers data between two asynchronous clock domains (write and read).
// It exposes standard FIFO signals for flow control and data transfer.
// ----------------------------------------------------------------------------

`timescale 1ns / 1ps
`include "async_fifo_ctrl.sv"

module async_fifo_top #(
    parameter DATA_WIDTH = 41,    // Width of the FIFO data
    parameter ADDR_WIDTH = 4      // Address width (FIFO depth = 2^ADDR_WIDTH)
)(
    input  wire                   wr_clk,     // Write clock domain
    input  wire                   wr_rst,     // Write domain reset (active-high)
    input  wire                   wr_en,      // Write enable
    input  wire [DATA_WIDTH-1:0]  wr_data,    // Data input for write
    input  wire                   rd_clk,     // Read clock domain
    input  wire                   rd_rst,     // Read domain reset (active-high)
    input  wire                   rd_en,      // Read enable
    output wire                   full,       // FIFO full flag (cannot write)
    output wire                   empty,      // FIFO empty flag (cannot read)
    output wire [DATA_WIDTH-1:0]  rd_data     // Data output for read
);

    // Instantiates the asynchronous FIFO controller with parameterized widths.
    async_fifo_ctrl #(
        .DATA_WIDTH(DATA_WIDTH),  // Pass data width parameter
        .ADDR_WIDTH(ADDR_WIDTH)   // Pass address width parameter
    ) u_async_fifo_ctrl (
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