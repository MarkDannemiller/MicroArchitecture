`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/11/2019 04:00:18 PM
// Design Name: 
// Module Name: B335_LFSR
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


module B410_LFSR_tb;
    
reg clock;
reg reset;
wire [15:0] pseudo;

LFSR uut(clock, reset, pseudo);

initial
    begin
    clock = 0;
    reset = 1;
    #20 reset = 0;
    
    end
                                        // cycles at 65535. 
always #5 clock = ~clock;    
    
endmodule
