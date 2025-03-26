`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/11/2019 03:52:38 PM
// Design Name: 
// Module Name: LFSR
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


module LFSR(
    input clk,
    input reset,
    output reg [15:0] pseudo
    );
    
initial pseudo = 1;

assign lsb = pseudo[10] ^ pseudo[12] ^ pseudo[13] ^ pseudo[15];

always @(posedge clk)
    begin
    if(reset)
        pseudo <= 1;
    else
        pseudo <= {pseudo[14:0], lsb};
    end
    
endmodule
