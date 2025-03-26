`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   20:40:19 03/31/2018
// Design Name:   memPROG
// Module Name:   C:/Users/Nutter/Desktop/DT docs/simple_examples/M120_program_memory.v
// Project Name:  simple_examples
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: memPROG
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module B460_program_memory_tb;

	// Inputs
	reg [7:0] PC;

	// Outputs
	wire [7:0] dataout;

	// Instantiate the Unit Under Test (UUT)
	memPROG uut (
		.PC(PC), 
		.dataout(dataout)
	);
	
	integer i;

	initial begin
		// Initialize Inputs
		PC = 0;

		// Wait 100 ns for global reset to finish
		#100;
		
		for(i=0;i<256; i=i+1)
			#10 PC = PC+1;
        
		// Add stimulus here

	end
      
endmodule

