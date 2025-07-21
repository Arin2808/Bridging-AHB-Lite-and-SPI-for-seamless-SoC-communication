module gray2bin #(
    parameter WIDTH = 5
)(
    input  wire [WIDTH-1:0] gray,
    output wire [WIDTH-1:0] bin
);
    // Gray to binary conversion: iterative XOR
    integer i;
    reg [WIDTH-1:0] bin_temp;

    always @* begin
        bin_temp[WIDTH-1] = gray[WIDTH-1];
        for (i = WIDTH - 2; i >= 0; i = i - 1) begin
            bin_temp[i] = bin_temp[i+1] ^ gray[i];
        end
    end

    assign bin = bin_temp;

endmodule