/*
 * Module: alu
 * Description: 32-bit RV32I arithmetic logic unit.
 * Inputs: alu_ctrl, operand_a, operand_b
 * Outputs: result, zero
 */
module alu (
    input  logic [4:0]  alu_ctrl,
    input  logic [31:0] operand_a,
    input  logic [31:0] operand_b,
    output logic [31:0] result,
    output logic        zero
);

    logic signed [63:0] mul_ss;
    logic signed [63:0] mul_su;
    logic        [63:0] mul_uu;

    assign mul_ss = $signed(operand_a) * $signed(operand_b);
    assign mul_su = $signed(operand_a) * $signed({1'b0, operand_b});
    assign mul_uu = operand_a * operand_b;

    always_comb begin
        unique case (alu_ctrl)
            5'b00000: result = operand_a + operand_b;
            5'b00001: result = operand_a - operand_b;
            5'b00010: result = operand_a & operand_b;
            5'b00011: result = operand_a | operand_b;
            5'b00100: result = operand_a ^ operand_b;
            5'b00101: result = operand_a << operand_b[4:0];
            5'b00110: result = operand_a >> operand_b[4:0];
            5'b00111: result = $signed(operand_a) >>> operand_b[4:0];
            5'b01000: result = ($signed(operand_a) < $signed(operand_b)) ? 32'd1 : 32'd0;
            5'b01001: result = (operand_a < operand_b) ? 32'd1 : 32'd0;
            5'b01010: result = mul_ss[31:0];   // MUL
            5'b01011: result = mul_ss[63:32];  // MULH
            5'b01100: result = mul_su[63:32];  // MULHSU
            5'b01101: result = mul_uu[63:32];  // MULHU
            5'b01110: begin // DIV
                if (operand_b == 32'd0)
                    result = 32'hFFFFFFFF;
                else if ((operand_a == 32'h80000000) && (operand_b == 32'hFFFFFFFF))
                    result = 32'h80000000;
                else
                    result = $unsigned($signed(operand_a) / $signed(operand_b));
            end
            5'b01111: begin // DIVU
                if (operand_b == 32'd0)
                    result = 32'hFFFFFFFF;
                else
                    result = operand_a / operand_b;
            end
            5'b10000: begin // REM
                if (operand_b == 32'd0)
                    result = operand_a;
                else if ((operand_a == 32'h80000000) && (operand_b == 32'hFFFFFFFF))
                    result = 32'd0;
                else
                    result = $unsigned($signed(operand_a) % $signed(operand_b));
            end
            5'b10001: begin // REMU
                if (operand_b == 32'd0)
                    result = operand_a;
                else
                    result = operand_a % operand_b;
            end
            default: result = 32'd0;
        endcase
    end

    assign zero = (result == 32'd0);

endmodule
