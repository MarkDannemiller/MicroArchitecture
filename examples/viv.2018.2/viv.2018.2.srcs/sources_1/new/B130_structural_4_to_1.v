`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:52:05 08/30/2018 
// Design Name: 
// Module Name:    B130_structural_4_to_1 
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
module dataflow_4_to_1(
    input [1:0] S,
    input [3:0] D,
    output Y
    );
													// functional descript
													// 4 to 1 MUX
assign Y = (~S[1] & ~S[0] & D[0]) |		// note use of white space to keep alignment
           (~S[1] &  S[0] & D[1]) |		// easier to read this way
           ( S[1] & ~S[0] & D[2]) |
           ( S[1] &  S[0] & D[3]) ;


endmodule
