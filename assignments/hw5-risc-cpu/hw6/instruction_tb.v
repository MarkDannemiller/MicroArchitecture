`timescale 1ns/1ps
`include "../definitions.v"
`include "../debug_defs.v"
`include "../top.v"
`include "../IF_stage.v"
`include "../DOF_stage.v"
`include "../EX_stage.v"
`include "../WB_stage.v"
`include "../instructionMemory.v"
`include "../instructionDecoder.v"
`include "../dataMemory.v"
`include "../registerFile.v"
`include "../constantUnit.v"
`include "../functionUnit.v"
`include "../muxA.v"
`include "../muxB.v"
`include "../muxC.v"
`include "../muxD.v"

module instruction_tb;

    // ──────────────────────────  parameters  ──────────────────────────
    localparam MEM_SIZE      = 1024;                //  words
    localparam TIMEOUT_CYC   = 10_000;              //  cycles / test
    localparam DBG_PERIOD    = 100;                 //  cycles between dbg prints

    // ──────────────────────────  clock & reset  ───────────────────────
    reg  clk = 0;
    reg  rst = 0;
    always #5 clk = ~clk;                           // 100 MHz

    // ──────────────────────────  DUT  ─────────────────────────────────
    top cpu ( .clk(clk), .rst(rst) );

    // ──────────────────────────  register snoop  ──────────────────────
    wire [31:0] R_debug [0:31];
    genvar r;
    generate
        for (r = 0; r < 32; r = r + 1)
            assign R_debug[r] = cpu.dof_stage.reg_file.registers[r];
    endgenerate

    // ──────────────────────────  local program buffer  ────────────────
    reg [31:0] instr_mem [0:MEM_SIZE-1];
    integer i;

    // ──────────────────────────  helpers  ─────────────────────────────
    function [31:0] pack_instruction;
        input [6:0] opcode;
        input [4:0] rd, rs1, rs2;
        input [14:0] imm15;
        begin
            // R-type default
            pack_instruction = {opcode, rd, rs1, rs2, 10'b0};
            // override for I/B/J formats that embed imm15
            if (opcode == `OP_ADI || opcode == `OP_SBI || opcode == `OP_ANI ||
                opcode == `OP_ORI || opcode == `OP_XRI || opcode == `OP_AIU ||
                opcode == `OP_SIU || opcode == `OP_LSL || opcode == `OP_LSR ||
                opcode == `OP_BZ  || opcode == `OP_BNZ || opcode == `OP_JMP ||
                opcode == `OP_JML)
                pack_instruction = {opcode, rd, rs1, imm15};
        end
    endfunction

    task add_nops (inout integer idx, input integer count);
        integer k;
        begin
            for (k = 0; k < count; k = k + 1)
                instr_mem[idx++] = pack_instruction(`OP_NOP,5'd0,5'd0,5'd0,15'd0);
        end
    endtask

    task load32 (inout integer idx, input [4:0] rd, input [31:0] val);
        reg [4:0] s; begin
            s = 5'd31;                                // scratch
            instr_mem[idx++] = pack_instruction(`OP_ADI, rd, `R0,5'd0,val[14:0]);
            add_nops(idx,4);
            instr_mem[idx++] = pack_instruction(`OP_ADI, s,`R0,5'd0,15'd1);
            add_nops(idx,4);
            instr_mem[idx++] = pack_instruction(`OP_LSL, s,s,5'd0,15'd15);
            add_nops(idx,4);
            instr_mem[idx++] = pack_instruction(val[15]?`OP_OR:`OP_ADI,
                                                rd, rd, s, 15'd0);
            add_nops(idx,4);
            instr_mem[idx++] = pack_instruction(`OP_LSL, rd,rd,5'd0,15'd16);
            add_nops(idx,4);
            instr_mem[idx++] = pack_instruction(`OP_ORI, rd,rd,5'd0,val[30:16]);
            add_nops(idx,4);
            instr_mem[idx++] = pack_instruction(`OP_ADI, s,`R0,5'd0,15'd1);
            add_nops(idx,4);
            instr_mem[idx++] = pack_instruction(`OP_LSL, s,s,5'd0,15'd31);
            add_nops(idx,4);
            instr_mem[idx++] = pack_instruction(val[31]?`OP_OR:`OP_ADI,
                                                rd, rd, s, 15'd0);
            add_nops(idx,4);
        end
    endtask

    // ──────────────────────────  one test case  ───────────────────────
    task run_test;
        input [8*32-1:0] name;
        input [6:0]  op;
        input [4:0]  rd, rs1, rs2;
        input [14:0] imm;
        input [31:0] v1,  v2,  expected;
        integer j, pc, cycles;
        begin
            $display("\n--- %0s ---", name); $fflush;

            // build fresh program
            for (i = 0; i < MEM_SIZE; i = i + 1) instr_mem[i] = 32'h0;
            j = 0;
            load32(j, rs1, v1);
            load32(j, rs2, v2);
            instr_mem[j++] = pack_instruction(op, rd, rs1, rs2, imm);
            for (j=0; j < MEM_SIZE; j = j + 1)
                instr_mem[j] = pack_instruction(`OP_NOP,5'd0,5'd0,5'd0,15'd0);

            // copy into DUT IMEM (PC=0 mapping)
            for (i = 0; i < MEM_SIZE; i = i + 1)
                cpu.if_stage.inst_mem.memory[i] = instr_mem[i];

            // reset pulse (sync reset assumed)
            rst = 1; repeat (3) @(posedge clk); rst = 0;

            // wait for result or timeout
            cycles = 0;
            while (R_debug[rd] !== expected && cycles < TIMEOUT_CYC) begin
                @(posedge clk);
                cycles = cycles + 1;
                if ((cycles % DBG_PERIOD == 0) || (cpu.if_stage.instruction !== 32'h0)) begin
                    pc = cpu.PC;                 // adjust hierarchy as needed
                    $display("Cycle=%0d PC=%0d IF=%h ID=%h FS=%h DR=%0d EX=%h WBa=%0d WBd=%h R0=%h R1=%h R2=%h R3=%h R4=%h R5=%h R6=%h R7=%h R8=%h R9=%h",
                             cycles, pc,
                             cpu.if_stage.instruction,
                             cpu.IF_DOF_instruction,
                             cpu.DOF_EX_FS, cpu.DOF_EX_DR,
                             cpu.EX_ALU_result,
                             cpu.wb_stage.WB_addr, cpu.wb_stage.WB_data,
                             R_debug[0], R_debug[1], R_debug[2], R_debug[3], R_debug[4],
                             R_debug[5], R_debug[6], R_debug[7], R_debug[8], R_debug[9]);
                    $fflush;
                end
            end

            if (R_debug[rd] === expected) begin
                $display("PASS  : R[%0d] = %h  (after %0d cycles)",
                         rd, R_debug[rd], cycles);
            end else begin
                $display("TIMEOUT after %0d cycles; R[%0d] = %h (exp %h)",
                         cycles, rd, R_debug[rd], expected);
                $fatal(1, "%0s FAILED", name);
            end
        end
    endtask

    // ──────────────────────────  master sequence  ─────────────────────
    integer passes = 0;
    initial begin
        $dumpfile("instruction_tb.vcd");
        $dumpvars(0, instruction_tb);

        //--------------------------------------------------------------
        //  R-type
        //--------------------------------------------------------------
        run_test("ADD R1=R2+R3",
                 `OP_ADD, `R1,`R2,`R3, 15'd0,
                 32'd5, 32'd7, 32'd12); passes++;
        run_test("SUB R4=R5-R6",
                 `OP_SUB, `R4,`R5,`R6, 15'd0,
                 32'd10,32'd3, 32'd7 ); passes++;
        run_test("AND R7=R8&R9",
                 `OP_AND, `R7,`R8,`R9, 15'd0,
                 32'hFF00FF00,32'h0F0F0F0F,32'h0F000F00); passes++;

        //--------------------------------------------------------------
        //  I-type (add others as needed)
        //--------------------------------------------------------------
        run_test("ADI R2=R3+10",
                 `OP_ADI, `R2,`R3,`R0, 15'd10,
                 32'd8, 0, 32'd18); passes++;

        //--------------------------------------------------------------
        $display("\n=== %0d tests completed ===", passes);
        $finish;
    end
endmodule
