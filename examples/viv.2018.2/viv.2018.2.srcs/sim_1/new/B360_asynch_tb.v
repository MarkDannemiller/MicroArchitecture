`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   14:20:31 03/08/2018
// Design Name:   async_example
// Module Name:   C:/Users/bnutter/Desktop/DT Docs/xilinx/asynchronous_money/asynch_tb.v
// Project Name:  asynchronous_money
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: async_example
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module B360_asynch_tb;

	// Inputs
	reg [9:0] coin;

	// Outputs
	wire [9:0] money;

	// Instantiate the Unit Under Test (UUT)
	async_example uut (
		.coin(coin), 
		.money(money)
	);

	initial begin
		// Initialize Inputs
		coin = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		coin = 5;
		#100;
		coin = 10;
		#100;
		coin = 0; 
		#100;
		coin = 64;		// bits not as simultaneous as test bench wants to pretend
		#1;
		coin = 96;
		#1;
		coin = 100;
		#100;
		coin = 36;
		#1;
		coin = 4;
		#1;
		coin = 0; 
		#100;


	end
      
endmodule

