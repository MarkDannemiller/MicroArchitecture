`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:18:47 08/30/2018 
// Design Name: 
// Module Name:    B190_adder 
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
module adder(
    input [7:0] A,
    input [7:0] B,
    input CIN,
    output [7:0] SUM,
    output COUT
    );

assign {COUT, SUM} = A + B + CIN;		// much better design this way

endmodule
