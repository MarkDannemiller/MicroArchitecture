`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/21/2020 10:46:09 AM
// Design Name: 
// Module Name: multi_array
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


module multi_array(
    input [2:0] i1,
    input [3:0] i2,
    input [4:0] i3,
    output [7:0] xport
    );
    
reg [7:0] block[7:0][15:0][31:0];

initial block[1][2][3] = 5;
initial block[4][5][6] = 15;

assign xport = block[i1][i2][i3];

endmodule
