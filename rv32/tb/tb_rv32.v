`timescale 1ns/1ps

module tb_rv32;
  reg clk = 1'b0;
  reg rst_n = 1'b0;
  always #5 clk = ~clk;
  
  initial begin
    rst_n = 1'b0;
    repeat(5) @(posedge clk);
    rst_n = 1'b1;
  end

  // dut <-> memory wires
  wire [31:0] imem_addr;
  reg  [31:0] imem_rdata;

  wire        dmem_valid;
  wire        dmem_we;
  wire [3:0]  dmem_wstrb;
  wire [31:0] dmem_addr;
  wire [31:0] dmem_wdata;
  reg  [31:0] dmem_rdata;

  // instantiate DUT
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

  // clock
  always #5 clk = ~clk;

  // -------------------------
  // Simple ROM (instructions)
  // -------------------------
  reg [31:0] rom [0:255];

  // -------------------------
  // Simple RAM (data)
  // -------------------------
  reg [31:0] ram [0:255];

  integer i;

  // ROM read (combinational)
  always @(*) begin
    imem_rdata = rom[imem_addr[9:2]]; // word addressed
  end

  // RAM read (combinational for minimal core)
  always @(*) begin
    dmem_rdata = ram[dmem_addr[9:2]];
  end

  // RAM write (on posedge)
  always @(posedge clk) begin
    if (dmem_valid && dmem_we) begin
      if (dmem_wstrb == 4'b1111) begin
        ram[dmem_addr[9:2]] <= dmem_wdata;
      end else begin
        // minimal: only support SW for now
        $display("[TB] WARN: partial store not supported yet, wstrb=%b addr=%h data=%h",
                 dmem_wstrb, dmem_addr, dmem_wdata);
      end
    end
  end

  // -------------------------
  // Test program (hand-encoded)
  // -------------------------
  // Program:
  //   addi x1, x0, 5
  //   addi x2, x0, 7
  //   add  x3, x1, x2        ; x3=12
  //   sw   x3, 0(x0)         ; ram[0]=12
  //   lw   x4, 0(x0)         ; x4=12
  //   addi x5, x0, 1
  //   sw   x5, 4(x0)         ; ram[1]=1 => PASS flag
  //   jal  x0, 0             ; loop
  //
  // Encodings (RV32I):
  // addi rd,rs1,imm:  imm[11:0] rs1 funct3 rd opcode(0010011)
  // add  rd,rs1,rs2 : funct7 rs2 rs1 funct3 rd opcode(0110011)
  // sw   rs2,imm(rs1): imm[11:5] rs2 rs1 funct3 imm[4:0] opcode(0100011)
  // lw   rd,imm(rs1): imm rs1 funct3 rd opcode(0000011)
  // jal  rd,imm: see spec

  initial begin
    // init memories
    for (i = 0; i < 256; i = i + 1) begin
      rom[i] = 32'h00000013; // nop (addi x0,x0,0)
      ram[i] = 32'h0;
    end

    // Fill ROM
    rom[0] = 32'h00500093; // addi x1,x0,5
    rom[1] = 32'h00700113; // addi x2,x0,7
    rom[2] = 32'h002081B3; // add  x3,x1,x2
    rom[3] = 32'h00302023; // sw   x3,0(x0)
    rom[4] = 32'h00002203; // lw   x4,0(x0)
    rom[5] = 32'h00100293; // addi x5,x0,1
    rom[6] = 32'h00502223; // sw   x5,4(x0)   (imm=4)
    rom[7] = 32'h0000006F; // jal  x0,0

    // reset
    rst_n = 0;
    repeat (5) @(posedge clk);
    rst_n = 1;

    // run
    repeat (200) begin
      @(posedge clk);

      // PASS condition: ram[1] == 1
      if (ram[1] == 32'h1) begin
        $display("[TB] PASS: ram[1]=%h, ram[0]=%h", ram[1], ram[0]);
        $finish;
      end
    end

    $display("[TB] TIMEOUT. ram[0]=%h ram[1]=%h", ram[0], ram[1]);
    $finish;
  end

  // optional waveform
  initial begin
  $dumpfile("sim/tb_rv32.vcd");
  $dumpvars(0, tb_rv32);
end

endmodule