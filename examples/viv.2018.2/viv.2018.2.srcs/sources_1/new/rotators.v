`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/24/2019 03:47:33 PM
// Design Name: 
// Module Name: rotators
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


module rotators(
    input clock,
    output [5:0] ABC1,
    output [5:0] ABC2
    );

assign ABC1 = {A1, B1, C1};
assign ABC2 = {A2, B2, C2};

reg [1:0] A1 = 1;
reg [1:0] A2 = 1;
reg [1:0] B1 = 2;
reg [1:0] B2 = 2;
reg [1:0] C1 = 3;
reg [1:0] C2 = 3;
    
always @(posedge clock)  
    begin
    A1 = B1;        // the original A1 is lost
    B1 = C1;        // B1 changes to original C1
    C1 = A1;        // C1 changes to original B1 - 2 way alternating
    A2 <= B2;       // A2 comes from B2
    B2 <= C2;       // B2 comes from C2
    C2 <= A2;       // C2 comes from A2 - 3 way rotation
    end  
endmodule
