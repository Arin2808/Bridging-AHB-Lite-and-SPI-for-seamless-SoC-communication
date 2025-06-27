module Async_FIFO #(
    parameter DATA_WIDTH = 8, // Width of each data word
    parameter ADDR = 4        // Number of address bits (FIFO depth = 2^ADDR)
)(
    input wire wr_clk,                    // Write clock
    input wire rd_clk,                    // Read clock
    input wire rst,                       // Asynchronous reset
    input wire wr_en,                     // Write enable
    input wire rd_en,                     // Read enable
    input wire [DATA_WIDTH-1:0] din,      // Data input
    output reg [DATA_WIDTH-1:0] dout,     // Data output
    output wire full,                     // FIFO full flag
    output wire empty                     // FIFO empty flag
);

    localparam DEPTH = (1 << ADDR);       // FIFO depth (number of entries)

    // FIFO memory array
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [ADDR-1:0] wr_ptr = 0;           // Write pointer
    reg [ADDR-1:0] rd_ptr = 0;           // Read pointer
    reg [ADDR:0] wr_count = 0;           // Write count (tracks total writes)
    reg [ADDR:0] rd_count = 0;           // Read count (tracks total reads)

    // Write logic: On write clock or reset
    always @(posedge wr_clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= 0;                 // Reset write pointer
            wr_count <= 0;               // Reset write count
        end else if (wr_en && !full) begin
            mem[wr_ptr] <= din;          // Write data to memory
            wr_ptr <= wr_ptr + 1;        // Increment write pointer
            wr_count <= wr_count + 1;    // Increment write count
        end
    end

    // Read logic: On read clock or reset
    always @(posedge rd_clk or posedge rst) begin
        if (rst) begin
            rd_ptr <= 0;                 // Reset read pointer
            rd_count <= 0;               // Reset read count
            dout <= 0;                   // Clear output data
        end else if (rd_en && !empty) begin
            dout <= mem[rd_ptr];         // Read data from memory
            rd_ptr <= rd_ptr + 1;        // Increment read pointer
            rd_count <= rd_count + 1;    // Increment read count
        end
    end

    // FIFO status flags
    assign full  = (wr_count - rd_count == DEPTH); // FIFO is full when difference equals depth
    assign empty = (wr_count == rd_count);         // FIFO is empty when counts
endmodule