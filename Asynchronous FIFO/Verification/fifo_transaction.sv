// UVM transaction class for asynchronous FIFO

class fifo_transaction extends uvm_sequence_item;
    randc bit [40:0] wr_data; // Matches DATA_WIDTH=41
    rand bit wr_en;
    rand bit rd_en;
    bit [40:0] rd_data;
    bit full;
    bit empty;

    `uvm_object_utils_begin(fifo_transaction)
        `uvm_field_int(wr_data, UVM_ALL_ON)
        `uvm_field_int(wr_en, UVM_ALL_ON)
        `uvm_field_int(rd_en, UVM_ALL_ON)
        `uvm_field_int(rd_data, UVM_ALL_ON)
        `uvm_field_int(full, UVM_ALL_ON)
        `uvm_field_int(empty, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "fifo_transaction");
        super.new(name);
    endfunction

    constraint wr_en_full {
        (full == 0) -> (wr_en == 1);
        (full == 1) -> (wr_en == 0);
    }
    constraint rd_en_empty {
        (empty == 0) -> (rd_en == 1);
        (empty == 1) -> (rd_en == 0);
    }
    constraint data {
        wr_data inside {[0:10]};
    }
endclass
