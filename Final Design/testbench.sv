// -----------------------------------------------------------------------------
// tb_ahb_spi_uvm: UVM Testbench Top Module for AHB to SPI Bridge
// -----------------------------------------------------------------------------
// This testbench sets up the simulation environment for the AHB-to-SPI bridge.
// It generates clocks and resets for both AHB and SPI domains, instantiates
// SystemVerilog interfaces for protocol connectivity, and connects them to the DUT.
// The testbench also sets up UVM configuration for virtual interfaces, starts the
// UVM test, and provides timeout and waveform dump for debug.
// -----------------------------------------------------------------------------
// Key features:
// - Clock generation for AHB (HCLK) and SPI (SCLK)
// - Reset sequencing for both domains
// - Instantiation of protocol interfaces (ahb_if, spi_if)
// - DUT instantiation and connection to interfaces
// - UVM config_db setup for virtual interface access in agents/monitors
// - Simulation timeout protection
// - VCD waveform dump for debugging
// -----------------------------------------------------------------------------

`timescale 1ns / 1ps
import uvm_pkg::*;
`include "uvm_macros.svh"
`include "ahb_spi_pkg.sv"
import ahb_spi_pkg::*;

module tb_ahb_spi_uvm;
    // Clock and reset signals
    logic HCLK, HRESET;
    logic SCLK, SRESET;

    // Clock generation
    localparam HCLK_PERIOD = 20; // 50 MHz
    localparam SCLK_PERIOD = 40; // 12.5 MHz

    initial begin
        HCLK = 0;
        forever #(HCLK_PERIOD/2) HCLK = ~HCLK;
    end

    initial begin
        SCLK = 0;
        forever #(SCLK_PERIOD/2) SCLK = ~SCLK;
    end

    // Instantiate interfaces
    ahb_if ahb_if_inst (.HCLK(HCLK), .HRESET(HRESET));
    spi_if spi_if_inst (.SCLK(SCLK), .SRESET(SRESET));

    // Instantiate DUT
    top_level dut (
        .HCLK(HCLK),
        .HRESET(HRESET),
        .HADDR(ahb_if_inst.HADDR),
        .HSIZE(ahb_if_inst.HSIZE),
        .HWRITE(ahb_if_inst.HWRITE),
        .HBURST(ahb_if_inst.HBURST),
        .HWDATA(ahb_if_inst.HWDATA),
        .HTRANS(ahb_if_inst.HTRANS),
        .SCLK(SCLK),
        .SRESET(SRESET),
        .HRDATA(ahb_if_inst.HRDATA),
        .HREADY(ahb_if_inst.HREADY),
        .HRESP(ahb_if_inst.HRESP),
        .spi_clk(spi_if_inst.spi_clk),
        .spi_mosi(spi_if_inst.spi_mosi),
        .spi_miso(spi_if_inst.spi_miso),
        .spi_cs(spi_if_inst.spi_cs)
    );

    initial begin
        // Reset ahb sequence
        HRESET = 1;
        #10;
        HRESET = 0;
    end
  	initial begin
        // Reset spi sequence
        SRESET = 1;
        #20;
        SRESET = 0;
    end

    initial begin
        // Set interfaces in config DB for UVM agents/monitors
        uvm_config_db#(virtual ahb_if)::set(null, "*", "ahb_vif", ahb_if_inst);
        uvm_config_db#(virtual spi_if)::set(null, "*", "spi_vif", spi_if_inst);
        run_test("AHB_SPI_Test"); // Start UVM test
    end

    initial begin
        // Timeout protection for simulation
        #8000;
        `uvm_error("TB", "Testbench timeout!")
        $finish;
    end
  
    initial begin
        // VCD waveform dump for debugging
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_ahb_spi_uvm);
    end
endmodule