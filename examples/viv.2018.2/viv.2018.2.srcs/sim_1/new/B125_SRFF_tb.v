`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/23/2020 02:29:29 PM
// Design Name: 
// Module Name: B125_SRFF_tb
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


module B122_SRlatch_tb(    );

reg R = 0, S = 0;
wire Q, Q_bar;

srlatch uut(S, R, Q, Q_bar);

initial 
    begin
    #10 S = 1;
    #10 S = 0;
    #10 R = 1;
    #10 R = 0;
    #10 S = 1;
    #10 S = 0;
    #10 R = 1;
    #10 R = 0;
    #10 R = 1;
    #10 S = 1;
    #10 S = 0;
    #10 R = 0;
    #10 S = 1;
    #10 R = 1;
    #10 R = 0;
    #10 S = 0;
        
    end

    
endmodule
