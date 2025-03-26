`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   11:21:21 08/29/2018
// Design Name:   B100_build_from_gates
// Module Name:   C:/Users/bnutter/Desktop/DT Docs/xilinx/simple_examples/B100_build_from_gates_tb.v
// Project Name:  simple_examples
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: B100_build_from_gates
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module B110_build_from_gates_tb;

	// Inputs
	reg Ebar;
	reg A0;
	reg A1;

	// Outputs
	wire D0bar;
	wire D1bar;
	wire D2bar;
	wire D3bar;

	// Instantiate the Unit Under Test (UUT)
	build_from_gates uut (
		.Ebar(Ebar), 
		.A0(A0), 
		.A1(A1), 
		.D0bar(D0bar), 
		.D1bar(D1bar), 
		.D2bar(D2bar), 
		.D3bar(D3bar)
	);

   integer i;

	initial begin
		// Initialize Inputs
		// Wait 100 ns for global reset to finish
		#100;
        
		for(i=0; i<8; i = i + 1)
		  begin
		    {Ebar, A1, A0} = i;
			 #10;
		  end
		// Add stimulus here

	end
      
endmodule

