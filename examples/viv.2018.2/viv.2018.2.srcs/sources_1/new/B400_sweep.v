`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:16:02 04/01/2018 
// Design Name: 
// Module Name:    sweep 
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
module sweep(
    input clock,
    input reset,
    output drive
    );

reg [7:0] position = 0;

wire last;

	PWM u1 (
		.clock(clock), 
		.reset(reset), 
		.duty(position), 
		.drive(drive),
		.last(last)
	);

always @(posedge clock)
	begin
	if(reset)
		position <= 0;
	else
		if(last)
			position <= position + 1;
	end


endmodule
