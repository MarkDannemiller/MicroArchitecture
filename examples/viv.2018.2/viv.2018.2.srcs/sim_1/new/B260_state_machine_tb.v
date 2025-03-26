`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   17:33:36 08/30/2018
// Design Name:   B200_state_machine
// Module Name:   C:/Users/bnutter/Desktop/DT Docs/xilinx/simple_examples/B200_state_machine_tb.v
// Project Name:  simple_examples
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: B200_state_machine
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module B260_state_machine_tb;

	// Inputs
	reg clk;
	reg reset;
	reg signal1;
	reg signal2;

	// Outputs
	wire actuator1;
	wire actuator2;

	// Instantiate the Unit Under Test (UUT)
	state_machine uut (
		.clk(clk), 
		.reset(reset), 
		.signal1(signal1), 
		.signal2(signal2), 
		.actuator1(actuator1), 
		.actuator2(actuator2)
	);

	initial begin
		// Initialize Inputs
		clk = 0;
		reset = 0;
		signal1 = 0;
		signal2 = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		signal1 = 1;
		#50;
		signal1 = 0;
		#50;
		signal2 = 1;
		#50;
		signal2 = 0;
	end
   
	always
		#5 clk = ~clk;
endmodule

