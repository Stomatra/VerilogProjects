module rv32_imm (
  input  logic [31:0] instr,
  output logic [31:0] imm_i,
  output logic [31:0] imm_s,
  output logic [31:0] imm_b,
  output logic [31:0] imm_u,
  output logic [31:0] imm_j
);
  // I-type
  assign imm_i = {{20{instr[31]}}, instr[31:20]};
  // S-type
  assign imm_s = {{20{instr[31]}}, instr[31:25], instr[11:7]};
  // B-type (note bit0 is 0)
  assign imm_b = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
  // U-type
  assign imm_u = {instr[31:12], 12'h000};
  // J-type (note bit0 is 0)
  assign imm_j = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
endmodule