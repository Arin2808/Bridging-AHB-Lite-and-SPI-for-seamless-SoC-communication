`timescale 1ns / 1ps

module top_level (
    input  wire        HCLK,          // AHB clock
    input  wire        HRESET,        // Active-high reset
    input  wire [7:0]  HADDR,         // AHB address input
    input  wire [2:0]  HSIZE,         // AHB transfer size
    input  wire        HWRITE,        // AHB write/read control
    input  wire [2:0]  HBURST,        // AHB burst type
    input  wire [31:0] HWDATA,        // AHB write data
    input  wire [1:0]  HTRANS,        // AHB transfer type (added as input)
    input  wire        SCLK,          // SPI clock
    input  wire        SRESET,        // SPI reset
    output wire [31:0] HRDATA,        // AHB read data
    output wire        HREADY,        // AHB ready signal
    output wire        HRESP,         // AHB response signal
    output wire        spi_clk,       // SPI clock output
    output wire        spi_mosi,      // SPI Master Out Slave In
    input  wire        spi_miso,      // SPI Master In Slave Out
    output wire        spi_cs0,       // SPI chip select 0
    output wire        spi_cs1,       // SPI chip select 1
    output wire        miso_slave0,   // MISO from slave 0
    output wire        miso_slave1    // MISO from slave 1
);

    // SPI interface signals
    wire spi_clk_int;
    wire spi_mosi_int;
    wire spi_cs0_int;
    wire spi_cs1_int;

    // MISO signals from slaves
    wire miso_slave0_int;
    wire miso_slave1_int;

    // Sequential MISO arbitration: register spi_miso on SCLK
    reg spi_miso_reg;
    always @(posedge SCLK or posedge SRESET) begin
        if (SRESET)
            spi_miso_reg <= 1'b0;
        else if (spi_cs0_int == 1'b0)
            spi_miso_reg <= miso_slave0_int;
        else if (spi_cs1_int == 1'b0)
            spi_miso_reg <= miso_slave1_int;
        else
            spi_miso_reg <= 1'b0;
    end
    assign spi_miso = spi_miso_reg;

    // AHB-to-SPI bridge
    ahb_to_spi_bridge bridge (
        .HCLK(HCLK),
        .HRESET(HRESET),
        .HADDR(HADDR),
        .HTRANS(HTRANS),         // Now passed as input
        .HWRITE(HWRITE),
        .HSIZE(HSIZE),
        .HBURST(HBURST),
        .HWDATA(HWDATA),
        .HRDATA(HRDATA),
        .HREADY(HREADY),
        .HRESP(HRESP),
        .SCLK(SCLK),
        .SRESET(SRESET),
        .spi_clk(spi_clk_int),
        .spi_mosi(spi_mosi_int),
        .spi_miso(spi_miso),
        .spi_cs0(spi_cs0_int),
        .spi_cs1(spi_cs1_int)
    );

    assign spi_clk  = spi_clk_int;
    assign spi_mosi = spi_mosi_int;
    assign spi_cs0  = spi_cs0_int;
    assign spi_cs1  = spi_cs1_int;
    assign miso_slave0 = miso_slave0_int;
    assign miso_slave1 = miso_slave1_int;

    // SPI slave 0
    spi_slave slave0 (
        .SCLK(SCLK),
        .SRESET(SRESET),
        .spi_clk(spi_clk_int),
        .cs(spi_cs0_int),
        .mosi(spi_mosi_int),
        .miso(miso_slave0_int)
    );

    // SPI slave 1
    spi_slave slave1 (
        .SCLK(SCLK),
        .SRESET(SRESET),
        .spi_clk(spi_clk_int),
        .cs(spi_cs1_int),
        .mosi(spi_mosi_int),
        .miso(miso_slave1_int)
    );

endmodule