// -----------------------------------------------------------------------------
// SPI_Monitor: UVM Monitor for SPI Bus Transactions
// -----------------------------------------------------------------------------
// This class implements a UVM monitor for the SPI protocol. It observes SPI
// transactions on the interface, reconstructs the packet, and sends relevant
// data to the analysis port for checking in the scoreboard. The monitor uses
// the virtual interface to access SPI signals and provides debug info via UVM
// messages. Only write transactions are sent to the scoreboard.
// -----------------------------------------------------------------------------

class SPI_Monitor extends uvm_monitor;
    // Virtual interface for accessing SPI signals
    virtual interface spi_if spi_vif;
    // Analysis port for sending observed transactions to the scoreboard
    uvm_analysis_port #(bit [39:0]) mon_ap;

    // UVM factory registration macro
    `uvm_component_utils(SPI_Monitor)

    // Constructor: initializes the monitor and analysis port
    function new(string name, uvm_component parent);
        super.new(name, parent);
        mon_ap = new("mon_ap", this);
    endfunction

    // UVM build_phase: gets the virtual interface from the config database
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual spi_if)::get(this, "", "spi_vif", spi_vif))
            `uvm_fatal("MON", "No SPI interface")
    endfunction

    // UVM run_phase: observes SPI transactions and sends write packets to scoreboard
    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        `uvm_info("MON", "Run phase started: Monitoring SPI transactions.", UVM_MEDIUM)
        // continuously observe SPI transactions
        forever begin
            bit [40:0] received_data;
            bit [7:0] addr;
            bit [31:0] data;
            bit wr_rd_en;
            int bit_count;

            @(negedge spi_vif.spi_cs); // Wait for start of SPI transaction (CS low)
            received_data = 41'b0;
            bit_count = 41;
            // Shift in SPI data packet, one bit per clock
            while (!spi_vif.spi_cs && bit_count > 0) begin
                @(posedge spi_vif.spi_clk);
                received_data = {received_data[39:0], spi_vif.spi_mosi};
                bit_count--;
            end
            @(posedge spi_vif.SCLK); // Wait for system clock to stabilize

            if (bit_count == 0) begin
                wr_rd_en = received_data[40];      // MSB: write/read flag
                addr     = received_data[39:32];   // Address field
                data     = received_data[31:0];    // Data field
                if (wr_rd_en) begin
                    // Only write transactions are sent to scoreboard
                    `uvm_info("MON", $sformatf("Captured SPI write - ADDR=%h, DATA=%h", addr, data), UVM_MEDIUM)
                    mon_ap.write({addr, data});
                end
            end
        end
    endtask
endclass