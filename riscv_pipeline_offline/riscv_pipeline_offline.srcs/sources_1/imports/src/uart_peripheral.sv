/*
 * Module: uart_peripheral
 * Description: Memory-mapped UART register interface.
 *
 *   Address map (alu_result[3:2] selects register, bit 31 qualifies UART space):
 *     0x80000000  R   UART_STATUS   bit0=tx_busy, bit1=rx_data_valid
 *     0x80000004  W   UART_TX_DATA  write byte[7:0] to transmit
 *     0x80000008  R   UART_RX_DATA  read received byte[7:0] (clears rx_data_valid)
 *
 *   uart_sel must be driven by the MEM stage (alu_result[31]).
 *   All other standard pipeline mem signals are passed through unchanged.
 */
module uart_peripheral #(
    parameter int CLKS_PER_BIT = 217   // 25 MHz / 115200 baud
)(
    input  logic        clk,
    input  logic        rst,
    // --- Memory bus from MEM stage ---
    input  logic        uart_sel,       // 1 when address is in UART space
    input  logic        mem_read,
    input  logic        mem_write,
    input  logic [3:0]  reg_addr,       // alu_result[3:0]
    input  logic [31:0] write_data,     // ex_mem_rs2_data
    output logic [31:0] read_data,
    // --- Physical UART pins ---
    input  logic        uart_rxd,       // from FPGA pin (already synchronised)
    output logic        uart_txd,       // to FPGA pin
    output logic        tx_busy_o       // status output
);

    // ---------------------------------------------------------------
    // TX sub-module
    // ---------------------------------------------------------------
    logic       tx_start;
    logic [7:0] tx_byte;
    logic       tx_busy;
    logic       tx_done;   // unused but good for debug visibility

    uart_tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) u_tx (
        .clk      (clk),
        .rst      (rst),
        .tx_start (tx_start),
        .tx_data  (tx_byte),
        .tx_busy  (tx_busy),
        .tx_done  (tx_done),
        .tx_serial(uart_txd)
    );

    // ---------------------------------------------------------------
    // RX sub-module
    // ---------------------------------------------------------------
    logic       rx_valid;
    logic [7:0] rx_byte_raw;

    uart_rx #(.CLKS_PER_BIT(CLKS_PER_BIT)) u_rx (
        .clk      (clk),
        .rst      (rst),
        .rx_serial(uart_rxd),
        .rx_valid (rx_valid),
        .rx_data  (rx_byte_raw)
    );

    // ---------------------------------------------------------------
    // RX holding register
    // ---------------------------------------------------------------
    logic [7:0] rx_hold_data;
    logic       rx_data_valid;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            rx_hold_data  <= 8'h00;
            rx_data_valid <= 1'b0;
        end else begin
            if (rx_valid) begin
                rx_hold_data  <= rx_byte_raw;
                rx_data_valid <= 1'b1;
            end
            // Reading RX_DATA register clears the valid flag
            if (uart_sel && mem_read && (reg_addr[3:2] == 2'b10)) begin
                rx_data_valid <= 1'b0;
            end
        end
    end

    // ---------------------------------------------------------------
    // TX write pulse logic
    // ---------------------------------------------------------------
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            tx_start <= 1'b0;
            tx_byte  <= 8'h00;
        end else begin
            tx_start <= 1'b0;   // default: deasserted
            if (uart_sel && mem_write && (reg_addr[3:2] == 2'b01)) begin
                tx_start <= 1'b1;
                tx_byte  <= write_data[7:0];
            end
        end
    end

    // ---------------------------------------------------------------
    // Read mux
    // ---------------------------------------------------------------
    always_comb begin
        read_data = 32'd0;
        if (uart_sel && mem_read) begin
            case (reg_addr[3:2])
                2'b00:   read_data = {30'b0, rx_data_valid, tx_busy};  // STATUS
                2'b10:   read_data = {24'b0, rx_hold_data};            // RX_DATA
                default: read_data = 32'd0;
            endcase
        end
    end

    assign tx_busy_o = tx_busy;

endmodule
