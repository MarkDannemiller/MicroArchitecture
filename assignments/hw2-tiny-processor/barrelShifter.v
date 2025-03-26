

module barrelShifter(
    input [1:0] select,  // Operation select
    input [31:0] inB,    // 32-bit Input
    output [31:0] out    // 32-bit Output
    );


assign out = (select == 0) ? inB :       // s=0 -> Pass through
             (select == 1) ? inB >> 1 :  // s=1 -> Shift right
                             inB << 1;   // s=2 -> Shift left

endmodule