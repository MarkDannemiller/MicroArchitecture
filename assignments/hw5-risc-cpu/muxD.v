module muxD(
    input wire [31:0] ALU_result,  // ALU output
    input wire [31:0] mem_data,    // Memory data
    input wire N_xor_V,            // N⊕V for SLT instruction
    input wire [1:0] MD,           // Memory Data select (2 bits)
    output reg [31:0] out          // Selected output
);
    /*
     * Multiplexer D - Pipeline Stage: Write Back (WB)
     * 
     * This multiplexer selects the data to be written back to registers.
     * It has three inputs selected by 2-bit MD control:
     * - MD = 00: ALU_result - Result from arithmetic/logical operations
     * - MD = 01: mem_data - Data loaded from memory
     * - MD = 10: {31'b0, N⊕V} - Sign bit for SLT instruction
     * 
     * In the diagram, this is shown at the bottom with inputs 0, 1, and 2.
     */

    // Select between ALU result, memory data, and N⊕V
    always @(*) begin
        case (MD)
            2'b00: out = ALU_result;            // ALU result
            2'b01: out = mem_data;              // Memory data
            2'b10: out = {31'b0, N_xor_V};      // N⊕V sign extended for SLT
            default: out = ALU_result;          // Default
        endcase
    end

endmodule
