// Simplified 1x1 Multiplication Testbench
`timescale 1ns / 1ps
`include "../definitions.v"

module multiply1x1_tb;

    // Testbench signals
    reg clk = 0;
    reg rst = 1;
    wire [31:0] R1_debug, R2_debug, R3_debug, R4_debug;
    wire [31:0] R7_debug, R8_debug, R9_debug, R10_debug;
    wire [31:0] R31_debug;
    wire [31:0] PC_debug;
    reg [31:0] prev_PC = 0;
    
    // Test tracking
    integer tests_passed = 0;
    integer tests_failed = 0;
    integer total_tests = 1;
    integer stuck_count = 0;
    reg [31:0] last_pc = 0;
    
    // Instantiate CPU
    wire [31:0] DOF_instruction_debug;
    wire [31:0] IF_instruction_debug;
    wire [6:0] opcode_debug;
    wire RW_debug;
    wire [4:0] FS_debug;
    wire [1:0] BS_debug;
    
    cpu cpu(
        .clk(clk),
        .rst(rst),
        .R1_debug(R1_debug),
        .R2_debug(R2_debug),
        .R3_debug(R3_debug),
        .R4_debug(R4_debug),
        .R7_debug(R7_debug),
        .R8_debug(R8_debug),
        .R9_debug(R9_debug),
        .R10_debug(R10_debug),
        .R31_debug(R31_debug),
        .PC_debug(PC_debug),
        .DOF_instruction_debug(DOF_instruction_debug),
        .IF_instruction_debug(IF_instruction_debug),
        .opcode_debug(opcode_debug),
        .RW_debug(RW_debug),
        .FS_debug(FS_debug),
        .BS_debug(BS_debug)
    );
    
    // Helper function to correctly pack instruction bits
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
            
            // I-type instructions
            if (opcode == `OP_ADI || opcode == `OP_SBI || opcode == `OP_ANI || 
                opcode == `OP_ORI || opcode == `OP_XRI || opcode == `OP_AIU || 
                opcode == `OP_SIU || opcode == `OP_LSL || opcode == `OP_LSR) begin
                pack_instruction = {opcode, rd, rs1, imm[14:0]};
            end
            
            // Branch instructions
            else if (opcode == `OP_BZ || opcode == `OP_BNZ) begin
                pack_instruction = {opcode, rd, rs1, imm[14:0]};
            end
            
            // Jump instructions
            else if (opcode == `OP_JMP || opcode == `OP_JML) begin
                pack_instruction = {opcode, rd, rs1, imm[14:0]};
            end
            
            // MOV instruction
            else if (opcode == `OP_MOV) begin
                pack_instruction = {opcode, rd, rs1, 16'b0};
            end
            
            // NOT instruction
            else if (opcode == `OP_NOT) begin
                pack_instruction = {opcode, rd, rs1, 16'b0};
            end
        end
    endfunction
    
    // Wait for completion or detect stuck CPU
    task wait_for_completion;
        begin
            stuck_count = 0;
            last_pc = PC_debug;
            
            while (PC_debug != 0 && stuck_count < 1000) begin
                #10;  // Wait one clock cycle
                
                if (PC_debug == last_pc) begin
                    stuck_count = stuck_count + 1;
                    if (stuck_count >= 1000) begin
                        $display("ERROR: CPU appears stuck at PC=%h", PC_debug);
                        $finish;
                    end
                end else begin
                    stuck_count = 0;  // Reset stuck counter when PC changes
                    last_pc = PC_debug;
                end
            end
        end
    endtask
    
    // Initialize instruction memory with multiplication program
    initial begin
        // Generate clock
        forever #5 clk = ~clk;  // 10ns period -> 100MHz clock
    end
    
    // Main test sequence
    initial begin
        $display("Starting 1x1 Multiplication Test");
        
        // Local memory array for instructions
        reg [31:0] instruction_memory[0:1023];
        integer j, m;
        
        // Clear instruction memory
        for (j = 0; j < 1024; j = j + 1) begin
            instruction_memory[j] = 32'h0;
        end
        
        // Initialize test program
        m = 0;  // Memory index counter
        
        // Initialize test input registers: R1=1, R2=1 (testing 1*1)
        instruction_memory[m++] = pack_instruction(`OP_ADI, `R1, `R0, 5'b0, 16'h1);  // R1 = 1
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        
        instruction_memory[m++] = pack_instruction(`OP_ADI, `R2, `R0, 5'b0, 16'h1);  // R2 = 1
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        
        // For Test Output: R3=0, R4=0 (Expected Result)
        instruction_memory[m++] = pack_instruction(`OP_ADI, `R3, `R0, 5'b0, 16'h0);  // R3 = 0 (Expected Result Low)
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        
        instruction_memory[m++] = pack_instruction(`OP_ADI, `R4, `R0, 5'b0, 16'h1);  // R4 = 1 (Expected Result High)
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        
        // Jump to multiplication algorithm at address 100
        instruction_memory[m++] = pack_instruction(`OP_JMP, 5'b0, 5'b0, 5'b0, 16'd100-m);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        
        // Skip to address 100 for multiplication algorithm
        m = 100;
        
        // ========== START OF MULTIPLICATION ALGORITHM ==========
        // Move input values to working registers
        instruction_memory[m++] = pack_instruction(`OP_MOV, `R3, `R1, 5'b0, 16'b0);  // R3 = R1 (multiplicand)
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        
        instruction_memory[m++] = pack_instruction(`OP_MOV, `R4, `R2, 5'b0, 16'b0);  // R4 = R2 (multiplier)
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        
        // Initialize result registers
        instruction_memory[m++] = pack_instruction(`OP_ADI, `R1, `R0, 5'b0, 16'h0);  // R1 = 0 (result low)
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        
        instruction_memory[m++] = pack_instruction(`OP_ADI, `R2, `R0, 5'b0, 16'h0);  // R2 = 0 (result high)
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        
        // Initialize loop counter
        instruction_memory[m++] = pack_instruction(`OP_ADI, `R31, `R0, 5'b0, 16'd32);  // R31 = 32 (loop counter)
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        
        // LOOP START (Label: loop)
        instruction_memory[m++] = pack_instruction(`OP_ANI, `R9, `R4, 5'b0, 16'h1);  // R9 = R4 & 1 (check LSB)
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        
        // Check if LSB is 0, skip addition
        instruction_memory[m++] = pack_instruction(`OP_BZ, `R9, 5'b0, 5'b0, 16'd10);  // Skip 4 instructions + 4 NOPs if R9 == 0
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        
        // If LSB is 1, add multiplicand to result
        instruction_memory[m++] = pack_instruction(`OP_ADD, `R1, `R1, `R3, 16'b0);  // R1 = R1 + R3 (add to low result)
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        
        // Shift multiplier right
        instruction_memory[m++] = pack_instruction(`OP_LSR, `R4, `R4, 5'b0, 16'h1);  // R4 = R4 >> 1
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        
        // Shift multiplicand left
        instruction_memory[m++] = pack_instruction(`OP_LSL, `R3, `R3, 5'b0, 16'h1);  // R3 = R3 << 1
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        
        // Decrement loop counter
        instruction_memory[m++] = pack_instruction(`OP_SBI, `R31, `R31, 5'b0, 16'h1);  // R31 = R31 - 1
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        
        // Check if counter is 0
        instruction_memory[m++] = pack_instruction(`OP_BNZ, `R31, 5'b0, 5'b0, 16'd-30);  // Jump to loop start if R31 != 0
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        
        // Halt - continue to result check
        instruction_memory[m++] = pack_instruction(`OP_JMP, 5'b0, 5'b0, 5'b0, 16'd200-m);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        
        // Place result verification code at address 200
        m = 200;
        
        // Halt - program completion
        instruction_memory[m++] = pack_instruction(`OP_JMP, 5'b0, 5'b0, 5'b0, 16'd0);  // Jump to address 0 (halt)
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        instruction_memory[m++] = pack_instruction(`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0);
        
        // Load the test setup instructions into CPU's instruction memory
        for (j = 0; j < 1024; j = j + 1) begin
            cpu.if_stage.inst_mem.memory[j] = instruction_memory[j];
        end
        
        // Display memory contents for verification
        $display("\n===== INSTRUCTION MEMORY DUMP (Key Sections) =====");
        $display("--- Initialization and Input Setup (0-20) ---");
        for (j = 0; j < 20; j = j + 1) begin
            $display("Addr %03d: %08h | Opcode: %07b", j, 
                     cpu.if_stage.inst_mem.memory[j],
                     cpu.if_stage.inst_mem.memory[j][31:25]);
        end
        
        $display("\n--- Multiplication Code (100-150) ---");
        for (j = 100; j < 150; j = j + 1) begin
            $display("Addr %03d: %08h | Opcode: %07b", j, 
                     cpu.if_stage.inst_mem.memory[j],
                     cpu.if_stage.inst_mem.memory[j][31:25]);
        end
        $display("======================================================\n");
        
        // Start processor
        rst = 1; #20; rst = 0;
        
        // Wait for completion
        wait_for_completion();
        
        // Check results
        $display("\n===== TEST RESULTS =====");
        $display("Input: R1=%h, R2=%h (1 * 1)", 
                 cpu.if_stage.inst_mem.memory[0][15:0], 
                 cpu.if_stage.inst_mem.memory[6][15:0]);
        $display("Expected: R1=%h (Low=1), R2=%h (High=0)", 
                 32'h1, 32'h0);
        $display("Actual: R1=%h (Low), R2=%h (High)", 
                 R1_debug, R2_debug);
        
        if (R1_debug === 32'h1 && R2_debug === 32'h0) begin
            $display("Test PASSED");
            tests_passed = tests_passed + 1;
        end else begin
            $display("Test FAILED");
            tests_failed = tests_failed + 1;
        end
        
        $display("=======================\n");
        $finish;
    end
    
    // Debug module to track execution through pipeline stages
    reg [31:0] debug_state = 0;
    
    always @(posedge clk) begin
        if (!rst) begin
            // Debug register values at key pipeline stages
            case (PC_debug)
                // Input loading
                0: $display("[PC=%d] Starting execution", PC_debug);
                1: $display("[PC=%d] Loading R1=1", PC_debug);
                6: $display("[PC=%d] Loading R2=1", PC_debug);
                11: $display("[PC=%d] Initializing expected result registers", PC_debug);
                20: $display("[PC=%d] Jumping to multiplication routine", PC_debug);
                
                // Multiplication algorithm
                100: $display("[PC=%d] MULTIPLY: Copying multiplicand to R3", PC_debug);
                106: $display("[PC=%d] MULTIPLY: Copying multiplier to R4", PC_debug);
                111: $display("[PC=%d] MULTIPLY: Initializing result low=0", PC_debug);
                116: $display("[PC=%d] MULTIPLY: Initializing result high=0", PC_debug);
                121: $display("[PC=%d] MULTIPLY: Setting loop counter to 32", PC_debug);
                126: begin
                    $display("[PC=%d] MULTIPLY: Loop start - iteration %d", PC_debug, R31_debug);
                    // Show values 3 cycles later to account for pipeline delay
                    $display("  After 3 cycles: R3=%h, R4=%h, R1=%h, R2=%h, R9=%h", 
                             R3_debug, R4_debug, R1_debug, R2_debug, R9_debug);
                end
                
                200: begin
                    $display("[PC=%d] MULTIPLY: Algorithm complete", PC_debug);
                    $display("  Final result: R1=%h (Low), R2=%h (High)", R1_debug, R2_debug);
                end
            endcase
            
            // Additional debug for specific instruction types
            if (BS_debug != 2'b00) begin
                $display("[PC=%d] Branch instruction detected, BS=%b", PC_debug, BS_debug);
            end
            
            // Debug every 10th cycle of the multiplication loop
            if (PC_debug >= 126 && PC_debug <= 180 && PC_debug % 10 == 0) begin
                $display("[PC=%d] Loop progress: Counter=%d, R3=%h, R4=%h, Result=%h:%h", 
                         PC_debug, R31_debug, R3_debug, R4_debug, R2_debug, R1_debug);
            end
        end
    end

endmodule
