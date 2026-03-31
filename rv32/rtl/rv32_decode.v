`include "rv32_pkg.vh"

// ============================================================
// rv32_decode
// ------------------------------------------------------------
// 功能:
//   RV32I 指令字段拆分模块。
//   将 32 位 instr 按 RISC-V 编码格式拆出常用字段：
//     opcode / rd / funct3 / rs1 / rs2 / funct7
//
// 备注:
//   本模块本身不依赖 rv32_pkg.vh 中的 OPC_* 常量；
//   保留 include 主要为了统一工程编译路径/风格（也方便后续扩展）。
// ============================================================
module rv32_decode (
  input  logic [31:0] instr,  // 32 位指令字
  output logic [6:0]  opcode, // instr[6:0]   : 主操作码
  output logic [2:0]  funct3, // instr[14:12] : 子操作码
  output logic [6:0]  funct7, // instr[31:25] : R/I(移位)等指令的扩展字段
  output logic [4:0]  rd,     // instr[11:7]  : 目的寄存器号
  output logic [4:0]  rs1,    // instr[19:15] : 源寄存器1号
  output logic [4:0]  rs2     // instr[24:20] : 源寄存器2号
);
  // 逐字段切片：纯组合逻辑
  assign opcode = instr[6:0];    // 主 opcode
  assign rd     = instr[11:7];   // rd
  assign funct3 = instr[14:12];  // funct3
  assign rs1    = instr[19:15];  // rs1
  assign rs2    = instr[24:20];  // rs2
  assign funct7 = instr[31:25];  // funct7
endmodule