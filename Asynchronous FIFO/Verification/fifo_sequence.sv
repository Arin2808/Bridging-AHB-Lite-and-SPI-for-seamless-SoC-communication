// UVM sequence for generating stimulus

class fifo_sequence extends uvm_sequence #(fifo_transaction);
    `uvm_object_utils(fifo_sequence)

    function new(string name = "fifo_sequence");
        super.new(name);
        `uvm_info("SEQ", "Constructor called", UVM_LOW)
    endfunction

    task body();
      fifo_transaction tx;
        `uvm_info("SEQ", "Sequence body started", UVM_LOW)
        
        repeat (10) begin
            tx = fifo_transaction::type_id::create("tx");
            start_item(tx);
            assert(tx.randomize());
            `uvm_info("SEQ", $sformatf("Transaction randomized: wr_en=%0b wr_data=%0h rd_en=%0b full=%0b empty=%0b",
                tx.wr_en, tx.wr_data, tx.rd_en, tx.full, tx.empty), UVM_MEDIUM)
            finish_item(tx);
        end
        `uvm_info("SEQ", "Sequence body completed", UVM_LOW)
    endtask
endclass
