`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   19:57:18 04/01/2018
// Design Name:   percentage
// Module Name:   C:/Users/Nutter/Desktop/DT docs/simple_examples/M150_percentages.v
// Project Name:  simple_examples
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: percentage
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module B510_percentages_tb;

	// Inputs
	reg clock;
	reg reset;
	reg [7:0] numerator;
	reg [7:0] denominator;
	reg go;

	// Outputs
	wire [7:0] percent;
	wire done;

	// Instantiate the Unit Under Test (UUT)
	percentage uut (
		.clock(clock), 
		.reset(reset), 
		.numerator(numerator), 
		.denominator(denominator), 
		.go(go), 
		.percent(percent), 
		.done(done)
	);

	initial begin
		// Initialize Inputs
		clock = 0;
		reset = 0;
		numerator = 0;
		denominator = 0;
		go = 0;

		// Wait 100 ns for global reset to finish
		#100;
		// Add stimulus here

       
		numerator = 33;
		denominator = 50;
		go = 1;
		#10 go = 0;
		#1000;
       
		numerator = 1;
		denominator = 3;
		go = 1;
		#10 go = 0;

		#1000;
       
		numerator = 2;
		denominator = 3;
		go = 1;
		#10 go = 0;

		#1000;
       
		numerator = 99;
		denominator = 100;
		go = 1;
		#10 go = 0;

		#1100;
       
		numerator = 100;
		denominator = 93;
		go = 1;
		#10 go = 0;


	end
	
	always
		begin
		#5 clock = ~clock;
		end
      
endmodule

