`timescale 1ns / 1ps

module sync_flop #(
    parameter WIDTH = 5
)(
    input  wire              clk,
    input  wire              rst,         // Active-high reset
    input  wire [WIDTH-1:0]  async_in,
    output reg  [WIDTH-1:0]  sync_out
);

    reg [WIDTH-1:0] sync_ff1;

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