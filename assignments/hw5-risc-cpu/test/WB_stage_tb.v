`timescale 1ns/1ps

`include "../WB_stage.v"
`include "../muxD.v"

module WB_stage_tb();

    // Test signals
    reg [31:0] ALU_result;
    reg [31:0] mem_data;
    reg N_xor_V;
    reg [1:0] MD;
    reg RW;
    reg [4:0] DR;
    
    // Outputs
    wire [31:0] WB_data;
    wire [4:0] WB_addr;
    wire WB_en;
    
    // Instantiate the WB stage
    WB_stage dut(
        .ALU_result(ALU_result),
        .mem_data(mem_data),
        .N_xor_V(N_xor_V),
        .MD(MD),
        .RW(RW),
        .DR(DR),
        .WB_data(WB_data),
        .WB_addr(WB_addr),
        .WB_en(WB_en)
    );
    
    // Test MD selection task
    task test_md_selection;
        input [1:0] md_val;
        input [31:0] alu_val;
        input [31:0] mem_val;
        input n_xor_v_val;
        input [31:0] expected_data;
        begin
            // Set up inputs
            ALU_result = alu_val;
            mem_data = mem_val;
            N_xor_V = n_xor_v_val;
            MD = md_val;
            
            #2; // Allow signals to propagate
            
            // Display info for debugging
            $display("Testing MD selection: MD=%b, ALU=%h, MEM=%h, N_xor_V=%b", 
                     md_val, alu_val, mem_val, n_xor_v_val);
            
            // Verify results
            if (WB_data !== expected_data)
                $display("FAIL: WB_data = %h, expected %h for MD=%b", 
                         WB_data, expected_data, md_val);
            else
                $display("PASS: WB_data = %h as expected for MD=%b", 
                         WB_data, md_val);
        end
    endtask
    
    // Test control signal propagation
    task test_control_signals;
        input rw_val;
        input [4:0] dr_val;
        begin
            // Set up inputs
            RW = rw_val;
            DR = dr_val;
            
            #2; // Allow signals to propagate
            
            // Display info for debugging
            $display("Testing control signals: RW=%b, DR=%h", rw_val, dr_val);
            
            // Verify results
            if (WB_addr !== dr_val)
                $display("FAIL: WB_addr = %h, expected %h", WB_addr, dr_val);
            else
                $display("PASS: WB_addr = %h as expected", WB_addr);
            
            if (WB_en !== rw_val)
                $display("FAIL: WB_en = %b, expected %b", WB_en, rw_val);
            else
                $display("PASS: WB_en = %b as expected", WB_en);
        end
    endtask
    
    // Main test sequence
    initial begin
        // Initialize waveform dumping
        $dumpfile("WB_stage_tb.vcd");
        $dumpvars(0, WB_stage_tb);
        
        // Initialize
        ALU_result = 32'h0;
        mem_data = 32'h0;
        N_xor_V = 1'b0;
        MD = 2'b00;
        RW = 1'b0;
        DR = 5'h0;
        
        #10; // Wait a bit
        
        $display("=== WB Stage Unit Test ===");
        
        $display("\n=== Testing MD Selection ===");
        // Test MD = 00 (select ALU_result)
        test_md_selection(2'b00, 32'hAAAAAAAA, 32'hBBBBBBBB, 1'b0, 32'hAAAAAAAA);
        
        // Test MD = 01 (select mem_data)
        test_md_selection(2'b01, 32'hAAAAAAAA, 32'hBBBBBBBB, 1'b0, 32'hBBBBBBBB);
        
        // Test MD = 10 (select N_xor_V, extended to 32 bits)
        test_md_selection(2'b10, 32'hAAAAAAAA, 32'hBBBBBBBB, 1'b0, 32'h00000000);
        test_md_selection(2'b10, 32'hAAAAAAAA, 32'hBBBBBBBB, 1'b1, 32'h00000001);
        
        $display("\n=== Testing Control Signal Propagation ===");
        // Test RW = 0, DR = 0
        test_control_signals(1'b0, 5'h00);
        
        // Test RW = 1, DR = 10
        test_control_signals(1'b1, 5'h0A);
        
        // Test RW = 1, DR = 31
        test_control_signals(1'b1, 5'h1F);
        
        // Test RW = 0, DR = 15
        test_control_signals(1'b0, 5'h0F);
        
        // End test
        $display("\n=== WB Stage Unit Test Complete ===");
        #10;
        $finish;
    end

endmodule 