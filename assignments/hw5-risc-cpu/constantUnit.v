module constantUnit(
    input wire [7:0] IM,     // Immediate value
    input wire CS,           // Constant Select (0: Zero-extend, 1: Sign-extend)
    output wire [15:0] out   // Extended immediate value
);
    /*
     * Constant Unit - Pipeline Stage: Decode and Operand Fetch (DOF)
     * 
     * This module handles immediate value extension in the DOF stage:
     * - Sign extension for signed immediate values (CS = 1)
     * - Zero extension for unsigned immediate values (CS = 0)
     * 
     * It operates in the Decode and Operand Fetch stage to prepare immediate
     * values for use in the Execute stage. The extension method is
     * controlled by the CS signal from the instruction decoder, ensuring
     * proper handling of signed and unsigned immediate values for
     * arithmetic and logical operations.
     */

    // Sign extension or zero extension based on CS
    assign out = CS ? {{8{IM[7]}}, IM} : {8'b00000000, IM};

endmodule
