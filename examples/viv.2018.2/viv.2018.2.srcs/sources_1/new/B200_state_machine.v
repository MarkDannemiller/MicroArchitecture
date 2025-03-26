`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:48:19 08/30/2018 
// Design Name: 
// Module Name:    B200_state_machine 
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
module state_machine(
    input clk,
    input reset,
    input signal1,
    input signal2,
    output reg actuator1,
    output reg actuator2
    );

wire [1:0] things;

reg [2:0] state = 0;							// real DFF
reg [2:0] nextstate = 0;

always @(posedge clk)
	begin
		if(reset)
			begin
				state <= 0;						// <= is reset of real flop with real clock edge
			end
		else
			state <= nextstate;				// <= is the actual setting of the state D-FF with real clock edge
	end

always @(*)										// determination of future state given circumstances at this instant
	begin
				actuator1 = 0;					// = is setting thing I have to remember for a while but not a real D-FF
				actuator2 = 0;					// = is setting thing I have to remember for a while
		case (state)
			0:
				begin
					if (signal1 == 1)
						nextstate = 1;
					else
						nextstate = 0;
				end
			1:
				begin
					if (signal1 == 1)
						nextstate = 1;
					else
						nextstate = 2;
				end
			2:
				begin
					actuator1 = 1;
					if (signal1 == 1)
						nextstate = 2;
					else
						nextstate = 3;
				end
			3:
				begin
					if (signal2 == 1)
						nextstate = 4;
					else
						nextstate = 3;
				end
			4:
				begin
						nextstate = 5;
				end
			5:
				begin
					actuator2 = 1;
					if (signal2 == 1)
						nextstate = 6;
					else
						nextstate = 0;
				end
			6:
				begin
						nextstate = 0;
				end
			7:
				begin
					if (signal1 == 1)
						nextstate = 7;
					else
						nextstate = 0;
				end
		endcase
	end

endmodule
