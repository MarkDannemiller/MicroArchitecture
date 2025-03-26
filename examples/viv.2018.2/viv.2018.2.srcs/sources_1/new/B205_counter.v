`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    08:08:15 08/31/2018 
// Design Name: 
// Module Name:    counter 
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
module counter(
    input clk,
    input reset,
	 input count,
	 input load,
	 input [7:0] loadval,
    output reg [7:0] value,
    output carry
    );


always @(posedge clk)
	begin
		if(reset)
			value <= 0;									// reset to known condition, which is done.
		else
			begin
				if(load)
					value <= loadval;					// start counting from somewhere
				else if(count)
					value <= value - 1;				// count down from wherever you are now
			end		
	end

assign carry = (value == 8'b0) ? 1 : 0;		// when zeroed out, raise done signal

endmodule
