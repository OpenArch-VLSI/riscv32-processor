/*
 * Module: debug_bus
 * Description: Debug register bus slave.
 *              Wraps all debug MMIO registers (0xC0000010–0xC000007F)
 *              behind the internal bus interface.
 *
 * Register map (word-aligned offsets from base 0xC0000000):
 *   0x10  current PC
 *   0x14  last committed PC
 *   0x18  last committed instruction
 *   0x1C  last writeback data
 *   0x20  last writeback status (register + reg_write flag)
 *   0x24  faulting PC
 *   0x28  faulting instruction
 *   0x2C  pipeline/debug status
 *   0x30  trace head/count
 *   0x34  last commit metadata
 *   0x38  pipeline status (alt view)
 *   0x40–0x4F  trace entry 0 (PC, instr, wb_data, status)
 *   0x50–0x5F  trace entry 1
 *   0x60–0x6F  trace entry 2
 *   0x70–0x7F  trace entry 3
 *
 * This is a single-cycle slave: ready is always 1.
 */
module debug_bus (
    input  logic        clk,
    input  logic        rst,
    // Bus slave interface
    input  bus_req_t    bus_req,
    output bus_resp_t   bus_resp,
    // Debug signals from top-level
    input  logic [31:0] debug_pc_current,
    input  logic [31:0] debug_last_commit_pc,
    input  logic [31:0] debug_last_commit_instr,
    input  logic [31:0] debug_last_wb_data,
    input  logic [4:0]  debug_last_wb_rd,
    input  logic        debug_last_wb_reg_write,
    input  logic [31:0] debug_fault_pc,
    input  logic [31:0] debug_fault_instr,
    input  logic        debug_halt,
    input  logic        debug_illegal,
    input  logic        debug_stall,
    input  logic        debug_flush,
    input  logic        debug_pc_sel,
    input  logic        debug_commit_valid,
    // Trace buffer signals (from mem_stage)
    input  logic [31:0] trace_pc     [0:3],
    input  logic [31:0] trace_instr   [0:3],
    input  logic [31:0] trace_wb_data [0:3],
    input  logic [31:0] trace_status  [0:3],
    input  logic [1:0]  trace_head,
    input  logic [2:0]  trace_count,
    input  logic        debug_commit_reg_write,
    input  logic [4:0]  debug_commit_rd
);

    import internal_bus_pkg::*;

    // ------------------------------------------------------------------
    // Read mux (combinational, single-cycle slave)
    // ------------------------------------------------------------------
    always_comb begin
        bus_resp.rdata = 32'd0;

        if (bus_req.valid && bus_req.read_en) begin
            unique case (bus_req.addr[7:2]) // word-aligned group/sub decode
                6'h04,
                6'h05: begin // 0x10–0x17
                    unique case (bus_req.addr[3:2])
                        2'b00: bus_resp.rdata = debug_pc_current;
                        2'b01: bus_resp.rdata = debug_last_commit_pc;
                        2'b10: bus_resp.rdata = debug_last_commit_instr;
                        2'b11: bus_resp.rdata = debug_last_wb_data;
                    endcase
                end

                6'h08,
                6'h09: begin // 0x20–0x27
                    unique case (bus_req.addr[3:2])
                        2'b00: bus_resp.rdata = {26'd0, debug_last_wb_reg_write, debug_last_wb_rd};
                        2'b01: bus_resp.rdata = debug_fault_pc;
                        2'b10: bus_resp.rdata = debug_fault_instr;
                        2'b11: bus_resp.rdata = {
                            20'd0,
                            debug_halt,
                            debug_illegal,
                            debug_stall,
                            debug_flush,
                            debug_pc_sel,
                            debug_commit_valid,
                            debug_last_wb_reg_write,
                            debug_last_wb_rd
                        };
                    endcase
                end

                6'h0C,
                6'h0D: begin // 0x30–0x37
                    unique case (bus_req.addr[3:2])
                        2'b00: bus_resp.rdata = {27'd0, trace_count, trace_head};
                        2'b01: bus_resp.rdata = {25'd0, debug_commit_valid, debug_last_wb_reg_write, debug_last_wb_rd};
                        2'b10: bus_resp.rdata = {
                            20'd0,
                            debug_halt,
                            debug_illegal,
                            debug_stall,
                            debug_flush,
                            debug_pc_sel,
                            debug_commit_valid,
                            debug_last_wb_reg_write,
                            debug_last_wb_rd
                        };
                        2'b11: bus_resp.rdata = 32'd0;
                    endcase
                end

                default: begin // 0x40–0x7F: trace buffer entries
                    if (bus_req.addr[7:4] >= 4'h4 && bus_req.addr[7:4] <= 4'h7) begin
                        unique case (bus_req.addr[3:2])
                            2'b00: bus_resp.rdata = trace_pc[bus_req.addr[5:4]];
                            2'b01: bus_resp.rdata = trace_instr[bus_req.addr[5:4]];
                            2'b10: bus_resp.rdata = trace_wb_data[bus_req.addr[5:4]];
                            2'b11: bus_resp.rdata = trace_status[bus_req.addr[5:4]];
                        endcase
                    end
                end
            endcase
        end
    end

    // Single-cycle slave: ready is always 1
    assign bus_resp.ready = 1'b1;

endmodule
