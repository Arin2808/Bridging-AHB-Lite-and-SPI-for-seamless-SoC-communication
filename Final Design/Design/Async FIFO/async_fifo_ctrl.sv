// -----------------------------------------------------------------------------
// async_fifo_ctrl: Parameterized Asynchronous FIFO Controller
// -----------------------------------------------------------------------------
// This module implements the core logic for an asynchronous FIFO, supporting
// safe data transfer between two independent clock domains (write and read).
// It uses Gray code pointers and synchronizers to avoid metastability issues.
// The FIFO is parameterized for data width and address width, allowing flexible
// sizing. Full and empty flags are generated for flow control.
// -----------------------------------------------------------------------------

`timescale 1ns / 1ps
`include "bin2gray.sv"
`include "gray2bin.sv"
`include "sync_flop.sv"
`include "fifo_mem.sv"

module async_fifo_ctrl #(
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

    localparam PTR_WIDTH = ADDR_WIDTH + 1; // Pointer width for addressing and full/empty detection

    // Write pointer (binary and Gray code)
    reg [PTR_WIDTH-1:0] wr_ptr_bin = 0;           // Binary write pointer
    wire [PTR_WIDTH-1:0] wr_ptr_gray;             // Gray-coded write pointer
    wire [PTR_WIDTH-1:0] rd_ptr_gray_sync;        // Synchronized read pointer (Gray) into write domain
    wire [PTR_WIDTH-1:0] rd_ptr_bin_sync;         // Synchronized read pointer (binary) into write domain

    // Read pointer (binary and Gray code)
    reg [PTR_WIDTH-1:0] rd_ptr_bin = 0;           // Binary read pointer
    wire [PTR_WIDTH-1:0] rd_ptr_gray;             // Gray-coded read pointer
    wire [PTR_WIDTH-1:0] wr_ptr_gray_sync;        // Synchronized write pointer (Gray) into read domain
    wire [PTR_WIDTH-1:0] wr_ptr_bin_sync;         // Synchronized write pointer (binary) into read domain

    // Binary to Gray code conversion for write pointer
    bin2gray #(.WIDTH(PTR_WIDTH)) wr_bin2gray (
        .bin(wr_ptr_bin),
        .gray(wr_ptr_gray)
    );

    // Binary to Gray code conversion for read pointer
    bin2gray #(.WIDTH(PTR_WIDTH)) rd_bin2gray (
        .bin(rd_ptr_bin),
        .gray(rd_ptr_gray)
    );

    // Synchronize read pointer (Gray) into write clock domain
    sync_flop #(.WIDTH(PTR_WIDTH)) rd_ptr_sync_inst (
        .clk(wr_clk),
        .rst(wr_rst),
        .async_in(rd_ptr_gray),
        .sync_out(rd_ptr_gray_sync)
    );

    // Synchronize write pointer (Gray) into read clock domain
    sync_flop #(.WIDTH(PTR_WIDTH)) wr_ptr_sync_inst (
        .clk(rd_clk),
        .rst(rd_rst),
        .async_in(wr_ptr_gray),
        .sync_out(wr_ptr_gray_sync)
    );

    // Convert synchronized Gray pointers back to binary
    gray2bin #(.WIDTH(PTR_WIDTH)) rd_gray2bin (
        .gray(rd_ptr_gray_sync),
        .bin(rd_ptr_bin_sync)
    );

    gray2bin #(.WIDTH(PTR_WIDTH)) wr_gray2bin (
        .gray(wr_ptr_gray_sync),
        .bin(wr_ptr_bin_sync)
    );

    // Write pointer increment logic
    always @(posedge wr_clk or posedge wr_rst) begin
        if (wr_rst) begin
            wr_ptr_bin <= 0; // Reset write pointer
        end else if (wr_en && !full) begin
            wr_ptr_bin <= wr_ptr_bin + 1'b1; // Increment on write
        end
    end

    // Read pointer increment logic
    always @(posedge rd_clk or posedge rd_rst) begin
        if (rd_rst) begin
            rd_ptr_bin <= 0; // Reset read pointer
        end else if (rd_en && !empty) begin
            rd_ptr_bin <= rd_ptr_bin + 1'b1; // Increment on read
        end
    end

    // Full flag logic: FIFO is full when write pointer is one cycle behind read pointer (in Gray code)
    assign full = ((wr_ptr_gray[PTR_WIDTH-1] != rd_ptr_gray_sync[PTR_WIDTH-1]) &&
                   (wr_ptr_gray[PTR_WIDTH-2] != rd_ptr_gray_sync[PTR_WIDTH-2]) &&
                   (wr_ptr_gray[PTR_WIDTH-3:0] == rd_ptr_gray_sync[PTR_WIDTH-3:0]));

    // Empty flag logic: FIFO is empty when read and write pointers are equal (in Gray code)
    assign empty = (rd_ptr_gray == wr_ptr_gray_sync);

    // FIFO memory instantiation
    fifo_mem #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) fifo_mem_inst (
        .wr_clk(wr_clk),                          // Write clock
        .wr_en(wr_en && !full),                   // Write enable (only if not full)
        .wr_addr(wr_ptr_bin[ADDR_WIDTH-1:0]),     // Write address (lower bits of write pointer)
        .wr_data(wr_data),                        // Data to write
        .rd_clk(rd_clk),                          // Read clock
        .rd_en(rd_en && !empty),                  // Read enable (only if not empty)
        .rd_addr(rd_ptr_bin[ADDR_WIDTH-1:0]),     // Read address (lower bits of read pointer)
        .rd_data(rd_data)                         // Data output
    );

endmodule