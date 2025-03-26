`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   18:59:35 04/01/2018
// Design Name:   PWM
// Module Name:   C:/Users/Nutter/Desktop/DT docs/simple_examples/M140_PWM.v
// Project Name:  simple_examples
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: PWM
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module B480_PWM_tb;

	// Inputs
	reg clock;
	reg reset;
	reg [7:0] duty;

	// Outputs
	wire drive;
	wire last;

	// Instantiate the Unit Under Test (UUT)
	PWM uut (
		.clock(clock), 
		.reset(reset), 
		.duty(duty), 
		.drive(drive),
		.last(last)
	);

	initial begin
		// Initialize Inputs
		clock = 0;
		reset = 0;
		duty = 0;

		// Wait 100 ns for global reset to finish
		#6000;
		
		duty = 127;
        
		#6000;
		
		duty = 255;
		// Add stimulus here

	end
	
	always
		begin
		#5 clock = ~clock;
		end
      
endmodule

