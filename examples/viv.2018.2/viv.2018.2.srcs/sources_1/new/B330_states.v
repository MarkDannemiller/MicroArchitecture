`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    20:03:13 03/18/2018 
// Design Name: 
// Module Name:    states 
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
module states(
    input clock,
    input reset,
    input in1,
    input in2,
    output reg out1,
    output reg out2
    );

reg [2:0] state = 0;

initial begin out1 = 0; out2 = 0; end

always @ (posedge clock)
	begin
		if(reset)
			{state, out1, out2} = 0;
		else
			begin
				case (state)
					0: if(in1)  		{state, out1, out2} <= {3'd0,  1'b0,  1'b0};		// heavy vector representations
						else				{state, out1, out2} <= {3'd1, ~out1,  1'b0};
					1: if(in2)  		{state, out1, out2} <= {3'd1,  1'b0,  1'b0};
						else				{state, out1, out2} <= {3'd2,  1'b0,  1'b0};
					2: if(in1 | in2)  {state, out1, out2} <= {3'd3,  1'b0,  1'b0};
						else				{state, out1, out2} <= {3'd4,  1'b0,  1'b0};
					3: if(in1)  		{state, out1, out2} <= {3'd2,  1'b0,  1'b1};
						else				{state, out1, out2} <= {3'd5,  1'b0,  1'b0};
					4: if(in2)  		{state, out1, out2} <= {3'd2,  1'b0,  1'b0};
						else				{state, out1, out2} <= {3'd6,  1'b0,  1'b0};
					5: if(in1 & in2)  {state, out1, out2} <= {3'd5,  1'b0,  1'b0};
						else				{state, out1, out2} <= {3'd6,  1'b0,  1'b0};
					6: 					{state, out1, out2} <= {3'd7,  1'b1,  1'b0};
					7: if(in2)  		{state, out1, out2} <= {3'd7,  1'b0, ~out2};
						else				{state, out1, out2} <= {3'd7,  1'b1,  1'b0};
				endcase
			end
	end
	

endmodule
