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
            // Explicitly align each field to its proper bit position
            pack_instruction = {opcode, rd, rs1, rs2, imm[9:0]};
            
            // For I-type instructions that use the full 15-bit immediate
            if (opcode == `OP_ADI || opcode == `OP_SBI || opcode == `OP_ANI || 
                opcode == `OP_ORI || opcode == `OP_XRI || opcode == `OP_AIU || 
                opcode == `OP_SIU || opcode == `OP_BZ || opcode == `OP_BNZ || 
                opcode == `OP_JMP || opcode == `OP_LSL || opcode == `OP_LSR) begin
                pack_instruction = {opcode, rd, rs1, imm};
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

    // Debug instruction flow - Monitor key signals on every clock cycle
    // This will help identify where and how instructions are getting corrupted
    always @(posedge clk) begin
        if (!rst) begin
            $display("DEBUG [%0t] PC=%h | IF_inst=%h | DOF_inst=%h | opcode=%b [%h] | RW=%b, FS=%h, BS=%b",
                     $time, PC_debug, IF_instruction_debug, DOF_instruction_debug, 
                     opcode_debug, opcode_debug, RW_debug, FS_debug, BS_debug);
            
            // Track instruction fetch from memory to verify correct instructions are fetched
            $display("         MEM[PC] = %h", cpu.if_stage.inst_mem.memory[PC_debug[9:0]]);
            
            // Special check for invalid opcode detection
            if (opcode_debug == 7'b0000100) begin  // opcode 0x04
                $display("WARNING: Detected potentially problematic opcode 0x04 at PC=%h", PC_debug);
                $display("         IF_inst=%h, DOF_inst=%h", IF_instruction_debug, DOF_instruction_debug);
                
                // Detailed bit examination of instruction encoding
                $display("         INSTRUCTION BIT ANALYSIS:");
                $display("         IF_inst bits[31:25]=%b (opcode)", IF_instruction_debug[31:25]);
                $display("         DOF_inst bits[31:25]=%b (opcode)", DOF_instruction_debug[31:25]);
                
                // Direct memory examination
                $display("         MEMORY CHECK: inst_mem[%h]=%h", PC_debug[9:0], cpu.if_stage.inst_mem.memory[PC_debug[9:0]]);
                
                // Check previous and next instructions for context
                if (PC_debug > 0) begin
                    $display("         PREV: inst_mem[%h]=%h", PC_debug[9:0] - 1, cpu.if_stage.inst_mem.memory[PC_debug[9:0] - 1]);
                end
                $display("         NEXT: inst_mem[%h]=%h", PC_debug[9:0] + 1, cpu.if_stage.inst_mem.memory[PC_debug[9:0] + 1]);
                
                // Check pipeline registers
                $display("         PIPELINE REGISTERS:");
                $display("         IF/DOF=%h", 
                         cpu.IF_DOF_instruction);
                
                // Try to determine if it's a fetch issue or a pipeline register corruption
                if (cpu.if_stage.inst_mem.memory[PC_debug[9:0]][31:25] != 7'b0000100) begin
                    $display("         CORRUPTION TYPE: Likely pipeline register or instruction fetching issue");
                    $display("         Memory has opcode %b but pipeline has %b", 
                              cpu.if_stage.inst_mem.memory[PC_debug[9:0]][31:25], 
                              DOF_instruction_debug[31:25]);
                end else begin
                    $display("         CORRUPTION TYPE: Likely erroneous instruction in memory");
                end
            end
            
            // Debug branch instructions specifically
            if (BS_debug != 2'b00) begin
                $display("         BRANCH DETECTED: BS=%b, PC=%h, target calculation in progress", 
                          BS_debug, PC_debug);
            end
            
            // Debug pipeline stage transitions
            $display("         IF->DOF: %h -> %h",
                     IF_instruction_debug, DOF_instruction_debug);
        end
    end
    
    // Additional monitor for tracking execution flow and detecting anomalies
    always @(posedge clk) begin
        if (!rst) begin
            // Check for PC changes and control flow
            if (PC_debug != prev_PC) begin
                if (prev_PC != -1) begin  // Skip first cycle after reset
                    if (PC_debug != prev_PC + 1 && !cpu.if_stage.BS) begin
                        // Unexpected PC change without branch signal
                        $display("WARNING: Unexpected PC change! prev=%h, current=%h, BS=%b", 
                                prev_PC, PC_debug, cpu.if_stage.BS);
                    end
                    
                    // Track instruction changes through pipeline
                    $display("FLOW: PC change %h -> %h | Instruction: %h", 
                            prev_PC, PC_debug, IF_instruction_debug);
                end
                prev_PC = PC_debug;
            end
        end else begin
            prev_PC = -1; // Reset tracking on reset signal
        end
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
        
    // Initialize the entire instruction memory array with NOPs
    for (i = 0; i < 1024; i = i + 1) begin
        instruction_memory[i] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);  // NOP instruction
    end
    
    // Start at address 100 (instead of 0) to leave room for test case setup code
    m = 100;

    //-------------------------------------------------------------------------
    // 1. Initialize product registers (R1 = low, R2 = high)
    //-------------------------------------------------------------------------
    instruction_memory[m++] = pack_instruction(`OP_MOV, `R1, `R0, 5'b0, 16'h0);  // R1 = 0 (Low Product) Addr 100
    instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // NOP for timing         Addr 101
    instruction_memory[m++] = pack_instruction(`OP_MOV, `R2, `R0, 5'b0, 16'h0);  // R2 = 0 (High Product)Addr 102
    instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // NOP                     Addr 103

    //-------------------------------------------------------------------------
    // 2. Load inputs into multiplicand and multiplier registers
    //    (Assume original inputs are in R1 and R2 from test setup; move to R3/R4)
    //-------------------------------------------------------------------------
    instruction_memory[m++] = pack_instruction(`OP_MOV, `R3, `R1, 5'b0, 16'h0);  // R3 = multiplicand (from R1) Addr 104
    instruction_memory[m++] = pack_instruction(`OP_MOV, `R4, `R2, 5'b0, 16'h0);  // R4 = multiplier (from R2)   Addr 105
    
    // Debug NOP instruction specifically
    $display("DEBUG NOP INSTRUCTION - Before storing:");
    $display("NOP opcode definition: `OP_NOP = %b", `OP_NOP);
    packed_nop = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0);
    $display("Correctly packed NOP = 0x%h (binary: %b)", packed_nop, packed_nop);
    instruction_memory[m++] = packed_nop; // Store explicit NOP at Addr 106
    $display("Final NOP at mem[%0d] = 0x%h (binary: %b)", m-1, instruction_memory[m-1], instruction_memory[m-1]);
    $display("END DEBUG NOP");

    //-------------------------------------------------------------------------
    // 3. Make multiplicand positive if needed; save sign in R7.
    //-------------------------------------------------------------------------
    instruction_memory[m++] = pack_instruction(`OP_LSR, `R7, `R3, 5'b0, 16'd31);  // R7 = R3 >> 31 (Extract sign bit) Addr 107
    instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // NOP                            Addr 108
    instruction_memory[m++] = pack_instruction(`OP_BZ,  `R7, 5'b0, 5'b0, 16'd2);  // if (R7==0) skip next 4 -> skip to Addr 113. Addr 109
    instruction_memory[m++] = pack_instruction(`OP_NOT, `R3, `R3, 5'b0, 16'h0);   // R3 = NOT R3                   Addr 110
    instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // NOP                           Addr 111
    instruction_memory[m++] = pack_instruction(`OP_ADI, `R3, `R3, 5'b0, 16'd1);         // R3 = R3 + 1 (Complete 2's comp) Addr 112

    //-------------------------------------------------------------------------
    // 4. Make multiplier positive if needed; save sign in R8.
    //-------------------------------------------------------------------------
    instruction_memory[m++] = pack_instruction(`OP_LSR, `R8, `R4, 5'b0, 16'd31);  // R8 = R4 >> 31 (Extract sign bit) Addr 113
    instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // NOP                            Addr 114
    instruction_memory[m++] = pack_instruction(`OP_BZ,  `R8, 5'b0, 5'b0, 16'd2);  // if (R8==0) skip next 4 -> skip to Addr 119. Addr 115
    instruction_memory[m++] = pack_instruction(`OP_NOT, `R4, `R4, 5'b0, 16'h0);   // R4 = NOT R4                   Addr 116
    instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // NOP                           Addr 117
    instruction_memory[m++] = pack_instruction(`OP_ADI, `R4, `R4, 5'b0, 16'd1);         // R4 = R4 + 1 (Complete 2's comp) Addr 118

    //-------------------------------------------------------------------------
    // 5. Initialize helper register R5 and loop counter R31.
    //-------------------------------------------------------------------------
    instruction_memory[m++] = pack_instruction(`OP_MOV, `R5, `R0, 5'b0, 16'h0);   // R5 = 0                       Addr 119
    instruction_memory[m++] = pack_instruction(`OP_ADI, `R31, `R0, 5'b0, 16'd32);       // R31 = 32 (Loop counter)      Addr 120

    //-------------------------------------------------------------------------
    // 6. Multiplication loop START (Target Address for BNZ)
    //-------------------------------------------------------------------------
    // Loop_Start: (Address 121)
    instruction_memory[m++] = pack_instruction(`OP_ANI, `R9, `R4, 5'b0, 16'd1);   // R9 = R4 & 1 (Test LSB of multiplier) Addr 121
    instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // NOP                            Addr 122
    instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // NOP                            Addr 123
    instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // NOP                            Addr 124
    instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // NOP                            Addr 125
    instruction_memory[m++] = pack_instruction(`OP_BZ,  `R9, 5'b0, 5'b0, 16'd2);  // if (R9==0) skip next 4 -> skip to Addr 130. Addr 126
    // If LSB was 1:
    instruction_memory[m++] = pack_instruction(`OP_ADD, `R1, `R1, `R3, 5'b0);     // R1 = R1 + R3 (Add multiplicand to Low Prod) Addr 127
    instruction_memory[m++] = pack_instruction(`OP_ADI, `R5, `R5, 5'b0, 16'd1);         // R5 = R5 + 1 (Carry handling?)           Addr 128
    instruction_memory[m++] = pack_instruction(`OP_ADD, `R2, `R2, `R5, 5'b0);     // R2 = R2 + R5 (Update High Prod?)        Addr 129
    // Skip_Target / Continue: (Address 130)
    // Shift registers and update loop counter:
    instruction_memory[m++] = pack_instruction(`OP_LSR, `R4, `R4, 5'b0, 16'd1);   // R4 = R4 >> 1 (Shift multiplier right)   Addr 130
    instruction_memory[m++] = pack_instruction(`OP_SBI, `R31, `R31, 5'b0, 16'd1);       // R31 = R31 - 1 (Decrement counter)       Addr 131
    instruction_memory[m++] = pack_instruction(`OP_LSL, `R3, `R3, 5'b0, 16'd1);   // R3 = R3 << 1 (Shift multiplicand left)  Addr 132
    instruction_memory[m++] = pack_instruction(`OP_LSL, `R5, `R5, 5'b0, 16'd1);   // R5 = R5 << 1 (Shift helper left)        Addr 133
    instruction_memory[m++] = pack_instruction(`OP_BNZ, `R31, 5'b0, 5'b0, -16'd15); // If R31!=0, jump back to Loop_Start (Addr 121). Addr 134
    // End of loop (Address 135)

    //-------------------------------------------------------------------------
    // 7. Adjust the final product sign if needed.
    //-------------------------------------------------------------------------
    instruction_memory[m++] = pack_instruction(`OP_XOR, `R10, `R7, `R8, 5'b0);    // R10 = R7 ^ R8 (Check if signs differed) Addr 135
    instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // NOP                             Addr 136
    instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // NOP                             Addr 137
    instruction_memory[m++] = pack_instruction(`OP_BZ,  `R10, 5'b0, 5'b0, 16'd5); // if (R10==0) skip next 8 -> skip to Addr 145. Addr 138
    // If signs differed, take two's complement of 64-bit result (R2:R1)
    instruction_memory[m++] = pack_instruction(`OP_NOT, `R2, `R2, 5'b0, 16'h0);   // R2 = NOT R2                     Addr 139
    instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // NOP                             Addr 140
    instruction_memory[m++] = pack_instruction(`OP_ADI, `R2, `R2, 5'b0, 16'd1);         // R2 = R2 + 1 (If R1 was 0, this finishes) Addr 141
    instruction_memory[m++] = pack_instruction(`OP_NOT, `R1, `R1, 5'b0, 16'h0);   // R1 = NOT R1                     Addr 142
    instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0); // NOP                             Addr 143
    instruction_memory[m++] = pack_instruction(`OP_ADI, `R1, `R1, 5'b0, 16'd1);         // R1 = R1 + 1 (Completes 2's comp)  Addr 144
    // Skip_Sign_Adjust: (Address 145)

    //-------------------------------------------------------------------------
    // 8. End of program: Jump 0 steps (halt)
    //-------------------------------------------------------------------------
    instruction_memory[m++] = pack_instruction(`OP_JMP, 5'b0, 5'b0, 5'b0, 16'h0); // JMP Offset 0 -> Target PC+2. Halts? Addr 145

    //-------------------------------------------------------------------------
    // 9. Fill remaining memory with NOPs.
    //-------------------------------------------------------------------------
    for (i = m; i < 1024; i = i + 1) begin
        instruction_memory[i] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0);
    end
end

    // Load initial multiplication program into CPU's instruction memory
    initial begin
        $display("\n===== INSTRUCTION LOADING PROCESS =====");
        for (j = 0; j < 1024; j = j + 1) begin
            // Only print detailed debug for the first 16 instructions and around address 100
            if (j < 16 || (j >= 100 && j < 116)) begin
                $display("Loading addr %02d: %08h", j, instruction_memory[j]);
            end
            
            // Add detailed debugging for addresses 6, 7, and around index 100
            if (j == 6 || j == 7 || j == 100 || j == 107) begin
                $display("DETAILED LOADING OF INSTRUCTION AT ADDR %0d:", j);
                $display("  Testbench array value: %08h", instruction_memory[j]);
                $display("  As binary: %032b", instruction_memory[j]);
                
                // Break down fields to check if they're correct
                $display("  Fields (if correct):");
                $display("    Opcode = %07b (decimal: %0d)", instruction_memory[j][31:25], instruction_memory[j][31:25]);
                $display("    RD = %05b", instruction_memory[j][24:20]);
                $display("    RS1 = %05b", instruction_memory[j][19:15]);
                $display("    RS2 = %05b", instruction_memory[j][14:10]);
                $display("    Imm = %016b", instruction_memory[j][15:0]);
                
                if (j == 6) begin
                    // For address 6, do extra debugging of NOP instruction
                    $display("  Expected NOP encoding: %08h", {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0});
                    
                    // Check instruction packing for NOP
                    packed_nop = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0};
                    $display("  Packed NOP value: %08h", packed_nop);
                    $display("  Packed NOP binary: %032b", packed_nop);
                end
                else if (j == 7) begin
                    // For address 7, do extra debugging of LSR instruction
                    $display("  Expected LSR encoding: %08h", {`OP_LSR, `R7, `R3, 5'b0, 16'd31});
                    
                    // Check instruction packing for LSR
                    packed_lsr = {`OP_LSR, `R7, `R3, 5'b0, 16'd31};
                    $display("  Packed LSR value: %08h", packed_lsr);
                    $display("  Packed LSR binary: %032b", packed_lsr);
                end
                else if (j == 107) begin
                    // For address 107, do extra debugging of the LSR instruction in the multiplication program
                    $display("  Expected LSR encoding: %08h", {`OP_LSR, `R7, `R3, 5'b0, 16'd31});
                    
                    // Check instruction packing for LSR
                    packed_lsr = {`OP_LSR, `R7, `R3, 5'b0, 16'd31};
                    $display("  Packed LSR value: %08h", packed_lsr);
                    $display("  Packed LSR binary: %032b", packed_lsr);
                end
            end
            
            cpu.if_stage.inst_mem.memory[j] = instruction_memory[j];
            
            // Check what was actually loaded into instruction memory
            if (j == 6 || j == 7 || j == 100 || j == 107) begin
                $display("  After loading to instruction memory: %08h", cpu.if_stage.inst_mem.memory[j]);
                $display("  As binary: %032b", cpu.if_stage.inst_mem.memory[j]);
                $display("  Opcode after loading: %07b", cpu.if_stage.inst_mem.memory[j][31:25]);
            end
        end
        $display("====================================\n");
    end

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

        // Debug all instruction memory contents
        $display("\n===== INSTRUCTION MEMORY DUMP =====");
        for (j = 0; j < 16; j = j + 1) begin
            $display("Addr %02d: %08h | Binary: %032b", j, 
                      cpu.if_stage.inst_mem.memory[j],
                      cpu.if_stage.inst_mem.memory[j]);
            
            if (j == 6 || j == 7) begin
                // Extra detailed debug for the problematic instructions
                $display("DETAILED ANALYSIS OF INSTRUCTION AT ADDR %0d:", j);
                $display("  Full instruction: %08h", cpu.if_stage.inst_mem.memory[j]);
                $display("  Opcode bits [31:25]: %07b (decimal: %0d)", 
                          cpu.if_stage.inst_mem.memory[j][31:25],
                          cpu.if_stage.inst_mem.memory[j][31:25]);
                $display("  RD bits [24:20]: %05b (decimal: %0d)", 
                          cpu.if_stage.inst_mem.memory[j][24:20],
                          cpu.if_stage.inst_mem.memory[j][24:20]);
                $display("  RS1 bits [19:15]: %05b (decimal: %0d)", 
                          cpu.if_stage.inst_mem.memory[j][19:15],
                          cpu.if_stage.inst_mem.memory[j][19:15]);
                $display("  RS2 bits [14:10]: %05b (decimal: %0d)", 
                          cpu.if_stage.inst_mem.memory[j][14:10],
                          cpu.if_stage.inst_mem.memory[j][14:10]);
                $display("  Immediate [15:0]: %016b", 
                          cpu.if_stage.inst_mem.memory[j][15:0]);
            end
        end
        
        // Also dump the multiplication program area
        $display("\n===== MULTIPLICATION PROGRAM MEMORY DUMP =====");
        for (j = 100; j < 120; j = j + 1) begin
            $display("Addr %03d: %08h | Binary: %032b", j, 
                      cpu.if_stage.inst_mem.memory[j],
                      cpu.if_stage.inst_mem.memory[j]);
                      
            if (j == 106 || j == 107) begin
                // Extra detailed debug for the potentially problematic instructions
                $display("DETAILED ANALYSIS OF INSTRUCTION AT ADDR %0d:", j);
                $display("  Full instruction: %08h", cpu.if_stage.inst_mem.memory[j]);
                $display("  Opcode bits [31:25]: %07b (decimal: %0d)", 
                          cpu.if_stage.inst_mem.memory[j][31:25],
                          cpu.if_stage.inst_mem.memory[j][31:25]);
                $display("  RD bits [24:20]: %05b (decimal: %0d)", 
                          cpu.if_stage.inst_mem.memory[j][24:20],
                          cpu.if_stage.inst_mem.memory[j][24:20]);
                $display("  RS1 bits [19:15]: %05b (decimal: %0d)", 
                          cpu.if_stage.inst_mem.memory[j][19:15],
                          cpu.if_stage.inst_mem.memory[j][19:15]);
                $display("  RS2 bits [14:10]: %05b (decimal: %0d)", 
                          cpu.if_stage.inst_mem.memory[j][14:10],
                          cpu.if_stage.inst_mem.memory[j][14:10]);
                $display("  Immediate [15:0]: %016b", 
                          cpu.if_stage.inst_mem.memory[j][15:0]);
            end
        end
        $display("================================\n");

        // --- Test Case 1: 0 * 0 ---
        $display("\nTest Case 1: 0 * 0");
        // Setup inputs directly in registers (requires internal path knowledge)
        // This approach bypasses the test instruction loading issue but is less realistic
        // A better approach loads setup instructions, jumps, waits, then checks.
        // We'll use the instruction loading approach.

        // Reset CPU state
        rst = 1; #20; rst = 0; #1;

        // Load Test Case 1 setup instructions into local memory array
        m = 0; // Overwrite starting from address 0 for test setup
        instruction_memory[m++] = pack_instruction(`OP_MOV, `R1, `R0, 5'b0, 16'h0000);  // MOV R1, #0 (Input 1)
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); // Timing NOPs
        instruction_memory[m++] = pack_instruction(`OP_MOV, `R2, `R0, 5'b0, 16'h0000);  // MOV R2, #0 (Input 2)
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); // Timing NOPs
        instruction_memory[m++] = pack_instruction(`OP_MOV, `R3, `R0, 5'b0, 16'h0000);  // Clear R3 (Expected Result Low)
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); // Timing NOPs
        instruction_memory[m++] = pack_instruction(`OP_MOV, `R4, `R0, 5'b0, 16'h0000);  // Clear R4 (Expected Result High)
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); // Timing NOPs
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); // Timing NOPs
        // PC is now 24 (m=24)
        // Jump to multiplication program at address 100
        // Offset calculation: Target=100, PC=24, PC+2+offset=100 → offset=100-(24+2)=74
        instruction_memory[m++] = pack_instruction(`OP_JMP, 5'b0, 5'b0, 5'b0, 16'd74);   // JMP to address 100

        // Load the test setup instructions into CPU's instruction memory
        for (j = 0; j < 1024; j = j + 1) begin
            cpu.if_stage.inst_mem.memory[j] = instruction_memory[j];
        end

        // Wait for program to complete (adjust time as needed)
        #4000;
        
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
        instruction_memory[m++] = pack_instruction(`OP_MOV, `R1, `R0, 5'b0, 16'h0001);  // MOV R1, #1
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_MOV, `R2, `R0, 5'b0, 16'h0001);  // MOV R2, #1
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_MOV, `R3, `R0, 5'b0, 16'h0000);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_MOV, `R4, `R0, 5'b0, 16'h0000);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); 
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0); // Timing NOPs
        // PC is now 24 (m=24)
        // Jump to multiplication program at address 100
        // Offset calculation: Target=100, PC=24, PC+2+offset=100 → offset=100-(24+2)=74
        instruction_memory[m++] = pack_instruction(`OP_JMP, 5'b0, 5'b0, 5'b0, 16'd74);   // JMP to address 100
        
        for (j = 0; j < 1024; j = j + 1) cpu.if_stage.inst_mem.memory[j] = instruction_memory[j]; // Load instructions
        #4000;
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
    always @(posedge clk) begin
        if (!rst) begin
            $display("REGISTERS: Time=%0t PC=%h Inst=%h | R1=%h R2=%h R3=%h R4=%h R5=%h R7=%h R8=%h R9=%h R10=%h R31=%d",
                     $time, cpu.PC, cpu.IF_DOF_instruction, R1_debug, R2_debug, R3_debug, R4_debug, R5_debug, R7_debug, R8_debug, R9_debug, R10_debug, R31_debug);
        end
    end

    // Hazard and pipeline integrity monitor
    always @(posedge clk) begin
        if (!rst) begin
            debug_cycle_count = debug_cycle_count + 1;
            
            // Only show full trace if flag is enabled
            if (debug_full_trace) begin
                $display("CYCLE %0d: PC=%h, IF=%h, DOF=%h",
                    debug_cycle_count, PC_debug, 
                    IF_instruction_debug, cpu.IF_DOF_instruction);
            end
    
            
            // Check for opcode corruption by comparing opcode at different pipeline stages
            if (cpu.IF_DOF_instruction[31:25] != opcode_debug) begin
                $display("WARNING: Opcode mismatch in DOF stage at cycle %0d", debug_cycle_count);
                $display("         IF_DOF_instruction[31:25]=%b", cpu.IF_DOF_instruction[31:25]);
                $display("         DOF opcode_debug=%b", opcode_debug);
            end
            
            // Check for NOPs being incorrectly processed
            if (cpu.IF_DOF_instruction[31:25] == 7'b0000000 && opcode_debug != 7'b0000000) begin
                $display("WARNING: NOP instruction corrupted in DOF stage at cycle %0d", debug_cycle_count);
            end
            
            // Store values for next cycle comparison
            prev_DOF_instruction = cpu.IF_DOF_instruction;
        end else begin
            // Reset tracking on reset
            debug_cycle_count = 0;
            prev_DOF_instruction = 32'h0;
        end
    end

endmodule