`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   17:43:38 03/10/2018
// Design Name:   posnotedge
// Module Name:   C:/Users/bnutter/Desktop/DT Docs/xilinx/asynchronous_money/edge_tb.v
// Project Name:  asynchronous_money
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: posnotedge
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module B380_edge_tb;

	// Inputs
	reg signal;
	reg clock;

	// Outputs
	wire edgeplus;
	wire edgeminus;

	// Instantiate the Unit Under Test (UUT)
	posnotedge uut (
		.signal(signal), 
		.clock(clock), 
		.edgeplus(edgeplus), 
		.edgeminus(edgeminus)
	);

	initial begin
		// Initialize Inputs
		signal = 0;
		clock = 0;

		// Wait 100 ns for global reset to finish
		#100;
		// Add stimulus here

		signal = 1;
		#100
		signal = 0;
        

	end
      
	always
	#5 clock = ~clock;
endmodule

