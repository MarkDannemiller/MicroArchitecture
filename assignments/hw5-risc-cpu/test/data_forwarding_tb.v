`timescale 1ns/1ps

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
`include "hazard_detection_unit.v"  // Include the hazard detection unit

module data_forwarding_tb();

    reg clk;
    reg rst;
    
    // For print_registers task
    reg [8*20:1] test_name;
    
    // Module level integer declarations for loop counters
    integer i;
    
    // Timing parameters
    parameter CLK_PERIOD = 10;  // 10ns clock period

    // Instantiate the top module (CPU)
    top dut(
        .clk(clk),
        .rst(rst)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Function to load a sequence of instructions with forwarding scenarios
    task load_forwarding_test_program;
        begin
            // Initialize all memory locations to NOP
            for (i = 0; i < 1024; i = i + 1)
                dut.if_stage.inst_mem.memory[i] = 32'h00000000;  // NOP
            
            // Test case 1: EX to EX forwarding
            // R1 = 0x12345678
            // ADD R2, R1, R0  (R2 = R1 + 0)
            // ADD R3, R2, R0  (R3 = R2 + 0) - Forward R2 from EX stage
            dut.if_stage.inst_mem.memory[0] = 32'h04200000;  // ADD R2, R1, R0
            dut.if_stage.inst_mem.memory[1] = 32'h04400000;  // ADD R3, R2, R0
            
            // Test case 2: MEM to EX forwarding
            // ADD R4, R1, R0  (R4 = R1 + 0)
            // NOP
            // ADD R5, R4, R0  (R5 = R4 + 0) - Forward R4 from MEM stage
            dut.if_stage.inst_mem.memory[3] = 32'h04800000;  // ADD R4, R1, R0
            dut.if_stage.inst_mem.memory[4] = 32'h00000000;  // NOP
            dut.if_stage.inst_mem.memory[5] = 32'h04A00000;  // ADD R5, R4, R0
            
            // Test case 3: Load-use hazard (stall required)
            // LD R6, [R1]     (Load data from memory[R1])
            // ADD R7, R6, R0  (R7 = R6 + 0) - Stall required, then forward
            dut.if_stage.inst_mem.memory[7] = 32'h21C00000;  // LD R6, [R1]
            dut.if_stage.inst_mem.memory[8] = 32'h04E00000;  // ADD R7, R6, R0
            
            // Test case 4: Multiple forwarding paths
            // ADD R8, R1, R0  (R8 = R1 + 0)
            // ADD R9, R8, R0  (R9 = R8 + 0) - Forward R8 from EX
            // ADD R10, R8, R9 (R10 = R8 + R9) - Forward R8 from MEM, R9 from EX
            dut.if_stage.inst_mem.memory[10] = 32'h05000000;  // ADD R8, R1, R0
            dut.if_stage.inst_mem.memory[11] = 32'h05200000;  // ADD R9, R8, R0
            dut.if_stage.inst_mem.memory[12] = 32'h05122000;  // ADD R10, R8, R9
            
            // Initialize memory data for LD test
            dut.ex_stage.data_mem.memory[dut.dof_stage.reg_file.registers[1][9:0]] = 32'hAABBCCDD;
        end
    endtask
    
    // Task to monitor register values for testing
    task print_registers;
        input [8*20:1] name;
        begin
            test_name = name;
            $display("---------  %0s ---------", test_name);
            $display("R1 = %h", dut.dof_stage.reg_file.registers[1]);
            $display("R2 = %h", dut.dof_stage.reg_file.registers[2]);
            $display("R3 = %h", dut.dof_stage.reg_file.registers[3]);
            $display("R4 = %h", dut.dof_stage.reg_file.registers[4]);
            $display("R5 = %h", dut.dof_stage.reg_file.registers[5]);
            $display("R6 = %h", dut.dof_stage.reg_file.registers[6]);
            $display("R7 = %h", dut.dof_stage.reg_file.registers[7]);
            $display("R8 = %h", dut.dof_stage.reg_file.registers[8]);
            $display("R9 = %h", dut.dof_stage.reg_file.registers[9]);
            $display("R10 = %h", dut.dof_stage.reg_file.registers[10]);
            $display("---------------------------");
        end
    endtask
    
    // Test stimulus
    initial begin
        // Initialize
        rst = 1;
        #(CLK_PERIOD * 2);
        rst = 0;
        
        // Initialize register values for testing
        dut.dof_stage.reg_file.registers[0] = 32'h00000000;  // R0 = 0
        dut.dof_stage.reg_file.registers[1] = 32'h12345678;  // R1 = 0x12345678
        
        // Load test program
        load_forwarding_test_program();
        
        // Print initial register values
        print_registers("Initial State");
        
        // Run test case 1: EX to EX forwarding
        $display("Running Test Case 1: EX to EX forwarding");
        #(CLK_PERIOD * 5);  // Wait for pipeline to execute instructions
        print_registers("After Test Case 1");
        
        // Verify test case 1 results
        if (dut.dof_stage.reg_file.registers[2] !== 32'h12345678)
            $display("ERROR: R2 should be 0x12345678, but is %h", dut.dof_stage.reg_file.registers[2]);
        else
            $display("PASS: R2 = 0x12345678 as expected");
            
        if (dut.dof_stage.reg_file.registers[3] !== 32'h12345678)
            $display("ERROR: R3 should be 0x12345678, but is %h", dut.dof_stage.reg_file.registers[3]);
        else
            $display("PASS: R3 = 0x12345678 as expected (forwarded from EX)");
            
        // Run test case 2: MEM to EX forwarding
        $display("Running Test Case 2: MEM to EX forwarding");
        #(CLK_PERIOD * 5);  // Wait for pipeline to execute instructions
        print_registers("After Test Case 2");
        
        // Verify test case 2 results
        if (dut.dof_stage.reg_file.registers[4] !== 32'h12345678)
            $display("ERROR: R4 should be 0x12345678, but is %h", dut.dof_stage.reg_file.registers[4]);
        else
            $display("PASS: R4 = 0x12345678 as expected");
            
        if (dut.dof_stage.reg_file.registers[5] !== 32'h12345678)
            $display("ERROR: R5 should be 0x12345678, but is %h", dut.dof_stage.reg_file.registers[5]);
        else
            $display("PASS: R5 = 0x12345678 as expected (forwarded from MEM)");
            
        // Run test case 3: Load-use hazard (stall required)
        $display("Running Test Case 3: Load-use hazard (stall required)");
        #(CLK_PERIOD * 5);  // Wait for pipeline to execute instructions
        print_registers("After Test Case 3");
        
        // Verify test case 3 results
        if (dut.dof_stage.reg_file.registers[6] !== 32'hAABBCCDD)
            $display("ERROR: R6 should be 0xAABBCCDD, but is %h", dut.dof_stage.reg_file.registers[6]);
        else
            $display("PASS: R6 = 0xAABBCCDD as expected (loaded from memory)");
            
        if (dut.dof_stage.reg_file.registers[7] !== 32'hAABBCCDD)
            $display("ERROR: R7 should be 0xAABBCCDD, but is %h", dut.dof_stage.reg_file.registers[7]);
        else
            $display("PASS: R7 = 0xAABBCCDD as expected (forwarded after stall)");
            
        // Run test case 4: Multiple forwarding paths
        $display("Running Test Case 4: Multiple forwarding paths");
        #(CLK_PERIOD * 5);  // Wait for pipeline to execute instructions
        print_registers("After Test Case 4");
        
        // Verify test case 4 results
        if (dut.dof_stage.reg_file.registers[8] !== 32'h12345678)
            $display("ERROR: R8 should be 0x12345678, but is %h", dut.dof_stage.reg_file.registers[8]);
        else
            $display("PASS: R8 = 0x12345678 as expected");
            
        if (dut.dof_stage.reg_file.registers[9] !== 32'h12345678)
            $display("ERROR: R9 should be 0x12345678, but is %h", dut.dof_stage.reg_file.registers[9]);
        else
            $display("PASS: R9 = 0x12345678 as expected (forwarded from EX)");
            
        if (dut.dof_stage.reg_file.registers[10] !== 32'h2468ACF0)
            $display("ERROR: R10 should be 0x2468ACF0, but is %h", dut.dof_stage.reg_file.registers[10]);
        else
            $display("PASS: R10 = 0x2468ACF0 as expected (multiple forwarding)");
        
        // End simulation
        $display("All data forwarding tests completed!");
        #(CLK_PERIOD * 2);
        $finish;
    end
    
    // Monitor pipeline states
    always @(posedge clk) begin
        $display("Time=%0t PC=%h IF-DOF-Inst=%h DOF-EX-BusA=%h DOF-EX-BusB=%h EX-ALU=%h",
                 $time, dut.PC, dut.IF_DOF_instruction, dut.DOF_EX_BusA, dut.DOF_EX_BusB, dut.EX_ALU_result);
    end

endmodule