`timescale 1ns/1ps

module AHB_master (
    input         HCLK,
    input         rst,            // Active-high reset
    input  [31:0] HRDATA,
    input         HREADY,
    input         HRESP,           
    input  [7:0]  addr, 
    input  [2:0]  size, 
    input         write,
    input  [2:0]  burst,
    input         start,         // External start signal
    output [7:0]  HADDR,
    output [1:0]  HTRANS,
    output        HWRITE,
    output [2:0]  HSIZE,
    output [2:0]  HBURST,
    output [31:0] HWDATA,
    output        done
);

    // Calculate burst_len from burst type
    reg [3:0] burst_len;
    always @(*) begin
        case (burst)
            3'b011: burst_len = 4;   // INCR4
            3'b101: burst_len = 8;   // INCR8
            3'b111: burst_len = 15;  // INCR16
            3'b010: burst_len = 4;   // WRAP4
            3'b100: burst_len = 8;   // WRAP8
            3'b110: burst_len = 15;  // WRAP16
            default: burst_len = 1;  // SINGLE/INCR
        endcase
    end

    wire busy, next_beat, store_read;
    wire [31:0] mem_out;

    AHB_master_ctrl ctrl_dut (
        .HCLK(HCLK),
        .rst(rst),       // Use the correct port name
        .start(start),
        .write(write),
        .burst(burst),
        .burst_len(burst_len),
        .HREADY(HREADY),
        .HRESP(HRESP),         
        .HTRANS(HTRANS),
        .HWRITE(HWRITE),
        .busy(busy),
        .next_beat(next_beat),
        .store_read(store_read),
        .done(done)
    );

    AHB_master_data data_dut (
        .HCLK(HCLK),
        .rst(rst),       // Changed to rst (active-high)
        .addr_in(addr),
        .size_in(size),
        .burst_in(burst),
        .write_in(write),
        .start_in(start),
        .next_beat(next_beat),
        .store_read(store_read),
        .HRDATA(HRDATA),
        .HADDR(HADDR),
        .HSIZE(HSIZE),
        .HBURST(HBURST),
        .HWDATA(HWDATA),
        .mem_out(mem_out)
    );

endmodule