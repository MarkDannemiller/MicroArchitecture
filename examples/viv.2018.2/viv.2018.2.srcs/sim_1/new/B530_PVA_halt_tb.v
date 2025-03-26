`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/14/2020 10:36:15 AM
// Design Name: 
// Module Name: B421_PVA_halt_tb
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


module B530_PVA_halt_tb();

reg clock = 0;
reg reset = 0;
reg [31:0] pos_in = 0;
reg pos_load = 0;
reg [31:0] vel_in = 0;
reg vel_load = 0;
reg [31:0] accel_in = 0;
reg accel_load = 0;
reg halt = 0;
wire [31:0] pos_out;
wire pt_out;
wire  [31:0] count;

PVA UUT(clock, reset, pos_in, pos_load, vel_in, vel_load, accel_in, accel_load, halt, pos_out, pt_out, count);

always
    #5 clock = ~clock;
    
initial
    begin
        #100
        reset = 1;
        #100
        reset = 0;
        #10
        pos_load = 1;
        pos_in = 1000;
        #10
        pos_load = 0;
        #100
        vel_load = 1;
        vel_in = 5000;
        #10
        vel_load = 0;
        #10000
        halt = 1;
        #10
        halt = 0;

        #10000
        vel_load = 1;
        vel_in = 5005;
        #10
        vel_load = 0;
        #10000
        halt = 1;
        #10
        halt = 0;

        #100000
        vel_load = 1;
        vel_in = -5000;
        #10
        vel_load = 0;
        #10000
        halt = 1;
        #10
        halt = 0;

        #100000
        vel_load = 1;
        vel_in = -5005;
        #10
        vel_load = 0;
        #10000
        halt = 1;
        #10
        halt = 0;

        #100000
        accel_load = 1;
        accel_in = -10;
        #10
        accel_load = 0;
        #110000
        halt = 1;
        #10
        halt = 0;


     end
    


endmodule
