//`include "debug_defs.v"

module registerFile(
    input wire clk,
    input wire rst,
    input wire [4:0] A_addr,    // Address for first operand (AA)
    input wire [4:0] B_addr,    // Address for second operand (BA)
    input wire [4:0] D_addr,    // Address for write data (DA)
    input wire [31:0] D_data,   // Write data (DA)
    input wire D_write,         // Write enable (RW)
    output wire [31:0] A_data,  // First operand
    output wire [31:0] B_data   // Second operand
);
    /*
     * Register File - Pipeline Stages: Decode and operand fetch (DOF) and Write Back (WB)
     * 
     * This module spans two pipeline stages:
     * 1. DOF - Reads two source operands (A_data and B_data)
     *    combinationally based on the instruction's register addresses.
     * 2. WB - Writes results back to the destination register on the
     *    rising clock edge when D_write is enabled.
     * 
     * The register file contains 32 registers, each 32 bits wide.
     * Register 0 is hardwired to 0 and cannot be written to.
     * Forward paths may be needed to handle data hazards between WB and DOF stages.
     */

    // Register array (32 registers, each 32 bits)
    reg [31:0] registers [0:31];
    integer i;  // Index for register array


    // Read operations (combinational)
    assign A_data = (A_addr == 5'b00000) ? 32'h00000000 : registers[A_addr];
    assign B_data = (B_addr == 5'b00000) ? 32'h00000000 : registers[B_addr];

    // Register write operation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset all registers to 0
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 32'h0;
                if (`DEBUG_REG) $display("REGISTER DEBUG: Reset R%d = 0", i);
            end
            if (`DEBUG_REG) $display("REGISTER DEBUG: Initializing all registers to 0");
        end
        else if (D_write && D_addr != 5'b00000) begin
            registers[D_addr] <= D_data;
            if (`DEBUG_REG) $display("REGISTER DEBUG: Write R%d = %h", D_addr, D_data);
        end
    end

endmodule
