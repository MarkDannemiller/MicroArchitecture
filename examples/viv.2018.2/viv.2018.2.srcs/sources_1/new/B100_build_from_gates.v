`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:12:50 08/29/2018 
// Design Name: 
// Module Name:    B100_build_from_gates 
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
module build_from_gates(
    input Ebar,
    input A0,
    input A1,
    output D0bar,
    output D1bar,
    output D2bar,
    output D3bar
    );
											// example of a structural description. 
											// 2 to 4 decoder
											// Easy to follow if you have a schematic
wire A0bar, A1bar, E;

not										// OUT, IN
	g0(A0bar, A0  ),					// Invert A0   to make A0bar
	g1(A1bar, A1  ),					// Invert A1   to make A1bar
	g2(E,     Ebar);					// Invert Ebar to make E
	
nand										// OUT IN IN ...
	g3(D0bar, A1bar, A0bar, E),	// Assert D0 negative iff A1 = 0, A0 = 0, and E = 0
	g4(D1bar, A1bar, A0,    E),	// Assert D1 negative iff A1 = 0, A0 = 1, and E = 0
    g5(D2bar, A1,    A0bar, E),	// Assert D2 negative iff A1 = 1, A0 = 0, and E = 0
	g6(D3bar, A1,    A0,    E);	// Assert D3 negative iff A1 = 1, A0 = 1, and E = 0

											// and or not nand nand xor xnor buf

endmodule
