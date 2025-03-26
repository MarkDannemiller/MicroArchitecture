`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    21:02:24 03/18/2018 
// Design Name: 
// Module Name:    mod2 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module mod2(
    input clock,
    input reset,
    input start,
    output reg finish,
	 output [1:0] pins
    );

reg [2:0] statetop = 0;
reg go1 = 0;
wire done1;
reg go2 = 0;
wire done2;

assign pins = {done1, done2};

initial finish = 0;

	mod1 U1 (							// first instance called U1
		.clock(clock), 
		.reset(reset), 
		.go(go1), 
		.done(done1)
	);
	
		mod1 U2 (						// second instance called U2
		.clock(clock), 
		.reset(reset), 
		.go(go2), 
		.done(done2)
	);

	always @(posedge clock)
		begin
			if(reset)
				begin
					{statetop, go1, go2, finish}  <= 0;		// nice syntax for mass reset
				end
			else
				begin
					case(statetop)
						0:	begin										// clear it all out to start over
							statetop <= 1;
							go1 <= 0;
							go2 <= 0;
							finish <= 0;
							end
						1: 
							begin
								if(start) 							// time to start doing your thing
									begin								// let U1 do its thing
										statetop <= 2;
										go1 <= 1;
									end
							end
						2:
							begin
								go1 <= 0;
								if(done1) statetop <= 3;		// U1 is done with its thing
							end
						3:
							begin
								statetop <= 4;
								go2 <= 1;							// let U2 do its thing
							end
						4:
						
							begin
								go2 <= 0;
								if(done2) statetop <= 5;		// U2 is done with its thing
							end
						5:
							statetop <= 6;							// one tick passes to delay finish
						6:
							begin
								finish <= 1;						// you are done with your thing
								statetop <= 0;
							end
					endcase
				end
		end

endmodule
