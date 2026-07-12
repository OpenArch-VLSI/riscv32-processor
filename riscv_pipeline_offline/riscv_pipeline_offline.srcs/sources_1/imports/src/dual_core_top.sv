`timescale 1ns / 1ps

module dual_core_top #(
    // Boot images. Override CORE0_INIT_FILE to run a different program on
    // core 0 (e.g. sw/string_match_interactive.mem for the interactive
    // pattern-matching demo) without touching RTL:
    //   set_property generic {CORE0_INIT_FILE=<path>} [current_fileset]
    parameter string CORE0_INIT_FILE = "../../../../../asm/core0_demo.mem",
    parameter string CORE1_INIT_FILE = "../../../../../asm/core1_demo.mem"
)(
    input  logic        clk,
    input  logic        rst_n,
    input  logic        uart_rxd,
    output logic        uart_txd,
    output logic [3:0]  led,
    output logic        halt
);

    // Core 0
    logic        core0_uart_tx, core0_uart_tx_busy, core0_halt;
    logic [3:0]  core0_led;
    
    // Core 1
    logic        core1_uart_tx, core1_uart_tx_busy, core1_halt;
    logic [3:0]  core1_led;
    
    // Mailbox — Core 0 side
    logic [31:0] core0_mbx_addr, core0_mbx_wdata, core0_mbx_rdata;
    logic        core0_mbx_we, core0_mbx_re, core0_mbx_valid;
    
    // Mailbox — Core 1 side
    logic [31:0] core1_mbx_addr, core1_mbx_wdata, core1_mbx_rdata;
    logic        core1_mbx_we, core1_mbx_re, core1_mbx_valid;

    // Reset conversion (top expects active-high rst)
    logic rst;
    assign rst = ~rst_n;

    top #(
        .CORE_ID(1'b0),
        .INSTR_INIT_FILE(CORE0_INIT_FILE)
    ) u_core0 (
        .clk(clk),
        .rst(rst),
        .uart_rxd(uart_rxd),
        .uart_txd(core0_uart_tx),
        .uart_tx_busy_o(core0_uart_tx_busy),
        .halt(core0_halt),
        .mbx_addr(core0_mbx_addr),
        .mbx_wdata(core0_mbx_wdata),
        .mbx_we(core0_mbx_we),
        .mbx_re(core0_mbx_re),
        .mbx_rdata(core0_mbx_rdata),
        .mbx_valid(core0_mbx_valid),
        .led_out(core0_led),
        .led_sw_ctrl(),
        .raw_btn(2'd0),
        .raw_sw(2'd0),
        .pwm_out(),
        .instr_load_en(1'b0),
        .instr_load_word_addr(10'd0),
        .instr_load_data(32'd0),
        .dbg_reg_addr(5'd0),
        .dbg_dmem_addr(10'd0),
        .dbg_trace_sel(2'd0)
    );

    top #(
        .CORE_ID(1'b1),
        .INSTR_INIT_FILE(CORE1_INIT_FILE)
    ) u_core1 (
        .clk(clk),
        .rst(rst),
        .uart_rxd(1'b1), // Core 1 RX tied idle
        .uart_txd(core1_uart_tx),
        .uart_tx_busy_o(core1_uart_tx_busy),
        .halt(core1_halt),
        .mbx_addr(core1_mbx_addr),
        .mbx_wdata(core1_mbx_wdata),
        .mbx_we(core1_mbx_we),
        .mbx_re(core1_mbx_re),
        .mbx_rdata(core1_mbx_rdata),
        .mbx_valid(core1_mbx_valid),
        .led_out(core1_led),
        .led_sw_ctrl(),
        .raw_btn(2'd0),
        .raw_sw(2'd0),
        .pwm_out(),
        .instr_load_en(1'b0),
        .instr_load_word_addr(10'd0),
        .instr_load_data(32'd0),
        .dbg_reg_addr(5'd0),
        .dbg_dmem_addr(10'd0),
        .dbg_trace_sel(2'd0)
    );

    ipc_mailbox u_mailbox (
        .clk(clk),
        .rst_n(rst_n),
        .c0_addr(core0_mbx_addr),
        .c0_wdata(core0_mbx_wdata),
        .c0_we(core0_mbx_we),
        .c0_re(core0_mbx_re),
        .c0_rdata(core0_mbx_rdata),
        .c0_valid(core0_mbx_valid),
        .c1_addr(core1_mbx_addr),
        .c1_wdata(core1_mbx_wdata),
        .c1_we(core1_mbx_we),
        .c1_re(core1_mbx_re),
        .c1_rdata(core1_mbx_rdata),
        .c1_valid(core1_mbx_valid)
    );

    assign uart_txd = core0_uart_tx_busy ? core0_uart_tx :
                      core1_uart_tx_busy ? core1_uart_tx :
                      1'b1;

    assign halt = core0_halt | core1_halt;

    // led[0] = core 0 halted, led[1] = core 1 halted
    assign led = {2'b00, core1_halt, core0_halt};

endmodule
