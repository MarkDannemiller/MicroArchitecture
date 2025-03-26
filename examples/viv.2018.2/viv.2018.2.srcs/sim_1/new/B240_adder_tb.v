`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   15:20:01 08/30/2018
// Design Name:   B190_adder
// Module Name:   C:/Users/bnutter/Desktop/DT Docs/xilinx/simple_examples/B190_adder_tb.v
// Project Name:  simple_examples
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: B190_adder
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module B240_adder_tb;

	// Inputs
	reg [7:0] A;
	reg [7:0] B;
	reg CIN;

	// Outputs
	wire [7:0] SUM;
	wire COUT;

	// Instantiate the Unit Under Test (UUT)
	adder uut (
		.A(A), 
		.B(B), 
		.CIN(CIN), 
		.SUM(SUM), 
		.COUT(COUT)
	);

	initial begin
		// Initialize Inputs
		A = 0;
		B = 0;
		CIN = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
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

	end
      
endmodule

