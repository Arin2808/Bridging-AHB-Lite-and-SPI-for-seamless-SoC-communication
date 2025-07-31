`timescale 1ns / 1ps

module ahb_to_spi_bridge (
    // AHB master interface
    input  wire        HCLK,          // AHB clock
    input  wire        rst,           // Active-high reset
    input  wire [7:0]  addr,          // AHB address input
    input  wire [2:0]  size,          // AHB transfer size
    input  wire        write,         // AHB write/read control
    input  wire [2:0]  burst,         // AHB burst type
    input  wire        start,         // Start signal for AHB master
    output wire [31:0] HRDATA,        // AHB read data
    output wire        HREADY,        // AHB ready signal
    output wire        HRESP,         // AHB response signal
    output wire [7:0]  HADDR,         // AHB address
    output wire [1:0]  HTRANS,        // AHB transfer type
    output wire        HWRITE,        // AHB write/read
    output wire [2:0]  HSIZE,         // AHB size
    output wire [2:0]  HBURST,        // AHB burst
    output wire [31:0] HWDATA,        // AHB write data
    output wire        done,          // AHB transaction done
    // SPI master interface (to external SPI slaves)
    input  wire        clk_spi,       // SPI clock
    output wire        spi_clk,       // SPI clock output
    output wire        spi_mosi,      // SPI Master Out Slave In
    input  wire        spi_miso,      // SPI Master In Slave Out
    output wire        spi_cs0,       // SPI chip select 0
    output wire        spi_cs1        // SPI chip select 1
);

    // Internal FIFO signals
    wire [40:0] tx_fifo_data_out;
    wire        tx_fifo_full;
    wire        tx_fifo_empty;
    wire        tx_fifo_read_en;
    wire [40:0] tx_fifo_data_in;
    wire        tx_fifo_write_en;
    wire [31:0] rx_fifo_data_out;
    wire        rx_fifo_full;
    wire        rx_fifo_empty;
    wire        rx_fifo_read_en;
    wire [31:0] rx_fifo_data_in;
    wire        rx_fifo_write_en;

    // AHB master
    AHB_master ahb_master (
        .HCLK(HCLK),
        .rst(rst),
        .HRDATA(HRDATA),
        .HREADY(HREADY),
        .HRESP(HRESP),
        .addr(addr),
        .size(size),
        .write(write),
        .burst(burst),
        .start(start),
        .HADDR(HADDR),
        .HTRANS(HTRANS),
        .HWRITE(HWRITE),
        .HSIZE(HSIZE),
        .HBURST(HBURST),
        .HWDATA(HWDATA),
        .done(done)
    );

    // AHB slave
    AHB_slave ahb_slave (
        .rst(rst),
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

    // TX FIFO (AHB to SPI)
    async_fifo_tx tx_fifo (
        .wr_clk(HCLK),
        .wr_rst(rst),              // Write domain reset (active-high)
        .wr_en(tx_fifo_write_en),
        .wr_data(tx_fifo_data_in),
        .rd_clk(clk_spi),
        .rd_rst(rst),              // Read domain reset (active-high)
        .rd_en(tx_fifo_read_en),
        .rd_data(tx_fifo_data_out),
        .full(tx_fifo_full),
        .empty(tx_fifo_empty)
    );

    // RX FIFO (SPI to AHB)
    async_fifo_rx rx_fifo (
        .wr_clk(clk_spi),
        .wr_rst(rst),              // Write domain reset (active-high)
        .wr_en(rx_fifo_write_en),
        .wr_data(rx_fifo_data_in),
        .rd_clk(HCLK),
        .rd_rst(rst),              // Read domain reset (active-high)
        .rd_en(rx_fifo_read_en),
        .rd_data(rx_fifo_data_out),
        .full(rx_fifo_full),
        .empty(rx_fifo_empty)
    );

    // SPI master
    spi_master spi_master (
        .clk(clk_spi),
        .rst(rst),
        .spi_clk(spi_clk),
        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso),
        .spi_cs0(spi_cs0),
        .spi_cs1(spi_cs1),
        .Tx_FIFO_data_in(tx_fifo_data_out),
        .Tx_FIFO_read_en(tx_fifo_read_en),
        .Tx_FIFO_empty(tx_fifo_empty),
        .Rx_FIFO_data_out(rx_fifo_data_in),
        .Rx_FIFO_write_en(rx_fifo_write_en),
        .Rx_FIFO_full(rx_fifo_full)
    );

endmodule