`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:49:20 03/09/2018 
// Design Name: 
// Module Name:    posnotedge 
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
module posnotedge(
    input signal,
	 input clock,
    output reg edgeplus,
	 output reg edgeminus
    );
	 
initial 
	begin
		edgeplus = 0;
		edgeminus = 0;
	end
reg oldsignal = 0;

always @(posedge clock)
	begin
		oldsignal <= signal;
	end

always @(*)
  begin
	if(signal == 1 & oldsignal == 0)		// rising edges
	  edgeplus = 1;
	else
	  edgeplus = 0;
	if(signal == 0 & oldsignal == 1)		// falling edges
	  edgeminus = 1;
	else
	  edgeminus = 0;
  end

endmodule
