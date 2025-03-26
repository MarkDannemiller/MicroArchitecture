`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/23/2020 03:39:16 PM
// Design Name: 
// Module Name: dff2
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


module dff(
    input D,
    input CLK,
    output Q,
    output Q_bar
    );
    
wire w1, w2, w3, w4, R, S;
    
srlatch U1(w1, w2, S, R),
        U2(w3, w4, Q, Q_bar);
        
nand    U3(w1,  D, CLK),
        U4(w2, ~D, CLK),
        U5(w3,  S, ~CLK),
        U6(w4,  R, ~CLK);
        
endmodule
