`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/23/2020 02:45:33 PM
// Design Name: 
// Module Name: dff
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


module dlatch(
    input D,
    input EN,
    output Q,
    output Q_bar
    );

wire R, S;


srlatch uut(S, R, Q, Q_bar);

nand u1(R,  D, EN),
     u2(S, ~D, EN);

endmodule
