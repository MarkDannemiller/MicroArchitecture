module IF_stage(
    input wire clk,                  // System clock signal that drives pipeline timing
    input wire rst,                  // Active-high reset signal to initialize components
    input wire [31:0] PC,            // Current Program Counter value from top module (points to instruction to fetch)
    input wire [31:0] BrA,           // Branch target address - calculated in EX stage for conditional branches
    input wire [31:0] RAA,           // Register jump address - used for JMR (Jump Register) instruction, sourced from register
    input wire [31:0] JMP,           // Jump target address - used for JMP (Jump Immediate) instruction
    input wire [1:0] BS,             // Branch Select control - determines type of branch/jump: 00=no branch, 01=conditional, 10=register, 11=direct
    input wire PS,                   // Program Select control - selects branch condition polarity: 0=branch if Z, 1=branch if !Z
    input wire Z,                    // Zero flag from ALU in EX stage - used for conditional branch decisions
    output wire [31:0] PC_next,      // Next PC value output - will become the new PC on next clock cycle
    output wire [31:0] PC_1,         // PC + 1 value - used for sequential execution and as return address for jump-and-link
    output wire [31:0] instruction   // Current instruction fetched from instruction memory at address PC
);
    /*
     * Instruction Fetch (IF) Stage - First stage of 4-stage RISC CPU pipeline
     *
     * Purpose and Operation:
     * ---------------------
     * The IF stage is responsible for fetching the current instruction pointed to by PC
     * and determining the next PC value based on branch/jump conditions.
     *
     * This stage coordinates three key operations:
     * 1. Reading the instruction at the current PC from instruction memory
     * 2. Incrementing PC to PC+1 for potential sequential execution
     * 3. Selecting the next PC value based on control signals and condition flags
     *
     * The PC update actually happens in the top module, where PC is stored in a
     * pipeline register and updated on the negative clock edge.
     *
     * Branch/Jump Selection Logic:
     * --------------------------
     * The MuxC component selects the next PC value from four possible sources:
     * - PC+1: Sequential execution (next instruction)
     * - BrA: Branch target address (for conditional branches)
     * - RAA: Register address (for jumps to address in register)
     * - JMP: Jump target address (for direct jumps)
     *
     * The selection is controlled by BS (Branch Select) and the branch 
     * condition is determined by PS (Program Select) and Z (Zero flag).
     */

    // Calculate PC+1 for sequential execution and branch calculations
    // This is used both for sequential execution and as a return address for jump-and-link
    assign PC_1 = PC + 32'h1;
    
    // Instruction Memory - Retrieves the instruction at the current PC address
    // This is an asynchronous read operation - the instruction is available immediately
    instructionMemory inst_mem(
        .addr(PC),                // Current PC value as memory address
        .instruction(instruction)  // Fetched instruction output
    );

    // MuxC - Next PC Selection Multiplexer
    // Determines the next PC value based on branch/jump control signals
    muxC mux_c(
        .PC_1(PC_1),          // PC+1 for sequential execution (no branch/jump)
        .BrA(BrA),            // Branch target address (for conditional branches - BZ/BNZ)
        .RAA(RAA),            // Register jump target (for JMR - Jump to Register)
        .JMP(JMP),            // Immediate jump target (for JMP - Jump Immediate)
        .BS(BS),              // Branch Select control - determines branch/jump type
        .PS(PS),              // Program Select - determines branch condition polarity
        .Z(Z),                // Zero flag - used for conditional branch decisions
        .out(PC_next)         // Selected next PC value output
    );

endmodule 