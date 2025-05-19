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
    // PC constants for multiplication program
    localparam PC_CORE = 200;           // Start of multiplication program
    localparam PC_LOADER_DONE = PC_CORE;   // End of loader
    localparam PC_START = PC_CORE;      // Initial setup
    localparam PC_INIT_R1 = PC_CORE + 10; // Initialize R1
    localparam PC_INIT_R2 = PC_CORE + 15; // Initialize R2
    localparam PC_ABS_A_SIGN = PC_CORE + 20; // Get sign of A
    localparam PC_ABS_A_BZ = PC_CORE + 30;   // Branch for A sign
    localparam PC_ABS_B_SIGN = PC_CORE + 50; // Get sign of B
    localparam PC_ABS_B_BZ = PC_CORE + 60;   // Branch for B sign
    localparam PC_COUNTER_SET = PC_CORE + 85; // Set up counter
    localparam PC_LOOP_HEAD = PC_CORE + 90;   // Start of main loop
    localparam PC_LSB_BZ = PC_CORE + 95;      // Branch on LSB
    localparam PC_LOOP_TAIL = PC_CORE + 135;  // End of loop iteration
    localparam PC_LOOP_BRANCH = PC_CORE + 150; // Loop back branch
    localparam PC_SIGN_XOR = PC_CORE + 155;    // XOR signs
    localparam PC_SIGN_BZ = PC_CORE + 160;     // Branch on sign
    localparam PC_HALT = PC_CORE + 182;        // Program halt

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

    // Debug state for pipeline delayed monitoring
    reg [31:0] debug_state = 0;
    reg [31:0] prev_debug_pc = 0;
    reg [31:0] pipeline_delay_counter = 0;
    reg [3:0] delay_cycles = 0;
    
    // -----------------------------------------------------------------------------
    //  pack_instruction  –  emit a 32-bit instruction word
    //                       (matches fields expected by instructionDecoder)
    // -----------------------------------------------------------------------------
    function [31:0] pack_instruction;
        input [6:0]  opcode;
        input [4:0]  rd;
        input [4:0]  rs1;
        input [4:0]  rs2;       // ignored for the I-type formats
        input [14:0] imm;       // 15-bit signed immediate
        reg   [31:0] word;
    begin
        // ─────────────────────────────────────────────────────────────────────────
        // Default: **R-type**  –  opcode | rd | rs1 | rs2 | 10×pad
        // ─────────────────────────────────────────────────────────────────────────
        word = {opcode, rd, rs1, rs2, 10'b0};

        // ─────────────────────────────────────────────────────────────────────────
        // I-type  (immediate arithmetic / logic / shifts)
        // Branch  (BZ / BNZ)
        // Jump    (JMP / JML)
        // All use: opcode | rd | rs1 | imm[14:0]
        // ─────────────────────────────────────────────────────────────────────────
        if ( opcode == `OP_ADI  || opcode == `OP_SBI  || opcode == `OP_ANI ||
             opcode == `OP_ORI  || opcode == `OP_XRI  || opcode == `OP_AIU ||
             opcode == `OP_SIU  || opcode == `OP_LSL  || opcode == `OP_LSR ||
             opcode == `OP_BZ   || opcode == `OP_BNZ  ||
             opcode == `OP_JMP  || opcode == `OP_JML ) begin
            word = {opcode, rd, rs1, imm[14:0]};
        end

        // Done
        pack_instruction = word;
    end
    endfunction

    // Helper task to add NOPs
    task add_nops(
        output integer idx,
        input integer count
    );
    begin
        for (integer k = 0; k < count; k = k + 1) begin
            instruction_memory[idx++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 15'b0);
        end
    end
    endtask

    reg [4:0] scratch_reg;
    // Helper task to load a 32-bit value into a register
    // Uses a fixed pattern to ensure consistent instruction count for all values
    task load32 (
        output integer idx,
        input  [4:0]  rd,
        input  [31:0] value
    );
    begin
        // Pick R13 as our scratch register for patching (should be unused by test code)
        scratch_reg = 5'd13;
        
        // Load bits 0-14 (low 15 bits)
        instruction_memory[idx++] = pack_instruction(`OP_ADI, rd, `R0, 5'd0, value[14:0]);
        add_nops(idx, 4);
        
        // Always handle bit 15 for consistent instruction count
        // Create mask 0x8000 in scratch register
        instruction_memory[idx++] = pack_instruction(`OP_ADI, scratch_reg, `R0, 5'd0, 15'd1);
        add_nops(idx, 4);
        instruction_memory[idx++] = pack_instruction(`OP_LSL, scratch_reg, scratch_reg, 5'd0, 15'd15);
        add_nops(idx, 4);

        // Conditionally OR mask with our value if bit 15 is set, otherwise set to 0
        if (value[15]) begin
            instruction_memory[idx++] = pack_instruction(`OP_OR, rd, rd, scratch_reg, 5'd0);
        end else begin
            instruction_memory[idx++] = pack_instruction(`OP_ADI, rd, rd, 5'd0, 15'd0); // NOP effect but same cycle count
        end
        add_nops(idx, 4);
        
        // Shift left by 16 to make room for high bits
        instruction_memory[idx++] = pack_instruction(`OP_LSL, rd, rd, 5'd0, 15'd16);
        add_nops(idx, 4);
        
        // OR in bits 16-30 (high 15 bits, excluding bit 31)
        instruction_memory[idx++] = pack_instruction(`OP_ORI, rd, rd, 5'd0, value[30:16]);
        add_nops(idx, 4);
        
        // Always handle bit 31 for consistent instruction count
        // Create mask 0x80000000 in scratch register
        instruction_memory[idx++] = pack_instruction(`OP_ADI, scratch_reg, `R0, 5'd0, 15'd1);
        add_nops(idx, 4);
        instruction_memory[idx++] = pack_instruction(`OP_LSL, scratch_reg, scratch_reg, 5'd0, 15'd31);
        add_nops(idx, 4);

        // Conditionally OR mask with our value if bit 31 is set, otherwise set to 0
        if (value[31]) begin
            instruction_memory[idx++] = pack_instruction(`OP_OR, rd, rd, scratch_reg, 5'd0);
        end else begin
            instruction_memory[idx++] = pack_instruction(`OP_ADI, rd, rd, 5'd0, 15'd0); // NOP effect but same cycle count
        end
        add_nops(idx, 4);
    end
    endtask

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
        for (i = 0; i < PC_CORE; i = i + 1) begin
            instruction_memory[i] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 15'b0);  // NOP instruction
        end
        
    // ============================================================================
    // 32-bit signed × 32-bit signed  → 64-bit product
    // Shift–and–add with explicit carry; all RAW hazards separated by 4 NOPs
    // ----------------------------------------------------------------------------
    //  Reg map
    //  R1  = product low            R2  = product high
    //  R3  = multiplicand (|A|)     R4  = multiplier  (|B|)
    //  R5  = running carry          R6  = – free –
    //  R7  = sign(A)                R8  = sign(B)
    //  R9  = A&1 test               R10 = R7 ⊕ R8  (final sign)
    //  R11 = sign(R1)               R12 = sign(R3)  (carry trick)
    //  R13 = scratch                R31 = loop counter (32 … 0)
    // ============================================================================

    m = PC_CORE;      // Core starts at PC_CORE (moved beyond loader area)
    // ---------------------------------------------------------------------------
    // 1.  Move the operands out of R1/R2 so product registers are free
    // ---------------------------------------------------------------------------
    instruction_memory[m++] = pack_instruction(`OP_MOV, `R3, `R1, 5'd0, 15'd0); // PC_CORE
    // Clear scratch register to avoid any loader residue
    instruction_memory[m++] = pack_instruction(`OP_ADI, `R13, `R0, 5'd0, 15'd0); // PC_CORE+1

    instruction_memory[m++] = pack_instruction(`OP_MOV, `R4, `R2, 5'd0, 15'd0); // PC_CORE+2
    instruction_memory[m++] = pack_instruction(`OP_NOP, 0,0,0,15'd0);           // PC_CORE+3-PC_CORE+6
    instruction_memory[m++] = pack_instruction(`OP_NOP, 0,0,0,15'd0);           // PC_CORE+4
    instruction_memory[m++] = pack_instruction(`OP_NOP, 0,0,0,15'd0);           // PC_CORE+5
    instruction_memory[m++] = pack_instruction(`OP_NOP, 0,0,0,15'd0);           // PC_CORE+6

    // ---------------------------------------------------------------------------
    // 2.  Zero-init product and carry
    // ---------------------------------------------------------------------------
    instruction_memory[m++] = pack_instruction(`OP_ADI, `R1, `R0, 5'd0, 15'd0); // PC_CORE+7
    instruction_memory[m++] = pack_instruction(`OP_NOP, 0,0,0,15'd0);            // PC_CORE+8-PC_CORE+11
    instruction_memory[m++] = pack_instruction(`OP_NOP, 0,0,0,15'd0);            // PC_CORE+9
    instruction_memory[m++] = pack_instruction(`OP_NOP, 0,0,0,15'd0);            // PC_CORE+10
    instruction_memory[m++] = pack_instruction(`OP_NOP, 0,0,0,15'd0);            // PC_CORE+11

    instruction_memory[m++] = pack_instruction(`OP_ADI, `R2, `R0, 5'd0, 15'd0); // PC_CORE+12
    instruction_memory[m++] = pack_instruction(`OP_NOP, 0,0,0,15'd0);            // PC_CORE+13-PC_CORE+16
    instruction_memory[m++] = pack_instruction(`OP_NOP, 0,0,0,15'd0);            // PC_CORE+14
    instruction_memory[m++] = pack_instruction(`OP_NOP, 0,0,0,15'd0);            // PC_CORE+15
    instruction_memory[m++] = pack_instruction(`OP_NOP, 0,0,0,15'd0);            // PC_CORE+16

    // ---------------------------------------------------------------------------
    // 3.  |R3| ← abs(A)     R7←sign(A)      (special case for 0x8000_0000)
    // ---------------------------------------------------------------------------
    instruction_memory[m++] = pack_instruction(`OP_LSR, `R7 ,`R3 ,5'd0,15'd31); // PC_CORE+17
    instruction_memory[m++] = pack_instruction(`OP_NOP, 0,0,0,15'd0);            // PC_CORE+18-PC_CORE+21
    instruction_memory[m++] = pack_instruction(`OP_NOP, 0,0,0,15'd0);            // PC_CORE+19
    instruction_memory[m++] = pack_instruction(`OP_NOP, 0,0,0,15'd0);            // PC_CORE+20
    instruction_memory[m++] = pack_instruction(`OP_NOP, 0,0,0,15'd0);            // PC_CORE+21

    instruction_memory[m++] = pack_instruction(`OP_ADD, `R13,`R3 ,`R3 ,5'd0);   // PC_CORE+22 2×R3
    instruction_memory[m++] = pack_instruction(`OP_NOP, 0,0,0,15'd0);            // PC_CORE+23-PC_CORE+26
    instruction_memory[m++] = pack_instruction(`OP_NOP, 0,0,0,15'd0);            // PC_CORE+24
    instruction_memory[m++] = pack_instruction(`OP_NOP, 0,0,0,15'd0);            // PC_CORE+25
    instruction_memory[m++] = pack_instruction(`OP_NOP, 0,0,0,15'd0);            // PC_CORE+26

    //  ▸ MAXNEG?  Skip negation to PC_ABS_A_SIGN
    instruction_memory[m++] = pack_instruction(`OP_BZ , `R13,5'd0,5'd0,15'd19); // PC_CORE+27 →PC_ABS_A_SIGN
    instruction_memory[m++] = pack_instruction(`OP_NOP, 0,0,0,15'd0);            // PC_CORE+28-PC_CORE+31
    instruction_memory[m++] = pack_instruction(`OP_NOP, 0,0,0,15'd0);            // PC_CORE+29
    instruction_memory[m++] = pack_instruction(`OP_NOP, 0,0,0,15'd0);            // PC_CORE+30
    instruction_memory[m++] = pack_instruction(`OP_NOP, 0,0,0,15'd0);            // PC_CORE+31

    //  ▸ Positive?  Skip negation to PC_ABS_A_SIGN
    instruction_memory[m++] = pack_instruction(`OP_BZ , `R7 ,5'd0,5'd0,15'd14); // PC_CORE+32 →PC_ABS_A_SIGN
    instruction_memory[m++] = pack_instruction(`OP_NOP, 0,0,0,15'd0);            // PC_CORE+33-PC_CORE+36
    instruction_memory[m++] = pack_instruction(`OP_NOP, 0,0,0,15'd0);            // PC_CORE+34
    instruction_memory[m++] = pack_instruction(`OP_NOP, 0,0,0,15'd0);            // PC_CORE+35
    instruction_memory[m++] = pack_instruction(`OP_NOP, 0,0,0,15'd0);            // PC_CORE+36

    instruction_memory[m++] = pack_instruction(`OP_NOT,`R3 ,`R3 ,5'd0,15'd0);   // PC_CORE+37
    instruction_memory[m++] = pack_instruction(`OP_NOP, 0,0,0,15'd0);            // PC_CORE+38-PC_CORE+41
    instruction_memory[m++] = pack_instruction(`OP_NOP, 0,0,0,15'd0);            // PC_CORE+39
    instruction_memory[m++] = pack_instruction(`OP_NOP, 0,0,0,15'd0);            // PC_CORE+40
    instruction_memory[m++] = pack_instruction(`OP_NOP, 0,0,0,15'd0);            // PC_CORE+41

    instruction_memory[m++] = pack_instruction(`OP_ADI,`R3 ,`R3 ,5'd0,15'd1);   // PC_CORE+42
    instruction_memory[m++] = pack_instruction(`OP_NOP, 0,0,0,15'd0);            // PC_CORE+43-PC_CORE+46
    instruction_memory[m++] = pack_instruction(`OP_NOP, 0,0,0,15'd0);            // PC_CORE+44
    instruction_memory[m++] = pack_instruction(`OP_NOP, 0,0,0,15'd0);            // PC_CORE+45
    instruction_memory[m++] = pack_instruction(`OP_NOP, 0,0,0,15'd0);            // PC_CORE+46

    // ---------------------------------------------------------------------------
    // 4.  |R4| ← abs(B)     R8←sign(B)      (same MAXNEG guard)
    // ---------------------------------------------------------------------------
    instruction_memory[m++] = pack_instruction(`OP_LSR, `R8 ,`R4 ,5'd0,15'd31); // PC_CORE+47
    instruction_memory[m++] = pack_instruction(`OP_NOP, 0,0,0,15'd0);            // PC_CORE+48-PC_CORE+51
    instruction_memory[m++] = pack_instruction(`OP_NOP, 0,0,0,15'd0);            // PC_CORE+49
    instruction_memory[m++] = pack_instruction(`OP_NOP, 0,0,0,15'd0);            // PC_CORE+50
    instruction_memory[m++] = pack_instruction(`OP_NOP, 0,0,0,15'd0);            // PC_CORE+51

    instruction_memory[m++] = pack_instruction(`OP_ADD, `R13,`R4 ,`R4 ,5'd0);   // PC_CORE+52
    instruction_memory[m++] = pack_instruction(`OP_NOP, 0,0,0,15'd0);            // PC_CORE+53-PC_CORE+56
    instruction_memory[m++] = pack_instruction(`OP_NOP, 0,0,0,15'd0);            // PC_CORE+54
    instruction_memory[m++] = pack_instruction(`OP_NOP, 0,0,0,15'd0);            // PC_CORE+55
    instruction_memory[m++] = pack_instruction(`OP_NOP, 0,0,0,15'd0);            // PC_CORE+56

    //  ▸ MAXNEG?  Skip negation to PC_COUNTER_SET
    instruction_memory[m++] = pack_instruction(`OP_BZ , `R13,5'd0,5'd0,15'd19); // PC_CORE+57 →PC_COUNTER_SET
    instruction_memory[m++] = pack_instruction(`OP_NOP, 0,0,0,15'd0);            // PC_CORE+58-PC_CORE+61
    instruction_memory[m++] = pack_instruction(`OP_NOP, 0,0,0,15'd0);            // PC_CORE+59
    instruction_memory[m++] = pack_instruction(`OP_NOP, 0,0,0,15'd0);            // PC_CORE+60
    instruction_memory[m++] = pack_instruction(`OP_NOP, 0,0,0,15'd0);            // PC_CORE+61

    //  ▸ Positive?  Skip negation to PC_COUNTER_SET
    instruction_memory[m++] = pack_instruction(`OP_BZ , `R8 ,5'd0,5'd0,15'd14); // PC_CORE+62 →PC_COUNTER_SET
    instruction_memory[m++] = pack_instruction(`OP_NOP, 0,0,0,15'd0);            // PC_CORE+63-PC_CORE+66
    instruction_memory[m++] = pack_instruction(`OP_NOP, 0,0,0,15'd0);            // PC_CORE+64
    instruction_memory[m++] = pack_instruction(`OP_NOP, 0,0,0,15'd0);            // PC_CORE+65
    instruction_memory[m++] = pack_instruction(`OP_NOP, 0,0,0,15'd0);            // PC_CORE+66

    instruction_memory[m++] = pack_instruction(`OP_NOT,`R4 ,`R4 ,5'd0,15'd0);   // PC_CORE+67
    instruction_memory[m++] = pack_instruction(`OP_NOP, 0,0,0,15'd0);            // PC_CORE+68-PC_CORE+71
    instruction_memory[m++] = pack_instruction(`OP_NOP, 0,0,0,15'd0);            // PC_CORE+69
    instruction_memory[m++] = pack_instruction(`OP_NOP, 0,0,0,15'd0);            // PC_CORE+70
    instruction_memory[m++] = pack_instruction(`OP_NOP, 0,0,0,15'd0);            // PC_CORE+71

    instruction_memory[m++] = pack_instruction(`OP_ADI,`R4 ,`R4 ,5'd0,15'd1);   // PC_CORE+72
    instruction_memory[m++] = pack_instruction(`OP_NOP, 0,0,0,15'd0);            // PC_CORE+73-PC_CORE+76
    instruction_memory[m++] = pack_instruction(`OP_NOP, 0,0,0,15'd0);            // PC_CORE+74
    instruction_memory[m++] = pack_instruction(`OP_NOP, 0,0,0,15'd0);            // PC_CORE+75
    instruction_memory[m++] = pack_instruction(`OP_NOP, 0,0,0,15'd0);            // PC_CORE+76

    // ---------------------------------------------------------------------------
    // 5.  carry ←0 ,  cnt ←32
    // ---------------------------------------------------------------------------
    instruction_memory[m++] = pack_instruction(`OP_ADI,`R5 ,`R0 ,5'd0,15'd0);   // PC_CORE+77
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+78-PC_CORE+81
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+79
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+80
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+81

    instruction_memory[m++] = pack_instruction(`OP_ADI,`R31,`R0 ,5'd0,15'd32);  // PC_CORE+82
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+83-PC_CORE+86
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+84
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+85
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+86

    // ---------------------------------------------------------------------------
    // 6.  LOOP-START  (PC = 190)
    // ---------------------------------------------------------------------------
    instruction_memory[m++] = pack_instruction(`OP_ANI,`R9 ,`R4 ,5'd0,15'd1);   // PC_CORE+87
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+88-PC_CORE+91
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+89
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+90
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+91

    //  ▸ LSB = 0?  skip ADD-carry block to PC_LOOP_TAIL
    instruction_memory[m++] = pack_instruction(`OP_BZ ,`R9 ,5'd0,5'd0,15'd39);   // PC_CORE+92 →PC_LOOP_TAIL
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+93-PC_CORE+96
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+94
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+95
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+96

    // -----  (LSB = 1)  product_low += multiplicand  ----------------------------
    instruction_memory[m++] = pack_instruction(`OP_ADD,`R1 ,`R1 ,`R3 ,5'd0);     // PC_CORE+97
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+98-PC_CORE+101
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+99
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+100
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+101

    // -----  unsigned-carry trick  ----------------------------------------------
    instruction_memory[m++] = pack_instruction(`OP_SLT,`R5 ,`R1 ,`R3 ,5'd0);      // PC_CORE+102
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+103-PC_CORE+106
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+104
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+105
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+106

    instruction_memory[m++] = pack_instruction(`OP_LSR,`R11,`R1 ,5'd0,15'd31);      // PC_CORE+107
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+108-PC_CORE+111
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+109
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+110
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+111

    instruction_memory[m++] = pack_instruction(`OP_XOR,`R5 ,`R5 ,`R11,5'd0);        // PC_CORE+112
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+113-PC_CORE+116
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+114
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+115
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+116

    instruction_memory[m++] = pack_instruction(`OP_LSR,`R12,`R3 ,5'd0,15'd31);       // PC_CORE+117
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+118-PC_CORE+121
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+119
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+120
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+121

    instruction_memory[m++] = pack_instruction(`OP_XOR,`R5 ,`R5 ,`R12,5'd0);        // PC_CORE+122
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+123-PC_CORE+126
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+124
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+125
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+126

    instruction_memory[m++] = pack_instruction(`OP_ADD,`R2 ,`R2 ,`R5 ,5'd0);         // PC_CORE+127
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+128-PC_CORE+131
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+129
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+130
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+131

    // -----  common tail of loop  -----------------------------------------------
    instruction_memory[m++] = pack_instruction(`OP_LSR,`R4 ,`R4 ,5'd0,15'd1);        // PC_CORE+132
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+133-PC_CORE+136
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+134
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+135
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+136

    instruction_memory[m++] = pack_instruction(`OP_SBI,`R31,`R31,5'd0,15'd1);         // PC_CORE+137
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+138-PC_CORE+141
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+139
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+140
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+141

    instruction_memory[m++] = pack_instruction(`OP_LSL,`R3 ,`R3 ,5'd0,15'd1);         // PC_CORE+142
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+143-PC_CORE+146
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+144
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+145
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+146

    //  ▸ loop back to PC_LOOP_HEAD : offset = PC_LOOP_HEAD − (PC_LOOP_BRANCH+1) = −61
    instruction_memory[m++] = pack_instruction(`OP_BNZ,`R31,5'd0,5'd0,-15'sd61);    // PC_CORE+147 → Jump back to PC_LOOP_HEAD
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+148-PC_CORE+151
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+149
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+150
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+151

    // ---------------------------------------------------------------------------
    // 7.  Apply sign  (R10 = R7 ⊕ R8)
    // ---------------------------------------------------------------------------
    instruction_memory[m++] = pack_instruction(`OP_XOR,`R10,`R7 ,`R8 ,5'd0);         // PC_CORE+152
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+153-PC_CORE+156
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+154
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+155
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+156

    //  ▸ signs equal?  skip 2-complement to PC_HALT
    instruction_memory[m++] = pack_instruction(`OP_BZ ,`R10,5'd0,5'd0,15'd24);         // PC_CORE+157 →PC_HALT
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+158-PC_CORE+161
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+159
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+160
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+161

    instruction_memory[m++] = pack_instruction(`OP_NOT,`R2 ,`R2 ,5'd0,15'd0);          // PC_CORE+162
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+163-PC_CORE+166
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+164
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+165
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+166

    instruction_memory[m++] = pack_instruction(`OP_ADI,`R2 ,`R2 ,5'd0,15'd1);          // PC_CORE+167
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+168-PC_CORE+171
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+169
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+170
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+171

    instruction_memory[m++] = pack_instruction(`OP_NOT,`R1 ,`R1 ,5'd0,15'd0);          // PC_CORE+172
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+173-PC_CORE+176
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+174
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+175
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+176

    instruction_memory[m++] = pack_instruction(`OP_ADI,`R1 ,`R1 ,5'd0,15'd1);          // PC_CORE+177
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+178-PC_CORE+181
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+179
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+180
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+181

    // ---------------------------------------------------------------------------
    // 8.  HALT  (JMP  –1)
    // ---------------------------------------------------------------------------
    instruction_memory[m++] = pack_instruction(`OP_JMP,5'd0,5'd0,5'd0,-15'h7FFF);    // PC_CORE+182 // Halt by jumping -1 (PC+1-1)
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+183-PC_CORE+186
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+184
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+185
    instruction_memory[m++] = pack_instruction(`OP_NOP,0,0,0,15'd0);             // PC_CORE+186

//  … rest of I-mem already filled with NOPs

    //-------------------------------------------------------------------------
    // 9. Fill remaining memory with NOPs.
    //-------------------------------------------------------------------------
    for (i = m; i < 1024; i = i + 1) begin
            instruction_memory[i] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 15'h0);
    end
end

    // Task to wait for program completion (PC = 285 and stable)
    task wait_for_completion;
        begin
            stable_count = 0;
            stuck_count = 0;
            last_pc = 0;

            while (stable_count < 5) begin
                @(posedge clk);
                
                // Check if PC is stable at the expected final halt address
                // HALT instruction at address PC_HALT with JMP -1 should keep PC at PC_HALT or nearby
                if (cpu.PC == PC_HALT || cpu.PC == PC_HALT + 1 || cpu.PC == PC_HALT + 2) begin
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
            $display("Program execution complete - PC stable at PC_HALT (%0d)", PC_HALT);
        end
    endtask

    //---------------------------------------------------------------------
    // Simple self-contained test executor
    //---------------------------------------------------------------------
    task run_test_case(
            input  [8*32-1:0] name,    // Label printed to the console (32 chars max)
            input  [31:0] opA,      // Multiplicand  (R1)
            input  [31:0] opB,      // Multiplier    (R2)
            input  [31:0] exp_lo,   // Expected low  32-b result
            input  [31:0] exp_hi    // Expected high 32-b result
        );
        integer j, m, pc_offset;
    begin
        $display("\n%s", name);

        //--------------------------------------------------------------
        // 1. Load 32-bit values with fixed instruction count
        //--------------------------------------------------------------
        m = 0;
        load32(m, `R1, opA);
        load32(m, `R2, opB);
        load32(m, `R3, exp_lo);
        load32(m, `R4, exp_hi);

        // Jump to multiplication algorithm at address PC_CORE
        pc_offset = PC_CORE - (m + 1);
        instruction_memory[m++] = pack_instruction(`OP_JMP, 5'd0, 5'd0, 5'd0, pc_offset[14:0]);
        
        $display("Loader size: %0d instructions, Jump offset: %0d", m, pc_offset);

        //--------------------------------------------------------------
        // 2.  Push the freshly-built loader into the DUT's I-mem.
        //--------------------------------------------------------------
        for (j = 0; j < 1024; j = j + 1)
            cpu.if_stage.inst_mem.memory[j] = instruction_memory[j];

        //--------------------------------------------------------------
        // 3.  Run the program, wait for it to halt, and score it.
        //--------------------------------------------------------------
        rst = 1;  #20;  rst = 0;  #1;
        wait_for_completion();

        if (R1_debug === exp_lo && R2_debug === exp_hi) begin
            $display("%s PASSED", name);
            tests_passed++;
        end else begin
            $display("%s FAILED -- got 0x%h:%h   expected 0x%h:%h",
                     name, R2_debug, R1_debug, exp_hi, exp_lo);
            tests_failed++;
        end
    end
    endtask

    //----------------------------------------------------------------------
    //  Test-vector table -- call run_test_case() for each entry
    //----------------------------------------------------------------------
    initial begin
        $dumpfile("hw6_tb.vcd");
        $dumpvars(0, hw6_tb);

        $display("Begin Test Cases");

        tests_passed = 0;
        tests_failed = 0;
        total_tests  = 10;

        // ------------ 10 signed 32×32→64 test cases ------------------
        run_test_case("Test 1: 0  * 0",        32'h00000000, 32'h00000000,    // 0 * 0
                                              32'h00000000, 32'h00000000);     // = 0

        run_test_case("Test 2: 1  * 1",        32'h00000001, 32'h00000001,    // 1 * 1
                                              32'h00000001, 32'h00000000);     // = 1

        run_test_case("Test 3: -2 * -3",       32'hFFFFFFFE, 32'hFFFFFFFD,    // -2 * -3
                                              32'h00000006, 32'h00000000);     // = 6

        run_test_case("Test 4:  2 * -3",       32'h00000002, 32'hFFFFFFFD,    // 2 * -3
                                              32'hFFFFFFFA, 32'hFFFFFFFF);     // = -6

        run_test_case("Test 5: -2 *  3",       32'hFFFFFFFE, 32'h00000003,    // -2 * 3
                                              32'hFFFFFFFA, 32'hFFFFFFFF);     // = -6

        run_test_case("Test 6:  5 * 0",        32'h00000005, 32'h00000000,    // 5 * 0
                                              32'h00000000, 32'h00000000);     // = 0

        run_test_case("Test 7: -5 * 0",        32'hFFFFFFFB, 32'h00000000,    // -5 * 0
                                              32'h00000000, 32'h00000000);     // = 0

        run_test_case("Test 8: MAXPOS*MAXPOS", 32'h7FFFFFFF, 32'h7FFFFFFF,    // 2147483647 * 2147483647
                                              32'h00000001, 32'h3FFFFFFF);     // = 4611686014132420609

        run_test_case("Test 9: MAXNEG*MAXNEG", 32'h80000000, 32'h80000000,    // -2147483648 * -2147483648
                                              32'h00000000, 32'h40000000);     // = 4611686018427387904

        run_test_case("Test10: MAXPOS*MAXNEG", 32'h7FFFFFFF, 32'h80000000,    // 2147483647 * -2147483648
                                              32'h80000000, 32'hC0000000);     // = -4611686016279904256

        //------------------------------------------------------------------
        $display("\n=== Test Summary ===");
        $display("Total Tests : %0d", total_tests);
        $display("Tests Passed: %0d", tests_passed);
        $display("Tests Failed: %0d", tests_failed);
        $finish;
    end

    // -----------------------------------------------------------------------------
    // Debug FSM – prints a high-level trace of the multiplier
    // -----------------------------------------------------------------------------
    integer settle_cnt /* synthesis keep */;
    integer halt_cnt;

    always @(posedge clk) begin
        if (rst) begin
            debug_state  <= 0;
            settle_cnt   <= 0;
        end else begin
            //----------------------------------------------------------
            // small helper – wait N cycles for WB to update registers
            //----------------------------------------------------------
            if (settle_cnt != 0)
                settle_cnt <= settle_cnt - 1;

            case (debug_state)
            // --------------------------------------------------------
            // 0  – wait for loader to hand control to multiplier core
            // --------------------------------------------------------
            0 : if (cpu.PC >= PC_LOADER_DONE) begin
                    $display("\n=== Test-vector started @%0t ns ===",$time);
                    debug_state <= 1;
            end
            // --------------------------------------------------------
            // 1  – first MOV completes (R3=mulcand) → wait 3 cycles
            // --------------------------------------------------------
            1 : if (cpu.PC == PC_START+4) begin  // MOV + 4 NOPs
                    $display("SETUP: R3 (multiplicand) <= %h", R3_debug);
                    settle_cnt  <= 3;            // pipeline latency to WB
                    debug_state <= 2;
            end
            // --------------------------------------------------------
            // 2  – second MOV completes (R4=multiplier)
            // --------------------------------------------------------
            2 : if (settle_cnt==0 && cpu.PC == PC_START+9) begin
                    $display("SETUP: R4 (multiplier)   <= %h", R4_debug);
                    debug_state <= 3;
            end
            // --------------------------------------------------------
            // 3  – product registers zeroed
            // --------------------------------------------------------
            3 : if (cpu.PC == PC_INIT_R2+4) begin // ADI + 4 NOPs
                    $display("INIT : R1/R2 cleared");
                    debug_state <= 4;
            end
            // --------------------------------------------------------
            // 4  – sign of A acquired
            // --------------------------------------------------------
            4 : if (cpu.PC == PC_ABS_A_SIGN+4) begin
                    $display("ABS  : sign(A)=R7=%0d  value now R3=%h",R7_debug,R3_debug);
                    debug_state <= 5;
            end
            // branch @130 -------------------------------------------------
            5 : if (cpu.PC == PC_ABS_A_BZ) begin
                    #1; // allow fetch of next instruction
                    $display("BR   : BZ @%3d %s-TAKEN  (A %s negative)",
                            PC_ABS_A_BZ,
                            (cpu.PC==PC_ABS_A_BZ+1)?"":"NOT ",
                            (cpu.PC==PC_ABS_A_BZ+1)?"is not":"is");
                    debug_state <= 6;
            end
            // sign of B ---------------------------------------------------
            6 : if (cpu.PC == PC_ABS_B_SIGN+4) begin
                    $display("ABS  : sign(B)=R8=%0d  value now R4=%h",R8_debug,R4_debug);
                    debug_state <= 7;
            end
            // branch @160 -------------------------------------------------
            7 : if (cpu.PC == PC_ABS_B_BZ) begin
                    #1;
                    $display("BR   : BZ @%3d %s-TAKEN  (B %s negative)",
                            PC_ABS_B_BZ,
                            (cpu.PC==PC_ABS_B_BZ+1)?"":"NOT ",
                            (cpu.PC==PC_ABS_B_BZ+1)?"is not":"is");
                    debug_state <= 8;
            end
            // counter set -------------------------------------------------
            8 : if (cpu.PC == PC_COUNTER_SET+4) begin
                    $display("LOOP : counter R31 = %0d", R31_debug);
                    debug_state <= 9;
            end
            // --------------------------------------------------------
            // 9  – main loop (one message each iteration)
            // --------------------------------------------------------
            9 : if (cpu.PC == PC_LOOP_HEAD+4) begin
                    $display("\nITER : R31=%0d  R4 LSB=%0d  R1=%h  R2=%h",
                            R31_debug, R9_debug[0], R1_debug,R2_debug);
                    debug_state <= 10;
            end
            // branch on LSB ----------------------------------------------
            10: if (cpu.PC == PC_LSB_BZ) begin
                    #1;
                    $display("BR   : BZ @%3d %s-TAKEN (LSB %s)",
                            PC_LSB_BZ,
                            (cpu.PC==PC_LSB_BZ+1)?"":"NOT ",
                            (cpu.PC==PC_LSB_BZ+1)?"0":"1");
                    debug_state <= 11;
            end
            // loop tail reached ------------------------------------------
            11: if (cpu.PC == PC_LOOP_TAIL+4) begin
                    $display("TAIL : after shifts  R3=%h  R4=%h  carry=%0d",
                            R3_debug, R4_debug, R5_debug);
                    debug_state <= 12;
            end
            // back-branch / exit -----------------------------------------
            12: if (cpu.PC == PC_LOOP_BRANCH) begin
                    #1;
                    if (cpu.PC==PC_LOOP_BRANCH+1) begin
                        $display("BR   : BNZ EXIT  (R31==0)");
                        debug_state <= 13;       // go finish
                    end else begin
                        $display("BR   : BNZ LOOP  (R31=%0d)",R31_debug);
                        debug_state <= 9;        // next iteration
                    end
            end
            // --------------------------------------------------------
            // 13 – sign fix-up
            // --------------------------------------------------------
            13: if (cpu.PC == PC_SIGN_XOR+4) begin
                    $display("SIGN : R7^R8 = %0d  (negate=%0d)",R10_debug,R10_debug);
                    debug_state <= 14;
            end
            14: if (cpu.PC == PC_SIGN_BZ) begin
                    #1;
                    $display("BR   : BZ @%3d %s-TAKEN (result %s negated)",
                            PC_SIGN_BZ,
                            (cpu.PC==PC_SIGN_BZ+1)?"":"NOT ",
                            (cpu.PC==PC_SIGN_BZ+1)?"NOT":"will be");
                    debug_state <= 15;
            end
            // --------------------------------------------------------
            // 15 – program halts → dump final product
            // --------------------------------------------------------
            15: if (cpu.PC >= PC_HALT) begin
                    $display("DONE :  R2:R1 = %h:%h", R2_debug,R1_debug);
                    debug_state <= 16;
            end
            // --------------------------------------------------------
            // 16 – wait 5 cycles at HALT then auto-reset FSM
            // --------------------------------------------------------
            16: begin
                    halt_cnt = 0;
                    if (cpu.PC >= PC_HALT) halt_cnt = halt_cnt + 1;
                    if (halt_cnt == 5) begin
                        halt_cnt    = 0;
                        debug_state = 0;
                        $display("=== Next test-vector will start ===");
                    end
            end
            endcase
        end
    end


endmodule