// Definitions
`include "../definitions.v"
`include "../debug_defs.v"

// Include all required modules
`include "../top.v"
`include "../IF_stage.v"
`include "../DOF_stage.v"
`include "../EX_stage.v"
`include "../WB_stage.v"
`include "../instructionMemory.v"
`include "../dataMemory.v"
`include "../registerFile.v"
`include "../constantUnit.v"
`include "../functionUnit.v"
`include "../instructionDecoder.v"
`include "../muxA.v"
`include "../muxB.v"
`include "../muxC.v"
`include "../muxD.v"

module hw6_tb();
    reg clk;
    reg rst;
    wire [31:0] R1_debug = cpu.dof_stage.reg_file.registers[1]; // Example direct access
    wire [31:0] R2_debug = cpu.dof_stage.reg_file.registers[2];
    wire [31:0] R3_debug = cpu.dof_stage.reg_file.registers[3];
    wire [31:0] R4_debug = cpu.dof_stage.reg_file.registers[4];
    wire [31:0] R5_debug = cpu.dof_stage.reg_file.registers[5];
    wire [31:0] R7_debug = cpu.dof_stage.reg_file.registers[7];
    wire [31:0] R8_debug = cpu.dof_stage.reg_file.registers[8];
    wire [31:0] R9_debug = cpu.dof_stage.reg_file.registers[9];
    wire [31:0] R10_debug = cpu.dof_stage.reg_file.registers[10];
    wire [31:0] R31_debug = cpu.dof_stage.reg_file.registers[31];

    // Debug signals for instruction flow tracking
    wire [31:0] PC_debug = cpu.PC;  // Current PC
    wire [31:0] IF_instruction_debug = cpu.if_stage.instruction;  // Instruction from IF stage
    wire [31:0] DOF_instruction_debug = cpu.IF_DOF_instruction;  // Instruction passed to DOF stage
    wire [6:0] opcode_debug = cpu.dof_stage.opcode;  // Extracted opcode in DOF
    
    // Control signals from instruction decoder
    wire RW_debug = cpu.dof_stage.RW;
    wire [1:0] MD_debug = cpu.dof_stage.MD;
    wire MW_debug = cpu.dof_stage.MW;
    wire [1:0] BS_debug = cpu.dof_stage.BS;
    wire [4:0] FS_debug = cpu.dof_stage.FS;
    
    // Debug control flags
    reg debug_full_trace = 1;   // Set to 1 to enable full instruction trace
    integer debug_cycle_count = 0;  // Track cycle count for debugging
    
    // Hazard detection signals (store previous values to detect changes)
    reg [31:0] prev_DOF_instruction = 32'h0;
    
    // Register fields for hazard detection
    reg [4:0] DOF_dst;
    reg [4:0] EX_src1;
    reg [4:0] EX_src2;
    
    // For PC tracking
    reg [31:0] prev_PC = -1;

    // Test counters
    integer tests_passed;
    integer tests_failed;
    integer total_tests;

    // Instruction memory array (local copy for setup)
    reg [31:0] instruction_memory [0:1023];  // 1024 instructions max

    integer i;
    integer j;
    integer m; // Instruction memory index
    
    // Variables for debug output
    reg [31:0] packed_nop;
    reg [31:0] packed_lsr;

    integer stable_count; // For wait_for_completion
    integer stuck_count; // For detecting PC stuck
    reg [31:0] last_pc; // For detecting PC stuck
    
    // Helper function to correctly pack instruction bits
    // This ensures opcodes and operands are aligned to proper bit positions
    function [31:0] pack_instruction(
        input [6:0] opcode,
        input [4:0] rd,
        input [4:0] rs1,
        input [4:0] rs2,
        input [15:0] imm
    );
        begin
            // Default to R-type format
            pack_instruction = {opcode, rd, rs1, rs2, imm[9:0]};
            
            // I-type instructions: opcode[6:0], rd[4:0], rs1[4:0], imm[15:0]
            if (opcode == `OP_ADI || opcode == `OP_SBI || opcode == `OP_ANI || 
                opcode == `OP_ORI || opcode == `OP_XRI || opcode == `OP_AIU || 
                opcode == `OP_SIU || opcode == `OP_LSL || opcode == `OP_LSR) begin
                pack_instruction = {opcode, rd, rs1, imm[14:0]};
            end
            
            // Branch instructions: opcode[6:0], rd[4:0], rs1[4:0], imm[15:0]
            else if (opcode == `OP_BZ || opcode == `OP_BNZ) begin
                pack_instruction = {opcode, rd, rs1, imm[14:0]};
            end
            
            // Jump instructions: opcode[6:0], rd[4:0], rs1[4:0], imm[15:0]
            else if (opcode == `OP_JMP || opcode == `OP_JML) begin
                pack_instruction = {opcode, rd, rs1, imm[14:0]};
            end
            
            // MOV instruction: opcode[6:0], rd[4:0], rs1[4:0], 16'b0
            else if (opcode == `OP_MOV) begin
                pack_instruction = {opcode, rd, rs1, 16'b0};
            end
            
            // NOT instruction: opcode[6:0], rd[4:0], rs1[4:0], 16'b0
            else if (opcode == `OP_NOT) begin
                pack_instruction = {opcode, rd, rs1, 16'b0};
            end
            
            // Print verbose debug info for each instruction
            $display("DEBUG PACK: opcode=%b (%s), rd=%d, rs1=%d, rs2=%d, imm=%h => packed=%h",
                      opcode, 
                      (opcode == `OP_NOP) ? "NOP" : 
                      (opcode == `OP_ADD) ? "ADD" : 
                      (opcode == `OP_SUB) ? "SUB" : 
                      (opcode == `OP_MOV) ? "MOV" : 
                      (opcode == `OP_ADI) ? "ADI" : 
                      (opcode == `OP_SBI) ? "SBI" : 
                      (opcode == `OP_LSL) ? "LSL" : 
                      (opcode == `OP_LSR) ? "LSR" : 
                      (opcode == `OP_ANI) ? "ANI" : 
                      (opcode == `OP_BZ) ? "BZ" : 
                      (opcode == `OP_BNZ) ? "BNZ" : 
                      (opcode == `OP_JMP) ? "JMP" : 
                      (opcode == `OP_NOT) ? "NOT" : 
                      (opcode == `OP_XOR) ? "XOR" : "OTHER",
                      rd, rs1, rs2, imm, pack_instruction);
        end
    endfunction

    // Instantiate the CPU
    top cpu(
        .clk(clk),
        .rst(rst)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 10ns period -> 100MHz clock
    end

    // Load multiplication program into local instruction memory array initially
    initial begin
        // Program: 32x32 -> 64-bit Multiplication Algorithm (Shift-and-Add style)
        // Format: {opcode[6:0], rd[4:0], rs1[4:0], rs2[4:0], imm[15:0]} or similar based on type
        // Registers: R1=Product_Low, R2=Product_High, R3=Multiplicand, R4=Multiplier
        //            R7=Sign_Multiplicand, R8=Sign_Multiplier, R9=LSB_Test, R10=Final_Sign_XOR
        //            R5=Helper/Carry?, R31=Loop_Counter

        // Initialize test counters
        tests_passed = 0;
        tests_failed = 0;
        total_tests = 8;  // Total number of test cases
            
        // Initialize the initial block of instructions as NOP (leave room for test case setup code)
        for (i = 0; i < 100; i = i + 1) begin
            instruction_memory[i] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);  // NOP instruction
        end
        
        // Start at address 100 (instead of 0) to leave room for test case setup code
        m = 100;

    //-------------------------------------------------------------------------
    // 1. Initialize product registers (R1 = low, R2 = high)
    //-------------------------------------------------------------------------
        instruction_memory[m++] = pack_instruction(`OP_ADI, `R1, `R0, 5'b0, 16'h0);  // [100] R1 = 0 (Low Product)
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [101] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [102] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [103] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [104] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [105] NOP
        instruction_memory[m++] = pack_instruction(`OP_ADI, `R2, `R0, 5'b0, 16'h0);  // [106] R2 = 0 (High Product)
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [107] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [108] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [109] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [110] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [111] NOP

    //-------------------------------------------------------------------------
    // 2. Load inputs into multiplicand and multiplier registers
        //    (Assume original inputs are in R1 and R2 from test setup; move to R3/R4)
    //-------------------------------------------------------------------------
        instruction_memory[m++] = pack_instruction(`OP_MOV, `R3, `R1, 5'b0, 16'h0);  // [112] R3 = multiplicand (from R1)
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [113] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [114] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [115] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [116] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [117] NOP
        instruction_memory[m++] = pack_instruction(`OP_MOV, `R4, `R2, 5'b0, 16'h0);  // [118] R4 = multiplier (from R2)
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [119] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [120] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [121] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [122] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [123] NOP

    //-------------------------------------------------------------------------
    // 3. Make multiplicand positive if needed; save sign in R7.
    //-------------------------------------------------------------------------
        instruction_memory[m++] = pack_instruction(`OP_LSR, `R7, `R3, 5'b0, 16'd31);  // [124] R7 = R3 >> 31 (Extract sign bit)
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [125] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [126] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [127] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [128] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [129] NOP
        instruction_memory[m++] = pack_instruction(`OP_BZ,  `R7, 5'b0, 5'b0, 16'd11);  // [130] if (R7==0) skip next instruction (and NOPs)
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [131] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [132] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [133] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [134] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [135] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOT, `R3, `R3, 5'b0, 16'h0);   // [136] R3 = NOT R3
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [137] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [138] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [139] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [140] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [141] NOP
        instruction_memory[m++] = pack_instruction(`OP_ADI, `R3, `R3, 5'b0, 16'd1);   // [142] R3 = R3 + 1 (Complete 2's comp)
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [143] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [144] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [145] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [146] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [147] NOP

    //-------------------------------------------------------------------------
    // 4. Make multiplier positive if needed; save sign in R8.
    //-------------------------------------------------------------------------
        instruction_memory[m++] = pack_instruction(`OP_LSR, `R8, `R4, 5'b0, 16'd31);  // [148] R8 = R4 >> 31 (Extract sign bit)
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [149] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [150] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [151] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [152] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [153] NOP
        instruction_memory[m++] = pack_instruction(`OP_BZ,  `R8, 5'b0, 5'b0, 16'd11);  // [154] if (R8==0) skip next instruction (and NOPs)
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [155] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [156] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [157] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [158] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [159] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOT, `R4, `R4, 5'b0, 16'h0);   // [160] R4 = NOT R4
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [161] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [162] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [163] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [164] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [165] NOP
        instruction_memory[m++] = pack_instruction(`OP_ADI, `R4, `R4, 5'b0, 16'd1);   // [166] R4 = R4 + 1 (Complete 2's comp)
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [167] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [168] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [169] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [170] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [171] NOP

    //-------------------------------------------------------------------------
        // 5. Initialize helper register R5 and loop counter R31.
    //-------------------------------------------------------------------------
        instruction_memory[m++] = pack_instruction(`OP_ADI, `R5, `R0, 5'b0, 16'h0);   // [172] R5 = 0
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [173] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [174] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [175] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [176] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [177] NOP
        instruction_memory[m++] = pack_instruction(`OP_ADI, `R31, `R0, 5'b0, 16'd32); // [178] R31 = 32 (Loop counter)
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [179] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [180] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [181] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [182] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [183] NOP

    //-------------------------------------------------------------------------
        // 6. Multiplication loop START (Target Address for BNZ)
    //-------------------------------------------------------------------------
        // Loop_Start:
        instruction_memory[m++] = pack_instruction(`OP_ANI, `R9, `R4, 5'b0, 16'd1);   // [184] R9 = R4 & 1 (Test LSB of multiplier)
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [185] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [186] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [187] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [188] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [189] NOP
        instruction_memory[m++] = pack_instruction(`OP_BZ,  `R9, 5'b0, 5'b0, 16'd17);  // [190] if (R9==0) skip next 3 instructions (and NOPs)
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [191] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [192] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [193] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [194] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [195] NOP
        // If LSB was 1:
        instruction_memory[m++] = pack_instruction(`OP_ADD, `R1, `R1, `R3, 5'b0);     // [196] R1 = R1 + R3 (Add multiplicand to Low Prod)
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [197] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [198] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [199] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [200] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [201] NOP
        instruction_memory[m++] = pack_instruction(`OP_ADI, `R5, `R5, 5'b0, 16'd1);   // [202] R5 = R5 + 1 (Carry handling)
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [203] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [204] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [205] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [206] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [207] NOP
        instruction_memory[m++] = pack_instruction(`OP_ADD, `R2, `R2, `R5, 5'b0);     // [208] R2 = R2 + R5 (Update High Prod)
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [209] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [210] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [211] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [212] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [213] NOP
        // Skip_Target / Continue:
    // Shift registers and update loop counter:
        instruction_memory[m++] = pack_instruction(`OP_LSR, `R4, `R4, 5'b0, 16'd1);   // [214] R4 = R4 >> 1 (Shift multiplier right)
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [215] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [216] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [217] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [218] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [219] NOP
        instruction_memory[m++] = pack_instruction(`OP_SBI, `R31, `R31, 5'b0, 16'd1); // [220] R31 = R31 - 1 (Decrement counter)
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [221] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [222] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [223] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [224] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [225] NOP
        instruction_memory[m++] = pack_instruction(`OP_LSL, `R3, `R3, 5'b0, 16'd1);   // [226] R3 = R3 << 1 (Shift multiplicand left)
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [227] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [228] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [229] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [230] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [231] NOP
        instruction_memory[m++] = pack_instruction(`OP_LSL, `R5, `R5, 5'b0, 16'd1);   // [232] R5 = R5 << 1 (Shift helper left)
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [233] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [234] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [235] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [236] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [237] NOP
        // Calculate the jump offset to loop_start based on current position
        // Jump back to address 184 (Loop_Start)
        // Target = 184, PC = 238, PC+1+offset = 184 → offset = 184-(238+1) = -55
        instruction_memory[m++] = pack_instruction(`OP_BNZ, `R31, 5'b0, 5'b0, -16'd55); // [238] If R31!=0, jump back to Loop_Start
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [239] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [240] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [241] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [242] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [243] NOP
        // End of loop

    //-------------------------------------------------------------------------
    // 7. Adjust the final product sign if needed.
    //-------------------------------------------------------------------------
        instruction_memory[m++] = pack_instruction(`OP_XOR, `R10, `R7, `R8, 5'b0);    // [244] R10 = R7 ^ R8 (Check if signs differed)
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [245] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [246] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [247] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [248] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [249] NOP
        instruction_memory[m++] = pack_instruction(`OP_BZ,  `R10, 5'b0, 5'b0, 16'd29); // [250] if (R10==0) skip next instructions (and NOPs)
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [251] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [252] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [253] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [254] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [255] NOP
        // If signs differed, take two's complement of 64-bit result (R2:R1)
        instruction_memory[m++] = pack_instruction(`OP_NOT, `R2, `R2, 5'b0, 16'h0);   // [256] R2 = NOT R2
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [257] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [258] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [259] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [260] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [261] NOP
        instruction_memory[m++] = pack_instruction(`OP_ADI, `R2, `R2, 5'b0, 16'd1);   // [262] R2 = R2 + 1 (If R1 was 0, this finishes)
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [263] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [264] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [265] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [266] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [267] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOT, `R1, `R1, 5'b0, 16'h0);   // [268] R1 = NOT R1
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [269] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [270] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [271] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [272] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [273] NOP
        instruction_memory[m++] = pack_instruction(`OP_ADI, `R1, `R1, 5'b0, 16'd1);   // [274] R1 = R1 + 1 (Completes 2's comp)
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [275] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [276] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [277] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [278] NOP
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // [279] NOP
        // Skip_Sign_Adjust:

    //-------------------------------------------------------------------------
        // 8. End of program: Jump -1 steps (halt)
    //-------------------------------------------------------------------------
        instruction_memory[m++] = pack_instruction(`OP_JMP, 5'b0, 5'b0, 5'b0, 16'h7FFF); // [280] JMP -1 (Halt)

    //-------------------------------------------------------------------------
    // 9. Fill remaining memory with NOPs.
    //-------------------------------------------------------------------------
    for (i = m; i < 1024; i = i + 1) begin
            instruction_memory[i] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0);
    end
end

    // Task to wait for program completion (PC = 280 and stable)
    task wait_for_completion;
        begin
            stable_count = 0;
            stuck_count = 0;
            last_pc = 0;

            while (stable_count < 5) begin
                @(posedge clk);
                
                // Check if PC is stable at the expected final address
                if (cpu.PC == 280) begin
                    stable_count = stable_count + 1;
                    stuck_count = 0;  // Reset stuck counter when PC changes
                end else begin
                    stable_count = 0;
                    
                    // Check if PC is stuck at some other value
                    if (cpu.PC == last_pc) begin
                        stuck_count = stuck_count + 1;
                        if (stuck_count >= 100) begin
                            $display("ERROR: Program appears stuck at PC=%h for %d cycles - exiting simulation", cpu.PC, stuck_count);
                            $finish;
                        end
                    end else begin
                        stuck_count = 0;  // Reset stuck counter when PC changes
        end
    end
                
                last_pc = cpu.PC;  // Record current PC for next cycle comparison
            end
            $display("Program execution complete - PC stable at 280");
        end
    endtask

    // Test stimulus
    initial begin
        // Initialize waveform dumping
        $dumpfile("hw6_tb.vcd");
        $dumpvars(0, hw6_tb);

        // Reset CPU before starting tests
        rst = 1;
        #20; // Hold reset for 2 cycles
        rst = 0;
        #1; // Release reset

        // --- Test Case 1: 0 * 0 ---
        $display("\nTest Case 1: 0 * 0");
        // Setup inputs directly in registers (requires internal path knowledge)
        // This approach bypasses the test instruction loading issue but is less realistic
        // A better approach loads setup instructions, jumps, waits, then checks.
        // We'll use the instruction loading approach.

        // Load Test Case 1 setup instructions into local memory array
        m = 0; // Overwrite starting from address 0 for test setup
        instruction_memory[m++] = pack_instruction(`OP_ADI, `R1, `R0, 5'b0, 16'h0);  // ADI R1, R0, #0 (Input 1)
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); // Timing NOPs
        instruction_memory[m++] = pack_instruction(`OP_ADI, `R2, `R0, 5'b0, 16'h0);  // ADI R2, R0, #0 (Input 2)
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); // Timing NOPs
        instruction_memory[m++] = pack_instruction(`OP_ADI, `R3, `R0, 5'b0, 16'h0);  // ADI R3, R0, #0 (Expected Result Low)
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); // Timing NOPs
        instruction_memory[m++] = pack_instruction(`OP_ADI, `R4, `R0, 5'b0, 16'h0);  // ADI R4, R0, #0 (Expected Result High)
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); // Timing NOPs
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); // Timing NOPs
        // PC is now 24 (m=24)
        // Jump to multiplication program at address 100
        // Offset calculation: Target=100, PC=24, PC+1+offset=100 → offset=100-(24+1)=75
        instruction_memory[m++] = pack_instruction(`OP_JMP, 5'b0, 5'b0, 5'b0, 16'd75);   // JMP to address 100

        // Load the test setup instructions into CPU's instruction memory
        for (j = 0; j < 1024; j = j + 1) begin
            cpu.if_stage.inst_mem.memory[j] = instruction_memory[j];
        end

                // Debug - Display first 200 instruction memory lines to verify loading
        $display("\n===== INSTRUCTION MEMORY DUMP (First 280 lines) =====");
        for (j = 0; j < 280; j = j + 1) begin
            $display("Addr %03d: %08h | Opcode: %07b", j, 
                      cpu.if_stage.inst_mem.memory[j],
                      cpu.if_stage.inst_mem.memory[j][31:25]);
        end
        $display("======================================================\n");
        
        // Reset CPU state to start test case 1
        rst = 1; #20; rst = 0; #1;
        
        // Wait for program to complete
        wait_for_completion();
        
        // Check results
        $display("Result TC1: R1(Low)=%h, R2(High)=%h", R1_debug, R2_debug);
        if (R1_debug === 32'h0 && R2_debug === 32'h0) begin
            $display("Test Case 1 PASSED"); tests_passed = tests_passed + 1;
        end else begin
            $display("Test Case 1 FAILED - Expected 0x0:0, Got %h:%h", R2_debug, R1_debug); tests_failed = tests_failed + 1;
        end
        #100; // Delay between tests


        // --- Test Case 2: 1 * 1 = 1 ---
        $display("\nTest Case 2: 1 * 1");
        rst = 1; #20; rst = 0; #1;
        m = 0;
        instruction_memory[m++] = pack_instruction(`OP_ADI, `R1, `R0, 5'b0, 16'h0001);  // ADI R1, R0, #1
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_ADI, `R2, `R0, 5'b0, 16'h0001);  // ADI R2, R0, #1
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_ADI, `R3, `R0, 5'b0, 16'h0001);  // ADI R3, R0, #1 (Expected Result Low)
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_ADI, `R4, `R0, 5'b0, 16'h0000);  // ADI R4, R0, #0 (Expected Result High)
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); // Timing NOPs
        // PC is now 24 (m=24)
        // Jump to multiplication program at address 100
        // Offset calculation: Target=100, PC=24, PC+1+offset=100 → offset=100-(24+1)=75
        instruction_memory[m++] = pack_instruction(`OP_JMP, 5'b0, 5'b0, 5'b0, 16'd75);   // JMP to address 100
        
        for (j = 0; j < 1024; j = j + 1) cpu.if_stage.inst_mem.memory[j] = instruction_memory[j]; // Load instructions
        
        // Reset CPU state and debug state for test case 2
        rst = 1; #20; rst = 0; #1;
        debug_state = 0;
        
        // Wait for program to complete
        wait_for_completion();
        
        $display("Result TC2: R1(Low)=%h, R2(High)=%h", R1_debug, R2_debug);
        if (R1_debug === 32'h1 && R2_debug === 32'h0) begin
            $display("Test Case 2 PASSED"); tests_passed = tests_passed + 1;
        end else begin
            $display("Test Case 2 FAILED - Expected 0x0:1, Got %h:%h", R2_debug, R1_debug); tests_failed = tests_failed + 1;
        end
        #100;



        // Display test summary
        $display("\n=== Test Summary ===");
        $display("Total Tests: %0d", total_tests);
        $display("Tests Passed: %0d", tests_passed);
        $display("Tests Failed: %0d", tests_failed);
        if (tests_failed == 0)
            $display("All tests PASSED!");
        else
            $display("Some tests FAILED!");
        $display("==================\n");

        // End simulation
        $display("All test cases completed");
        $finish;
    end

    // Monitor register values (for debug)
    reg [31:0] pipeline_delay_counter = 0;  // Track pipeline stages
    reg [31:0] debug_state = 0;  // Use state-based debugging to track pipeline operations
    
    always @(posedge clk) begin
        if (!rst) begin
            // Debug register values at appropriate pipeline stages
            case (debug_state)
                // Test setup debugging states
                0: begin
                    if (cpu.PC == 0) begin
                        $display("CRITICAL: [PC=%d] Test case setup started", cpu.PC);
                        debug_state = 1;
                    end
                end
                
                1: begin
                    // Wait for first MOV instruction to complete (R1 load)
                    if (cpu.PC >= 6) begin
                        $display("CRITICAL: Test input R1=%h loaded", R1_debug);
                        debug_state = 2;
                    end
                end
                
                2: begin
                    // Wait for second MOV instruction to complete (R2 load)
                    if (cpu.PC >= 12) begin
                        $display("CRITICAL: Test input R2=%h loaded", R2_debug);
                        debug_state = 3;
                    end
                end
                
                3: begin
                    // Watch for jump to multiplication code
                    if (cpu.PC == 24) begin
                        $display("CRITICAL: [PC=%d] Jumping to multiplication algorithm", cpu.PC);
                        debug_state = 10;
                    end
                end
                
                10: begin
                    // First instruction of multiplication code
                    if (cpu.PC == 100) begin
                        $display("\nCRITICAL: [PC=%d] MULTIPLICATION STARTED", cpu.PC);
                        $display("  Initial inputs: R1=%h, R2=%h", R1_debug, R2_debug);
                        $display("  Expected for TC1 (0*0): R1=0, R2=0");
                        $display("  Expected for TC2 (1*1): R1=1, R2=0");
                        debug_state = 11;
                    end
                end
                
                11: begin
                    // Wait for R1 initialization to complete
                    if (cpu.PC >= 106) begin
                        $display("CRITICAL: [PC=%d] R1 initialized to %h", cpu.PC, R1_debug);
                        debug_state = 12;
                    end 
                end
                
                12: begin
                    // Wait for R2 initialization to complete 
                    if (cpu.PC >= 112) begin
                        $display("CRITICAL: [PC=%d] R2 initialized to %h", cpu.PC, R2_debug);
                        debug_state = 13;
                    end
                end
                
                13: begin
                    // Wait for inputs to be moved to R3 and R4
                    if (cpu.PC >= 124) begin
                        $display("CRITICAL: Inputs moved to multiplicand/multiplier");
                        $display("  R3 (multiplicand)=%h, R4 (multiplier)=%h", R3_debug, R4_debug);
                        debug_state = 14;
                    end
                end
                
                14: begin
                    // Wait for sign extraction of multiplicand
                    if (cpu.PC >= 130) begin
                        $display("CRITICAL: Sign extracted from multiplicand, R7=%h", R7_debug);
                        debug_state = 15;
                    end
                end
                
                15: begin
                    // Wait for sign extraction of multiplier
                    if (cpu.PC >= 154) begin
                        $display("CRITICAL: Sign extracted from multiplier, R8=%h", R8_debug);
                        debug_state = 16;
                    end
                end
                
                16: begin
                    // Wait for loop counter initialization
                    if (cpu.PC >= 182) begin
                        $display("CRITICAL: Loop counter initialized, R31=%d", R31_debug);
                        debug_state = 20;
                    end
                end
                
                // ---- Multiplication loop tracking ----
                20: begin
                    // Beginning of multiplication loop
                    if (cpu.PC == 184) begin
                        $display("\nCRITICAL: LOOP ITERATION - Counter=%d", R31_debug);
                        $display("  LSB check: R9=%h (multiplier R4=%h)", R9_debug, R4_debug);
                        debug_state = 21;
                    end
                end
                
                21: begin
                    // After LSB check
                    if (cpu.PC > 190 && cpu.PC < 196) begin
                        if (R9_debug == 0) begin
                            $display("  LSB is 0, skipping addition");
        end else begin
                            $display("  LSB is 1, will add multiplicand to product");
                        end
                        debug_state = 22;
                    end
                end
                
                22: begin
                    // After addition (if performed)
                    if (cpu.PC >= 214) begin
                        $display("  Current product: R2:R1 = %h:%h", R2_debug, R1_debug);
                        debug_state = 23;
                    end
                end
                
                23: begin
                    // After multiplier shift
                    if (cpu.PC >= 226) begin
                        $display("  Shifted multiplier: R4=%h", R4_debug);
                        $display("  Shifted multiplicand: R3=%h", R3_debug);
                        debug_state = 24;
                    end
                end
                
                24: begin
                    // After loop branch check
                    if (cpu.PC > 238) begin
                        // If we're still in the loop
                        if (R31_debug > 0) begin
                            debug_state = 20; // Go back to loop start
                            $display("  Loop continues, iterations left: %d", R31_debug);
        end else begin
                            debug_state = 30; // Move to sign adjustment
                            $display("\nCRITICAL: MULTIPLICATION LOOP COMPLETE");
                        end
                    end
                end
                
                // ---- Sign adjustment ----
                30: begin
                    // Wait for sign adjustment check
                    if (cpu.PC >= 250) begin
                        $display("CRITICAL: Sign check result R10=%h", R10_debug);
                        if (R10_debug != 0) begin
                            $display("  Signs differed, need to negate result");
        end else begin
                            $display("  Signs matched, no negation needed");
                        end
                        debug_state = 31;
                    end
                end
                
                31: begin
                    // Wait for end of multiplication
                    if (cpu.PC >= 280) begin
                        $display("\nCRITICAL: MULTIPLICATION COMPLETE");
                        $display("  Final result: R1 (low)=%h, R2 (high)=%h", R1_debug, R2_debug);
                        
                        // Determine which test case is running
                        if (cpu.if_stage.inst_mem.memory[0][31:25] == `OP_ADI && 
                            cpu.if_stage.inst_mem.memory[6][31:25] == `OP_ADI) begin
                            
                            // Test case 1 (0*0)
                            if (cpu.if_stage.inst_mem.memory[0][15:0] == 16'h0 && 
                                cpu.if_stage.inst_mem.memory[6][15:0] == 16'h0) begin
                                $display("  Test Case: 0 * 0");
                                $display("  Expected: 0x00000000:00000000");
                                if (R1_debug == 32'h0 && R2_debug == 32'h0) begin
                                    $display("  Actual: 0x%h:%h - CORRECT", R2_debug, R1_debug);
                                end else begin
                                    $display("  Actual: 0x%h:%h - ERROR", R2_debug, R1_debug);
                                end
                            end
                            // Test case 2 (1*1)
                            else if (cpu.if_stage.inst_mem.memory[0][15:0] == 16'h1 && 
                                     cpu.if_stage.inst_mem.memory[6][15:0] == 16'h1) begin
                                $display("  Test Case: 1 * 1");
                                $display("  Expected: 0x00000000:00000001");
                                if (R1_debug == 32'h1 && R2_debug == 32'h0) begin
                                    $display("  Actual: 0x%h:%h - CORRECT", R2_debug, R1_debug);
        end else begin
                                    $display("  Actual: 0x%h:%h - ERROR", R2_debug, R1_debug);
                                end
                            end
                        end
                        
                        debug_state = 0; // Reset for next test case
                    end
                end
            endcase
            
            prev_PC = cpu.PC;
        end else begin
            // Reset debug state when CPU is reset
            debug_state = 0;
            prev_PC = 0;
        end
    end

endmodule