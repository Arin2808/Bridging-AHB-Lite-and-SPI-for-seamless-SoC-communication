// UVM driver for asynchronous FIFO

class fifo_driver extends uvm_driver #(fifo_transaction);
    `uvm_component_utils(fifo_driver)

    virtual fifo_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        `uvm_info("FIFO_DRIVER", "Constructor called", UVM_LOW)
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("FIFO_DRIVER", "Build phase started", UVM_LOW)
        if (!uvm_config_db#(virtual fifo_if)::get(this, "", "vif", vif))
            `uvm_fatal("NO_VIF", "Virtual interface not set for driver")
        else
            `uvm_info("FIFO_DRIVER", "Virtual interface set for driver", UVM_LOW)
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        `uvm_info("FIFO_DRIVER", "Run phase started", UVM_LOW)
        forever begin
            fifo_transaction tx;
            @(posedge vif.wr_clk);
            seq_item_port.get_next_item(tx);
//             `uvm_info("FIFO_DRIVER", "Printing transaction req:", UVM_MEDIUM)
//             tx.print(); // This prints all fields of tx
            do_drive(tx);
            seq_item_port.item_done();
        end
    endtask

    task do_drive(fifo_transaction tx);
        vif.wr_en = tx.wr_en;
        vif.wr_data = tx.wr_data;
        @(posedge vif.rd_clk);
        vif.rd_en = tx.rd_en;
        `uvm_info("FIFO_DRIVER", "Driving transaction:", UVM_MEDIUM)
        tx.print();
    endtask
endclass
