`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:26:24 03/18/2018 
// Design Name: 
// Module Name:    casex 
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
module casexample(
    input [2:0] A,
    output reg [1:0] B1,
    output reg [1:0] B2	 
    );

always @(*)
	begin
		casex(A)
			3'b1xx:  B1 = 0;
			3'bx1x:  B1 = 1;
			3'bxx1:  B1 = 2;
			default: B1 = 3;
		endcase
	end

always @(*)
	begin
		casex(A)						// same values, different order, different results
			3'bxx1:  B2 = 2;
			3'bx1x:  B2 = 1;
			3'b1xx:  B2 = 0;
			default: B2 = 3;
		endcase
	end


endmodule
