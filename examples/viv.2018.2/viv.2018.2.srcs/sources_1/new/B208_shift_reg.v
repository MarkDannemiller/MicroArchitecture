`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    08:31:12 08/31/2018 
// Design Name: 
// Module Name:    shift_reg 
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
module shift_reg(
    input clk,
    input reset,
    input SI,
	 input load,
    output reg [7:0] value,
    output reg SO
    );

always @(posedge clk)
	begin
		if(reset)
			{value,SO} <= 0;					// reset to known start condition
		else if(load)
			{value,SO} <= {SI,value};		// use vector syntax to make shift 
	end
endmodule
