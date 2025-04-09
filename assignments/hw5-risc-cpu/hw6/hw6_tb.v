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
    wire [31:0] R1, R2, R3, R4;  // Registers for multiplication
    wire [31:0] R5, R6, R7, R8;  // Additional registers for debugging
    wire [31:0] R9, R10, R11, R12, R13;  // More registers for debugging

    // Test counters
    integer tests_passed;
    integer tests_failed;
    integer total_tests;

    // Instruction memory array
    reg [31:0] instruction_memory [0:1023];  // 1024 instructions max

    integer i;
    integer j;

    integer m;

    // Instantiate the CPU
    top cpu(
        .clk(clk),
        .rst(rst)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 100MHz clock
    end

    // Initialize test counters
    initial begin
        tests_passed = 0;
        tests_failed = 0;
        total_tests = 8;  // Total number of test cases
    end

    // Load program into instruction memory
   initial begin
    // Program: 64-bit Multiplication (Updated to follow first snippet algorithm)
    // Format: {opcode[6:0], rd[4:0], rs1[4:0], rs2[4:0], imm[15:0]}
    m = 0;

    //-------------------------------------------------------------------------
    // 1. Initialize product registers (R1 = low, R2 = high)
    //-------------------------------------------------------------------------
    instruction_memory[m++] = {`OP_MOV, `R1, `R0, 5'b0, 16'h0};  // R1 = 0
    instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0}; // NOP for timing
    instruction_memory[m++] = {`OP_MOV, `R2, `R0, 5'b0, 16'h0};  // R2 = 0
    instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0};
    instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0};
    instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0};
    instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0};
    instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0};
    instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0};
    instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0};
    instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0};
    instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0};
    instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0};
    instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0};
    instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0};
    instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0};
    instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0};
    instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0};
    instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0};
    instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0};
    instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0};
    instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0};
    instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0};
    instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0};  // Load NOP to leave room for custom instructions loaded by test cases

    //-------------------------------------------------------------------------
    // 2. Load inputs into multiplicand and multiplier registers
    //    (Assume original inputs are in R1 and R2; now move them into R3 and R4.)
    //-------------------------------------------------------------------------
    instruction_memory[m++] = {`OP_MOV, `R3, `R1, 5'b0, 16'h0};  // R3 = multiplicand
    instruction_memory[m++] = {`OP_MOV, `R4, `R2, 5'b0, 16'h0};  // R4 = multiplier
    instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0};

    //-------------------------------------------------------------------------
    // 3. Make multiplicand positive if needed; save sign in R7.
    //    (Shift right 31 bits to extract the sign bit, then if nonzero,
    //     take the two’s complement: NOT then INC.)
    //-------------------------------------------------------------------------
    instruction_memory[m++] = {`OP_LSR, `R7, `R3, 5'b0, 16'd31};  // R7 = R3 >> 31
    instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0};
    instruction_memory[m++] = {`OP_BZ,  `R7, 5'b0, 5'b0, 16'd5};    // if (R7==0) skip next 5
    instruction_memory[m++] = {`OP_NOT, `R3, `R3, 5'b0, 16'h0};    // R3 = NOT R3
    instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0};
    instruction_memory[m++] = {`OP_ADI, `R3, `R3, 16'd1};   // R3 = R3 + 1

    //-------------------------------------------------------------------------
    // 4. Make multiplier positive if needed; save sign in R8.
    //-------------------------------------------------------------------------
    instruction_memory[m++] = {`OP_LSR, `R8, `R4, 5'b0, 16'd31};  // R8 = R4 >> 31
    instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0};
    instruction_memory[m++] = {`OP_BZ,  `R8, 5'b0, 5'b0, 16'd5};    // if (R8==0) skip next 5
    instruction_memory[m++] = {`OP_NOT, `R4, `R4, 5'b0, 16'h0};    // R4 = NOT R4
    instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0};
    instruction_memory[m++] = {`OP_ADI, `R4, `R4, 16'd1};   // R4 = R4 + 1

    //-------------------------------------------------------------------------
    // 5. Initialize helper register R5 (for the upper product update) and
    //    the loop counter R31 (set to 32 iterations).
    //-------------------------------------------------------------------------
    instruction_memory[m++] = {`OP_MOV, `R5, `R0, 5'b0, 16'h0};   // R5 = 0
    instruction_memory[m++] = {`OP_ADI, `R31, `R0, 16'd32};       // R31 = 32

    //-------------------------------------------------------------------------
    // 6. Multiplication loop:
    //    For each bit of the multiplier in R4:
    //      - Test the LSB (R4 & 1 → R9)
    //      - If set, add R3 to the low product (R1) and update R2 via R5.
    //      - Then shift R4 right, R3 (and R5) left, and decrement R31.
    //-------------------------------------------------------------------------
    instruction_memory[m++] = {`OP_ANI, `R9, `R4, 5'b0, 16'd1};   // R9 = R4 & 1
    instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0};
    instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0};
    instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0};
    instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0};
    instruction_memory[m++] = {`OP_BZ,  `R9, 5'b0, 5'b0, 16'd4};    // if (R9==0) skip next 4 instructions
    instruction_memory[m++] = {`OP_ADD, `R1, `R1, `R3, 16'h0};    // R1 = R1 + R3
    instruction_memory[m++] = {`OP_ADI, `R5, `R5, 16'd1};         // R5 = R5 + 1
    instruction_memory[m++] = {`OP_ADD, `R2, `R2, `R5, 16'h0};    // R2 = R2 + R5

    // Shift registers and update loop counter:
    instruction_memory[m++] = {`OP_LSR, `R4, `R4, 5'b0, 16'd1};    // R4 = R4 >> 1
    instruction_memory[m++] = {`OP_SBI, `R31, `R31, 16'd1};         // R31 = R31 - 1
    instruction_memory[m++] = {`OP_LSL, `R3, `R3, 5'b0, 16'd1};    // R3 = R3 << 1
    instruction_memory[m++] = {`OP_LSL, `R5, `R5, 5'b0, 16'd1};    // R5 = R5 << 1
    instruction_memory[m++] = {`OP_BNZ, `R31, 5'b0, 5'b0, -16'd17}; // If R31 ≠ 0, jump back to loop start

    //-------------------------------------------------------------------------
    // 7. Adjust the final product sign if needed.
    //    (Compute R10 = R7 XOR R8; if nonzero, take two's complement of the product.)
    //-------------------------------------------------------------------------
    instruction_memory[m++] = {`OP_XOR, `R10, `R7, `R8, 16'h0};    // R10 = R7 XOR R8
    instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0};
    instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0};
    instruction_memory[m++] = {`OP_BZ,  `R10, 5'b0, 5'b0, 16'd9};    // if (R10==0) skip next 9 instructions
    instruction_memory[m++] = {`OP_NOT, `R2, `R2, 5'b0, 16'h0};     // R2 = NOT R2
    instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0};
    instruction_memory[m++] = {`OP_ADI, `R2, `R2, 16'd1};     // R2 = R2 + 1
    instruction_memory[m++] = {`OP_NOT, `R1, `R1, 5'b0, 16'h0};     // R1 = NOT R1
    instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0};
    instruction_memory[m++] = {`OP_ADI, `R1, `R1, 16'd1};     // R1 = R1 + 1

    //-------------------------------------------------------------------------
    // 8. End of program: Jump 0 steps (or halt)
    //-------------------------------------------------------------------------
    instruction_memory[m++] = {`OP_JMP, 5'b0, 5'b0, 5'b0, 16'h0};

    //-------------------------------------------------------------------------
    // 9. Fill remaining memory with NOPs.
    //-------------------------------------------------------------------------
    for (i = m; i < 1024; i = i + 1) begin
        instruction_memory[i] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'h0};
    end
end

    // Load instructions into CPU's instruction memory
    initial begin
        for (j = 0; j < 1024; j = j + 1) begin
            cpu.if_stage.inst_mem.memory[j] = instruction_memory[j];
        end
    end

    // Test stimulus
    initial begin
        // Initialize waveform dumping
        $dumpfile("hw6_tb.vcd");
        $dumpvars(0, hw6_tb);

        // Initialize test counters
        tests_passed = 0;
        tests_failed = 0;


        //=====================================================================
        

        // Test Case 1: 0 * 0 = 0
        $display("\nTest Case 1: 0 * 0");
        $display("Input: R1 = %h, R2 = %h", 32'h0, 32'h0);
        $display("Expected: R3 = %h, R4 = %h", 32'h0, 32'h0);
        
        // Reset to clear previous state
        rst = 1;
        #20;
        rst = 0;
        #20;

        m=0;
        
        // Update instruction memory for this test case
        instruction_memory[m++] = {`OP_MOV, `R1, 5'b0, 5'b0, 16'h0000};  // MOV R1, #0
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
        instruction_memory[m++] = {`OP_MOV, `R2, 5'b0, 5'b0, 16'h0000};  // MOV R2, #0
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
        instruction_memory[m++] = {`OP_MOV, `R3, 5'b0, 5'b0, 16'h0000};  // MOV R3, #0
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
        instruction_memory[m++] = {`OP_MOV, `R4, 5'b0, 5'b0, 16'h0000};  // MOV R4, #0
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
        instruction_memory[m++] = {`OP_JMP, 5'b0, 5'b0, 5'b0, 16'd64};   // JMP 16 (start multiplication)
        
        // Load updated instructions into CPU's instruction memory
        for (j = 0; j < 1024; j = j + 1) begin
            cpu.if_stage.inst_mem.memory[j] = instruction_memory[j];
        end
        
        // Wait for program to complete
        #4000;  // Increased wait time to ensure all instructions complete
        
        // Check results
        $display("Result: R3 = %h, R4 = %h", 
                 cpu.dof_stage.reg_file.registers[3], 
                 cpu.dof_stage.reg_file.registers[4]);
        if (cpu.dof_stage.reg_file.registers[3] === 32'h0 && 
            cpu.dof_stage.reg_file.registers[4] === 32'h0) begin
            $display("Test Case 1 PASSED");
            tests_passed = tests_passed + 1;
        end else begin
            $display("Test Case 1 FAILED");
            tests_failed = tests_failed + 1;
        end
        #100;


        //=====================================================================


        // Test Case 2: 1 * 1 = 1
        $display("\nTest Case 2: 1 * 1");
        $display("Input: R1 = %h, R2 = %h", 32'h1, 32'h1);
        $display("Expected: R3 = %h, R4 = %h", 32'h0, 32'h1);
        
        // Reset to clear previous state
        rst = 1;
        #20;
        rst = 0;
        #20;

        m=0;
        
        // Update instruction memory for this test case
        instruction_memory[m++] = {`OP_MOV, `R1, 5'b0, 5'b0, 16'h0001};  // MOV R1, #1
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
        instruction_memory[m++] = {`OP_MOV, `R2, 5'b0, 5'b0, 16'h0001};  // MOV R2, #1
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
        instruction_memory[m++] = {`OP_MOV, `R3, 5'b0, 5'b0, 16'h0000};  // MOV R3, #0
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
        instruction_memory[m++] = {`OP_MOV, `R4, 5'b0, 5'b0, 16'h0000};  // MOV R4, #0
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
        instruction_memory[m++] = {`OP_JMP, 5'b0, 5'b0, 5'b0, 16'd64};   // JMP 16 (start multiplication)
        
        // Load updated instructions into CPU's instruction memory
        for (j = 0; j < 1024; j = j + 1) begin
            cpu.if_stage.inst_mem.memory[j] = instruction_memory[j];
        end
        
        // Wait for program to complete
        #4000;  // Increased wait time to ensure all instructions complete
        
        // Check results
        $display("Result: R3 = %h, R4 = %h", 
                 cpu.dof_stage.reg_file.registers[3], 
                 cpu.dof_stage.reg_file.registers[4]);
        if (cpu.dof_stage.reg_file.registers[3] === 32'h0 && 
            cpu.dof_stage.reg_file.registers[4] === 32'h1) begin
            $display("Test Case 2 PASSED");
            tests_passed = tests_passed + 1;
        end else begin
            $display("Test Case 2 FAILED");
            tests_failed = tests_failed + 1;
        end
        #100;

        // Test Case 3: -1 * -1 = 1
        $display("\nTest Case 3: -1 * -1");
        $display("Input: R1 = %h, R2 = %h", 32'hFFFFFFFF, 32'hFFFFFFFF);
        $display("Expected: R3 = %h, R4 = %h", 32'h0, 32'h1);
        
        // Reset to clear previous state
        rst = 1;
        #20;
        rst = 0;
        #20;

        m=0;

        // Update instruction memory for this test case
        // Load 0xFFFFFFFF into R1
        instruction_memory[m++] = {`OP_MOV, `R1, 5'b0, 5'b0, 16'hFFFF};  // MOV R1, #0xFFFF
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
        instruction_memory[m++] = {`OP_LSL, `R1, `R1, 5'b0, 16'd16};     // LSL R1, R1, 16
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
        instruction_memory[m++] = {`OP_ORI, `R1, `R1, 5'b0, 16'hFFFF};   // ORI R1, R1, 0xFFFF
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing

        // Load 0xFFFFFFFF into R2
        instruction_memory[m++] = {`OP_MOV, `R2, 5'b0, 5'b0, 16'hFFFF};  // MOV R2, #0xFFFF
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
        instruction_memory[m++] = {`OP_LSL, `R2, `R2, 5'b0, 16'd16};     // LSL R2, R2, 16
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
        instruction_memory[m++] = {`OP_ORI, `R2, `R2, 5'b0, 16'hFFFF};  // ORI R2, R2, 0xFFFF
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
        instruction_memory[m++] = {`OP_MOV, `R3, 5'b0, 5'b0, 16'h0000}; // MOV R3, #0
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
        instruction_memory[m++] = {`OP_MOV, `R4, 5'b0, 5'b0, 16'h0000}; // MOV R4, #0
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
        instruction_memory[m++] = {`OP_JMP, 5'b0, 5'b0, 5'b0, 16'd16};  // JMP 16 (start multiplication)
        
        // Load updated instructions into CPU's instruction memory
        for (j = 0; j < 1024; j = j + 1) begin
            cpu.if_stage.inst_mem.memory[j] = instruction_memory[j];
        end
        
        // Wait for program to complete
        #4000;  // Increased wait time to ensure all instructions complete
        
        // Check results
        $display("Result: R3 = %h, R4 = %h", 
                 cpu.dof_stage.reg_file.registers[3], 
                 cpu.dof_stage.reg_file.registers[4]);
        if (cpu.dof_stage.reg_file.registers[3] === 32'h0 && 
            cpu.dof_stage.reg_file.registers[4] === 32'h1) begin
            $display("Test Case 3 PASSED");
            tests_passed = tests_passed + 1;
        end else begin
            $display("Test Case 3 FAILED");
            tests_failed = tests_failed + 1;
        end
        #100;


        //=====================================================================


        // Test Case 4: MAX_POS * MAX_POS
        $display("\nTest Case 4: MAX_POS * MAX_POS");
        $display("Input: R1 = %h, R2 = %h", `MAX_POS, `MAX_POS);
        $display("Expected: R3 = %h, R4 = %h", 32'h3FFFFFFF, 32'h00000001);
        
        // Reset to clear previous state
        rst = 1;
        #20;
        rst = 0;
        #20;

        m=0;
        
        // Update instruction memory for this test case
        // Load 0x7FFFFFFF into R1
        instruction_memory[m++] = {`OP_MOV, `R1, 5'b0, 5'b0, 16'h7FFF};  // MOV R1, #0x7FFF
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
        instruction_memory[m++] = {`OP_LSL, `R1, `R1, 5'b0, 16'd16};     // LSL R1, R1, 16
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
        instruction_memory[m++] = {`OP_ORI, `R1, `R1, 5'b0, 16'hFFFF};   // ORI R1, R1, 0xFFFF
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing

        // Load 0x7FFFFFFF into R2
        instruction_memory[m++] = {`OP_MOV, `R2, 5'b0, 5'b0, 16'h7FFF};  // MOV R2, #0x7FFF
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
        instruction_memory[m++] = {`OP_LSL, `R2, `R2, 5'b0, 16'd16};     // LSL R2, R2, 16
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
        instruction_memory[m++] = {`OP_ORI, `R2, `R2, 5'b0, 16'hFFFF};  // ORI R2, R2, 0xFFFF
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
        instruction_memory[m++] = {`OP_MOV, `R3, 5'b0, 5'b0, 16'h0000}; // MOV R3, #0
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
        instruction_memory[m++] = {`OP_MOV, `R4, 5'b0, 5'b0, 16'h0000}; // MOV R4, #0
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
        instruction_memory[m++] = {`OP_JMP, 5'b0, 5'b0, 5'b0, 16'd16};  // JMP 16 (start multiplication)
        
        // Load updated instructions into CPU's instruction memory
        for (j = 0; j < 1024; j = j + 1) begin
            cpu.if_stage.inst_mem.memory[j] = instruction_memory[j];
        end
        
        // Wait for program to complete
        #4000;  // Increased wait time to ensure all instructions complete
        
        // Check results
        $display("Result: R3 = %h, R4 = %h", 
                 cpu.dof_stage.reg_file.registers[3], 
                 cpu.dof_stage.reg_file.registers[4]);
        if (cpu.dof_stage.reg_file.registers[3] === 32'h3FFFFFFF && 
            cpu.dof_stage.reg_file.registers[4] === 32'h00000001) begin
            $display("Test Case 4 PASSED");
            tests_passed = tests_passed + 1;
        end else begin
            $display("Test Case 4 FAILED");
            tests_failed = tests_failed + 1;
        end
        #100;


        //=====================================================================


        // Test Case 5: MAX_NEG * MAX_NEG
        $display("\nTest Case 5: MAX_NEG * MAX_NEG");
        $display("Input: R1 = %h, R2 = %h", `MAX_NEG, `MAX_NEG);
        $display("Expected: R3 = %h, R4 = %h", 32'h40000000, 32'h00000000);
        
        // Reset to clear previous state
        rst = 1;
        #20;
        rst = 0;
        #20;

        m=0;
        
        // Update instruction memory for this test case
        // Load MAX_NEG (0x80000000) into R1
        instruction_memory[m++] = {`OP_MOV, `R1, 5'b0, 5'b0, 16'h8000};  // MOV R1, #0x8000
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
        instruction_memory[m++] = {`OP_LSL, `R1, `R1, 5'b0, 16'd16};     // LSL R1, R1, 16
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing

        // Load MAX_NEG (0x80000000) into R2
        instruction_memory[m++] = {`OP_MOV, `R2, 5'b0, 5'b0, 16'h8000};  // MOV R2, #0x8000
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
        instruction_memory[m++] = {`OP_LSL, `R2, `R2, 5'b0, 16'd16};     // LSL R2, R2, 16
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
        instruction_memory[m++] = {`OP_MOV, `R3, 5'b0, 5'b0, 16'h0000};  // MOV R3, #0
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
        instruction_memory[m++] = {`OP_MOV, `R4, 5'b0, 5'b0, 16'h0000}; // MOV R4, #0
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
        instruction_memory[m++] = {`OP_JMP, 5'b0, 5'b0, 5'b0, 16'd16};  // JMP 16 (start multiplication)
        
        // Load updated instructions into CPU's instruction memory
        for (j = 0; j < 1024; j = j + 1) begin
            cpu.if_stage.inst_mem.memory[j] = instruction_memory[j];
        end
        
        // Wait for program to complete
        #4000;  // Increased wait time to ensure all instructions complete
        
        // Check results
        $display("Result: R3 = %h, R4 = %h", 
                 cpu.dof_stage.reg_file.registers[3], 
                 cpu.dof_stage.reg_file.registers[4]);
        if (cpu.dof_stage.reg_file.registers[3] === 32'h40000000 && 
            cpu.dof_stage.reg_file.registers[4] === 32'h00000000) begin
            $display("Test Case 5 PASSED");
            tests_passed = tests_passed + 1;
        end else begin
            $display("Test Case 5 FAILED");
            tests_failed = tests_failed + 1;
        end
        #100;


        //=====================================================================

        
        // Test Case 6: Random positive numbers
        $display("\nTest Case 6: Random positive numbers");
        $display("Input: R1 = %h, R2 = %h", 32'h12345678, 32'h76543210);
        $display("Expected: R3 = %h, R4 = %h", 32'h0, 32'h0B88D780);
        
        // Reset to clear previous state
        rst = 1;
        #20;
        rst = 0;
        #20;

        m=0;
        
        // Update instruction memory for this test case
        // Load 0x12345678 into R1
        instruction_memory[m++] = {`OP_MOV, `R1, 5'b0, 5'b0, 16'h1234};  // MOV R1, #0x1234
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
        instruction_memory[m++] = {`OP_LSL, `R1, `R1, 5'b0, 16'd16};     // LSL R1, R1, 16
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
        instruction_memory[m++] = {`OP_ORI, `R1, `R1, 5'b0, 16'h5678};   // ORI R1, R1, 0x5678
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing

        // Load 0x76543210 into R2
        instruction_memory[m++] = {`OP_MOV, `R2, 5'b0, 5'b0, 16'h7654};  // MOV R2, #0x7654
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
        instruction_memory[m++] = {`OP_LSL, `R2, `R2, 5'b0, 16'd16};     // LSL R2, R2, 16
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
        instruction_memory[m++] = {`OP_ORI, `R2, `R2, 5'b0, 16'h3210};  // ORI R2, R2, 0x3210
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
        instruction_memory[m++] = {`OP_MOV, `R3, 5'b0, 5'b0, 16'h0000}; // MOV R3, #0
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
        instruction_memory[m++] = {`OP_MOV, `R4, 5'b0, 5'b0, 16'h0000}; // MOV R4, #0
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
        instruction_memory[m++] = {`OP_JMP, 5'b0, 5'b0, 5'b0, 16'd16};  // JMP 16 (start multiplication)
        
        // Load updated instructions into CPU's instruction memory
        for (j = 0; j < 1024; j = j + 1) begin
            cpu.if_stage.inst_mem.memory[j] = instruction_memory[j];
        end
        
        // Wait for program to complete
        #4000;  // Increased wait time to ensure all instructions complete
        
        // Check results
        $display("Result: R3 = %h, R4 = %h", 
                 cpu.dof_stage.reg_file.registers[3], 
                 cpu.dof_stage.reg_file.registers[4]);
        if (cpu.dof_stage.reg_file.registers[3] === 32'h0 && 
            cpu.dof_stage.reg_file.registers[4] === 32'h0B88D780) begin
            $display("Test Case 6 PASSED");
            tests_passed = tests_passed + 1;
        end else begin
            $display("Test Case 6 FAILED");
            tests_failed = tests_failed + 1;
        end
        #100;


        //=====================================================================


        // Test Case 7: Random negative numbers
        $display("\nTest Case 7: Random negative numbers");
        $display("Input: R1 = %h, R2 = %h", 32'hFEDCBA98, 32'h89ABCDEF);
        $display("Expected: R3 = %h, R4 = %h", 32'h0, 32'hAD05EBE8);
        
        // Reset to clear previous state
        rst = 1;
        #20;
        rst = 0;
        #20;

        m=0;

        // Update instruction memory for this test case
        // Load 0xFEDCBA98 into R1
        instruction_memory[m++] = {`OP_MOV, `R1, 5'b0, 5'b0, 16'hFEDC};  // MOV R1, #0xFEDC
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
        instruction_memory[m++] = {`OP_LSL, `R1, `R1, 5'b0, 16'd16};     // LSL R1, R1, 16
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
        instruction_memory[m++] = {`OP_ORI, `R1, `R1, 5'b0, 16'hBA98};  // ORI R1, R1, 0xBA98
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing

        // Load 0x89ABCDEF into R2
        instruction_memory[m++] = {`OP_MOV, `R2, 5'b0, 5'b0, 16'h89AB}; // MOV R2, #0x89AB
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing

            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
        instruction_memory[m++] = {`OP_LSL, `R2, `R2, 5'b0, 16'd16};    // LSL R2, R2, 16
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
        instruction_memory[m++] = {`OP_ORI, `R2, `R2, 5'b0, 16'hCDEF};  // ORI R2, R2, 0xCDEF
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
        instruction_memory[m++] = {`OP_MOV, `R3, 5'b0, 5'b0, 16'h0000}; // MOV R3, #0
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
        instruction_memory[m++] = {`OP_MOV, `R4, 5'b0, 5'b0, 16'h0000}; // MOV R4, #0
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
        instruction_memory[m++] = {`OP_JMP, 5'b0, 5'b0, 5'b0, 16'd16};  // JMP 16 (start multiplication)
        
        // Load updated instructions into CPU's instruction memory
        for (j = 0; j < 1024; j = j + 1) begin
            cpu.if_stage.inst_mem.memory[j] = instruction_memory[j];
        end
        
        // Wait for program to complete
        #4000;  // Increased wait time to ensure all instructions complete
        
        // Check results
        $display("Result: R3 = %h, R4 = %h", 
                 cpu.dof_stage.reg_file.registers[3], 
                 cpu.dof_stage.reg_file.registers[4]);
        if (cpu.dof_stage.reg_file.registers[3] === 32'h0 && 
            cpu.dof_stage.reg_file.registers[4] === 32'hAD05EBE8) begin
            $display("Test Case 7 PASSED");
            tests_passed = tests_passed + 1;
        end else begin
            $display("Test Case 7 FAILED");
            tests_failed = tests_failed + 1;
        end
        #100;

        
        //=====================================================================


        // Test Case 8: Mixed signs
        $display("\nTest Case 8: Mixed signs");
        $display("Input: R1 = %h, R2 = %h", 32'h12345678, 32'hFEDCBA98);
        $display("Expected: R3 = %h, R4 = %h", 32'h0, 32'h35068740);
        
        // Reset to clear previous state
        rst = 1;
        #20;
        rst = 0;
        #20;

        m=0;
        
        // Update instruction memory for this test case
        // Load 0x12345678 into R1
        instruction_memory[m++] = {`OP_MOV, `R1, 5'b0, 5'b0, 16'h1234};  // MOV R1, #0x1234
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
        instruction_memory[m++] = {`OP_LSL, `R1, `R1, 5'b0, 16'd16};     // LSL R1, R1, 16
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};    // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
        instruction_memory[m++] = {`OP_ORI, `R1, `R1, 5'b0, 16'h5678};  // ORI R1, R1, 0x5678
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing

        // Load 0xFEDCBA98 into R2
        instruction_memory[m++] = {`OP_MOV, `R2, 5'b0, 5'b0, 16'hFEDC}; // MOV R2, #0xFEDC
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
        instruction_memory[m++] = {`OP_LSL, `R2, `R2, 5'b0, 16'd16};    // LSL R2, R2, 16
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
        instruction_memory[m++] = {`OP_ORI, `R2, `R2, 5'b0, 16'hBA98};  // ORI R2, R2, 0xBA98
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
        instruction_memory[m++] = {`OP_MOV, `R3, 5'b0, 5'b0, 16'h0000}; // MOV R3, #0
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
        instruction_memory[m++] = {`OP_MOV, `R4, 5'b0, 5'b0, 16'h0000}; // MOV R4, #0
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
            instruction_memory[m++] = {`OP_NOP, 5'b0, 5'b0, 5'b0, 16'b0};   // NOP for pipeline timing
        instruction_memory[m++] = {`OP_JMP, 5'b0, 5'b0, 5'b0, 16'd16};  // JMP 16 (start multiplication)
        
        // Load updated instructions into CPU's instruction memory
        for (j = 0; j < 1024; j = j + 1) begin
            cpu.if_stage.inst_mem.memory[j] = instruction_memory[j];
        end
        
        // Wait for program to complete
        #4000;  // Increased wait time to ensure all instructions complete
        
        // Check results
        $display("Result: R3 = %h, R4 = %h", 
                 cpu.dof_stage.reg_file.registers[3], 
                 cpu.dof_stage.reg_file.registers[4]);
        if (cpu.dof_stage.reg_file.registers[3] === 32'h0 && 
            cpu.dof_stage.reg_file.registers[4] === 32'h35068740) begin
            $display("Test Case 8 PASSED");
            tests_passed = tests_passed + 1;
        end else begin
            $display("Test Case 8 FAILED");
            tests_failed = tests_failed + 1;
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

    // // Monitor register values
    // always @(posedge clk) begin
    //     if (!rst) begin
    //         $display("Time=%0t R1=%h R2=%h R3=%h R4=%h", 
    //                  $time,
    //                  cpu.dof_stage.reg_file.registers[1],
    //                  cpu.dof_stage.reg_file.registers[2],
    //                  cpu.dof_stage.reg_file.registers[3],
    //                  cpu.dof_stage.reg_file.registers[4]);
    //     end
    // end

endmodule

