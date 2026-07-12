`timescale 1ns / 1ps

/*
 * tb_string_match — drives the interactive pattern-matching demo
 * (sw/demos/string_match_interactive.c) end-to-end over the UART.
 *
 * Plays scripted keystrokes into uart_rxd:
 *     Text:    ABABCABAB
 *     Pattern: ABC
 * and verifies the step-by-step alignment trace on uart_txd:
 *   - exactly one "MATCH!" line
 *   - "Matches: 1 at [2]"
 *   - alignment 0 mismatches at pattern index 2, alignment 1 at index 0
 *   - a "Cycles: " report followed by the next "Text: " prompt
 */
module tb_string_match;

    logic clk = 0;
    logic rst = 1;
    logic uart_rxd = 1'b1;   // idle high
    logic uart_txd;

    // 25 MHz clock — 40 ns period
    always #20 clk = ~clk;

    localparam integer CLKS_PER_BIT = 217;
    localparam integer BIT_NS       = CLKS_PER_BIT * 40;   // 8680 ns

    top #(
        .INSTR_INIT_FILE("c:/Users/nayak/Desktop/riscv32-processor/sw/string_match_interactive.mem")
    ) u_dut (
        .clk                 (clk),
        .rst                 (rst),
        .uart_rxd            (uart_rxd),
        .uart_txd            (uart_txd),
        .instr_load_en       (1'b0),
        .instr_load_word_addr(10'd0),
        .instr_load_data     (32'd0),
        .dbg_reg_addr        (5'd0),
        .dbg_dmem_addr       (10'd0),
        .dbg_trace_sel       (2'd0),
        .raw_btn             (2'd0),
        .raw_sw              (2'd0),
        .mbx_rdata           (32'd0),
        .mbx_valid           (1'b0)
    );

    // ----------------------------------------------------------------
    // UART receive: collect everything the CPU prints into rx_acc
    // ----------------------------------------------------------------
    string rx_acc = "";
    event  rx_char_ev;

    task automatic uart_rx_byte(output logic [7:0] data);
        integer i;
        begin
            @(negedge uart_txd);
            #(BIT_NS / 2);
            #(BIT_NS);
            for (i = 0; i < 8; i = i + 1) begin
                data[i] = uart_txd;
                if (i < 7) #(BIT_NS);
            end
            #(BIT_NS);          // centre of stop bit
            #(BIT_NS / 2);
        end
    endtask

    initial begin : rx_collector
        logic [7:0] b;
        forever begin
            uart_rx_byte(b);
            rx_acc = {rx_acc, string'(b)};
            if (b != 8'h0D) $write("%c", b);   // live console mirror
            -> rx_char_ev;
        end
    end

    // ----------------------------------------------------------------
    // UART send: scripted keystrokes into the CPU
    // ----------------------------------------------------------------
    task automatic send_byte(input logic [7:0] b);
        integer i;
        begin
            uart_rxd = 1'b0;                 // start bit
            #(BIT_NS);
            for (i = 0; i < 8; i = i + 1) begin
                uart_rxd = b[i];
                #(BIT_NS);
            end
            uart_rxd = 1'b1;                 // stop bit
            #(BIT_NS);
            #(2 * BIT_NS);                   // inter-byte gap
        end
    endtask

    task automatic send_line(input string s);
        integer i;
        begin
            for (i = 0; i < s.len(); i = i + 1)
                send_byte(s[i]);
            send_byte(8'h0D);                // Enter
        end
    endtask

    // ----------------------------------------------------------------
    // String helpers
    // ----------------------------------------------------------------
    function automatic integer find_str(input string hay, input string needle);
        integer i, j;
        begin
            find_str = -1;
            if (needle.len() == 0) return 0;
            for (i = 0; i + needle.len() <= hay.len(); i = i + 1) begin
                j = 0;
                while (j < needle.len() && hay[i + j] == needle[j]) j = j + 1;
                if (j == needle.len()) return i;
            end
        end
    endfunction

    function automatic integer count_str(input string hay, input string needle);
        integer i, j, n;
        begin
            n = 0;
            for (i = 0; i + needle.len() <= hay.len(); i = i + 1) begin
                j = 0;
                while (j < needle.len() && hay[i + j] == needle[j]) j = j + 1;
                if (j == needle.len()) n = n + 1;
            end
            return n;
        end
    endfunction

    task automatic wait_for(input string s);
        while (find_str(rx_acc, s) == -1) @(rx_char_ev);
    endtask

    task automatic wait_for_nth(input string s, input integer n);
        while (count_str(rx_acc, s) < n) @(rx_char_ev);
    endtask

    // ----------------------------------------------------------------
    // Scenario — the user's text/pattern come from (in priority order):
    //   1. pm_input.txt in the run directory (line 1 = text, line 2 =
    //      pattern) — used by run_pattern_match.ps1; immune to Windows
    //      command-line quoting, so spaces are fine
    //   2. plusargs: -testplusarg TEXT=... -testplusarg PATTERN=...
    //   3. built-in defaults (fixed regression case)
    // The expected match count/positions are recomputed here in the TB,
    // so the check is valid for ANY input.
    // ----------------------------------------------------------------
    localparam TIMEOUT_NS = 700_000_000;   // 700 ms simulated

    string text_in = "ABABCABAB";
    string pat_in  = "ABC";

    function automatic string strip_eol(input string s);
        int l = s.len();
        while (l > 0 && (s[l-1] == "\n" || s[l-1] == "\r")) l = l - 1;
        if (l == 0) return "";
        return s.substr(0, l - 1);
    endfunction

    initial begin : watchdog
        #(TIMEOUT_NS);
        $display("");
        $display("ERROR: timeout. Output so far:");
        $display("%s", rx_acc);
        $fatal(1, "tb_string_match FAILED: timeout");
    end

    initial begin : scenario
        integer exp_count;
        integer exp_first;
        integer i, j;
        string  summary;

        void'($value$plusargs("TEXT=%s", text_in));
        void'($value$plusargs("PATTERN=%s", pat_in));

        begin : file_input
            integer fd;
            string  line;
            fd = $fopen("pm_input.txt", "r");
            if (fd != 0) begin
                if ($fgets(line, fd) > 0) text_in = strip_eol(line);
                if ($fgets(line, fd) > 0) pat_in  = strip_eol(line);
                $fclose(fd);
            end
        end
        $display("TB inputs: text=\"%s\" pattern=\"%s\"", text_in, pat_in);

        // Reference model: naive search over the same inputs
        exp_count = 0;
        exp_first = -1;
        for (i = 0; i + pat_in.len() <= text_in.len(); i = i + 1) begin
            j = 0;
            while (j < pat_in.len() && text_in[i + j] == pat_in[j]) j = j + 1;
            if (j == pat_in.len()) begin
                if (exp_first == -1) exp_first = i;
                exp_count = exp_count + 1;
            end
        end

        rst = 1;
        repeat (10) @(posedge clk);
        rst = 0;

        wait_for("Text: ");
        send_line(text_in);

        wait_for("Pattern: ");
        send_line(pat_in);

        // Full report done once the next prompt appears
        wait_for("Cycles: ");
        wait_for_nth("Text: ", 2);

        // ---- Checks (input-independent, from the reference model) ----
        if (count_str(rx_acc, "MATCH!") != exp_count) begin
            $display("%s", rx_acc);
            $fatal(1, "tb_string_match FAILED: expected %0d MATCH! lines, got %0d",
                   exp_count, count_str(rx_acc, "MATCH!"));
        end
        summary = $sformatf("Matches: %0d", exp_count);
        if (find_str(rx_acc, summary) == -1) begin
            $display("%s", rx_acc);
            $fatal(1, "tb_string_match FAILED: summary '%s' missing", summary);
        end
        if (exp_count > 0) begin
            summary = $sformatf("at [%0d", exp_first);
            if (find_str(rx_acc, summary) == -1) begin
                $display("%s", rx_acc);
                $fatal(1, "tb_string_match FAILED: first match position '%s' missing",
                       summary);
            end
        end

        $display("");
        $display("*** tb_string_match PASSED — %0d match(es), as computed by the reference model ***",
                 exp_count);
        $finish;
    end

endmodule
