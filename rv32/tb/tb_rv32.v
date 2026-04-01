`timescale 1ns/1ps

// ============================================================
// tb_rv32
// ------------------------------------------------------------
// 功能:
//   RV32 最小单周期核的 testbench（教学/自测用途）。
//
// 核心思路:
//   1) 例化 rv32_top。
//   2) 在 TB 内部用两个数组模拟 ROM/RAM：
//      - ROM：指令存储器，只读，组合读。
//      - RAM：数据存储器，组合读 + 时钟上升沿写（带字节使能）。
//   3) 通过 plusargs 传入要加载的程序 hex 文件：
//        vvp ... "+hex=tests/addi.hex"
//      TB 用 $readmemh 将程序写入 rom[]。
//   4) 运行若干周期，监视 RAM 的约定地址：
//      - ram[1] == 32'h1         -> PASS
//      - ram[1] == 32'hDEAD_BEEF -> FAIL
//      - 超时仍未写出以上标志  -> TIMEOUT
//
// 约定说明:
//   - 本 TB 的 ROM/RAM 以“字”为粒度（32bit word）建模：
//     使用 addr[9:2] 作为索引，即忽略 addr[1:0]（字内偏移）。
//     对于 LB/LH 等需要字节/半字对齐的场景，内核会根据 addr[1:0]
//     对 dmem_rdata 做 lane 选择与扩展。
// ============================================================
module tb_rv32;
  // ----------------------------
  // 时钟/复位
  // ----------------------------
  reg clk = 1'b0;
  reg rst_n = 1'b0;
  always #5 clk = ~clk; // 100MHz（周期 10ns）

  // ----------------------------
  // DUT <-> TB memory 连接信号
  // ----------------------------
  wire [31:0] imem_addr;
  reg  [31:0] imem_rdata;

  wire        dmem_valid;
  wire        dmem_we;
  wire [3:0]  dmem_wstrb;
  wire [31:0] dmem_addr;
  wire [31:0] dmem_wdata;
  reg  [31:0] dmem_rdata;

  rv32_top dut (
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

  // ----------------------------
  // ROM/RAM：用数组模拟指令/数据存储器
  // ----------------------------
  reg [31:0] rom [0:255];
  reg [31:0] ram [0:255];
  integer i;

  // ROM read：组合读（字寻址）
  // imem_addr 是字节地址；rom 以 word 存放，所以用 [9:2] 做索引。
  always @(*) begin
    imem_rdata = rom[imem_addr[9:2]];
  end

  // RAM read：组合读（字寻址）
  // dmem_addr 是字节地址；ram 以 word 存放，所以用 [9:2] 做索引。
  always @(*) begin
    dmem_rdata = ram[dmem_addr[9:2]];
  end

  // RAM write：时钟上升沿写，支持字节使能（小端 byte lane）
  // - dmem_valid && dmem_we 表示 store
  // - dmem_wstrb[i]=1 表示写入对应的 8bit lane
  always @(posedge clk) begin
    if (dmem_valid && dmem_we) begin
      integer wi;
      reg [31:0] cur;
      wi  = dmem_addr[9:2];
      cur = ram[wi];

      if (dmem_wstrb[0]) cur[7:0]   = dmem_wdata[7:0];
      if (dmem_wstrb[1]) cur[15:8]  = dmem_wdata[15:8];
      if (dmem_wstrb[2]) cur[23:16] = dmem_wdata[23:16];
      if (dmem_wstrb[3]) cur[31:24] = dmem_wdata[31:24];

      ram[wi] <= cur;
    end
  end

  // ----------------------------
  // program load：选择并加载要运行的 .hex 程序
  // ----------------------------
  reg [1023:0] hex_path;

  initial begin
    for (i = 0; i < 256; i = i + 1) begin
      rom[i] = 32'h00000013; // NOP
      ram[i] = 32'h0;
    end

    // 从命令行读取 +hex=... 参数；若未提供，就用一个存在的默认用例。
    // 说明：run_all_tests.* 会始终传入 +hex=...，因此默认值主要用于手动运行。
    if (!$value$plusargs("hex=%s", hex_path)) begin
      hex_path = "tests/addi.hex";
    end

    $display("[TB] loading program: %0s", hex_path);
    $readmemh(hex_path, rom);

    // reset：低有效复位，保持若干拍后释放
    rst_n = 1'b0;
    repeat (5) @(posedge clk);
    rst_n = 1'b1;

    // run：最多跑 5000 个周期；PASS 标志 = ram[1] == 1
    repeat (5000) begin
      @(posedge clk);
      if (ram[1] == 32'h1) begin
        $display("[TB] PASS: ram[0]=%h ram[1]=%h", ram[0], ram[1]);
        $finish;
      end
      if (ram[1] == 32'hDEAD_BEEF) begin
        $display("[TB] FAIL: ram[0]=%h ram[1]=%h", ram[0], ram[1]);
        $finish;
      end
    end

    $display("[TB] TIMEOUT: ram[0]=%h ram[1]=%h", ram[0], ram[1]);
    $finish;
  end

  initial begin
    // 波形导出：方便用 GTKWave 等查看指令/访存行为。
    // 注意：路径包含 sim/，请确保该目录存在（run_all_tests.* 会自动创建）。
    $dumpfile("sim/tb_rv32.vcd");
    $dumpvars(0, tb_rv32);
  end

endmodule