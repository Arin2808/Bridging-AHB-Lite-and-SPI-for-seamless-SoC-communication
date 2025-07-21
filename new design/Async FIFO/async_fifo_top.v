`timescale 1ns / 1ps
/*
 * Top-level module instantiating the asynchronous FIFO controller
 * Example usage: instantiate async_fifo_ctrl with parameters
 */

module async_fifo_top #(
    parameter DATA_WIDTH = 41,
    parameter ADDR_WIDTH = 4
)(
    input  wire                   wr_clk,
    input  wire                   wr_rst,
    input  wire                   wr_en,
    input  wire [DATA_WIDTH-1:0]  wr_data,

    input  wire                   rd_clk,
    input  wire                   rd_rst,
    input  wire                   rd_en,

    output wire                   full,
    output wire                   empty,
    output wire [DATA_WIDTH-1:0]  rd_data
);

    // Instantiate the asynchronous FIFO controller
    async_fifo_ctrl #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_async_fifo_ctrl (
        .wr_clk(wr_clk),
        .wr_rst(wr_rst),       // Pass write domain reset
        .wr_en(wr_en),
        .wr_data(wr_data),

        .rd_clk(rd_clk),
        .rd_rst(rd_rst),       // Pass read domain reset
        .rd_en(rd_en),

        .full(full),
        .empty(empty),
        .rd_data(rd_data)
    );

endmodule