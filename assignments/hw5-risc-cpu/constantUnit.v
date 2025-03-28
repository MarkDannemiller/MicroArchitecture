module constantUnit(
    input wire [14:0] IMM,    // 15-bit Immediate value
    input wire CS,            // Constant Select (0: Zero-extend, 1: Sign-extend)
    output wire [31:0] out    // Extended immediate value
);
    /*
     * Constant Unit - Pipeline Stage: Decode & Operand Fetch (DOF)
     * 
     * This module handles immediate value extension:
     * - Sign extension for signed immediate values (CS = 1)
     * - Zero extension for unsigned immediate values (CS = 0)
     * 
     * The immediate field is now 15 bits as per the instruction format.
     */

    // Sign extension or zero extension based on CS
    assign out = CS ? {{17{IMM[14]}}, IMM} : {17'b0, IMM};

endmodule
