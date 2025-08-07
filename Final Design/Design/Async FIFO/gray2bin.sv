// -----------------------------------------------------------------------------
// gray2bin: Gray Code to Binary Converter
// -----------------------------------------------------------------------------
// This module converts a Gray code input value to its equivalent binary value.
// The parameter WIDTH sets the width of the input and output buses.
// -----------------------------------------------------------------------------

`timescale 1ns / 1ps

module gray2bin #(
    parameter WIDTH = 5                // Width of the Gray/binary code
)(
    input  wire [WIDTH-1:0] gray,      // Gray code input
    output wire [WIDTH-1:0] bin        // Binary output
);

    integer i;
    reg [WIDTH-1:0] bin_temp;

    // Gray to binary conversion: MSB is same, each lower bit is XOR of previous binary and current Gray
    always @* begin
        bin_temp[WIDTH-1] = gray[WIDTH-1];
        for (i = WIDTH - 2; i >= 0; i = i - 1) begin
            bin_temp[i] = bin_temp[i+1] ^ gray[i];
        end
    end

    assign bin = bin_temp;

endmodule