`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:03:13 08/30/2018 
// Design Name: 
// Module Name:    B180_full_adder 
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
module full_adder1(
    input [7:0] A,
    input [7:0] B,
    input C0,
    output [7:0] S,
    output C8
    );

wire [7:1] C;


full_adder	    FA0(A[0], B[0], C0,   S[0], C[1]),				// 8 instances of full adder to make 8 bit circuit
				FA1(A[1], B[1], C[1], S[1], C[2]),				// careful use of whitespace to keep aligned
				FA2(A[2], B[2], C[2], S[2], C[3]),
				FA3(A[3], B[3], C[3], S[3], C[4]),
				FA4(A[4], B[4], C[4], S[4], C[5]),
				FA5(A[5], B[5], C[5], S[5], C[6]),
				FA6(A[6], B[6], C[6], S[6], C[7]),
				FA7(A[7], B[7], C[7], S[7], C8  );
endmodule
