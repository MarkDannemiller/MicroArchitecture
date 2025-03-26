`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   07:13:03 03/19/2018
// Design Name:   mod2
// Module Name:   C:/Users/bnutter/Desktop/DT Docs/xilinx/asynchronous_money/M101_Mod2_tb.v
// Project Name:  asynchronous_money
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: mod2
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module B430_Mod2_tb;

	// Inputs
	reg clock;
	reg reset;
	reg start;

	// Outputs
	wire finish;
	wire [1:0] pins;

	// Instantiate the Unit Under Test (UUT)
	mod2 uut (
		.clock(clock), 
		.reset(reset), 
		.start(start), 
		.finish(finish),
		.pins(pins)
	);

	initial begin
		// Initialize Inputs
		clock = 0;
		reset = 0;
		start = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		reset = 1;
		#10 reset = 0;
		#100 start = 1;
		#10 start = 0;

	end
      
	always
		#5 clock = ~clock;
      
endmodule

