//`include "debug_defs.v"

module dataMemory(
    input wire clk,              // Clock input
    input wire [31:0] addr,      // Address input
    input wire [31:0] data_in,   // Data input
    input wire MW,               // Memory Write enable
    output reg [31:0] data_out   // Data output
);
    /*
     * Data Memory - Pipeline Stage: Execute (EX)
     * 
     * It provides:
     * - Synchronous write operations (on positive clock edge when MW is high)
     * - Asynchronous read operations (combinational, no clock required)
     * 
     * The memory contains 1024 words, each 32 bits wide.
     * Address space is byte-addressable but word-aligned (uses lower 10 bits).
     * Data is stored in the memory on the positive clock edge when MW is high.
     */

    // Memory array (1024 words, each 32 bits)
    reg [31:0] memory [0:1023];
    integer i;  // Index for memory array


    // Memory read operation (combinational)
    always @(*) begin
        if (addr[31:10] == 22'h0) begin  // Check if address is in valid range
            data_out = memory[addr[9:0]];
            if (`DEBUG_MEM) $display("MEMORY DEBUG: READ addr=%h[%d], data=%h", addr, addr[9:0], memory[addr[9:0]]);
        end else begin
            data_out = 32'h0;  // Return 0 for out-of-range addresses
        end
    end

    // Memory write operation (synchronous)
    always @(posedge clk) begin
        if (MW && addr[31:10] == 22'h0) begin  // Write if enabled and address is valid
            memory[addr[9:0]] <= data_in;
            if (`DEBUG_MEM) $display("MEMORY DEBUG: STORE addr=%h[%d], data=%h, MW=%b", addr, addr[9:0], data_in, MW);
        end
    end

    // Initialize memory with test values
    initial begin
        for (i = 0; i < 1024; i = i + 1)
            memory[i] = 32'h00000000;
    end

endmodule
