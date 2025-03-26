`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/18/2018 08:43:44 PM
// Design Name: 
// Module Name: SPI
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


module SPI(
    input clock,
    input reset,
    input [15:0] datain,
    input go,
    output reg CS,
    output reg MOSI,
    output reg CLKOUT,
    output reg done
    );
    
    reg [15:0] shiftreg;
    reg [3:0] bitcount;
    reg [3:0] state;
    
    //   G
    //    CS-------------CS
    //      CK-CK-CK-CK
    //    D0 D1 D2 D3
    always @(posedge(clock))
        begin
            if(reset)
                begin
                    bitcount <= 0;
                    CS <= 0;
                    MOSI <= 0;
                    CLKOUT <= 0;
                    done <= 0;
                    state <= 0; 
                end
            else // !reset
                begin
                    case (state)
                        000:
                            if(go)
                                begin
                                    state <= 1;
                                    CS <= 1;
                                    CLKOUT <= 0;
                                    MOSI <= 0;
                                    shiftreg <= datain;
                                    bitcount <= 15;
                                end
                        001:
                            begin    
                                MOSI <= shiftreg[0];            // LSB first;
                                shiftreg <= {1'b0,shiftreg[15:1]};
                                if(bitcount == 0)
                                    state <= 3;
                                else
                                   state <= 2;
                                bitcount <= bitcount-1;
                                CLKOUT <= 0;
                             end
                        002:
                            begin
                                CLKOUT <= 1;
                                    state <= 1;
                             end
                        003:
                            begin
                                CS <= 0;
                                done <= 1;
                                state <= 0;
                            end
                   endcase        
                end
           
        end
    
endmodule
