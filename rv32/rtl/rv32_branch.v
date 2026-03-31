// ============================================================
// rv32_branch
// ------------------------------------------------------------
// 功能:
//   RV32I 分支条件判断模块。
//   对应 opcode=BRANCH 时，由 funct3 决定比较类型，输出 take。
//
// 输入:
//   funct3 : 分支子类型 (BEQ/BNE/BLT/BGE/BLTU/BGEU)
//   rs1/rs2: 参与比较的两个寄存器值
// 输出:
//   take   : 1 表示分支成立，需要跳转到 branch_target
// ============================================================
module rv32_branch (
  input  logic [2:0]  funct3, // 分支指令 funct3
  input  logic [31:0] rs1,    // rs1 当前值
  input  logic [31:0] rs2,    // rs2 当前值
  output logic        take    // 分支是否成立
);
  // 纯组合比较逻辑
  always_comb begin
    unique case (funct3)
      3'b000: take = (rs1 == rs2);                   // BEQ  : 相等则跳转
      3'b001: take = (rs1 != rs2);                   // BNE  : 不等则跳转
      3'b100: take = ($signed(rs1) < $signed(rs2));  // BLT  : 有符号小于
      3'b101: take = ($signed(rs1) >= $signed(rs2)); // BGE  : 有符号大于等于
      3'b110: take = (rs1 < rs2);                    // BLTU : 无符号小于
      3'b111: take = (rs1 >= rs2);                   // BGEU : 无符号大于等于
      default: take = 1'b0;                          // 非法 funct3 -> 不跳转
    endcase
  end
endmodule