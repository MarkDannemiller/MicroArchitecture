- [ ] Instruction decoder might deserve its own module
- [ ] IDecoder outputs are not buffered at the moment, but always updated (they need to be updated on low edge, but are they actually needed in DOF stage?)
- [ ] We adjusted from thinking in 5 stages to 4, confirm how many clock cycles the pipeline takes, and adjust test bench
- [ ] We moved from 16 bits to 32 bits for all registers and memory. Update test bench to match


- [ ] Test code and generate GTKWave graphs
- [ ] Organize into powerpoint