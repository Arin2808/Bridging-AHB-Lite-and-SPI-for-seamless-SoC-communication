`timescale 1ns / 1ps
`include "spi_slave.v"
module spi_slave_tb;
    
    reg clk;              
    reg rst;              
    reg sclk;           
    reg cs;               
    reg mosi;             
    reg [15:0] tx_data;   
    
    // Outputs from the SPI slave
    wire miso;            // Master In, Slave Out
    wire [15:0] rx_data;  // Data received by slave
    
   
    spi_slave uut (
        .clk(clk),
        .rst(rst),
        .sclk(sclk),
        .cs(cs),
        .mosi(mosi),
        .miso(miso),
        .rx_data(rx_data),
        .tx_data(tx_data)
    );
    
    // System clock generation (50 MHz, 20ns period)
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end
    
    // SPI clock generation (5 MHz, 200ns period)
    initial begin
        sclk = 0;
        forever #100 sclk = ~sclk;
    end
    
  
    initial begin
       
        rst = 1;       
        cs = 1;          
        mosi = 0;         
        tx_data = 16'hA5A5; 
        #200;           
        
        // Test Case 1: Reset behavior
        rst = 0;          
        #200;            
        
        // Test Case 2: Full 16-bit transaction
        cs = 0;         
        #100;             
        
        // Send 16 bits via MOSI 
        mosi = 0; #200;   
        mosi = 1; #200;  
        mosi = 0; #200;   
        mosi = 1; #200;   
        mosi = 0; #200;   
        mosi = 1; #200;   
        mosi = 0; #200;   
        mosi = 1; #200;   
        mosi = 1; #200;   
        mosi = 0; #200;   
        mosi = 1; #200;   
        mosi = 0; #200;   
        mosi = 1; #200;   
        mosi = 0; #200;   
        mosi = 1; #200;   
        mosi = 0; #200;   
        
        #100;           
        cs = 1;           // Deassert chip select
        #200;             // Wait after transaction
        
        // Test Case 3: Partial transaction (aborted by CS)
        tx_data = 16'h1234; 
        cs = 0;          
        #100;             
        mosi = 0; #200;   
        mosi = 0; #200;   
        mosi = 0; #200;   
        cs = 1;           //reset transaction early
        #200;            
        
        // Test Case 4: Reset during transaction
        cs = 0;          
        #100;             
        mosi = 1; #200;   // Bit 15
        mosi = 0; #200;   // Bit 14
        rst = 1;          // reset mid-transaction
        #200;             // Hold reset
        rst = 0;          // Release reset
        #200;             
        
        // Test Case 5: Another full transaction to verify post-reset behavior
        tx_data = 16'hFF00; 
        cs = 0;          
        #100;
        mosi = 1; #200;   
        mosi = 1; #200;   
        mosi = 1; #200;   
        mosi = 1; #200;   
        mosi = 0; #200;   
        mosi = 0; #200;   
        mosi = 0; #200;   
        mosi = 0; #200;   
        mosi = 1; #200;   
        mosi = 0; #200;   
        mosi = 1; #200;   
        mosi = 0; #200;   
        mosi = 1; #200;   
        mosi = 0; #200;   
        mosi = 1; #200;   
        mosi = 0; #200;   
        #100;
        cs = 1;           
        #200;
        
       
        $display("Simulation completed successfully.");
        $finish;
    end
    
    
    initial begin
        $monitor("Time=%t | rst=%b | cs=%b | sclk=%b | mosi=%b | miso=%b | rx_data=%h | tx_data=%h",
                 $time, rst, cs, sclk, mosi, miso, rx_data, tx_data);
    end
    
  
    initial begin
        $dumpfile("spi_slave_tb.vcd");
        $dumpvars(0, spi_slave_tb);
    end
endmodule