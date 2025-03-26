`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:45:47 04/01/2018 
// Design Name: 
// Module Name:    percentage 
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
module percentage(
	 input clock,
	 input reset,
    input [7:0] numerator,
    input [7:0] denominator,
    input go,
    output reg [7:0] percent,
    output reg done
    );

reg [14:0] summation;
reg [1:0] state = 0;


always @(posedge clock)
	begin
		if(reset)
			begin
				{state, summation, percent, done} <= 0;									// nice syntax for mass reset
			end
		else
			begin
				case(state)
					0: 
						begin
							done <= 0;
							if(go && denominator > 0)
								begin
									summation <= numerator * 100 + denominator /2;		// to be done in parts per hundred, plus rounding
									percent <= 0;													// clear it out to start
									state <= 1;
								end
						end
					1:
						begin
							if(summation >= denominator)										// see if it fits
								begin
									summation <= summation - denominator;					// take one out
									percent <= percent + 1;										// percentage goes up
								end
							else
								begin
									state <= 2;														// otherwise now ready to quit
								end
						end
					2:
						begin
							state <= 0;																// quit
							done <= 1;																// and tell the world
						end
				endcase
			end
	end


endmodule
