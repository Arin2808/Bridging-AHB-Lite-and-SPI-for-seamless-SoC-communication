`timescale 1ns / 1ps
/*
 * Asynchronous FIFO Controller Module
 * Uses gray code pointer conversion and two-flop synchronizers for safe crossing
 * Instantiates fifo_mem, bin2gray, gray2bin, and sync_flop modules.
 */

module async_fifo_ctrl #(
    parameter DATA_WIDTH = 41,
    parameter ADDR_WIDTH = 4
)(
    input  wire                   wr_clk,
    input  wire                   wr_rst_n,
    input  wire                   wr_en,
    input  wire [DATA_WIDTH-1:0]  wr_data,

    input  wire                   rd_clk,
    input  wire                   rd_rst_n,
    input  wire                   rd_en,

    output wire                   full,
    output wire                   empty,
    output wire [DATA_WIDTH-1:0]  rd_data
);

    localparam PTR_WIDTH = ADDR_WIDTH + 1;

    // Write pointer logic
    reg [PTR_WIDTH-1:0] wr_ptr_bin = 0;
    wire [PTR_WIDTH-1:0] wr_ptr_gray;
    wire [PTR_WIDTH-1:0] rd_ptr_gray_sync; // synchronized read pointer in write clock domain
    wire  [PTR_WIDTH-1:0] rd_ptr_bin_sync;

    // Read pointer logic
    reg [PTR_WIDTH-1:0] rd_ptr_bin = 0;
    wire [PTR_WIDTH-1:0] rd_ptr_gray;
    wire [PTR_WIDTH-1:0] wr_ptr_gray_sync; // synchronized write pointer in read clock domain
    wire  [PTR_WIDTH-1:0] wr_ptr_bin_sync;

    // Instantiate bin2gray converters
    bin2gray #(.WIDTH(PTR_WIDTH)) wr_bin2gray (
        .bin(wr_ptr_bin),
        .gray(wr_ptr_gray)
    );

    bin2gray #(.WIDTH(PTR_WIDTH)) rd_bin2gray (
        .bin(rd_ptr_bin),
        .gray(rd_ptr_gray)
    );

    // Synchronize the opposite pointers with two flop synchronizers
    sync_flop #(.WIDTH(PTR_WIDTH)) rd_ptr_sync_inst (
        .clk(wr_clk),
        .rst_n(wr_rst_n),
        .async_in(rd_ptr_gray),
        .sync_out(rd_ptr_gray_sync)
    );

    sync_flop #(.WIDTH(PTR_WIDTH)) wr_ptr_sync_inst (
        .clk(rd_clk),
        .rst_n(rd_rst_n),
        .async_in(wr_ptr_gray),
        .sync_out(wr_ptr_gray_sync)
    );

    // Gray to binary conversion of synchronized pointers
    gray2bin #(.WIDTH(PTR_WIDTH)) rd_gray2bin (
        .gray(rd_ptr_gray_sync),
        .bin(rd_ptr_bin_sync)
    );

    gray2bin #(.WIDTH(PTR_WIDTH)) wr_gray2bin (
        .gray(wr_ptr_gray_sync),
        .bin(wr_ptr_bin_sync)
    );

    // Write pointer logic
    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wr_ptr_bin <= 0;
        end else if (wr_en && !full) begin
            wr_ptr_bin <= wr_ptr_bin + 1'b1;
        end
    end

    // Read pointer logic
    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_ptr_bin <= 0;
        end else if (rd_en && !empty) begin
            rd_ptr_bin <= rd_ptr_bin + 1'b1;
        end
    end

    // Full and empty flag generation
    assign full = ((wr_ptr_gray[PTR_WIDTH-1] != rd_ptr_gray_sync[PTR_WIDTH-1]) &&
                   (wr_ptr_gray[PTR_WIDTH-2] != rd_ptr_gray_sync[PTR_WIDTH-2]) &&
                   (wr_ptr_gray[PTR_WIDTH-3:0] == rd_ptr_gray_sync[PTR_WIDTH-3:0]));

    assign empty = (rd_ptr_gray == wr_ptr_gray_sync);

    // FIFO memory instance
    fifo_mem #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) fifo_mem_inst (
        .wr_clk(wr_clk),
        .wr_en(wr_en && !full),
        .wr_addr(wr_ptr_bin[ADDR_WIDTH-1:0]),
        .wr_data(wr_data),

        .rd_clk(rd_clk),
        .rd_en(rd_en && !empty),
        .rd_addr(rd_ptr_bin[ADDR_WIDTH-1:0]),
        .rd_data(rd_data)
    );

endmodule