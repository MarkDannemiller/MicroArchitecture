// 64-bit Multiplication Program
// Input: R1 (32-bit multiplicand), R2 (32-bit multiplier)
// Output: R3 (upper 32 bits), R4 (lower 32 bits)

// Save input values and initialize result registers
MOV R5, R1          // Save multiplicand
MOV R6, R2          // Save multiplier
MOV R3, R0          // Clear upper result
MOV R4, R0          // Clear lower result

// Check signs and store result sign
SLT R7, R5, R0      // Check if multiplicand is negative
SLT R8, R6, R0      // Check if multiplier is negative
XOR R9, R7, R8      // Final sign (1 if result should be negative)

// Make multiplicand positive if needed
BNZ R7, 2           // Skip if multiplicand is not negative
JMP 4               // Jump to multiplier check
SUB R5, R0, R5      // Negate multiplicand

// Make multiplier positive if needed
BNZ R8, 2           // Skip if multiplier is not negative
JMP 4               // Jump to multiplication loop
SUB R6, R0, R6      // Negate multiplier

// Multiplication loop
MOV R10, R0         // Initialize counter
MOV R11, R0         // Initialize shift counter
MOV R12, R6         // Copy multiplier for shifting

MULT_LOOP:
    BZ R12, 2       // Skip if current bit is 0
    JMP 4           // Jump to add multiplicand
    JMP 2           // Skip addition
    ADD R4, R4, R5  // Add multiplicand to lower result
    ADI R10, R10, 1 // Increment counter

    LSL R5, R5, 1   // Shift multiplicand left
    LSR R12, R12, 1 // Shift multiplier right
    ADI R11, R11, 1 // Increment shift counter

    // Check if we need to handle overflow
    SLT R13, R11, 32 // Check if shift counter < 32
    BZ R13, 2        // Skip if shift counter >= 32
    JMP 4            // Jump to overflow handling
    JMP 2            // Skip overflow handling
    MOV R3, R4       // Move lower result to upper
    MOV R4, R0       // Clear lower result
    JMP 2            // Skip overflow handling

    // Check if multiplication is complete
    SLT R13, R10, 32 // Check if counter < 32
    BZ R13, 2        // Skip if counter >= 32
    JMP 4            // Jump to sign correction
    JMP 2            // Skip sign correction
    JMP -16          // Continue multiplication loop

// Apply final sign if needed
BNZ R9, 2           // Skip if result should not be negative
JMP 4               // Jump to end
SUB R4, R0, R4      // Negate lower result
SLT R13, R4, R0     // Check if lower result is negative
BNZ R13, 2          // Skip if lower result is not negative
JMP 4               // Jump to end
SUB R3, R0, R3      // Negate upper result
ADI R3, R3, 1       // Add 1 to upper result for 2's complement

// End of program
JMP 0               // Infinite loop to end program 