// UVM monitor for asynchronous FIFO

class fifo_monitor extends uvm_monitor;
    `uvm_component_utils(fifo_monitor)

    virtual fifo_if vif;
    uvm_analysis_port #(fifo_transaction) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
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
            tx.wr_en = vif.wr_en;
            tx.wr_data = vif.wr_data;
            tx.full = vif.full;
            @(posedge vif.rd_clk);
            tx.rd_en = vif.rd_en;
            tx.rd_data = vif.rd_data;
            tx.empty = vif.empty;
            `uvm_info("FIFO_MONITOR", $sformatf("Sampled: wr_en=%0b wr_data=%0h full=%0b rd_en=%0b rd_data=%0h empty=%0b",
                tx.wr_en, tx.wr_data, tx.full, tx.rd_en, tx.rd_data, tx.empty), UVM_MEDIUM)
            ap.write(tx);
        end
    endtask
endclass
