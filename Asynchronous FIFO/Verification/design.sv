// Code your design here
`timescale 1ns / 1ps
`include "async_fifo_ctrl.v"
/*
 * Top-level module instantiating the asynchronous FIFO controller
 * Example usage: instantiate async_fifo_ctrl with parameters
 */

module async_fifo_top #(
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

    // Instantiate the asynchronous FIFO controller
    async_fifo_ctrl #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_async_fifo_ctrl (
        .wr_clk(wr_clk),
        .wr_rst_n(wr_rst_n),
        .wr_en(wr_en),
        .wr_data(wr_data),

        .rd_clk(rd_clk),
        .rd_rst_n(rd_rst_n),
        .rd_en(rd_en),

        .full(full),
        .empty(empty),
        .rd_data(rd_data)
    );

endmodule

// Interface for asynchronous FIFO

interface fifo_if (
    input logic wr_clk,
    input logic rd_clk
);
    logic wr_rst_n;
    logic wr_en;
    logic [40:0] wr_data;
    logic rd_rst_n;
    logic rd_en;
    logic [40:0] rd_data;
    logic full;
    logic empty;

    clocking wr_cb @(posedge wr_clk);
        input full;
        output wr_en, wr_data;
    endclocking

    clocking rd_cb @(posedge rd_clk);
        input rd_data, empty;
        output rd_en;
    endclocking

    modport dut (
        input wr_clk, wr_rst_n, wr_en, wr_data,
        input rd_clk, rd_rst_n, rd_en,
        output full, empty, rd_data
    );
endinterface

