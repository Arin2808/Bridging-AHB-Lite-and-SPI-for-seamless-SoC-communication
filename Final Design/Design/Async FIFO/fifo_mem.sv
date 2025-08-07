// -----------------------------------------------------------------------------
// fifo_mem: Dual-Port FIFO Memory
// -----------------------------------------------------------------------------
// This module implements the memory array for an asynchronous FIFO. It supports
// independent write and read operations on separate clocks, allowing safe data
// storage and retrieval between two clock domains. The memory is parameterized
// for data width and address width, enabling flexible FIFO sizing.
// ----------------------------------------------------------------------------

`timescale 1ns / 1ps

module fifo_mem #(
    parameter DATA_WIDTH = 41,                // Width of each memory word
    parameter ADDR_WIDTH = 4                  // Address width (FIFO depth = 2^ADDR_WIDTH)
)(
    input  wire                   wr_clk,     // Write clock
    input  wire                   wr_en,      // Write enable
    input  wire [ADDR_WIDTH-1:0]  wr_addr,    // Write address
    input  wire [DATA_WIDTH-1:0]  wr_data,    // Data to write
    input  wire                   rd_clk,     // Read clock
    input  wire                   rd_en,      // Read enable
    input  wire [ADDR_WIDTH-1:0]  rd_addr,    // Read address
    output reg  [DATA_WIDTH-1:0]  rd_data     // Data output
);

    localparam DEPTH = 1 << ADDR_WIDTH;       // FIFO depth

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];     // Memory array

    // Write logic: synchronous to wr_clk
    always @(posedge wr_clk) begin
        if (wr_en) begin
            mem[wr_addr] <= wr_data;          // Write data to memory
        end
    end

    // Read logic: synchronous to rd_clk
    always @(posedge rd_clk) begin
        if (rd_en) begin
            rd_data <= mem[rd_addr];          // Read data from memory
        end
    end

endmodule