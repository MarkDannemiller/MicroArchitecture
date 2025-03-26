`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:06:31 03/18/2018 
// Design Name: 
// Module Name:    regfile 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module regfile(
    input clock,
    input reset,
	 input WE,
    input [3:0] Asel,
    input [3:0] Bsel,
    input [3:0] Dsel,
    input [7:0] DIN,
    output [7:0] AOUT,
    output [7:0] BOUT
    );

reg [7:0] data [15:0];

assign AOUT = data [Asel];
assign BOUT = data [Bsel];

integer counter;

initial
	for(counter = 0; counter < 16; counter = counter + 1)
		data [counter] = counter;									// for easier initial debugging
		
always @(posedge clock)
	begin
		if(reset)
			for(counter = 0; counter < 16; counter = counter + 1)
				data [counter] <= 0;									// clear all regs on reset
		else if(WE)														// if not clearing, then write
			data[Dsel] <= DIN;		
	end
	
endmodule
