module instructionMemory(
    input wire [31:0] addr,        // Address input
    output wire [31:0] instruction // Instruction output
);
    /*
     * Instruction Memory - Pipeline Stage: Instruction Fetch (IF)
     * 
     * This module represents the instruction memory in the first stage of the pipeline.
     * It stores the program instructions and outputs them based on the PC address.
     * Each instruction is 32 bits wide, and the memory can store 1024 instructions.
     * The module is read-only and combinational, providing instructions immediately
     * without any clock delay.
     */

    // Memory array (1024 instructions, each 32 bits)
    reg [31:0] memory [0:1023];

    // Combinational read operation
    assign instruction = memory[addr[9:0]];  // Use lower 10 bits for addressing

    // Initialize memory
    initial begin
        // Initialize all memory locations to NOP
        integer i;
        for (i = 0; i < 1024; i = i + 1)
            memory[i] = 32'h00000000;
    end

endmodule
