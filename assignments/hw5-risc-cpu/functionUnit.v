module functionUnit(
    input wire [4:0] FS,      // Function select
    input wire [31:0] A,      // First operand
    input wire [31:0] B,      // Second operand
    input wire [4:0] SH,      // Shift amount
    output reg [31:0] F,      // Result
    output reg C,             // Carry flag
    output reg V,             // Overflow flag
    output reg N,             // Negative flag
    output reg Z              // Zero flag
);
    /*
     * Function Unit (ALU) - Pipeline Stage: Execute (EX)
     * 
     * This module represents the Execute stage of the pipeline, performing all
     * arithmetic, logical, and shift operations. It includes:
     * - Arithmetic operations (ADD, SUB) with overflow detection
     * - Logical operations (AND, OR, XOR, NOT)
     * - Shift operations (LSL, LSR) with carry out
     * - Flag generation (Zero, Negative, Carry, Overflow)
     * 
     * The function unit is purely combinational, computing results within
     * a single clock cycle. Results and flags are used by subsequent pipeline
     * stages and for branch condition evaluation.
     */

    // Internal wires for extended results
    wire [32:0] add_result;
    wire [32:0] sub_result;

    // Extended arithmetic operations
    assign add_result = {1'b0, A} + {1'b0, B};
    assign sub_result = {1'b0, A} - {1'b0, B};

    // Function Select codes
    localparam FS_NOP  = 5'b00000;
    localparam FS_MOV  = 5'b00001;
    localparam FS_ADD  = 5'b00010;
    localparam FS_SUB  = 5'b00101;
    localparam FS_AND  = 5'b01000;
    localparam FS_OR   = 5'b01010;
    localparam FS_XOR  = 5'b01100;
    localparam FS_NOT  = 5'b01110;
    localparam FS_LSL  = 5'b10100;
    localparam FS_LSR  = 5'b11000;

    // Main ALU operation
    always @(*) begin
        case (FS)
            FS_NOP: begin
                F = 32'h00000000;
                C = 1'b0;
                V = 1'b0;
            end
            FS_MOV: begin
                F = A;
                C = 1'b0;
                V = 1'b0;
            end
            FS_ADD: begin
                F = A + B;
                C = add_result[32];
                V = (~A[31] & ~B[31] & F[31]) | (A[31] & B[31] & ~F[31]);
            end
            FS_SUB: begin
                F = A - B;
                C = sub_result[32];
                V = (~A[31] & B[31] & F[31]) | (A[31] & ~B[31] & ~F[31]);
            end
            FS_AND: begin
                F = A & B;
                C = 1'b0;
                V = 1'b0;
            end
            FS_OR: begin
                F = A | B;
                C = 1'b0;
                V = 1'b0;
            end
            FS_XOR: begin
                F = A ^ B;
                C = 1'b0;
                V = 1'b0;
            end
            FS_NOT: begin
                F = ~A;
                C = 1'b0;
                V = 1'b0;
            end
            FS_LSL: begin
                F = A << SH;
                C = (SH > 0) ? A[32-SH] : 1'b0;
                V = 1'b0;
            end
            FS_LSR: begin
                F = A >> SH;
                C = (SH > 0) ? A[SH-1] : 1'b0;
                V = 1'b0;
            end
            default: begin
                F = 32'h00000000;
                C = 1'b0;
                V = 1'b0;
            end
        endcase

        // Set Zero flag
        Z = (F == 32'h00000000);
        
        // Set Negative flag
        N = F[31];
    end

endmodule
