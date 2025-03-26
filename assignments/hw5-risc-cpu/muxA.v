module muxA(
    input wire [15:0] A_data,    // Register A data
    input wire [15:0] PC_1,      // PC-1 value
    input wire MA,               // Mux A select
    output wire [15:0] out       // Selected output
);
    /*
     * Multiplexer A - Pipeline Stage: Execute (EX)
     * 
     * This multiplexer selects between:
     * - Register A data (from ID stage)
     * - PC+1 value (for jump and link instructions)
     * 
     * It operates in the Execute stage to provide the first operand
     * to the Function Unit. The selection is controlled by the MA signal
     * from the instruction decoder.
     */

    // Select between A_data and PC_1 based on MA
    assign out = MA ? PC_1 : A_data;

endmodule
