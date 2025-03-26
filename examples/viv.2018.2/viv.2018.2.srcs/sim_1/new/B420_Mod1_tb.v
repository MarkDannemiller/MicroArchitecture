`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   20:58:16 03/18/2018
// Design Name:   mod1
// Module Name:   C:/Users/bnutter/Desktop/DT Docs/xilinx/asynchronous_money/M100_Mod1_tb.v
// Project Name:  asynchronous_money
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: mod1
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module B420_Mod1_tb;

	// Inputs
	reg clock;
	reg reset;
	reg go;

	// Outputs
	wire done;

	// Instantiate the Unit Under Test (UUT)
	mod1 uut (
		.clock(clock), 
		.reset(reset), 
		.go(go), 
		.done(done)
	);

	initial begin
		// Initialize Inputs
		clock = 0;
		reset = 0;
		go = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		reset = 1;
		#10 reset = 0;
		#100 go = 1;
		#10 go = 0;

	end
      
	always
		#5 clock = ~clock;
	
endmodule

