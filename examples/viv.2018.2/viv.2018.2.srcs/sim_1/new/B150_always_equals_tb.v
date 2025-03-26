`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/22/2019 10:53:57 AM
// Design Name: 
// Module Name: B133_always_equals
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module B150_always_equals_tb;

	reg Ebar;
	reg [1:0] A;

	// Outputs
	wire [3:0] Dbar;

	// Instantiate the Unit Under Test (UUT)
	always_star uut (
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
