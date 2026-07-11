/*
 * Module: top
 * Description: Top-level 32-bit 5-stage pipelined RV32I processor. Instantiates
 *              fetch, decode, execute, memory, write-back, pipeline registers,
 *              hazard detection, forwarding, instruction memory, data memory,
 *              register file through their stage modules,
 *              CSR file, and timer peripheral.
 *              UART pins are threaded through to mem_stage.
 *              Instruction-memory loader inputs are exposed for Phase 4.
 *              Performance counters: cycle, instruction, stall, flush.
 *              halt: asserted on ECALL/EBREAK, freezes the pipeline.
 *              trap: trap entry redirects PC to mtvec, saves mepc/mcause.
 * Inputs: clk, rst, uart_rxd, instr_load_*, dbg_reg_addr, dbg_dmem_addr,
 *         dbg_trace_sel, cpu_reset_n
 * Outputs: debug trace, uart_txd, halt, dbg_reg_data, dbg_dmem_data,
 *          dbg_perf_*, dbg_trace_*, dbg_trace_count, dbg_trace_head
 */
(* keep_hierarchy = "yes" *)
module top #(
    parameter logic CORE_ID = 1'b0
)(
    input  logic        clk,
    input  logic        rst,
    output logic [31:0] debug_pc_current,
    output logic        debug_wb_reg_write,
    output logic [4:0]  debug_wb_rd,
    output logic [31:0] debug_wb_write_data,
    output logic        halt,
    input  logic        instr_load_en,
    input  logic [9:0]  instr_load_word_addr,
    input  logic [31:0] instr_load_data,
    // UART pins (connected to mem_stage -> uart_peripheral)
    input  logic        uart_rxd,
    output logic        uart_txd,
    // Debug read ports for UART monitor
    input  logic [4:0]  dbg_reg_addr,
    output logic [31:0] dbg_reg_data,
    input  logic [9:0]  dbg_dmem_addr,
    output logic [31:0] dbg_dmem_data,
    output logic [31:0] dbg_perf_cycle,
    output logic [31:0] dbg_perf_instr,
    output logic [31:0] dbg_perf_stall,
    output logic [31:0] dbg_perf_flush,
    input  logic [1:0]  dbg_trace_sel,
    output logic [31:0] dbg_trace_pc,
    output logic [31:0] dbg_trace_instr,
    output logic [31:0] dbg_trace_wb_data,
    output logic [31:0] dbg_trace_status,
    output logic [2:0]  dbg_trace_count,
    output logic [1:0]  dbg_trace_head,
    // Phase 12 peripheral I/O
    output logic [3:0]  led_out,
    output logic        led_sw_ctrl,
    input  logic [1:0]  raw_btn,
    input  logic [1:0]  raw_sw,
    output logic        pwm_out,
    // Phase 13 dual-core mailbox
    output logic [31:0] mbx_addr,
    output logic [31:0] mbx_wdata,
    output logic        mbx_we,
    output logic        mbx_re,
    input  logic [31:0] mbx_rdata,
    input  logic        mbx_valid,
    output logic        uart_tx_busy_o
);

    logic [31:0] pc_current;
    logic [31:0] if_pc;
    logic [31:0] if_instr;
    logic [31:0] if_id_pc;
    logic [31:0] if_id_instr;
    logic        if_id_valid;

    logic [31:0] id_pc;
    logic [31:0] id_rs1_data;
    logic [31:0] id_rs2_data;
    logic [31:0] id_imm;
    logic [4:0]  id_rs1;
    logic [4:0]  id_rs2;
    logic [4:0]  id_rd;
    logic [2:0]  id_funct3;
    logic [6:0]  id_opcode;
    logic [4:0]  id_alu_control;
    logic        id_reg_write;
    logic        id_mem_read;
    logic        id_mem_write;
    logic        id_mem_to_reg;
    logic        id_alu_src;
    logic        id_branch;
    logic        id_jump;
    logic        id_mret;
    logic        id_is_csr_inst;
    logic        id_csr_write;
    logic        id_csr_imm_sel;
    logic [31:0] id_csr_read_data;
    logic        halt_id;
    logic        illegal_id;
    logic        trap_taken;
    logic [31:0] trap_cause;
    logic [31:0] trap_pc;
    logic        id_predict_taken;
    logic [31:0] id_predict_target;
    logic        id_predict_taken_valid;
    logic [2:0]  id_packed_op;
    logic [2:0]  id_ex_packed_op;

    logic [31:0] id_ex_pc;
    logic [31:0] id_ex_instr;
    logic [31:0] id_ex_rs1_data;
    logic [31:0] id_ex_rs2_data;
    logic [31:0] id_ex_imm;
    logic [4:0]  id_ex_rs1;
    logic [4:0]  id_ex_rs2;
    logic [4:0]  id_ex_rd;
    logic [2:0]  id_ex_funct3;
    logic [6:0]  id_ex_opcode;
    logic [4:0]  id_ex_alu_control;
    logic        id_ex_reg_write;
    logic        id_ex_mem_read;
    logic        id_ex_mem_write;
    logic        id_ex_mem_to_reg;
    logic        id_ex_alu_src;
    logic        id_ex_branch;
    logic        id_ex_jump;
    logic        id_ex_valid;
    logic        id_ex_mret;
    logic        id_ex_is_csr_inst;
    logic        id_ex_csr_write;
    logic        id_ex_csr_imm_sel;
    logic [31:0] id_ex_csr_read_data;
    logic        id_ex_predict_taken;
    logic [31:0] id_ex_predict_target;

    logic [31:0] ex_alu_result;
    logic [31:0] ex_rs2_data;
    logic [31:0] ex_branch_target;
    logic [4:0]  ex_rd;
    logic [2:0]  ex_funct3;
    logic        ex_branch_taken;
    logic        ex_reg_write;
    logic        ex_mem_read;
    logic        ex_mem_write;
    logic        ex_mem_to_reg;
    logic        ex_is_csr_inst;
    logic        ex_csr_write;
    logic [31:0] ex_csr_write_data;

    logic [31:0] ex_mem_pc;
    logic [31:0] ex_mem_instr;
    logic [31:0] ex_mem_alu_result;
    logic [31:0] ex_mem_rs2_data;
    logic [31:0] ex_mem_branch_target;
    logic [4:0]  ex_mem_rd;
    logic [2:0]  ex_mem_funct3;
    logic        ex_mem_branch_taken;
    logic        ex_mem_reg_write;
    logic        ex_mem_mem_read;
    logic        ex_mem_mem_write;
    logic        ex_mem_mem_to_reg;
    logic        ex_mem_valid;
    logic        ex_mem_is_csr_inst;
    logic        ex_mem_csr_write;
    logic [31:0] ex_mem_csr_write_data;

    logic [31:0] mem_alu_result;
    logic [31:0] mem_read_data;
    logic [4:0]  mem_rd;
    logic        mem_reg_write;
    logic        mem_mem_to_reg;
    logic        mem_is_csr_inst;
    logic        mem_csr_write;
    logic [11:0] mem_csr_addr;
    logic [31:0] mem_csr_write_data;

    logic [31:0] mem_wb_pc;
    logic [31:0] mem_wb_instr;
    logic [31:0] mem_wb_alu_result;
    logic [31:0] mem_wb_mem_read_data;
    logic [4:0]  mem_wb_rd;
    logic        mem_wb_reg_write;
    logic        mem_wb_mem_to_reg;
    logic        mem_wb_valid;
    logic        mem_wb_is_csr_inst;
    logic        mem_wb_csr_write;
    logic [11:0] mem_wb_csr_addr;
    logic [31:0] mem_wb_csr_write_data;

    logic [31:0] wb_write_data;
    logic [4:0]  wb_rd;
    logic        wb_reg_write;

    logic        stall;
    logic        ex_stall;
    logic        flush;
    logic        flush_if_id;
    logic        flush_id_ex;
    logic        trap_flush;
    logic        mret_exec;
    logic        halt_latched;
    logic        illegal_latched;
    logic        pc_sel;
    logic        pc_sel_combined;
    logic [31:0] branch_target;
    logic [31:0] mepc;
    logic [31:0] mtvec;
    logic        mie;
    logic [1:0]  forward_a;
    logic [1:0]  forward_b;
    logic [31:0] perf_cycle_count;
    logic [31:0] perf_instr_count;
    logic [31:0] perf_stall_count;
    logic [31:0] perf_flush_count;

    logic [31:0] debug_last_commit_pc;
    logic [31:0] debug_last_commit_instr;
    logic [31:0] debug_last_wb_write_data;
    logic [4:0]  debug_last_wb_rd;
    logic        debug_last_wb_reg_write;
    logic [31:0] debug_fault_pc;
    logic [31:0] debug_fault_instr;

    logic [4:0] if_id_rs1_for_hazard;
    logic [4:0] if_id_rs2_for_hazard;
    logic       if_id_uses_rs1;
    logic       if_id_uses_rs2;
    logic       effective_stall;

    // CSR file signals
    logic [31:0] csr_read_data;
    logic [11:0] csr_read_addr;
    logic        csr_write_en;
    logic [11:0] csr_write_addr;
    logic [31:0] csr_write_data;

    // Timer signals
    logic [31:0] timer_read_data;
    logic        timer_irq;

    // Combined PC redirect: branch/jump, trap, MRET, or timer IRQ
    // Timer IRQ is gated by MIE (machine interrupt enable)
    logic        effective_timer_irq;
    logic [31:0] if_branch_target;
    logic        id_trap_valid;

    assign effective_stall = stall || ex_stall;

    // A trap in ID is only valid if an older instruction in EX is not flushing it!
    assign id_trap_valid = trap_taken && !pc_sel && !mret_exec && !ex_stall;

    assign effective_timer_irq = timer_irq && mie && !ex_stall;
    
    // Validate ID prediction (must not predict if bubbling or overridden by older flush)
    assign id_predict_taken_valid = id_predict_taken && if_id_valid && !pc_sel && !mret_exec && !id_trap_valid && !effective_timer_irq && !effective_stall;

    assign pc_sel_combined = pc_sel || id_trap_valid || mret_exec || effective_timer_irq || id_predict_taken_valid;
    assign if_branch_target = (id_trap_valid || effective_timer_irq) ? mtvec :
                              (pc_sel || mret_exec) ? branch_target : 
                              id_predict_target;

    // For trap with timer IRQ, capture the interrupt flag in mcause
    logic [31:0] final_trap_cause;
    logic [31:0] final_trap_pc;

    assign final_trap_cause = timer_irq ? 32'h80000007 : trap_cause;
    assign final_trap_pc    = timer_irq ? pc_current : trap_pc;

    assign flush_if_id = pc_sel_combined;
    assign flush_id_ex = pc_sel || id_trap_valid || mret_exec || effective_timer_irq;
    assign flush = flush_id_ex; // For ID/EX and ID stage
    
    // effective_stall is assigned above

    // =================================================================
    // Branch History Table (BHT)
    // =================================================================
    logic bht_predict_taken;

    bht #(
        .ENTRIES(64)
    ) u_bht (
        .clk(clk),
        .rst(rst),
        .read_pc(if_id_pc),
        .predict_taken(bht_predict_taken),
        .update_en(id_ex_valid && id_ex_branch),
        .update_pc(id_ex_pc),
        .actual_taken(ex_branch_taken)
    );

    always_comb begin
        unique case (if_id_instr[6:0])
            7'b0110011,
            7'b0100011,
            7'b1100011,
            7'b0001011: begin
                if_id_uses_rs1 = 1'b1;
                if_id_uses_rs2 = 1'b1;
            end
            7'b0010011,
            7'b0000011,
            7'b1100111: begin
                if_id_uses_rs1 = 1'b1;
                if_id_uses_rs2 = 1'b0;
            end
            default: begin
                if_id_uses_rs1 = 1'b0;
                if_id_uses_rs2 = 1'b0;
            end
        endcase
    end

    assign if_id_rs1_for_hazard = if_id_uses_rs1 ? if_id_instr[19:15] : 5'd0;
    assign if_id_rs2_for_hazard = if_id_uses_rs2 ? if_id_instr[24:20] : 5'd0;

    // =================================================================
    // CSR File
    // =================================================================
    csr_file u_csr_file (
        .clk            (clk),
        .rst            (rst),
        .csr_read_addr  (if_id_instr[31:20]),
        .csr_read_data  (csr_read_data),
        .csr_write_en   (csr_write_en),
        .csr_write_addr (csr_write_addr),
        .csr_write_data (csr_write_data),
        .trap_taken     (id_trap_valid || effective_timer_irq),
        .trap_cause     (final_trap_cause),
        .trap_pc        (final_trap_pc),
        .mret_exec      (id_mret),
        .mepc           (mepc),
        .mtvec          (mtvec),
        .mie            (mie)
    );

    // =================================================================
    // Pipeline
    // =================================================================
    (* DONT_TOUCH = "yes" *) if_stage u_if_stage (
        .clk(clk),
        .rst(rst),
        .stall(effective_stall),
        .pc_sel(pc_sel_combined),
        .branch_target(if_branch_target),
        .instr_load_en(instr_load_en),
        .instr_load_word_addr(instr_load_word_addr),
        .instr_load_data(instr_load_data),
        .if_id_pc(if_pc),
        .if_id_instr(if_instr),
        .pc_current(pc_current)
    );

    (* DONT_TOUCH = "yes" *) if_id_reg u_if_id_reg (
        .clk(clk),
        .rst(rst),
        .stall(effective_stall),
        .flush(flush_if_id),
        .valid_in(1'b1),
        .pc_in(if_pc),
        .instr_in(if_instr),
        .pc_out(if_id_pc),
        .instr_out(if_id_instr),
        .valid_out(if_id_valid)
    );

    (* DONT_TOUCH = "yes" *) hazard_detection_unit u_hazard_detection_unit (
        .id_ex_rd(id_ex_rd),
        .id_ex_mem_read(id_ex_mem_read),
        .if_id_rs1(if_id_rs1_for_hazard),
        .if_id_rs2(if_id_rs2_for_hazard),
        .stall(stall)
    );

    (* DONT_TOUCH = "yes" *) id_stage u_id_stage (
        .clk(clk),
        .rst(rst),
        .if_id_instr(if_id_instr),
        .if_id_pc(if_id_pc),
        .bht_predict_taken(bht_predict_taken),
        .flush(flush_id_ex),
        .wb_reg_write(wb_reg_write),
        .wb_rd(wb_rd),
        .wb_write_data(wb_write_data),
        .csr_read_data(csr_read_data),
        .id_ex_pc(id_pc),
        .id_ex_rs1_data(id_rs1_data),
        .id_ex_rs2_data(id_rs2_data),
        .id_ex_imm(id_imm),
        .id_ex_rs1(id_rs1),
        .id_ex_rs2(id_rs2),
        .id_ex_rd(id_rd),
        .id_ex_funct3(id_funct3),
        .id_ex_opcode(id_opcode),
        .id_ex_alu_control(id_alu_control),
        .id_ex_reg_write(id_reg_write),
        .id_ex_mem_read(id_mem_read),
        .id_ex_mem_write(id_mem_write),
        .id_ex_mem_to_reg(id_mem_to_reg),
        .id_ex_alu_src(id_alu_src),
        .id_ex_branch(id_branch),
        .id_ex_jump(id_jump),
        .id_ex_mret(id_mret),
        .id_ex_is_csr_inst(id_is_csr_inst),
        .id_ex_csr_write(id_csr_write),
        .id_ex_csr_imm_sel(id_csr_imm_sel),
        .id_ex_csr_read_data(id_csr_read_data),
        .halt(halt_id),
        .illegal_instr(illegal_id),
        .trap_taken(trap_taken),
        .trap_cause(trap_cause),
        .trap_pc(trap_pc),
        .id_predict_taken(id_predict_taken),
        .id_predict_target(id_predict_target),
        .id_ex_packed_op(id_packed_op),
        .dbg_reg_addr(dbg_reg_addr),
        .dbg_reg_data(dbg_reg_data)
    );

    (* DONT_TOUCH = "yes" *) id_ex_reg u_id_ex_reg (
        .clk(clk),
        .rst(rst),
        .stall(ex_stall),
        .flush(flush || stall),
        .valid_in(if_id_valid),
        .pc_in(id_pc),
        .instr_in(if_id_instr),
        .rs1_data_in(id_rs1_data),
        .rs2_data_in(id_rs2_data),
        .imm_in(id_imm),
        .rs1_in(id_rs1),
        .rs2_in(id_rs2),
        .rd_in(id_rd),
        .funct3_in(id_funct3),
        .opcode_in(id_opcode),
        .alu_control_in(id_alu_control),
        .reg_write_in(id_reg_write),
        .mem_read_in(id_mem_read),
        .mem_write_in(id_mem_write),
        .mem_to_reg_in(id_mem_to_reg),
        .alu_src_in(id_alu_src),
        .branch_in(id_branch),
        .jump_in(id_jump),
        .mret_in(id_mret),
        .is_csr_inst_in(id_is_csr_inst),
        .csr_write_in(id_csr_write),
        .csr_imm_sel_in(id_csr_imm_sel),
        .csr_read_data_in(id_csr_read_data),
        .predict_taken_in(id_predict_taken_valid),
        .predict_target_in(id_predict_target),
        .packed_op_in(id_packed_op),
        .pc_out(id_ex_pc),
        .instr_out(id_ex_instr),
        .rs1_data_out(id_ex_rs1_data),
        .rs2_data_out(id_ex_rs2_data),
        .imm_out(id_ex_imm),
        .rs1_out(id_ex_rs1),
        .rs2_out(id_ex_rs2),
        .rd_out(id_ex_rd),
        .funct3_out(id_ex_funct3),
        .opcode_out(id_ex_opcode),
        .alu_control_out(id_ex_alu_control),
        .reg_write_out(id_ex_reg_write),
        .mem_read_out(id_ex_mem_read),
        .mem_write_out(id_ex_mem_write),
        .mem_to_reg_out(id_ex_mem_to_reg),
        .alu_src_out(id_ex_alu_src),
        .branch_out(id_ex_branch),
        .jump_out(id_ex_jump),
        .valid_out(id_ex_valid),
        .mret_out(id_ex_mret),
        .is_csr_inst_out(id_ex_is_csr_inst),
        .csr_write_out(id_ex_csr_write),
        .csr_imm_sel_out(id_ex_csr_imm_sel),
        .csr_read_data_out(id_ex_csr_read_data),
        .predict_taken_out(id_ex_predict_taken),
        .predict_target_out(id_ex_predict_target),
        .packed_op_out(id_ex_packed_op)
    );

    (* DONT_TOUCH = "yes" *) ex_stage u_ex_stage (
        .clk(clk),
        .rst(rst),
        .flush(flush_id_ex),
        .id_ex_valid(id_ex_valid),
        .ex_stall(ex_stall),
        .id_ex_pc(id_ex_pc),
        .id_ex_rs1_data(id_ex_rs1_data),
        .id_ex_rs2_data(id_ex_rs2_data),
        .id_ex_imm(id_ex_imm),
        .id_ex_rs1(id_ex_rs1),
        .id_ex_rs2(id_ex_rs2),
        .id_ex_rd(id_ex_rd),
        .id_ex_funct3(id_ex_funct3),
        .id_ex_opcode(id_ex_opcode),
        .id_ex_alu_control(id_ex_alu_control),
        .id_ex_reg_write(id_ex_reg_write),
        .id_ex_mem_read(id_ex_mem_read),
        .id_ex_mem_write(id_ex_mem_write),
        .id_ex_mem_to_reg(id_ex_mem_to_reg),
        .id_ex_alu_src(id_ex_alu_src),
        .id_ex_branch(id_ex_branch),
        .id_ex_jump(id_ex_jump),
        .id_ex_mret(id_ex_mret),
        .id_ex_is_csr_inst(id_ex_is_csr_inst),
        .id_ex_csr_write(id_ex_csr_write),
        .id_ex_csr_imm_sel(id_ex_csr_imm_sel),
        .id_ex_csr_read_data(id_ex_csr_read_data),
        .id_ex_predict_taken(id_ex_predict_taken),
        .id_ex_predict_target(id_ex_predict_target),
        .id_ex_packed_op(id_ex_packed_op),
        .ex_mem_alu_result(ex_mem_alu_result),
        .ex_mem_rd(ex_mem_rd),
        .ex_mem_reg_write(ex_mem_reg_write),
        .mem_wb_write_data(wb_write_data),
        .mem_wb_rd(mem_wb_rd),
        .mem_wb_reg_write(mem_wb_reg_write),
        .mepc(mepc),
        .mtvec(mtvec),
        .ex_mem_alu_result_in(ex_alu_result),
        .ex_mem_rs2_data_in(ex_rs2_data),
        .ex_mem_branch_target_in(ex_branch_target),
        .ex_mem_rd_in(ex_rd),
        .ex_mem_funct3_in(ex_funct3),
        .ex_mem_branch_taken_in(ex_branch_taken),
        .ex_mem_reg_write_in(ex_reg_write),
        .ex_mem_mem_read_in(ex_mem_read),
        .ex_mem_mem_write_in(ex_mem_write),
        .ex_mem_mem_to_reg_in(ex_mem_to_reg),
        .ex_mem_is_csr_inst(ex_is_csr_inst),
        .ex_mem_csr_write(ex_csr_write),
        .ex_mem_csr_write_data(ex_csr_write_data),
        .forward_a(forward_a),
        .forward_b(forward_b),
        .pc_sel(pc_sel),
        .branch_target(branch_target),
        .trap_flush(trap_flush),
        .mret_exec(mret_exec)
    );

    (* DONT_TOUCH = "yes" *) ex_mem_reg u_ex_mem_reg (
        .clk(clk),
        .rst(rst),
        .stall(1'b0),
        .flush(ex_stall),
        .valid_in(id_ex_valid),
        .pc_in(id_ex_pc),
        .instr_in(id_ex_instr),
        .alu_result_in(ex_alu_result),
        .rs2_data_in(ex_rs2_data),
        .branch_target_in(ex_branch_target),
        .rd_in(ex_rd),
        .funct3_in(ex_funct3),
        .branch_taken_in(ex_branch_taken),
        .reg_write_in(ex_reg_write),
        .mem_read_in(ex_mem_read),
        .mem_write_in(ex_mem_write),
        .mem_to_reg_in(ex_mem_to_reg),
        .is_csr_inst_in(ex_is_csr_inst),
        .csr_write_in(ex_csr_write),
        .csr_write_data_in(ex_csr_write_data),
        .pc_out(ex_mem_pc),
        .instr_out(ex_mem_instr),
        .alu_result_out(ex_mem_alu_result),
        .rs2_data_out(ex_mem_rs2_data),
        .branch_target_out(ex_mem_branch_target),
        .rd_out(ex_mem_rd),
        .funct3_out(ex_mem_funct3),
        .branch_taken_out(ex_mem_branch_taken),
        .reg_write_out(ex_mem_reg_write),
        .mem_read_out(ex_mem_mem_read),
        .mem_write_out(ex_mem_mem_write),
        .mem_to_reg_out(ex_mem_mem_to_reg),
        .valid_out(ex_mem_valid),
        .is_csr_inst_out(ex_mem_is_csr_inst),
        .csr_write_out(ex_mem_csr_write),
        .csr_write_data_out(ex_mem_csr_write_data)
    );

    (* DONT_TOUCH = "yes" *) mem_stage #(
        .CORE_ID(CORE_ID)
    ) u_mem_stage (
        .clk                    (clk),
        .rst                    (rst),
        .ex_mem_alu_result      (ex_mem_alu_result),
        .ex_mem_rs2_data        (ex_mem_rs2_data),
        .ex_mem_rd              (ex_mem_rd),
        .ex_mem_funct3          (ex_mem_funct3),
        .ex_mem_reg_write       (ex_mem_reg_write),
        .ex_mem_mem_read        (ex_mem_mem_read),
        .ex_mem_mem_write       (ex_mem_mem_write),
        .ex_mem_mem_to_reg      (ex_mem_mem_to_reg),
        .ex_mem_is_csr_inst     (ex_mem_is_csr_inst),
        .ex_mem_csr_write       (ex_mem_csr_write),
        .ex_mem_csr_write_data  (ex_mem_csr_write_data),
        .ex_mem_instr           (ex_mem_instr),
        .mem_wb_alu_result_in   (mem_alu_result),
        .mem_wb_mem_read_data_in(mem_read_data),
        .mem_wb_rd_in           (mem_rd),
        .mem_wb_reg_write_in    (mem_reg_write),
        .mem_wb_mem_to_reg_in   (mem_mem_to_reg),
        .mem_wb_is_csr_inst     (mem_is_csr_inst),
        .mem_wb_csr_write       (mem_csr_write),
        .mem_wb_csr_addr        (mem_csr_addr),
        .mem_wb_csr_write_data  (mem_csr_write_data),
        .perf_cycle_count       (perf_cycle_count),
        .perf_instr_count       (perf_instr_count),
        .perf_stall_count       (perf_stall_count),
        .perf_flush_count       (perf_flush_count),
        .timer_read_data        (timer_read_data),
        .timer_irq              (timer_irq),
        .debug_pc_current       (pc_current),
        .debug_last_commit_pc   (debug_last_commit_pc),
        .debug_last_commit_instr(debug_last_commit_instr),
        .debug_last_wb_data     (debug_last_wb_write_data),
        .debug_last_wb_rd       (debug_last_wb_rd),
        .debug_last_wb_reg_write(debug_last_wb_reg_write),
        .debug_fault_pc         (debug_fault_pc),
        .debug_fault_instr      (debug_fault_instr),
        .debug_halt             (halt_latched),
        .debug_illegal          (illegal_latched),
        .debug_stall            (stall),
        .debug_flush            (flush),
        .debug_pc_sel           (pc_sel),
        .debug_commit_valid     (mem_wb_valid),
        .debug_commit_pc        (mem_wb_pc),
        .debug_commit_instr     (mem_wb_instr),
        .debug_commit_rd        (wb_rd),
        .debug_commit_reg_write (wb_reg_write),
        .debug_commit_wb_data   (wb_write_data),
        // UART pins threaded to peripheral
        .uart_rxd               (uart_rxd),
        .uart_txd               (uart_txd),
        // Debug read port for UART monitor
        .dbg_dmem_addr          (dbg_dmem_addr),
        .dbg_dmem_data          (dbg_dmem_data),
        .mon_trace_pc           (dbg_trace_pc),
        .mon_trace_instr         (dbg_trace_instr),
        .mon_trace_wb_data      (dbg_trace_wb_data),
        .mon_trace_status       (dbg_trace_status),
        .mon_trace_count        (dbg_trace_count),
        .mon_trace_head         (dbg_trace_head),
        .mon_trace_sel          (dbg_trace_sel),
        // Phase 12 peripheral I/O
        .led_out                (led_out),
        .led_sw_ctrl            (led_sw_ctrl),
        .raw_btn                (raw_btn),
        .raw_sw                 (raw_sw),
        .pwm_out                (pwm_out),
        .mbx_addr               (mbx_addr),
        .mbx_wdata              (mbx_wdata),
        .mbx_we                 (mbx_we),
        .mbx_re                 (mbx_re),
        .mbx_rdata              (mbx_rdata),
        .mbx_valid              (mbx_valid),
        .uart_tx_busy_o         (uart_tx_busy_o)
    );

    (* DONT_TOUCH = "yes" *) mem_wb_reg u_mem_wb_reg (
        .clk(clk),
        .rst(rst),
        .stall(1'b0),
        .flush(1'b0),
        .valid_in(ex_mem_valid),
        .pc_in(ex_mem_pc),
        .instr_in(ex_mem_instr),
        .alu_result_in(mem_alu_result),
        .mem_read_data_in(mem_read_data),
        .rd_in(mem_rd),
        .reg_write_in(mem_reg_write),
        .mem_to_reg_in(mem_mem_to_reg),
        .is_csr_inst_in(mem_is_csr_inst),
        .csr_write_in(mem_csr_write),
        .csr_addr_in(mem_csr_addr),
        .csr_write_data_in(mem_csr_write_data),
        .pc_out(mem_wb_pc),
        .instr_out(mem_wb_instr),
        .alu_result_out(mem_wb_alu_result),
        .mem_read_data_out(mem_wb_mem_read_data),
        .rd_out(mem_wb_rd),
        .reg_write_out(mem_wb_reg_write),
        .mem_to_reg_out(mem_wb_mem_to_reg),
        .valid_out(mem_wb_valid),
        .is_csr_inst_out(mem_wb_is_csr_inst),
        .csr_write_out(mem_wb_csr_write),
        .csr_addr_out(mem_wb_csr_addr),
        .csr_write_data_out(mem_wb_csr_write_data)
    );

    (* DONT_TOUCH = "yes" *) wb_stage u_wb_stage (
        .mem_wb_alu_result(mem_wb_alu_result),
        .mem_wb_mem_read_data(mem_wb_mem_read_data),
        .mem_wb_rd(mem_wb_rd),
        .mem_wb_reg_write(mem_wb_reg_write),
        .mem_wb_mem_to_reg(mem_wb_mem_to_reg),
        .mem_wb_is_csr_inst(mem_wb_is_csr_inst),
        .mem_wb_csr_write(mem_wb_csr_write),
        .mem_wb_csr_addr(mem_wb_csr_addr),
        .mem_wb_csr_write_data(mem_wb_csr_write_data),
        .wb_write_data(wb_write_data),
        .wb_rd(wb_rd),
        .wb_reg_write(wb_reg_write),
        .csr_write_en(csr_write_en),
        .csr_addr(csr_write_addr),
        .csr_write_data(csr_write_data)
    );

    assign debug_pc_current = pc_current;
    assign debug_wb_reg_write = wb_reg_write;
    assign debug_wb_rd = wb_rd;
    assign debug_wb_write_data = wb_write_data;

    assign dbg_perf_cycle = perf_cycle_count;
    assign dbg_perf_instr = perf_instr_count;
    assign dbg_perf_stall = perf_stall_count;
    assign dbg_perf_flush = perf_flush_count;

    // =================================================================
    // Debug capture
    // =================================================================
    always_ff @(posedge clk) begin
        if (rst) begin
            debug_last_commit_pc     <= 32'd0;
            debug_last_commit_instr  <= 32'h00000013;
            debug_last_wb_write_data <= 32'd0;
            debug_last_wb_rd         <= 5'd0;
            debug_last_wb_reg_write  <= 1'b0;
            debug_fault_pc           <= 32'd0;
            debug_fault_instr        <= 32'h00000013;
        end else begin
            if (mem_wb_valid) begin
                debug_last_commit_pc     <= mem_wb_pc;
                debug_last_commit_instr  <= mem_wb_instr;
                debug_last_wb_write_data <= wb_write_data;
                debug_last_wb_rd         <= wb_rd;
                debug_last_wb_reg_write  <= wb_reg_write;
            end

            if (halt_id || illegal_id) begin
                debug_fault_pc    <= if_id_pc;
                debug_fault_instr <= if_id_instr;
            end
        end
    end

    // =================================================================
    // Halt on ECALL/EBREAK (legacy: traps now handle ECALL/EBREAK)
    // halt_latched is for board-level LED indication, not pipeline stall
    // =================================================================
    always_ff @(posedge clk) begin
        if (rst) begin
            halt_latched <= 1'b0;
            illegal_latched <= 1'b0;
        end else begin
            if ((halt_id || illegal_id) && !pc_sel && !mret_exec) begin
                halt_latched <= 1'b1;
            end
            if (illegal_id && !pc_sel && !mret_exec) begin
                illegal_latched <= 1'b1;
            end
            if (id_trap_valid || mret_exec) begin
                halt_latched <= 1'b0;
            end
        end
    end

    assign halt = halt_latched;

    // =================================================================
    // Performance Counters
    // =================================================================
    always_ff @(posedge clk) begin
        if (rst) begin
            perf_cycle_count <= 32'd0;
            perf_instr_count <= 32'd0;
            perf_stall_count <= 32'd0;
            perf_flush_count <= 32'd0;
        end else begin
            perf_cycle_count <= perf_cycle_count + 32'd1;

            if (mem_wb_valid)
                perf_instr_count <= perf_instr_count + 32'd1;

            if (stall)
                perf_stall_count <= perf_stall_count + 32'd1;

            if (flush)
                perf_flush_count <= perf_flush_count + 32'd1;
        end
    end

endmodule
