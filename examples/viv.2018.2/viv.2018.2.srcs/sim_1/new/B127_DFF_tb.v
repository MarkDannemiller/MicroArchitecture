`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/23/2020 03:09:45 PM
// Design Name: 
// Module Name: B127_DFF_tb
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


module B123_Dlatch_tb(    );

reg D = 0;
reg EN = 0;
wire Q1, Q1_bar;

dlatch uut(D, EN, Q1, Q1_bar);

always #10 D = ~D;
always #11 EN = ~EN;


endmodule
