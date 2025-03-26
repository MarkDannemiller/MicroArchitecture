`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:24:16 08/30/2018 
// Design Name: 
// Module Name:    B140_better_assign_syntax 
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
module better_assign_syntax(
    input [1:0] S,
    input [3:0] D,
    output Y
    );

assign Y = (S == 2'b00) ? D[0] :				// looking at bits as vector ie easier to read
           (S == 2'b01) ? D[1] :
           (S == 2'b10) ? D[2] :
           (S == 2'b11) ? D[3] : 1'bx;


endmodule
