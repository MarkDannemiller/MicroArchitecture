`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   14:56:02 08/30/2018
// Design Name:   B170_instantiate_other_modules
// Module Name:   C:/Users/bnutter/Desktop/DT Docs/xilinx/simple_examples/B170_snstantiate_other_modules_tb.v
// Project Name:  simple_examples
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: B170_instantiate_other_modules
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module B220_full_adder_tb;

	// Inputs
	reg A;
	reg B;
	reg CIN;

	// Outputs
	wire SUM;
	wire COUT;

	// Instantiate the Unit Under Test (UUT)
	full_adder uut (
		.A(A), 
		.B(B), 
		.CIN(CIN), 
		.SUM(SUM), 
		.COUT(COUT)
	);
	
	integer i;
	integer j;

	initial begin
		// Initialize Inputs
		// Wait 100 ns for global reset to finish
		#100;
		
		for(i=0; i<8; i=i+1)
			begin
				{A, B, CIN} = i;
				j = A + B + CIN;
				#10;
			end
        
		// Add stimulus here

	end
      
endmodule

