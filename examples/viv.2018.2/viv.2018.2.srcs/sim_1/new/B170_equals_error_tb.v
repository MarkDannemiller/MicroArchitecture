`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/24/2019 03:53:38 PM
// Design Name: 
// Module Name: B138_equals_error
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


module B170_equals_error_tb;

wire [5:0] ABC1;
wire [5:0] ABC2;
reg clock=0;

rotators uut(clock, ABC1, ABC2);

    
always 
    #5 clock = ~clock;
    
endmodule
