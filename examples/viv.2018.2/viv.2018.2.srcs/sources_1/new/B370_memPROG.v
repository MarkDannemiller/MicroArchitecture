`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    20:35:36 03/31/2018 
// Design Name: 
// Module Name:    memPROG 
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
module memPROG(
    input [7:0] PC,
    output [7:0] dataout
    );

`include "PATT.inc"										// parameter macros for ASSY instructions

integer i;

reg [7:0] memword [255:0];
initial
  begin
    memword[0] = PATT0;									// these represent the ASSY guy's instructions
    memword[1] = PATT1;									// ADD R3, R2, R1
    memword[2] = PATT2;									// ADD R4, R3, R2
    memword[3] = PATT3;									// ADD R5, R4, R3
    memword[4] = PATT4;									// etc. Easier to read with ASSY looking stuff here
    memword[5] = PATT5;
    memword[6] = PATT6;
    memword[7] = PATT7;
	 for(i=8; i< 256; i = i+1)
		memword[i] = PATTX;
  end


assign dataout = memword[PC];



endmodule
