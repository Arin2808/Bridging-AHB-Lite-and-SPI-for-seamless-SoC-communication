// -----------------------------------------------------------------------------
// Scoreboard: UVM Scoreboard for Data Checking
// -----------------------------------------------------------------------------
// This class implements a UVM scoreboard to compare expected and actual data
// from the DUT. It receives transactions from the driver and monitor via analysis
// ports, stores them in TLM FIFOs, and checks correctness in the run_phase.
// UVM info and error messages provide debug and pass/fail reporting.
// -----------------------------------------------------------------------------

class Scoreboard extends uvm_scoreboard;
    // Analysis exports for connecting to monitor and driver
    uvm_analysis_export #(bit [39:0]) mon_export;
    uvm_analysis_export #(AHB_Transaction) drv_export;
    // TLM FIFOs for storing incoming transactions
    uvm_tlm_analysis_fifo #(bit [39:0]) mon_fifo;
    uvm_tlm_analysis_fifo #(AHB_Transaction) drv_fifo;

    // UVM factory registration macro
    `uvm_component_utils(Scoreboard)

    // Constructor: initializes analysis ports and FIFOs
    function new(string name, uvm_component parent);
        super.new(name, parent);
        mon_export = new("mon_export", this);
        drv_export = new("drv_export", this);
        mon_fifo = new("mon_fifo", this);
        drv_fifo = new("drv_fifo", this);
    endfunction

    // UVM build_phase: connect analysis exports to FIFOs
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        mon_export.connect(mon_fifo.analysis_export);
        drv_export.connect(drv_fifo.analysis_export);
        `uvm_info("SCB", "Build phase completed: Analysis exports connected to FIFOs.", UVM_MEDIUM)
    endfunction

    // UVM run_phase: compare expected and actual transactions
    task run_phase(uvm_phase phase);
//         super.run_phase(phase);
      AHB_Transaction expected_trans;
//         `uvm_info("SCB", "Run phase started: Waiting for transactions.", UVM_MEDIUM)
        bit [39:0] actual;
        bit [31:0] expected_data;
        bit [31:0] actual_data;
        

        forever begin
            drv_fifo.get(expected_trans); // Get expected transaction from driver
            mon_fifo.get(actual);         // Get actual data from monitor
            // Data alignment based on transfer size
            case (expected_trans.hsize)
                3'b000: expected_data = {24'h0, expected_trans.hwdata[7:0]}; // Byte
                3'b001: expected_data = {16'h0, expected_trans.hwdata[15:0]}; // Half-word
                3'b010: expected_data = expected_trans.hwdata; // Word
                default: begin
                    `uvm_error("SCB", $sformatf("Invalid HSIZE: %b", expected_trans.hsize))
                    continue;
                end
            endcase
            actual_data = actual[31:0]; // Extract actual data from monitor packet
            // Debug info for expected and actual values
            `uvm_info("SCB", $sformatf("Expected: ADDR=%h, DATA=%h", expected_trans.haddr, expected_data), UVM_MEDIUM)
            `uvm_info("SCB", $sformatf("Actual: ADDR=%h, DATA=%h", actual[39:32], actual_data), UVM_MEDIUM)
            // Compare address and data, report pass/fail
            if (expected_trans.haddr == actual[39:32] && expected_data == actual_data) begin
                `uvm_info("SCB", "PASS: Write transaction verified", UVM_LOW)
            end else begin
                `uvm_error("SCB", $sformatf("FAIL: Mismatch - Expected ADDR=%h, DATA=%h; Actual ADDR=%h, DATA=%h",
                                            expected_trans.haddr, expected_data, actual[39:32], actual_data))
            end
        end
    endtask
endclass