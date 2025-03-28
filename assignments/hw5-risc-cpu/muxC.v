module muxC(
    input wire [31:0] PC_1,      // PC+1 value
    input wire [31:0] BrA,       // Branch address
    input wire [31:0] RAA,       // Register A address
    input wire [31:0] JMP,       // Jump address
    input wire [1:0] BS,         // Branch Select
    input wire PS,               // Program Select (single bit)
    input wire Z,                // Zero flag
    output wire [31:0] out       // Selected output
);
    /*
     * Multiplexer C - Pipeline Stage: Instruction Fetch (IF)
     * 
     * This multiplexer controls program flow by selecting the next PC value.
     * The design shown in the diagram uses a combination of AND, OR gates
     * with BS1 (high bit of BS) controlling the upper MUX path.
     * 
     * Control logic:
     * - BS=00: Select PC+1 (sequential execution)
     * - BS=01 and PS=0: BZ - Branch if Zero (select BrA if Z=1)
     * - BS=01 and PS=1: BNZ - Branch if Not Zero (select BrA if Z=0)
     * - BS=10: JMR - Jump to Register (select RAA)
     * - BS=11: JMP - Jump to immediate (select JMP)
     */

    // BS[1] (high bit) controls whether PC+1/conditional branch or JMR/JMP is selected
    wire BS1 = BS[1];
    wire BS0 = BS[0];
    
    // Control for conditional branch
    wire branch_condition = PS ? ~Z : Z;  // BNZ: Branch if Z=0, BZ: Branch if Z=1
    
    // BS0 determines whether to use BrA (conditional branch) or PC+1
    wire [31:0] top_path = (BS0 & branch_condition) ? BrA : PC_1;
    
    // BS0 determines whether to use JMP (unconditional jump) or RAA (jump register) 
    wire [31:0] bottom_path = BS0 ? JMP : RAA;
    
    // BS1 selects between top path (sequential/conditional) and bottom path (jumps)
    assign out = BS1 ? bottom_path : top_path;

endmodule
