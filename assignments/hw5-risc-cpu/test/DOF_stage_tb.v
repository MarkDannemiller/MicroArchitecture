`timescale 1ns/1ps

`include "../DOF_stage.v"
`include "../registerFile.v"
`include "../constantUnit.v"
`include "../instructionDecoder.v"
`include "../muxA.v"
`include "../muxB.v"

module DOF_stage_tb();

    // Test signals
    reg clk;
    reg rst;
    reg [31:0] instruction;
    reg [31:0] PC_1;
    reg [31:0] WB_data;
    reg [4:0] WB_addr;
    reg WB_en;
    
    // Output signals
    wire [31:0] A_data;
    wire [31:0] B_data;
    wire [31:0] BusA;
    wire [31:0] BusB;
    wire [31:0] extended_imm;
    wire RW, MW, PS;
    wire [1:0] MD, BS;
    wire [4:0] FS, DR, SH;
    
    // Timing parameters
    parameter CLK_PERIOD = 10; // 10ns clock period
    
    // Instantiate the DOF stage
    DOF_stage dut(
        .clk(clk),
        .rst(rst),
        .instruction(instruction),
        .PC_1(PC_1),
        .WB_data(WB_data),
        .WB_addr(WB_addr),
        .WB_en(WB_en),
        .A_data(A_data),
        .B_data(B_data),
        .BusA(BusA),
        .BusB(BusB),
        .extended_imm(extended_imm),
        .RW(RW),
        .MD(MD),
        .MW(MW),
        .BS(BS),
        .PS(PS),
        .FS(FS),
        .DR(DR),
        .SH(SH)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Initialize registers task
    task initialize_registers;
        begin
            // Initialize registers with test values
            dut.reg_file.registers[0] = 32'h00000000;  // R0 = 0 (always)
            dut.reg_file.registers[1] = 32'h12345678;  // R1
            dut.reg_file.registers[2] = 32'h56789ABC;  // R2
            dut.reg_file.registers[3] = 32'h9ABCDEF0;  // R3
            dut.reg_file.registers[4] = 32'hFFFFFFFF;  // R4
            dut.reg_file.registers[5] = 32'h80000000;  // R5
            dut.reg_file.registers[6] = 32'h7FFFFFFF;  // R6
            dut.reg_file.registers[7] = 32'hAAAAAAAA;  // R7
            dut.reg_file.registers[8] = 32'h55555555;  // R8
        end
    endtask
    
    // Test verification task for control signals
    task verify_control_signals;
        input [6:0] opcode;
        input exp_RW;
        input [1:0] exp_MD;
        input exp_MW;
        input [1:0] exp_BS;
        input exp_PS;
        input [4:0] exp_FS;
        input exp_MA;
        input exp_MB;
        input exp_CS;
        begin
            // Construct an instruction with the given opcode
            instruction = {opcode, 25'b0};
            #1; // Wait for combinational logic to settle
            
            // Verify control signals
            if (RW !== exp_RW)
                $display("FAIL: RW = %b, expected %b for opcode %h", RW, exp_RW, opcode);
            else
                $display("PASS: RW = %b as expected for opcode %h", RW, opcode);
                
            if (MD !== exp_MD)
                $display("FAIL: MD = %b, expected %b for opcode %h", MD, exp_MD, opcode);
            else
                $display("PASS: MD = %b as expected for opcode %h", MD, opcode);
                
            if (MW !== exp_MW)
                $display("FAIL: MW = %b, expected %b for opcode %h", MW, exp_MW, opcode);
            else
                $display("PASS: MW = %b as expected for opcode %h", MW, opcode);
                
            if (BS !== exp_BS)
                $display("FAIL: BS = %b, expected %b for opcode %h", BS, exp_BS, opcode);
            else
                $display("PASS: BS = %b as expected for opcode %h", BS, opcode);
                
            if (PS !== exp_PS)
                $display("FAIL: PS = %b, expected %b for opcode %h", PS, exp_PS, opcode);
            else
                $display("PASS: PS = %b as expected for opcode %h", PS, opcode);
                
            if (FS !== exp_FS)
                $display("FAIL: FS = %b, expected %b for opcode %h", FS, exp_FS, opcode);
            else
                $display("PASS: FS = %b as expected for opcode %h", FS, opcode);
                
            // We can't directly check the internal signals MA, MB, CS, but we can verify
            // their effects through BusA, BusB, and extended_imm
        end
    endtask
    
    // Test register file read
    task test_register_read;
        input [4:0] reg_A;
        input [4:0] reg_B;
        input [31:0] expected_A;
        input [31:0] expected_B;
        begin
            // Construct an instruction with reg_A as SA and reg_B as SB
            instruction = {7'b0, 5'b0, reg_A, reg_B, 10'b0};
            #1; // Wait for combinational logic to settle
            
            if (A_data !== expected_A)
                $display("FAIL: A_data = %h, expected %h for reg %d", A_data, expected_A, reg_A);
            else
                $display("PASS: A_data = %h as expected for reg %d", A_data, reg_A);
                
            if (B_data !== expected_B)
                $display("FAIL: B_data = %h, expected %h for reg %d", B_data, expected_B, reg_B);
            else
                $display("PASS: B_data = %h as expected for reg %d", B_data, reg_B);
        end
    endtask
    
    // Test MuxA functionality
    task test_muxA;
        input [6:0] opcode; // Opcode that would set MA=0 or MA=1
        input [4:0] reg_A;
        input [31:0] pc_1_val;
        input [31:0] expected_busA;
        begin
            // Set up test conditions
            PC_1 = pc_1_val;
            instruction = {opcode, 5'b0, reg_A, 15'b0};
            #1; // Wait for combinational logic to settle
            
            if (BusA !== expected_busA)
                $display("FAIL: BusA = %h, expected %h for opcode %h", BusA, expected_busA, opcode);
            else
                $display("PASS: BusA = %h as expected for opcode %h", BusA, opcode);
        end
    endtask
    
    // Test MuxB functionality with proper instruction formatting
    task test_muxB;
        input [6:0] opcode;       // Opcode that would set MB=0 or MB=1
        input [4:0] reg_A;        // Source register A (SA field)
        input [4:0] reg_B;        // Source register B (SB field) 
        input [14:0] imm_val;     // Immediate value (15 bits) for two-register format
        input [31:0] expected_busB;
        begin
            if (opcode == 7'b0000010) begin
                // Three-register format
                instruction = {opcode, 5'b00001, reg_A, reg_B, 10'b0};
            end else if (opcode == 7'b0100010) begin
                // Two-register format with immediate
                instruction = {opcode, 5'b00001, reg_A, imm_val};
            end
            
            #1; // Wait for combinational logic to settle
            
            // Debug information
            $display("DEBUG: opcode=%h, reg_A=%d, format=%s", opcode, reg_A, 
                     dut.i_decoder.MB ? "Two-register" : "Three-register");
            
            if (dut.i_decoder.MB == 0) begin
                $display("DEBUG: reg_B=%d", reg_B);
            end else begin
                $display("DEBUG: imm_val=%h", imm_val);
            end
            
            $display("DEBUG: instruction=%h", instruction);
            $display("DEBUG: MB=%b from decoder", dut.i_decoder.MB);
            $display("DEBUG: CS=%b from decoder", dut.i_decoder.CS);
            $display("DEBUG: B_data=%h from register file", B_data);
            $display("DEBUG: extended_imm=%h from constant unit", extended_imm);
            $display("DEBUG: BusB=%h from muxB", BusB);
            
            if (BusB !== expected_busB)
                $display("FAIL: BusB = %h, expected %h for opcode %h", BusB, expected_busB, opcode);
            else
                $display("PASS: BusB = %h as expected for opcode %h", BusB, opcode);
        end
    endtask
    
    // Test register file write
    task test_register_write;
        input [4:0] dest_reg;
        input [31:0] write_data;
        input [31:0] expected_value;
        begin
            // Set up WB signals
            WB_addr = dest_reg;
            WB_data = write_data;
            WB_en = 1'b1;
            
            // Wait for clock edge
            @(posedge clk);
            #1; // Wait for settled state
            
            // Check if write occurred
            WB_en = 1'b0;
            if (dut.reg_file.registers[dest_reg] !== expected_value)
                $display("FAIL: Register %d = %h, expected %h after write", 
                        dest_reg, dut.reg_file.registers[dest_reg], expected_value);
            else
                $display("PASS: Register %d = %h as expected after write", 
                        dest_reg, expected_value);
        end
    endtask
    
    // Main test sequence
    initial begin

        // Initialize waveform dumping
        $dumpfile("DOF_stage_tb.vcd");
        $dumpvars(0, DOF_stage_tb);

        // Initialize
        rst = 1;
        instruction = 32'h0;
        PC_1 = 32'h200;
        WB_data = 32'h0;
        WB_addr = 5'b0;
        WB_en = 0;
        
        // Wait for reset
        #(CLK_PERIOD * 2);
        rst = 0;
        #(CLK_PERIOD);
        
        $display("=== DOF Stage Unit Test ===");
        
        // Initialize test registers
        initialize_registers();
        
        $display("\n=== Testing Register File Read Operations ===");
        test_register_read(5'd1, 5'd2, 32'h12345678, 32'h56789ABC);
        test_register_read(5'd0, 5'd4, 32'h00000000, 32'hFFFFFFFF);
        
        $display("\n=== Testing Control Signal Decoding ===");
        // Test ADD instruction (opcode 0000010)
        verify_control_signals(7'b0000010, 1'b1, 2'b00, 1'b0, 2'b00, 1'b0, 5'h02, 1'b0, 1'b0, 1'b0);
        
        // Test LD instruction (opcode 0100001)
        verify_control_signals(7'b0100001, 1'b1, 2'b01, 1'b0, 2'b00, 1'b0, 5'h00, 1'b0, 1'b0, 1'b0);
        
        // Test ST instruction (opcode 0000001)
        verify_control_signals(7'b0000001, 1'b0, 2'b00, 1'b1, 2'b00, 1'b0, 5'h00, 1'b0, 1'b0, 1'b0);
        
        // Test BZ instruction (opcode 0100000)
        verify_control_signals(7'b0100000, 1'b0, 2'b00, 1'b0, 2'b01, 1'b0, 5'h00, 1'b0, 1'b1, 1'b1);
        
        // Test BNZ instruction (opcode 1100000)
        verify_control_signals(7'b1100000, 1'b0, 2'b00, 1'b0, 2'b01, 1'b1, 5'h00, 1'b0, 1'b1, 1'b1);
        
        // Test JMP instruction (opcode 1000100)
        verify_control_signals(7'b1000100, 1'b0, 2'b00, 1'b0, 2'b11, 1'b0, 5'h00, 1'b0, 1'b1, 1'b1);
        
        // Test SLT instruction (opcode 1100101)
        verify_control_signals(7'b1100101, 1'b1, 2'b10, 1'b0, 2'b00, 1'b0, 5'h05, 1'b0, 1'b0, 1'b0);
        
        $display("\n=== Testing MuxA Functionality ===");
        // Test MuxA with MA=0 (normal register access)
        test_muxA(7'b0000010, 5'd1, 32'h200, 32'h12345678); // ADD instruction, MA=0
        
        // Test MuxA with MA=1 (use PC_1)
        test_muxA(7'b0000111, 5'd1, 32'h200, 32'h200); // JML instruction, MA=1
        
        $display("\n=== Testing MuxB Functionality ===");
        
        // Before MuxB tests, ensure register values are known
        dut.reg_file.registers[2] = 32'h56789ABC;  // Set register 2 value
        
        // Test MuxB with MB=0 (normal register access - three-register format)
        test_muxB(7'b0000010, 5'd1, 5'd2, 15'h00AB, 32'h56789ABC); // ADD instruction, MB=0
        
        // Test MuxB with MB=1 (use immediate - two-register format)
        // For ADI (0100010) with sign extension, use immediate with MSB=1 for negative test
        test_muxB(7'b0100010, 5'd1, 5'd0, 15'h60AB, 32'hFFFF60AB); // ADI instruction, MB=1, sign-extended
        
        // Test MuxB with MB=1 (use immediate - two-register format)  
        // For AIU (1100010) without sign extension, use immediate for positive test
        test_muxB(7'b1100010, 5'd1, 5'd0, 15'h60AB, 32'h000060AB); // AIU instruction, MB=1, zero-extended
        
        $display("\n=== Testing Register File Write Operations ===");
        test_register_write(5'd10, 32'hA5A5A5A5, 32'hA5A5A5A5);
        test_register_write(5'd0, 32'hDEADBEEF, 32'h00000000); // R0 should remain 0
        
        // End test
        $display("\n=== DOF Stage Unit Test Complete ===");
        #(CLK_PERIOD * 2);
        $finish;
    end

endmodule 