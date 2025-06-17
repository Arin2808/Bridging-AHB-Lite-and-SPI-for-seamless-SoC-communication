`timescale 1ns/1ps

/*
 * Testbench for Asynchronous FIFO Top Module
 * Tests write and read across different clock domains
 */

module async_fifo_tb();

  parameter DATA_WIDTH = 41;
  parameter ADDR_WIDTH = 4;
  localparam FIFO_DEPTH = 1 << ADDR_WIDTH;

  reg wr_clk;
  reg wr_rst_n;
  reg wr_en;
  reg [DATA_WIDTH-1:0] wr_data;

  reg rd_clk;
  reg rd_rst_n;
  reg rd_en;

  wire full;
  wire empty;
  wire [DATA_WIDTH-1:0] rd_data;

  // Instantiate the async FIFO top module
  async_fifo_top #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
  ) dut (
    .wr_clk(wr_clk),
    .wr_rst_n(wr_rst_n),
    .wr_en(wr_en),
    .wr_data(wr_data),

    .rd_clk(rd_clk),
    .rd_rst_n(rd_rst_n),
    .rd_en(rd_en),

    .full(full),
    .empty(empty),
    .rd_data(rd_data)
  );

  // Generate write clock: 25 MHz (40 ns period) 50 MHz (20 ns period) 100 MHz (10 ns period)
  initial begin
    wr_clk = 0;
    forever #10 wr_clk = ~wr_clk;
  end

  // Generate read clock: 12.5 MHz (80 ns period)
  initial begin
    rd_clk = 0;
    forever #40 rd_clk = ~rd_clk;
  end

  // Test stimulus
  initial begin
    // Initialize signals
    wr_rst_n = 0;
    rd_rst_n = 0;
    wr_en = 0;
    rd_en = 0;
    wr_data = 0;

    // Reset both domains
    #50;
    wr_rst_n = 1;
    rd_rst_n = 1;

    fork
      // Write process
      begin : write_proc
        reg [DATA_WIDTH-1:0] i;
        for (i = 0; i < FIFO_DEPTH + 2; i = i + 1) begin
          @(posedge wr_clk);
          if (!full) begin
            wr_en <= 1;
           i= $urandom_range(0,20);
            wr_data <= i;
          end else begin
            wr_en <= 0;
          end
        end
        wr_en <= 0;
      end

      begin : read_proc
        while(rd_rst_n) begin
          @(posedge rd_clk);
          if (!empty) begin
            rd_en <= 1;
          end else begin
            rd_en <= 0;
          end
        end
        rd_en <= 0;
      end
    join
  end
endmodule
