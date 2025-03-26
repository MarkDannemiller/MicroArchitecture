`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   18:31:41 03/18/2018
// Design Name:   casexample
// Module Name:   C:/Users/bnutter/Desktop/DT Docs/xilinx/asynchronous_money/casexample_tb.v
// Project Name:  asynchronous_money
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: casexample
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module B350_casexample_tb;

	// Inputs
	reg [2:0] A;

	// Outputs
	wire [1:0] B1;
	wire [1:0] B2;
	
	wire differ;
	
	assign differ = (B1 != B2);		// highlighjt differences
	
	integer i=0;

	// Instantiate the Unit Under Test (UUT)
	casexample uut (
		.A(A), 
		.B1(B1), 
		.B2(B2)
	);

	initial begin
		// Initialize Inputs
		A = 0;

		// Wait 100 ns for global reset to finish
		#100;
		// Add stimulus here
        
		for(i = 0; i < 8; i = i + 1)
			#10 A = i;

	end
      
endmodule

