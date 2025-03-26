module top(
    input wire clk,
    input wire rst
);
    // ========================================================================
    // Pipeline Stage Registers and Control Signals
    // ========================================================================


    // ========================================================================
    // IF Stage (Instruction Fetch) - Updates on Falling Edge
    // ========================================================================
    
    // Program Counter and related signals
    reg [31:0] PC;            // Current PC
    wire [31:0] PC_next;      // Next PC value
    reg [31:0] PC_1;          // PC+1 for branch calculations
    reg [31:0] PC_2;          // PC+2 for jump-and-link

    // Instruction Memory
    wire [31:0] instruction;
    instructionMemory inst_mem(
        .addr(PC),
        .instruction(instruction)
    );

    // Next PC Selection (MuxC)
    wire [31:0] offset_addr = PC_1 + {{8{IM[7]}}, IM};
    muxC mux_c(
        .PC_1(PC_1),
        .BrA(offset_addr),
        .RAA(A_data),
        .JMP(offset_addr),
        .BS(BS),
        .PS(PS),
        .Z(Z),
        .out(PC_next)
    );

    // IF Stage Registers (falling edge)
    always @(negedge clk or posedge rst) begin
        if (rst) begin
            PC <= 32'h0000;
            PC_1 <= 32'h0000;
            PC_2 <= 32'h0000;
        end else begin
            PC <= PC_next;
            PC_1 <= PC;
            PC_2 <= PC_1;
        end
    end

    // ========================================================================
    // DOF Stage (Decode & Operand Fetch) - Updates on Falling Edge
    // ========================================================================
        
    // Instruction Register
    reg [31:0] IR;
    always @(negedge clk or posedge rst) begin
        if (rst)
            IR <= 32'h0000;
        else
            IR <= instruction;
    end
        
    // Control signals from instruction decoder
    wire RW, MD, MW;          // Register Write, Memory Data, Memory Write
    wire [1:0] BS, PS;        // Branch Select, Program Select
    wire [4:0] FS;            // Function Select
    wire MB, MA, CS;          // Mux B, Mux A, Constant Select

    // Instruction fields
    wire [7:0] IM;            // Immediate field
    wire [4:0] SH;            // Shift amount
    wire [4:0] DR;            // Destination Register
    wire [4:0] SA;            // Source A Register
    wire [4:0] SB;            // Source B Register
    wire [7:0] opcode;        // Opcode field

    // Instruction Decoder
    assign {DR, SA, SB, IM, SH} = IR;

    // Register File Read (combinational)
    wire [31:0] A_data, B_data;
    wire [31:0] D_data;
    registerFile reg_file(
        .clk(clk),
        .rst(rst),
        .A_addr(SA),
        .B_addr(SB),
        .D_addr(DR),
        .D_data(D_data),
        .D_write(RW),
        .A_data(A_data),
        .B_data(B_data)
    );

    // Constant Unit
    wire [31:0] constant;
    constantUnit const_unit(
        .IM(IM),
        .CS(CS),
        .out(constant)
    );
        
    // Operand Selection
    wire [31:0] ALU_A, ALU_B;
    muxA mux_a(
        .A_data(A_data),
        .PC_1(PC_1),
        .MA(MA),
        .out(ALU_A)
    );

    muxB mux_b(
        .B_data(B_data),
        .constant(constant),
        .MB(MB),
        .out(ALU_B)
    );

    // ========================================================================
    // EX Stage (Execute) - Updates on Falling Edge
    // ========================================================================

    
    // Control Unit
    always @(*) begin
        case (opcode)
            7'b0000000: begin // NOP
                RW = 1'b0; MD = 1'b0; BS = 2'b00; PS = 2'b00; MW = 1'b0;
                FS = 5'b00000; MB = 1'b0; MA = 1'b0; CS = 1'b0;
            end
            7'b0000010: begin // ADD
                RW = 1'b1; MD = 1'b0; BS = 2'b00; PS = 2'b00; MW = 1'b0;
                FS = 5'b00010; MB = 1'b0; MA = 1'b0; CS = 1'b0;
            end
            7'b0000101: begin // SUB
                RW = 1'b1; MD = 1'b0; BS = 2'b00; PS = 2'b00; MW = 1'b0;
                FS = 5'b00101; MB = 1'b0; MA = 1'b0; CS = 1'b0;
            end
            7'b1100101: begin // SLT
                RW = 1'b1; MD = 1'b1; BS = 2'b00; PS = 2'b00; MW = 1'b0;
                FS = 5'b00101; MB = 1'b0; MA = 1'b0; CS = 1'b0;
            end
            7'b0001000: begin // AND
                RW = 1'b1; MD = 1'b0; BS = 2'b00; PS = 2'b00; MW = 1'b0;
                FS = 5'b01000; MB = 1'b0; MA = 1'b0; CS = 1'b0;
            end
            7'b0001010: begin // OR
                RW = 1'b1; MD = 1'b0; BS = 2'b00; PS = 2'b00; MW = 1'b0;
                FS = 5'b01010; MB = 1'b0; MA = 1'b0; CS = 1'b0;
            end
            7'b0001100: begin // XOR
                RW = 1'b1; MD = 1'b0; BS = 2'b00; PS = 2'b00; MW = 1'b0;
                FS = 5'b01100; MB = 1'b0; MA = 1'b0; CS = 1'b0;
            end
            7'b0000001: begin // ST
                RW = 1'b0; MD = 1'b0; BS = 2'b00; PS = 2'b00; MW = 1'b1;
                FS = 5'b00000; MB = 1'b0; MA = 1'b0; CS = 1'b0;
            end
            7'b0100001: begin // LD
                RW = 1'b1; MD = 1'b1; BS = 2'b00; PS = 2'b00; MW = 1'b0;
                FS = 5'b00000; MB = 1'b0; MA = 1'b0; CS = 1'b0;
            end
            7'b0100010: begin // ADI
                RW = 1'b1; MD = 1'b0; BS = 2'b00; PS = 2'b00; MW = 1'b0;
                FS = 5'b00010; MB = 1'b1; MA = 1'b0; CS = 1'b1;
            end
            7'b0100101: begin // SBI
                RW = 1'b1; MD = 1'b0; BS = 2'b00; PS = 2'b00; MW = 1'b0;
                FS = 5'b00101; MB = 1'b1; MA = 1'b0; CS = 1'b1;
            end
            7'b0101110: begin // NOT
                RW = 1'b1; MD = 1'b0; BS = 2'b00; PS = 2'b00; MW = 1'b0;
                FS = 5'b01110; MB = 1'b0; MA = 1'b0; CS = 1'b0;
            end
            7'b0101000: begin // ANI
                RW = 1'b1; MD = 1'b0; BS = 2'b00; PS = 2'b00; MW = 1'b0;
                FS = 5'b01000; MB = 1'b1; MA = 1'b0; CS = 1'b0;
            end
            7'b0101010: begin // ORI
                RW = 1'b1; MD = 1'b0; BS = 2'b00; PS = 2'b00; MW = 1'b0;
                FS = 5'b01010; MB = 1'b1; MA = 1'b0; CS = 1'b0;
            end
            7'b0101100: begin // XRI
                RW = 1'b1; MD = 1'b0; BS = 2'b00; PS = 2'b00; MW = 1'b0;
                FS = 5'b01100; MB = 1'b1; MA = 1'b0; CS = 1'b0;
            end
            7'b1100010: begin // AIU
                RW = 1'b1; MD = 1'b0; BS = 2'b00; PS = 2'b00; MW = 1'b0;
                FS = 5'b00010; MB = 1'b1; MA = 1'b0; CS = 1'b0;
            end
            7'b1100101: begin // SIU
                RW = 1'b1; MD = 1'b0; BS = 2'b00; PS = 2'b00; MW = 1'b0;
                FS = 5'b00101; MB = 1'b1; MA = 1'b0; CS = 1'b0;
            end
            7'b1000000: begin // MOV
                RW = 1'b1; MD = 1'b0; BS = 2'b00; PS = 2'b00; MW = 1'b0;
                FS = 5'b00000; MB = 1'b0; MA = 1'b0; CS = 1'b0;
            end
            7'b0110000: begin // LSL
                RW = 1'b1; MD = 1'b0; BS = 2'b00; PS = 2'b00; MW = 1'b0;
                FS = 5'b10100; MB = 1'b0; MA = 1'b0; CS = 1'b0;
            end
            7'b0110001: begin // LSR
                RW = 1'b1; MD = 1'b0; BS = 2'b00; PS = 2'b00; MW = 1'b0;
                FS = 5'b11000; MB = 1'b0; MA = 1'b0; CS = 1'b0;
            end
            7'b1100001: begin // JMR
                RW = 1'b0; MD = 1'b0; BS = 2'b10; PS = 2'b00; MW = 1'b0;
                FS = 5'b00000; MB = 1'b0; MA = 1'b0; CS = 1'b0;
            end
            7'b0100000: begin // BZ
                RW = 1'b0; MD = 1'b0; BS = 2'b01; PS = 2'b0; MW = 1'b0;
                FS = 5'b00000; MB = 1'b1; MA = 1'b0; CS = 1'b1;
            end
            7'b1100000: begin // BNZ
                RW = 1'b0; MD = 1'b0; BS = 2'b01; PS = 2'b1; MW = 1'b0;
                FS = 5'b00000; MB = 1'b1; MA = 1'b0; CS = 1'b1;
            end
            7'b1000100: begin // JMP
                RW = 1'b0; MD = 1'b0; BS = 2'b11; PS = 2'b00; MW = 1'b0;
                FS = 5'b00000; MB = 1'b1; MA = 1'b1; CS = 1'b1;
            end
            7'b1000000: begin // JML
                RW = 1'b1; MD = 1'b0; BS = 2'b11; PS = 2'b00; MW = 1'b0;
                FS = 5'b00111; MB = 1'b1; MA = 1'b1; CS = 1'b1;
            end
            default: begin // Default case (NOP)
                RW = 1'b0; MD = 1'b0; BS = 2'b00; PS = 2'b00; MW = 1'b0;
                FS = 5'b00000; MB = 1'b0; MA = 1'b0; CS = 1'b0;
            end
        endcase
    end

    // Function Unit
    wire [31:0] ALU_result;
    wire Z, V, N, C;
    functionUnit func_unit(
        .A(ALU_A),
        .B(ALU_B),
        .FS(FS),
        .SH(SH),
        .F(ALU_result),
        .Z(Z),
        .V(V),
        .N(N),
        .C(C)
    );
        
    // Data Memory (writes on rising edge)
    wire [31:0] mem_data_out;
    dataMemory data_mem(
        .clk(clk),
        .addr(ALU_result),
        .data_in(B_data),
        .data_out(mem_data_out),
        .MW(MW)
    );

    // ========================================================================
    // Memory and WB Stage - Memory/Register Writes on Rising Edge
    // ========================================================================

    // Write Back Data Selection
    wire [31:0] D_data;
    muxD mux_d(
        .ALU_result(ALU_result),
        .mem_data(mem_data_out),
        .PC_2(PC_2),
        .MD(MD),
        .out(D_data)
    );


endmodule
