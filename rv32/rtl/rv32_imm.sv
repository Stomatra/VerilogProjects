// ============================================================
// rv32_imm
// ------------------------------------------------------------
// 功能:
//   RV32I 立即数生成模块。
//   将 instr 中分散的立即数字段拼成 32 位有符号立即数（符号扩展）。
//
// 输出:
//   imm_i : I-type  (ADDI/LB/LW/JALR 等)
//   imm_s : S-type  (SB/SH/SW 等)
//   imm_b : B-type  (BEQ/BNE/...)  注意最低位 imm[0]=0
//   imm_u : U-type  (LUI/AUIPC)    低 12 位补 0
//   imm_j : J-type  (JAL)          注意最低位 imm[0]=0
// ============================================================
module rv32_imm (
  input  logic [31:0] instr, // 32 位指令字
  output logic [31:0] imm_i, // I-type 立即数（符号扩展）
  output logic [31:0] imm_s, // S-type 立即数（符号扩展）
  output logic [31:0] imm_b, // B-type 立即数（符号扩展，bit0=0）
  output logic [31:0] imm_u, // U-type 立即数（左移 12）
  output logic [31:0] imm_j  // J-type 立即数（符号扩展，bit0=0）
);
  // I-type: imm[11:0] = instr[31:20]
  // 最高位 instr[31] 作为符号位，扩展到 32 位
  assign imm_i = {{20{instr[31]}}, instr[31:20]};

  // S-type: imm[11:5]=instr[31:25], imm[4:0]=instr[11:7]
  assign imm_s = {{20{instr[31]}}, instr[31:25], instr[11:7]};

  // B-type (分支):
  //   imm[12]  = instr[31]
  //   imm[11]  = instr[7]
  //   imm[10:5]= instr[30:25]
  //   imm[4:1] = instr[11:8]
  //   imm[0]   = 0
  // 这里同样做符号扩展；注意 bit0 固定为 0（分支偏移按 2 字节对齐）
  assign imm_b = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};

  // U-type:
  //   imm[31:12] = instr[31:12]
  //   imm[11:0]  = 0
  assign imm_u = {instr[31:12], 12'h000};

  // J-type (JAL):
  //   imm[20]   = instr[31]
  //   imm[19:12]= instr[19:12]
  //   imm[11]   = instr[20]
  //   imm[10:1] = instr[30:21]
  //   imm[0]    = 0
  // 同样符号扩展；bit0 固定为 0（跳转偏移按 2 字节对齐）
  assign imm_j = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
endmodule