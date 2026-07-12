`timescale 1ns / 1ps
module ipc_mailbox (
    input  logic        clk,
    input  logic        rst_n,

    // Core 0 access port
    input  logic [31:0] c0_addr,
    input  logic [31:0] c0_wdata,
    input  logic        c0_we,
    input  logic        c0_re,
    output logic [31:0] c0_rdata,
    output logic        c0_valid,

    // Core 1 access port
    input  logic [31:0] c1_addr,
    input  logic [31:0] c1_wdata,
    input  logic        c1_we,
    input  logic        c1_re,
    output logic [31:0] c1_rdata,
    output logic        c1_valid
);

    // INTERNAL REGISTERS: exactly 4, each 32 bits
    // 0 = C0_TO_C1_DATA, 1 = C0_TO_C1_FLAG, 2 = C1_TO_C0_DATA, 3 = C1_TO_C0_FLAG
    logic [31:0] regs [0:3];

    // Combinational read data: the pipeline samples MMIO read data during
    // the MEM stage (same convention as data_mem), so rdata must be valid
    // in the same cycle re/addr are presented.
    assign c0_rdata = regs[c0_addr[3:2]];
    assign c1_rdata = regs[c1_addr[3:2]];

    // Priority rule: If both ports write to the SAME register in the same cycle, Core 0's write wins.
    // Core 0 has priority for simultaneous writes to the same address.
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            regs[0] <= 32'h00000000;
            regs[1] <= 32'h00000000;
            regs[2] <= 32'h00000000;
            regs[3] <= 32'h00000000;
            c0_valid <= 1'b0;
            c1_valid <= 1'b0;
        end else begin
            // Registered read-acknowledge pulse
            c0_valid <= c0_re;
            c1_valid <= c1_re;

            // Handle writes
            if (c0_we && c1_we) begin
                regs[c0_addr[3:2]] <= c0_wdata;
                // If c1 writes to a different register, it succeeds
                if (c1_addr[3:2] != c0_addr[3:2]) begin
                    regs[c1_addr[3:2]] <= c1_wdata;
                end
            end else if (c0_we) begin
                regs[c0_addr[3:2]] <= c0_wdata;
            end else if (c1_we) begin
                regs[c1_addr[3:2]] <= c1_wdata;
            end
        end
    end

endmodule
