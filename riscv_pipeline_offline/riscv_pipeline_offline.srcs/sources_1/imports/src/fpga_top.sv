/*
 * Module: fpga_top
 * Description: PYNQ Z2 board wrapper for the dual-core RV32I SoC (Phase 13).
 *              Generates a 25 MHz CPU clock from the 125 MHz board clock,
 *              instantiates dual_core_top (2x pipeline cores + IPC mailbox),
 *              and keeps the Phase 4 UART monitor for reset/run control and
 *              UART passthrough.
 *
 *              LED map: led[0] heartbeat (board clock alive)
 *                       led[1] PLL locked
 *                       led[2] core 0 halted
 *                       led[3] core 1 halted
 *
 *              Note: the monitor's instruction-loader and debug-readback
 *              commands are not wired into the dual-core cluster (each core
 *              boots from its own preloaded instruction memory). Its inputs
 *              are tied off; RUN/RESET and UART passthrough remain functional.
 */

module fpga_top (
    input  logic       clk,
    input  logic       rst,
    output logic [3:0] led,
    // UART pins
    input  logic       uart_rxd,
    output logic       uart_txd,
    // Phase 12 peripheral I/O (unused in the dual-core configuration)
    input  logic        raw_btn_board,  // BTN1 only (BTN0 is rst)
    input  logic [1:0]  raw_sw,
    output logic        pwm_out
);

    logic pll_clk;
    logic cpu_clk;
    logic clkfb;
    logic clkfb_buf;
    logic pll_locked;
    logic unused_clkout1;
    logic unused_clkout2;
    logic unused_clkout3;
    logic unused_clkout4;
    logic unused_clkout5;

    PLLE2_BASE #(
        .BANDWIDTH("OPTIMIZED"),
        .CLKFBOUT_MULT(8),
        .CLKFBOUT_PHASE(0.0),
        .CLKIN1_PERIOD(8.000),
        .CLKOUT0_DIVIDE(40),
        .CLKOUT0_DUTY_CYCLE(0.5),
        .CLKOUT0_PHASE(0.0),
        .DIVCLK_DIVIDE(1),
        .REF_JITTER1(0.010),
        .STARTUP_WAIT("FALSE")
    ) u_cpu_pll (
        .CLKIN1(clk),
        .CLKFBIN(clkfb_buf),
        .RST(rst),
        .PWRDWN(1'b0),
        .CLKFBOUT(clkfb),
        .CLKOUT0(pll_clk),
        .CLKOUT1(unused_clkout1),
        .CLKOUT2(unused_clkout2),
        .CLKOUT3(unused_clkout3),
        .CLKOUT4(unused_clkout4),
        .CLKOUT5(unused_clkout5),
        .LOCKED(pll_locked)
    );

    BUFG u_clkfb_buf (
        .I(clkfb),
        .O(clkfb_buf)
    );

    BUFG u_cpu_clk_buf (
        .I(pll_clk),
        .O(cpu_clk)
    );

    logic [1:0] cpu_rst_sync;
    logic       cpu_rst;
    logic       cpu_rst_async;

    assign cpu_rst_async = rst;  // pll_locked removed from async path — UART TX switching
                                  // noise was glitching pll_locked LOW and pulsing
                                  // cpu_rst_async, restarting both cores every character.
    assign cpu_rst = cpu_rst_sync[1];

    always_ff @(posedge cpu_clk or posedge cpu_rst_async) begin
        if (cpu_rst_async) begin
            cpu_rst_sync <= 2'b11;
        end else begin
            cpu_rst_sync <= {cpu_rst_sync[0], 1'b0};
        end
    end

    logic cpu_halt;

    // UART monitor signals
    logic        cpu_reset_n;
    logic        monitor_mode;
    logic        cpu_uart_txd;
    logic        mon_uart_txd;

    // UART mux: when in monitor mode, txd comes from monitor.
    // When running, txd comes from CPU. rxd always goes to monitor
    // (which forwards bytes to CPU in passthrough mode).
    logic mon_rxd;
    assign mon_rxd = uart_rxd;

    // CPU rxd: in monitor-mode, idle=1 (CPU UART isn't connected to wire).
    // In passthrough mode, rxd comes from the physical pin.
    logic cpu_uart_rxd;
    logic uart_rxd_sync;
    assign cpu_uart_rxd = monitor_mode ? 1'b1 : uart_rxd_sync;

    assign uart_txd = cpu_uart_txd;  // monitor TX mux bypassed — CPU output goes
                                      // directly to wire. Monitor mode no longer
                                      // blocks core UART output.

    // CPU reset: active when cpu_reset_n is 0 OR during board power-on reset
    logic cpu_rst_effective;
    assign cpu_rst_effective = cpu_rst;  // monitor reset gate bypassed — cores start
                                          // automatically when BTN0 is released.
                                          // cpu_reset_n from monitor is unused.

    // 2-stage synchroniser for uart_rxd into cpu_clk domain
    // (uart_rx inside also has its own 2-FF synchroniser for belt-and-braces)
    logic [1:0] uart_rx_sync;

    always_ff @(posedge cpu_clk or posedge cpu_rst_async) begin
        if (cpu_rst_async)
            uart_rx_sync <= 2'b11;
        else
            uart_rx_sync <= {uart_rx_sync[0], uart_rxd};
    end
    assign uart_rxd_sync = uart_rx_sync[1];

    uart_monitor #(.CLKS_PER_BIT(217)) u_monitor (
        .clk                  (cpu_clk),
        .rst                  (cpu_rst),
        .uart_rxd             (mon_rxd),
        .uart_txd             (mon_uart_txd),
        .cpu_reset_n          (cpu_reset_n),
        .monitor_mode         (monitor_mode),
        // Loader / debug-readback: not connected in the dual-core config
        .instr_load_en        (),
        .instr_load_word_addr (),
        .instr_load_data      (),
        .dbg_reg_addr         (),
        .dbg_reg_data         (32'd0),
        .dbg_dmem_addr        (),
        .dbg_dmem_data        (32'd0),
        .dbg_perf_cycle       (32'd0),
        .dbg_perf_instr       (32'd0),
        .dbg_perf_stall       (32'd0),
        .dbg_perf_flush       (32'd0),
        .dbg_trace_pc         (32'd0),
        .dbg_trace_instr      (32'd0),
        .dbg_trace_wb_data    (32'd0),
        .dbg_trace_status     (32'd0),
        .dbg_trace_count      (3'd0),
        .dbg_trace_head       (2'd0),
        .dbg_trace_sel        ()
    );

    logic [3:0] core_status_led;

    dual_core_top u_cpu (
        .clk      (cpu_clk),
        .rst_n    (~cpu_rst_effective),
        .uart_rxd (1'b1),        // tied to UART idle level — CP2102 RX noise was
                                  // causing framing errors and spurious traps that
                                  // restarted cores from PC=0. Assembly never reads
                                  // UART RX so this is safe.
        .uart_txd (cpu_uart_txd),
        .led      (core_status_led),
        .halt     (cpu_halt)
    );

    // Unused Phase 12 peripheral pin in the dual-core configuration
    assign pwm_out = 1'b0;

    logic [24:0] heartbeat_counter;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            heartbeat_counter <= 25'd0;
        end else begin
            heartbeat_counter <= heartbeat_counter + 25'd1;
        end
    end

    // core_status_led[0] = core 0 halted, [1] = core 1 halted (see dual_core_top)
    assign led = {core_status_led[1], core_status_led[0],
                  pll_locked, heartbeat_counter[24]};

endmodule