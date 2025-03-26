`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/23/2020 03:49:04 PM
// Design Name: 
// Module Name: B128_Dff_tb
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


module B128_Dff_tb( );

reg D = 0;
reg CLK = 0;
wire Q1, Q1_bar;

dff uut(D, CLK, Q1, Q1_bar);

always #50 
       //#0 
       CLK = ~CLK;
     
always #51 D = ~D;

//------------------------------------

reg Q2;

always @(negedge(CLK))
    Q2 <= D;

//------------------------------------

wire diff;
assign diff = (Q1 == Q2) ? 0 : 1'bx;

endmodule
