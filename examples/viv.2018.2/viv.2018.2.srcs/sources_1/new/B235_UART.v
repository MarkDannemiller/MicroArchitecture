`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/18/2018 10:12:24 PM
// Design Name: 
// Module Name: B235_UART
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


module UART(
    input clock,
    input reset,
    input [15:0] datain,
    input go,
    output reg TX,
    output reg done
    );
  
    reg [15:0] shiftreg;
    reg [4:0] bitcount;
    reg [3:0] state;
    reg [14:0] baudcount;

    
    always @(posedge(clock))
        begin
            if(reset)
                begin
                    {bitcount, state, baudcount, done} <= 0;
                    TX <= 1;            // stop is ONE
                end
            else // !reset
                begin
                    case (state)
                        0:
                            begin
                                done <= 0;              // makes DONE pulse skinny if here
                                if(go)
                                    begin
                                        baudcount <= 100_000_000 / 9600; // 10416
                                        state <= 1;
                                        shiftreg <= datain;
                                        TX <= 0;        // start is ZERO
                                        bitcount <= 16;
                                        done <= 0;              // makes DONE pulse fat if here
                                    end;
                            end
                        1:
                            if(baudcount == 0)
                                begin
                                    baudcount <= 100_000_000 / 9600;        // not expensive. Compiler knows 10416
                                    if(bitcount != 0)
                                        begin
                                            TX <= shiftreg[15];             // MSB first
                                            shiftreg <= {shiftreg[14:0], 1'b0};
                                            bitcount <= bitcount - 1;
                                        end
                                    else
                                        begin
                                        baudcount <= 100_000_000 / 9600; // 10416
                                        state <= 2;
                                         TX <= 1;                       // STOP bit
                                        end
                                end
                            else
                                begin
                                    baudcount <= baudcount - 1;
                                end
                        2:
                            if(baudcount == 0)
                                begin
                                    state <= 0;
                                    done <= 1;
                                end
                            else
                                baudcount <= baudcount - 1;
                    endcase
                end
        end
endmodule
