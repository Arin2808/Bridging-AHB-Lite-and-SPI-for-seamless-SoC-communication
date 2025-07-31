// UVM environment for asynchronous FIFO

class fifo_env extends uvm_env;
    `uvm_component_utils(fifo_env)

    fifo_agent agent;
    fifo_scoreboard scoreboard;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        `uvm_info("FIFO_ENV", "Constructor called", UVM_LOW)
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("FIFO_ENV", "Build phase started", UVM_LOW)
        agent = fifo_agent::type_id::create("agent", this);
        scoreboard = fifo_scoreboard::type_id::create("scoreboard", this);
        `uvm_info("FIFO_ENV", "Agent and scoreboard created", UVM_LOW)
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        `uvm_info("FIFO_ENV", "Connect phase started", UVM_LOW)
        agent.agent_mon_export.connect(scoreboard.port_mon);
        agent.agent_drv_export.connect(scoreboard.port_drv);
        `uvm_info("FIFO_ENV", "Monitor and driver analysis exports connected to scoreboard", UVM_LOW)
    endfunction
endclass
