class fifo_transaction #(parameter DATA_WIDTH = 41);

    // Data and control fields
    rand bit [DATA_WIDTH-1:0] wdata;
    rand bit                  wr_en;
    rand bit                  rd_en;
    // Control signals
    bit                      full;
    bit                      empty;
    // Output data (read)
    bit [DATA_WIDTH-1:0]      rdata;

    constraint c {
        if (!full) {
            wr_en == 1'b1; // write if not full
        }

        if (!empty) {
            rd_en == 1'b1; // read if not empty
        }

        wdata inside {[0:20]}; // Example range for wdata 0 to 20
    }

    // Constructor
    function new();
        wdata = '0;
        wr_en = 0;
        rd_en = 0;
        rdata = '0;
    endfunction

    // Display method for debugging
    function void display(string prefix = "");
        $display("[%s] wdata=%0h wr_en=%0b rd_en=%0b rdata=%0h", prefix, wdata, wr_en, rd_en, rdata);
    endfunction

endclass