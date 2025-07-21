`timescale 1ns / 1ps

module top_level (
    input  wire        HCLK,          // AHB clock
    input  wire        rst,           // Active-high reset
    input  wire [7:0]  addr,          // AHB address input
    input  wire [2:0]  size,          // AHB transfer size
    input  wire        write,         // AHB write/read control
    input  wire [2:0]  burst,         // AHB burst type
    input  wire        start,         // Start signal for AHB master
    input  wire        clk_spi,       // SPI clock
    output wire [31:0] HRDATA,        // AHB read data
    output wire        HREADY,        // AHB ready signal
    output wire        HRESP,         // AHB response signal
    output wire [7:0]  HADDR,         // AHB address
    output wire [1:0]  HTRANS,        // AHB transfer type
    output wire        HWRITE,        // AHB write/read
    output wire [2:0]  HSIZE,         // AHB size
    output wire [2:0]  HBURST,        // AHB burst
    output wire [31:0] HWDATA,        // AHB write data
    output wire        done           // AHB transaction done
);

    // SPI interface signals
    wire spi_clk;
    wire spi_mosi;
    wire spi_miso;
    wire spi_cs0;
    wire spi_cs1;

    // MISO signals from slaves
    wire miso_slave0;
    wire miso_slave1;

    // Sequential MISO arbitration: register spi_miso on clk_spi
    reg spi_miso_reg;
    always @(posedge clk_spi or posedge rst) begin
        if (rst)
            spi_miso_reg <= 1'b0;
        else if (spi_cs0 == 1'b0)
            spi_miso_reg <= miso_slave0;
        else if (spi_cs1 == 1'b0)
            spi_miso_reg <= miso_slave1;
        else
            spi_miso_reg <= 1'b0;
    end
    assign spi_miso = spi_miso_reg;

    // AHB-to-SPI bridge
    ahb_to_spi_bridge bridge (
        .HCLK(HCLK),
        .rst(rst),
        .addr(addr),
        .size(size),
        .write(write),
        .burst(burst),
        .start(start),
        .HRDATA(HRDATA),
        .HREADY(HREADY),
        .HRESP(HRESP),
        .HADDR(HADDR),
        .HTRANS(HTRANS),
        .HWRITE(HWRITE),
        .HSIZE(HSIZE),
        .HBURST(HBURST),
        .HWDATA(HWDATA),
        .done(done),
        .clk_spi(clk_spi),
        .spi_clk(spi_clk),
        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso),
        .spi_cs0(spi_cs0),
        .spi_cs1(spi_cs1)
    );

    // SPI slave 0
    spi_slave slave0 (
        .clk(clk_spi),
        .rst(rst),
        .sclk(spi_clk),
        .cs(spi_cs0),
        .mosi(spi_mosi),
        .miso(miso_slave0)
    );

    // SPI slave 1
    spi_slave slave1 (
        .clk(clk_spi),
        .rst(rst),
        .sclk(spi_clk),
        .cs(spi_cs1),
        .mosi(spi_mosi),
        .miso(miso_slave1)
    );

endmodule