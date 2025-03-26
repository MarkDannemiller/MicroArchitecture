//=============================================================================
// HW2 Tiny Processor
// Mark Dannemiller
//=============================================================================
`include "alu.v"
`include "barrelShifter.v"
`include "muxF.v"

module functionUnit (
    input [4:0]     FS,    // Function select
    input [31:0]    inA,   // 32-bit Input A (for ALU)
    input [31:0]    inB,   // 32-bit Input B (for ALU and Barrel Shifter)

    output [31:0]   outF,  // 32-bit Output
    output          v,     // Overflow
    output          c,     // Carry out
    output          n,     // Negative flag
    output          zero   // Zero flag
);

// Selectors
wire MF_select;     // MuxF select
wire[3:0] gSelect;  // ALU function select
wire [1:0] hSelect; // Barrel shifter select

// Internal module outputs
wire [31:0] ALU_result;
wire [31:0] BS_result;
wire ALU_carryOut;
wire ALU_v;

// From table 7-10 select codes defined in terms of FS
assign MF_select = FS[4];
assign gSelect = FS[3:0];
assign hSelect = FS[3:2];

// Instantiate ALU
ALU alu(
    .select(gSelect[3:1]),
    .a(inA),
    .b(inB),
    .carryIn(gSelect[0]),
    .result(ALU_result),
    .carryOut(ALU_carryOut),
    .v(ALU_v)
);

// Instantiate Barrel Shifter
barrelShifter bs(
    .select(hSelect),
    .inB(inB),
    .out(BS_result)
);

// Instantiate MuxF to select between ALU and Barrel Shifter
muxF mf(
    .select(MF_select),
    .input0(ALU_result),
    .input1(BS_result),
    .out(outF)
);

// Set flags
assign v = ALU_v;
assign c = ALU_carryOut;
assign n = outF[31];
assign zero = (outF == 32'b0);

    
endmodule