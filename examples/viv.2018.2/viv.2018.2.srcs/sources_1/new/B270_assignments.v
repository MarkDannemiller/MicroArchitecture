`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:53:54 03/18/2018 
// Design Name: 
// Module Name:    assignments 
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
module assignments(
    input [1:0] control,
    input [7:0] D1,
    input [7:0] D2,
    output [7:0] result1,										// not reg because assigned
    output reg [7:0] result2									// has to be reg because soly solved when inputs change
    );

assign result1 = 	(control == 2'b00) ? D1      :		// done as assign
						(control == 2'b01) ? D1 & D2 :
						(control == 2'b10) ? D1 | D2 :
						                     D1 ^ D2 ;

always @(*)
	begin
		case (control)												// done as case, identical circuit
			2'b00: 	result2 = D1;
			2'b01: 	result2 = D1 & D2;
			2'b10: 	result2 = D1 | D2;
			default: result2 = D1 ^ D2;
		endcase
	end
	
endmodule
