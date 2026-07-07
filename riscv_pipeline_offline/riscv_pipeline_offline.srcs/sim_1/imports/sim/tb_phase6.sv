/*
 * Module: tb_phase6
 * Description: Self-checking testbench for Phase 6 - RV32M Multiply Extension.
 *
 * Tests:
 *   1. MUL
 *   2. MULH
 *   3. MULHSU
 *   4. MULHU
 *
 * Uses the instruction loader port to inject Phase 6 test sequences.
 */
`timescale 1ns/1ps

module tb_phase6;

    logic clk;
    logic rst;
    int   failures;

    logic uart_txd, uart_rxd_tb;
    logic instr_load_en;
    logic [9:0]  instr_load_word_addr;
    logic [31:0] instr_load_data;
    logic [31:0] program_words [0:1023];

    logic [31:0] debug_pc_current;
    logic        debug_wb_reg_write;
    logic [4:0]  debug_wb_rd;
    logic [31:0] debug_wb_write_data;
    logic        halt;
    logic [4:0]  dbg_reg_addr;
    logic [31:0] dbg_reg_data;
    logic [9:0]  dbg_dmem_addr;
    logic [31:0] dbg_dmem_data;
    logic [31:0] dbg_perf_cycle;
    logic [31:0] dbg_perf_instr;
    logic [31:0] dbg_perf_stall;
    logic [31:0] dbg_perf_flush;
    logic [1:0]  dbg_trace_sel;
    logic [31:0] dbg_trace_pc, dbg_trace_instr, dbg_trace_wb_data, dbg_trace_status;
    logic [2:0]  dbg_trace_count;
    logic [1:0]  dbg_trace_head;

    top uut (
        .clk(clk), .rst(rst),
        .debug_pc_current(debug_pc_current),
        .debug_wb_reg_write(debug_wb_reg_write),
        .debug_wb_rd(debug_wb_rd),
        .debug_wb_write_data(debug_wb_write_data),
        .halt(halt),
        .instr_load_en(instr_load_en),
        .instr_load_word_addr(instr_load_word_addr),
        .instr_load_data(instr_load_data),
        .uart_rxd(uart_rxd_tb), .uart_txd(uart_txd),
        .dbg_reg_addr(dbg_reg_addr), .dbg_reg_data(dbg_reg_data),
        .dbg_dmem_addr(dbg_dmem_addr), .dbg_dmem_data(dbg_dmem_data),
        .dbg_perf_cycle(dbg_perf_cycle), .dbg_perf_instr(dbg_perf_instr),
        .dbg_perf_stall(dbg_perf_stall), .dbg_perf_flush(dbg_perf_flush),
        .dbg_trace_sel(dbg_trace_sel),
        .dbg_trace_pc(dbg_trace_pc), .dbg_trace_instr(dbg_trace_instr),
        .dbg_trace_wb_data(dbg_trace_wb_data), .dbg_trace_status(dbg_trace_status),
        .dbg_trace_count(dbg_trace_count), .dbg_trace_head(dbg_trace_head)
    );

    initial uart_rxd_tb = 1'b1;
    initial begin clk = 1'b0; forever #5 clk = ~clk; end

    initial begin
        $dumpfile("riscv_pipeline_phase6.vcd");
        $dumpvars(0, tb_phase6);
    end

    // ------------------------------------------------------------------
    // Helpers
    // ------------------------------------------------------------------
    task run_cycles(input int count);
        repeat (count) @(posedge clk);
        #1;
    endtask

    task load_word(input logic [9:0] addr, input logic [31:0] data);
        @(negedge clk);
        instr_load_en = 1'b1; instr_load_word_addr = addr; instr_load_data = data;
        @(posedge clk); #1;
        instr_load_en = 1'b0;
    endtask

    task check_reg(input int r, input logic [31:0] exp, input string msg);
        logic [31:0] val = uut.u_id_stage.u_reg_file.regs[r];
        if (val == exp)
            $display("PASS: %s (x%0d=0x%08h)", msg, r, val);
        else begin
            $error("FAIL: %s expected x%0d=0x%08h got 0x%08h", msg, r, exp, val);
            failures++;
        end
    endtask

    // ------------------------------------------------------------------
    // Main test
    // ------------------------------------------------------------------
    initial begin
        failures = 0;
        instr_load_en = 1'b0; instr_load_word_addr = 10'd0; instr_load_data = 32'd0;
        dbg_reg_addr = 5'd0; dbg_dmem_addr = 10'd0; dbg_trace_sel = 2'd0;

        // Reset
        rst = 1'b1; run_cycles(5); rst = 1'b0; run_cycles(10);

        $display("\n=== Phase 6 Test: RV32M Multiply Instructions ===");

        // Inject MUL test program at address 0x100
        // @0x100: addi x1, x0, -1    -> 0xFFF00093
        // @0x104: addi x2, x0, -1    -> 0xFFF00113
        // @0x108: mul x3, x1, x2     -> 0x022081B3
        // @0x10C: mulh x4, x1, x2    -> 0x02209233
        // @0x110: mulhsu x5, x1, x2  -> 0x0220A2B3
        // @0x114: mulhu x6, x1, x2   -> 0x0220B333
        // @0x118: jal x0, 0 (spin)   -> 0x0000006F
        
        load_word(10'd64, 32'hFFF00093);
        load_word(10'd65, 32'hFFF00113);
        load_word(10'd66, 32'h022081B3);
        load_word(10'd67, 32'h02209233);
        load_word(10'd68, 32'h0220A2B3);
        load_word(10'd69, 32'h0220B333);
        load_word(10'd70, 32'h0000006F);

        // Force PC to 0x100
        force uut.u_if_stage.pc_current = 32'h100;
        run_cycles(1); release uut.u_if_stage.pc_current;
        run_cycles(20);

        // x1 = 0xFFFFFFFF
        // x2 = 0xFFFFFFFF
        check_reg(1, 32'hFFFFFFFF, "Load x1");
        check_reg(2, 32'hFFFFFFFF, "Load x2");
        
        // x3 = MUL = 1
        check_reg(3, 32'h00000001, "MUL result");
        
        // x4 = MULH = 0
        check_reg(4, 32'h00000000, "MULH result");
        
        // x5 = MULHSU = 0xFFFFFFFF
        check_reg(5, 32'hFFFFFFFF, "MULHSU result");
        
        // x6 = MULHU = 0xFFFFFFFE
        check_reg(6, 32'hFFFFFFFE, "MULHU result");

        // ------------------------------------------------------------------
        // DIV/REM tests
        // ------------------------------------------------------------------
        $display("\n=== Phase 6 Test: RV32M Divide/Remainder Instructions ===");

        // Load DIV/REM test program at 0x140 (word addr 80)
        // Common register init
        load_word(10'd80, 32'h00A00513); // addi x10, x0, 10
        load_word(10'd81, 32'h00300593); // addi x11, x0, 3
        load_word(10'd82, 32'hFF600693); // addi x13, x0, -10
        load_word(10'd83, 32'hFFD00713); // addi x14, x0, -3
        load_word(10'd84, 32'h00500993); // addi x19, x0, 5
        load_word(10'd85, 32'hFFF00613); // addi x12, x0, -1

        // Test  1: DIV positive/positive   — 10/3 = 3
        load_word(10'd86, 32'h02B547B3); // DIV x15, x10, x11
        // Test  2: DIV negative/positive   — (-10)/3 = -3 (0xFFFFFFFD)
        load_word(10'd87, 32'h02B6C833); // DIV x16, x13, x11
        // Test  3: DIV positive/negative   — 10/(-3) = -3 (0xFFFFFFFD)
        load_word(10'd88, 32'h02E548B3); // DIV x17, x10, x14
        // Test  4: DIV negative/negative   — (-10)/(-3) = 3
        load_word(10'd89, 32'h02E6C933); // DIV x18, x13, x14
        // Test  5: DIV divide by zero      — 5/0 = 0xFFFFFFFF
        load_word(10'd90, 32'h0209CA33); // DIV x20, x19, x0
        // Test  6: DIV signed overflow     — 0x80000000/(-1) = 0x80000000
        load_word(10'd91, 32'h80000AB7); // lui x21, 0x80000
        load_word(10'd92, 32'h02CACB33); // DIV x22, x21, x12

        // Test  7: DIVU basic             — 0x80000000/2 = 0x40000000
        load_word(10'd93, 32'h80000BB7); // lui x23, 0x80000
        load_word(10'd94, 32'h00200C13); // addi x24, x0, 2
        load_word(10'd95, 32'h038BDCB3); // DIVU x25, x23, x24
        // Test  8: DIVU divide by zero     — 5/0 = 0xFFFFFFFF
        load_word(10'd96, 32'h0209DD33); // DIVU x26, x19, x0

        // Test  9: REM positive/positive   — 10%3 = 1
        load_word(10'd97, 32'h02B56DB3); // REM x27, x10, x11
        // Test 10: REM negative/positive   — (-10)%3 = -1 (0xFFFFFFFF)
        load_word(10'd98, 32'h02B6EE33); // REM x28, x13, x11
        // Test 11: REM positive/negative   — 10%(-3) = 1
        load_word(10'd99, 32'h02E56EB3); // REM x29, x10, x14
        // Test 12: REM divide by zero      — 5%0 = 5
        load_word(10'd100, 32'h0209EF33); // REM x30, x19, x0
        // Test 13: REM overflow            — 0x80000000%(-1) = 0
        load_word(10'd101, 32'h02CAE133); // REM x2, x21, x12

        // Test 14: REMU basic             — 0x80000000%3 = 2
        load_word(10'd102, 32'h02BBF1B3); // REMU x3, x23, x11
        // Test 15: REMU divide by zero     — 5%0 = 5
        load_word(10'd103, 32'h0209F233); // REMU x4, x19, x0

        // Test 16: Combined back-to-back DIV/DIVU/REM/REMU — 100/7
        load_word(10'd104, 32'h06400293); // addi x5, x0, 100
        load_word(10'd105, 32'h00700313); // addi x6, x0, 7
        load_word(10'd106, 32'h0262C3B3); // DIV  x7, x5, x6   — 100/7 = 14
        load_word(10'd107, 32'h0262D433); // DIVU x8, x5, x6   — 100/7 = 14
        load_word(10'd108, 32'h0262E4B3); // REM  x9, x5, x6   — 100%7 = 2
        load_word(10'd109, 32'h0262FFB3); // REMU x31, x5, x6  — 100%7 = 2
        load_word(10'd110, 32'h0000006F); // jal x0, 0 (spin)

        // Force PC to 0x140 and run
        force uut.u_if_stage.pc_current = 32'h140;
        run_cycles(1); release uut.u_if_stage.pc_current;
        run_cycles(1000);

        // Check DIV results (tests 1-6)
        check_reg(15, 32'd3,            "DIV  10/3");
        check_reg(16, 32'hFFFFFFFD,     "DIV  (-10)/3");
        check_reg(17, 32'hFFFFFFFD,     "DIV  10/(-3)");
        check_reg(18, 32'd3,            "DIV  (-10)/(-3)");
        check_reg(20, 32'hFFFFFFFF,     "DIV  5/0");
        check_reg(22, 32'h80000000,     "DIV  0x80000000/(-1)");

        // Check DIVU results (tests 7-8)
        check_reg(25, 32'h40000000,     "DIVU 0x80000000/2");
        check_reg(26, 32'hFFFFFFFF,     "DIVU 5/0");

        // Check REM results (tests 9-13)
        check_reg(27, 32'd1,            "REM  10%3");
        check_reg(28, 32'hFFFFFFFF,     "REM  (-10)%3");
        check_reg(29, 32'd1,            "REM  10%(-3)");
        check_reg(30, 32'd5,            "REM  5%0");
        check_reg(2,  32'd0,            "REM  0x80000000%(-1)");

        // Check REMU results (tests 14-15)
        check_reg(3,  32'd2,            "REMU 0x80000000%3");
        check_reg(4,  32'd5,            "REMU 5%0");

        // Check combined program results (test 16)
        check_reg(7,  32'd14,           "DIV  100/7");
        check_reg(8,  32'd14,           "DIVU 100/7");
        check_reg(9,  32'd2,            "REM  100%7");
        check_reg(31, 32'd2,            "REMU 100%7");

        // ------------------------------------------------------------------
        // Final
        // ------------------------------------------------------------------
        if (failures == 0)
            $display("\n*** PHASE 6 ALL TESTS PASSED ***");
        else
            $display("\n*** PHASE 6 TESTS FAILED: %0d failure(s) ***", failures);
        $finish;
    end

endmodule
