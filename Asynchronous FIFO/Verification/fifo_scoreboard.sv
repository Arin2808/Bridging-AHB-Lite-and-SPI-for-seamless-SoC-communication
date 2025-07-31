// UVM scoreboard for asynchronous FIFO

class fifo_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(fifo_scoreboard)

    uvm_analysis_imp #(fifo_transaction, fifo_scoreboard) port_mon;
    uvm_analysis_imp #(fifo_transaction, fifo_scoreboard) port_drv;

    uvm_tlm_analysis_fifo #(bit [40:0]) port_mon_fifo;
    uvm_tlm_analysis_fifo #(bit [40:0]) port_drv_fifo;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        port_mon = new("port_mon", this);
        port_drv = new("port_drv", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("FIFO_SCOREBOARD", "Entered build phase", UVM_NONE)
        port_mon_fifo = new("port_mon_fifo", this);
        port_drv_fifo = new("port_drv_fifo", this);
    endfunction

    function void write(fifo_transaction tx);
        `uvm_info("FIFO_SCOREBOARD", "Entering write implementation", UVM_NONE)
//         tx.print();
        case (tx.source_port)
            "fifo_monitor": begin
                `uvm_info(get_type_name(), $sformatf("Received transaction from Monitor: wr_data=%h", tx.wr_data), UVM_LOW);
                port_mon_fifo.write(tx.wr_data);
            end
            "fifo_driver": begin
                `uvm_info(get_type_name(), $sformatf("Received transaction from Driver: wr_data=%h", tx.wr_data), UVM_LOW);
                port_drv_fifo.write(tx.wr_data);
            end
            default: begin
                `uvm_warning(get_type_name(), $sformatf("Received transaction from unknown source: %s", tx.source_port));
            end
        endcase
    endfunction

    task run_phase(uvm_phase phase);
        bit [40:0] req_mon_data, req_drv_data;
        `uvm_info(get_type_name(), "Executing final phase", UVM_MEDIUM)
        super.run_phase(phase);
        forever begin
            port_mon_fifo.get(req_mon_data);
            port_drv_fifo.get(req_drv_data);
            `uvm_info("FIFO_SCOREBOARD", $sformatf("Monitor wr_data= %h, Driver wr_data= %h", req_mon_data, req_drv_data), UVM_NONE)
            if (req_mon_data == req_drv_data) begin
                `uvm_info(get_type_name(), "*****PASS***********", UVM_LOW)
            end
            else begin
                `uvm_info(get_type_name(), "********FAIL********", UVM_LOW)
            end
        end
    endtask
endclass