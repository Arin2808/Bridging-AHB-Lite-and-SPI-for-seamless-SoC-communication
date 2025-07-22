// UVM test for asynchronous FIFO

class fifo_test extends uvm_test;
    `uvm_component_utils(fifo_test)

    fifo_env env;
    fifo_sequence seq;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("FIFO_TEST", "Build phase started", UVM_LOW)
        env = fifo_env::type_id::create("env", this);
        uvm_config_db#(uvm_active_passive_enum)::set(this, "env.agent", "is_active", UVM_ACTIVE);
        `uvm_info("FIFO_TEST", "Environment created and agent set to active", UVM_LOW)
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        `uvm_info("FIFO_TEST", "Run phase started, raising objection", UVM_LOW)
        phase.raise_objection(this);
        seq = fifo_sequence::type_id::create("seq");
        `uvm_info("FIFO_TEST", "Sequence created, starting sequence", UVM_LOW)
        seq.start(env.agent.sequencer);
        #100ns; // Wait for transactions to complete
        `uvm_info("FIFO_TEST", "Dropping objection, run phase ending", UVM_LOW)
        phase.drop_objection(this);
    endtask
endclass
