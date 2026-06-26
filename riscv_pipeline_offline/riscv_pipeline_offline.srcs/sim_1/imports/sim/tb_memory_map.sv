/*
 * Module: tb_memory_map
 * Description: Memory map regression test for Phase 11.
 *              Runs entirely in simulation without a C program.
 */
`timescale 1ns/1ps

module tb_memory_map;

    logic clk;
    logic rst;
    int   failures;

    logic uart_txd;
    logic uart_rxd_tb;
    logic instr_load_en;
    logic [9:0]  instr_load_word_addr;
    logic [31:0] instr_load_data;

    top uut (
        .clk      (clk),
        .rst      (rst),
        .instr_load_en       (instr_load_en),
        .instr_load_word_addr(instr_load_word_addr),
        .instr_load_data     (instr_load_data),
        .uart_rxd (uart_rxd_tb),
        .uart_txd (uart_txd)
    );

    initial uart_rxd_tb = 1'b1;
    initial instr_load_en = 1'b0;
    initial instr_load_word_addr = 0;
    initial instr_load_data = 0;

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task mmio_read(input logic [31:0] addr, output logic [31:0] got);
        force uut.u_mem_stage.ex_mem_alu_result = addr;
        force uut.u_mem_stage.ex_mem_mem_read   = 1'b1;
        force uut.u_mem_stage.ex_mem_mem_write  = 1'b0;
        force uut.u_mem_stage.ex_mem_funct3     = 3'b010;
        #1; // allow combinational path to propagate
        got = uut.u_mem_stage.mem_wb_mem_read_data_in;
        release uut.u_mem_stage.ex_mem_alu_result;
        release uut.u_mem_stage.ex_mem_mem_read;
        release uut.u_mem_stage.ex_mem_mem_write;
    endtask

    task mmio_write(input logic [31:0] addr, input logic [31:0] data);
        force uut.u_mem_stage.ex_mem_alu_result = addr;
        force uut.u_mem_stage.ex_mem_rs2_data   = data;
        force uut.u_mem_stage.ex_mem_mem_read   = 1'b0;
        force uut.u_mem_stage.ex_mem_mem_write  = 1'b1;
        force uut.u_mem_stage.ex_mem_funct3     = 3'b010; // SW (aligned word)
        @(posedge clk);
        #1;
        release uut.u_mem_stage.ex_mem_alu_result;
        release uut.u_mem_stage.ex_mem_rs2_data;
        release uut.u_mem_stage.ex_mem_mem_read;
        release uut.u_mem_stage.ex_mem_mem_write;
        release uut.u_mem_stage.ex_mem_funct3;
    endtask

    task automatic run_cycles(input int count);
        int c;
        for (c = 0; c < count; c++)
            @(posedge clk);
        #1;
    endtask

    logic [31:0] got;

    initial begin
        failures = 0;
        rst = 1'b1;
        run_cycles(5);
        rst = 1'b0;
        run_cycles(5);

        $display("--- Starting tb_memory_map regressions ---");

        // 1. RAM Read/Write
        $display("Test 1: RAM (0x00000000, 0x00000010)");
        mmio_write(32'h00000000, 32'hDEADBEEF);
        mmio_write(32'h00000010, 32'hCAFEBABE);
        mmio_read(32'h00000000, got);
        assert(got === 32'hDEADBEEF) else begin $error("RAM[0] fail: got %h", got); failures++; end
        mmio_read(32'h00000010, got);
        assert(got === 32'hCAFEBABE) else begin $error("RAM[0x10] fail: got %h", got); failures++; end

        // 2. UART Write shouldn't affect RAM
        $display("Test 2: UART (0x80000004)");
        mmio_write(32'h80000004, 32'h55555555); // write TX register
        mmio_read(32'h00000000, got); // re-read RAM[0]
        assert(got === 32'hDEADBEEF) else begin $error("UART write corrupted RAM: got %h", got); failures++; end

        // 3. Perf Counters (Read-Only)
        $display("Test 3: Perf Counters (0xC0000000, 0xC0000004)");
        mmio_read(32'hC0000000, got); // cycle count
        assert(got !== 32'hx) else begin $error("Perf Cycle got X"); failures++; end
        assert(got === uut.perf_cycle_count) else begin $error("Perf Cycle mismatch: got %h, expected %h", got, uut.perf_cycle_count); failures++; end
        
        mmio_read(32'hC0000004, got); // instr count
        assert(got === uut.perf_instr_count) else begin $error("Perf Instr mismatch: got %h, expected %h", got, uut.perf_instr_count); failures++; end

        // 4. Timer MMIO
        $display("Test 4: Timer (0xC0000200-208)");
        // Write mtimecmp (0xC0000204)
        mmio_write(32'hC0000204, 32'h00000005);
        // Reset mtime (0xC0000200)
        mmio_write(32'hC0000200, 32'h00000000);
        // Enable timer (0xC0000208 bit 0)
        mmio_write(32'hC0000208, 32'h00000001);
        
        // Wait until timer_irq fires
        run_cycles(10);
        assert(uut.timer_irq === 1'b1) else begin $error("Timer IRQ didn't fire"); failures++; end
        
        mmio_read(32'hC0000208, got);
        assert(got[1] === 1'b1) else begin $error("Timer Pending bit not set: got %h", got); failures++; end

        // 5. Debug Register
        $display("Test 5: Debug Register (0xC0000010)");
        mmio_read(32'hC0000010, got); // PC current
        assert(got === uut.debug_pc_current) else begin $error("Debug PC mismatch: got %h, expected %h", got, uut.debug_pc_current); failures++; end

        // 6. Unmapped Address Check
        $display("Test 6: Unmapped Address (0x40000000)");
        mmio_read(32'h40000000, got);
        assert(got === 32'd0) else begin $error("Unmapped read returned 0x%08h, expected 32'd0", got); failures++; end

        if (failures == 0) begin
            $display("*** ALL TESTS PASSED ***");
        end else begin
            $display("*** %0d TESTS FAILED ***", failures);
        end

        $finish;
    end

endmodule
