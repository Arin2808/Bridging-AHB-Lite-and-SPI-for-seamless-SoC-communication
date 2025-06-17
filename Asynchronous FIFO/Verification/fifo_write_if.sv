interface fifo_write_if #(parameter DATA_WIDTH = 41) (input logic wr_clk, input logic wr_rst_n);
    logic wr_en;
    logic [DATA_WIDTH-1:0] wr_data;
    logic full;

    // Driver clocking block
    clocking cb_driver @(posedge wr_clk);
        default input #1ns output #1ns;
        output wr_en, wr_data;
        input  full;
    endclocking

    // Monitor clocking block
    clocking cb_monitor @(posedge wr_clk);
        default input #1ns output #1ns;
        input wr_en, wr_data, full;
    endclocking

    // Modport for DUT
    modport dut_mp (input  wr_clk, wr_rst_n, wr_en, wr_data, output full);

    // Modport for  driver
    modport wr_drv_mp (clocking cb_driver, input wr_clk, input wr_rst_n);

    // Modport for monitor
    modport wr_mon_mp (clocking cb_monitor, input wr_clk, input wr_rst_n);

endinterface