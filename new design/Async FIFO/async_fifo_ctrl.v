`timescale 1ns / 1ps

module async_fifo_ctrl #(
    parameter DATA_WIDTH = 41,
    parameter ADDR_WIDTH = 4
)(
    input  wire                   wr_clk,      // Write clock domain
    input  wire                   wr_rst,      // Write domain reset (active-high)
    input  wire                   wr_en,       // Write enable signal
    input  wire [DATA_WIDTH-1:0]  wr_data,     // Data to be written to FIFO
    input  wire                   rd_clk,      // Read clock domain
    input  wire                   rd_rst,      // Read domain reset (active-high)
    input  wire                   rd_en,       // Read enable signal
    output wire                   full,        // FIFO full flag
    output wire                   empty,       // FIFO empty flag
    output wire [DATA_WIDTH-1:0]  rd_data      // Data read from FIFO
);

    localparam PTR_WIDTH = ADDR_WIDTH + 1;     // Pointer width for addressing FIFO

    // Write and read pointers (binary and gray-coded)
    reg [PTR_WIDTH-1:0] wr_ptr_bin = 0;        // Write pointer (binary)
    wire [PTR_WIDTH-1:0] wr_ptr_gray;          // Write pointer (gray code)
    wire [PTR_WIDTH-1:0] rd_ptr_gray_sync;     // Synchronized read pointer (gray code) in write domain
    wire [PTR_WIDTH-1:0] rd_ptr_bin_sync;      // Synchronized read pointer (binary) in write domain

    reg [PTR_WIDTH-1:0] rd_ptr_bin = 0;        // Read pointer (binary)
    wire [PTR_WIDTH-1:0] rd_ptr_gray;          // Read pointer (gray code)
    wire [PTR_WIDTH-1:0] wr_ptr_gray_sync;     // Synchronized write pointer (gray code) in read domain
    wire [PTR_WIDTH-1:0] wr_ptr_bin_sync;      // Synchronized write pointer (binary) in read domain

    // Convert binary pointers to gray code for safe clock domain crossing
    bin2gray #(.WIDTH(PTR_WIDTH)) wr_bin2gray (
        .bin(wr_ptr_bin),
        .gray(wr_ptr_gray)
    );

    bin2gray #(.WIDTH(PTR_WIDTH)) rd_bin2gray (
        .bin(rd_ptr_bin),
        .gray(rd_ptr_gray)
    );

    // Synchronize read pointer into write clock domain
    sync_flop #(.WIDTH(PTR_WIDTH)) rd_ptr_sync_inst (
        .clk(wr_clk),
        .rst(wr_rst),         // Use write domain reset
        .async_in(rd_ptr_gray),
        .sync_out(rd_ptr_gray_sync)
    );

    // Synchronize write pointer into read clock domain
    sync_flop #(.WIDTH(PTR_WIDTH)) wr_ptr_sync_inst (
        .clk(rd_clk),
        .rst(rd_rst),         // Use read domain reset
        .async_in(wr_ptr_gray),
        .sync_out(wr_ptr_gray_sync)
    );

    // Convert synchronized gray-coded pointers back to binary
    gray2bin #(.WIDTH(PTR_WIDTH)) rd_gray2bin (
        .gray(rd_ptr_gray_sync),
        .bin(rd_ptr_bin_sync)
    );

    gray2bin #(.WIDTH(PTR_WIDTH)) wr_gray2bin (
        .gray(wr_ptr_gray_sync),
        .bin(wr_ptr_bin_sync)
    );

    // Write pointer update logic (write clock domain)
    always @(posedge wr_clk or posedge wr_rst) begin
        if (wr_rst) begin
            wr_ptr_bin <= 0;                // Reset write pointer
        end else if (wr_en && !full) begin
            wr_ptr_bin <= wr_ptr_bin + 1'b1;// Increment write pointer on write
        end
    end

    // Read pointer update logic (read clock domain)
    always @(posedge rd_clk or posedge rd_rst) begin
        if (rd_rst) begin
            rd_ptr_bin <= 0;                // Reset read pointer
        end else if (rd_en && !empty) begin
            rd_ptr_bin <= rd_ptr_bin + 1'b1;// Increment read pointer on read
        end
    end

    // FIFO full detection (write domain)
    assign full = ((wr_ptr_gray[PTR_WIDTH-1] != rd_ptr_gray_sync[PTR_WIDTH-1]) &&
                   (wr_ptr_gray[PTR_WIDTH-2] != rd_ptr_gray_sync[PTR_WIDTH-2]) &&
                   (wr_ptr_gray[PTR_WIDTH-3:0] == rd_ptr_gray_sync[PTR_WIDTH-3:0]));

    // FIFO empty detection (read domain)
    assign empty = (rd_ptr_gray == wr_ptr_gray_sync);

    // FIFO memory instantiation
    fifo_mem #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) fifo_mem_inst (
        .wr_clk(wr_clk),
        .wr_en(wr_en && !full),                         // Write only if not full
        .wr_addr(wr_ptr_bin[ADDR_WIDTH-1:0]),           // Write address
        .wr_data(wr_data),                              // Write data
        .rd_clk(rd_clk),
        .rd_en(rd_en && !empty),                        // Read only if not empty
        .rd_addr(rd_ptr_bin[ADDR_WIDTH-1:0]),           // Read address
        .rd_data(rd_data)                              // Read data
    );

endmodule