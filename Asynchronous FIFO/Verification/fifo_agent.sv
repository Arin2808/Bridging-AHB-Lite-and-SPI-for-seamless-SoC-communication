// UVM agent for asynchronous FIFO

class fifo_agent extends uvm_agent;
    `uvm_component_utils(fifo_agent)

    fifo_driver driver;
    fifo_monitor monitor;
    uvm_sequencer #(fifo_transaction) sequencer;
    uvm_analysis_export #(fifo_transaction) agent_mon_export;
    uvm_analysis_export #(fifo_transaction) agent_drv_export;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        agent_mon_export = new("agent_mon_export", this);
        agent_drv_export = new("agent_drv_export", this);
        `uvm_info("FIFO_AGENT", "Constructor called", UVM_LOW)
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("FIFO_AGENT", "Build phase started", UVM_LOW)
        monitor = fifo_monitor::type_id::create("monitor", this);
        if (get_is_active()) begin
            driver = fifo_driver::type_id::create("driver", this);
            sequencer = uvm_sequencer#(fifo_transaction)::type_id::create("sequencer", this);
            `uvm_info("FIFO_AGENT", "Driver and sequencer created (active mode)", UVM_LOW)
        end
        else begin
            `uvm_info("FIFO_AGENT", "Agent is passive, only monitor created", UVM_LOW)
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        `uvm_info("FIFO_AGENT", "Connect phase started", UVM_LOW)
        if (get_is_active()) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
            `uvm_info("FIFO_AGENT", "Driver connected to sequencer", UVM_LOW)
            driver.dport.connect(this.agent_drv_export);
            `uvm_info("MY_AGENT","driver port and agent export2 connection is done ",UVM_NONE)
        end
        monitor.maport.connect(this.agent_mon_export);
        `uvm_info("MY_AGENT","monitor port and agent export1 connection is done ",UVM_NONE)
    endfunction
endclass
