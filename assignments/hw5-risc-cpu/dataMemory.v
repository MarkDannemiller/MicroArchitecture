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


    // Combinational read operation
    always @(*) begin
        data_out = memory[addr[9:0]];  // Use lower 10 bits for addressing
    end

    // Synchronous write operation - explicitly on rising edge only
    always @(posedge clk) begin
        if (MW) begin
            memory[addr[9:0]] <= data_in;  // Write data to memory
            $display("MEMORY DEBUG: STORE addr=%h[%d], data=%h, MW=%b", addr, addr[9:0], data_in, MW);
        end
    end

    // Add debug display for every memory read
    always @(addr) begin
        $display("MEMORY DEBUG: READ addr=%h[%d], data=%h", addr, addr[9:0], memory[addr[9:0]]);
    end

    // Initialize memory with test values
    initial begin
        for (i = 0; i < 1024; i = i + 1)
            memory[i] = 32'h00000000;
    end

endmodule
