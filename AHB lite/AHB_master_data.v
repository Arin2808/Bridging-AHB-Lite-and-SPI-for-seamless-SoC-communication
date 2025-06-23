module AHB_master_data (
    input         HCLK,
    input         HRESETn,
    input  [7:0]  addr_in,
    input  [2:0]  size_in,
    input  [2:0]  burst_in,
    input         write_in,
    input         start_in,
    input         next_beat,
    input         store_read,
    input  [31:0] HRDATA,
    output reg [7:0]  HADDR,
    output reg [2:0]  HSIZE,
    output reg [2:0]  HBURST,
    output reg [31:0] HWDATA,
    output reg [31:0] mem_out
);

    reg [31:0] mem [0:255];
    reg [7:0] addr_reg;
    reg [3:0] beat_count; // For wrapping calculation

    // Burst type localparams
    localparam BURST_SINGLE = 3'b000;
    localparam BURST_INCR   = 3'b001;
    localparam BURST_WRAP4  = 3'b010;
    localparam BURST_INCR4  = 3'b011;
    localparam BURST_WRAP8  = 3'b100;
    localparam BURST_INCR8  = 3'b101;
    localparam BURST_WRAP16 = 3'b110;
    localparam BURST_INCR16 = 3'b111;

    // Calculate wrap mask based on burst type and size
    function [7:0] wrap_mask(input [2:0] burst, input [2:0] size);
        case (burst)
            BURST_WRAP4:  wrap_mask = (4 << size) - 1;
            BURST_WRAP8:  wrap_mask = (8 << size) - 1;
            BURST_WRAP16: wrap_mask = (16 << size) - 1;
            default:      wrap_mask = 8'hFF; // No wrapping
        endcase
    endfunction

    // Memory initialization and address/beat management
    integer i;
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            for (i = 0; i < 256; i = i + 1)
                mem[i] <= i*2;
            addr_reg <= 8'h00;
            beat_count <= 0;
        end else if (start_in) begin
            addr_reg <= addr_in;
            beat_count <= 0;
        end else if (next_beat) begin
            beat_count <= beat_count + 1;
            // Address calculation for burst types
            case (burst_in)
                BURST_INCR, BURST_INCR4, BURST_INCR8, BURST_INCR16: begin
                    addr_reg <= addr_reg + (1 << size_in);
                end
                BURST_WRAP4, BURST_WRAP8, BURST_WRAP16: begin
                    // Wrapping: increment, then wrap using mask
                    addr_reg <= (addr_reg & ~wrap_mask(burst_in, size_in)) |
                                (((addr_reg + (1 << size_in)) & wrap_mask(burst_in, size_in)));
                end
                default: begin
                    // SINGLE or undefined: no increment
                    addr_reg <= addr_reg;
                end
            endcase
        end
        if (store_read)
            mem[addr_reg] <= HRDATA;
    end

    // Output assignments
    always @(*) begin
        HADDR  = addr_reg;
        HSIZE  = size_in;
        HBURST = burst_in;
        HWDATA = mem[addr_reg];
        mem_out = mem[addr_reg];
    end

endmodule