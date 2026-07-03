/*
 * Module: id_stage
 * Description: Instruction decode, immediate generation, control decode,
 *              CSR read, and register-file read stage.
 * Inputs: clk, rst, if_id_instr, if_id_pc, flush, wb write-back interface,
 *         csr_read_data, dbg_reg_addr
 * Outputs: decoded values and controls for the ID/EX register, trap signals,
 *          dbg_reg_data
 */
module id_stage (
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] if_id_instr,
    input  logic [31:0] if_id_pc,
    input  logic        bht_predict_taken,
    input  logic        flush,
    input  logic        wb_reg_write,
    input  logic [4:0]  wb_rd,
    input  logic [31:0] wb_write_data,
    input  logic [31:0] csr_read_data,
    output logic [31:0] id_ex_pc,
    output logic [31:0] id_ex_rs1_data,
    output logic [31:0] id_ex_rs2_data,
    output logic [31:0] id_ex_imm,
    output logic [4:0]  id_ex_rs1,
    output logic [4:0]  id_ex_rs2,
    output logic [4:0]  id_ex_rd,
    output logic [2:0]  id_ex_funct3,
    output logic [6:0]  id_ex_opcode,
    output logic [4:0]  id_ex_alu_control,
    output logic        id_ex_reg_write,
    output logic        id_ex_mem_read,
    output logic        id_ex_mem_write,
    output logic        id_ex_mem_to_reg,
    output logic        id_ex_alu_src,
    output logic        id_ex_branch,
    output logic        id_ex_jump,
    output logic        id_ex_mret,
    output logic        id_ex_is_csr_inst,
    output logic        id_ex_csr_write,
    output logic        id_ex_csr_imm_sel,
    output logic [2:0]  id_ex_packed_op,
    output logic [11:0] id_ex_csr_addr,
    output logic [31:0] id_ex_csr_read_data,
    output logic        halt,
    output logic        illegal_instr,
    output logic        trap_taken,
    output logic [31:0] trap_cause,
    output logic [31:0] trap_pc,
    output logic        id_predict_taken,
    output logic [31:0] id_predict_target,
    input  logic [4:0]  dbg_reg_addr,
    output logic [31:0] dbg_reg_data
);

    logic [6:0] opcode;
    logic [2:0] funct3;
    logic       funct7_bit5;
    logic       funct7_bit0;
    logic [3:0] alu_op;
    logic       reg_write_dec;
    logic       mem_read_dec;
    logic       mem_write_dec;
    logic       mem_to_reg_dec;
    logic       alu_src_dec;
    logic       branch_dec;
    logic       jump_dec;
    logic       halt_dec;
    logic       illegal_instr_dec;
    logic       csr_read_dec;
    logic       csr_write_dec;
    logic       mret_dec;
    logic       csr_imm_sel_dec;
    logic       is_csr_inst_dec;
    logic [2:0] packed_op_dec;
    logic [31:0] imm_dec;
    logic [4:0] alu_control_dec;

    assign opcode      = if_id_instr[6:0];
    assign id_ex_rd    = if_id_instr[11:7];
    assign funct3      = if_id_instr[14:12];
    assign id_ex_rs1   = if_id_instr[19:15];
    assign id_ex_rs2   = if_id_instr[24:20];
    assign funct7_bit5 = if_id_instr[30];
    assign funct7_bit0 = if_id_instr[25];

    assign id_ex_pc     = if_id_pc;
    assign id_ex_imm    = imm_dec;
    assign id_ex_funct3 = funct3;
    assign id_ex_opcode = opcode;

    control_unit u_control_unit (
        .opcode(opcode),
        .funct3(funct3),
        .funct7_bit5(funct7_bit5),
        .funct12(if_id_instr[31:20]),
        .reg_write(reg_write_dec),
        .mem_read(mem_read_dec),
        .mem_write(mem_write_dec),
        .mem_to_reg(mem_to_reg_dec),
        .alu_src(alu_src_dec),
        .branch(branch_dec),
        .jump(jump_dec),
        .alu_op(alu_op),
        .halt(halt_dec),
        .illegal_instr(illegal_instr_dec),
        .csr_read(csr_read_dec),
        .csr_write(csr_write_dec),
        .mret(mret_dec),
        .csr_imm_sel(csr_imm_sel_dec),
        .is_csr_inst(is_csr_inst_dec),
        .packed_op(packed_op_dec)
    );

    alu_control u_alu_control (
        .alu_op(alu_op),
        .funct3(funct3),
        .funct7_bit5(funct7_bit5),
        .funct7_bit0(funct7_bit0),
        .alu_ctrl(alu_control_dec)
    );

    imm_gen u_imm_gen (
        .instr(if_id_instr),
        .imm(imm_dec)
    );

    reg_file u_reg_file (
        .clk(clk),
        .rst(rst),
        .reg_write(wb_reg_write),
        .rs1(id_ex_rs1),
        .rs2(id_ex_rs2),
        .rd(wb_rd),
        .write_data(wb_write_data),
        .rs1_data(id_ex_rs1_data),
        .rs2_data(id_ex_rs2_data),
        .dbg_addr(dbg_reg_addr),
        .dbg_data(dbg_reg_data)
    );

    // CSR read data: pass through to ID/EX register
    // For CSR instructions, this is the value read from the CSR.
    // For non-CSR instructions, it's unused (don't-care).
    assign id_ex_csr_read_data = csr_read_data;
    assign id_ex_packed_op     = packed_op_dec;

    // Trap detection: generate trap on ECALL/EBREAK or illegal instruction
    // mcause: 11 = ECALL from M-mode, 2 = illegal instruction, 3 = EBREAK
    logic        is_ecall;
    logic        is_ebreak;
    logic [31:0] trap_cause_dec;

    assign is_ecall  = (opcode == 7'b1110011) && (funct3 == 3'b000) && (if_id_instr[31:20] == 12'h000);
    assign is_ebreak = (opcode == 7'b1110011) && (funct3 == 3'b000) && (if_id_instr[31:20] == 12'h001);

    always_comb begin
        trap_cause_dec = 32'd0;
        if (is_ecall)
            trap_cause_dec = 32'd11;  // Environment call from M-mode
        else if (is_ebreak)
            trap_cause_dec = 32'd3;   // Breakpoint
        else if (illegal_instr_dec)
            trap_cause_dec = 32'd2;   // Illegal instruction
    end

    assign trap_taken = halt_dec || illegal_instr_dec;
    assign trap_cause = trap_cause_dec;
    assign trap_pc    = if_id_pc;

    // Dynamic Branch Prediction
    logic is_branch_inst;
    logic is_jal_inst;

    assign is_branch_inst = (opcode == 7'b1100011);
    assign is_jal_inst    = (opcode == 7'b1101111);

    always_comb begin
        id_predict_taken = 1'b0;
        if (is_jal_inst) begin
            id_predict_taken = 1'b1;
        end else if (is_branch_inst) begin
            id_predict_taken = bht_predict_taken;
        end
    end

    assign id_predict_target = if_id_pc + imm_dec;

    always_comb begin
        if (rst || flush) begin
            id_ex_alu_control   = 5'd0;
            id_ex_reg_write     = 1'b0;
            id_ex_mem_read      = 1'b0;
            id_ex_mem_write     = 1'b0;
            id_ex_mem_to_reg    = 1'b0;
            id_ex_alu_src       = 1'b0;
            id_ex_branch        = 1'b0;
            id_ex_jump          = 1'b0;
            id_ex_mret          = 1'b0;
            id_ex_is_csr_inst   = 1'b0;
            id_ex_csr_write     = 1'b0;
            id_ex_csr_imm_sel   = 1'b0;
            halt                = 1'b0;
            illegal_instr       = 1'b0;
        end else begin
            id_ex_alu_control   = alu_control_dec;
            id_ex_reg_write     = reg_write_dec;
            id_ex_mem_read      = mem_read_dec;
            id_ex_mem_write     = mem_write_dec;
            id_ex_mem_to_reg    = mem_to_reg_dec;
            id_ex_alu_src       = alu_src_dec;
            id_ex_branch        = branch_dec;
            id_ex_jump          = jump_dec;
            id_ex_mret          = mret_dec;
            id_ex_is_csr_inst   = is_csr_inst_dec;
            id_ex_csr_write     = csr_write_dec;
            id_ex_csr_imm_sel   = csr_imm_sel_dec;
            halt                = halt_dec;
            illegal_instr       = illegal_instr_dec;
        end
    end

endmodule
