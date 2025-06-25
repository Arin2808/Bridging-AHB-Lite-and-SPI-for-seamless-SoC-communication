module AHB_master_ctrl (
    input         HCLK,
    input         HRESETn,
    input         start,         // Pulse to start a new transfer
    input         write,         // 1: write, 0: read
    input  [2:0]  burst,
    input  [3:0]  burst_len,
    input         HREADY,
    input         HRESP,        
    output reg [1:0] HTRANS,
    output reg       HWRITE,
    output reg       busy,
    output reg       next_beat,
    output reg       store_read,
    output reg       done
);

    localparam IDLE   = 2'b00;
    localparam NONSEQ = 2'b10;
    localparam SEQ    = 2'b11;

    reg [3:0] burst_count;
    reg       write_reg;
    reg [2:0] burst_reg;

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

            if (!busy && start) begin
                busy        <= 1'b1;
                burst_count <= 4'd0;
                write_reg   <= write;
                burst_reg   <= burst;
                HTRANS      <= NONSEQ; // First beat
                HWRITE      <= write;
            end else if (busy && HREADY) begin
                // Error handling: if HRESP is asserted, abort burst
                if (HRESP) begin
                    HTRANS <= IDLE;
                    busy   <= 1'b0;
                    done   <= 1'b1;
                end
                // Normal burst completion
                else if (burst_count == burst_len - 1) begin
                    HTRANS <= IDLE;
                    busy   <= 1'b0;
                    done   <= 1'b1;
                    if (!write_reg)
                        store_read <= 1'b1;
                end else begin
                    burst_count <= burst_count + 1;
                    HTRANS      <= SEQ; // Remain in SEQ for all remaining beats
                    next_beat   <= 1'b1;
                    if (!write_reg)
                        store_read <= 1'b1;
                end
            end else if (!busy) begin
                HTRANS <= IDLE;
            end
        end
    end

endmodule