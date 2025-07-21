`timescale 1ns / 1ps

module tb_top_level;

    // Testbench signals (all as logic)
    logic HCLK;
    logic rst;
    logic [7:0] addr;
    logic [2:0] size;
    logic write;
    logic [2:0] burst;
    logic start;
    logic clk_spi;
    logic [31:0] tb_HWDATA; // Testbench drives this

    // DUT outputs as logic
    logic [31:0] HRDATA;
    logic HREADY;
    logic HRESP;
    logic [7:0] HADDR;
    logic [1:0] HTRANS;
    logic HWRITE;
    logic [2:0] HSIZE;
    logic [2:0] HBURST;
    logic done;

    // Clock generation
    parameter HCLK_PERIOD = 10;      // 100 MHz
    parameter CLK_SPI_PERIOD = 40;   // 25 MHz (1/4 of HCLK)
    initial begin
        HCLK = 0;
        forever #(HCLK_PERIOD/2) HCLK = ~HCLK;
    end
    initial begin
        clk_spi = 0;
        forever #(CLK_SPI_PERIOD/2) clk_spi = ~clk_spi;
    end

    // Reset generation
    initial begin
        rst = 1;
        #50 rst = 0;
    end

    // DUT instantiation
    top_level dut (
        .HCLK(HCLK),
        .rst(rst),
        .addr(addr),
        .size(size),
        .write(write),
        .burst(burst),
        .start(start),
        .clk_spi(clk_spi),
        .HRDATA(HRDATA),
        .HREADY(HREADY),
        .HRESP(HRESP),
        .HADDR(HADDR),
        .HTRANS(HTRANS),
        .HWRITE(HWRITE),
        .HSIZE(HSIZE),
        .HBURST(HBURST),
        .HWDATA(tb_HWDATA),
        .done(done)
    );

    // Stimulus and monitoring
    initial begin
        $display("Simulation started at %t", $time);
        $monitor("Time=%0t | HADDR=%h | HWDATA=%h | HRDATA=%h | HREADY=%b | HRESP=%b | done=%b",
                 $time, HADDR, tb_HWDATA, HRDATA, HREADY, HRESP, done);

        // Initialize inputs
        addr = 8'h00;
        size = 3'b010;  // Word
        write = 0;
        burst = 3'b000; // Single
        start = 0;
        tb_HWDATA = 32'h00000000; // Initialize

        // Wait for reset to deassert
        #55;

        // Test 1: Write to Slave 0 (address 0)
        addr = 8'h00;  // Chip select 0, address 0
        write = 1;
        tb_HWDATA = 32'hA5A5A5A5;
        start = 1;
        #12 start = 0;
        #50;

        // Test 2: Read from Slave 0 (address 0)
        addr = 8'h00;
        write = 0;
        start = 1;
        #12 start = 0;
        #100;

        // Test 3: Write to Slave 1 (address 1)
        addr = 8'h01;  // Chip select 1, address 0
        write = 1;
        tb_HWDATA = 32'h5A5A5A5A;
        start = 1;
        #12 start = 0;
        #50;

        // Test 4: Read from Slave 1 (address 1)
        addr = 8'h01;
        write = 0;
        start = 1;
        #12 start = 0;
        #100;

        // Test 5: Burst Write to Slave 0 (INCR4)
        addr = 8'h00;
        write = 1;
        burst = 3'b011;  // INCR4
        tb_HWDATA = 32'h11111111;
        start = 1;
        #12 start = 0;
        #20 tb_HWDATA = 32'h22222222;
        #20 tb_HWDATA = 32'h33333333;
        #20 tb_HWDATA = 32'h44444444;
        #100;

        // End simulation
        #50 $display("Simulation completed at %t", $time);
        $finish;
    end

    // Optional: Assertions
    initial begin
        #20;
        if (!HREADY) $display("Error: HREADY not asserted at %t", $time);

        #200;
        if (HRESP) $display("Error: HRESP asserted unexpectedly at %t", $time);
    end

endmodule