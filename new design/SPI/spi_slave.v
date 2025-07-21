`timescale 1ns / 1ps

module spi_slave (
    input wire clk,          // System clock
    input wire rst,          // Active-high reset
    input wire sclk,         // SPI clock from master
    input wire cs,           // Chip select from master (active low)
    input wire mosi,         // Master Out Slave In
    output reg miso          // Master In Slave Out
);

    reg [5:0]  bit_cnt;
    reg [40:0] shift_reg_in;
    reg [31:0] shift_reg_out;
    reg [31:0] rx_data;
    reg [31:0] tx_data;
    reg [6:0]  addr;
    reg        wr_rd_en;
    reg        sclk_prev;
    reg        active;

    reg [31:0] mem [0:127];

    always @(posedge clk) begin
        if (rst) begin
            shift_reg_in  <= 41'b0;
            shift_reg_out <= 32'b0;
            rx_data       <= 32'b0;
            tx_data       <= 32'b0;
            addr          <= 7'b0;
            wr_rd_en      <= 1'b0;
            miso          <= 1'b0;
            bit_cnt       <= 6'd0;
            sclk_prev     <= 1'b0;
            active        <= 1'b0;
        end else begin
            sclk_prev <= sclk;

            if (!cs && !active) begin
                active       <= 1'b1;
                bit_cnt      <= 6'd40;
                shift_reg_in <= 41'b0;
                shift_reg_out <= 32'b0;
                miso         <= 1'b0;
            end

            if (cs) begin
                active    <= 1'b0;
                miso      <= 1'b0;
                bit_cnt   <= 6'd0;
                if (bit_cnt == 6'd0 && active) begin
                    wr_rd_en <= shift_reg_in[40];
                    addr     <= shift_reg_in[39:33];
                    rx_data  <= shift_reg_in[32:1];
                    if (shift_reg_in[40]) begin
                        mem[shift_reg_in[39:33]] <= shift_reg_in[32:1];
                    end else begin
                        tx_data <= mem[shift_reg_in[39:33]];
                    end
                end
            end

            if (active && !cs) begin
                if (!sclk_prev && sclk) begin
                    shift_reg_in <= {shift_reg_in[39:0], mosi};
                    if (bit_cnt == 6'd33) begin
                        wr_rd_en <= shift_reg_in[40];
                        addr     <= shift_reg_in[39:33];
                        if (!shift_reg_in[40]) begin
                            shift_reg_out <= mem[shift_reg_in[39:33]];
                        end
                    end
                    if (bit_cnt > 6'd0) begin
                        bit_cnt <= bit_cnt - 1;
                    end
                end

                if (sclk_prev && !sclk) begin
                    if (wr_rd_en) begin
                        miso <= 1'b0;
                    end else if (bit_cnt >= 6'd9 && bit_cnt <= 6'd40) begin
                        miso <= shift_reg_out[40 - bit_cnt];
                    end else begin
                        miso <= 1'b0;
                    end
                end
            end
        end
    end

endmodule