`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   15:12:56 08/30/2018
// Design Name:   B180_full_adder
// Module Name:   C:/Users/bnutter/Desktop/DT Docs/xilinx/simple_examples/B180_full_adder_tb.v
// Project Name:  simple_examples
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: B180_full_adder
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module B230_full_adder_tb;

	// Inputs
	reg [7:0] A;
	reg [7:0] B;
	reg C0;

	// Outputs
	wire [7:0] S;
	wire C8;

	// Instantiate the Unit Under Test (UUT)
	full_adder1 uut (
		.A(A), 
		.B(B), 
		.C0(C0), 
		.S(S), 
		.C8(C8)
	);

	initial begin
		// Initialize Inputs
		A = 0;
		B = 0;
		C0 = 0;

		// Wait 100 ns for global reset to finish
		#100;
      A=1;
		#10;
		B=2;
		#10;
		A=4;
		#10;
		B = 8;
		#10;
		A = 127;
		#10;
		B=127;
		#10;
		A=128;
		#10;
		B=128;
		#10
		A=255;
		#10;
		B=255;
		// Add stimulus here

	end
      
endmodule

