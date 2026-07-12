`timescale 1ns / 1ps

module tb_phase13;

    // ----------------------------------------------------------------
    // DUT signals
    // ----------------------------------------------------------------
    logic        clk     = 0;
    logic        rst_n   = 0;
    logic        uart_rxd = 1'b1;   // idle high
    logic        uart_txd;
    logic [3:0]  led;
    logic        halt;

    // 25 MHz clock — 40 ns period
    always #20 clk = ~clk;

    // ----------------------------------------------------------------
    // DUT
    // ----------------------------------------------------------------
    dual_core_top u_dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .uart_rxd (uart_rxd),
        .uart_txd (uart_txd),
        .led      (led),
        .halt     (halt)
    );

    // ----------------------------------------------------------------
    // VCD dump
    // ----------------------------------------------------------------
    initial begin
        $dumpfile("tb_phase13.vcd");
        $dumpvars(0, tb_phase13);
    end

    // ----------------------------------------------------------------
    // UART parameters
    // Read from your uart_tx.sv — this project uses 115200 baud at 25 MHz.
    // Clocks per bit = 25_000_000 / 115200 = 217 (rounded)
    // Bit period in ns = 217 * 40 ns = 8680 ns
    // ----------------------------------------------------------------
    localparam integer CLKS_PER_BIT  = 217;
    localparam integer BIT_PERIOD_NS = CLKS_PER_BIT * 40;  // 8680 ns

    // ----------------------------------------------------------------
    // UART RX task — samples one byte from uart_txd
    // ----------------------------------------------------------------
    task automatic uart_rx_byte(output logic [7:0] data);
        integer i;
        begin
            // Wait for start bit (falling edge)
            @(negedge uart_txd);
            // Skip to middle of start bit, then skip past it to bit 0 centre
            #(BIT_PERIOD_NS / 2);
            #(BIT_PERIOD_NS);
            // Sample 8 data bits (LSB first)
            for (i = 0; i < 8; i = i + 1) begin
                data[i] = uart_txd;
                if (i < 7)
                    #(BIT_PERIOD_NS);
            end
            // Advance to centre of stop bit and verify
            #(BIT_PERIOD_NS);
            if (uart_txd !== 1'b1)
                $display("[%0t] WARNING: stop bit not high for byte 0x%02x", $time, data);
            // Consume remainder of stop bit
            #(BIT_PERIOD_NS / 2);
        end
    endtask

    // ----------------------------------------------------------------
    // String collection and verification
    // ----------------------------------------------------------------
    // We collect characters into lines (terminated by '\n').
    // Then check each line against the 5 required strings.
    //
    // Required strings (exact, no trailing whitespace):
    //   "C0: SENT 8"
    //   "C0: ACK RCVD"
    //   "C0: DUAL-CORE OK"
    //   "C1: RCVD 8"
    //   "C1: SENT 16"
    // ----------------------------------------------------------------

    // Simple string match: compare byte array against a literal.
    // We store received lines as fixed-width byte arrays (up to 32 chars).
    localparam MAX_LINE  = 32;
    localparam MAX_LINES = 20;

    reg [7:0] lines [0:MAX_LINES-1][0:MAX_LINE-1];
    integer   line_lens [0:MAX_LINES-1];
    integer   line_count;

    // Expected strings as byte arrays (null-padded)
    localparam [7:0] E0 [0:9]  = '{"C","0",":"," ","S","E","N","T"," ","8"};             // "C0: SENT 8"
    localparam [7:0] E1 [0:11] = '{"C","0",":"," ","A","C","K"," ","R","C","V","D"};    // "C0: ACK RCVD"
    localparam [7:0] E2 [0:15] = '{"C","0",":"," ","D","U","A","L","-","C","O","R","E"," ","O","K"}; // "C0: DUAL-CORE OK"
    localparam [7:0] E3 [0:9]  = '{"C","1",":"," ","R","C","V","D"," ","8"};             // "C1: RCVD 8"
    localparam [7:0] E4 [0:10] = '{"C","1",":"," ","S","E","N","T"," ","1","6"};         // "C1: SENT 16"

    localparam E0_LEN = 10;
    localparam E1_LEN = 12;
    localparam E2_LEN = 16;
    localparam E3_LEN = 10;
    localparam E4_LEN = 11;

    // Line-match function — returns 1 if line[idx] matches expected string of length elen
    function automatic integer line_matches;
        input integer idx;
        input integer elen;
        input [7:0]   expected [0:31];
        integer j;
        begin
            if (line_lens[idx] < elen) begin
                line_matches = 0;
            end else begin
                line_matches = 1;
                for (j = 0; j < elen; j = j + 1) begin
                    if (lines[idx][j] !== expected[j])
                        line_matches = 0;
                end
            end
        end
    endfunction

    // Pad expected arrays to 32 bytes for the function call
    function automatic integer check_e0(input integer idx);
        reg [7:0] e [0:31];
        integer k;
        begin
            for (k = 0; k < 32; k = k + 1) e[k] = 8'h00;
            e[0]="C"; e[1]="0"; e[2]=":"; e[3]=" ";
            e[4]="S"; e[5]="E"; e[6]="N"; e[7]="T"; e[8]=" "; e[9]="8";
            check_e0 = (line_lens[idx] == E0_LEN) && line_matches(idx, E0_LEN, e);
        end
    endfunction

    function automatic integer check_e1(input integer idx);
        reg [7:0] e [0:31];
        integer k;
        begin
            for (k = 0; k < 32; k = k + 1) e[k] = 8'h00;
            e[0]="C"; e[1]="0"; e[2]=":"; e[3]=" ";
            e[4]="A"; e[5]="C"; e[6]="K"; e[7]=" "; e[8]="R"; e[9]="C"; e[10]="V"; e[11]="D";
            check_e1 = (line_lens[idx] == E1_LEN) && line_matches(idx, E1_LEN, e);
        end
    endfunction

    function automatic integer check_e2(input integer idx);
        reg [7:0] e [0:31];
        integer k;
        begin
            for (k = 0; k < 32; k = k + 1) e[k] = 8'h00;
            e[0]="C"; e[1]="0"; e[2]=":"; e[3]=" ";
            e[4]="D"; e[5]="U"; e[6]="A"; e[7]="L"; e[8]="-"; e[9]="C";
            e[10]="O"; e[11]="R"; e[12]="E"; e[13]=" "; e[14]="O"; e[15]="K";
            check_e2 = (line_lens[idx] == E2_LEN) && line_matches(idx, E2_LEN, e);
        end
    endfunction

    function automatic integer check_e3(input integer idx);
        reg [7:0] e [0:31];
        integer k;
        begin
            for (k = 0; k < 32; k = k + 1) e[k] = 8'h00;
            e[0]="C"; e[1]="1"; e[2]=":"; e[3]=" ";
            e[4]="R"; e[5]="C"; e[6]="V"; e[7]="D"; e[8]=" "; e[9]="8";
            check_e3 = (line_lens[idx] == E3_LEN) && line_matches(idx, E3_LEN, e);
        end
    endfunction

    function automatic integer check_e4(input integer idx);
        reg [7:0] e [0:31];
        integer k;
        begin
            for (k = 0; k < 32; k = k + 1) e[k] = 8'h00;
            e[0]="C"; e[1]="1"; e[2]=":"; e[3]=" ";
            e[4]="S"; e[5]="E"; e[6]="N"; e[7]="T"; e[8]=" "; e[9]="1"; e[10]="6";
            check_e4 = (line_lens[idx] == E4_LEN) && line_matches(idx, E4_LEN, e);
        end
    endfunction

    // ----------------------------------------------------------------
    // Main test sequence
    // ----------------------------------------------------------------
    integer  found_e0, found_e1, found_e2, found_e3, found_e4;
    integer  cur_len;
    logic [7:0] rx_byte;
    integer  i, j;

    // Timeout: 500,000 cycles × 40 ns = 20 ms simulated
    // In ps-resolution timescale (1ns/1ps): 20_000_000 ns
    localparam TIMEOUT_NS = 20_000_000;

    initial begin
        // Initialise
        line_count = 0;
        cur_len    = 0;
        found_e0   = 0; found_e1 = 0; found_e2 = 0; found_e3 = 0; found_e4 = 0;
        for (i = 0; i < MAX_LINES; i = i + 1) begin
            line_lens[i] = 0;
            for (j = 0; j < MAX_LINE; j = j + 1)
                lines[i][j] = 8'h00;
        end

        // Reset
        rst_n = 0;
        repeat (10) @(posedge clk);
        rst_n = 1;

        fork
            // ---- Watchdog ----
            begin
                #(TIMEOUT_NS);
                $display("ERROR: Timeout after %0d ns. Lines received so far:", TIMEOUT_NS);
                for (i = 0; i < line_count; i = i + 1) begin
                    $write("  [%0d] \"", i);
                    for (j = 0; j < line_lens[i]; j = j + 1)
                        $write("%c", lines[i][j]);
                    $display("\"");
                end
                $fatal(1, "tb_phase13 FAILED: timeout waiting for expected UART output");
            end

            // ---- UART character collector ----
            begin
                forever begin
                    uart_rx_byte(rx_byte);
                    $display("[%0t] RX: %c (0x%02x)", $time, rx_byte, rx_byte);

                    if (rx_byte == 8'h0A || rx_byte == 8'h0D) begin
                        // End of line — evaluate if non-empty
                        if (cur_len > 0 && line_count < MAX_LINES) begin
                            line_lens[line_count] = cur_len;

                            // Print the completed line
                            $write("[%0t] LINE[%0d]: \"", $time, line_count);
                            for (j = 0; j < cur_len; j = j + 1)
                                $write("%c", lines[line_count][j]);
                            $display("\"");

                            // Check against expected strings
                            if (!found_e0 && check_e0(line_count)) begin
                                found_e0 = 1;
                                $display("[%0t] MATCHED: C0: SENT 8", $time);
                            end
                            if (!found_e1 && check_e1(line_count)) begin
                                found_e1 = 1;
                                $display("[%0t] MATCHED: C0: ACK RCVD", $time);
                            end
                            if (!found_e2 && check_e2(line_count)) begin
                                found_e2 = 1;
                                $display("[%0t] MATCHED: C0: DUAL-CORE OK", $time);
                            end
                            if (!found_e3 && check_e3(line_count)) begin
                                found_e3 = 1;
                                $display("[%0t] MATCHED: C1: RCVD 8", $time);
                            end
                            if (!found_e4 && check_e4(line_count)) begin
                                found_e4 = 1;
                                $display("[%0t] MATCHED: C1: SENT 16", $time);
                            end

                            line_count = line_count + 1;
                            cur_len    = 0;

                            // Check pass condition
                            if (found_e0 && found_e1 && found_e2 && found_e3 && found_e4) begin
                                $display("*** tb_phase13 PASSED — DUAL-CORE COMMUNICATION VERIFIED ***");
                                $finish;
                            end
                        end
                        // Ignore bare CR/LF when cur_len == 0
                    end else begin
                        // Accumulate character
                        if (cur_len < MAX_LINE && line_count < MAX_LINES) begin
                            lines[line_count][cur_len] = rx_byte;
                            cur_len = cur_len + 1;
                        end
                    end
                end
            end

            // ---- Halt monitor (both cores halted, but strings not yet seen) ----
            begin
                @(posedge halt);
                // Give UART time to finish transmitting after halt
                // Worst case: one more character at 115200 baud = ~87 µs = 87_000 ns
                #(BIT_PERIOD_NS * 12);
                if (!(found_e0 && found_e1 && found_e2 && found_e3 && found_e4)) begin
                    $display("ERROR: halt asserted before all strings received.");
                    $display("  found_e0=%0d found_e1=%0d found_e2=%0d found_e3=%0d found_e4=%0d",
                             found_e0, found_e1, found_e2, found_e3, found_e4);
                    $display("Lines received:");
                    for (i = 0; i < line_count; i = i + 1) begin
                        $write("  [%0d] \"", i);
                        for (j = 0; j < line_lens[i]; j = j + 1)
                            $write("%c", lines[i][j]);
                        $display("\"");
                    end
                    $fatal(1, "tb_phase13 FAILED: premature halt");
                end
                // If strings already found, the forever loop already called $finish
            end
        join
    end

endmodule