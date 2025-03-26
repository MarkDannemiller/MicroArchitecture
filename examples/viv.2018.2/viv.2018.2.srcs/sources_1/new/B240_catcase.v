`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:15:46 03/09/2018 
// Design Name: 
// Module Name:    catcase 
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
module catcase(
    input a,
    input b,
	 input c,
    output reg [3:0] d
    );

always @(*)
	begin
		case ({a,b,c})					// pull bits together to make clean case statement
			3'b000: d = 2;
			3'b001: d = 5;
			3'b010: d = 11;
			3'b011: d = 14;
			3'b100, 3'b101: d = 7;
			3'b110, 3'b111: d = 3;
			default: d = 4'bx;
		endcase	
	end

endmodule
