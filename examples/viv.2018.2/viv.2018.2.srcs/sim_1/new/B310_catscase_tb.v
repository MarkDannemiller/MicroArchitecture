`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   13:19:21 03/09/2018
// Design Name:   catcase
// Module Name:   C:/Users/bnutter/Desktop/DT Docs/xilinx/asynchronous_money/catscase_tb.v
// Project Name:  asynchronous_money
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: catcase
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module B310_catscase_tb;

	// Inputs
	reg a;
	reg b;
	reg c;
	integer i=0;

	// Outputs
	wire [3:0] d;

	// Instantiate the Unit Under Test (UUT)
	catcase uut (
		.a(a), 
		.b(b), 
		.c(c),
		.d(d)
	);

	initial begin
		// Initialize Inputs
		a = 0;
		b = 0;
		c = 0;
		i = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		for(i = 0; i < 16; i = i + 1)
			begin
				{a,b,c} = i;
				#10;
			end
		// Add stimulus here

	end
      
endmodule

