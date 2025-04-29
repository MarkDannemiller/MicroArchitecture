Firstly, the agent does not know why opcode "4" is being injected at instruction 6 in our test bench. This opcode appears consistently across my testing.

The beginning of the testbench multiplication script is also wrong. We need to make sure that the instructions for the multiplication program are not loaded at program memory address 0, but instead some number of lines into the program that leaves room for the test cases to do setup in the beginning. For each test case, the program needs to be loaded like so:
1. Load test case-specific code (set up registers for program)
2. Load multiplication program starting at defined memory

For each of the test case setup code sequence, the last instruction should jump to the start of the multiplication program.

This fix can happen by simply setting the m variable to a higher value at the initialization of the multiplication program. But, all of the test case relative jumps need to be updated to jump foward to the start of the multiplication program.


Some next steps need to be running the first test again and identifying the unknown opcode area and analyzing debug or the waveform file to trace mistakes in the test or pipeline.