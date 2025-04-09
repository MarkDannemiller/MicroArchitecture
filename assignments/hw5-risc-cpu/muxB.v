module muxB(
    input wire [31:0] B_data,      // Register B data
    input wire [31:0] constant,    // Immediate constant value
    input wire MB,                 // Mux B select (0: B_data, 1: constant)
    output reg [31:0] out          // Mux B output
);
    /*
     * Mux B - Pipeline Stage: Decode and Operand Fetch (DOF)
     * 
     * This multiplexer selects the second operand for the ALU:
     * - If MB = 0, B_data (from register file) is selected
     * - If MB = 1, constant (from constant unit) is selected
     */

    always @(*) begin
        case (MB)
            1'b0: out = B_data;
            1'b1: out = constant;
            default: out = 32'hx;  // For simulation, mark invalid selections
        endcase
        
        // Debug output
        if(`DEBUG_MUXB) begin
            $display("MUXB DEBUG: MB=%b, B_data=%h, constant=%h, out=%h", MB, B_data, constant, out);
        end
    end

endmodule
