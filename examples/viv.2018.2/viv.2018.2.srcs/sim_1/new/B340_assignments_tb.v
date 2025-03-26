`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   19:01:41 03/18/2018
// Design Name:   assignments
// Module Name:   C:/Users/bnutter/Desktop/DT Docs/xilinx/asynchronous_money/assignments_tb.v
// Project Name:  asynchronous_money
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: assignments
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module B340_assignments_tb;

	// Inputs
	reg [1:0] control;
	reg [7:0] D1;
	reg [7:0] D2;

	// Outputs
	wire [7:0] result1;
	wire [7:0] result2;
	
	wire diff;
	assign diff = (result1 == result2) ? 0 : 1'bx;

	// Instantiate the Unit Under Test (UUT)
	assignments uut (
		.control(control), 
		.D1(D1), 
		.D2(D2), 
		.result1(result1),
		.result2(result2)
	);

	initial begin
		// Initialize Inputs
		control = 0;
		D1 = 8'h53;
		D2 = 8'hFA;

		// Wait 100 ns for global reset to finish
		#100;
		// Add stimulus here

		#10 control = 1;
		
		#10 control = 2;
		#10 control = 3;
        
	end
      
endmodule

