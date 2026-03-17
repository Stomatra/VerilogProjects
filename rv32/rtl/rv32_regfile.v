module rv32_regfile (
  input  logic        clk,
  input  logic        we,
  input  logic [4:0]  waddr,
  input  logic [31:0] wdata,
  input  logic [4:0]  raddr1,
  input  logic [4:0]  raddr2,
  output logic [31:0] rdata1,
  output logic [31:0] rdata2
);
  logic [31:0] regs [31:0];

  // read: combinational
  always_comb begin
    rdata1 = (raddr1 == 0) ? 32'h0 : regs[raddr1];
    rdata2 = (raddr2 == 0) ? 32'h0 : regs[raddr2];
  end

  // write: synchronous
  always_ff @(posedge clk) begin
    if (we && (waddr != 0)) begin
      regs[waddr] <= wdata;
    end
  end
endmodule