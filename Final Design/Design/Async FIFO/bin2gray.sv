// -----------------------------------------------------------------------------
// bin2gray: Binary to Gray Code Converter
// -----------------------------------------------------------------------------
// This module converts a binary input value to its equivalent Gray code.
// The parameter WIDTH sets the width of the input and output buses.
// -----------------------------------------------------------------------------

`timescale 1ns / 1ps

module bin2gray #(
    parameter WIDTH = 5                // Width of the binary/Gray code
)(
    input  wire [WIDTH-1:0] bin,       // Binary input
    output wire [WIDTH-1:0] gray       // Gray code output
);

    // Gray code conversion: MSB is same, each lower bit is XOR of adjacent binary bits
    assign gray = (bin >> 1) ^ bin;

endmodule