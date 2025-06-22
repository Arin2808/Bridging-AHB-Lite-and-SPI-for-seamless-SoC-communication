`timescale 1ns/1ps
`include "AHB_master.v"
module AHB_master_tb;

    reg HCLK;
    reg HRESETn;

    // AHB-Lite bus signals
    wire [7:0]  HADDR;
    wire [1:0]  HTRANS;
    wire        HWRITE;
    wire [2:0]  HSIZE;
    wire [2:0]  HBURST;
    wire [31:0] HWDATA;
    reg  [31:0] HRDATA;
    reg         HREADY;
    wire        done;

    // Instantiate AHB Master
    AHB_master master (
        .HCLK(HCLK),
        .HRESETn(HRESETn),
        .HRDATA(HRDATA),
        .HREADY(HREADY),
        .HADDR(HADDR),
        .HTRANS(HTRANS),
        .HWRITE(HWRITE),
        .HSIZE(HSIZE),
        .HBURST(HBURST),
        .HWDATA(HWDATA),
        .done(done)
    );

    // Clock generation
    initial HCLK = 0;
    always #5 HCLK = ~HCLK; // 100MHz

    // Simple slave model: always ready, returns address as data
    initial begin
        HRESETn = 0;
        HREADY  = 1;
        HRDATA  = 32'h0;
        #20;
        HRESETn = 1;
    end

    always @(posedge HCLK) begin
        if (HWRITE == 0 && HTRANS != 2'b00)
            HRDATA <= {24'h0, HADDR}; // For read, return address as data
    end

    // End simulation after master is done
    initial begin
        wait(done);
        repeat(5) @(negedge HCLK);
        $finish;
    end

    // Monitor
    initial begin
        $monitor("T=%0t HADDR=%h HTRANS=%h HWRITE=%h HSIZE=%h HBURST=%h HWDATA=%h HRDATA=%h HREADY=%h",
            $time, HADDR, HTRANS, HWRITE, HSIZE, HBURST, HWDATA, HRDATA, HREADY);
        $dumpfile("ahb_master_tb.vcd");
        $dumpvars(0, AHB_master_tb);
    end

endmodule