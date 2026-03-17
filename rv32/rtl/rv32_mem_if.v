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