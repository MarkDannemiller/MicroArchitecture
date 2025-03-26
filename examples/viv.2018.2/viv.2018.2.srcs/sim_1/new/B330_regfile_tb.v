`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   18:12:09 03/18/2018
// Design Name:   regfile
// Module Name:   C:/Users/bnutter/Desktop/DT Docs/xilinx/asynchronous_money/regfile_tb.v
// Project Name:  asynchronous_money
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: regfile
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module B330_regfile_tb;

	// Inputs
	reg clock;
	reg reset;
	reg WE;
	reg [3:0] Asel;
	reg [3:0] Bsel;
	reg [3:0] Dsel;
	reg [7:0] DIN;

	// Outputs
	wire [7:0] AOUT;
	wire [7:0] BOUT;

	integer i=0;

	// Instantiate the Unit Under Test (UUT)
	regfile uut (
		.clock(clock), 
		.reset(reset), 
		.WE(WE), 
		.Asel(Asel), 
		.Bsel(Bsel), 
		.Dsel(Dsel), 
		.DIN(DIN), 
		.AOUT(AOUT), 
		.BOUT(BOUT)
	);

	initial begin
		// Initialize Inputs
		clock = 0;
		reset = 0;
		WE = 0;
		Asel = 0;
		Bsel = 0;
		Dsel = 0;
		DIN = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		for (i=0; i < 32; i = i + 1)
			begin
				#2 Asel = i[3:0];
				#2 Bsel = i[3:0];
			end
		
		#10 reset = 1;
		#10 reset = 0;

		for (i=0; i < 32; i = i + 1)
			begin
				#2 Asel = i[3:0];
				#2 Bsel = i[3:0];
			end
			
		#10 WE = 1;
		Asel = 5;
		Bsel = 9;

		for (i=0; i < 32; i = i + 1)
			begin
				#10 Dsel = i[3:0];
				DIN = i[7:0];
			end

		for (i=0; i < 32; i = i + 1)
			begin
				#2 Asel = i[3:0];
				#2 Bsel = i[3:0];
			end
		

	end
	
	always
		#5 clock = ~clock;
      
endmodule

