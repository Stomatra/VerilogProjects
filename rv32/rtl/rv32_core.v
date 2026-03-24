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

  localparam logic [3:0] ALU_ADD  = 4'd0;
  localparam logic [3:0] ALU_SUB  = 4'd1;
  localparam logic [3:0] ALU_AND  = 4'd2;
  localparam logic [3:0] ALU_OR   = 4'd3;
  localparam logic [3:0] ALU_XOR  = 4'd4;
  localparam logic [3:0] ALU_SLT  = 4'd5;
  localparam logic [3:0] ALU_SLTU = 4'd6;
  localparam logic [3:0] ALU_SLL  = 4'd7;
  localparam logic [3:0] ALU_SRL  = 4'd8;
  localparam logic [3:0] ALU_SRA  = 4'd9;

  localparam logic       ALU_SRC_A_RS1 = 1'b0;
  localparam logic       ALU_SRC_A_PC  = 1'b1;

  localparam logic [1:0] ALU_SRC_B_RS2   = 2'd0;
  localparam logic [1:0] ALU_SRC_B_IMM_I = 2'd1;
  localparam logic [1:0] ALU_SRC_B_IMM_S = 2'd2;
  localparam logic [1:0] ALU_SRC_B_IMM_U = 2'd3;

  localparam logic [1:0] WB_SRC_ALU   = 2'd0;
  localparam logic [1:0] WB_SRC_MEM   = 2'd1;
  localparam logic [1:0] WB_SRC_PC4   = 2'd2;
  localparam logic [1:0] WB_SRC_IMM_U = 2'd3;

  localparam logic [1:0] PC_SRC_PC4    = 2'd0;
  localparam logic [1:0] PC_SRC_BRANCH = 2'd1;
  localparam logic [1:0] PC_SRC_JAL    = 2'd2;
  localparam logic [1:0] PC_SRC_JALR   = 2'd3;

  // PC
  logic [31:0] pc_q, pc_n;
  logic [31:0] pc_plus4, branch_target, jal_target, jalr_target;

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
  logic [31:0] wb_data;
  logic [1:0]  wb_sel;

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
  logic        alu_src_a_sel;
  logic [1:0]  alu_src_b_sel;
  logic [31:0] alu_b_mux;

  rv32_alu u_alu (.alu_op(alu_op), .a(alu_a), .b(alu_b), .y(alu_y));

  // branch decision
  logic br_take;
  rv32_branch u_br (.funct3(funct3), .rs1(rs1_val), .rs2(rs2_val), .take(br_take));

  // memory data formatting
  logic        dmem_req;
  logic        dmem_write;
  logic [3:0]  store_wstrb;
  logic [31:0] store_wdata;
  logic [31:0] load_data;
  logic [7:0]  load_byte;
  logic [15:0] load_half;

  logic [1:0]  pc_sel;

  // instr fetch
  assign imem_addr = pc_q;
  assign pc_plus4 = pc_q + 32'd4;
  assign branch_target = pc_q + imm_b;
  assign jal_target = pc_q + imm_j;
  assign jalr_target = {alu_y[31:1], 1'b0};
  assign alu_a = (alu_src_a_sel == ALU_SRC_A_PC) ? pc_q : rs1_val;
  assign alu_b = alu_b_mux;

  assign dmem_valid = dmem_req;
  assign dmem_we    = dmem_write;
  assign dmem_addr  = dmem_req ? alu_y : 32'h0;
  assign dmem_wstrb = dmem_write ? store_wstrb : 4'b0000;
  assign dmem_wdata = dmem_write ? store_wdata : 32'h0;
  assign rf_wdata   = wb_data;

  always_comb begin
    unique case (alu_src_b_sel)
      ALU_SRC_B_RS2:   alu_b_mux = rs2_val;
      ALU_SRC_B_IMM_I: alu_b_mux = imm_i;
      ALU_SRC_B_IMM_S: alu_b_mux = imm_s;
      ALU_SRC_B_IMM_U: alu_b_mux = imm_u;
      default:         alu_b_mux = rs2_val;
    endcase
  end

  always_comb begin
    unique case (alu_y[1:0])
      2'd0: load_byte = dmem_rdata[7:0];
      2'd1: load_byte = dmem_rdata[15:8];
      2'd2: load_byte = dmem_rdata[23:16];
      2'd3: load_byte = dmem_rdata[31:24];
      default: load_byte = dmem_rdata[7:0];
    endcase

    load_half = alu_y[1] ? dmem_rdata[31:16] : dmem_rdata[15:0];

    unique case (funct3)
      3'b000: load_data = {{24{load_byte[7]}}, load_byte};
      3'b001: load_data = {{16{load_half[15]}}, load_half};
      3'b010: load_data = dmem_rdata;
      3'b100: load_data = {24'h0, load_byte};
      3'b101: load_data = {16'h0, load_half};
      default: load_data = dmem_rdata;
    endcase
  end

  always_comb begin
    store_wstrb = 4'b0000;
    store_wdata = 32'h0;

    unique case (funct3)
      3'b000: begin
        unique case (alu_y[1:0])
          2'd0: begin
            store_wstrb = 4'b0001;
            store_wdata = {24'h0, rs2_val[7:0]};
          end
          2'd1: begin
            store_wstrb = 4'b0010;
            store_wdata = {16'h0, rs2_val[7:0], 8'h0};
          end
          2'd2: begin
            store_wstrb = 4'b0100;
            store_wdata = {8'h0, rs2_val[7:0], 16'h0};
          end
          2'd3: begin
            store_wstrb = 4'b1000;
            store_wdata = {rs2_val[7:0], 24'h0};
          end
          default: begin
            store_wstrb = 4'b0000;
            store_wdata = 32'h0;
          end
        endcase
      end
      3'b001: begin
        if (alu_y[1] == 1'b0) begin
          store_wstrb = 4'b0011;
          store_wdata = {16'h0, rs2_val[15:0]};
        end else begin
          store_wstrb = 4'b1100;
          store_wdata = {rs2_val[15:0], 16'h0};
        end
      end
      3'b010: begin
        store_wstrb = 4'b1111;
        store_wdata = rs2_val;
      end
      default: begin
        store_wstrb = 4'b0000;
        store_wdata = 32'h0;
      end
    endcase
  end

  always_comb begin
    unique case (wb_sel)
      WB_SRC_ALU:   wb_data = alu_y;
      WB_SRC_MEM:   wb_data = load_data;
      WB_SRC_PC4:   wb_data = pc_plus4;
      WB_SRC_IMM_U: wb_data = imm_u;
      default:      wb_data = 32'h0;
    endcase
  end

  always_comb begin
    unique case (pc_sel)
      PC_SRC_PC4:    pc_n = pc_plus4;
      PC_SRC_BRANCH: pc_n = branch_target;
      PC_SRC_JAL:    pc_n = jal_target;
      PC_SRC_JALR:   pc_n = jalr_target;
      default:       pc_n = pc_plus4;
    endcase
  end

  always_comb begin
    rf_we    = 1'b0;
    wb_sel   = WB_SRC_ALU;

    alu_src_a_sel = ALU_SRC_A_RS1;
    alu_src_b_sel = ALU_SRC_B_RS2;
    alu_op        = ALU_ADD;

    pc_sel     = PC_SRC_PC4;
    dmem_req   = 1'b0;
    dmem_write = 1'b0;

    unique case (opcode)

      OPC_LUI: begin
        rf_we    = 1'b1;
        wb_sel   = WB_SRC_IMM_U;
      end

      OPC_AUIPC: begin
        rf_we         = 1'b1;
        wb_sel        = WB_SRC_ALU;
        alu_src_a_sel = ALU_SRC_A_PC;
        alu_src_b_sel = ALU_SRC_B_IMM_U;
      end

      OPC_JAL: begin
        rf_we  = 1'b1;
        wb_sel = WB_SRC_PC4;
        pc_sel = PC_SRC_JAL;
      end

      OPC_JALR: begin
        rf_we         = 1'b1;
        wb_sel        = WB_SRC_PC4;
        alu_src_a_sel = ALU_SRC_A_RS1;
        alu_src_b_sel = ALU_SRC_B_IMM_I;
        pc_sel        = PC_SRC_JALR;
      end

      OPC_BRANCH: begin
        if (br_take) begin
          pc_sel = PC_SRC_BRANCH;
        end
      end

      OPC_OPIMM: begin
        rf_we         = 1'b1;
        wb_sel        = WB_SRC_ALU;
        alu_src_a_sel = ALU_SRC_A_RS1;
        alu_src_b_sel = ALU_SRC_B_IMM_I;

        unique case (funct3)
          3'b000: alu_op = ALU_ADD;
          3'b010: alu_op = ALU_SLT;
          3'b011: alu_op = ALU_SLTU;
          3'b100: alu_op = ALU_XOR;
          3'b110: alu_op = ALU_OR;
          3'b111: alu_op = ALU_AND;
          3'b001: alu_op = ALU_SLL;
          3'b101: alu_op = funct7[5] ? ALU_SRA : ALU_SRL;
          default: begin
            rf_we = 1'b0;
          end
        endcase
      end

      OPC_OP: begin
        rf_we         = 1'b1;
        wb_sel        = WB_SRC_ALU;
        alu_src_a_sel = ALU_SRC_A_RS1;
        alu_src_b_sel = ALU_SRC_B_RS2;

        unique case (funct3)
          3'b000: alu_op = funct7[5] ? ALU_SUB : ALU_ADD;
          3'b001: alu_op = ALU_SLL;
          3'b010: alu_op = ALU_SLT;
          3'b011: alu_op = ALU_SLTU;
          3'b100: alu_op = ALU_XOR;
          3'b101: alu_op = funct7[5] ? ALU_SRA : ALU_SRL;
          3'b110: alu_op = ALU_OR;
          3'b111: alu_op = ALU_AND;
          default: begin
            rf_we = 1'b0;
          end
        endcase
      end

      OPC_LOAD: begin
        rf_we         = 1'b1;
        wb_sel        = WB_SRC_MEM;
        alu_src_a_sel = ALU_SRC_A_RS1;
        alu_src_b_sel = ALU_SRC_B_IMM_I;
        alu_op        = ALU_ADD;
        dmem_req      = 1'b1;

        unique case (funct3)
          3'b000,
          3'b001,
          3'b010,
          3'b100,
          3'b101: begin
          end
          default: begin
            rf_we = 1'b0;
          end
        endcase
      end

      OPC_STORE: begin
        alu_src_a_sel = ALU_SRC_A_RS1;
        alu_src_b_sel = ALU_SRC_B_IMM_S;
        alu_op        = ALU_ADD;
        dmem_req      = 1'b1;
        dmem_write    = 1'b1;

        unique case (funct3)
          3'b000,
          3'b001,
          3'b010: begin
          end
          default: begin
            dmem_req   = 1'b0;
            dmem_write = 1'b0;
          end
        endcase
      end

      default: begin
      end
    endcase
  end

  // state update
  always_ff @(posedge clk) begin
    if (!rst_n) pc_q <= 32'h0000_0000;
    else        pc_q <= pc_n;
  end

endmodule