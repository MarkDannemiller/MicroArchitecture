`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   13:25:28 08/29/2018
// Design Name:   B110_vectors
// Module Name:   C:/Users/bnutter/Desktop/DT Docs/xilinx/simple_examples/B110_gates_vectors_tb.v
// Project Name:  simple_examples
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: B110_vectors
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module B120_gates_vectors_tb;

	// Inputs
	reg [1:0] S;
	reg [3:0] D;

	// Outputs
	wire Y1;

	// Instantiate the Unit Under Test (UUT)
	vectors uut (
		.S(S), 
		.D(D), 
		.Y1(Y1)
	);
	
	integer i;

	initial begin
		// Initialize Inputs
		

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		for(i=0; i<64; i=i+1)
			begin
				{S,D} = i;
				#10;
			end
	end
      
endmodule

