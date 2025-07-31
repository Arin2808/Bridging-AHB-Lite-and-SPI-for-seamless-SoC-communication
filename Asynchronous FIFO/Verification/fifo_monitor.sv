// UVM monitor for asynchronous FIFO

class fifo_monitor extends uvm_monitor;
    `uvm_component_utils(fifo_monitor)

    virtual fifo_if vif;
    uvm_analysis_port #(fifo_transaction) maport;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        maport = new("maport", this);
        `uvm_info("FIFO_MONITOR", "Constructor called", UVM_LOW)
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("FIFO_MONITOR", "Build phase started", UVM_LOW)
        if (!uvm_config_db#(virtual fifo_if)::get(this, "", "vif", vif))
            `uvm_fatal("NO_VIF", "Virtual interface not set for monitor")
        else
            `uvm_info("FIFO_MONITOR", "Virtual interface set for monitor", UVM_LOW)
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        `uvm_info("FIFO_MONITOR", "Run phase started", UVM_LOW)
        forever begin
            fifo_transaction tx = fifo_transaction::type_id::create("tx");
            @(posedge vif.wr_clk);            
          	@(posedge vif.wr_clk);
            tx.wr_data = vif.wr_data;
            tx.source_port = "fifo_monitor"; // Set source
            `uvm_info("FIFO_MONITOR", $sformatf("Sampled: wr_data=%0h", tx.wr_data), UVM_MEDIUM)
            maport.write(tx);
        end
    endtask
endclass
