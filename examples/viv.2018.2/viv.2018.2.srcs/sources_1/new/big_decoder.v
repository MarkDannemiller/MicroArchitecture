`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/08/2020 07:02:53 PM
// Design Name: 
// Module Name: big_decoder
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


module big_decoder(
    input [4:0] inA,
    output reg [31:0] outB
    );
    
    always @(*)
    begin
        outB = 0;
        outB[inA] = 1;
    end
    
endmodule
