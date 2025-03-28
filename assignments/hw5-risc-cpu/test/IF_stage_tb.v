`timescale 1ns/1ps

`include "../IF_stage.v"
`include "../instructionMemory.v"
`include "../muxC.v"

module IF_stage_tb();

    // Test inputs
    reg clk;
    reg rst;
    reg [31:0] PC_initial;
    reg [31:0] BrA;         // Branch target address
    reg [31:0] RAA;         // Register jump address
    reg [31:0] JMP;         // Jump target address
    reg [1:0] BS;           // Branch Select
    reg PS;                 // Program Select (single bit)
    reg Z;                  // Zero flag for branch decisions
    
    // Test outputs
    wire [31:0] PC_next;    // Next PC value
    wire [31:0] PC_1;       // PC + 1
    wire [31:0] instruction; // Current instruction
    
    // For direct testing of instruction memory
    reg [31:0] test_addr;
    wire [31:0] test_instruction;
    
    // Timing parameters
    parameter CLK_PERIOD = 10; // Clock period in ns
    
    // Instantiate the IF stage
    IF_stage dut(
        .clk(clk),
        .rst(rst),
        .PC(PC_initial),
        .BrA(BrA),
        .RAA(RAA),
        .JMP(JMP),
        .BS(BS),
        .PS(PS),
        .Z(Z),
        .PC_next(PC_next),
        .PC_1(PC_1),
        .instruction(instruction)
    );
    
    // Instantiate instruction memory for direct testing
    instructionMemory inst_mem_test(
        .addr(test_addr),
        .instruction(test_instruction)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Initialize test values
    task initialize;
        begin
            rst = 1;
            PC_initial = 32'h0;
            BrA = 32'h20;
            RAA = 32'h30;
            JMP = 32'h40;
            BS = 2'b00;
            PS = 1'b0;
            Z = 1'b0;
            test_addr = 32'h0;
        end
    endtask
    
    // Load test instructions into memory
    task load_test_instructions;
        begin
            // Load some test instructions
            dut.inst_mem.memory[0] = 32'h00000000;  // NOP
            dut.inst_mem.memory[1] = 32'h04108000;  // ADD R1, R2, R4
            dut.inst_mem.memory[2] = 32'h0A108000;  // SUB R1, R2, R4
            dut.inst_mem.memory[3] = 32'hE4518000;  // SLT R2, R5, R6
            
            // Also add to the test memory
            inst_mem_test.memory[0] = 32'h00000000;  // NOP
            inst_mem_test.memory[1] = 32'h04108000;  // ADD R1, R2, R4
            inst_mem_test.memory[2] = 32'h0A108000;  // SUB R1, R2, R4
            inst_mem_test.memory[3] = 32'hE4518000;  // SLT R2, R5, R6
        end
    endtask
    
    // Test scenarios
    task test_sequential_fetch;
        begin
            $display("Testing sequential instruction fetch...");
            PC_initial = 32'h0;
            BS = 2'b00;  // Select PC+1
            PS = 1'b0;
            Z = 1'b0;
            #CLK_PERIOD;
            
            if (PC_next !== 32'h1)
                $display("ERROR: PC_next = %h, expected 32'h1", PC_next);
            else
                $display("PASS: PC_next = %h as expected", PC_next);
                
            if (instruction !== 32'h00000000)
                $display("ERROR: Instruction = %h, expected 32'h00000000", instruction);
            else
                $display("PASS: Instruction = %h as expected", instruction);
            
            // Try next address
            PC_initial = 32'h1;
            #CLK_PERIOD;
            
            if (PC_next !== 32'h2)
                $display("ERROR: PC_next = %h, expected 32'h2", PC_next);
            else
                $display("PASS: PC_next = %h as expected", PC_next);
                
            if (instruction !== 32'h04108000)
                $display("ERROR: Instruction = %h, expected 32'h04108000", instruction);
            else
                $display("PASS: Instruction = %h as expected", instruction);
        end
    endtask
    
    task test_branch_taken;
        begin
            $display("Testing branch taken...");
            PC_initial = 32'h2;
            BS = 2'b01;  // Branch
            PS = 1'b0;   // BZ
            Z = 1'b1;    // Zero is true, should branch
            BrA = 32'h20;
            #CLK_PERIOD;
            
            if (PC_next !== 32'h20)
                $display("ERROR: PC_next = %h, expected 32'h20", PC_next);
            else
                $display("PASS: PC_next = %h as expected", PC_next);
        end
    endtask
    
    task test_branch_not_taken;
        begin
            $display("Testing branch not taken...");
            PC_initial = 32'h2;
            BS = 2'b01;  // Branch
            PS = 1'b0;   // BZ
            Z = 1'b0;    // Zero is false, should not branch
            BrA = 32'h20;
            #CLK_PERIOD;
            
            if (PC_next !== 32'h3)
                $display("ERROR: PC_next = %h, expected 32'h3", PC_next);
            else
                $display("PASS: PC_next = %h as expected", PC_next);
        end
    endtask
    
    task test_bnz_taken;
        begin
            $display("Testing BNZ taken...");
            PC_initial = 32'h2;
            BS = 2'b01;  // Branch
            PS = 1'b1;   // BNZ
            Z = 1'b0;    // Zero is false, should branch for BNZ
            BrA = 32'h20;
            #CLK_PERIOD;
            
            if (PC_next !== 32'h20)
                $display("ERROR: PC_next = %h, expected 32'h20", PC_next);
            else
                $display("PASS: PC_next = %h as expected", PC_next);
        end
    endtask
    
    task test_jump_register;
        begin
            $display("Testing jump register...");
            PC_initial = 32'h2;
            BS = 2'b10;  // Jump register
            RAA = 32'h30;
            #CLK_PERIOD;
            
            if (PC_next !== 32'h30)
                $display("ERROR: PC_next = %h, expected 32'h30", PC_next);
            else
                $display("PASS: PC_next = %h as expected", PC_next);
        end
    endtask
    
    task test_jump_immediate;
        begin
            $display("Testing jump immediate...");
            PC_initial = 32'h2;
            BS = 2'b11;  // Jump immediate
            JMP = 32'h40;
            #CLK_PERIOD;
            
            if (PC_next !== 32'h40)
                $display("ERROR: PC_next = %h, expected 32'h40", PC_next);
            else
                $display("PASS: PC_next = %h as expected", PC_next);
        end
    endtask
    
    task test_instruction_memory;
        begin
            $display("Testing instruction memory directly...");
            test_addr = 32'h0;
            #CLK_PERIOD;
            if (test_instruction !== 32'h00000000)
                $display("ERROR: Instruction at addr 0 = %h, expected 32'h00000000", test_instruction);
            else
                $display("PASS: Instruction at addr 0 = %h as expected", test_instruction);
                
            test_addr = 32'h1;
            #CLK_PERIOD;
            if (test_instruction !== 32'h04108000)
                $display("ERROR: Instruction at addr 1 = %h, expected 32'h04108000", test_instruction);
            else
                $display("PASS: Instruction at addr 1 = %h as expected", test_instruction);
                
            test_addr = 32'h2;
            #CLK_PERIOD;
            if (test_instruction !== 32'h0A108000)
                $display("ERROR: Instruction at addr 2 = %h, expected 32'h0A108000", test_instruction);
            else
                $display("PASS: Instruction at addr 2 = %h as expected", test_instruction);
        end
    endtask
    
    // Main test sequence
    initial begin

        // Initialize waveform dumping
        $dumpfile("IF_stage_tb.vcd");
        $dumpvars(0, IF_stage_tb);
        
        $display("Starting IF stage tests...");
        
        // Initialize
        initialize();
        load_test_instructions();
        
        // Reset sequence
        #(CLK_PERIOD * 2);
        rst = 0;
        #(CLK_PERIOD);
        
        // Run tests
        test_sequential_fetch();
        test_branch_taken();
        test_branch_not_taken();
        test_bnz_taken();
        test_jump_register();
        test_jump_immediate();
        test_instruction_memory();
        
        // End simulation
        $display("All IF stage tests completed!");
        #(CLK_PERIOD * 2);
        $finish;
    end

endmodule 