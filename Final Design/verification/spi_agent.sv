// -----------------------------------------------------------------------------
// SPI_Agent: UVM Agent for SPI Bus Monitoring
// -----------------------------------------------------------------------------
// This class implements a UVM agent for the SPI protocol. The agent typically
// encapsulates the sequencer, driver, and monitor, but here only the monitor is
// shown. The agent manages creation and connection of protocol components and is
// registered as a UVM component for factory automation.
// -----------------------------------------------------------------------------

class SPI_Agent extends uvm_agent;
    // SPI monitor for observing SPI transactions
    SPI_Monitor monitor;

    // UVM factory registration macro for this agent
    `uvm_component_utils(SPI_Agent)

    // Constructor: initializes the agent with a name and parent component
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // UVM build_phase: creates the monitor component
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        monitor = SPI_Monitor::type_id::create("monitor", this);
        // UVM info message: agent build phase completed
        `uvm_info("SPI_AGENT", "Build phase completed: monitor created", UVM_MEDIUM);
    endfunction
endclass