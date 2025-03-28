module muxA(
    input wire [31:0] A_data,    // Register A data
    input wire [31:0] PC_1,      // PC+1 value
    input wire MA,               // Mux A select (0: A_data, 1: PC_1)
    output reg [31:0] out        // Mux A output
);
    /*
     * Mux A - Pipeline Stage: Decode and Operand Fetch (DOF)
     * 
     * This multiplexer selects the first operand for the ALU:
     * - If MA = 0, A_data (from register file) is selected
     * - If MA = 1, PC_1 (PC + 1) is selected for JML instructions
     */

    always @(*) begin
        case (MA)
            1'b0: out = A_data;
            1'b1: out = PC_1;
            default: out = 32'hx;  // For simulation, mark invalid selections
        endcase
        
        // Debug output
        $display("MUXA DEBUG: MA=%b, A_data=%h, PC_1=%h, out=%h", MA, A_data, PC_1, out);
    end

endmodule
