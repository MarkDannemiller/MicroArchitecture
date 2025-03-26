`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   12:56:07 03/09/2018
// Design Name:   replicator
// Module Name:   C:/Users/bnutter/Desktop/DT Docs/xilinx/asynchronous_money/extend_tb.v
// Project Name:  asynchronous_money
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: replicator
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module B320_extend_tb;

	// Inputs
	reg [7:0] shortnum;
	reg extend;

	// Outputs
	wire [15:0] longnum;

	// Instantiate the Unit Under Test (UUT)
	replicator uut (
		.shortnum(shortnum), 
		.longnum(longnum), 
		.extend(extend)
	);

	initial begin
		// Initialize Inputs
		shortnum = 0;
		extend = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		shortnum = 8'h7f;
		#10
		extend = 1;
		#10
		shortnum = 8'hff;
		#10
		extend = 0;

	end
      
endmodule

