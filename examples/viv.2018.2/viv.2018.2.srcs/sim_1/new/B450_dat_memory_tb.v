`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   13:41:15 03/30/2018
// Design Name:   memDATA
// Module Name:   C:/Users/bnutter/Desktop/DT Docs/xilinx/simple_examples/M110_dat_memory.v
// Project Name:  simple_examples
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: memDATA
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module B450_dat_memory_tb;

	// Inputs
	reg clk;
	reg [5:0] addr;
	reg MW;
	reg [31:0] datain;

	// Outputs
	wire [31:0] dataout;

	// Instantiate the Unit Under Test (UUT)
	memDATA uut (
		.clk(clk), 
		.addr(addr), 
		.MW(MW), 
		.datain(datain), 
		.dataout(dataout)
	);

	initial begin
		// Initialize Inputs
		clk = 0;
		addr = 0;
		MW = 0;
		datain = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		datain = 15;
		addr = 1;
		#10;
		addr = 2;
		#10
		MW = 1;
		addr = 3;
		#10
		MW = 0;
		#10
		addr = 4;
	end
	
	always begin
		#5 clk = ~clk;
	end
      
endmodule

