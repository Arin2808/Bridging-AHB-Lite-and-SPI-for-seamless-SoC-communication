`timescale 1ns / 1ps

module async_fifo_tx (
    input  wire                   wr_clk,      // AHB clock (HCLK)
    input  wire                   wr_rst,      // Write domain reset (active-high)
    input  wire                   wr_en,       // Write enable
    input  wire [40:0]            wr_data,     // 41-bit input data
    input  wire                   rd_clk,      // SPI clock
    input  wire                   rd_rst,      // Read domain reset (active-high)
    input  wire                   rd_en,       // Read enable
    output wire [40:0]            rd_data,     // 41-bit output data
    output wire                   full,        // FIFO full flag
    output wire                   empty        // FIFO empty flag
);

    async_fifo_top #(
        .DATA_WIDTH(41),
        .ADDR_WIDTH(4)
    ) u_async_fifo_tx (
        .wr_clk(wr_clk),
        .wr_rst(wr_rst),     
        .wr_en(wr_en),
        .wr_data(wr_data),
        .rd_clk(rd_clk),
        .rd_rst(rd_rst),     
        .rd_en(rd_en),
        .full(full),
        .empty(empty),
        .rd_data(rd_data)
    );

endmodule