`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:29:59 03/30/2018 
// Design Name: 
// Module Name:    memDATA 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module memDATA(
    input clk,
    input [5:0] addr,
    input MW,
    input [31:0] datain,
    output [31:0] dataout
    );

reg [31:0] memword [63:0];
integer i;

initial
  begin
  for(i=0; i<64; i=i+1)
    memword[i] <= i;					// for easier debugging
  end

always @ (posedge clk)
  begin
    if(MW)
	   memword[addr] <= datain;
  end

assign dataout = memword[addr];

endmodule
