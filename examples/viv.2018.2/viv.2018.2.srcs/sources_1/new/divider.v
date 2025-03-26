`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/11/2018 02:05:07 PM
// Design Name: 
// Module Name: divider
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


module divider(
    input clock,
    input [15:0] numerator,
    input [7:0] denominator,
    input go,
    output [7:0] answer,
    output [7:0] remainder,
    output overflow,
    output done
    );

parameter init = 0, signs = 1, check = 2, shift = 3, count = 4, checksigns = 5, posneg = 6, negpos = 7, negneg = 8, pospos = 9, finish = 10, divbyzero = 11;

reg overflow;
reg done;
reg [15:0] top;
reg [7:0] bottom;
reg [3:0] state = init;
reg topsign;
reg bottomsign;
reg [3:0] bitcount;
reg [7:0] quotient;

assign remainder = top[15:8];                           // left-over bits in top will give us remainder
assign answer = quotient;

always @(posedge clock)
    begin
        case(state)
        init:
            begin
            overflow <= 0;
            done <= 0;
            if(go)
                begin
                top <= numerator;                           // dividend
                bottom <= denominator;                      // divisor
                bitcount <= 8;
                state <= signs;
                quotient <= 0;
                end
            end
        signs:
            begin
            if(top[15])
                begin
                top <= -top;
                topsign <= 1;
                end
            else
                topsign <= 0;
            if(bottom[7])
                begin
                bottom <= -bottom;  
                bottomsign <= 1;
                end
            else
                bottomsign <= 0;
            if(bottom == 0)
                state <= divbyzero;
            else
                state <= check;    
            end
        check:
            begin
            if(top[15:8] >= bottom)
                begin
                top[15:8] <= top[15:8] - bottom;
                quotient <= quotient | 1;
                end
            state <= count;
            end
        count:
            begin
            if(bitcount != 0)
                begin
                bitcount <= bitcount - 1;
                top <= {top[14:0], 1'b0};               // throw away used up top bit
                quotient <=  {quotient[6:0], 1'b0};     // all zeroes in high bits
                state <= check;
                end
            else
                state <= checksigns;  
            end
        checksigns:
            begin
            if(topsign == 0 && bottomsign == 0)
                state <= pospos;
            else if(topsign == 1 && bottomsign == 0)
                state <= negpos;
            else if(topsign == 0 && bottomsign == 1)
                state <= posneg;
            else 
                state <= negneg;
            if(top[15:8] > bottom[7:0] || quotient[7])
                    overflow <= 1;
                else
                    overflow <= 0;
            end
        pospos:                                             // divided is positive, divisor is positive
            begin                                           // 27 / 5 = 5 % 2
                state <= finish;                            
            end
        posneg:                                             // divided is positive, divisor is negative
            begin                                           // 27 / -5 = -5 % 2
                quotient <= -quotient;                      // C convention flips signs of quotient but not remainder
                state <= finish;                            
            end
        negpos:                                             // divided is negative, divisor is positive
            begin                                           // -27 / 5 = -5 % -2
                quotient <= -quotient;                      // C convention flips sign of quotient
                top <= -top;                                // C convention flips sign of remainder
                state <= finish;
            end
        negneg:                                             // divided is negative, divisor is negative
            begin                                           // -27 / -5 = 5 % -2 
                top <= -top;                                // C convention flips sign of remainder
                state <= finish;
            end
        divbyzero:                                          // automatic overflow
            begin
                overflow <= 1;
                if(topsign)
                    begin
                    top[15:8] <= -top[7:0];
                    quotient <= 8'h80;                      // saturate big negative
                    end
                else
                    begin
                    top[15:8] <= top[7:0];
                    quotient <= 8'h7f;                      // saturate big positive
                    end
                state <= finish;
            end                    
        finish:
            begin
            done <= 1;    
            state <= init;
            end
        endcase
    end
endmodule
