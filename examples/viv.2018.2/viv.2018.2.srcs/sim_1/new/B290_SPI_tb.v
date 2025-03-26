`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/18/2018 09:09:29 PM
// Design Name: 
// Module Name: B220_SPI_tb
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


module B290_SPI_tb;

reg clock = 0;
reg reset = 0;
reg [15:0]datain = 0;
reg go = 0;
wire CS;
wire MOSI;
wire CLKOUT;
wire done;

SPI UUT(clock, reset, datain, go, CS, MOSI, CLKOUT, done);

always
    #5 clock = ~clock; 

initial
    begin
    #100
    reset = 1;
    #10
    reset = 0; 
    #20
    datain = 16'hA5A5;
    go = 1;
    #10
    go = 0;
    end

    
endmodule
