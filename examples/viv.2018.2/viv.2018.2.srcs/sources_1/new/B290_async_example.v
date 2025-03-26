`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:18:19 03/08/2018 
// Design Name: 
// Module Name:    async_example 
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
module async_example(
    input [9:0] coin,
    output reg [9:0] money
    );

initial money = 9'b0; 

always @(coin)							// uodate on arrival of coin
	begin
		money = money + coin; 		// why do you give away credit in tb?
	end

endmodule
