`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/21/2018 03:52:57 PM
// Design Name: 
// Module Name: B420_PVA
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


module PVA(
    input clock,
    input reset,
    input [31:0] pos_in,
    input pos_load,
    input [31:0] vel_in,
    input vel_load,
    input [31:0] accel_in,
    input accel_load,
    input halt,
    output [31:0] pos_out,
    output pt_out,
    output [31:0] count
    );
    
    reg [31:0] position = 0;            // MAX will be +/- 2 Gig (Billion)
    reg [31:0] velocity = 0;
    reg [31:0] acceleration = 0;
    reg [31:0] count = 0;
    reg halting = 0;
    reg pt_out = 0;
    reg old_pos_bit = 0;
    wire new_pos_bit;
     
    wire [31:0] pos_next;
    wire [31:0] vel_next;
//    reg [31:0] counter = 0;
    
    wire vpos, vzero, vneg;
    wire apos, azero, aneg;

    assign vpos = ~velocity[31] && velocity > 0;
    assign vneg = velocity[31];
    assign vzero = ~|velocity;

    assign apos = ~acceleration[31] && acceleration > 0;
    assign aneg = acceleration[31];
    assign azero = ~|acceleration;
   
    assign new_pos_bit = position[15];
    
    always @(posedge clock)
        begin
        if(reset)
          {old_pos_bit, pt_out, count} = 0;
        else
            begin
            old_pos_bit <= new_pos_bit;
            pt_out = new_pos_bit ^ old_pos_bit;
            if(pt_out)
                begin
                if(vpos)
                    count = count + 1;
                else if (vneg)
                    count = count - 1;    
                end
            end
        end
    
    assign pos_out = position;
    assign pos_next = position + velocity;    
    assign vel_next = velocity + acceleration;
 
    parameter VELMAXPLUS  =  8192;
    parameter VELMAXMINUS = -VELMAXPLUS;
    parameter POSMAXPLUS = 32'h7fffffff;
    parameter POSMAXMINUS = -POSMAXPLUS;
    parameter ACCELMAXPLUS = 10;
    parameter ACCELMAXMINUS = -10;
     
    always @(posedge clock)
        begin
        if(reset)
            begin
            {position, velocity, acceleration, halting} = 0;
            end
        else
            begin
            if(halt)
                halting = 1;
                
            
            if(halting)
                begin
                if(vzero)
                    begin
                        acceleration = 0;
                        velocity = 0;  
                        halting = 0; 
                    end
                else if(vpos)
                    begin
                    if(apos)
                        acceleration = 0;
                    else if(velocity >= ACCELMAXPLUS)
                        acceleration = ACCELMAXMINUS;
                    else  
                        acceleration = - velocity;
                    velocity = velocity + acceleration;   
                    end
                else if(vneg)
                    begin
                    if(aneg)
                        acceleration = 0;
                    else if(velocity <= ACCELMAXMINUS)
                        acceleration = ACCELMAXPLUS;
                    else  
                        acceleration = - velocity;
                    velocity = velocity + acceleration;   
                    end
                end
            
            else
                begin    
                if(vel_load)
                    velocity = vel_in;            
                else if (vneg && aneg && vel_next <= VELMAXMINUS)
                    begin
                        velocity = VELMAXMINUS;
                        acceleration = 0;
                    end
                else if (vpos && apos && vel_next >= VELMAXPLUS)
                    begin
                        velocity = VELMAXPLUS;
                        acceleration = 0;
                    end
                      
                else
                    velocity = velocity + acceleration;   
               end
           
            if(pos_load)
                position = pos_in;
            else if(position[31] == 1 && vneg && pos_next[31] == 0)        // rolling too negative
                begin
                position = POSMAXMINUS;                             // saturate at full value
                velocity = 0;
                acceleration = 0;
                end
            else if(position[31] == 0 && vpos && pos_next[31] == 1)        // rolling too positive
                begin
                position = POSMAXPLUS;                             // saturate at full value
                velocity = 0;
                acceleration = 0;
                end
            else 
                position = pos_next;
                        
                           
            if(accel_load)
                acceleration = accel_in;
                     
            end
        end
endmodule
