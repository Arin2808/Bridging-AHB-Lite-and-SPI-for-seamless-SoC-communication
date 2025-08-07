// -----------------------------------------------------------------------------
// AHB_Agent: UVM Agent for AHB Bus Transactions
// -----------------------------------------------------------------------------
// This class implements a UVM agent for the AHB protocol. An agent encapsulates
// the sequencer (which generates transactions), the driver (which drives signals
// to the DUT), and optionally a monitor. The agent manages connections between
// sequencer and driver, and is registered as a UVM component.
// -----------------------------------------------------------------------------

class AHB_Agent extends uvm_agent;
    // UVM sequencer for generating AHB_Transaction sequence items
    uvm_sequencer #(AHB_Transaction) sequencer;
    // Driver for applying transactions to the DUT
    AHB_Driver driver;

    // UVM factory registration macro for this agent
    `uvm_component_utils(AHB_Agent)

    // Constructor: initializes the agent with a name and parent component
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // UVM build_phase: creates sequencer and driver components
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        sequencer = uvm_sequencer#(AHB_Transaction)::type_id::create("sequencer", this);
        driver = AHB_Driver::type_id::create("driver", this);
        // UVM info message: agent build phase completed
        `uvm_info("AHB_AGENT", "Build phase completed: sequencer and driver created.", UVM_MEDIUM)
    endfunction

    // UVM connect_phase: connects the sequencer to the driver's seq_item_port
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        driver.seq_item_port.connect(sequencer.seq_item_export);
        // UVM info message: agent connect phase completed
        `uvm_info("AHB_AGENT", "Connect phase completed: sequencer connected to driver.", UVM_MEDIUM)
    endfunction
endclass