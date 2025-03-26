`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   20:18:15 03/18/2018
// Design Name:   states
// Module Name:   C:/Users/bnutter/Desktop/DT Docs/xilinx/asynchronous_money/M090_state_machine.v
// Project Name:  asynchronous_money
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: states
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module B400_state_machine_tb;

	// Inputs
	reg clock;
	reg reset;
	reg in1;
	reg in2;

	// Outputs
	wire out1;
	wire out2;

	// Instantiate the Unit Under Test (UUT)
	states uut (
		.clock(clock), 
		.reset(reset), 
		.in1(in1), 
		.in2(in2), 
		.out1(out1), 
		.out2(out2)
	);

	initial begin
		// Initialize Inputs
		clock = 0;
		reset = 0;
		in1 = 0;
		in2 = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		reset = 1;
		in1 = 1;
		in2 = 1;
		#100;
		reset = 0;
		#50;
		in2 = 0;
		#50
		in1 = 0;
		in2 = 1;
		#50
		in2 = 0;
		#100
		in2 = 1;
	end
   
	always
		#5 clock = ~clock;
endmodule

