// Instruction Opcodes (7 bits)
`define OP_NOP     7'b0000000
`define OP_ADD     7'b0000010
`define OP_SUB     7'b0000101
`define OP_SLT     7'b1100101
`define OP_AND     7'b0001000
`define OP_OR      7'b0001010
`define OP_XOR     7'b0001100
`define OP_ST      7'b0000001
`define OP_LD      7'b0100001
`define OP_ADI     7'b0100010
`define OP_SBI     7'b0100101
`define OP_NOT     7'b0101110
`define OP_ANI     7'b0101000
`define OP_ORI     7'b0101010
`define OP_XRI     7'b0101100
`define OP_AIU     7'b1100010
`define OP_SIU     7'b1000101
`define OP_MOV     7'b1000000
`define OP_LSL     7'b0110000
`define OP_LSR     7'b0110001
`define OP_JMR     7'b1100001
`define OP_BZ      7'b0100000
`define OP_BNZ     7'b1100000
`define OP_JMP     7'b1000100
`define OP_JML     7'b0000111

// Register Numbers (5 bits)
`define R0         5'd0
`define R1         5'd1
`define R2         5'd2
`define R3         5'd3
`define R4         5'd4
`define R5         5'd5
`define R6         5'd6
`define R7         5'd7
`define R8         5'd8
`define R9         5'd9
`define R10        5'd10
`define R11        5'd11
`define R12        5'd12
`define R13        5'd13
`define R14        5'd14
`define R15        5'd15
`define R16        5'd16
`define R17        5'd17
`define R18        5'd18
`define R19        5'd19
`define R20        5'd20
`define R21        5'd21
`define R22        5'd22
`define R23        5'd23
`define R24        5'd24
`define R25        5'd25
`define R26        5'd26
`define R27        5'd27
`define R28        5'd28
`define R29        5'd29
`define R30        5'd30
`define R31        5'd31

// Constants
`define MAX_POS    32'h7FFFFFFF
`define MAX_NEG    32'h80000000
`define ONE        32'h00000001
`define ZERO       32'h00000000 