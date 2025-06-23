class fifo_monitor #(parameter DATA_WIDTH = 41);

    // Transaction handle
    fifo_transaction #(DATA_WIDTH) fifo_pkt;

    // Mailbox to scoreboard
    mailbox mon2sb;
    event mon_done;

    // Both interfaces
    virtual fifo_write_if.wr_mon_mp wr_mon_vif;
    virtual fifo_read_if.rd_mon_mp  rd_mon_vif;

    string name;
    typedef enum {WRITE, READ} mon_type_e;
    mon_type_e mon_type;

    // Constructor
    function new(string name = "fifo_monitor", mon_type_e mon_type = WRITE);
        this.name = name;
        this.mon_type = mon_type;
        log("FIFO_MONITOR_BUILD");
    endfunction

    // Log function
    function void log(string message);
        $display("[%t] INFO [MON %s]: %s", $time, this.name, message);
    endfunction

    // Connect function
    function void connect(mailbox mon2sb, event mon_done, virtual fifo_write_if.wr_mon_mp wr_mon_vif, virtual fifo_read_if.rd_mon_mp  rd_mon_vif);
        this.mon2sb = mon2sb;
        this.mon_done = mon_done;
        this.wr_mon_vif = wr_mon_vif;
        this.rd_mon_vif = rd_mon_vif;
        log("FIFO_MONITOR_CONNECT");
    endfunction

    // Run task: sample data for 'itration' cycles
    task run(input int itration);
        forever begin
            log("FIFO_MONITOR_RUN_START");
            if (mon_type == WRITE) begin
                while(wr_mon_vif.wr_rst_n == 1'b0) @(wr_mon_vif.cb_monitor);
                repeat(itration) sample_write();
            end else begin
                while(rd_mon_vif.rd_rst_n == 1'b0) @(rd_mon_vif.cb_monitor);
                repeat(itration) sample_read();
            end
            -> mon_done;
            log("FIFO_MONITOR_EVENT_TRIGGERED");
        end
    endtask

    // Sample data from interface and send to scoreboard
    task sample_write();
        @(wr_mon_vif.cb_monitor);
        fifo_pkt = new();
        fifo_pkt.wr_en  = wr_mon_vif.cb_monitor.wr_en;
        fifo_pkt.wdata  = wr_mon_vif.cb_monitor.wr_data;
        fifo_pkt.display("MON_WRITE");
        mon2sb.put(fifo_pkt);
    endtask

    task sample_read();
        @(rd_mon_vif.cb_monitor);
        fifo_pkt = new();
        fifo_pkt.rd_en  = rd_mon_vif.cb_monitor.rd_en;
        fifo_pkt.rdata  = rd_mon_vif.cb_monitor.rd_data;
        fifo_pkt.display("MON_READ");
        mon2sb.put(fifo_pkt);
    endtask

endclass