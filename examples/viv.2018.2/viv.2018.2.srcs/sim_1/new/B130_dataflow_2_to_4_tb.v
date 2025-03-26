`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   14:11:21 08/30/2018
// Design Name:   B120_dataflow
// Module Name:   C:/Users/bnutter/Desktop/DT Docs/xilinx/simple_examples/B120_dataflow_2_to_4.v
// Project Name:  simple_examples
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: B120_dataflow
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module B130_dataflow_2_to_4_tb;

	// Inputs
	reg Ebar;
	reg [1:0] A;

	// Outputs
	wire [3:0] Dbar;

	// Instantiate the Unit Under Test (UUT)
	dataflow uut (
		.Ebar(Ebar), 
		.A(A), 
		.Dbar(Dbar)
	);

	integer i;

	initial begin
		// Initialize Inputs
		Ebar = 0;
		A = 0;

		// Wait 100 ns for global reset to finish
		#100;
      for(i=0; i<8; i = i+1)
			begin
				{Ebar, A} = i;
				#10;
			end
		// Add stimulus here

	end
      
endmodule

