`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:39:00 08/29/2018 
// Design Name: 
// Module Name:    B120_dataflow 
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
module dataflow(
    input Ebar,
    input [1:0] A,
    output [3:0] Dbar
    );
															// example of a functional description
															// 2 to 4 decoder
assign Dbar[0] = ~(~Ebar & ~A[1] & ~A[0]);	// c-like syntax
assign Dbar[1] = ~(~Ebar & ~A[1] &  A[0]);	// note binary progression pattern with address bits
assign Dbar[2] = ~(~Ebar &  A[1] & ~A[0]);
assign Dbar[3] = ~(~Ebar &  A[1] &  A[0]);
															// A&B bitwise AND
															// A|B bitwise OR
															// A^B bitwise XOR
															// ~A  bitwise NOT

endmodule
