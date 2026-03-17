`include "rv32_pkg.vh"

module rv32_core (
  input  logic        clk,
  input  logic        rst_n,

  // instruction memory (combinational for minimal core)
  output logic [31:0] imem_addr,
  input  logic [31:0] imem_rdata,

  // data memory (combinational for minimal core; extend to handshake later)
  output logic        dmem_valid,
  output logic        dmem_we,
  output logic [3:0]  dmem_wstrb,
  output logic [31:0] dmem_addr,
  output logic [31:0] dmem_wdata,
  input  logic [31:0] dmem_rdata
);

  // PC
  logic [31:0] pc_q, pc_n;

  // instruction fields
  logic [6:0] opcode, funct7;
  logic [2:0] funct3;
  logic [4:0] rd, rs1, rs2;

  rv32_decode u_dec (
    .instr(imem_rdata),
    .opcode(opcode),
    .funct3(funct3),
    .funct7(funct7),
    .rd(rd), .rs1(rs1), .rs2(rs2)
  );

  // immediates
  logic [31:0] imm_i, imm_s, imm_b, imm_u, imm_j;
  rv32_imm u_imm (.instr(imem_rdata), .imm_i, .imm_s, .imm_b, .imm_u, .imm_j);

  // regfile
  logic [31:0] rs1_val, rs2_val;
  logic        rf_we;
  logic [31:0] rf_wdata;

  rv32_regfile u_rf (
    .clk(clk),
    .we(rf_we),
    .waddr(rd),
    .wdata(rf_wdata),
    .raddr1(rs1),
    .raddr2(rs2),
    .rdata1(rs1_val),
    .rdata2(rs2_val)
  );

  // ALU
  logic [3:0]  alu_op;
  logic [31:0] alu_a, alu_b, alu_y;

  rv32_alu u_alu (.alu_op(alu_op), .a(alu_a), .b(alu_b), .y(alu_y));

  // branch decision
  logic br_take;
  rv32_branch u_br (.funct3(funct3), .rs1(rs1_val), .rs2(rs2_val), .take(br_take));

  // instr fetch
  assign imem_addr = pc_q;

  // default memory outputs
  always_comb begin
    dmem_valid = 1'b0;
    dmem_we    = 1'b0;
    dmem_wstrb = 4'b0000;
    dmem_addr  = 32'h0;
    dmem_wdata = 32'h0;
  end

  // next-state logic
  always_comb begin
    // defaults
    pc_n     = pc_q + 32'd4;
    rf_we    = 1'b0;
    rf_wdata = 32'h0;

    alu_a  = rs1_val;
    alu_b  = rs2_val;
    alu_op = 4'd0; // ADD

    unique case (opcode)

      OPC_LUI: begin
        rf_we    = 1'b1;
        rf_wdata = imm_u;
      end

      OPC_AUIPC: begin
        rf_we    = 1'b1;
        rf_wdata = pc_q + imm_u;
      end

      OPC_JAL: begin
        rf_we    = 1'b1;
        rf_wdata = pc_q + 32'd4;
        pc_n     = pc_q + imm_j;
      end

      OPC_JALR: begin
        rf_we    = 1'b1;
        rf_wdata = pc_q + 32'd4;
        pc_n     = (rs1_val + imm_i) & 32'hFFFF_FFFE;
      end

      OPC_BRANCH: begin
        if (br_take) pc_n = pc_q + imm_b;
      end

      OPC_OPIMM: begin
        // only implement a minimal subset first, expand later
        rf_we = 1'b1;
        unique case (funct3)
          3'b000: begin // ADDI
            rf_wdata = rs1_val + imm_i;
          end
          3'b111: begin // ANDI
            rf_wdata = rs1_val & imm_i;
          end
          3'b110: begin // ORI
            rf_wdata = rs1_val | imm_i;
          end
          3'b100: begin // XORI
            rf_wdata = rs1_val ^ imm_i;
          end
          3'b010: begin // SLTI
            rf_wdata = ($signed(rs1_val) < $signed(imm_i)) ? 32'd1 : 32'd0;
          end
          3'b011: begin // SLTIU
            rf_wdata = (rs1_val < imm_i) ? 32'd1 : 32'd0;
          end
          3'b001: begin // SLLI
            rf_wdata = rs1_val << imm_i[4:0];
          end
          3'b101: begin // SRLI/SRAI
            if (funct7[5]) rf_wdata = $signed(rs1_val) >>> imm_i[4:0];
            else           rf_wdata = rs1_val >> imm_i[4:0];
          end
          default: rf_wdata = 32'h0;
        endcase
      end

      OPC_OP: begin
        rf_we = 1'b1;
        unique case (funct3)
          3'b000: rf_wdata = (funct7[5] ? (rs1_val - rs2_val) : (rs1_val + rs2_val)); // ADD/SUB
          3'b111: rf_wdata = rs1_val & rs2_val; // AND
          3'b110: rf_wdata = rs1_val | rs2_val; // OR
          3'b100: rf_wdata = rs1_val ^ rs2_val; // XOR
          3'b010: rf_wdata = ($signed(rs1_val) < $signed(rs2_val)) ? 32'd1 : 32'd0; // SLT
          3'b011: rf_wdata = (rs1_val < rs2_val) ? 32'd1 : 32'd0; // SLTU
          3'b001: rf_wdata = rs1_val << rs2_val[4:0]; // SLL
          3'b101: rf_wdata = (funct7[5] ? ($signed(rs1_val) >>> rs2_val[4:0]) : (rs1_val >> rs2_val[4:0])); // SRL/SRA
          default: rf_wdata = 32'h0;
        endcase
      end

      OPC_LOAD: begin
        // Minimal: assume zero-wait memory; add stall/handshake later
        dmem_valid = 1'b1;
        dmem_we    = 1'b0;
        dmem_addr  = rs1_val + imm_i;

        rf_we = 1'b1;
        unique case (funct3)
          3'b010: rf_wdata = dmem_rdata; // LW
          // LB/LH/LBU/LHU need sign/zero extend based on addr[1:0]
          default: rf_wdata = dmem_rdata;
        endcase
      end

      OPC_STORE: begin
        dmem_valid = 1'b1;
        dmem_we    = 1'b1;
        dmem_addr  = rs1_val + imm_s;
        dmem_wdata = rs2_val;

        unique case (funct3)
          3'b010: dmem_wstrb = 4'b1111; // SW
          // SB/SH need byte enables and write data shift
          default: dmem_wstrb = 4'b1111;
        endcase
      end

      default: begin
        // For minimal core: treat unsupported as NOP
        // (Later: raise illegal instruction trap)
      end
    endcase
  end

  // state update
  always_ff @(posedge clk) begin
    if (!rst_n) pc_q <= 32'h0000_0000;
    else        pc_q <= pc_n;
  end

endmodule