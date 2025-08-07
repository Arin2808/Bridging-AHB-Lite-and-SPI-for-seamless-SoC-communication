// -----------------------------------------------------------------------------
// sync_flop: Multi-bit Two-Stage Synchronizer
// -----------------------------------------------------------------------------
// This module synchronizes an asynchronous multi-bit signal into a clock domain.
// It uses two flip-flop stages to reduce metastability risk. The parameter WIDTH
// sets the width of the signal being synchronized.
// -----------------------------------------------------------------------------

`timescale 1ns / 1ps

module sync_flop #(
    parameter WIDTH = 5                    // Width of the signal to synchronize
)(
    input  wire              clk,          // Destination clock domain
    input  wire              rst,          // Active-high reset
    input  wire [WIDTH-1:0]  async_in,     // Asynchronous input signal
    output reg  [WIDTH-1:0]  sync_out      // Synchronized output signal
);

    reg [WIDTH-1:0] sync_ff1;              // First stage flip-flop

    // Two-stage synchronizer: reduces metastability for async_in crossing into clk domain
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sync_ff1 <= 0;
            sync_out <= 0;
        end else begin
            sync_ff1 <= async_in;
            sync_out <= sync_ff1;
        end
    end

endmodule