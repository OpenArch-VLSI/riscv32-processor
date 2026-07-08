`timescale 1ns / 1ps
/*
 * Module: instr_mem
 * Description: 1024-word instruction memory with a ROM preload and a write
 *              port for future loader support. The bundled boot image is
 *              generated from asm/demo_perf_uart.s by tools/build_program.ps1.
 * Inputs: clk, word_addr, load_en, load_word_addr, load_data
 * Outputs: instr
 */
module instr_mem #(
    parameter string INIT_FILE = "program.mem"
) (
    input  logic        clk,
    input  logic [9:0]  word_addr,
    input  logic        load_en,
    input  logic [9:0]  load_word_addr,
    input  logic [31:0] load_data,
    output logic [31:0] instr
);

    logic [31:0] memory [0:1023];
    integer i;

    initial begin
        for (i = 0; i < 1024; i = i + 1) begin
            memory[i] = 32'h00000013;
        end

        $readmemh(INIT_FILE, memory);
    end

    always_ff @(posedge clk) begin
        if (load_en) begin
            memory[load_word_addr] <= load_data;
        end
    end

    assign instr = memory[word_addr];

endmodule
