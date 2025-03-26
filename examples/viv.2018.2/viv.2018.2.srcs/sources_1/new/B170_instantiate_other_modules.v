`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:51:51 08/30/2018 
// Design Name: 
// Module Name:    B170_instantiate_other_modules 
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
module full_adder(
    input A,
    input B,
    input CIN,
    output SUM,
    output COUT
    );

wire halfsum, halfcarry, topcarry;

half_adder	HA1(A, 		 B,   halfsum, halfcarry),				// 2 instances of half adder
			HA2(halfsum, CIN, SUM,     topcarry);			// to make one full adder
						
assign COUT = halfcarry | topcarry;

endmodule
