`timescale 1ns / 1ps

//=============================================================================
// HW1 Basic Verilog
// Mark Dannemiller
//=============================================================================

module hw1(
    input A,
    input B,
    input C,
    input D,
    output out
);

    assign out = (A | D) & (~B | C);
    
endmodule
