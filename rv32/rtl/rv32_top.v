`timescale 1ns/1ps

// ============================================================
// rv32_top
// ------------------------------------------------------------
// Wrapper module: instantiates rv32_core and exposes all
// instruction/data memory ports (including ready/valid signals)
// to the testbench or SoC integration layer.
// ============================================================
module rv32_top (
  input  wire        clk,
  input  wire        rst_n,

  // Instruction memory port
  output wire        imem_valid,        // core requesting instruction
  output wire [31:0] imem_addr,         // fetch address (byte address)
  input  wire        imem_ready,        // memory accepts request
  input  wire        imem_rdata_valid,  // instruction data valid
  input  wire [31:0] imem_rdata,        // instruction word

  // Data memory port
  output wire        dmem_valid,        // core requesting data access
  output wire        dmem_we,           // 1=store, 0=load
  output wire [3:0]  dmem_wstrb,        // byte enables (little-endian)
  output wire [31:0] dmem_addr,         // data address (byte address)
  output wire [31:0] dmem_wdata,        // write data
  input  wire        dmem_ready,        // memory accepts request
  input  wire        dmem_rdata_valid,  // read data valid (loads)
  input  wire [31:0] dmem_rdata         // read data
);

  rv32_core u_core (
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

endmodule
