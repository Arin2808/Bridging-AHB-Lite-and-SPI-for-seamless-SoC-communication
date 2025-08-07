// -----------------------------------------------------------------------------
// AHB_Transaction: UVM Sequence Item for AHB Bus Transactions
// -----------------------------------------------------------------------------
// This class defines the transaction object for AHB protocol in UVM.
// It contains all fields required for a single AHB transfer, including address,
// transfer size, write data, write/read control, and burst mode.
// Constraints ensure valid values for address, size, and burst type.
// The class is registered with the UVM factory and supports field automation
// for randomization and reporting. The convert2string function provides a
// readable string representation for debug and logging.
// -----------------------------------------------------------------------------

class AHB_Transaction extends uvm_sequence_item;
    rand bit [7:0]  haddr;       // AHB address
    rand bit [2:0]  hsize;       // AHB transfer size (0=BYTE, 1=HALFWORD, 2=WORD)
    rand bit [31:0] hwdata;      // AHB write data
    bit             hwrite;      // Write enable (1 for write)
    bit      [2:0]  hburst;      // Burst mode: single, incr, incr4, incr8

    // Constraints for valid transaction fields
    constraint valid_addr { haddr < 256; } // SPI slave address range
    constraint valid_size { hsize inside {0, 1, 2}; } // BYTE, HALFWORD, WORD
    constraint burst_mode { hburst inside {0, 1, 3, 5}; } // SINGLE, INCR, INCR4, INCR8

    // UVM field macros for factory registration and automation
    `uvm_object_utils_begin(AHB_Transaction)
        `uvm_field_int(haddr, UVM_ALL_ON)
        `uvm_field_int(hsize, UVM_ALL_ON)
        `uvm_field_int(hwdata, UVM_ALL_ON)
        `uvm_field_int(hwrite, UVM_ALL_ON)
    `uvm_object_utils_end

    // Constructor: initializes default values
    function new(string name = "AHB_Transaction");
        super.new(name);
        hwrite = 1; // Write transaction by default
        hburst = 0; // Single transaction by default
    endfunction

    // Converts transaction fields to a readable string for debug/logging
    function string convert2string();
        return $sformatf("HADDR=%h, HSIZE=%b, HWDATA=%h, HWRITE=%b", haddr, hsize, hwdata, hwrite);
    endfunction
endclass