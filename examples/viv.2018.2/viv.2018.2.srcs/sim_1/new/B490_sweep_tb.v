`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   19:19:47 04/01/2018
// Design Name:   sweep
// Module Name:   C:/Users/Nutter/Desktop/DT docs/simple_examples/M141_sweep.v
// Project Name:  simple_examples
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: sweep
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module B490_sweep_tb;

	// Inputs
	reg clock;
	reg reset;

	// Outputs
	wire drive;

	// Instantiate the Unit Under Test (UUT)
	sweep uut (
		.clock(clock), 
		.reset(reset), 
		.drive(drive)
	);

	initial begin
		// Initialize Inputs
		clock = 0;
		reset = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here

	end
	always
		begin
		#5 clock = ~clock;
		end
      
endmodule

