module muxC(
    input wire [15:0] PC_1,      // PC+1 value
    input wire [15:0] BrA,       // Branch address
    input wire [15:0] RAA,       // Register A address
    input wire [15:0] JMP,       // Jump address
    input wire [1:0] BS,         // Branch Select
    input wire [1:0] PS,         // Program Select
    input wire Z,                // Zero flag
    output wire [15:0] out       // Selected output
);
    /*
     * Multiplexer C - Pipeline Stage: Instruction Fetch (IF)
     * 
     * This multiplexer controls program flow by selecting the next PC value:
     * - PC+1: Sequential execution
     * - BrA: Conditional branch target
     * - RAA: Register-based jump target (JMR)
     * - JMP: Immediate jump target
     * 
     * It operates between IF stages to determine the next instruction address.
     * The selection is controlled by BS (Branch Select) and PS (Program Select)
     * signals, with Z flag input for conditional branches. This module is
     * critical for implementing the control flow instructions.
     */

    reg [15:0] next_pc;

    // Branch and jump control logic
    always @(*) begin
        case (BS)
            2'b00: begin  // Sequential execution
                next_pc = PC_1;
            end
            2'b01: begin  // Conditional branch
                if ((PS[0] && Z) || (PS[1] && !Z))
                    next_pc = BrA;
                else
                    next_pc = PC_1;
            end
            2'b10: begin  // Jump register
                next_pc = RAA;
            end
            2'b11: begin  // Unconditional jump
                next_pc = JMP;
            end
        endcase
    end

    assign out = next_pc;

endmodule
