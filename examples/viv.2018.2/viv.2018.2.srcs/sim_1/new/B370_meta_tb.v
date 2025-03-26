`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   18:00:23 03/10/2018
// Design Name:   meta
// Module Name:   C:/Users/bnutter/Desktop/DT Docs/xilinx/asynchronous_money/meta_tb.v
// Project Name:  asynchronous_money
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: meta
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module B370_meta_tb;

	// Inputs
	reg async;
	reg clock;

	// Outputs
	wire sync;

	// Instantiate the Unit Under Test (UUT)
	meta uut (
		.async(async), 
		.clock(clock), 
		.sync(sync)
	);

	initial begin
		// Initialize Inputs
		async = 0;
		clock = 0;

		// Wait 100 ns for global reset to finish
		#100;
       
		// Add stimulus here

	end
	
	
	always
		begin
			#5 clock = ~clock;			// 10 tick clock
      end

	always
		begin
			#21 async = ~async;			// 22 tick input from outside. Will be 2 or 3 clock ticks each
      end
		
endmodule

