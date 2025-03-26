`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/21/2020 10:53:24 AM
// Design Name: 
// Module Name: B355_multi_d_blocks
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


module B440_multi_d_blocks(

    );
    
    reg [2:0] i1 = 0;
    reg [3:0] i2 = 0;
    reg [4:0] i3 = 0;
    wire [7:0] xport;
    
multi_array UUT (i1, i2, i3, xport);
 
integer a1, a2, a3;
 
initial
begin
for(a1 = 0; a1 <= 7; a1 = a1 + 1)
    begin
    #10
    for(a2 = 0; a2 <= 15; a2 = a2 + 1)
        begin
        #10
        for(a3 = 0; a3 <= 31; a3 = a3 + 1)
            begin
                #10;
                i3 = a3;
                i2 = a2;
                i1 = a1;
            end
        end
    end
end


endmodule
