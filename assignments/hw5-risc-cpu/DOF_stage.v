//`include "debug_defs.v"

module DOF_stage(
    input wire clk,                  // System clock signal for synchronizing register reads/writes
    input wire rst,                  // Active-high reset signal to initialize components
    input wire [31:0] instruction,   // Current instruction from IF stage through pipeline register
    input wire [31:0] PC_1,          // PC+1 value from top module pipeline register (for jump-and-link)
    input wire [31:0] WB_data,       // Data to write to register file from WB stage
    input wire [4:0] WB_addr,        // Register address to write to from WB stage
    input wire WB_en,                // Register write enable signal from WB stage
    output wire [31:0] A_data,       // Data read from source register A (directly from register file)
    output wire [31:0] B_data,       // Data read from source register B (directly from register file)
    output wire [31:0] BusA,         // First ALU operand - output from MuxA (either A_data or PC_1)
    output wire [31:0] BusB,         // Second ALU operand - output from MuxB (either B_data or immediate)
    output wire [31:0] extended_imm, // Sign/zero-extended immediate value from instruction
    // Control signals generated from opcode
    output wire RW,                  // Register Write control - enables register write for the instruction
    output wire [1:0] MD,            // Memory Data select (2 bits) - selects data source for register write
    output wire MW,                  // Memory Write control - enables memory write for store instructions
    output wire [1:0] BS,            // Branch Select control - determines branch type (no branch/conditional/register/direct)
    output wire PS,                  // Program Select control - selects branch condition polarity (BZ vs BNZ)
    output wire [4:0] FS,            // Function Select code - determines ALU operation
    // Instruction fields extracted directly
    output wire [4:0] DR,            // Destination Register field (bits 24:20) - target for results
    output wire [4:0] SH             // Shift amount field (bits 4:0) - for barrel shifter operations
);
    /*
     * Decode and Operand Fetch (DOF) Stage - Second stage of 4-stage RISC CPU pipeline
     *
     * Purpose and Operation:
     * ---------------------
     * The DOF stage serves two critical functions in the pipeline:
     * 1. Instruction Decoding - Breaking down the instruction into:
     *    - Opcode field to determine the operation
     *    - Register addresses for operand fetch and result destination
     *    - Immediate values for constant operations
     *    - Control signals to guide execution in later stages
     *
     * 2. Operand Fetching - Retrieving data needed for execution:
     *    - Reading values from the register file
     *    - Sign/zero-extending immediate values
     *    - Selecting and routing operands to the execution stage
     *
     * Instruction Formats:
     * ------------------
     * This CPU supports three primary instruction formats:
     * 
     * 1. Three-register format (R-type):
     *    [31:25] OPCODE (7 bits) - Operation code specifying instruction type
     *    [24:20] DR (5 bits) - Destination Register for result 
     *    [19:15] SA (5 bits) - Source Register A (first operand)
     *    [14:10] SB (5 bits) - Source Register B (second operand)
     *    [9:0]   Unused/Reserved (10 bits)
     *    Example: ADD, SUB, AND, OR, XOR
     * 
     * 2. Two-register format with immediate (I-type):
     *    [31:25] OPCODE (7 bits) - Operation code specifying instruction type
     *    [24:20] DR (5 bits) - Destination Register for result
     *    [19:15] SA (5 bits) - Source Register A (first operand)
     *    [14:0]  IMM (15 bits) - Immediate value (sign/zero-extended)
     *    Example: ADI, SBI, ANI, ORI, XRI
     * 
     * 3. Branch format (B-type):
     *    [31:25] OPCODE (7 bits) - Operation code specifying branch type
     *    [24:20] DR (5 bits) - Often unused or destination for jump-and-link
     *    [19:15] SA (5 bits) - Source Register A (condition register for BZ/BNZ)
     *    [14:0]  IMM (15 bits) - Signed offset for branch target
     *    Example: BZ, BNZ, JMP, JMR
     *
     * Key Components:
     * -------------
     * 1. Instruction Decoder - Generates control signals based on opcode
     * 2. Register File - Provides access to architectural registers
     * 3. Constant Unit - Extends immediate values from instruction
     * 4. MuxA/MuxB - Select appropriate operands based on instruction type
     */

    // Instruction Register and Field Extraction
    // The instruction is passed from IF stage through pipeline register
    wire [31:0] IR = instruction;

    // Extract and isolate individual fields from the instruction
    wire [6:0] opcode = IR[31:25]; // 7-bit opcode field - determines the operation
    assign DR = IR[24:20];         // 5-bit destination register field - target for results
    wire [4:0] SA = IR[19:15];     // 5-bit source register A field - first operand address
    wire [4:0] SB = IR[14:10];     // 5-bit source register B field - second operand address
    wire [14:0] IMM = IR[14:0];    // 15-bit immediate field - used for I-type and B-type instructions
    assign SH = IR[4:0];           // 5-bit shift amount field - overlaps with IMM, used for shift operations
    
    // Debug output for instruction decoding
    // Shows the breakdown of the current instruction into its component fields
    always @(posedge clk) begin
        if(`DEBUG_DOF) begin
            $display("INSTRUCTION DEBUG: IR=%h", IR);
            $display("INSTRUCTION FIELDS: opcode=%b, DR=%d, SA=%d, SB=%d, IMM=%h", 
                    opcode, DR, SA, SB, IMM);
        end
    end

    // Internal control signals not exposed as module outputs
    wire MA;                       // MuxA select - chooses between register A and PC+1
    wire MB;                       // MuxB select - chooses between register B and immediate
    wire CS;                       // Constant Select - determines sign/zero extension mode

    // Register File - Provides access to CPU registers
    // Supports two simultaneous reads (A_data, B_data) and one write (WB_data)
    registerFile reg_file(
        .clk(clk),                 // Clock input - writes occur on rising edge
        .rst(rst),                 // Reset input - initializes registers to 0
        .A_addr(SA),               // Read address A - from source register A field
        .B_addr(SB),               // Read address B - from source register B field
        .D_addr(WB_addr),          // Write address - from WB stage (destination register)
        .D_data(WB_data),          // Write data - from WB stage (computation result)
        .D_write(WB_en),           // Write enable - from WB stage (RW control signal)
        .A_data(A_data),           // Read data A output - first potential operand
        .B_data(B_data)            // Read data B output - second potential operand
    );

    // Debug output for register file access
    // Shows register addresses and values being read, and register writes
    always @(posedge clk) begin
        if(`DEBUG_DOF) begin
            $display("DOF DEBUG: Register A_addr=%d, B_addr=%d, A_data=%h, B_data=%h", SA, SB, A_data, B_data);
            if (WB_en)
                $display("DOF DEBUG: REGISTER WRITE - addr=%d, data=%h", WB_addr, WB_data);
        end
    end

    // Constant Unit - Handles immediate value extension
    // Performs sign or zero extension based on CS control signal
    constantUnit const_unit(
        .IMM(IMM),                 // 15-bit immediate value from instruction
        .CS(CS),                   // Constant Select control - from instruction decoder
        .out(extended_imm)         // 32-bit extended output - sign or zero extended
    );

    // Instruction Decoder - Generates control signals based on opcode
    // Maps instruction opcode to the specific control signals needed by all pipeline stages
    instructionDecoder i_decoder(
        .opcode(opcode),           // 7-bit opcode field from instruction
        .RW(RW),                   // Register Write control output
        .MD(MD),                   // Memory Data select output (2 bits)
        .MW(MW),                   // Memory Write control output
        .BS(BS),                   // Branch Select output (2 bits)
        .PS(PS),                   // Program Select output (1 bit)
        .FS(FS),                   // Function Select output (5 bits for ALU)
        .MB(MB),                   // MuxB select output (internal)
        .MA(MA),                   // MuxA select output (internal)
        .CS(CS)                    // Constant Select output (internal)
    );
    
    // MuxA - Selects first ALU operand
    // Chooses between register A data and PC+1 (for jump-and-link instructions)
    muxA mux_a(
        .A_data(A_data),           // Register A data input - from register file
        .PC_1(PC_1),               // PC+1 input - for jump-and-link return address
        .MA(MA),                   // MuxA select control - from instruction decoder
        .out(BusA)                 // Selected first ALU operand output
    );

    // MuxB - Selects second ALU operand
    // Chooses between register B data and extended immediate value
    muxB mux_b(
        .B_data(B_data),           // Register B data input - from register file
        .constant(extended_imm),   // Extended immediate input - from constant unit
        .MB(MB),                   // MuxB select control - from instruction decoder
        .out(BusB)                 // Selected second ALU operand output
    );

endmodule 