`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:15:01 08/29/2018 
// Design Name: 
// Module Name:    B110_vectors 
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
module vectors(
    input [1:0] S,
    input [3:0] D,
    output Y1
    );
														// example Verilog structural description
														// 4 to 1 multiplexer
														// using vectors of things
wire [1:0] Sbar;									// 2 bits [1] [0] of Sbar
wire [3:0] W;										// 4 bits [3] [2] [1] [0] of W

not 													// OUT IN
	g0not(Sbar[0], S[0]),
	g1not(Sbar[1], S[1]);

and													// OUT IN IN ...
	g0and(W[0], Sbar[1], Sbar[0], D[0]),
	g1and(W[1], Sbar[1], S[0],    D[1]),
	g2and(W[2], S[1],    Sbar[0], D[2]),
	g3and(W[3], S[1],    S[0],    D[3]);

or														// OUT IN IN ...
	g0or(Y1, W[0], W[1], W[2], W[3]);
	
endmodule
