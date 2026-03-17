`timescale 1ns/1ps

module rv32_top (
  input  wire        clk,
  input  wire        rst_n,

  // instruction memory port
  output wire [31:0] imem_addr,
  input  wire [31:0] imem_rdata,

  // data memory port
  output wire        dmem_valid,
  output wire        dmem_we,
  output wire [3:0]  dmem_wstrb,
  output wire [31:0] dmem_addr,
  output wire [31:0] dmem_wdata,
  input  wire [31:0] dmem_rdata
);

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