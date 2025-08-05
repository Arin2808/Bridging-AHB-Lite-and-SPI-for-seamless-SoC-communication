// -----------------------------------------------------------------------------
// AHB_Driver: UVM Driver for AHB Bus Transactions
// -----------------------------------------------------------------------------
// This class implements the UVM driver for the AHB protocol. The driver receives
// sequence items from the sequencer, drives them onto the DUT via the virtual
// interface, and writes the transaction to the analysis port for scoreboard or
// coverage collection. UVM info messages are used for debug visibility.
// -----------------------------------------------------------------------------

class AHB_Driver extends uvm_driver #(AHB_Transaction);
    // Virtual interface to drive AHB signals on the DUT
    virtual interface ahb_if ahb_vif;
    // Analysis port to send driven transactions to scoreboard/coverage
    uvm_analysis_port #(AHB_Transaction) drv_ap;

    // UVM factory registration macro
    `uvm_component_utils(AHB_Driver)

    // Constructor: initializes the driver and analysis port
    function new(string name, uvm_component parent);
        super.new(name, parent);
        drv_ap = new("drv_ap", this);
    endfunction

    // UVM build_phase: gets the virtual interface from the config database
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual ahb_if)::get(this, "", "ahb_vif", ahb_vif))
            `uvm_fatal("DRV", "No AHB interface")
        `uvm_info("DRV", "Build phase completed: AHB interface obtained.", UVM_MEDIUM)
    endfunction

    // UVM run_phase: main driver loop
    // Gets sequence items, drives them, and sends to analysis port
    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        `uvm_info("DRV", "Run phase started: waiting for transactions.", UVM_MEDIUM)
        forever begin
            AHB_Transaction trans;
            seq_item_port.get_next_item(trans);      // Get transaction from sequencer
            drive_transaction(trans);                // Drive transaction to DUT
            drv_ap.write(trans);                     // Send to scoreboard/coverage
            seq_item_port.item_done();               // Notify sequencer
        end
    endtask

    // Drives a single AHB transaction onto the bus
    task drive_transaction(AHB_Transaction trans);
        @(posedge ahb_vif.HCLK);
        ahb_vif.HADDR = trans.haddr;
        ahb_vif.HSIZE = trans.hsize;
        ahb_vif.HWRITE = trans.hwrite;
        ahb_vif.HBURST = trans.hburst;
        ahb_vif.HTRANS = 2'b10; // NONSEQ
        @(posedge ahb_vif.HCLK);
        while (!ahb_vif.HREADY) @(posedge ahb_vif.HCLK); // Wait for ready
        ahb_vif.HWDATA = trans.hwdata;
        @(posedge ahb_vif.HCLK);
        ahb_vif.HTRANS = 2'b00; // IDLE
        while (!ahb_vif.HREADY) @(posedge ahb_vif.HCLK); // Wait for ready
        // UVM info message for debug
        `uvm_info("DRV", $sformatf("Drove: %s", trans.convert2string()), UVM_MEDIUM)
    endtask
endclass