`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   08:34:11 08/31/2018
// Design Name:   shift_reg
// Module Name:   C:/Users/bnutter/Desktop/DT Docs/xilinx/simple_examples/B208_shift_reg_tb.v
// Project Name:  simple_examples
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: shift_reg
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module B280_shift_reg_tb;

	// Inputs
	reg clk;
	reg reset;
	reg SI;
	reg load;

	// Outputs
	wire [7:0] value;
	wire SO;

	// Instantiate the Unit Under Test (UUT)
	shift_reg uut (
		.clk(clk), 
		.reset(reset), 
		.SI(SI), 
		.load(load), 
		.value(value), 
		.SO(SO)
	);

	initial begin
		// Initialize Inputs
		clk = 0;
		reset = 0;
		SI = 1;
		load = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		reset = 1;
		#10;
		reset = 0;
		#10;
		load = 1;
		#50;
		SI = 0;
		#50;
		SI = 1;
		#10
		SI = 0;
	end
      
	always
		#5 clk = ~clk;
endmodule

