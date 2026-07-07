/*
 * Module: ex_stage
 * Description: Execute stage with operand forwarding, ALU operation, branch
 *              condition evaluation, jump target generation, and CSR write
 *              data computation.
 * Inputs: ID/EX values, EX/MEM forwarding source, MEM/WB forwarding source,
 *         mepc, mtvec for trap/MRET handling
 * Outputs: EX/MEM candidate values, branch redirect, forwarding selects,
 *          CSR write data
 */
module ex_stage (
    input  logic        clk,
    input  logic        rst,
    input  logic        flush,
    input  logic        id_ex_valid,
    output logic        ex_stall,
    input  logic [31:0] id_ex_pc,
    input  logic [31:0] id_ex_rs1_data,
    input  logic [31:0] id_ex_rs2_data,
    input  logic [31:0] id_ex_imm,
    input  logic [4:0]  id_ex_rs1,
    input  logic [4:0]  id_ex_rs2,
    input  logic [4:0]  id_ex_rd,
    input  logic [2:0]  id_ex_funct3,
    input  logic [6:0]  id_ex_opcode,
    input  logic [4:0]  id_ex_alu_control,
    input  logic        id_ex_reg_write,
    input  logic        id_ex_mem_read,
    input  logic        id_ex_mem_write,
    input  logic        id_ex_mem_to_reg,
    input  logic        id_ex_alu_src,
    input  logic        id_ex_branch,
    input  logic        id_ex_jump,
    input  logic        id_ex_mret,
    input  logic        id_ex_is_csr_inst,
    input  logic        id_ex_csr_write,
    input  logic        id_ex_csr_imm_sel,
    input  logic [31:0] id_ex_csr_read_data,
    input  logic        id_ex_predict_taken,
    input  logic [31:0] id_ex_predict_target,
    input  logic [2:0]  id_ex_packed_op,
    input  logic [31:0] ex_mem_alu_result,
    input  logic [4:0]  ex_mem_rd,
    input  logic        ex_mem_reg_write,
    input  logic [31:0] mem_wb_write_data,
    input  logic [4:0]  mem_wb_rd,
    input  logic        mem_wb_reg_write,
    input  logic [31:0] mepc,
    input  logic [31:0] mtvec,
    output logic [31:0] ex_mem_alu_result_in,
    output logic [31:0] ex_mem_rs2_data_in,
    output logic [31:0] ex_mem_branch_target_in,
    output logic [4:0]  ex_mem_rd_in,
    output logic [2:0]  ex_mem_funct3_in,
    output logic        ex_mem_branch_taken_in,
    output logic        ex_mem_reg_write_in,
    output logic        ex_mem_mem_read_in,
    output logic        ex_mem_mem_write_in,
    output logic        ex_mem_mem_to_reg_in,
    output logic        ex_mem_is_csr_inst,
    output logic        ex_mem_csr_write,
    output logic [31:0] ex_mem_csr_write_data,
    output logic [1:0]  forward_a,
    output logic [1:0]  forward_b,
    output logic        pc_sel,
    output logic [31:0] branch_target,
    output logic        trap_flush,
    output logic        mret_exec
);

    localparam logic [6:0] OPCODE_BRANCH = 7'b1100011;
    localparam logic [6:0] OPCODE_JALR   = 7'b1100111;
    localparam logic [6:0] OPCODE_JAL    = 7'b1101111;
    localparam logic [6:0] OPCODE_LUI    = 7'b0110111;
    localparam logic [6:0] OPCODE_AUIPC  = 7'b0010111;

    logic [31:0] operand_a_forwarded;
    logic [31:0] operand_b_forwarded;
    logic [31:0] operand_b_selected;
    logic [31:0] alu_result_raw;
    logic        alu_zero;
    logic        branch_condition_met;
    logic [31:0] csr_write_data_raw;

    forwarding_unit u_forwarding_unit (
        .ex_mem_rd(ex_mem_rd),
        .mem_wb_rd(mem_wb_rd),
        .ex_mem_reg_write(ex_mem_reg_write),
        .mem_wb_reg_write(mem_wb_reg_write),
        .id_ex_rs1(id_ex_rs1),
        .id_ex_rs2(id_ex_rs2),
        .forward_a(forward_a),
        .forward_b(forward_b)
    );

    always_comb begin
        unique case (forward_a)
            2'b10: operand_a_forwarded = ex_mem_alu_result;
            2'b01: operand_a_forwarded = mem_wb_write_data;
            default: operand_a_forwarded = id_ex_rs1_data;
        endcase

        unique case (forward_b)
            2'b10: operand_b_forwarded = ex_mem_alu_result;
            2'b01: operand_b_forwarded = mem_wb_write_data;
            default: operand_b_forwarded = id_ex_rs2_data;
        endcase
    end

    assign operand_b_selected = id_ex_alu_src ? id_ex_imm : operand_b_forwarded;

    alu u_alu (
        .alu_ctrl(id_ex_alu_control),
        .operand_a(operand_a_forwarded),
        .operand_b(operand_b_selected),
        .result(alu_result_raw),
        .zero(alu_zero)
    );

    // =================================================================
    // Multi-Cycle Divider (Iterative Shift-Subtract)
    // =================================================================
    logic is_div_inst;
    assign is_div_inst = (id_ex_alu_control == 5'b01110) || (id_ex_alu_control == 5'b01111) ||
                         (id_ex_alu_control == 5'b10000) || (id_ex_alu_control == 5'b10001);

    logic is_signed_div;
    assign is_signed_div = (id_ex_alu_control == 5'b01110) || (id_ex_alu_control == 5'b10000);

    typedef enum logic [1:0] { IDLE, DIVIDING, DONE } div_state_t;
    div_state_t div_state;

    logic [31:0] div_dividend;
    logic [31:0] div_divisor;
    logic [31:0] div_quotient;
    logic [31:0] div_remainder;
    logic [5:0]  div_count;
    logic        div_sign_q;
    logic        div_sign_r;
    logic        div_by_zero;
    logic        div_overflow;

    assign ex_stall = (div_state == DIVIDING) || (is_div_inst && id_ex_valid && div_state == IDLE);

    always_ff @(posedge clk) begin
        if (rst || flush) begin
            div_state <= IDLE;
        end else begin
            unique case (div_state)
                IDLE: begin
                    if (is_div_inst && id_ex_valid) begin
                        if ((operand_b_selected == 32'd0) || (is_signed_div && (operand_a_forwarded == 32'h80000000) && (operand_b_selected == 32'hFFFFFFFF))) begin
                            div_state <= DONE;
                            div_by_zero <= (operand_b_selected == 32'd0);
                            div_overflow <= (is_signed_div && (operand_a_forwarded == 32'h80000000) && (operand_b_selected == 32'hFFFFFFFF));
                        end else begin
                            div_state <= DIVIDING;
                            div_count <= 6'd31;
                            div_by_zero <= 1'b0;
                            div_overflow <= 1'b0;
                            
                            if (is_signed_div) begin
                                div_dividend <= operand_a_forwarded[31] ? -operand_a_forwarded : operand_a_forwarded;
                                div_divisor  <= operand_b_selected[31] ? -operand_b_selected : operand_b_selected;
                                div_sign_q   <= operand_a_forwarded[31] ^ operand_b_selected[31];
                                div_sign_r   <= operand_a_forwarded[31];
                            end else begin
                                div_dividend <= operand_a_forwarded;
                                div_divisor  <= operand_b_selected;
                                div_sign_q   <= 1'b0;
                                div_sign_r   <= 1'b0;
                            end
                            div_quotient <= 32'd0;
                            div_remainder <= 32'd0;
                        end
                    end
                end
                DIVIDING: begin
                    if (div_count == 0) begin
                        div_state <= DONE;
                    end else begin
                        div_count <= div_count - 1;
                    end
                    
                    begin : div_step
                        logic [32:0] partial_rem;
                        partial_rem = {1'b0, div_remainder[30:0], div_dividend[31]} - {1'b0, div_divisor};
                        div_dividend <= {div_dividend[30:0], 1'b0};
                        
                        if (partial_rem[32]) begin // negative (borrow)
                            div_remainder <= {div_remainder[30:0], div_dividend[31]};
                            div_quotient <= {div_quotient[30:0], 1'b0};
                        end else begin
                            div_remainder <= partial_rem[31:0];
                            div_quotient <= {div_quotient[30:0], 1'b1};
                        end
                    end
                end
                DONE: begin
                    div_state <= IDLE;
                end
                default: div_state <= IDLE;
            endcase
        end
    end

    logic [31:0] final_quotient;
    logic [31:0] final_remainder;

    always_comb begin
        if (div_by_zero) begin
            final_quotient = 32'hFFFFFFFF;
            final_remainder = operand_a_forwarded;
        end else if (div_overflow) begin
            final_quotient = 32'h80000000;
            final_remainder = 32'd0;
        end else begin
            final_quotient = div_sign_q ? -div_quotient : div_quotient;
            final_remainder = div_sign_r ? -div_remainder : div_remainder;
        end
    end

    always_comb begin
        unique case (id_ex_funct3)
            3'b000: branch_condition_met = (operand_a_forwarded == operand_b_forwarded);
            3'b001: branch_condition_met = (operand_a_forwarded != operand_b_forwarded);
            3'b100: branch_condition_met = ($signed(operand_a_forwarded) < $signed(operand_b_forwarded));
            3'b101: branch_condition_met = ($signed(operand_a_forwarded) >= $signed(operand_b_forwarded));
            3'b110: branch_condition_met = (operand_a_forwarded < operand_b_forwarded);
            3'b111: branch_condition_met = (operand_a_forwarded >= operand_b_forwarded);
            default: branch_condition_met = 1'b0;
        endcase
    end

    always_comb begin
        // Default jump/branch target
        ex_mem_branch_target_in = id_ex_pc + id_ex_imm;

        if (id_ex_opcode == OPCODE_JALR) begin
            ex_mem_branch_target_in = (operand_a_forwarded + id_ex_imm) & 32'hFFFF_FFFE;
        end

        // MRET: jump to mepc
        if (id_ex_mret) begin
            ex_mem_branch_taken_in = 1'b1;
            pc_sel = 1'b1;
            branch_target = mepc;
            mret_exec = 1'b1;
            trap_flush = 1'b0;
        end else begin
            ex_mem_branch_taken_in = (id_ex_branch && branch_condition_met) || id_ex_jump;
            
            // Misprediction Check
            if (ex_mem_branch_taken_in != id_ex_predict_taken) begin
                // Predict Taken != Actual Taken
                pc_sel = 1'b1;
                branch_target = ex_mem_branch_taken_in ? ex_mem_branch_target_in : (id_ex_pc + 32'd4);
            end else if (ex_mem_branch_taken_in && (ex_mem_branch_target_in != id_ex_predict_target)) begin
                // Both predict taken, but wrong target (e.g. JALR)
                pc_sel = 1'b1;
                branch_target = ex_mem_branch_target_in;
            end else begin
                // Prediction was correct
                pc_sel = 1'b0;
                branch_target = ex_mem_branch_target_in;
            end
            
            mret_exec = 1'b0;
            trap_flush = 1'b0;
        end

        // ALU result selection
        unique case (id_ex_opcode)
            OPCODE_LUI:   ex_mem_alu_result_in = id_ex_imm;
            OPCODE_AUIPC: ex_mem_alu_result_in = id_ex_pc + id_ex_imm;
            OPCODE_JAL,
            OPCODE_JALR:  ex_mem_alu_result_in = id_ex_pc + 32'd4;
            default: begin
                if (id_ex_alu_control == 5'b01110 || id_ex_alu_control == 5'b01111)
                    ex_mem_alu_result_in = final_quotient;
                else if (id_ex_alu_control == 5'b10000 || id_ex_alu_control == 5'b10001)
                    ex_mem_alu_result_in = final_remainder;
                else
                    ex_mem_alu_result_in = alu_result_raw;
            end
        endcase

        // For CSR instructions, the ALU result is the CSR read value
        // (which passes through to the WB stage as writeback data)
        if (id_ex_is_csr_inst) begin
            ex_mem_alu_result_in = id_ex_csr_read_data;
        end

        // Packed-SIMD override: substitute packed result for custom-0 ops
        if (id_ex_packed_op != 3'd0) begin
            ex_mem_alu_result_in = packed_result;
        end

        ex_mem_rs2_data_in   = operand_b_forwarded;
        ex_mem_rd_in         = id_ex_rd;
        ex_mem_funct3_in     = id_ex_funct3;
        ex_mem_reg_write_in  = id_ex_reg_write;
        ex_mem_mem_read_in   = id_ex_mem_read;
        ex_mem_mem_write_in  = id_ex_mem_write;
        ex_mem_mem_to_reg_in = id_ex_mem_to_reg;
    end

    // CSR write data computation
    // funct3[2] = csr_imm_sel: 0 = rs1, 1 = zero-extended 5-bit immediate
    // funct3[1:0]: 01 = CSRRW, 10 = CSRRS, 11 = CSRRC
    always_comb begin
        logic [31:0] rs1_operand;
        rs1_operand = id_ex_csr_imm_sel ? {27'd0, id_ex_rs1} : operand_a_forwarded;

        unique case (id_ex_funct3[1:0])
            2'b01: csr_write_data_raw = rs1_operand;                              // CSRRW / CSRRWI
            2'b10: csr_write_data_raw = id_ex_csr_read_data | rs1_operand;        // CSRRS / CSRRSI
            2'b11: csr_write_data_raw = id_ex_csr_read_data & ~rs1_operand;       // CSRRC / CSRRCI
            default: csr_write_data_raw = 32'd0;
        endcase
    end

    // Packed-SIMD result computation
    // Each instruction operates on 4 packed 8-bit lanes:
    //   lane 0 = bits [7:0], lane 1 = [15:8], lane 2 = [23:16], lane 3 = [31:24]
    logic [31:0] packed_result;
    always_comb begin
        packed_result = 32'd0;
        unique case (id_ex_packed_op)
            3'b000: // PADD8 — 4× 8-bit add, wrap
                packed_result = {
                    operand_a_forwarded[31:24] + operand_b_forwarded[31:24],
                    operand_a_forwarded[23:16] + operand_b_forwarded[23:16],
                    operand_a_forwarded[15:8]  + operand_b_forwarded[15:8],
                    operand_a_forwarded[7:0]   + operand_b_forwarded[7:0]
                };
            3'b001: // PSUB8 — 4× 8-bit sub, wrap
                packed_result = {
                    operand_a_forwarded[31:24] - operand_b_forwarded[31:24],
                    operand_a_forwarded[23:16] - operand_b_forwarded[23:16],
                    operand_a_forwarded[15:8]  - operand_b_forwarded[15:8],
                    operand_a_forwarded[7:0]   - operand_b_forwarded[7:0]
                };
            3'b010: // PMAXU8 — 4× unsigned 8-bit max
                packed_result = {
                    operand_a_forwarded[31:24] > operand_b_forwarded[31:24] ? operand_a_forwarded[31:24] : operand_b_forwarded[31:24],
                    operand_a_forwarded[23:16] > operand_b_forwarded[23:16] ? operand_a_forwarded[23:16] : operand_b_forwarded[23:16],
                    operand_a_forwarded[15:8]  > operand_b_forwarded[15:8]  ? operand_a_forwarded[15:8]  : operand_b_forwarded[15:8],
                    operand_a_forwarded[7:0]   > operand_b_forwarded[7:0]   ? operand_a_forwarded[7:0]   : operand_b_forwarded[7:0]
                };
            3'b011: // PMINU8 — 4× unsigned 8-bit min
                packed_result = {
                    operand_a_forwarded[31:24] < operand_b_forwarded[31:24] ? operand_a_forwarded[31:24] : operand_b_forwarded[31:24],
                    operand_a_forwarded[23:16] < operand_b_forwarded[23:16] ? operand_a_forwarded[23:16] : operand_b_forwarded[23:16],
                    operand_a_forwarded[15:8]  < operand_b_forwarded[15:8]  ? operand_a_forwarded[15:8]  : operand_b_forwarded[15:8],
                    operand_a_forwarded[7:0]   < operand_b_forwarded[7:0]   ? operand_a_forwarded[7:0]   : operand_b_forwarded[7:0]
                };
            3'b100: // PAVG8 — 4× unsigned 8-bit average, round down ((a+b)>>1)
                packed_result = {
                    (operand_a_forwarded[31:24] + operand_b_forwarded[31:24]) >> 1,
                    (operand_a_forwarded[23:16] + operand_b_forwarded[23:16]) >> 1,
                    (operand_a_forwarded[15:8]  + operand_b_forwarded[15:8])  >> 1,
                    (operand_a_forwarded[7:0]   + operand_b_forwarded[7:0])   >> 1
                };
            default: packed_result = 32'd0;
        endcase
    end

    assign ex_mem_csr_write_data = csr_write_data_raw;
    assign ex_mem_is_csr_inst    = id_ex_is_csr_inst;
    assign ex_mem_csr_write      = id_ex_csr_write;

endmodule
