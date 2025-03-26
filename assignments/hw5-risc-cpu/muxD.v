module muxD(
    input wire [15:0] ALU_result,  // ALU output
    input wire [15:0] mem_data,    // Memory data
    input wire [15:0] PC_2,        // PC-2 value
    input wire MD,                 // Memory Data select
    output wire [15:0] out         // Selected output
);
    /*
     * Multiplexer D - Pipeline Stage: Write Back (WB)
     * 
     * This multiplexer selects the data to be written back to registers:
     * - ALU_result: Result from arithmetic/logical operations
     * - mem_data: Data loaded from memory
     * - PC_2: Return address for jump-and-link instructions
     * 
     * It operates in the Write Back stage to select the appropriate
     * data source for register file writes. The selection is controlled
     * by the MD signal from the instruction decoder. This multiplexer
     * is crucial for completing the data path for different instruction
     * types (ALU ops, loads, and jumps).
     */

    // Select between ALU result, memory data, and PC-2 based on MD
    assign out = MD ? mem_data : ALU_result;

endmodule
