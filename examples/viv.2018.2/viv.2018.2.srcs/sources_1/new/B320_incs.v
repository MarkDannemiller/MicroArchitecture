`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:15:34 03/18/2018 
// Design Name: 
// Module Name:    incs 
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
module incs(
    input [2:0] A,
    output reg [7:0] B
    );

`include "PATT.INC"			// lots of parameters 
 
	always @(*)
		begin
			case (A)
				0:
					B = PATT0;
				1:
					B = PATT1;
				2:
					B = PATT2;
				3:
					B = PATT3;
				4:
					B = PATT4;
				5:
					B = PATT5;
				6:
					B = PATT6;
				7:
					B = PATT7;
				default:
					B = PATTX;
			endcase
		end
endmodule
