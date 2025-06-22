`timescale 1ns/1ps
`include "AHB_master_data.v"
`include "AHB_master_ctrl.v"

module AHB_master (
    input         HCLK,
    input         HRESETn,
    input  [31:0] HRDATA,
    input         HREADY,
    output [7:0]  HADDR,
    output [1:0]  HTRANS,
    output        HWRITE,
    output [2:0]  HSIZE,
    output [2:0]  HBURST,
    output [31:0] HWDATA,
    output        done
);

    // Internal control registers
    reg        start;
    reg [7:0]  addr;
    reg        write;
    reg [2:0]  size;
    reg [2:0]  burst;
    reg [3:0]  burst_len;

    reg started_once;

    // Only trigger a single burst after reset
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            start        <= 1'b0;
            addr         <= 8'h10;
            write        <= 1'b1;
            size         <= 3'b010; // word
            burst        <= 3'b011; // INCR4
            burst_len    <= 4;
            started_once <= 1'b0;
        end else if (!started_once) begin
            start        <= 1'b1;
            started_once <= 1'b1;
        end else begin
            start        <= 1'b0;
        end
    end

    wire busy, next_beat, store_read;
    wire [31:0] mem_out;

    AHB_master_ctrl ctrl_dut (
        .HCLK(HCLK),
        .HRESETn(HRESETn),
        .start(start),
        .write(write),
        .burst(burst),
        .burst_len(burst_len),
        .HREADY(HREADY),
        .HTRANS(HTRANS),
        .HWRITE(HWRITE),
        .busy(busy),
        .next_beat(next_beat),
        .store_read(store_read),
        .done(done)
    );

    AHB_master_data data_dut (
        .HCLK(HCLK),
        .HRESETn(HRESETn),
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