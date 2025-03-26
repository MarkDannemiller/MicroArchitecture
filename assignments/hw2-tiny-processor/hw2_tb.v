//=============================================================================
// HW2 Tiny Processor
// Mark Dannemiller
//=============================================================================
`timescale 1ns/1ps
`include "function-unit.v"

module hw2_tb;

    // Test bench signals
    reg  [4:0]  FS;
    reg  [31:0] inA, inB;
    wire [31:0] outF;
    wire        v, c, n, zero;

    // Instantiate the function unit
    functionUnit dut (
        .FS (FS),
        .inA(inA),
        .inB(inB),
        .outF(outF),
        .v(v),
        .c(c),
        .n(n),
        .zero(zero)
    );

    // Test vectors
    reg [31:0] testAs [0:3];
    reg [31:0] testBs [0:3];
    integer i, j;

    initial begin
        // Initialize Inputs
        $dumpfile("hw2_tb.vcd");
        $dumpvars(0, hw2_tb);
        $display("Homework 2 Tiny Processor Testbench");

        // Interesting values for edge testing
        testAs[0] = 32'h00000000; 
        testAs[1] = 32'hFFFFFFFF; 
        testAs[2] = 32'h80000000; 
        testAs[3] = 32'hA5A5A5A5;
        testBs[0] = 32'h00000000;
        testBs[1] = 32'h00000001;
        testBs[2] = 32'h7FFFFFFF;
        testBs[3] = 32'h5A5A5A5A;

        $display("   FS inA      inB      outF     v c n z");
        for (FS = 0; FS < 25; FS = FS + 1) begin
            for (i = 0; i < 4; i = i + 1) begin
                for (j = 0; j < 4; j = j + 1) begin
                    inA = testAs[i]; inB = testBs[j];
                    #10;
                    $display("%5d %8h %8h %8h %1d %1d %1d %1d", FS, inA, inB, outF, v, c, n, zero);
                end
            end
        end
    end

endmodule