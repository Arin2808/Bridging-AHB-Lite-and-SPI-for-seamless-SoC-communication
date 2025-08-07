// -----------------------------------------------------------------------------
// AHB_Sequence: UVM Sequence for Generating AHB Transactions
// -----------------------------------------------------------------------------
// This class implements a UVM sequence that creates and randomizes AHB_Transaction
// objects. The sequence starts the transaction, randomizes its fields, prints debug
// info, and finishes the item. Sequences are used to generate stimulus for the DUT
// via the sequencer and driver in the agent.
// -----------------------------------------------------------------------------

class AHB_Sequence extends uvm_sequence #(AHB_Transaction);
    // Register this sequence with the UVM factory
    `uvm_object_utils(AHB_Sequence)

    // Constructor: initializes the sequence with a name
    function new(string name = "AHB_Sequence");
        super.new(name);
    endfunction

    // Sequence body: creates, randomizes, and sends a transaction
    task body();
//         `uvm_info("SEQ", "Starting AHB sequence body.", UVM_MEDIUM)
        AHB_Transaction trans;
        trans = AHB_Transaction::type_id::create("trans"); // Create transaction object
        start_item(trans);                                 // Start transaction
        if (!trans.randomize()) begin                      // Randomize transaction fields
            `uvm_fatal("SEQ", "Transaction randomization failed")
        end
        // UVM info message for debug visibility
        `uvm_info("SEQ", $sformatf("Generated: %s", trans.convert2string()), UVM_MEDIUM)
        finish_item(trans);                                // Finish transaction
    endtask
endclass