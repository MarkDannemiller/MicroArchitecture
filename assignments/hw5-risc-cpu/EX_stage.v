module EX_stage(
    input wire clk,                  // System clock signal for synchronizing data memory operations
    input wire rst,                  // Active-high reset signal to initialize components
    // Data inputs
    input wire [31:0] BusA,         // First ALU operand from DOF stage (register A, or PC+1 for jump-and-link)
    input wire [31:0] BusB,         // Second ALU operand from DOF stage (register B or immediate value)
    input wire [31:0] extended_imm, // Sign/zero-extended immediate value from DOF stage (for branch address calculation)
    input wire [31:0] PC_2,         // PC+2 value from pipeline register in top module (for branch target calculation)
    input wire [4:0] SH,            // Shift amount field for barrel shifter operations (LSL, LSR instructions)
    // Control inputs
    input wire [4:0] FS,            // Function Select code that determines ALU operation
    input wire MW,                  // Memory Write control signal - enables writing to data memory when high
    // Outputs
    output wire [31:0] ALU_result,  // Result of ALU operation (used for register writes and memory addressing)
    output wire [31:0] mem_data,    // Data read from memory at address BusA (for load instructions)
    output wire [31:0] BrA,         // Calculated branch address (PC_2 + extended_imm) for branch instructions
    output wire N_xor_V,            // N XOR V condition for SLT (Set Less Than) instruction 
    output wire Z,                  // Zero flag - set when ALU result is zero
    output wire V,                  // Overflow flag - set when arithmetic operation causes signed overflow
    output wire N,                  // Negative flag - set when ALU result is negative (MSB=1)
    output wire C                   // Carry flag - set when arithmetic operation produces a carry-out
);
    /*
     * Execute (EX) Stage - Third stage of 4-stage RISC CPU pipeline
     *
     * Purpose and Operation:
     * ---------------------
     * The EX stage performs three critical functions:
     * 1. ALU Computation - Executes arithmetic and logical operations based on FS code
     * 2. Memory Access - Performs load/store operations on data memory
     * 3. Branch Target Calculation - Computes target addresses for branch/jump instructions
     *
     * This stage receives operands from the DOF stage and produces:
     * - Computation results for register write operations
     * - Memory data for load operations
     * - Condition flags for branch decisions
     * - Branch target addresses for the IF stage
     *
     * Key Components:
     * --------------
     * 1. Function Unit - The ALU that performs computation and sets flags
     * 2. Data Memory - Provides read/write access to data memory
     * 3. Branch Address Calculator - Computes branch targets for conditional branches
     *
     * The N⊕V signal is specifically for the SLT (Set Less Than) instruction,
     * which sets a register to 1 if the first operand is less than the second
     * when interpreted as signed values.
     */

    // Branch address calculation - Add PC_2 and extended immediate for branch target
    // For conditional branches (BZ/BNZ), PC-relative addressing is implemented
    // by adding the sign-extended immediate to PC+2
    assign BrA = PC_2 + extended_imm;
    
    // N XOR V calculation for signed comparison (SLT instruction)
    // When N and V are different, it indicates the result is negative after accounting for overflow
    // This allows for correct signed less-than comparisons
    assign N_xor_V = N ^ V;

    // Function Unit (ALU) - Performs the specified operation and sets condition flags
    // Operations are determined by the FS (Function Select) control signal
    functionUnit func_unit(
        .A(BusA),               // First operand - from register A or PC+1
        .B(BusB),               // Second operand - from register B or immediate value
        .FS(FS),                // Function Select code - determines operation type
        .SH(SH),                // Shift amount - for barrel shifter operations
        .F(ALU_result),         // ALU result output - computation result
        .Z(Z),                  // Zero flag output - set when result is zero
        .V(V),                  // Overflow flag output - set when signed overflow occurs
        .N(N),                  // Negative flag output - set when result is negative
        .C(C)                   // Carry flag output - set when carry/borrow occurs
    );
    
    // Data Memory - Provides data storage and retrieval capabilities
    // Synchronous writes (on rising clock edge) and asynchronous reads
    dataMemory data_mem(
        .clk(clk),              // Clock input - writes occur on rising edge
        .addr(BusA),            // Memory address - from register A
        .data_in(BusB),         // Write data - from register B
        .data_out(mem_data),    // Read data output - for load instructions
        .MW(MW)                 // Memory Write control - enables writing when high
    );

endmodule 