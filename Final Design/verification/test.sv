// -----------------------------------------------------------------------------
// AHB_SPI_Test: UVM Test for AHB to SPI Bridge Verification
// -----------------------------------------------------------------------------
// This class implements the top-level UVM test. It creates the environment and
// sequence, starts the sequence on the AHB agent's sequencer, and manages the
// testbench objection for proper simulation control. The test ensures stimulus
// is generated and transactions are checked via the scoreboard.
// -----------------------------------------------------------------------------

class AHB_SPI_Test extends uvm_test;
    Environment env;         // UVM environment containing agents and scoreboard
    AHB_Sequence seq;        // Sequence to generate AHB transactions

    `uvm_component_utils(AHB_SPI_Test)

    // Constructor: initializes the test
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // UVM build_phase: create environment and sequence
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = Environment::type_id::create("env", this);      // Create environment
        seq = AHB_Sequence::type_id::create("seq");           // Create sequence
        `uvm_info("TEST", "Build phase completed: Environment and sequence created.", UVM_MEDIUM)
    endfunction

    // UVM run_phase: start sequence and manage simulation objection
    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        `uvm_info("TEST", "Run phase started: Starting AHB sequence.", UVM_MEDIUM)
        phase.raise_objection(this);                          // Raise objection to keep simulation running
        seq.start(env.ahb_agent.sequencer);                   // Start sequence on AHB agent's sequencer
        #3600; // Wait for SPI transaction to complete
        phase.drop_objection(this);                           // Drop objection to end simulation
    endtask
endclass