`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   08:25:13 08/31/2018
// Design Name:   counter
// Module Name:   C:/Users/bnutter/Desktop/DT Docs/xilinx/simple_examples/B205_counter_tb.v
// Project Name:  simple_examples
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: counter
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module B270_counter_tb;

	// Inputs
	reg clk;
	reg reset;
	reg count;
	reg load;
	reg [7:0] loadval;

	// Outputs
	wire [7:0] value;
	wire carry;

	// Instantiate the Unit Under Test (UUT)
	counter uut (
		.clk(clk), 
		.reset(reset), 
		.count(count), 
		.load(load), 
		.loadval(loadval), 
		.value(value), 
		.carry(carry)
	);

	initial begin
		// Initialize Inputs
		clk = 0;
		reset = 0;
		count = 0;
		load = 0;
		loadval = 0;

		// Wait 100 ns for global reset to finish
		#100;
      reset = 1;
		#10;
		reset= 0;
		#10;
		loadval = 5;
		load = 1;
		#10;
		load = 0;
		#20;
		count = 1;
		
		// Add stimulus here

	end
     always
		#5 clk = ~clk;
endmodule

