interface fifo_read_if #(parameter DATA_WIDTH = 41) (input logic rd_clk, input logic rd_rst_n);
    logic rd_en;
    logic [DATA_WIDTH-1:0] rd_data;
    logic empty;

    // Driver clocking block
    clocking cb_driver @(posedge rd_clk);
        default input #1ns output #1ns;
        output rd_en;
        input  rd_data, empty;
    endclocking

    // Monitor clocking block
    clocking cb_monitor @(posedge rd_clk);
        default input #1ns output #1ns;
        input rd_en, rd_data, empty;
    endclocking

    // Modport for DUT
    modport dut_mp (input  rd_clk, rd_rst_n, rd_en, output rd_data, empty);

    // Modport for driver
    modport rd_drv_mp (clocking cb_driver, input rd_clk, input rd_rst_n);

    // Modport for TB monitor
    modport rd_mon_mp (clocking cb_monitor, input rd_clk, input rd_rst_n);

endinterface