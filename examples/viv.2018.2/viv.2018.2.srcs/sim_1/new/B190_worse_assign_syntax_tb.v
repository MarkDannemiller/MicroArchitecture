`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   14:36:11 08/30/2018
// Design Name:   B150_worse_assign_syntax
// Module Name:   C:/Users/bnutter/Desktop/DT Docs/xilinx/simple_examples/B150_worse_assign_syntax_tb.v
// Project Name:  simple_examples
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: B150_worse_assign_syntax
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module B190_worse_assign_syntax_tb;

	// Inputs
	reg [1:0] S;
	reg [3:0] D;
	wire Y;

	// Instantiate the Unit Under Test (UUT) 
	worse_assign_syntax uut (
		.S(S), 
		.D(D), 
		.Y(Y)
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

