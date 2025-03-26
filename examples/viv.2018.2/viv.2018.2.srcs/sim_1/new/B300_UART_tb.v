`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/18/2018 10:30:07 PM
// Design Name: 
// Module Name: B235_UART_tb
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


module B300_UART_tb(

    );

reg clock = 0;
reg reset = 0;
reg [15:0] datain = 0;
reg go = 0;
wire TX;
wire done;

UART UUT(clock, reset, datain, go, TX, done);

always
    #5 clock = ~clock; 

initial
    begin
    #100
    reset = 1;
    #10
    reset = 0; 
    #200
    datain = 16'hA5A5;
    go = 1;
    #10
    go = 0;
    #5000000
    datain = 16'h5AA5;
    go = 1;
    #10
    go = 0;
    end
    

    
endmodule
