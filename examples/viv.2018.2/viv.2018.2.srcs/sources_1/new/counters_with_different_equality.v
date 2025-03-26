`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/27/2018 02:53:57 PM
// Design Name: 
// Module Name: counters_with_different_equality
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


module counters_with_different_equality(
    input clock,
    input reset,
    output out1,
    output out2
    );
    
    reg out1 = 0;
    reg out2 = 0;
    
    reg [3:0] count1 = 0;
    reg [3:0] count2 = 0;
    
    always @(posedge clock)
        begin
        if(reset)
            begin
                count1 = 0;
                count2 <= 0;
                out1 = 0;
                out2 = 0;
            end
        else
            begin
            count1 = count1 + 1;            // increment now
            count2 <= count2 + 1;           // increment on the tick after processing loop
            
            if(count1 == 5)                 // checks incremented value
                begin
                    count1 = 0;             // never sees 5 - 0 1 2 3 4 0 1 2 3 4 0 
                    out1 = 1;
                end
            else
                out1 = 0;
            if(count2 == 5)                 // checks unincremented value
                begin
                    count2 <= 0;            // does see 5 - 0 1 2 3 4 5 0 1 2 3 4 5 0
                    out2 = 1;
                end
            else
                out2 = 0;
            end
        end
endmodule
