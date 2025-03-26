module muxB(
    input wire [15:0] B_data,    // Register B data
    input wire [15:0] constant,  // Constant value
    input wire MB,               // Mux B select
    output wire [15:0] out       // Selected output
);
    /*
     * Multiplexer B - Pipeline Stage: Execute (EX)
     * 
     * This multiplexer selects between:
     * - Register B data (from ID stage)
     * - Immediate constant (from constant unit)
     * 
     * It operates in the Execute stage to provide the second operand
     * to the Function Unit. The selection is controlled by the MB signal
     * from the instruction decoder, allowing immediate operands for
     * arithmetic and logical operations.
     */

    // Select between B_data and constant based on MB
    assign out = MB ? constant : B_data;

endmodule
