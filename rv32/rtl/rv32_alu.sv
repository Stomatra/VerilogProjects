// ============================================================
// rv32_alu
// ------------------------------------------------------------
// 功能:
//   RV32I 最小内核的算术逻辑单元(ALU)，纯组合逻辑。
//   由 alu_op 选择具体运算，对 a/b 进行计算，输出 y。
//
// 设计要点:
//   - SLT/SLTU 的结果为 32'd0 或 32'd1
//   - 移位量只取 b[4:0]（RV32 规定 shamt 范围 0..31）
//   - 使用 unique case 让仿真器/综合器能做覆盖/互斥检查
// ============================================================
module rv32_alu (
  input  logic [3:0]  alu_op, // 运算选择码（与 rv32_core 的 ALU_* 编码保持一致）
  input  logic [31:0] a,      // 操作数A
  input  logic [31:0] b,      // 操作数B / 移位量来源
  output logic [31:0] y       // 运算结果
);
  // 运算编码定义（注意：这些编码需要与 rv32_core 内部保持一致）
  localparam logic [3:0] ALU_ADD  = 4'd0; // 加法
  localparam logic [3:0] ALU_SUB  = 4'd1; // 减法
  localparam logic [3:0] ALU_AND  = 4'd2; // 按位与
  localparam logic [3:0] ALU_OR   = 4'd3; // 按位或
  localparam logic [3:0] ALU_XOR  = 4'd4; // 按位异或
  localparam logic [3:0] ALU_SLT  = 4'd5; // 有符号小于置位
  localparam logic [3:0] ALU_SLTU = 4'd6; // 无符号小于置位
  localparam logic [3:0] ALU_SLL  = 4'd7; // 逻辑左移
  localparam logic [3:0] ALU_SRL  = 4'd8; // 逻辑右移
  localparam logic [3:0] ALU_SRA  = 4'd9; // 算术右移

  // ALU 主组合逻辑：根据 alu_op 选择输出
  always_comb begin
    unique case (alu_op)
      ALU_ADD:  y = a + b;                                     // a + b
      ALU_SUB:  y = a - b;                                     // a - b
      ALU_AND:  y = a & b;                                     // a & b
      ALU_OR:   y = a | b;                                     // a | b
      ALU_XOR:  y = a ^ b;                                     // a ^ b
      ALU_SLT:  y = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0; // signed(a) < signed(b)
      ALU_SLTU: y = (a < b) ? 32'd1 : 32'd0;                   // unsigned(a) < unsigned(b)
      ALU_SLL:  y = a << b[4:0];                               // a << shamt
      ALU_SRL:  y = a >> b[4:0];                               // a >> shamt (逻辑)
      ALU_SRA:  y = $signed(a) >>> b[4:0];                     // a >>> shamt (算术)
      default:  y = 32'h0;                                     // 未定义编码输出 0
    endcase
  end
endmodule