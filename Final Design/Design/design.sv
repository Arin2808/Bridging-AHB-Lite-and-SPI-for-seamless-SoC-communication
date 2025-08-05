// -----------------------------------------------------------------------------
// top_level: AHB to SPI Bridge System Top Module
// -----------------------------------------------------------------------------
// This top-level module integrates the AHB-to-SPI bridge and SPI slave modules.
// It connects the AHB bus interface to the SPI interface, allowing data transfer
// between the two protocols. The module manages all necessary signal routing and
// exposes standard AHB and SPI ports for system integration.
// -----------------------------------------------------------------------------

`timescale 1ns / 1ps
`include "ahb_to_spi_bridge.sv"
`include "spi_slave.sv"

module top_level (
    input         HCLK,          // AHB clock
    input         HRESET,        // Active-high reset
    input  [7:0]  HADDR,         // AHB address input
    input  [2:0]  HSIZE,         // AHB transfer size
    input         HWRITE,        // AHB write/read control
    input  [2:0]  HBURST,        // AHB burst type
    input  [31:0] HWDATA,        // AHB write data
    input  [1:0]  HTRANS,        // AHB transfer type
    input         SCLK,          // SPI clock
    input         SRESET,        // SPI reset
    output [31:0] HRDATA,        // AHB read data
    output        HREADY,        // AHB ready signal
    output        HRESP,         // AHB response signal
    output        spi_clk,       // SPI clock output
    output        spi_mosi,      // SPI Master Out Slave In
    input         spi_miso,      // SPI Master In Slave Out
    output        spi_cs         // SPI chip select
);

    // Internal SPI interface signals
    wire spi_clk_int;      // Internal SPI clock
    wire spi_mosi_int;     // Internal SPI MOSI
    wire spi_cs_int;       // Internal SPI chip select
    wire miso_slave_int;   // Internal MISO from slave

    // Instantiate AHB-to-SPI bridge
    ahb_to_spi_bridge bridge (
        .HCLK(HCLK),
        .HRESET(HRESET),
        .HADDR(HADDR),
        .HTRANS(HTRANS),
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
        .spi_cs(spi_cs_int)
    );

    // Connect internal SPI signals to top-level outputs
    assign spi_clk  = spi_clk_int;
    assign spi_mosi = spi_mosi_int;
    assign spi_cs   = spi_cs_int;

    // Instantiate SPI slave
    spi_slave slave (
        .SCLK(SCLK),
        .SRESET(SRESET),
        .spi_clk(spi_clk_int),
        .cs(spi_cs_int),
        .mosi(spi_mosi_int),
        .miso(miso_slave_int)
    );

    // Connect MISO directly since there's only one slave
    assign spi_miso = miso_slave_int;

endmodule

// -----------------------------------------------------------------------------
// AHB and SPI Interface Definitions (for testbench or higher-level integration)
// -----------------------------------------------------------------------------

// The 'interface' construct in SystemVerilog is used to group related signals together.
// This makes module connections and testbench stimulus much cleaner and less error-prone.
// Interfaces can also include clocking blocks for synchronized signal access and modports
// for controlling access direction. Below are two interfaces for AHB and SPI protocols:

interface ahb_if (
    input logic HCLK,      // AHB clock for interface synchronization
    input logic HRESET     // AHB reset for interface
);
    // All signals required for AHB bus transactions are grouped here.
    logic [7:0]  HADDR;    // Address bus
    logic [2:0]  HSIZE;    // Transfer size
    logic        HWRITE;   // Write/read control
    logic [2:0]  HBURST;   // Burst type
    logic [31:0] HWDATA;   // Write data bus
    logic [1:0]  HTRANS;   // Transfer type
    logic [31:0] HRDATA;   // Read data bus
    logic        HREADY;   // Ready signal
    logic        HRESP;    // Response signal

    // The clocking block defines which signals are driven and which are sampled,
    // ensuring correct timing in testbenches and verification environments.
    clocking cb @(posedge HCLK);
        input HRESET;                              // Sample reset
        output HADDR, HSIZE, HWRITE, HBURST, HWDATA, HTRANS; // Drive control and address signals
        input HRDATA, HREADY, HRESP;               // Sample read data and response signals
    endclocking
endinterface

interface spi_if (
    input logic SCLK,      // SPI clock for interface synchronization
    input logic SRESET     // SPI reset for interface
);
    // All signals required for SPI communication are grouped here.
    logic spi_clk;         // SPI clock output from master
    logic spi_mosi;        // Master Out Slave In
    logic spi_miso;        // Master In Slave Out
    logic spi_cs;          // Chip select

    // The clocking block defines which signals are sampled in the SPI domain,
    // helping with timing and stimulus in testbenches.
    clocking cb @(posedge SCLK);
        input SRESET;                      // Sample reset
        input spi_clk, spi_mosi, spi_miso, spi_cs; // Sample SPI signals
    endclocking
endinterface