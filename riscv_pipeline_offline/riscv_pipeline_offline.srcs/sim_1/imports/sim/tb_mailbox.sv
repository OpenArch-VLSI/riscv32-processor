`timescale 1ns / 1ps

module tb_mailbox;

    logic        clk;
    logic        rst_n;

    // Core 0 access port
    logic [31:0] c0_addr;
    logic [31:0] c0_wdata;
    logic        c0_we;
    logic        c0_re;
    logic [31:0] c0_rdata;
    logic        c0_valid;

    // Core 1 access port
    logic [31:0] c1_addr;
    logic [31:0] c1_wdata;
    logic        c1_we;
    logic        c1_re;
    logic [31:0] c1_rdata;
    logic        c1_valid;

    ipc_mailbox uut (
        .clk     (clk),
        .rst_n   (rst_n),
        .c0_addr (c0_addr),
        .c0_wdata(c0_wdata),
        .c0_we   (c0_we),
        .c0_re   (c0_re),
        .c0_rdata(c0_rdata),
        .c0_valid(c0_valid),
        .c1_addr (c1_addr),
        .c1_wdata(c1_wdata),
        .c1_we   (c1_we),
        .c1_re   (c1_re),
        .c1_rdata(c1_rdata),
        .c1_valid(c1_valid)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test sequence
    initial begin
        // Initialize inputs
        rst_n = 1'b0;
        c0_addr = 0; c0_wdata = 0; c0_we = 0; c0_re = 0;
        c1_addr = 0; c1_wdata = 0; c1_we = 0; c1_re = 0;

        #20 rst_n = 1'b1;
        #10;

        // 1. Reset state check
        c0_re = 1'b1;
        for (int i = 0; i < 4; i++) begin
            c0_addr = i * 4;
            #10;
            if (c0_rdata !== 32'h0) $fatal(1, "MAILBOX TEST FAILED");
        end
        c0_re = 1'b0;
        #10;

        // 2. Core 0 writes DEAD_BEEF to C0_TO_C1_DATA (addr 0)
        c0_we = 1'b1; c0_addr = 32'd0; c0_wdata = 32'hDEAD_BEEF;
        #10 c0_we = 1'b0;

        // Core 1 reads it back
        c1_re = 1'b1; c1_addr = 32'd0;
        #10;
        if (c1_rdata !== 32'hDEAD_BEEF) $fatal(1, "MAILBOX TEST FAILED");
        if (c1_valid !== 1'b1) $fatal(1, "MAILBOX TEST FAILED");
        c1_re = 1'b0;
        #10;
        if (c1_valid !== 1'b0) $fatal(1, "MAILBOX TEST FAILED"); // check 1-cycle pulse

        // 3. Core 1 writes CAFE_BABE to C1_TO_C0_DATA (addr 8)
        c1_we = 1'b1; c1_addr = 32'd8; c1_wdata = 32'hCAFE_BABE;
        #10 c1_we = 1'b0;

        // Core 0 reads it back
        c0_re = 1'b1; c0_addr = 32'd8;
        #10;
        if (c0_rdata !== 32'hCAFE_BABE) $fatal(1, "MAILBOX TEST FAILED");
        c0_re = 1'b0;
        #10;

        // 4. Flag protocol
        // Core 0 writes 1 to C0_TO_C1_FLAG (addr 4)
        c0_we = 1'b1; c0_addr = 32'd4; c0_wdata = 32'd1;
        #10 c0_we = 1'b0;
        // Core 1 reads it as 1
        c1_re = 1'b1; c1_addr = 32'd4;
        #10;
        if (c1_rdata !== 32'd1) $fatal(1, "MAILBOX TEST FAILED");
        c1_re = 1'b0;
        // Core 1 writes 0 to C0_TO_C1_FLAG
        c1_we = 1'b1; c1_addr = 32'd4; c1_wdata = 32'd0;
        #10 c1_we = 1'b0;
        // Core 0 reads it as 0
        c0_re = 1'b1; c0_addr = 32'd4;
        #10;
        if (c0_rdata !== 32'd0) $fatal(1, "MAILBOX TEST FAILED");
        c0_re = 1'b0;
        #10;

        // 5. Simultaneous access
        c0_re = 1'b1; c0_addr = 32'd0; // C0 reads C0_TO_C1_DATA (DEAD_BEEF)
        c1_re = 1'b1; c1_addr = 32'd8; // C1 reads C1_TO_C0_DATA (CAFE_BABE)
        #10;
        if (c0_rdata !== 32'hDEAD_BEEF) $fatal(1, "MAILBOX TEST FAILED");
        if (c1_rdata !== 32'hCAFE_BABE) $fatal(1, "MAILBOX TEST FAILED");
        c0_re = 1'b0; c1_re = 1'b0;
        #10;

        // 6. Write collision on C0_TO_C1_DATA (addr 0)
        c0_we = 1'b1; c0_addr = 32'd0; c0_wdata = 32'hAAAAAAAA;
        c1_we = 1'b1; c1_addr = 32'd0; c1_wdata = 32'hBBBBBBBB;
        #10;
        c0_we = 1'b0; c1_we = 1'b0;
        
        c0_re = 1'b1; c0_addr = 32'd0;
        #10;
        if (c0_rdata !== 32'hAAAAAAAA) $fatal(1, "MAILBOX TEST FAILED");
        c0_re = 1'b0;
        #10;

        // 7. Write FFFFFFFF
        c1_we = 1'b1; c1_addr = 32'd12; c1_wdata = 32'hFFFF_FFFF;
        #10 c1_we = 1'b0;
        c1_re = 1'b1; c1_addr = 32'd12;
        #10;
        if (c1_rdata !== 32'hFFFF_FFFF) $fatal(1, "MAILBOX TEST FAILED");
        c1_re = 1'b0;
        #10;

        // 8. Sequential writes
        c0_we = 1'b1;
        c0_addr = 32'd0; c0_wdata = 32'h11111111; #10;
        c0_addr = 32'd4; c0_wdata = 32'h22222222; #10;
        c0_addr = 32'd8; c0_wdata = 32'h33333333; #10;
        c0_addr = 32'd12; c0_wdata = 32'h44444444; #10;
        c0_we = 1'b0;
        #10;

        c1_re = 1'b1;
        c1_addr = 32'd0; #10; if (c1_rdata !== 32'h11111111) $fatal(1, "MAILBOX TEST FAILED");
        c1_addr = 32'd4; #10; if (c1_rdata !== 32'h22222222) $fatal(1, "MAILBOX TEST FAILED");
        c1_addr = 32'd8; #10; if (c1_rdata !== 32'h33333333) $fatal(1, "MAILBOX TEST FAILED");
        c1_addr = 32'd12; #10; if (c1_rdata !== 32'h44444444) $fatal(1, "MAILBOX TEST FAILED");
        c1_re = 1'b0;
        #10;

        // 9. Pulsed read pattern
        c0_we = 1'b1; c0_addr = 32'd0; c0_wdata = 32'h12345678;
        #10 c0_we = 1'b0;

        c1_re = 1'b1; c1_addr = 32'd0;
        #10; // hold high for exactly 1 clock cycle (10ns because #10 was used between edges)
        c1_re = 1'b0;
        // Check immediately after deasserting
        if (c1_valid !== 1'b1) $fatal(1, "MAILBOX TEST FAILED");
        if (c1_rdata !== 32'h12345678) $fatal(1, "MAILBOX TEST FAILED");
        #10;

        $display("*** tb_mailbox PASSED ***");
        $finish;
    end

endmodule
