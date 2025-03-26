`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/18/2018 02:59:38 PM
// Design Name: 
// Module Name: B405_divider_tb
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


module B500_divider_tb(

    ); 
    
    reg clock;
    reg [15:0] numerator;
    reg [7:0] denominator;
    reg go;
    
    wire [7:0] answer;
    wire [7:0] remainder;
    wire overflow;
    wire done;

    divider uut(.clock(clock), 
                .numerator(numerator), 
                .denominator(denominator), 
                .go(go), 
                .answer(answer), 
                .remainder(remainder), 
                .overflow(overflow), 
                .done(done));
    
    initial
        begin
        clock = 0;
        numerator = 1000;
        denominator = 6;        // 166 (does not fit) % 4 - should overflow w/ -90      166 * 6 + 4 = 1000
        #10 go = 1;
        #10 go = 0;
        #350
        numerator = 500;        // 83 % 2       83 * 6 + 2 = 500
        denominator = 6;
        #10 go = 1;
        #10 go = 0;
        #350
        numerator = -500;       // -83 % -2     -83 * 6 + -2 = -500
        denominator = 6;
        #10 go = 1;
        #10 go = 0;
        #350
        numerator = 500;        // -83 % 2      -83 * -6 + 2 = 500
        denominator = -6;
        #10 go = 1;
        #10 go = 0;
        #350
        numerator = -500;       // 83 % -2      83 * -6 + -2 = -500
        denominator = -6;       
        #10 go = 1;
        #10 go = 0;
        #350
        numerator = 50;         //              BIGPOS * 0 % 50 = 50
        denominator = 0;
        #10 go = 1;
        #10 go = 0;
        #350
        numerator = -50;        //              BIGNEG * 0 % -50 = -50
        denominator = 0;
        #10 go = 1;
        #10 go = 0;
        end
        
    always
        begin
        #5 clock = ~clock;
        end
endmodule
