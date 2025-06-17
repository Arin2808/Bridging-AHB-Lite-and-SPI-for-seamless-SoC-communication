# AHB-Lite to SPI Bridge: Design & Verification

This project implements and verifies an efficient bridge between AHB-Lite and SPI protocols, enabling seamless communication between high-speed AHB-based SoC systems and SPI peripherals. The design focuses on robust protocol conversion, data integrity, and reliable integration for SoC architectures.

## Features

- **AHB-Lite to SPI Protocol Conversion:** Converts AHB-Lite transactions to SPI-compatible operations and vice versa.
- **Asynchronous FIFO Buffers:** Ensures safe and efficient data transfer across different clock domains.
- **Data Integrity:** Implements error handling and data alignment for reliable communication.
- **SystemVerilog UVM-style Verification:** Includes testbenches, drivers, monitors, generators, and transactions for comprehensive functional verification.

## Directory Structure

```
AHB/
  AHB_slave.v         # AHB slave control unit
Asynchronous FIFO/
  design/
    async_fifo_ctrl.v    # Asynchronous FIFO controller
    async_fifo_top.v     # Top-level FIFO module
    fifo_mem.v           # FIFO memory block
    gray_code.v          # Gray code converters
    sync_flop.v          # Synchronizer flops
    test_async_fifo.v    # FIFO testbench
  verification/
    fifo_read_if.sv      # Read interface
    fifo_write_if.sv     # Write interface
    fifo_transaction.sv  # Transaction object
    fifo_generator.sv    # Transaction generator
    fifo_driver.sv       # Driver for FIFO verification
    fifo_monitor.sv      # Monitor for FIFO activity
```

## Getting Started

1. **Clone the repository**
2. **Simulate the design** using your preferred SystemVerilog simulator (e.g., ModelSim, Questasim).
3. **Run testbenches** in `Asynchronous FIFO/design/test_async_fifo.v` to verify functionality.

## Authors

- Ekansh Bansal ([ekanshbansal](https://github.com/ekb0412))
- Arin Singh ([arinsingh](https://github.com/Arin2808))
- Ayushmoy Datta ([ayushmoydatta](https://github.com/aushmoy))
- Satyam Triphati ([satyamtripathi](https://github.com/SatyamTripathi13))

