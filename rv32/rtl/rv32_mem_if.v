// ============================================================
// rv32_mem_if (接口占位模块)
// ------------------------------------------------------------
// 功能:
//   这是一个“内存接口”的占位模块（stub），当前未在设计中使用。
//   用来明确列出 RV32 最小核所需的指令口/数据口信号集合。
//
// 未来扩展方向:
//   - ready/valid 握手（支持等待周期/流水线暂停）
//   - 指令/数据总线仲裁
//   - MMIO 地址空间
//   - 对齐检测/异常处理
// ============================================================
// Minimalistic memory interface:
// - instr fetch: separate read-only port
// - data: load/store port with byte enables
module rv32_mem_if (
  // instruction
  output logic [31:0] imem_addr,
  input  logic [31:0] imem_rdata,

  // data
  output logic        dmem_valid,
  output logic        dmem_we,
  output logic [3:0]  dmem_wstrb,
  output logic [31:0] dmem_addr,
  output logic [31:0] dmem_wdata,
  input  logic [31:0] dmem_rdata
);
  // This is just an interface stub module for future expansion.
  // Real design: add ready/valid handshake, stalls, MMIO, etc.
endmodule