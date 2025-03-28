module functionUnit(
    input wire [31:0] A,     // First operand
    input wire [31:0] B,     // Second operand
    input wire [4:0] FS,     // Function select
    input wire [4:0] SH,     // Shift amount
    output wire [31:0] F,    // Result
    output wire Z,           // Zero flag
    output wire C,           // Carry flag
    output wire V,           // Overflow flag
    output wire N            // Negative flag
);
    /*
     * Function Unit Module - Pipeline Stage: Execute (EX)
     * 
     * This module executes the arithmetic and logical operations specified by FS.
     * The flags (Z, C, V, N) are used for conditional branching and the SLT instruction.
     * For barrel shifter operations, the SH value determines the shift amount.
     * 
     * Function select codes (FS):
     * 00000 - NOP / MOV (pass through A)
     * 00010 - ADD (A + B)
     * 00101 - SUB (A - B)
     * 00111 - JML (PC+1 for jump and link)
     * 01000 - AND (A & B)
     * 01010 - OR (A | B)
     * 01100 - XOR (A ^ B)
     * 01110 - NOT (~A)
     * 10100 - LSL (A << SH)
     * 11000 - LSR (A >> SH)
     */

    // Local parameters for function select codes
    localparam FS_NOP = 5'b00000; // NOP/MOV
    localparam FS_MOV = 5'b00000; // MOV is now FS=00000
    localparam FS_ADD = 5'b00010; // Add
    localparam FS_SUB = 5'b00101; // Subtract
    localparam FS_JML = 5'b00111; // Jump and link
    localparam FS_AND = 5'b01000; // AND
    localparam FS_OR  = 5'b01010; // OR
    localparam FS_XOR = 5'b01100; // XOR
    localparam FS_NOT = 5'b01110; // NOT
    localparam FS_LSL = 5'b10100; // Logical shift left
    localparam FS_LSR = 5'b11000; // Logical shift right

    // Internal wires
    reg [31:0] result;
    reg carry_out;
    reg overflow;
    
    // ALU operation
    always @(*) begin
        // Default values
        carry_out = 0;
        overflow = 0;
        
        // Enhanced debug output
        $display("ALU OPERATION: FS=%b (%h), A=%h, B=%h", FS, FS, A, B);
        
        case (FS)
            FS_MOV, FS_NOP: begin
                result = A;           // Pass A to output (correct for MOV)
                $display("ALU DEBUG: MOV/NOP - Output = A = %h", result);
            end
            FS_JML: begin
                result = A;           // Pass A to output for jump and link
                $display("ALU DEBUG: JML - Output = A = %h", result);
            end
            FS_ADD: begin
                {carry_out, result} = {1'b0, A} + {1'b0, B};  // Addition with carry
                // Check for overflow in signed addition
                overflow = (A[31] == B[31]) && (result[31] != A[31]);
                $display("ALU DEBUG: ADD - A(%h) + B(%h) = %h, carry=%b, overflow=%b", A, B, result, carry_out, overflow);
            end
            FS_SUB: begin
                {carry_out, result} = {1'b0, A} - {1'b0, B};  // Subtraction with borrow
                // Check for overflow in signed subtraction
                overflow = (A[31] != B[31]) && (result[31] != A[31]);
                $display("ALU DEBUG: SUB - A(%h) - B(%h) = %h, carry=%b, overflow=%b", A, B, result, carry_out, overflow);
            end
            FS_AND: begin
                // Logical AND
                result = A & B;
                $display("ALU DEBUG: AND - A(%h) & B(%h) = %h", A, B, result);
            end
            FS_OR: begin
                // Logical OR
                result = A | B;
                $display("ALU DEBUG: OR - A(%h) | B(%h) = %h", A, B, result);
            end
            FS_XOR: begin
                // Logical XOR
                result = A ^ B;
                $display("ALU DEBUG: XOR - A(%h) ^ B(%h) = %h", A, B, result);
            end
            FS_NOT: begin
                // Logical NOT
                result = ~A;
                $display("ALU DEBUG: NOT - ~A(%h) = %h", A, result);
            end
            FS_LSL: begin
                // Logical Shift Left (barrel shifter)
                result = A << SH;
                // Capture the last bit shifted out for carry
                if (SH > 0 && SH <= 32)
                    carry_out = (SH == 32) ? A[0] : A[32-SH];
                $display("ALU DEBUG: LSL - A(%h) << SH(%d) = %h", A, SH, result);
            end
            FS_LSR: begin
                // Logical Shift Right (barrel shifter)
                result = A >> SH;
                // Capture the last bit shifted out for carry
                if (SH > 0 && SH <= 32)
                    carry_out = (SH == 32) ? A[31] : A[SH-1];
                $display("ALU DEBUG: LSR - A(%h) >> SH(%d) = %h", A, SH, result);
            end
            default: begin
                // Undefined operation - set to x for debugging
                result = 32'hxxxxxxxx;
                carry_out = 1'bx;
                overflow = 1'bx;
                $display("ALU DEBUG: UNKNOWN OPERATION - FS=%b", FS);
            end
        endcase
    end

    // Assign outputs
    assign F = result;
    assign Z = (result == 32'h00000000);
    assign C = carry_out;
    assign V = overflow;
    assign N = result[31];

endmodule
