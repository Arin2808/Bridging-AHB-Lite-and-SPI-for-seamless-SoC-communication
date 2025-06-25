# AHB-Lite to SPI Bridge: Design & Verification

This project presents a comprehensive solution for bridging AHB-Lite and SPI protocols, facilitating seamless communication between high-speed AHB-based System-on-Chip (SoC) systems and a wide range of SPI peripherals. The bridge is designed to ensure robust protocol conversion, maintain data integrity, and provide reliable integration within complex SoC architectures. The implementation leverages asynchronous FIFO buffers to safely transfer data across different clock domains, and the entire design is rigorously verified using SystemVerilog and UVM-style methodologies.

## Key Features

- **Seamless Protocol Bridging:**  
  Efficiently translates AHB-Lite bus transactions into SPI-compatible operations, enabling direct interfacing between SoC masters and SPI slave devices without manual intervention or protocol mismatches.

- **Asynchronous FIFO Buffers:**  
  Integrates dual-clock FIFO buffers to safely and efficiently transfer data between the AHB-Lite and SPI clock domains. This ensures reliable data passage even when the two domains operate at different frequencies.

- **Robust Data Integrity:**  
  Implements comprehensive error detection, data alignment, and correction mechanisms to guarantee that data transferred between protocols remains accurate and consistent.

- **Flexible and Scalable Architecture:**  
  The modular design allows for easy customization and scaling, making it suitable for a variety of SoC applications and SPI device configurations.

- **Comprehensive Verification Environment:**  
  Includes a full suite of SystemVerilog UVM-style verification components such as testbenches, drivers, monitors, generators, and transaction objects. This ensures thorough functional verification and validation of the bridge under various scenarios.

- **Extensive Testbenches:**  
  Provides ready-to-use testbenches for both the asynchronous FIFO and the protocol bridge, enabling users to quickly simulate and validate the design using industry-standard tools like ModelSim or Questasim.

- **Clear Documentation and Collaboration:**  
  The project is well-documented, with clear instructions for setup, simulation, and verification. Contributions from multiple collaborators ensure a robust and well-reviewed codebase.

## Getting Started

1. **Clone the repository** to your local machine.
2. **Simulate the design** using your preferred SystemVerilog simulator (e.g., ModelSim, Questasim).
3. **Run the provided testbenches** to verify the functionality and robustness of the asynchronous FIFO and protocol bridge modules.

## Collaborators

- [Ekansh Bansal](https://github.com/ekb0412)
- [Arin Singh](https://github.com/Arin2808)
- [Ayushmoy Datta](https://github.com/aushmoy)
- [Satyam Triphati](https://github.com/SatyamTripathi13)

