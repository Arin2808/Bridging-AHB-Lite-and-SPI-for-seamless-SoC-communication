class fifo_generator #(parameter DATA_WIDTH = 41);

    // Transaction handle
    fifo_transaction #(DATA_WIDTH) fifo_pkt;

    // Mailbox for communication with driver
    mailbox gen2drv;

    // Event to signal completion
    event gen_done;

    string name;

    //log 
	function void log(string message);
		$display("[%t] INFO [GEN %s]: %s",$time, this.name, message);
	endfunction

    // Constructor
    function new(string name = "fifo_generator");
        this.name = name;
        log("FIFO_GENERATOR_BUILD");
    endfunction

    // Connect mailbox and event
    function void connect(mailbox gen2drv, event gen_done);
        this.mbx = mbx;
        this.gen_done = gen_done;
        log("FIFO_GENERATOR_CONNECT");
    endfunction

    // Run task: generate and send transactions
    task run(input int itration);
        for (int i = 0; i < itration; i++) begin
            fifo_pkt = new();
            assert(fifo_pkt.randomize());
            gen2drv.put(fifo_pkt);
            fifo_pkt.display($sformatf("GEN[%0d]", i));
        end
        -> gen_done;
    endtask

endclass