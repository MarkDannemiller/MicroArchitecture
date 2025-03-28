`timescale 1ns/1ps

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

module top_tb();

    reg clk;
    reg rst;
    
    // Module level integer declarations
    integer i;
    integer inst_index;
    integer debug_cycle;
    integer test_phase;
    integer error_count;
    integer pass_count;
    
    // For branch testing
    integer branch_target;
    integer no_branch_target;

    // Timing parameters
    parameter CLK_PERIOD = 10;  // Clock period in ticks
    parameter PIPELINE_STAGES = 6;  // Number of pipeline stages (increased to account for synchronization)
    parameter PIPELINE_DELAY = CLK_PERIOD * PIPELINE_STAGES;  // Wait time for full pipeline
    parameter NOP_COUNT = 5;  // Number of NOPs to insert between instructions (set to 0 to disable)
    parameter NOP_DELAY = CLK_PERIOD * NOP_COUNT;  // Additional delay for NOPs
    
    // Debug parameter - set to 1 to enable debug output, 2 to enable more detailed debug output
    parameter DEBUG = 1;
    
    // Instruction opcodes for easier reference
    parameter NOP_OPCODE = 7'b0000000;
    parameter ADD_OPCODE = 7'b0000010;
    parameter SUB_OPCODE = 7'b0000101;
    parameter AND_OPCODE = 7'b0001000;
    parameter OR_OPCODE  = 7'b0001010;
    parameter XOR_OPCODE = 7'b0001100;
    parameter ST_OPCODE  = 7'b0000001;
    parameter LD_OPCODE  = 7'b0100001;
    parameter BZ_OPCODE  = 7'b0100000;
    parameter BNZ_OPCODE = 7'b1100000;
    parameter JMP_OPCODE = 7'b1000100;

    // Instantiate the top module
    top dut(
        .clk(clk),
        .rst(rst)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;  // 100MHz clock
    end

    // Function to load instruction with NOPs
    function [31:0] load_instruction;
        input [31:0] inst;
        input integer index;
        begin
            if (NOP_COUNT > 0 && (index % (NOP_COUNT + 1) != 0)) begin
                load_instruction = 32'h00000000;  // NOP
            end else begin
                load_instruction = inst;
            end
        end
    endfunction

    // Task to load an instruction with NOPs at the current PC
    task load_instruction_at_pc;
        input [31:0] inst;
        begin
            // Get current PC value to use as the memory index
            inst_index = dut.PC;
            
            // Load instruction at current PC and NOPs after it
            for (i = 0; i <= NOP_COUNT; i = i + 1) begin
                dut.if_stage.inst_mem.memory[inst_index + i] = load_instruction(inst, inst_index + i);
                if (DEBUG) $display("Loaded instruction at mem[%0d] = %h", inst_index + i, dut.if_stage.inst_mem.memory[inst_index + i]);
            end
            
            // For debugging
            if (DEBUG) begin
                $display("Instruction loaded at current PC = %h", inst_index);
                $display("Next instruction should be at PC + NOP_COUNT + 1 = %h", inst_index + NOP_COUNT + 1);
            end
        end
    endtask

    integer pc_val;
    
    // Task to load an instruction sequence without NOPs for hazard testing
    task load_instruction_sequence;
        input [31:0] inst1;
        input [31:0] inst2;
        input [31:0] inst3;
        begin
            // Get current PC value to use as the memory index
            pc_val = dut.PC;
            
            dut.if_stage.inst_mem.memory[pc_val] = inst1;
            dut.if_stage.inst_mem.memory[pc_val+1] = inst2;
            dut.if_stage.inst_mem.memory[pc_val+2] = inst3;
            
            if (DEBUG) begin
                $display("Loaded instruction sequence at PC = %h:", pc_val);
                $display("  mem[%0d] = %h", pc_val, inst1);
                $display("  mem[%0d] = %h", pc_val+1, inst2);
                $display("  mem[%0d] = %h", pc_val+2, inst3);
            end
        end
    endtask
    
    // Verify register value task
    task verify_reg;
        input [4:0] reg_num;
        input [31:0] expected_value;
        begin
            if (dut.dof_stage.reg_file.registers[reg_num] !== expected_value) begin
                $display("FAIL: R%0d = %h, expected %h", reg_num, dut.dof_stage.reg_file.registers[reg_num], expected_value);
                error_count = error_count + 1;
            end else begin
                $display("PASS: R%0d = %h as expected", reg_num, expected_value);
                pass_count = pass_count + 1;
            end
        end
    endtask
    
    // Verify memory value task
    task verify_mem;
        input [31:0] addr;
        input [31:0] expected_value;
        begin
            if (dut.ex_stage.data_mem.memory[addr[9:0]] !== expected_value) begin
                $display("FAIL: mem[%h] = %h, expected %h", addr, dut.ex_stage.data_mem.memory[addr[9:0]], expected_value);
                error_count = error_count + 1;
            end else begin
                $display("PASS: mem[%h] = %h as expected", addr, expected_value);
                pass_count = pass_count + 1;
            end
        end
    endtask
    
    // Verify PC value task
    task verify_pc;
        input [31:0] expected_pc;
        begin
            if (dut.PC !== expected_pc) begin
                $display("FAIL: PC = %h, expected %h", dut.PC, expected_pc);
                error_count = error_count + 1;
            end else begin
                $display("PASS: PC = %h as expected", expected_pc);
                pass_count = pass_count + 1;
            end
        end
    endtask
    
    // Debug signals at each clock cycle
    always @(posedge clk) begin
        if (DEBUG > 1) begin
            $display("------ Cycle %0d ------", debug_cycle);
            $display("PC=%h, PC_1=%h, PC_2=%h", dut.PC, dut.PC_1, dut.PC_2);
            
            // IF Stage debug
            $display("IF: next_PC=%h, instruction=%h", dut.IF_PC_next, dut.IF_instruction);
            
            // DOF Stage debug - enhanced with register values and MUX outputs
            $display("DOF: instruction=%h, RW=%b, FS=%h, DR=%h", 
                     dut.IF_DOF_instruction, dut.DOF_RW, dut.DOF_FS, dut.DOF_DR);
            $display("DOF: A_data=%h, B_data=%h, BusA=%h, BusB=%h", 
                     dut.DOF_A_data, dut.DOF_B_data, dut.DOF_BusA, dut.DOF_BusB);
            $display("DOF Control: MW=%b, MD=%b, BS=%b, PS=%b, extended_imm=%h", 
                     dut.DOF_MW, dut.DOF_MD, dut.DOF_BS, dut.DOF_PS, dut.DOF_extended_imm);
            
            // EX Stage debug - enhanced with control signals
            $display("EX: BusA=%h, BusB=%h, ALU_result=%h, Z=%b, V=%b, N=%b", 
                     dut.DOF_EX_BusA, dut.DOF_EX_BusB, dut.EX_ALU_result, dut.EX_Z, dut.EX_V, dut.EX_N);
            $display("EX Control: RW=%b, MW=%b, MD=%b, FS=%h, DR=%h, SH=%h", 
                     dut.DOF_EX_RW, dut.DOF_EX_MW, dut.DOF_EX_MD, dut.DOF_EX_FS, dut.DOF_EX_DR, dut.DOF_EX_SH);
            $display("EX Memory: mem_data=%h, BrA=%h, N_xor_V=%b", 
                     dut.EX_mem_data, dut.EX_BrA, dut.EX_N_xor_V);
            
            // WB Stage debug
            $display("WB: RW=%b, DR=%h, data=%h", 
                     dut.EX_WB_RW, dut.EX_WB_DR, dut.WB_data);
            $display("WB Control: MD=%b, N_xor_V=%b", 
                     dut.EX_WB_MD, dut.EX_WB_N_xor_V);
            
            $display("---------------------");
            debug_cycle = debug_cycle + 1;
        end
    end

    // Task to display pipeline state for better visualization
    task display_pipeline_state;
        begin
            $display("===== PIPELINE STATE =====");
            $display("PC: %h | IF: %h | DOF: %h | EX: %h | WB: %h", 
                    dut.PC, 
                    dut.IF_instruction,
                    dut.IF_DOF_instruction, 
                    {dut.DOF_EX_FS, dut.DOF_EX_DR, "-"},  // Simplified format for readability
                    {dut.EX_WB_DR, dut.WB_data[15:0]});   // Truncated data for readability
            
            // Show register file state for key registers
            $display("Register file: R1=%h R2=%h R3=%h R4=%h R5=%h",
                    dut.dof_stage.reg_file.registers[1],
                    dut.dof_stage.reg_file.registers[2],
                    dut.dof_stage.reg_file.registers[3],
                    dut.dof_stage.reg_file.registers[4],
                    dut.dof_stage.reg_file.registers[5]);
            $display("========================");
        end
    endtask

    // Test stimulus
    initial begin
        // Initialize debug counter and error tracking
        debug_cycle = 0;
        test_phase = 0;
        error_count = 0;
        pass_count = 0;
        
        // Debug module hierarchy check
        if (DEBUG) begin
            $display("===== MODULE HIERARCHY CHECK =====");
            $display("top.PC = %h", dut.PC);
            $display("top.if_stage.PC = %h", dut.if_stage.PC);
            $display("top.dof_stage.instruction = %h", dut.dof_stage.instruction);
            $display("top.ex_stage.BusA = %h", dut.ex_stage.BusA);
            $display("top.wb_stage.ALU_result = %h", dut.wb_stage.ALU_result);
            
            // Check if instruction memory is accessible
            $display("IF inst_mem memory[0] initially = %h", dut.if_stage.inst_mem.memory[0]);
            // Check if register file is accessible
            $display("DOF reg_file registers[1] initially = %h", dut.dof_stage.reg_file.registers[1]);
            $display("==============================");
        end
        
        // Initialize waveform dumping
        $dumpfile("top_tb.vcd");
        $dumpvars(0, top_tb);

        // Reset sequence
        rst = 1;
        #(CLK_PERIOD * 4);  // Extended wait for reset (4 cycles)
        
        // Debug checking reset state
        if (DEBUG > 0) begin
            $display("===== AFTER RESET =====");
            $display("PC = %h", dut.PC);
            $display("IF_DOF_instruction = %h", dut.IF_DOF_instruction);
            $display("DOF_EX_* signals reset? RW=%b, MD=%b, MW=%b", 
                     dut.DOF_EX_RW, dut.DOF_EX_MD, dut.DOF_EX_MW);
            $display("EX_WB_* signals reset? RW=%b, MD=%b", 
                     dut.EX_WB_RW, dut.EX_WB_MD);
            $display("=====================");
        end
        
        rst = 0;
        #(CLK_PERIOD * 4);  // Extended wait after reset (4 cycles)
        
        if (DEBUG > 0) $display("===== PIPELINE VERIFICATION TEST =====");
        // PHASE 1: PIPELINE VERIFICATION TEST
        test_phase = 1;
        $display("\n===== PHASE %0d: PIPELINE VERIFICATION TEST =====", test_phase);
        
        // Clear any existing instructions and start fresh
        for (i = 0; i < 1024; i = i + 1) begin
            dut.if_stage.inst_mem.memory[i] = 32'h00000000;  // NOP
        end
        
        // Load test instructions to verify pipeline register propagation
        load_instruction_at_pc(32'h04200000);  // ADD R2, R1, R0 at index 1
        
        // Initialize register 1 with a test value
        dut.dof_stage.reg_file.registers[1] = 32'h12345678;
        
        // Wait for a full clock cycle to allow the first instruction to be fetched
        #(CLK_PERIOD);
        if (DEBUG > 0) begin
            $display("After 1 cycle - PC=%h, IF_instruction=%h", dut.PC, dut.IF_instruction);
            display_pipeline_state();
        end
        
        // Wait another cycle for the first instruction to move to DOF
        #(CLK_PERIOD);
        if (DEBUG > 0) begin
            $display("After 2 cycles - PC=%h, IF_DOF_instruction=%h", dut.PC, dut.IF_DOF_instruction);
            display_pipeline_state();
        end
        
        // Wait another cycle for execution stage
        #(CLK_PERIOD);
        if (DEBUG > 0) begin
            $display("After 3 cycles - DOF_EX_RW=%b, DOF_EX_FS=%h", dut.DOF_EX_RW, dut.DOF_EX_FS);
            display_pipeline_state();
        end
        
        // Wait another cycle for writeback
        #(CLK_PERIOD);
        if (DEBUG > 0) begin
            $display("After 4 cycles - EX_WB_RW=%b, EX_WB_DR=%h", dut.EX_WB_RW, dut.EX_WB_DR);
            display_pipeline_state();
        end
        
        // Final verification of registers
        #(CLK_PERIOD);
        if (DEBUG > 0) begin
            $display("After 5 cycles - R2=%h", dut.dof_stage.reg_file.registers[2]);
            display_pipeline_state();
        end
        
        verify_reg(5'b00010, 32'h12345678); // R2 should have R1's value after ADD R2, R1, R0
        $display("===== END PIPELINE VERIFICATION =====\n");
        
        // Wait one more cycle to ensure pipeline is fully reset
        #(CLK_PERIOD);
        
        // PHASE 2: REGISTER INITIALIZATION AND BASIC INSTRUCTION TESTING
        test_phase = 2;
        $display("\n===== PHASE %0d: REGISTER INITIALIZATION AND BASIC INSTRUCTION TESTING =====", test_phase);
        
        // Clear any existing instructions again
        for (i = 0; i < 1024; i = i + 1) begin
            dut.if_stage.inst_mem.memory[i] = 32'h00000000;  // NOP
        end
        
        // Reset instruction index
        inst_index = 0;
        
        // Initialize test data in registers with edge cases
        dut.dof_stage.reg_file.registers[0] = 32'h00000000;  // R0 = 0 (always 0)
        dut.dof_stage.reg_file.registers[1] = 32'h12345678;  // R1 = 0x12345678
        dut.dof_stage.reg_file.registers[2] = 32'h56789ABC;  // R2 = 0x56789ABC
        dut.dof_stage.reg_file.registers[3] = 32'h9ABCDEF0;  // R3 = 0x9ABCDEF0
        dut.dof_stage.reg_file.registers[4] = 32'hFFFFFFFF;  // R4 = -1 (all 1s)
        dut.dof_stage.reg_file.registers[5] = 32'h80000000;  // R5 = min negative
        dut.dof_stage.reg_file.registers[6] = 32'h7FFFFFFF;  // R6 = max positive
        dut.dof_stage.reg_file.registers[7] = 32'hAAAAAAAA;  // R7 = alternating 1s
        dut.dof_stage.reg_file.registers[8] = 32'h55555555;  // R8 = alternating 0s
        
        if (DEBUG > 0) begin
            $display("===== REGISTER INITIALIZATION =====");
            for (i = 0; i < 9; i = i + 1) begin
                $display("R%0d = %h", i, dut.dof_stage.reg_file.registers[i]);
            end
            $display("=================================");
        end
        
        // Test sequence with edge cases
        $display("Starting instruction tests...");
        
        // Test NOP
        $display("Testing NOP instruction...");
        load_instruction_at_pc(32'h00000000);  // NOP (0000000 DR SA SB -)
        inst_index = inst_index + NOP_COUNT + 1;
        #(PIPELINE_DELAY + NOP_DELAY);  // Wait for pipeline + NOPs
        verify_reg(5'b00001, 32'h12345678);  // Verify R1 unchanged
        
        // Test ADD with various cases
        $display("Testing ADD instruction with various cases...");
        load_instruction_at_pc(32'h04108000);  // ADD R1, R2, R4 (0000010 00001 00010 00100 -)
        inst_index = inst_index + NOP_COUNT + 1;
        
        if (DEBUG > 0) begin
            $display("===== BEFORE ADD EXECUTION =====");
            $display("PC = %h", dut.PC);
            $display("ADD instruction location = %h", inst_index - NOP_COUNT - 1);
            $display("ADD instruction in memory = %h", dut.if_stage.inst_mem.memory[inst_index - NOP_COUNT - 1]);
            $display("R2 = %h, R4 = %h", dut.dof_stage.reg_file.registers[2], dut.dof_stage.reg_file.registers[4]);
            $display("==============================");
        end
        
        #(PIPELINE_DELAY + NOP_DELAY);  // Wait for pipeline + NOPs
        
        if (DEBUG > 0) begin
            $display("===== AFTER ADD EXECUTION =====");
            $display("PC = %h", dut.PC);
            $display("R1 = %h (expected: %h)", 
                     dut.dof_stage.reg_file.registers[1], 
                     32'h5678789B);
            $display("==============================");
        end
        
        verify_reg(5'b00001, 32'h5678789B);  // Check R1 = R2 + R4
        
        load_instruction_at_pc(32'h04518000);  // ADD R2, R5, R6 (0000010 00010 00101 00110 -)
        inst_index = inst_index + NOP_COUNT + 1;
        #(PIPELINE_DELAY + NOP_DELAY);  // Wait for pipeline + NOPs
        
        if (DEBUG > 0) begin
            $display("===== AFTER SECOND ADD EXECUTION =====");
            $display("PC = %h", dut.PC);
            $display("R2 = %h (expected: %h)",
                     dut.dof_stage.reg_file.registers[2],
                     32'hFFFFFFFF);
            $display("R5 = %h, R6 = %h", 
                     dut.dof_stage.reg_file.registers[5], 
                     dut.dof_stage.reg_file.registers[6]);
            $display("==================================");
        end
        
        verify_reg(5'b00010, 32'hFFFFFFFF);  // Check R2 = R5 + R6 (overflow)
        
        // Test SUB with various cases
        $display("Testing SUB instruction with various cases...");
        load_instruction_at_pc(32'h0A108000);  // SUB R1, R2, R4 (0000101 00001 00010 00100 -)
        inst_index = inst_index + NOP_COUNT + 1;
        #(PIPELINE_DELAY + NOP_DELAY);  // Wait for pipeline + NOPs
        
        if (DEBUG > 0) begin
            $display("===== AFTER SUB EXECUTION =====");
            $display("PC = %h", dut.PC);
            $display("R1 = %h (expected: %h)", 
                     dut.dof_stage.reg_file.registers[1], 
                     32'h00000000);  // FFFFFFFF - FFFFFFFF = 0
            $display("R2 = %h, R4 = %h", 
                     dut.dof_stage.reg_file.registers[2], 
                     dut.dof_stage.reg_file.registers[4]);
            $display("==============================");
        end
        
        verify_reg(5'b00001, 32'h00000000);  // Check R1 = R2 - R4
        
        load_instruction_at_pc(32'h0A518000);  // SUB R2, R5, R6 (0000101 00010 00101 00110 -)
        inst_index = inst_index + NOP_COUNT + 1;
        #(PIPELINE_DELAY + NOP_DELAY);  // Wait for pipeline + NOPs
        verify_reg(5'b00010, 32'h00000001);  // Check R2 = R5 - R6 = 80000000 - 7FFFFFFF = 1
        
        // Test SLT with various cases
        $display("Testing SLT instruction with various cases...");
        load_instruction_at_pc(32'hE4518000);  // SLT R2, R5, R6 (1100101 00010 00101 00110 -)
        inst_index = inst_index + NOP_COUNT + 1;
        #(PIPELINE_DELAY + NOP_DELAY);  // Wait for pipeline + NOPs
        
        if (DEBUG > 0) begin
            $display("===== AFTER SLT EXECUTION =====");
            $display("PC = %h", dut.PC);
            $display("R2 = %h (expected: %h)", 
                     dut.dof_stage.reg_file.registers[2], 
                     32'h00000001);  // R5 < R6, so result should be 1
            $display("R5 = %h, R6 = %h", 
                     dut.dof_stage.reg_file.registers[5], 
                     dut.dof_stage.reg_file.registers[6]);
            $display("EX_N_xor_V = %b", dut.EX_N_xor_V);
            $display("EX_WB_N_xor_V = %b", dut.EX_WB_N_xor_V);
            $display("EX_WB_MD = %b", dut.EX_WB_MD);
            $display("==============================");
        end
        
        verify_reg(5'b00010, 32'h00000001);  // Check R2 = 1 (R5 < R6)
        
        load_instruction_at_pc(32'hE4728000);  // SLT R3, R6, R5 (1100101 00011 00110 00101 -)
        inst_index = inst_index + NOP_COUNT + 1;
        #(PIPELINE_DELAY + NOP_DELAY);  // Wait for pipeline + NOPs
        verify_reg(5'b00011, 32'h00000000);  // Check R3 = 0 (R6 > R5)
        
        // Test AND with various cases
        $display("Testing AND instruction with various cases...");
        load_instruction_at_pc(32'h10108000);  // AND R1, R2, R8 (0001000 00001 00010 01000 -)
        inst_index = inst_index + NOP_COUNT + 1;
        #(PIPELINE_DELAY + NOP_DELAY);  // Wait for pipeline + NOPs
        
        if (DEBUG > 0) begin
            $display("===== AFTER AND EXECUTION =====");
            $display("PC = %h", dut.PC);
            $display("R1 = %h (expected: %h)", 
                     dut.dof_stage.reg_file.registers[1], 
                     32'h00000001 & 32'h55555555);  // R2 & R8
            $display("R2 = %h, R8 = %h", 
                     dut.dof_stage.reg_file.registers[2], 
                     dut.dof_stage.reg_file.registers[8]);
            $display("==============================");
        end
        
        verify_reg(5'b00001, 32'h00000001 & 32'h55555555);  // Check R1 = R2 & R8
        
        // Test OR with various cases
        $display("Testing OR instruction with various cases...");
        load_instruction_at_pc(32'h14738000);  // OR R3, R7, R8 (0001010 00011 00111 01000 -)
        inst_index = inst_index + NOP_COUNT + 1;
        #(PIPELINE_DELAY + NOP_DELAY);  // Wait for pipeline + NOPs
        
        if (DEBUG > 0) begin
            $display("===== AFTER OR EXECUTION =====");
            $display("PC = %h", dut.PC);
            $display("R3 = %h (expected: %h)", 
                     dut.dof_stage.reg_file.registers[3], 
                     32'hFFFFFFFF);  // R7 | R8 = AAAAAAAA | 55555555 = FFFFFFFF
            $display("R7 = %h, R8 = %h", 
                     dut.dof_stage.reg_file.registers[7], 
                     dut.dof_stage.reg_file.registers[8]);
            $display("==============================");
        end
        
        verify_reg(5'b00011, 32'hFFFFFFFF);  // Check R3 = R7 | R8 = AAAAAAAA | 55555555 = FFFFFFFF
        
        // Test XOR with various cases
        $display("Testing XOR instruction with various cases...");
        load_instruction_at_pc(32'h18738000);  // XOR R3, R7, R8 (0001100 00011 00111 01000 -)
        inst_index = inst_index + NOP_COUNT + 1;
        #(PIPELINE_DELAY + NOP_DELAY);  // Wait for pipeline + NOPs
        
        if (DEBUG > 0) begin
            $display("===== AFTER XOR EXECUTION =====");
            $display("PC = %h", dut.PC);
            $display("R3 = %h (expected: %h)", 
                     dut.dof_stage.reg_file.registers[3], 
                     32'hFFFFFFFF);  // R7 ^ R8 = AAAAAAAA ^ 55555555 = FFFFFFFF
            $display("R7 = %h, R8 = %h", 
                     dut.dof_stage.reg_file.registers[7], 
                     dut.dof_stage.reg_file.registers[8]);
            $display("==============================");
        end
        
        verify_reg(5'b00011, 32'hFFFFFFFF);  // Check R3 = R7 ^ R8 = AAAAAAAA ^ 55555555 = FFFFFFFF
        
        // PHASE 3: MEMORY OPERATIONS
        test_phase = 3;
        $display("\n===== PHASE %0d: MEMORY OPERATIONS =====", test_phase);
        
        // Initialize some memory locations for testing
        dut.ex_stage.data_mem.memory[0] = 32'h00000000;
        dut.ex_stage.data_mem.memory[10] = 32'hDEADBEEF;
        
        // Test ST and LD with various addresses
        $display("Testing ST and LD instructions with various addresses...");
        
        // Store R2 to memory location [R1] (R1 has value 0x00000001)
        dut.dof_stage.reg_file.registers[1] = 32'h00000020;  // Set R1 to 0x20 (memory address)
        load_instruction_at_pc(32'h01200000);  // ST [R1], R2 (0000001 00000 00001 00010 -)
        inst_index = inst_index + NOP_COUNT + 1;
        #(PIPELINE_DELAY + NOP_DELAY);  // Wait for pipeline + NOPs
        
        if (DEBUG > 0) begin
            $display("===== AFTER ST EXECUTION =====");
            $display("PC = %h", dut.PC);
            $display("mem[%h] = %h (expected: %h)", 
                     dut.dof_stage.reg_file.registers[1], 
                     dut.ex_stage.data_mem.memory[32'h20], 
                     dut.dof_stage.reg_file.registers[2]);
            $display("R1 = %h, R2 = %h", 
                     dut.dof_stage.reg_file.registers[1], 
                     dut.dof_stage.reg_file.registers[2]);
            $display("==============================");
        end
        
        verify_mem(32'h20, 32'h00000001);  // Check memory at R1's address has R2's value
        
        // Load from memory location [R1] to R9
        load_instruction_at_pc(32'h21100000);  // LD R9, [R1] (0100001 01001 00001 00000 -)
        inst_index = inst_index + NOP_COUNT + 1;
        #(PIPELINE_DELAY + NOP_DELAY);  // Wait for pipeline + NOPs
        
        if (DEBUG > 0) begin
            $display("===== AFTER LD EXECUTION =====");
            $display("PC = %h", dut.PC);
            $display("R9 = %h (expected: %h)", 
                     dut.dof_stage.reg_file.registers[9], 
                     dut.ex_stage.data_mem.memory[32'h20]);
            $display("mem[%h] = %h", 
                     dut.dof_stage.reg_file.registers[1], 
                     dut.ex_stage.data_mem.memory[32'h20]);
            $display("==============================");
        end
        
        verify_reg(5'b01001, 32'h00000001);  // Check R9 loaded from memory
        
        // PHASE 4: IMMEDIATE OPERATIONS
        test_phase = 4;
        $display("\n===== PHASE %0d: IMMEDIATE OPERATIONS =====", test_phase);
        
        // Test immediate operations with various values
        $display("Testing immediate operations with various values...");
        
        // Set R1 to a known value for immediate operations
        dut.dof_stage.reg_file.registers[1] = 32'h12345678;
        
        // Test ADI (Add Immediate)
        load_instruction_at_pc(32'h24140001);  // ADI R10, R1, #1 (0100010 01010 00001 Imm8=1)
        inst_index = inst_index + NOP_COUNT + 1;
        #(PIPELINE_DELAY + NOP_DELAY);  // Wait for pipeline + NOPs
        
        if (DEBUG > 0) begin
            $display("===== AFTER ADI EXECUTION =====");
            $display("PC = %h", dut.PC);
            $display("R10 = %h (expected: %h)", 
                     dut.dof_stage.reg_file.registers[10], 
                     32'h12345679);  // R1 + 1
            $display("R1 = %h", dut.dof_stage.reg_file.registers[1]);
            $display("==============================");
        end
        
        verify_reg(5'b01010, 32'h12345679);  // Check R10 = R1 + 1
        
        // Test SBI (Subtract Immediate)
        load_instruction_at_pc(32'h28140001);  // SBI R11, R1, #1 (0100101 01011 00001 Imm8=1)
        inst_index = inst_index + NOP_COUNT + 1;
        #(PIPELINE_DELAY + NOP_DELAY);  // Wait for pipeline + NOPs
        
        if (DEBUG > 0) begin
            $display("===== AFTER SBI EXECUTION =====");
            $display("PC = %h", dut.PC);
            $display("R11 = %h (expected: %h)", 
                     dut.dof_stage.reg_file.registers[11], 
                     32'h12345676);  // R1 - 1 - 1
            $display("R1 = %h", dut.dof_stage.reg_file.registers[1]);
            $display("==============================");
        end
        
        verify_reg(5'b01011, 32'h12345676);  // Check R11 = R1 - 1 - 1
        
        // Test NOT (Logical NOT)
        load_instruction_at_pc(32'h1C100000);  // NOT R12, R1 (0001110 01100 00001 00000 -)
        inst_index = inst_index + NOP_COUNT + 1;
        #(PIPELINE_DELAY + NOP_DELAY);  // Wait for pipeline + NOPs
        
        if (DEBUG > 0) begin
            $display("===== AFTER NOT EXECUTION =====");
            $display("PC = %h", dut.PC);
            $display("R12 = %h (expected: %h)", 
                     dut.dof_stage.reg_file.registers[12], 
                     ~32'h12345678);  // ~R1
            $display("R1 = %h", dut.dof_stage.reg_file.registers[1]);
            $display("==============================");
        end
        
        verify_reg(5'b01100, ~32'h12345678);  // Check R12 = ~R1
        
        // Test ANI (AND Immediate)
        load_instruction_at_pc(32'h501400F0);  // ANI R13, R1, #0xF0 (0101000 01101 00001 Imm8=0xF0)
        inst_index = inst_index + NOP_COUNT + 1;
        #(PIPELINE_DELAY + NOP_DELAY);  // Wait for pipeline + NOPs
        
        if (DEBUG > 0) begin
            $display("===== AFTER ANI EXECUTION =====");
            $display("PC = %h", dut.PC);
            $display("R13 = %h (expected: %h)", 
                     dut.dof_stage.reg_file.registers[13], 
                     32'h12345678 & 32'h000000F0);  // R1 & 0x000000F0
            $display("R1 = %h", dut.dof_stage.reg_file.registers[1]);
            $display("==============================");
        end
        
        verify_reg(5'b01101, 32'h12345678 & 32'h000000F0);  // Check R13 = R1 & 0x000000F0
        
        // PHASE 5: BRANCH AND JUMP OPERATIONS
        test_phase = 5;
        $display("\n===== PHASE %0d: BRANCH AND JUMP OPERATIONS =====", test_phase);
        
        // Clear all memory with NOPs and reset instruction index
        for (i = 0; i < 1024; i = i + 1) begin
            dut.if_stage.inst_mem.memory[i] = 32'h00000000;  // NOP
        end
        inst_index = 100;  // Start at index 100 to give room for branches
        
        // Test BZ (Branch if Zero)
        $display("Testing BZ instruction...");
        
        // Set R1 to zero for branch taken test
        dut.dof_stage.reg_file.registers[1] = 32'h00000000;
        
        // Branch if R1 = 0, to PC+10
        load_instruction_at_pc(32'h2010000A);  // BZ R1, #10 (0100000 00000 00001 Offset=10)
        
        // Expected branch target
        branch_target = inst_index + NOP_COUNT + 1 + 10;
        
        inst_index = inst_index + NOP_COUNT + 1;
        #(PIPELINE_DELAY + NOP_DELAY);  // Wait for pipeline + NOPs
        
        if (DEBUG > 0) begin
            $display("===== AFTER BZ EXECUTION (R1=0) =====");
            $display("PC = %h", dut.PC);
            $display("Expected PC = %h", branch_target);
            $display("BrA = %h", dut.EX_BrA);
            $display("R1 = %h", dut.dof_stage.reg_file.registers[1]);
            $display("================================");
        end
        
        verify_pc(branch_target);  // Check PC = branch target address
        
        // Reset for next test
        inst_index = 150;
        
        // Set R1 to non-zero for branch not taken test
        dut.dof_stage.reg_file.registers[1] = 32'h12345678;
        
        // Branch if R1 = 0, to PC+10 (should not branch)
        load_instruction_at_pc(32'h2010000A);  // BZ R1, #10 (0100000 00000 00001 Offset=10)
        
        // Expected next PC (no branch)
        no_branch_target = inst_index + NOP_COUNT + 1;
        
        inst_index = inst_index + NOP_COUNT + 1;
        #(PIPELINE_DELAY + NOP_DELAY);  // Wait for pipeline + NOPs
        
        if (DEBUG > 0) begin
            $display("===== AFTER BZ EXECUTION (R1≠0) =====");
            $display("PC = %h", dut.PC);
            $display("Expected PC = %h", no_branch_target);
            $display("BrA = %h", dut.EX_BrA);
            $display("R1 = %h", dut.dof_stage.reg_file.registers[1]);
            $display("================================");
        end
        
        verify_pc(no_branch_target);  // Check PC = no branch target
        
        // PHASE 6: HAZARD TESTING (PIPELINE DEPENDENCIES)
        test_phase = 6;
        $display("\n===== PHASE %0d: HAZARD TESTING =====", test_phase);
        
        // Clear all memory again
        for (i = 0; i < 1024; i = i + 1) begin
            dut.if_stage.inst_mem.memory[i] = 32'h00000000;  // NOP
        end
        
        // Initialize registers for hazard testing
        dut.dof_stage.reg_file.registers[1] = 32'h00000001;
        dut.dof_stage.reg_file.registers[2] = 32'h00000002;
        dut.dof_stage.reg_file.registers[3] = 32'h00000003;
        
        // Test data hazard (RAW - Read After Write)
        $display("Testing data hazard (RAW)...");
        
        // Setup instruction sequence with dependency
        // ADD R4, R1, R2     # R4 = 1 + 2 = 3
        // ADD R5, R4, R3     # R5 = R4 + 3 = 6 (depends on previous result)
        // ADD R6, R5, R1     # R6 = R5 + 1 = 7 (depends on previous result)
        
        inst_index = 200;
        load_instruction_sequence(
            32'h04108000,  // ADD R4, R1, R2
            32'h04283000,  // ADD R5, R4, R3
            32'h05401000   // ADD R6, R5, R1
        );
        
        // Execute the instruction sequence (need to wait for more cycles due to dependencies)
        #(PIPELINE_DELAY * 3 + CLK_PERIOD * 5);
        
        if (DEBUG > 0) begin
            $display("===== AFTER RAW HAZARD SEQUENCE =====");
            $display("PC = %h", dut.PC);
            $display("R4 = %h (expected: %h)", 
                     dut.dof_stage.reg_file.registers[4], 
                     32'h00000003);  // R1 + R2
            $display("R5 = %h (expected: %h)", 
                     dut.dof_stage.reg_file.registers[5], 
                     32'h00000006);  // R4 + R3
            $display("R6 = %h (expected: %h)", 
                     dut.dof_stage.reg_file.registers[6], 
                     32'h00000007);  // R5 + R1
            $display("================================");
        end
        
        // Since we have no forwarding, hazards may cause incorrect results
        // If we get correct results, it's likely because we're using negedge for pipeline registers
        // But this is still a good test of pipeline behavior
        
        verify_reg(5'b00100, 32'h00000003);  // Check R4 = R1 + R2 = 3
        verify_reg(5'b00101, 32'h00000006);  // Check R5 = R4 + R3 = 6
        verify_reg(5'b00110, 32'h00000007);  // Check R6 = R5 + R1 = 7
        
        // TEST SUMMARY AND CONCLUSION
        $display("\n===== TEST SUMMARY =====");
        $display("Total tests passed: %0d", pass_count);
        $display("Total tests failed: %0d", error_count);
        $display("======================");
        
        // Display the final state of important registers
        $display("\n===== FINAL REGISTER STATE =====");
        for (i = 0; i < 16; i = i + 1) begin
            $display("R%0d = %h", i, dut.dof_stage.reg_file.registers[i]);
        end
        
        // Display the state of data memory
        $display("\n===== DATA MEMORY STATE =====");
        $display("mem[0x00] = %h", dut.ex_stage.data_mem.memory[0]);
        $display("mem[0x20] = %h", dut.ex_stage.data_mem.memory[32'h20]);
        
        // End simulation
        $display("\nAll tests completed!");
        #(CLK_PERIOD * 5);
        $finish;
    end

    // Monitor changes in important signals for debugging
    // Uncomment this section for more detailed signal monitoring
    /*
    always @(posedge clk) begin
        $display("Time=%0t PC=%h A_data=%h B_data=%h ALU_result=%h Z=%b V=%b N=%b C=%b",
                 $time, dut.PC, dut.DOF_A_data, dut.DOF_B_data, dut.EX_ALU_result, 
                 dut.EX_Z, dut.EX_V, dut.EX_N, dut.EX_C);
    end
    */

endmodule 