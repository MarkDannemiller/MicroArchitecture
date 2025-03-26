`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:45:38 08/30/2018 
// Design Name: 
// Module Name:    B160_half_adder 
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
module half_adder(
    input A,
    input B,
    output sum,
    output carry
    );

assign sum   = A ^ B;	// traditional start for addition circuit
assign carry = A & B;

endmodule
