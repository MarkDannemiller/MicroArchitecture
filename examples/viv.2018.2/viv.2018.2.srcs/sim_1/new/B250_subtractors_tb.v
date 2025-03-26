`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/03/2020 05:30:34 PM
// Design Name: 
// Module Name: B195_subtractors
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


module B250_subtractors_tb(

    );


reg [7:0] inA;
reg [7:0] inB;
wire [7:0] outC;
wire Z, V, N, C, S;

subsyntax uut(inA, inB, outC, Z, V, N, C, S);

integer counter;

initial
begin
    for(counter = 0; counter < 256*256; counter = counter+1)
    begin
        {inA, inB} = counter;
        #10;
    end
    
end


endmodule
