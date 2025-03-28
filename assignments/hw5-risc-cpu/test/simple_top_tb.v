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

module simple_top_tb();

    reg clk;
    reg rst;
    
    // Clock period
    parameter CLK_PERIOD = 10;

    // Instantiate the top module
    top dut(
        .clk(clk),
        .rst(rst)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Test stimulus
    initial begin
        // Initialize waveform dumping
        $dumpfile("simple_top_tb.vcd");
        $dumpvars(0, simple_top_tb);

        // Reset sequence
        rst = 1;
        #(CLK_PERIOD * 4);
        rst = 0;
        
        // Initialize registers
        dut.dof_stage.reg_file.registers[0] = 32'h00000000;
        dut.dof_stage.reg_file.registers[1] = 32'h12345678;
        dut.dof_stage.reg_file.registers[2] = 32'h56789ABC;
        
        // Load a simple instruction (ADD R3, R1, R2)
        dut.if_stage.inst_mem.memory[0] = 32'h04180000;  // ADD R3, R1, R2
        
        // Run for a few cycles
        #(CLK_PERIOD * 10);
        
        // Check result
        if (dut.dof_stage.reg_file.registers[3] === (32'h12345678 + 32'h56789ABC))
            $display("PASS: R3 = %h as expected", dut.dof_stage.reg_file.registers[3]);
        else
            $display("FAIL: R3 = %h, expected %h", 
                    dut.dof_stage.reg_file.registers[3], 
                    32'h12345678 + 32'h56789ABC);
                    
        // End simulation
        #(CLK_PERIOD * 5);
        $finish;
    end

endmodule 