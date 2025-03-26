`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/08/2020 07:07:17 PM
// Design Name: 
// Module Name: B155_decoder
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


module B200_decoder_tb(

    );
    
reg [4:0] A;
wire [31:0] B;
integer i = 0;

big_decoder uut(A, B);

initial
begin
    for (i = 0; i < 32; i = i + 1)
    begin
        A <= i;
        #10;    
    end
end

endmodule
