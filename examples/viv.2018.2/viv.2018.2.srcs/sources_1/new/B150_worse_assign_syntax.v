`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:35:30 08/30/2018 
// Design Name: 
// Module Name:    B150_worse-assign_syntax 
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
module worse_assign_syntax(
    input [1:0] S,
    input [3:0] D,
    output Y
    );

assign Y = S[1] ? (S[0] ? D[3] : D[2]) : 	// looking at bits in binary tree is harder to see
                  (S[0] ? D[1] : D[0]) ;
endmodule
