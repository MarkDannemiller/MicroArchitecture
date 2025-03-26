`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/22/2019 10:49:29 AM
// Design Name: 
// Module Name: always_star
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module always_star(
    input Ebar,
    input [1:0] A,
    output reg [3:0] Dbar
    );
    
    always @(*)
        begin
        Dbar[0] = ~(~Ebar & ~A[1] & ~A[0]);	// c-like syntax
        Dbar[1] = ~(~Ebar & ~A[1] &  A[0]);	// note binary progression pattern with address bits
        Dbar[2] = ~(~Ebar &  A[1] & ~A[0]);
        Dbar[3] = ~(~Ebar &  A[1] &  A[0]);
        end
endmodule
