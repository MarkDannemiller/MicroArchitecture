`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:39:20 03/09/2018 
// Design Name: 
// Module Name:    replicator 
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
module replicator(
    input [7:0] shortnum,
    output [15:0] longnum,
    input extend
    );

assign longnum = (extend) ? {{8{shortnum[7]}}, shortnum} : {8'b0, shortnum};

//                             { a vector of one bit
//                           {8 a vector replicated 8 times
//                          { a vector contatenating 2 vectors  
endmodule

