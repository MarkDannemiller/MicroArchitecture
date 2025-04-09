module WB_stage(
    // Data inputs
    input wire [31:0] ALU_result,   // ALU computation result from EX stage - used for most arithmetic/logical operations
    input wire [31:0] mem_data,     // Data read from memory in EX stage - used for load operations
    input wire N_xor_V,             // N XOR V condition flag from EX stage - used for SLT (Set Less Than) instruction
    // Control inputs
    input wire [1:0] MD,            // Memory Data select control - determines data source for register write: 00=ALU, 01=memory, 10=N⊕V
    input wire RW,                  // Register Write enable - controls whether register file is written to
    input wire [4:0] DR,            // Destination Register number - specifies which register to write to (R0-R31)
    // Outputs
    output wire [31:0] WB_data,     // Final data value to write to register file - selected from the three input sources
    output wire [4:0] WB_addr,      // Register address to write to (simply passes through DR)
    output wire WB_en               // Final write enable signal for register file (simply passes through RW)
);
    /*
     * Write Back (WB) Stage - Fourth and final stage of the 4-stage RISC CPU pipeline
     *
     * Purpose and Operation:
     * ---------------------
     * The WB stage is responsible for selecting the appropriate data to write back
     * to the register file and generating the control signals for the write operation.
     * 
     * This stage represents the completion of instruction execution and is where
     * the CPU finally updates the architectural state visible to the programmer.
     * 
     * Key Functions:
     * -------------
     * 1. Data Selection - Choose the appropriate value to write to registers:
     *    - ALU result for arithmetic, logical, and shift operations
     *    - Memory data for load operations
     *    - N⊕V flag for SLT (Set Less Than) instruction
     * 
     * 2. Register Write Control - Generate the signals needed to:
     *    - Specify which register to write to (WB_addr from DR)
     *    - Enable or disable the write operation (WB_en from RW)
     * 
     * The MuxD component has three inputs selected by the 2-bit MD control signal:
     * - MD=00: ALU_result (from arithmetic/logical operations)
     * - MD=01: mem_data (from load operations)
     * - MD=10: N⊕V flag (extended to 32 bits for SLT instruction)
     *
     * Note: When RW=0, no register write occurs regardless of other signals.
     */

    // MuxD - Write Back Data Selection Multiplexer
    // Selects the appropriate data source for register write operations
    // based on the type of instruction being executed
    muxD mux_d(
        .ALU_result(ALU_result),   // ALU computation result (for arithmetic/logical operations)
        .mem_data(mem_data),       // Memory data (for load operations)
        .N_xor_V(N_xor_V),         // N XOR V condition flag (for SLT instruction)
        .MD(MD),                   // Memory Data select control signal (2 bits)
        .out(WB_data)              // Selected data output to register file
    );

    // Write back control signals - Pass through from pipeline registers
    // These signals connect directly to the register file to control the write operation
    assign WB_addr = DR;           // Destination Register number becomes the write address
    assign WB_en = RW;             // Register Write enable becomes the write enable signal
    
    // Debug output - Displays register write information when enabled
    // This helps track the flow of data from the pipeline to the register file
    always @(*) begin
        if (RW)
            if (`DEBUG_WB) $display("WB DEBUG: Write enabled DR=%d WB_data=%h", DR, WB_data);
    end

endmodule 