`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   19:27:57 03/18/2018
// Design Name:   incs
// Module Name:   C:/Users/bnutter/Desktop/DT Docs/xilinx/asynchronous_money/M080_headers_tb.v
// Project Name:  asynchronous_money
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: incs
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module B390_headers_tb; 

`include "PATT.INC"			// lots of parameters 

	// Inputs
	reg [2:0] A; 

	// Outputs 
	wire [7:0] B;
	
	wire match;
	integer i=0;  
	
	assign match = (B == PATT3) ? 1'bx : 0;		// this is the interesting use case here - PATT comes from marco in header

	// Instantiate the Unit Under Test (UUT)
	incs uut (
		.A(A), 
		.B(B)
	);

	initial begin
		// Initialize Inputs
		A = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		for(i = 0; i < 8; i = i + 1)
			begin
				#10 A = i;
			end
	end
      
endmodule

