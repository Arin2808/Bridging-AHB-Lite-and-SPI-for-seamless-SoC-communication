`timescale 1ns / 1ps

module spi_slave (
    input wire clk,       
    input wire rst,       
    input wire sclk,      
    input wire cs,        
    input wire mosi,      
    output reg miso,      
    output reg [15:0] rx_data, 
    input  wire [15:0] tx_data   
);

reg [3:0] bit_cnt;      
reg [15:0] shift_reg_in;  // Shift register for received data
reg [15:0] shift_reg_out; // Shift register for transmit data
reg sclk_prev;            // Stores previous SCLK value
reg active;               // Indicates if slave is active

always @(posedge clk) begin
    if (rst) begin
        rx_data <= 16'b0;
        shift_reg_in <= 16'b0;
        shift_reg_out <= 16'b0;
        miso <= 1'b0;
        bit_cnt <= 4'd0;
        sclk_prev <= 1'b0;
        active <= 1'b0;
    end else begin
        sclk_prev <= sclk;

        // Detect CS falling edge to start transmission
        if (!cs && !active) begin
            active <= 1'b1;
            bit_cnt <= 4'd15;
            shift_reg_out <= tx_data;
        end

        // If CS is high, we're idle
        if (cs) begin
            active <= 1'b0;
            miso <= 1'b0;
        end

        // While active and CS low
        if (active && !cs) begin
            // Rising edge of SCLK - sample MOSI
            if (!sclk_prev && sclk) begin
                shift_reg_in <= {shift_reg_in[14:0], mosi};
                bit_cnt <= bit_cnt - 1;
            end

            // Falling edge of SCLK - shift MISO
            if (sclk_prev && !sclk) begin
                miso <= shift_reg_out[15];
                shift_reg_out <= {shift_reg_out[14:0], 1'b0};
            end

            // If all 16 bits received
            if (bit_cnt == 0 && sclk_prev && !sclk) begin
                rx_data <= {shift_reg_in[14:0], mosi}; // Final bit
                active <= 1'b0;
            end
        end
    end
end

endmodule