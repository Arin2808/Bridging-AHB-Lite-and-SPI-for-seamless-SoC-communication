// -----------------------------------------------------------------------------
// Environment: UVM Environment Container
// -----------------------------------------------------------------------------
// This class defines the top-level UVM environment. It instantiates and connects
// the protocol agents (AHB and SPI) and the scoreboard. The environment manages
// the build and connect phases for all components, enabling stimulus generation,
// monitoring, and checking in a UVM testbench.
// -----------------------------------------------------------------------------

class Environment extends uvm_env;
    // AHB agent for driving and monitoring AHB transactions
    AHB_Agent ahb_agent;
    // SPI agent for driving and monitoring SPI transactions
    SPI_Agent spi_agent;
    // Scoreboard for checking correctness of transactions
    Scoreboard scb;

    // Register this environment with the UVM factory
    `uvm_component_utils(Environment)

    // Constructor: initializes the environment
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // UVM build_phase: create all sub-components
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ahb_agent = AHB_Agent::type_id::create("ahb_agent", this);      // Create AHB agent
        spi_agent = SPI_Agent::type_id::create("spi_agent", this);      // Create SPI agent
        scb = Scoreboard::type_id::create("scb", this);                 // Create scoreboard
        `uvm_info("ENV", "Build phase completed: AHB and SPI agents, scoreboard created.", UVM_MEDIUM)
    endfunction

    // UVM connect_phase: connect analysis ports/exports
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        spi_agent.monitor.mon_ap.connect(scb.mon_export);               // Connect SPI monitor to scoreboard
        ahb_agent.driver.drv_ap.connect(scb.drv_export);                // Connect AHB driver to scoreboard
        `uvm_info("ENV", "Connect phase completed: Analysis ports connected to scoreboard.", UVM_MEDIUM)
    endfunction
endclass
