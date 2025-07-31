import uvm_pkg::*;
`include "uvm_macros.svh"
`include "fifo_pkg.sv"
import fifo_pkg::*;

module fifo_tb_top;

    logic wr_clk = 0;
    logic rd_clk = 0;

    // Clock generation
    initial begin
        `uvm_info("TB", "Clock generation started", UVM_MEDIUM)
        fork
            forever #20ns wr_clk = ~wr_clk; // 25 MHz
            forever #40ns rd_clk = ~rd_clk; // ~12.5 MHz
        join
    end

    fifo_if fifo_if_inst (.wr_clk(wr_clk), .rd_clk(rd_clk));

    async_fifo_top #(
        .DATA_WIDTH(41),
        .ADDR_WIDTH(4)
    ) dut (
        .wr_clk(wr_clk),
        .wr_rst_n(fifo_if_inst.wr_rst_n),
        .wr_en(fifo_if_inst.wr_en),
        .wr_data(fifo_if_inst.wr_data),
        .rd_clk(rd_clk),
        .rd_rst_n(fifo_if_inst.rd_rst_n),
        .rd_en(fifo_if_inst.rd_en),
        .full(fifo_if_inst.full),
        .empty(fifo_if_inst.empty),
        .rd_data(fifo_if_inst.rd_data)
    );

    initial begin
        `uvm_info("TB", "Setting virtual interface and starting test", UVM_MEDIUM)
        uvm_config_db#(virtual fifo_if)::set(null, "*", "vif", fifo_if_inst);
        run_test("fifo_test");
    end

    initial begin
        `uvm_info("TB", "Applying resets", UVM_MEDIUM)
        fifo_if_inst.wr_rst_n = 0; // Assert reset (active low)
        fifo_if_inst.rd_rst_n = 0; // Assert reset (active low)
        #20ns;
        fifo_if_inst.wr_rst_n = 1; // Deassert reset
        fifo_if_inst.rd_rst_n = 1; // Deassert reset
        `uvm_info("TB", "Resets deasserted", UVM_MEDIUM)
    end

    initial begin
        $dumpfile("fifo_tb.vcd");
        $dumpvars(0, fifo_tb_top);
    end
endmodule
