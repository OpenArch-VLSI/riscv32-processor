/*
 * Module: if_id_reg
 * Description: IF/ID pipeline register for fetched instruction and PC.
 * Inputs: clk, rst, stall, flush, pc_in, instr_in
 * Outputs: pc_out, instr_out
 */
module if_id_reg (
    input  logic        clk,
    input  logic        rst,
    input  logic        stall,
    input  logic        flush,
    input  logic        valid_in,
    input  logic [31:0] pc_in,
    input  logic [31:0] instr_in,
    output logic [31:0] pc_out,
    output logic [31:0] instr_out,
    output logic        valid_out
);

    localparam logic [31:0] NOP = 32'h00000013;

    always_ff @(posedge clk) begin
        if (rst) begin
            pc_out    <= 32'd0;
            instr_out <= NOP;
            valid_out <= 1'b0;
        end else if (flush) begin
            pc_out    <= 32'd0;
            instr_out <= NOP;
            valid_out <= 1'b0;
        end else if (!stall) begin
            pc_out    <= pc_in;
            instr_out <= instr_in;
            valid_out <= valid_in;
        end
    end

endmodule

/*
 * Module: id_ex_reg
 * Description: ID/EX pipeline register for decoded operands, immediates,
 *              register indexes, function fields, opcode, controls, and
 *              CSR/trap metadata.
 * Inputs: clk, rst, stall, flush, decoded ID-stage values
 * Outputs: registered EX-stage values
 */
module id_ex_reg (
    input  logic        clk,
    input  logic        rst,
    input  logic        stall,
    input  logic        flush,
    input  logic        valid_in,
    input  logic [31:0] pc_in,
    input  logic [31:0] instr_in,
    input  logic [31:0] rs1_data_in,
    input  logic [31:0] rs2_data_in,
    input  logic [31:0] imm_in,
    input  logic [4:0]  rs1_in,
    input  logic [4:0]  rs2_in,
    input  logic [4:0]  rd_in,
    input  logic [2:0]  funct3_in,
    input  logic [6:0]  opcode_in,
    input  logic [4:0]  alu_control_in,
    input  logic        reg_write_in,
    input  logic        mem_read_in,
    input  logic        mem_write_in,
    input  logic        mem_to_reg_in,
    input  logic        alu_src_in,
    input  logic        branch_in,
    input  logic        jump_in,
    input  logic        mret_in,
    input  logic        is_csr_inst_in,
    input  logic        csr_write_in,
    input  logic        csr_imm_sel_in,
    input  logic [11:0] csr_addr_in,
    input  logic [31:0] csr_read_data_in,
    input  logic        predict_taken_in,
    input  logic [31:0] predict_target_in,
    input  logic [2:0]  packed_op_in,
    output logic [31:0] pc_out,
    output logic [31:0] instr_out,
    output logic [31:0] rs1_data_out,
    output logic [31:0] rs2_data_out,
    output logic [31:0] imm_out,
    output logic [4:0]  rs1_out,
    output logic [4:0]  rs2_out,
    output logic [4:0]  rd_out,
    output logic [2:0]  funct3_out,
    output logic [6:0]  opcode_out,
    output logic [4:0]  alu_control_out,
    output logic        reg_write_out,
    output logic        mem_read_out,
    output logic        mem_write_out,
    output logic        mem_to_reg_out,
    output logic        alu_src_out,
    output logic        branch_out,
    output logic        jump_out,
    output logic        valid_out,
    output logic        mret_out,
    output logic        is_csr_inst_out,
    output logic        csr_write_out,
    output logic        csr_imm_sel_out,
    output logic [31:0] csr_read_data_out,
    output logic        predict_taken_out,
    output logic [31:0] predict_target_out,
    output logic [2:0]  packed_op_out
);

    always_ff @(posedge clk) begin
        if (rst || flush) begin
            pc_out            <= 32'd0;
            instr_out         <= 32'h00000013;
            rs1_data_out      <= 32'd0;
            rs2_data_out      <= 32'd0;
            imm_out           <= 32'd0;
            rs1_out           <= 5'd0;
            rs2_out           <= 5'd0;
            rd_out            <= 5'd0;
            funct3_out        <= 3'd0;
            opcode_out        <= 7'b0010011;
            alu_control_out   <= 5'd0;
            reg_write_out     <= 1'b0;
            mem_read_out      <= 1'b0;
            mem_write_out     <= 1'b0;
            mem_to_reg_out    <= 1'b0;
            alu_src_out       <= 1'b0;
            branch_out        <= 1'b0;
            jump_out          <= 1'b0;
            valid_out         <= 1'b0;
            mret_out          <= 1'b0;
            is_csr_inst_out   <= 1'b0;
            csr_write_out     <= 1'b0;
            csr_imm_sel_out   <= 1'b0;
            csr_read_data_out <= 32'd0;
            predict_taken_out <= 1'b0;
            predict_target_out <= 32'd0;
            packed_op_out     <= 3'd0;
        end else if (!stall) begin
            pc_out            <= pc_in;
            instr_out         <= instr_in;
            rs1_data_out      <= rs1_data_in;
            rs2_data_out      <= rs2_data_in;
            imm_out           <= imm_in;
            rs1_out           <= rs1_in;
            rs2_out           <= rs2_in;
            rd_out            <= rd_in;
            funct3_out        <= funct3_in;
            opcode_out        <= opcode_in;
            alu_control_out   <= alu_control_in;
            reg_write_out     <= reg_write_in;
            mem_read_out      <= mem_read_in;
            mem_write_out     <= mem_write_in;
            mem_to_reg_out    <= mem_to_reg_in;
            alu_src_out       <= alu_src_in;
            branch_out        <= branch_in;
            jump_out          <= jump_in;
            valid_out         <= valid_in;
            mret_out          <= mret_in;
            is_csr_inst_out   <= is_csr_inst_in;
            csr_write_out     <= csr_write_in;
            csr_imm_sel_out   <= csr_imm_sel_in;
            csr_read_data_out <= csr_read_data_in;
            predict_taken_out <= predict_taken_in;
            predict_target_out <= predict_target_in;
            packed_op_out     <= packed_op_in;
        end
    end

