`timescale 1ns/1ps

// ============================================================
// rv32_top
// ------------------------------------------------------------
// 功能:
//   顶层封装模块（wrapper）。
//   - 不实现额外逻辑，仅例化 rv32_core 并把指令/数据存储器端口引出。
//
// 这样做的好处:
//   - 方便 testbench/SoC 顶层直接连接内核
//   - 后续如果要加总线/仲裁/外设，可以在 top 层扩展
// ============================================================
module rv32_top (
  input  wire        clk,      // 时钟
  input  wire        rst_n,     // 低有效复位

  // instruction memory port（指令存储器：只读）
  output wire [31:0] imem_addr,  // 取指地址（字节地址）
  input  wire [31:0] imem_rdata, // 指令数据（组合读）

  // data memory port（数据存储器：读写）
  output wire        dmem_valid, // 数据口请求有效
  output wire        dmem_we,    // 数据口写使能（1=写，0=读）
  output wire [3:0]  dmem_wstrb, // 写字节使能（小端 4 lanes）
  output wire [31:0] dmem_addr,  // 数据口地址（字节地址）
  output wire [31:0] dmem_wdata, // 写数据
  input  wire [31:0] dmem_rdata  // 读数据（组合读）
);

  // 例化核心
  rv32_core u_core (
    .clk(clk),
    .rst_n(rst_n),

    .imem_addr(imem_addr),
    .imem_rdata(imem_rdata),

    .dmem_valid(dmem_valid),
    .dmem_we(dmem_we),
    .dmem_wstrb(dmem_wstrb),
    .dmem_addr(dmem_addr),
    .dmem_wdata(dmem_wdata),
    .dmem_rdata(dmem_rdata)
  );

endmodule