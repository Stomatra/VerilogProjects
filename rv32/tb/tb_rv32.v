`timescale 1ns/1ps

module tb_rv32;
  reg clk = 1'b0;
  reg rst_n = 1'b0;
  always #5 clk = ~clk;

  // dut <-> memory wires
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

  // ROM/RAM
  reg [31:0] rom [0:255];
  reg [31:0] ram [0:255];
  integer i;

  // ROM read
  always @(*) begin
    imem_rdata = rom[imem_addr[9:2]];
  end

  // RAM read (word addressed)
  always @(*) begin
    dmem_rdata = ram[dmem_addr[9:2]];
  end

  // RAM write with byte enable (little-endian lanes)
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

  // program load
  reg [1023:0] hex_path;

  initial begin
    for (i = 0; i < 256; i = i + 1) begin
      rom[i] = 32'h00000013; // NOP
      ram[i] = 32'h0;
    end

    if (!$value$plusargs("hex=%s", hex_path)) begin
      hex_path = "tests/00_sanity.hex";
    end

    $display("[TB] loading program: %0s", hex_path);
    $readmemh(hex_path, rom);

    // reset
    rst_n = 1'b0;
    repeat (5) @(posedge clk);
    rst_n = 1'b1;

    // run; PASS flag = ram[1] == 1
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