`timescale 1ns/1ps

// ============================================================
// tb_rv32
// ------------------------------------------------------------
// Testbench for the RV32I 5-stage pipeline core.
//
// Memory model (zero-wait):
//   - imem_ready = 1, imem_rdata_valid = imem_valid  (combinational)
//   - dmem_ready = 1
//   - dmem_rdata_valid = dmem_valid & ~dmem_we        (combinational)
//   These settings ensure no pipeline stalls occur, so the only
//   source of bubbles is control-hazard flushing on taken branches/jumps.
//
// PASS/FAIL convention (same as before):
//   ram[1] == 1           -> PASS
//   ram[1] == 0xDEAD_BEEF -> FAIL
//   timeout               -> TIMEOUT
//
// Usage:
//   vvp sim/tb_rv32.vvp +hex=tests/xxx.hex
// ============================================================
module tb_rv32;

  // ----------------------------
  // Clock / reset
  // ----------------------------
  reg clk   = 1'b0;
  reg rst_n = 1'b0;
  always #5 clk = ~clk; // 100 MHz (10 ns period)

  // ----------------------------
  // DUT <-> TB connections
  // ----------------------------
  // IMEM
  wire        imem_valid;
  wire [31:0] imem_addr;
  reg         imem_ready;
  reg         imem_rdata_valid;
  reg  [31:0] imem_rdata;

  // DMEM
  wire        dmem_valid;
  wire        dmem_we;
  wire [3:0]  dmem_wstrb;
  wire [31:0] dmem_addr;
  wire [31:0] dmem_wdata;
  reg         dmem_ready;
  reg         dmem_rdata_valid;
  reg  [31:0] dmem_rdata;

  rv32_top dut (
    .clk              (clk),
    .rst_n            (rst_n),
    .imem_valid       (imem_valid),
    .imem_addr        (imem_addr),
    .imem_ready       (imem_ready),
    .imem_rdata_valid (imem_rdata_valid),
    .imem_rdata       (imem_rdata),
    .dmem_valid       (dmem_valid),
    .dmem_we          (dmem_we),
    .dmem_wstrb       (dmem_wstrb),
    .dmem_addr        (dmem_addr),
    .dmem_wdata       (dmem_wdata),
    .dmem_ready       (dmem_ready),
    .dmem_rdata_valid (dmem_rdata_valid),
    .dmem_rdata       (dmem_rdata)
  );

  // ----------------------------
  // ROM / RAM arrays
  // ----------------------------
  reg [31:0] rom [0:255];
  reg [31:0] ram [0:255];
  integer i;

  // ----------------------------
  // Zero-wait memory model
  // ----------------------------
  // IMEM: always ready; rdata_valid fires combinatorially when valid.
  // Gate on rst_n to avoid latching garbage during reset.
  always @(*) begin
    imem_ready       = 1'b1;
    imem_rdata_valid = rst_n && imem_valid;  // zero-wait: data ready same cycle
    imem_rdata       = rom[imem_addr[9:2]];
  end

  // DMEM: always ready; rdata_valid fires combinatorially for loads.
  // Gate on rst_n to avoid spurious valid assertions during reset.
  always @(*) begin
    dmem_ready       = 1'b1;
    dmem_rdata_valid = rst_n && dmem_valid & ~dmem_we; // loads only
    dmem_rdata       = ram[dmem_addr[9:2]];
  end

  // RAM write: clock-edge write with byte enables
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
  // Program load & simulation control
  // ----------------------------
  reg [1023:0] hex_path;

  initial begin
    for (i = 0; i < 256; i = i + 1) begin
      rom[i] = 32'h00000013; // NOP
      ram[i] = 32'h0;
    end

    // Load hex from +hex= plusarg (default: tests/addi.hex for manual runs)
    if (!$value$plusargs("hex=%s", hex_path)) begin
      hex_path = "tests/addi.hex";
    end

    $display("[TB] loading program: %0s", hex_path);
    $readmemh(hex_path, rom);

    // Reset sequence
    rst_n = 1'b0;
    repeat (5) @(posedge clk);
    rst_n = 1'b1;

    // Run up to 5000 cycles; check PASS/FAIL marker at ram[1]
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
    $dumpfile("sim/tb_rv32.vcd");
    $dumpvars(0, tb_rv32);
  end

endmodule
