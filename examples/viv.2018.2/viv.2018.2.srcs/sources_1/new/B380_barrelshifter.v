`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:52:23 03/30/2018 
// Design Name: 
// Module Name:    barrelshifter 
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
module barrelshifter(
    input [31:0] datain,
    input [4:0] SH,
    input [2:0] ftn,
    output reg [31:0] dataout
    );

parameter LSL = 0, LSR = 1, ASL = 2, ASR = 3, ROTL = 4, ROTR = 5;		// could `include HEADER.H file for macros

wire [63:0] rot;
wire [63:0] logical;
wire [63:0] arith;

assign logical = {           32'b0, datain};			// using whitespace to make patterns more clear
assign arith =   {{32{datain[31]}}, datain};
assign rot =     {          datain, datain};

always @(*)
	begin
		case(ftn)
			LSL: 			dataout =    logical <<     SH;
			LSR: 			dataout =    logical >>     SH;
			ASL: 			dataout =      arith <<     SH;
			ASR: 			dataout =      arith >>     SH;
			ROTL: 		dataout =        rot >> (32-SH); // to make the << SH work
			ROTR: 		dataout =        rot >>     SH;
			default: 	dataout =     datain;
		endcase
	end
endmodule