endmodule

/*
 * Module: ex_mem_reg
 * Description: EX/MEM pipeline register for ALU result, store data, branch
 *              metadata, destination register, controls, and CSR data.
 * Inputs: clk, rst, stall, flush, EX-stage values
 * Outputs: registered MEM-stage values
 */
module ex_mem_reg (
    input  logic        clk,
    input  logic        rst,
    input  logic        stall,
    input  logic        flush,
    input  logic        valid_in,
    input  logic [31:0] pc_in,
    input  logic [31:0] instr_in,
    input  logic [31:0] alu_result_in,
    input  logic [31:0] rs2_data_in,
    input  logic [31:0] branch_target_in,
    input  logic [4:0]  rd_in,
    input  logic [2:0]  funct3_in,
    input  logic        branch_taken_in,
    input  logic        reg_write_in,
    input  logic        mem_read_in,
    input  logic        mem_write_in,
    input  logic        mem_to_reg_in,
    input  logic        is_csr_inst_in,
    input  logic        csr_write_in,
    input  logic [31:0] csr_write_data_in,
    output logic [31:0] pc_out,
    output logic [31:0] instr_out,
    output logic [31:0] alu_result_out,
    output logic [31:0] rs2_data_out,
    output logic [31:0] branch_target_out,
    output logic [4:0]  rd_out,
    output logic [2:0]  funct3_out,
    output logic        branch_taken_out,
    output logic        reg_write_out,
    output logic        mem_read_out,
    output logic        mem_write_out,
    output logic        mem_to_reg_out,
    output logic        valid_out,
    output logic        is_csr_inst_out,
    output logic        csr_write_out,
    output logic [31:0] csr_write_data_out
);

    always_ff @(posedge clk) begin
        if (rst || flush) begin
            pc_out              <= 32'd0;
            instr_out           <= 32'h00000013;
            alu_result_out      <= 32'd0;
            rs2_data_out        <= 32'd0;
            branch_target_out   <= 32'd0;
            rd_out              <= 5'd0;
            funct3_out          <= 3'd0;
            branch_taken_out    <= 1'b0;
            reg_write_out       <= 1'b0;
            mem_read_out        <= 1'b0;
            mem_write_out       <= 1'b0;
            mem_to_reg_out      <= 1'b0;
            valid_out           <= 1'b0;
            is_csr_inst_out     <= 1'b0;
            csr_write_out       <= 1'b0;
            csr_write_data_out  <= 32'd0;
        end else if (!stall) begin
            pc_out              <= pc_in;
            instr_out           <= instr_in;
            alu_result_out      <= alu_result_in;
            rs2_data_out        <= rs2_data_in;
            branch_target_out   <= branch_target_in;
            rd_out              <= rd_in;
            funct3_out          <= funct3_in;
            branch_taken_out    <= branch_taken_in;
            reg_write_out       <= reg_write_in;
            mem_read_out        <= mem_read_in;
            mem_write_out       <= mem_write_in;
            mem_to_reg_out      <= mem_to_reg_in;
            valid_out           <= valid_in;
            is_csr_inst_out     <= is_csr_inst_in;
            csr_write_out       <= csr_write_in;
            csr_write_data_out  <= csr_write_data_in;
        end
    end

