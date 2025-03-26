`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/27/2018 03:04:45 PM
// Design Name: 
// Module Name: B135_equals
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


module B160_equals_tb;


reg clock = 0;
reg reset = 0;
wire out1;
wire out2;

    always
        #5 clock = ~clock;

counters_with_different_equality uut(clock, reset, out1, out2);

    initial begin
    #100 reset = 1;
    #100 reset = 0;
    end
endmodule
