// -----------------------------------------------------------------------------
// ahb_to_spi_bridge: Top-Level Bridge Between AHB and SPI
// -----------------------------------------------------------------------------
// This module connects the AHB bus to the SPI master using asynchronous FIFOs.
// It instantiates the AHB slave, transmit FIFO (AHB to SPI), receive FIFO (SPI to AHB),
// and SPI master. Data is safely transferred between clock domains using FIFOs.
// All necessary signals are routed between submodules for protocol conversion.
// -----------------------------------------------------------------------------

`timescale 1ns / 1ps
`include "AHB_slave.sv"
`include "async_fifo_tx.sv"
`include "async_fifo_rx.sv"
`include "spi_master.sv"

module ahb_to_spi_bridge (
    // AHB slave interface
    input         HCLK,          // AHB clock
    input         HRESET,        // Active-high reset
    input  [7:0]  HADDR,         // AHB address input
    input  [1:0]  HTRANS,        // AHB transfer type
    input         HWRITE,        // AHB write/read control
    input  [2:0]  HSIZE,         // AHB transfer size
    input  [2:0]  HBURST,        // AHB burst type
    input  [31:0] HWDATA,        // AHB write data
    output [31:0] HRDATA,        // AHB read data
    output        HREADY,        // AHB ready signal
    output        HRESP,         // AHB response signal
    // SPI master interface
    input         SCLK,          // SPI clock
    input         SRESET,        // SPI reset
    output        spi_clk,       // SPI clock output
    output        spi_mosi,      // SPI Master Out Slave In
    input         spi_miso,      // SPI Master In Slave Out
    output        spi_cs         // SPI chip select
);

    // Internal FIFO signals for data and control between modules
    wire [40:0] tx_fifo_data_out;   // Data output from TX FIFO to SPI master
    wire        tx_fifo_full;       // TX FIFO full flag
    wire        tx_fifo_empty;      // TX FIFO empty flag
    wire        tx_fifo_read_en;    // Read enable for TX FIFO (SPI master)
    wire [40:0] tx_fifo_data_in;    // Data input to TX FIFO from AHB slave
    wire        tx_fifo_write_en;   // Write enable for TX FIFO (AHB slave)
    wire [31:0] rx_fifo_data_out;   // Data output from RX FIFO to AHB slave
    wire        rx_fifo_full;       // RX FIFO full flag
    wire        rx_fifo_empty;      // RX FIFO empty flag
    wire        rx_fifo_read_en;    // Read enable for RX FIFO (AHB slave)
    wire [31:0] rx_fifo_data_in;    // Data input to RX FIFO from SPI master
    wire        rx_fifo_write_en;   // Write enable for RX FIFO (SPI master)

    // Instantiate AHB slave: handles AHB protocol and interfaces with FIFOs
    AHB_slave ahb_slave (
        .HRESET(HRESET),
        .HCLK(HCLK),
        .HADDR(HADDR),
        .HTRANS(HTRANS),
        .HWRITE(HWRITE),
        .HSIZE(HSIZE),
        .HBURST(HBURST),
        .HWDATA(HWDATA),
        .DATA_to_TxFIFO(tx_fifo_data_in),
        .TxFIFO_wr_en(tx_fifo_write_en),
        .TxFIFO_full(tx_fifo_full),
        .DATA_from_RxFIFO(rx_fifo_data_out),
        .RxFIFO_rd_en(rx_fifo_read_en),
        .RxFIFO_empty(rx_fifo_empty),
        .HRDATA(HRDATA),
        .HRESP(HRESP),
        .HREADY(HREADY)
    );

    // Instantiate TX FIFO: bridges AHB (write side) to SPI (read side)
    async_fifo_tx tx_fifo (
        .wr_clk(HCLK),
        .wr_rst(HRESET),
        .wr_en(tx_fifo_write_en),
        .wr_data(tx_fifo_data_in),
        .rd_clk(SCLK),
        .rd_rst(SRESET),
        .rd_en(tx_fifo_read_en),
        .rd_data(tx_fifo_data_out),
        .full(tx_fifo_full),
        .empty(tx_fifo_empty)
    );

    // Instantiate RX FIFO: bridges SPI (write side) to AHB (read side)
    async_fifo_rx rx_fifo (
        .wr_clk(SCLK),
        .wr_rst(SRESET),
        .wr_en(rx_fifo_write_en),
        .wr_data(rx_fifo_data_in),
        .rd_clk(HCLK),
        .rd_rst(HRESET),
        .rd_en(rx_fifo_read_en),
        .rd_data(rx_fifo_data_out),
        .full(rx_fifo_full),
        .empty(rx_fifo_empty)
    );

    // Instantiate SPI master: handles SPI protocol and interfaces with FIFOs
    spi_master spi_master (
        .SCLK(SCLK),
        .SRESET(SRESET),
        .spi_clk(spi_clk),
        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso),
        .spi_cs(spi_cs),
        .Tx_FIFO_data_in(tx_fifo_data_out),
        .Tx_FIFO_read_en(tx_fifo_read_en),
        .Tx_FIFO_empty(tx_fifo_empty),
        .Rx_FIFO_data_out(rx_fifo_data_in),
        .Rx_FIFO_write_en(rx_fifo_write_en),
        .Rx_FIFO_full(rx_fifo_full)
    );

endmodule