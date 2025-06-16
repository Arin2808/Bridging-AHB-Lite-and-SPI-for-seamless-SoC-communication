`timescale 1ns / 1ps

module bin2gray #(
    parameter WIDTH = 5
)(
    input  wire [WIDTH-1:0] bin,
    output wire [WIDTH-1:0] gray
);

    assign gray = (bin >> 1) ^ bin;

endmodule
