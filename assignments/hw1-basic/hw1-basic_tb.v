`timescale 1ns / 1ps
`include "./hw1-basic.v"

//=============================================================================
// HW1 Basic Verilog
// Mark Dannemiller
//=============================================================================

module hw1_tb;

    // Inputs
    reg A;
    reg B;
    reg C;
    reg D;

    // Outputs
    wire out;

    // Instantiate the Unit Under Test (UUT)
    hw1 uut (
        .A(A), 
        .B(B), 
        .C(C),
        .D(D), 
        .out(out)
    );

    integer i;

    initial begin
        // Initialize Inputs
        $dumpfile("hw1-basic_tb.vcd");
        $dumpvars(0, hw1_tb);
        $display("Homework 1 Basic Testbench");
        
        // Wait 100 ns for global reset to finish
        #100;
        
        for(i=0; i<16; i = i + 1)
          begin
            {A,B,C,D} = i;
            #10;
          end

    end
endmodule
