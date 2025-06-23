class fifo_driver #(parameter DATA_WIDTH = 41);

    // Transaction handle
    fifo_transaction #(DATA_WIDTH) fifo_pkt;

    // Mailboxes
    mailbox gen2drv;      // From generator
    mailbox drv2scb;      // To scoreboard

    // Event to signal completion
    event gen_done;

    // Virtual interfaces
    virtual fifo_write_if.wr_drv_mp wr_drv_vif;
    virtual fifo_read_if.rd_drv_mp  rd_drv_vif;

    string name;

    //log 
    function void log(string message);
        $display("[%t] INFO [GEN %s]: %s",$time, this.name, message);
    endfunction

    // Constructor
    function new(string name = "fifo_driver");
        this.name = name;
        log("FIFO_DRIVER_BUILD");
    endfunction

    // Connect mailboxes and interface
    function void connect(mailbox gen2drv, mailbox drv2scb, event gen_done, virtual fifo_write_if.wr_drv_mp wr_drv_vif, virtual fifo_read_if.rd_drv_mp rd_drv_vif);
        this.gen2drv = gen2drv;
        this.drv2scb = drv2scb;
        this.gen_done = gen_done;
        this.wr_drv_vif = wr_drv_vif;
        this.rd_drv_vif = rd_drv_vif;
        log("FIFO_DRIVER_CONNECT");
    endfunction

    // Run task: fork write and read, each for itration times
    task run(input int itration);
        fifo_pkt = new();
        fork
            write_proc(itration);
            read_proc(itration);
        join
    endtask

    // Write process: drives write transactions from mailbox
    task write_proc(input int itration);
        wait(gen_done.triggered);
        while(wr_drv_vif.wr_rst_n == 1'b0) @(wr_drv_vif.cb_driver);
        repeat(itration) begin
            @(wr_drv_vif.cb_driver);
            gen2drv.get(fifo_pkt);
            drv2scb.put(fifo_pkt);
            wr_drv_vif.cb_driver.wr_en   <= fifo_pkt.wr_en;
            wr_drv_vif.cb_driver.wr_data <= fifo_pkt.wdata;
            fifo_pkt.display("DRV_WRITE");
        end
        wr_drv_vif.cb_driver.wr_en <= 0;
    endtask

    // Read process: asserts rd_en for each iteration
    task read_proc(input int itration);
        wait(gen_done.triggered);
        while(rd_drv_vif.rd_rst_n == 1'b0) @(rd_drv_vif.cb_driver);
        repeat(itration) begin
            @(rd_drv_vif.cb_driver);
            gen2drv.get(fifo_pkt);
            drv2scb.put(fifo_pkt);
            rd_drv_vif.cb_driver.rd_en <= fifo_pkt.rd_en;
        end
        rd_drv_vif.cb_driver.rd_en <= 0;
    endtask

endclass