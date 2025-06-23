module AHB_master_ctrl (
    input         HCLK,
    input         HRESETn,
    input         start,         // Pulse to start a new transfer
    input         write,         // 1: write, 0: read
    input  [2:0]  burst,         // Burst type (SINGLE, INCR4, WRAP4, etc.)
    input  [3:0]  burst_len,     // Number of beats in the burst
    input         HREADY,        // Slave ready signal
    output reg [1:0] HTRANS,     // AHB transfer type (IDLE, NONSEQ, SEQ)
    output reg       HWRITE,     // Write/read indication
    output reg       busy,       // Indicates transfer in progress
    output reg       next_beat,  // Pulse to increment address/data in datapath
    output reg       store_read, // Pulse to store read data in datapath
    output reg       done        // Pulse when transfer is complete
);

    // AHB transfer type encodings
    localparam IDLE   = 2'b00;
    localparam NONSEQ = 2'b10;
    localparam SEQ    = 2'b11;

    // Internal registers
    reg [3:0] burst_count; // Counts number of beats in current burst
    reg       write_reg;   // Latches write/read mode for the burst
    reg [2:0] burst_reg;   // Latches burst type for the burst

    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            HTRANS      <= IDLE;
            HWRITE      <= 1'b0;
            busy        <= 1'b0;
            burst_count <= 4'd0;
            write_reg   <= 1'b0;
            burst_reg   <= 3'b000;
            next_beat   <= 1'b0;
            store_read  <= 1'b0;
            done        <= 1'b0;
        end else begin
            next_beat  <= 1'b0;
            store_read <= 1'b0;
            done       <= 1'b0;

            // Start a new transfer if not busy and start is asserted
            if (!busy && start) begin
                busy        <= 1'b1;
                burst_count <= 4'd0;
                write_reg   <= write;
                burst_reg   <= burst;
                HTRANS      <= NONSEQ; // First beat is always NONSEQ
                HWRITE      <= write;
            end 
            // If busy and slave is ready, proceed with burst
            else if (busy && HREADY) begin
                // If single transfer or last beat of burst
                if (burst_reg == 3'b000 || burst_count == burst_len - 1) begin
                    HTRANS <= IDLE;
                    busy   <= 1'b0;
                    done   <= 1'b1; // Pulse done
                    if (!write_reg)
                        store_read <= 1'b1; // Pulse store_read for last read beat
                end else begin
                    // Continue burst
                    burst_count <= burst_count + 1;
                    HTRANS      <= SEQ;     // Subsequent beats are SEQ
                    next_beat   <= 1'b1;    // Pulse to increment address/data
                    if (!write_reg)
                        store_read <= 1'b1; // Pulse store_read for each read beat
                end
            end
        end
    end

endmodule