`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:53:59 04/01/2018 
// Design Name: 
// Module Name:    PWM 
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
module PWM(
    input clock,
    input reset,
    input [7:0] duty,
    output drive,
	 output last
    );

reg [7:0] period = 0;

assign drive = (period >= duty) ? 0 : 1;		// PWM output
assign last = (period == 8'hff) ? 1 : 0;		// signal for end of cycle

always @(posedge clock)
	begin
		if(reset)
			period <= 0;
		else
			period <= period + 1;
	end

endmodule
