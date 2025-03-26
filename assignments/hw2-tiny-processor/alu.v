
module ALU(
    input[2:0]  select,    // Function select
    input[31:0] a,         // 32-bit Input A
    input[31:0] b,         // 32-bit Input B
    input       carryIn,   // Carry in
    output[31:0] result,   // Output result
    output      carryOut,  // Carry out
    output      v          // Overflow
);

// Assign 32-bit result based on function select and carry in
assign {carryOut, result} = 
            (select == 0) ? 
                    (carryIn) ? a + 1 : a :             // s=0 -> Transfer a or increment a
            (select == 1) ? 
                    (carryIn) ? a + b + 1 : a + b :     // s=1 -> Add a and b with carry
            (select == 2) ? 
                    (carryIn) ? a + ~b + 1 : a + ~b :   // s=2 -> Add a and 1's complement of b
            (select == 3) ? 
                    (carryIn) ? a : a - 1 :             // s=3 -> transfer or Decrement a
            (select == 4) ? a & b :                     // s=4 -> a AND b
            (select == 5) ? a | b :                     // s=5 -> a OR b
            (select == 6) ? a ^ b :                     // s=6 -> a XOR b
            (select == 7) ? ~a :                        // s=7 -> NOT a
            4'b0; // Default

assign v = carryIn ^ carryOut;

endmodule