// From B310_posnotedge.v example

module posnotedge(
    input signal,
	 input clock,
    output reg edgeplus,
	 output reg edgeminus
    );
	 
initial 
	begin
		edgeplus = 0;
		edgeminus = 0;
	end
reg oldsignal = 0;

always @(posedge clock)
	begin
		oldsignal <= signal;
	end

always @(*)
  begin
	if(signal == 1 & oldsignal == 0)		// rising edges
	  edgeplus = 1;
	else
	  edgeplus = 0;
	if(signal == 0 & oldsignal == 1)		// falling edges
	  edgeminus = 1;
	else
	  edgeminus = 0;
  end

endmodule