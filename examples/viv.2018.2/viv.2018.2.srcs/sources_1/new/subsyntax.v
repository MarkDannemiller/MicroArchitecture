`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/03/2020 05:21:15 PM
// Design Name: 
// Module Name: subsyntax
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


module subsyntax(
    input [7:0] inA,
    input [7:0] inB,
    output [7:0] outC,
    output Z,
    output reg V,
    output N,
    output C,
    output S
    );

assign {C,outC} = inA - inB;

assign N = outC[7];
assign Z = ~|outC;
assign S = N^V;

always @(*)
begin
    if(inA[7] & ~inB[7] & ~outC[7])         // neg - pos == pos is V
        V = 1;
    else if(~inA[7] & inB[7] & outC[7])     // pos - neg == neg is V
        V = 1;
    else
        V = 0;                              // other cases not V
end

endmodule
