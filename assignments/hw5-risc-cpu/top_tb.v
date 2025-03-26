module top_tb();

    reg clk;
    reg rst;
    wire [15:0] PC;
    wire [15:0] A_data, B_data;
    wire [15:0] ALU_result;
    wire Z, V, N, C;

    // Timing parameters
    parameter CLK_PERIOD = 10;  // Clock period in ticks
    parameter PIPELINE_STAGES = 5;  // Number of pipeline stages
    parameter PIPELINE_DELAY = CLK_PERIOD * PIPELINE_STAGES;  // Wait time for full pipeline
    parameter NOP_COUNT = 5;  // Number of NOPs to insert between instructions (set to 0 to disable)
    parameter NOP_DELAY = CLK_PERIOD * NOP_COUNT;  // Additional delay for NOPs

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
    function [21:0] load_instruction;
        input [21:0] inst;
        input integer index;
        begin
            if (NOP_COUNT > 0 && (index % (NOP_COUNT + 1) != 0)) begin
                load_instruction = 22'b0000000000000000000000;  // NOP
            end else begin
                load_instruction = inst;
            end
        end
    endfunction

    // Task to load an instruction with NOPs
    task load_instruction_with_nops;
        input [21:0] inst;
        input integer start_index;
        begin
            integer i;
            for (i = 0; i <= NOP_COUNT; i = i + 1) begin
                dut.inst_mem.memory[start_index + i] = load_instruction(inst, start_index + i);
            end
        end
    endtask

    // Test stimulus
    initial begin
        // Initialize waveform dumping
        $dumpfile("top_tb.vcd");
        $dumpvars(0, top_tb);

        // Reset sequence
        rst = 1;
        #(CLK_PERIOD * 2);  // Wait 2 clock cycles for reset
        rst = 0;
        #(CLK_PERIOD * 2);  // Wait 2 clock cycles after reset

        // Load all instructions at the beginning
        integer inst_index = 0;
        
        // Initialize test data in registers with edge cases
        dut.reg_file.registers[0] = 16'h0000;  // R0 = 0 (always 0)
        dut.reg_file.registers[1] = 16'h1234;  // R1 = 0x1234
        dut.reg_file.registers[2] = 16'h5678;  // R2 = 0x5678
        dut.reg_file.registers[3] = 16'h9ABC;  // R3 = 0x9ABC
        dut.reg_file.registers[4] = 16'hFFFF;  // R4 = -1 (all 1s)
        dut.reg_file.registers[5] = 16'h8000;  // R5 = -32768 (min negative)
        dut.reg_file.registers[6] = 16'h7FFF;  // R6 = 32767 (max positive)
        dut.reg_file.registers[7] = 16'hAAAA;  // R7 = 0xAAAA (alternating 1s)
        dut.reg_file.registers[8] = 16'h5555;  // R8 = 0x5555 (alternating 0s)
        
        // Test sequence with edge cases
        $display("Starting instruction tests...");
        
        // Test NOP
        $display("Testing NOP instruction...");
        load_instruction_with_nops(22'b0000000000000000000000, inst_index);  // NOP
        inst_index = inst_index + NOP_COUNT + 1;
        #(PIPELINE_DELAY + NOP_DELAY);  // Wait for pipeline + NOPs
        verify_reg(5'b00001, 16'h1234);  // Verify R1 unchanged
        
        // Test ADD with various cases
        $display("Testing ADD instruction with various cases...");
        load_instruction_with_nops(22'b0000100010000100000000, inst_index);  // ADD R1, R2, R4 (normal)
        inst_index = inst_index + NOP_COUNT + 1;
        #(PIPELINE_DELAY + NOP_DELAY);  // Wait for pipeline + NOPs
        verify_reg(5'b00001, 16'h690C);  // Check R1 = R2 + R4
        
        load_instruction_with_nops(22'b0000100101000110000000, inst_index);  // ADD R2, R5, R6 (overflow)
        inst_index = inst_index + NOP_COUNT + 1;
        #(PIPELINE_DELAY + NOP_DELAY);  // Wait for pipeline + NOPs
        verify_reg(5'b00010, 16'hFFFF);  // Check R2 = R5 + R6 (overflow)
        
        // Test SUB with various cases
        $display("Testing SUB instruction with various cases...");
        load_instruction_with_nops(22'b0010000101000100000000, inst_index);  // SUB R1, R2, R4 (normal)
        inst_index = inst_index + NOP_COUNT + 1;
        #(PIPELINE_DELAY + NOP_DELAY);  // Wait for pipeline + NOPs
        verify_reg(5'b00001, 16'h690B);  // Check R1 = R2 - R4 - 1
        
        load_instruction_with_nops(22'b0010001001000110000000, inst_index);  // SUB R2, R5, R6 (underflow)
        inst_index = inst_index + NOP_COUNT + 1;
        #(PIPELINE_DELAY + NOP_DELAY);  // Wait for pipeline + NOPs
        verify_reg(5'b00010, 16'h0000);  // Check R2 = R5 - R6 - 1 (underflow)
        
        // Test SLT with various cases
        $display("Testing SLT instruction with various cases...");
        load_instruction_with_nops(22'b0010100101000110000000, inst_index);  // SLT R2, R5, R6 (negative < positive)
        inst_index = inst_index + NOP_COUNT + 1;
        #(PIPELINE_DELAY + NOP_DELAY);  // Wait for pipeline + NOPs
        verify_reg(5'b00010, 16'h0001);  // Check R2 = 1 (R5 < R6)
        
        load_instruction_with_nops(22'b0010100111001000000000, inst_index);  // SLT R3, R6, R5 (positive > negative)
        inst_index = inst_index + NOP_COUNT + 1;
        #(PIPELINE_DELAY + NOP_DELAY);  // Wait for pipeline + NOPs
        verify_reg(5'b00011, 16'h0000);  // Check R3 = 0 (R6 > R5)
        
        // Test AND with various cases
        $display("Testing AND instruction with various cases...");
        load_instruction_with_nops(22'b0011000101001000000000, inst_index);  // AND R1, R2, R8 (with alternating 0s)
        inst_index = inst_index + NOP_COUNT + 1;
        #(PIPELINE_DELAY + NOP_DELAY);  // Wait for pipeline + NOPs
        verify_reg(5'b00001, 16'h0000);  // Check R1 = R2 & R8
        
        load_instruction_with_nops(22'b0011000111001110000000, inst_index);  // AND R3, R7, R8 (with alternating 1s)
        inst_index = inst_index + NOP_COUNT + 1;
        #(PIPELINE_DELAY + NOP_DELAY);  // Wait for pipeline + NOPs
        verify_reg(5'b00011, 16'h0000);  // Check R3 = R7 & R8
        
        // Test OR with various cases
        $display("Testing OR instruction with various cases...");
        load_instruction_with_nops(22'b0011100101001000000000, inst_index);  // OR R1, R2, R8 (with alternating 0s)
        inst_index = inst_index + NOP_COUNT + 1;
        #(PIPELINE_DELAY + NOP_DELAY);  // Wait for pipeline + NOPs
        verify_reg(5'b00001, 16'hFFFF);  // Check R1 = R2 | R8
        
        load_instruction_with_nops(22'b0011100111001110000000, inst_index);  // OR R3, R7, R8 (with alternating 1s)
        inst_index = inst_index + NOP_COUNT + 1;
        #(PIPELINE_DELAY + NOP_DELAY);  // Wait for pipeline + NOPs
        verify_reg(5'b00011, 16'hFFFF);  // Check R3 = R7 | R8
        
        // Test XOR with various cases
        $display("Testing XOR instruction with various cases...");
        load_instruction_with_nops(22'b0100000101001000000000, inst_index);  // XOR R1, R2, R8 (with alternating 0s)
        inst_index = inst_index + NOP_COUNT + 1;
        #(PIPELINE_DELAY + NOP_DELAY);  // Wait for pipeline + NOPs
        verify_reg(5'b00001, 16'hFFFF);  // Check R1 = R2 ^ R8
        
        load_instruction_with_nops(22'b0100000111001110000000, inst_index);  // XOR R3, R7, R8 (with alternating 1s)
        inst_index = inst_index + NOP_COUNT + 1;
        #(PIPELINE_DELAY + NOP_DELAY);  // Wait for pipeline + NOPs
        verify_reg(5'b00011, 16'hFFFF);  // Check R3 = R7 ^ R8
        
        // Test ST and LD with various addresses
        $display("Testing ST and LD instructions with various addresses...");
        load_instruction_with_nops(22'b0000000101000100000000, inst_index);  // ST [R1], R2
        inst_index = inst_index + NOP_COUNT + 1;
        #(PIPELINE_DELAY + NOP_DELAY);  // Wait for pipeline + NOPs
        verify_mem(16'hFFFF, 16'hFFFF);  // Check memory at R1's address
        
        load_instruction_with_nops(22'b0100100100000000000000, inst_index);  // LD R9, [R1]
        inst_index = inst_index + NOP_COUNT + 1;
        #(PIPELINE_DELAY + NOP_DELAY);  // Wait for pipeline + NOPs
        verify_reg(5'b01001, 16'hFFFF);  // Check R9 loaded from memory
        
        // Test immediate operations with various values
        $display("Testing immediate operations with various values...");
        load_instruction_with_nops(22'b0101000100000000000001, inst_index);  // ADI R10, R1, #1
        inst_index = inst_index + NOP_COUNT + 1;
        #(PIPELINE_DELAY + NOP_DELAY);  // Wait for pipeline + NOPs
        verify_reg(5'b01010, 16'h0000);  // Check R10 = R1 + 1 (overflow)
        
        load_instruction_with_nops(22'b0101100100000000000001, inst_index);  // SBI R11, R1, #1
        inst_index = inst_index + NOP_COUNT + 1;
        #(PIPELINE_DELAY + NOP_DELAY);  // Wait for pipeline + NOPs
        verify_reg(5'b01011, 16'hFFFE);  // Check R11 = R1 - 1 - 1
        
        // Test NOT with various inputs
        $display("Testing NOT instruction with various inputs...");
        load_instruction_with_nops(22'b0110000100000000000000, inst_index);  // NOT R12, R1
        inst_index = inst_index + NOP_COUNT + 1;
        #(PIPELINE_DELAY + NOP_DELAY);  // Wait for pipeline + NOPs
        verify_reg(5'b01100, 16'h0000);  // Check R12 = ~R1
        
        // Test immediate logical operations
        $display("Testing immediate logical operations...");
        load_instruction_with_nops(22'b011010010000000011110000, inst_index);  // ANI R13, R1, #0xF0
        inst_index = inst_index + NOP_COUNT + 1;
        #(PIPELINE_DELAY + NOP_DELAY);  // Wait for pipeline + NOPs
        verify_reg(5'b01101, 16'h00F0);  // Check R13 = R1 & 0xF0
        
        load_instruction_with_nops(22'b011100010000000000001111, inst_index);  // ORI R14, R1, #0x0F
        inst_index = inst_index + NOP_COUNT + 1;
        #(PIPELINE_DELAY + NOP_DELAY);  // Wait for pipeline + NOPs
        verify_reg(5'b01110, 16'hFFFF);  // Check R14 = R1 | 0x0F
        
        load_instruction_with_nops(22'b011110010000000011111111, inst_index);  // XRI R15, R1, #0xFF
        inst_index = inst_index + NOP_COUNT + 1;
        #(PIPELINE_DELAY + NOP_DELAY);  // Wait for pipeline + NOPs
        verify_reg(5'b01111, 16'hFF00);  // Check R15 = R1 ^ 0xFF
        
        // Test unsigned immediate operations
        $display("Testing unsigned immediate operations...");
        load_instruction_with_nops(22'b100000010000000100000000, inst_index);  // AIU R16, R1, #0x100
        inst_index = inst_index + NOP_COUNT + 1;
        #(PIPELINE_DELAY + NOP_DELAY);  // Wait for pipeline + NOPs
        verify_reg(5'b10000, 16'h0134);  // Check R16 = R1 + 0x100
        
        load_instruction_with_nops(22'b100010010000000100000000, inst_index);  // SIU R17, R1, #0x100
        inst_index = inst_index + NOP_COUNT + 1;
        #(PIPELINE_DELAY + NOP_DELAY);  // Wait for pipeline + NOPs
        verify_reg(5'b10001, 16'h0133);  // Check R17 = R1 - 0x100 - 1
        
        // Test MOV with various sources
        $display("Testing MOV instruction with various sources...");
        load_instruction_with_nops(22'b1001000100000000000000, inst_index);  // MOV R18, R1
        inst_index = inst_index + NOP_COUNT + 1;
        #(PIPELINE_DELAY + NOP_DELAY);  // Wait for pipeline + NOPs
        verify_reg(5'b10010, 16'hFFFF);  // Check R18 = R1
        
        // Test shift operations with various amounts
        $display("Testing shift operations with various amounts...");
        load_instruction_with_nops(22'b1001100100000000000010, inst_index);  // LSL R19, R1, #2
        inst_index = inst_index + NOP_COUNT + 1;
        #(PIPELINE_DELAY + NOP_DELAY);  // Wait for pipeline + NOPs
        verify_reg(5'b10011, 16'hFFFC);  // Check R19 = R1 << 2
        
        load_instruction_with_nops(22'b1010000100000000000001, inst_index);  // LSR R20, R1, #1
        inst_index = inst_index + NOP_COUNT + 1;
        #(PIPELINE_DELAY + NOP_DELAY);  // Wait for pipeline + NOPs
        verify_reg(5'b10100, 16'h7FFF);  // Check R20 = R1 >> 1
        
        // Test branch and jump operations with various conditions
        $display("Testing branch and jump operations with various conditions...");
        
        // Test BZ with zero and non-zero conditions
        dut.reg_file.registers[1] = 16'h0000;  // Set R1 to zero
        load_instruction_with_nops(22'b1011000100000000001010, inst_index);  // BZ R1, #10
        inst_index = inst_index + NOP_COUNT + 1;
        #(PIPELINE_DELAY + NOP_DELAY);  // Wait for pipeline + NOPs
        if (PC !== (PC + 10))
            $display("ERROR: BZ failed with zero condition - PC = %h", PC);
        else
            $display("PASS: BZ successful with zero condition");
            
        dut.reg_file.registers[1] = 16'h1234;  // Set R1 to non-zero
        load_instruction_with_nops(22'b1011000100000000001010, inst_index);  // BZ R1, #10
        inst_index = inst_index + NOP_COUNT + 1;
        #(PIPELINE_DELAY + NOP_DELAY);  // Wait for pipeline + NOPs
        if (PC === (PC + 10))
            $display("ERROR: BZ failed with non-zero condition - PC = %h", PC);
        else
            $display("PASS: BZ successful with non-zero condition");
            
        // Test BNZ with zero and non-zero conditions
        dut.reg_file.registers[1] = 16'h0000;  // Set R1 to zero
        load_instruction_with_nops(22'b1011100100000000010100, inst_index);  // BNZ R1, #20
        inst_index = inst_index + NOP_COUNT + 1;
        #(PIPELINE_DELAY + NOP_DELAY);  // Wait for pipeline + NOPs
        if (PC === (PC + 20))
            $display("ERROR: BNZ failed with zero condition - PC = %h", PC);
        else
            $display("PASS: BNZ successful with zero condition");
            
        dut.reg_file.registers[1] = 16'h1234;  // Set R1 to non-zero
        load_instruction_with_nops(22'b1011100100000000010100, inst_index);  // BNZ R1, #20
        inst_index = inst_index + NOP_COUNT + 1;
        #(PIPELINE_DELAY + NOP_DELAY);  // Wait for pipeline + NOPs
        if (PC !== (PC + 20))
            $display("ERROR: BNZ failed with non-zero condition - PC = %h", PC);
        else
            $display("PASS: BNZ successful with non-zero condition");
            
        // Test JMP and JML with various offsets
        load_instruction_with_nops(22'b11000000000001100100, inst_index);  // JMP #100
        inst_index = inst_index + NOP_COUNT + 1;
        #(PIPELINE_DELAY + NOP_DELAY);  // Wait for pipeline + NOPs
        if (PC !== (PC + 100))
            $display("ERROR: JMP failed - PC = %h", PC);
        else
            $display("PASS: JMP successful");
            
        load_instruction_with_nops(22'b11001000000011001000, inst_index);  // JML #200
        inst_index = inst_index + NOP_COUNT + 1;
        #(PIPELINE_DELAY + NOP_DELAY);  // Wait for pipeline + NOPs
        if (PC !== (PC + 200))
            $display("ERROR: JML failed - PC = %h", PC);
        else
            $display("PASS: JML successful");

        // End simulation
        $display("All tests completed!");
        #(CLK_PERIOD * 2);  // Wait 2 clock cycles before ending
        $finish;
    end

    // Monitor changes
    always @(posedge clk) begin
        $display("Time=%0t PC=%h A_data=%h B_data=%h ALU_result=%h Z=%b V=%b N=%b C=%b",
                 $time, PC, A_data, B_data, ALU_result, Z, V, N, C);
    end

    // Task to verify register contents
    task verify_reg;
        input [4:0] reg_addr;
        input [15:0] expected_value;
        begin
            if (dut.reg_file.registers[reg_addr] !== expected_value)
                $display("ERROR: Register %h contains %h, expected %h",
                        reg_addr, dut.reg_file.registers[reg_addr], expected_value);
            else
                $display("PASS: Register %h contains expected value %h",
                        reg_addr, expected_value);
        end
    endtask

    // Task to verify memory contents
    task verify_mem;
        input [15:0] addr;
        input [15:0] expected_value;
        begin
            if (dut.data_mem.memory[addr] !== expected_value)
                $display("ERROR: Memory[%h] contains %h, expected %h",
                        addr, dut.data_mem.memory[addr], expected_value);
            else
                $display("PASS: Memory[%h] contains expected value %h",
                        addr, expected_value);
        end
    endtask

endmodule 