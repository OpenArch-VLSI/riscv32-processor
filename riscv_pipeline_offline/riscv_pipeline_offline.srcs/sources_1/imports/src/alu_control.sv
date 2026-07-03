/*
 * Module: alu_control
 * Description: Decodes control-unit ALU operation class and instruction fields
 *              into a concrete ALU operation.
 * Inputs: alu_op, funct3, funct7_bit5
 * Outputs: alu_ctrl
 */
module alu_control (
    input  logic [3:0] alu_op,
    input  logic [2:0] funct3,
    input  logic       funct7_bit5,
    input  logic       funct7_bit0,
    output logic [4:0] alu_ctrl
);

    localparam logic [3:0] ALU_OP_ADD    = 4'b0000;
    localparam logic [3:0] ALU_OP_BRANCH = 4'b0001;
    localparam logic [3:0] ALU_OP_RTYPE  = 4'b0010;
    localparam logic [3:0] ALU_OP_ITYPE  = 4'b0011;
    localparam logic [4:0] ALU_CTRL_DIV  = 5'b01110;
    localparam logic [4:0] ALU_CTRL_DIVU = 5'b01111;
    localparam logic [4:0] ALU_CTRL_REM  = 5'b10000;
    localparam logic [4:0] ALU_CTRL_REMU = 5'b10001;

    always_comb begin
        alu_ctrl = 5'b00000;

        unique case (alu_op)
            ALU_OP_ADD: begin
                alu_ctrl = 5'b00000;
            end

            ALU_OP_BRANCH: begin
                alu_ctrl = 5'b00001;
            end

            ALU_OP_RTYPE: begin
                if (funct7_bit0) begin
                    unique case (funct3)
                        3'b000: alu_ctrl = 5'b01010; // MUL
                        3'b001: alu_ctrl = 5'b01011; // MULH
                        3'b010: alu_ctrl = 5'b01100; // MULHSU
                        3'b011: alu_ctrl = 5'b01101; // MULHU
                        3'b100: alu_ctrl = ALU_CTRL_DIV;  // DIV
                        3'b101: alu_ctrl = ALU_CTRL_DIVU; // DIVU
                        3'b110: alu_ctrl = ALU_CTRL_REM;  // REM
                        3'b111: alu_ctrl = ALU_CTRL_REMU; // REMU
                        default: alu_ctrl = 5'b00000;
                    endcase
                end else begin
                    unique case (funct3)
                        3'b000: alu_ctrl = funct7_bit5 ? 5'b00001 : 5'b00000;
                        3'b001: alu_ctrl = 5'b00101;
                        3'b010: alu_ctrl = 5'b01000;
                        3'b011: alu_ctrl = 5'b01001;
                        3'b100: alu_ctrl = 5'b00100;
                        3'b101: alu_ctrl = funct7_bit5 ? 5'b00111 : 5'b00110;
                        3'b110: alu_ctrl = 5'b00011;
                        3'b111: alu_ctrl = 5'b00010;
                        default: alu_ctrl = 5'b00000;
                    endcase
                end
            end

            ALU_OP_ITYPE: begin
                unique case (funct3)
                    3'b000: alu_ctrl = 5'b00000;
                    3'b001: alu_ctrl = 5'b00101;
                    3'b010: alu_ctrl = 5'b01000;
                    3'b011: alu_ctrl = 5'b01001;
                    3'b100: alu_ctrl = 5'b00100;
                    3'b101: alu_ctrl = funct7_bit5 ? 5'b00111 : 5'b00110;
                    3'b110: alu_ctrl = 5'b00011;
                    3'b111: alu_ctrl = 5'b00010;
                    default: alu_ctrl = 5'b00000;
                endcase
            end

            default: begin
                alu_ctrl = 5'b00000;
            end
        endcase
    end

endmodule
