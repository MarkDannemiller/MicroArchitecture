//`include "debug_defs.v"
//`include "definitions.v"

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

    // Decode instruction
    always @(*) begin

        if (`DEBUG_DECODER) begin
            $display("DECODER DEBUG: opcode=%b [%h], RW=%b, FS=%h, MB=%b, MA=%b, BS=%b",
                     opcode, opcode, RW, FS, MB, MA, BS);
        end

        // Default values
        RW = 1'b0;    // No register write
        MD = 2'b00;   // ALU result
        MW = 1'b0;    // No memory write
        BS = 2'b00;   // No branch
        PS = 1'b0;    // Normal branch condition
        FS = 5'h0;    // NOP operation
        MB = 1'b0;    // Select register B
        MA = 1'b0;    // Select register A
        CS = 1'b0;    // No sign extension

        // Decode opcode
        case (opcode)
            `OP_NOP: begin    // No operation
                RW = 1'b0;    // No register write
                MW = 1'b0;    // No memory write
                if (`DEBUG_DECODER) $display("DECODER DEBUG: Found NOP instruction");
            end
            `OP_ADD: begin    // Add: Add two register values
                RW = 1'b1;    // Write to register
                MD = 2'b00;   // ALU result
                BS = 2'b00;   // No branch
                MW = 1'b0;    // No memory write
                FS = 5'b00010; // ADD operation
                MB = 1'b0;    // Select register B
                MA = 1'b0;    // Select register A
                if (`DEBUG_DECODER) $display("DECODER DEBUG: Found ADD instruction");
            end
            `OP_SUB: begin    // Subtract: Subtract two register values
                RW = 1'b1;    // Write to register
                MD = 2'b00;   // ALU result
                BS = 2'b00;   // No branch
                MW = 1'b0;    // No memory write
                FS = 5'b00101; // SUB operation
                MB = 1'b0;    // Select register B
                MA = 1'b0;    // Select register A
                if (`DEBUG_DECODER) $display("DECODER DEBUG: Found SUB instruction");
            end
            `OP_SLT: begin    // Set Less Than: Set destination to 1 if source1 < source2 (signed)
                RW = 1'b1;    // Write to register
                MD = 2'b10;   // N⊕V for SLT
                BS = 2'b00;   // No branch
                MW = 1'b0;    // No memory write
                FS = 5'b00101; // SUB operation for comparison
                MB = 1'b0;    // Select register B
                MA = 1'b0;    // Select register A
                if (`DEBUG_DECODER) $display("DECODER DEBUG: Found SLT instruction");
            end
            `OP_AND: begin    // Logical AND: Bitwise AND of two register values
                RW = 1'b1;    // Write to register
                MD = 2'b00;   // ALU result
                BS = 2'b00;   // No branch
                MW = 1'b0;    // No memory write
                FS = 5'b01000; // AND operation
                MB = 1'b0;    // Select register B
                MA = 1'b0;    // Select register A
                if (`DEBUG_DECODER) $display("DECODER DEBUG: Found AND instruction");
            end
            `OP_OR: begin     // Logical OR: Bitwise OR of two register values
                RW = 1'b1;    // Write to register
                MD = 2'b00;   // ALU result
                BS = 2'b00;   // No branch
                MW = 1'b0;    // No memory write
                FS = 5'b01010; // OR operation
                MB = 1'b0;    // Select register B
                MA = 1'b0;    // Select register A
                if (`DEBUG_DECODER) $display("DECODER DEBUG: Found OR instruction");
            end
            `OP_XOR: begin    // Logical XOR: Bitwise XOR of two register values
                RW = 1'b1;    // Write to register
                MD = 2'b00;   // ALU result
                BS = 2'b00;   // No branch
                MW = 1'b0;    // No memory write
                FS = 5'b01100; // XOR operation
                MB = 1'b0;    // Select register B
                MA = 1'b0;    // Select register A
                if (`DEBUG_DECODER) $display("DECODER DEBUG: Found XOR instruction");
            end
            `OP_ST: begin     // Store: Store register value to memory
                RW = 1'b0;    // No register write
                MD = 2'b00;   // ALU result
                BS = 2'b00;   // No branch
                MW = 1'b1;    // Memory write
                FS = 5'b00000; // NOP operation
                MB = 1'b0;    // Select register B
                MA = 1'b0;    // Select register A
                if (`DEBUG_DECODER) $display("DECODER DEBUG: Found ST instruction");
            end
            `OP_LD: begin     // Load: Load value from memory to register
                RW = 1'b1;    // Write to register
                MD = 2'b01;   // Memory data
                BS = 2'b00;   // No branch
                MW = 1'b0;    // No memory write
                FS = 5'b00000; // NOP operation
                MA = 1'b0;    // Select register A
                if (`DEBUG_DECODER) $display("DECODER DEBUG: Found LD instruction");
            end
            `OP_ADI: begin    // Add Immediate: Add register value with immediate value (signed)
                RW = 1'b1;    // Write to register
                MD = 2'b00;   // ALU result
                BS = 2'b00;   // No branch
                MW = 1'b0;    // No memory write
                FS = 5'b00010; // ADD operation
                MB = 1'b1;    // Select immediate
                MA = 1'b0;    // Select register A
                CS = 1'b1;    // Sign extend immediate
                if (`DEBUG_DECODER) $display("DECODER DEBUG: Found ADI instruction");
            end
            `OP_SBI: begin    // Subtract Immediate: Subtract immediate value from register (signed)
                RW = 1'b1;    // Write to register
                MD = 2'b00;   // ALU result
                BS = 2'b00;   // No branch
                MW = 1'b0;    // No memory write
                FS = 5'b00101; // SUB operation
                MB = 1'b1;    // Select immediate
                MA = 1'b0;    // Select register A
                CS = 1'b1;    // Sign extend immediate
                if (`DEBUG_DECODER) $display("DECODER DEBUG: Found SBI instruction");
            end
            `OP_NOT: begin    // Logical NOT: Bitwise complement of register value
                RW = 1'b1;    // Write to register
                MD = 2'b00;   // ALU result
                BS = 2'b00;   // No branch
                MW = 1'b0;    // No memory write
                FS = 5'b01110; // NOT operation
                MA = 1'b0;    // Select register A
                if (`DEBUG_DECODER) $display("DECODER DEBUG: Found NOT instruction");
            end
            `OP_ANI: begin    // AND Immediate: Bitwise AND of register with immediate value
                RW = 1'b1;    // Write to register
                MD = 2'b00;   // ALU result
                BS = 2'b00;   // No branch
                MW = 1'b0;    // No memory write
                FS = 5'b01000; // AND operation
                MB = 1'b1;    // Select immediate
                MA = 1'b0;    // Select register A
                if (`DEBUG_DECODER) $display("DECODER DEBUG: Found ANI instruction");
            end
            `OP_ORI: begin    // OR Immediate: Bitwise OR of register with immediate value
                RW = 1'b1;    // Write to register
                MD = 2'b00;   // ALU result
                BS = 2'b00;   // No branch
                MW = 1'b0;    // No memory write
                FS = 5'b01010; // OR operation
                MB = 1'b1;    // Select immediate
                MA = 1'b0;    // Select register A
                if (`DEBUG_DECODER) $display("DECODER DEBUG: Found ORI instruction");
            end
            `OP_XRI: begin    // XOR Immediate: Bitwise XOR of register with immediate value
                RW = 1'b1;    // Write to register
                MD = 2'b00;   // ALU result
                BS = 2'b00;   // No branch
                MW = 1'b0;    // No memory write
                FS = 5'b01100; // XOR operation
                MB = 1'b1;    // Select immediate
                MA = 1'b0;    // Select register A
                if (`DEBUG_DECODER) $display("DECODER DEBUG: Found XRI instruction");
            end
            `OP_AIU: begin    // Add Immediate Unsigned: Add register with immediate (unsigned)
                RW = 1'b1;    // Write to register
                MD = 2'b00;   // ALU result
                BS = 2'b00;   // No branch
                MW = 1'b0;    // No memory write
                FS = 5'b00010; // ADD operation
                MB = 1'b1;    // Select immediate
                MA = 1'b0;    // Select register A
                if (`DEBUG_DECODER) $display("DECODER DEBUG: Found AIU instruction");
            end
            `OP_SIU: begin    // Subtract Immediate Unsigned: Subtract immediate from register (unsigned)
                RW = 1'b1;    // Write to register
                MD = 2'b00;   // ALU result
                BS = 2'b00;   // No branch
                MW = 1'b0;    // No memory write
                FS = 5'b00101; // SUB operation
                MB = 1'b1;    // Select immediate
                MA = 1'b0;    // Select register A
                if (`DEBUG_DECODER) $display("DECODER DEBUG: Found SIU instruction");
            end
            `OP_MOV: begin    // Move Register: Copy value from source to destination register
                RW = 1'b1;    // Write to register
                MD = 2'b00;   // ALU result
                BS = 2'b00;   // No branch
                MW = 1'b0;    // No memory write
                FS = 5'b00000; // MOV operation
                MA = 1'b0;    // Select register A
                if (`DEBUG_DECODER) $display("DECODER DEBUG: Found MOV instruction");
            end
            `OP_LSL: begin    // Logical Shift Left: Shift register value left by immediate amount
                RW = 1'b1;    // Write to register
                MD = 2'b00;   // ALU result
                BS = 2'b00;   // No branch
                MW = 1'b0;    // No memory write
                FS = 5'b10100; // LSL operation
                MA = 1'b0;    // Select register A
                if (`DEBUG_DECODER) $display("DECODER DEBUG: Found LSL instruction");
            end
            `OP_LSR: begin    // Logical Shift Right: Shift register value right by immediate amount
                RW = 1'b1;    // Write to register
                MD = 2'b00;   // ALU result
                BS = 2'b00;   // No branch
                MW = 1'b0;    // No memory write
                FS = 5'b11000; // LSR operation
                MA = 1'b0;    // Select register A
                if (`DEBUG_DECODER) $display("DECODER DEBUG: Found LSR instruction");
            end
            `OP_JMR: begin    // Jump Register: Jump to address in register
                RW = 1'b0;    // No register write
                BS = 2'b10;   // Register jump
                MW = 1'b0;    // No memory write
                FS = 5'b00000; // NOP operation
                MA = 1'b0;    // Select register A
                if (`DEBUG_DECODER) $display("DECODER DEBUG: Found JMR instruction");
            end
            `OP_BZ: begin     // Branch if Zero: Branch if result is zero
                RW = 1'b0;    // No register write
                BS = 2'b01;   // Conditional branch
                PS = 1'b0;    // Branch if zero
                MW = 1'b0;    // No memory write
                FS = 5'b00000; // NOP operation
                MB = 1'b1;    // Select immediate
                MA = 1'b0;    // Select register A
                CS = 1'b1;    // Sign extend immediate
                if (`DEBUG_DECODER) $display("DECODER DEBUG: Found BZ instruction");
            end
            `OP_BNZ: begin    // Branch if Not Zero: Branch if result is non-zero
                RW = 1'b0;    // No register write
                BS = 2'b01;   // Conditional branch
                PS = 1'b1;    // Branch if not zero
                MW = 1'b0;    // No memory write
                FS = 5'b00000; // NOP operation
                MB = 1'b1;    // Select immediate
                MA = 1'b0;    // Select register A
                CS = 1'b1;    // Sign extend immediate
                if (`DEBUG_DECODER) $display("DECODER DEBUG: Found BNZ instruction");
            end
            `OP_JMP: begin    // Jump: Jump to immediate address
                RW = 1'b0;    // No register write
                BS = 2'b11;   // Direct jump
                MW = 1'b0;    // No memory write
                MB = 1'b1;    // Select immediate
                CS = 1'b1;    // Sign extend immediate
                if (`DEBUG_DECODER) $display("DECODER DEBUG: Found JMP instruction");
            end
            `OP_JML: begin    // Jump and Link: Jump to immediate address and save return address
                RW = 1'b1;    // Write to register
                MD = 2'b00;   // ALU result
                BS = 2'b11;   // Direct jump
                MW = 1'b0;    // No memory write
                FS = 5'b00111; // JML operation
                MB = 1'b1;    // Select immediate
                MA = 1'b1;    // Select PC+1
                CS = 1'b1;    // Sign extend immediate
                if (`DEBUG_DECODER) $display("DECODER DEBUG: Found JML instruction");
            end
            default: begin    // Invalid instruction - treat as NOP instead of setting to x
                RW = 1'b0;    // No register write
                MD = 2'b00;   // ALU result
                BS = 2'b00;   // No branch
                PS = 1'b0;    // Normal branch condition
                MW = 1'b0;    // No memory write
                FS = 5'h0;    // NOP operation
                MB = 1'b0;    // Select register B
                MA = 1'b0;    // Select register A
                CS = 1'b0;    // No sign extension
                $display("\n\n\nDECODER DEBUG: Invalid instruction detected (opcode=%b), treating as NOP\n\n\n", opcode);
            end
        endcase
    end

endmodule 