// UVM scoreboard for asynchronous FIFO

class fifo_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(fifo_scoreboard)

    uvm_analysis_imp #(fifo_transaction, fifo_scoreboard) ap;
    bit [40:0] fifo_model [$];
    int fifo_depth = 16; // 2^ADDR_WIDTH (4) = 16

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void write(fifo_transaction tx);
        // Write operation
        if (tx.wr_en && !tx.full) begin
            fifo_model.push_back(tx.wr_data);
            `uvm_info("SCB", $sformatf("Write: %h, FIFO size: %0d", tx.wr_data, fifo_model.size()), UVM_MEDIUM)
        end
        // Read operation
        if (tx.rd_en && !tx.empty) begin
            bit [40:0] expected_data;
            if (fifo_model.size() > 0) begin
                expected_data = fifo_model.pop_front();
                if (expected_data != tx.rd_data)
                    `uvm_error("SCB", $sformatf("Mismatch! Expected: %h, Got: %h", expected_data, tx.rd_data))
                else
                    `uvm_info("SCB", $sformatf("Read: %h, FIFO size: %0d", tx.rd_data, fifo_model.size()), UVM_MEDIUM)
            end
        end
        // Check full/empty flags
        if (fifo_model.size() == fifo_depth && !tx.full)
            `uvm_error("SCB", "FIFO should be full")
        if (fifo_model.size() == 0 && !tx.empty)
            `uvm_error("SCB", "FIFO should be empty")
        `uvm_info("SCB", $sformatf("Scoreboard write completed. FIFO size: %0d", fifo_model.size()), UVM_MEDIUM)
    endfunction
endclass