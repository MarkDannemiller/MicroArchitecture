`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   20:24:36 03/31/2018
// Design Name:   barrelshifter
// Module Name:   C:/Users/Nutter/Desktop/DT docs/simple_examples/M130_barrel_shifter.v
// Project Name:  simple_examples
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: barrelshifter
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module B470_barrel_shifter_tb;

	// Inputs
	reg [31:0] datain;
	reg [4:0] SH;
	reg [2:0] ftn;

	// Outputs
	wire [31:0] dataout;

	// Instantiate the Unit Under Test (UUT)
	barrelshifter uut (
		.datain(datain), 
		.SH(SH), 
		.ftn(ftn), 
		.dataout(dataout)
	);

	initial begin
		// Initialize Inputs
		datain = 0;
		SH = 0;
		ftn = 0;

		// Wait 100 ns for global reset to finish
		#100;
		SH = 8;
		datain = 32'h12345678;
      #10 ftn = 1;  
      #10 ftn = 2;  
      #10 ftn = 3;  
      #10 ftn = 4;  
      #10 ftn = 5;  
      #10 ftn = 6;  
      #10 ftn = 7;  
		// Add stimulus here

	end
      
endmodule

