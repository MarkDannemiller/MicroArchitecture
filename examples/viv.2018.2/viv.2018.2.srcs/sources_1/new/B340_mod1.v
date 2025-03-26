`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    20:53:24 03/18/2018 
// Design Name: 
// Module Name:    mod1 
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
module mod1(
    input clock,
    input reset,
    input go,
    output done
    );

reg [2:0] state = 0;
assign done = (state == 6) ? 1 : 0;		// simple module to delay done pulse several ticks after go pulse

always @(posedge clock)
	begin
		if(reset)
			state <= 0;
		else
			begin
				if(state == 0 && go)
					state <= 1;
				else if(state > 0 && state <= 6)
					state <= state + 1;
			end
	end

endmodule
