module instructionDecoder(
    input wire [6:0] opcode,        // 7-bit Opcode field from instruction
    output reg RW,                  // Register Write
    output reg [1:0] MD,            // Memory Data select (2 bits for MuxD)
    output reg MW,                  // Memory Write
    output reg [1:0] BS,            // Branch Select
    output reg PS,                  // Program Select (single bit)
    output reg [4:0] FS,            // Function Select
    output reg MB,                  // Mux B select
    output reg MA,                  // Mux A select
    output reg CS                   // Constant Select
);

    /*
     * Instruction Decoder - Pipeline Stage: Decode & Operand Fetch (DOF)
     *
     * This module decodes instruction opcodes and generates control signals.
     * The MD signal is 2 bits to support 3 options:
     * - 00: ALU result
     * - 01: Memory data
     * - 10: N⊕V for SLT
     * 
     * PS is now a single bit as it only has two states:
     * - 0: Normal branch (BZ)
     * - 1: Inverted branch condition (BNZ)
     *
     * Opcodes are now 7 bits to match the instruction format diagram.
     * 
     * For "don't care" (—) signals in the control word table:
     * - We set them to 0 for simplicity unless otherwise required
     * - For MB (MuxB select), we set it based on whether immediate value is needed
     * - For CS (Constant Select), we set it based on whether sign extension is needed
     */

    // Debug info to show opcode interpretation
    always @(*) begin
        $display("DECODER DEBUG: opcode=%b [%h], RW=%b, FS=%h, MB=%b, MA=%b, BS=%b", 
                 opcode, opcode, RW, FS, MB, MA, BS);
    end

    // Combinational logic for control signal generation
    always @(*) begin
        // Special debug for ADD
        if (opcode == 7'b0000010) begin
            $display("DECODER DEBUG: Found ADD instruction, setting RW=1, FS=00010");
        end
        
        case (opcode)
            7'b0000000: begin // NOP
                RW = 1'b0; MD = 2'b00; BS = 2'b00; PS = 1'b0; MW = 1'b0;
                FS = 5'b00000; MB = 1'b0; MA = 1'b0; CS = 1'b0;
            end
            7'b0000010: begin // ADD (was 0000100)
                RW = 1'b1; MD = 2'b00; BS = 2'b00; PS = 1'b0; MW = 1'b0;
                FS = 5'b00010; MB = 1'b0; MA = 1'b0; CS = 1'b0;
            end
            7'b0000101: begin // SUB (was 0001010)
                RW = 1'b1; MD = 2'b00; BS = 2'b00; PS = 1'b0; MW = 1'b0;
                FS = 5'b00101; MB = 1'b0; MA = 1'b0; CS = 1'b0;
            end
            7'b1100101: begin // SLT (was 1100110)
                RW = 1'b1; MD = 2'b10; BS = 2'b00; PS = 1'b0; MW = 1'b0;
                FS = 5'b00101; MB = 1'b0; MA = 1'b0; CS = 1'b0;
            end
            7'b0001000: begin // AND (was 0010000)
                RW = 1'b1; MD = 2'b00; BS = 2'b00; PS = 1'b0; MW = 1'b0;
                FS = 5'b01000; MB = 1'b0; MA = 1'b0; CS = 1'b0;
            end
            7'b0001010: begin // OR (was 0010100)
                RW = 1'b1; MD = 2'b00; BS = 2'b00; PS = 1'b0; MW = 1'b0;
                FS = 5'b01010; MB = 1'b0; MA = 1'b0; CS = 1'b0;
            end
            7'b0001100: begin // XOR (was 0011000)
                RW = 1'b1; MD = 2'b00; BS = 2'b00; PS = 1'b0; MW = 1'b0;
                FS = 5'b01100; MB = 1'b0; MA = 1'b0; CS = 1'b0;
            end
            7'b0000001: begin // ST (Store) (was 0000010)
                RW = 1'b0; MD = 2'b00; BS = 2'b00; PS = 1'b0; MW = 1'b1;
                FS = 5'b00000; MB = 1'b0; MA = 1'b0; CS = 1'b0;
            end
            7'b0100001: begin // LD (Load) (was 1000010)
                RW = 1'b1; MD = 2'b01; BS = 2'b00; PS = 1'b0; MW = 1'b0;
                FS = 5'b00000; MB = 1'b0; MA = 1'b0; CS = 1'b0;
            end
            7'b0100010: begin // ADI (Add Immediate) (was 1000100)
                RW = 1'b1; MD = 2'b00; BS = 2'b00; PS = 1'b0; MW = 1'b0;
                FS = 5'b00010; MB = 1'b1; MA = 1'b0; CS = 1'b1;
            end
            7'b0100101: begin // SBI (Subtract Immediate) (was 1001000)
                RW = 1'b1; MD = 2'b00; BS = 2'b00; PS = 1'b0; MW = 1'b0;
                FS = 5'b00101; MB = 1'b1; MA = 1'b0; CS = 1'b1;
            end
            7'b0101110: begin // NOT (was 0011110)
                RW = 1'b1; MD = 2'b00; BS = 2'b00; PS = 1'b0; MW = 1'b0;
                FS = 5'b01110; MB = 1'b0; MA = 1'b0; CS = 1'b0;
            end
            7'b0101000: begin // ANI (AND Immediate) (was 1010000)
                RW = 1'b1; MD = 2'b00; BS = 2'b00; PS = 1'b0; MW = 1'b0;
                FS = 5'b01000; MB = 1'b1; MA = 1'b0; CS = 1'b0;
            end
            7'b0101010: begin // ORI (OR Immediate) (was 1010100)
                RW = 1'b1; MD = 2'b00; BS = 2'b00; PS = 1'b0; MW = 1'b0;
                FS = 5'b01010; MB = 1'b1; MA = 1'b0; CS = 1'b0;
            end
            7'b0101100: begin // XRI (XOR Immediate) (was 1011000)
                RW = 1'b1; MD = 2'b00; BS = 2'b00; PS = 1'b0; MW = 1'b0;
                FS = 5'b01100; MB = 1'b1; MA = 1'b0; CS = 1'b0;
            end
            7'b1100010: begin // AIU (Add Immediate Unsigned) (was 1100100)
                RW = 1'b1; MD = 2'b00; BS = 2'b00; PS = 1'b0; MW = 1'b0;
                FS = 5'b00010; MB = 1'b1; MA = 1'b0; CS = 1'b0;
            end
            7'b1100101: begin // SIU (Subtract Immediate Unsigned) (was 1101000)
                RW = 1'b1; MD = 2'b00; BS = 2'b00; PS = 1'b0; MW = 1'b0;
                FS = 5'b00101; MB = 1'b1; MA = 1'b0; CS = 1'b0;
            end
            7'b1000000: begin // MOV (Move Register)
                RW = 1'b1; MD = 2'b00; BS = 2'b00; PS = 1'b0; MW = 1'b0;
                FS = 5'b00000; MB = 1'b0; MA = 1'b0; CS = 1'b0;
            end
            7'b0110000: begin // LSL (Logical Shift Left)
                RW = 1'b1; MD = 2'b00; BS = 2'b00; PS = 1'b0; MW = 1'b0;
                FS = 5'b10100; MB = 1'b0; MA = 1'b0; CS = 1'b0;
            end
            7'b0110001: begin // LSR (Logical Shift Right) (was 0110010)
                RW = 1'b1; MD = 2'b00; BS = 2'b00; PS = 1'b0; MW = 1'b0;
                FS = 5'b11000; MB = 1'b0; MA = 1'b0; CS = 1'b0;
            end
            7'b1100001: begin // JMR (Jump Register) (was 1110000)
                RW = 1'b0; MD = 2'b00; BS = 2'b10; PS = 1'b0; MW = 1'b0;
                FS = 5'b00000; MB = 1'b0; MA = 1'b0; CS = 1'b0;
            end
            7'b0100000: begin // BZ (Branch if Zero) (was 1000000)
                RW = 1'b0; MD = 2'b00; BS = 2'b01; PS = 1'b0; MW = 1'b0;
                FS = 5'b00000; MB = 1'b1; MA = 1'b0; CS = 1'b1;
            end
            7'b1100000: begin // BNZ (Branch if Not Zero)
                RW = 1'b0; MD = 2'b00; BS = 2'b01; PS = 1'b1; MW = 1'b0;
                FS = 5'b00000; MB = 1'b1; MA = 1'b0; CS = 1'b1;
            end
            7'b1000100: begin // JMP (Jump Immediate) (was 1001100)
                RW = 1'b0; MD = 2'b00; BS = 2'b11; PS = 1'b0; MW = 1'b0;
                FS = 5'b00000; MB = 1'b1; MA = 1'b0; CS = 1'b1;
            end
            7'b0000111: begin // JML (Jump and Link)
                RW = 1'b1; MD = 2'b00; BS = 2'b11; PS = 1'b0; MW = 1'b0;
                FS = 5'b00111; MB = 1'b1; MA = 1'b1; CS = 1'b1;
            end
            default: begin // Invalid instruction - set all signals to x (error)
                RW = 1'bx; MD = 2'bxx; BS = 2'bxx; PS = 1'bx; MW = 1'bx;
                FS = 5'bxxxxx; MB = 1'bx; MA = 1'bx; CS = 1'bx;
            end
        endcase
    end

endmodule 