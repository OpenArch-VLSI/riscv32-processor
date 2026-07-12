`timescale 1ns / 1ps

module tb_instr_mem_param;

    logic        clk;
    logic [9:0]  word_addr;
    logic        load_en;
    logic [9:0]  load_word_addr;
    logic [31:0] load_data;
    
    logic [31:0] instr0;
    logic [31:0] instr1;

    // Instance 0: core0
    instr_mem #(
        .INIT_FILE("../../../../../asm/core0_placeholder.mem")
    ) mem0 (
        .clk(clk),
        .word_addr(word_addr),
        .load_en(load_en),
        .load_word_addr(load_word_addr),
        .load_data(load_data),
        .instr(instr0)
    );

    // Instance 1: core1
    instr_mem #(
        .INIT_FILE("../../../../../asm/core1_placeholder.mem")
    ) mem1 (
        .clk(clk),
        .word_addr(word_addr),
        .load_en(load_en),
        .load_word_addr(load_word_addr),
        .load_data(load_data),
        .instr(instr1)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        word_addr = 0;
        load_en = 0;
        load_word_addr = 0;
        load_data = 0;

        #20;

        // 1. Check core0
        word_addr = 10'd0;
        #10;
        if (instr0 == 32'd0) begin
            $fatal(1, "TEST FAILED: core0 instruction is zero");
        end

        // 2. Check core1
        if (instr1 !== 32'h00000013) begin
            $fatal(1, "TEST FAILED: core1 instruction is not 00000013");
        end

        // 3. Verify they return different data for the same address (addr 15)
        // Note: program.mem usually has different data at addr 15 than core1 (which is 00000073 after 10)
        word_addr = 10'd15;
        #10;
        if (instr0 === instr1) begin
            $fatal(1, "TEST FAILED: Both instances returned same data for address 15");
        end

        $display("*** tb_instr_mem_param PASSED ***");
        $finish;
    end

endmodule
