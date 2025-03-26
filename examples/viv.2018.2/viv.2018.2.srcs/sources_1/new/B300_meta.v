`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:57:32 03/10/2018 
// Design Name: 
// Module Name:    meta 
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
module meta(
    input async,								// no other moduels see this - only read once in here
	 input clock,
    output sync								// other modules can use at will
    );

reg async_old = 0;							// no other modules msee this - only read once in here
reg async_old_old = 0;

assign sync = async_old_old;

always @(posedge clock)
	begin
		async_old <= async;					// read and latch to synchronize, hoping not to catch 2.5 V. Million : 1 long shot
		async_old_old <= async_old;		// read and latch to address metastability on 2.5 V catch. Million^2 : 1 real long shot
	end

endmodule