endmodule

/*
 * Module: mem_wb_reg
 * Description: MEM/WB pipeline register for memory data, ALU result,
 *              destination register, write-back controls, and CSR data.
 * Inputs: clk, rst, stall, flush, MEM-stage values
 * Outputs: registered WB-stage values
 */
module mem_wb_reg (
    input  logic        clk,
    input  logic        rst,
    input  logic        stall,
    input  logic        flush,
    input  logic        valid_in,
    input  logic [31:0] pc_in,
    input  logic [31:0] instr_in,
    input  logic [31:0] alu_result_in,
    input  logic [31:0] mem_read_data_in,
    input  logic [4:0]  rd_in,
    input  logic        reg_write_in,
    input  logic        mem_to_reg_in,
    input  logic        is_csr_inst_in,
    input  logic        csr_write_in,
    input  logic [11:0] csr_addr_in,
    input  logic [31:0] csr_write_data_in,
    output logic [31:0] pc_out,
    output logic [31:0] instr_out,
    output logic [31:0] alu_result_out,
    output logic [31:0] mem_read_data_out,
    output logic [4:0]  rd_out,
    output logic        reg_write_out,
    output logic        mem_to_reg_out,
    output logic        valid_out,
    output logic        is_csr_inst_out,
    output logic        csr_write_out,
    output logic [11:0] csr_addr_out,
    output logic [31:0] csr_write_data_out
);

    always_ff @(posedge clk) begin
        if (rst || flush) begin
            pc_out             <= 32'd0;
            instr_out          <= 32'h00000013;
            alu_result_out     <= 32'd0;
            mem_read_data_out  <= 32'd0;
            rd_out             <= 5'd0;
            reg_write_out      <= 1'b0;
            mem_to_reg_out     <= 1'b0;
            valid_out          <= 1'b0;
            is_csr_inst_out    <= 1'b0;
            csr_write_out      <= 1'b0;
            csr_addr_out       <= 12'd0;
            csr_write_data_out <= 32'd0;
        end else if (!stall) begin
            pc_out             <= pc_in;
            instr_out          <= instr_in;
            alu_result_out     <= alu_result_in;
            mem_read_data_out  <= mem_read_data_in;
            rd_out             <= rd_in;
            reg_write_out      <= reg_write_in;
            mem_to_reg_out     <= mem_to_reg_in;
            valid_out          <= valid_in;
            is_csr_inst_out    <= is_csr_inst_in;
            csr_write_out      <= csr_write_in;
            csr_addr_out       <= csr_addr_in;
            csr_write_data_out <= csr_write_data_in;
        end
    end

endmodule
