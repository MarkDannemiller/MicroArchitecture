`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   14:46:58 08/30/2018
// Design Name:   B160_half_adder
// Module Name:   C:/Users/bnutter/Desktop/DT Docs/xilinx/simple_examples/B160_hlaf_adder_tb.v
// Project Name:  simple_examples
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: B160_half_adder
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module B210_half_adder_tb;

	// Inputs
	reg A;
	reg B;

	// Outputs
	wire sum;
	wire carry;

	// Instantiate the Unit Under Test (UUT)
	half_adder uut (
		.A(A), 
		.B(B), 
		.sum(sum), 
		.carry(carry)
	);
	
	integer i;

	initial begin
		// Initialize Inputs

		// Wait 100 ns for global reset to finish
		#100;
        
		for(i=0; i<4; i = i + 1)
			begin
				{A,B} = i;
				#10;
			end
		// Add stimulus here

	end
      
endmodule

