`include "rv32_pkg.vh"

// ============================================================
// rv32_core - RV32I 最小单周期内核（教学/实验用途）
// ------------------------------------------------------------
// 架构特点/假设:
//   - 单周期：一条指令在一个周期内完成（译码→执行→访存→写回）。
//   - imem/dmem 采用“组合读”假设：地址变化后可立即得到 rdata。
//     这让 LOAD 可以在同一周期内完成读出与写回（非常适合 TB/教学）。
//   - 暂无 ready/valid 握手与 stall；无异常/中断/CSR/FENCE 支持。
//   - 未实现的指令默认当作 NOP（不写回/不访存，PC 按 pc+4 前进）。
//
// 端口约定:
//   - 地址均为“字节地址”。
//   - dmem_wstrb 为小端字节使能：wstrb[0] 对应最低字节 byte0。
// ============================================================
module rv32_core (
  input  logic        clk,      // 时钟：posedge 更新 PC/寄存器写端口
  input  logic        rst_n,     // 低有效复位

  // instruction memory（最小核假设为组合读）
  output logic [31:0] imem_addr,  // 取指地址（字节地址）
  input  logic [31:0] imem_rdata, // 取回指令（32 位）

  // data memory（最小核假设为组合读；后续可扩展握手）
  output logic        dmem_valid, // 数据口访问有效（load/store 时置 1）
  output logic        dmem_we,    // 数据口写使能（1=store，0=load）
  output logic [3:0]  dmem_wstrb, // 写字节使能（仅 store 有意义）
  output logic [31:0] dmem_addr,  // 数据口地址（字节地址）
  output logic [31:0] dmem_wdata, // 写数据（配合 wstrb 按字节写入）
  input  logic [31:0] dmem_rdata  // 读数据（组合读）
);

  // ----------------------------
  // ALU 运算编码（与 rv32_alu 内部 ALU_* 对齐）
  // ----------------------------
  localparam logic [3:0] ALU_ADD  = 4'd0; // 加法
  localparam logic [3:0] ALU_SUB  = 4'd1; // 减法
  localparam logic [3:0] ALU_AND  = 4'd2; // 按位与
  localparam logic [3:0] ALU_OR   = 4'd3; // 按位或
  localparam logic [3:0] ALU_XOR  = 4'd4; // 按位异或
  localparam logic [3:0] ALU_SLT  = 4'd5; // 有符号比较：<
  localparam logic [3:0] ALU_SLTU = 4'd6; // 无符号比较：<
  localparam logic [3:0] ALU_SLL  = 4'd7; // 逻辑左移
  localparam logic [3:0] ALU_SRL  = 4'd8; // 逻辑右移
  localparam logic [3:0] ALU_SRA  = 4'd9; // 算术右移

  // ----------------------------
  // ALU 操作数来源选择
  // ----------------------------
  localparam logic       ALU_SRC_A_RS1 = 1'b0; // A = rs1_val
  localparam logic       ALU_SRC_A_PC  = 1'b1; // A = pc_q

  localparam logic [1:0] ALU_SRC_B_RS2   = 2'd0; // B = rs2_val
  localparam logic [1:0] ALU_SRC_B_IMM_I = 2'd1; // B = imm_i
  localparam logic [1:0] ALU_SRC_B_IMM_S = 2'd2; // B = imm_s
  localparam logic [1:0] ALU_SRC_B_IMM_U = 2'd3; // B = imm_u

  // ----------------------------
  // 写回数据来源选择（写入 rd）
  // ----------------------------
  localparam logic [1:0] WB_SRC_ALU   = 2'd0; // 写回 ALU 结果
  localparam logic [1:0] WB_SRC_MEM   = 2'd1; // 写回 LOAD 数据
  localparam logic [1:0] WB_SRC_PC4   = 2'd2; // 写回 PC+4（JAL/JALR）
  localparam logic [1:0] WB_SRC_IMM_U = 2'd3; // 写回 imm_u（LUI）

  // ----------------------------
  // PC 下一值来源选择
  // ----------------------------
  localparam logic [1:0] PC_SRC_PC4    = 2'd0; // 默认：顺序执行 PC+4
  localparam logic [1:0] PC_SRC_BRANCH = 2'd1; // 条件分支成立：PC+imm_b
  localparam logic [1:0] PC_SRC_JAL    = 2'd2; // JAL：PC+imm_j
  localparam logic [1:0] PC_SRC_JALR   = 2'd3; // JALR：(rs1+imm_i)&~1

  // ----------------------------
  // PC 状态寄存器与各类目标地址计算
  // ----------------------------
  logic [31:0] pc_q, pc_n;                              // pc_q：当前 PC（寄存器）；pc_n：下一周期 PC（组合）
  logic [31:0] pc_plus4, branch_target, jal_target, jalr_target; // 常用 PC 候选值

  // ----------------------------
  // 指令字段拆分（来自 imem_rdata）
  // ----------------------------
  logic [6:0] opcode, funct7;
  logic [2:0] funct3;
  logic [4:0] rd, rs1, rs2;

  // 指令字段拆分器：从 instr 中切出 opcode/rd/rs1/rs2/funct3/funct7
  rv32_decode u_dec (
    .instr(imem_rdata),
    .opcode(opcode),
    .funct3(funct3),
    .funct7(funct7),
    .rd(rd), .rs1(rs1), .rs2(rs2)
  );

  // ----------------------------
  // 立即数生成：I/S/B/U/J 五种格式
  // ----------------------------
  logic [31:0] imm_i, imm_s, imm_b, imm_u, imm_j;
  rv32_imm u_imm (.instr(imem_rdata), .imm_i, .imm_s, .imm_b, .imm_u, .imm_j);

  // ----------------------------
  // 寄存器堆：组合读 + 时序写（x0 恒为 0）
  // ----------------------------
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

  // ----------------------------
  // ALU：地址计算/算术逻辑/比较/移位
  // ----------------------------
  logic [3:0]  alu_op;
  logic [31:0] alu_a, alu_b, alu_y;
  logic        alu_src_a_sel;
  logic [1:0]  alu_src_b_sel;
  logic [31:0] alu_b_mux;

  rv32_alu u_alu (.alu_op(alu_op), .a(alu_a), .b(alu_b), .y(alu_y));

  // ----------------------------
  // 分支条件判断：仅决定“是否跳转”，目标地址在上方 branch_target 已计算
  // ----------------------------
  logic br_take;
  rv32_branch u_br (.funct3(funct3), .rs1(rs1_val), .rs2(rs2_val), .take(br_take));

  // ----------------------------
  // 访存相关信号
  //   - dmem_req/dmem_write 控制是否发起 load/store
  //   - store_wstrb/store_wdata 将 SB/SH/SW 转成按字节写
  //   - load_data 将 dmem_rdata 按 LB/LH/LW/LBU/LHU 进行对齐与扩展
  // ----------------------------
  logic        dmem_req;
  logic        dmem_write;
  logic [3:0]  store_wstrb;
  logic [31:0] store_wdata;
  logic [31:0] load_data;
  logic [7:0]  load_byte;
  logic [15:0] load_half;

  logic [1:0]  pc_sel; // PC 下一值选择（PC_SRC_*）

  // ----------------------------
  // 取指与 PC 候选值计算
  // ----------------------------
  assign imem_addr = pc_q;                 // 当前 PC 直接作为取指地址
  assign pc_plus4 = pc_q + 32'd4;          // 顺序执行：PC + 4
  assign branch_target = pc_q + imm_b;     // 分支目标：PC + imm_b
  assign jal_target = pc_q + imm_j;        // JAL 目标：PC + imm_j
  assign jalr_target = {alu_y[31:1], 1'b0}; // JALR 目标：(rs1+imm_i) 的最低位清零（对齐要求）

  // ALU A/B 操作数 mux（由控制信号选择来源）
  assign alu_a = (alu_src_a_sel == ALU_SRC_A_PC) ? pc_q : rs1_val; // A = PC 或 rs1
  assign alu_b = alu_b_mux;                                        // B 由下方 mux 决定

  // ----------------------------
  // 数据存储器端口连线
  // ----------------------------
  assign dmem_valid = dmem_req;                         // 发起 load/store 请求
  assign dmem_we    = dmem_write;                       // store 时为 1
  assign dmem_addr  = dmem_req ? alu_y : 32'h0;         // 地址一般由 ALU 计算（rs1 + imm）
  assign dmem_wstrb = dmem_write ? store_wstrb : 4'b0000; // 写字节使能（非写时置 0）
  assign dmem_wdata = dmem_write ? store_wdata : 32'h0;   // 写数据（非写时置 0）

  // 写回到寄存器堆的数据（最终由 wb_sel 决定）
  assign rf_wdata   = wb_data;

  // ALU B 操作数选择
  always_comb begin
    unique case (alu_src_b_sel)
      ALU_SRC_B_RS2:   alu_b_mux = rs2_val; // R-type: B=rs2
      ALU_SRC_B_IMM_I: alu_b_mux = imm_i;   // I-type: B=imm_i
      ALU_SRC_B_IMM_S: alu_b_mux = imm_s;   // S-type(store): B=imm_s
      ALU_SRC_B_IMM_U: alu_b_mux = imm_u;   // U-type(LUI/AUIPC): B=imm_u
      default:         alu_b_mux = rs2_val; // 防御性默认值
    endcase
  end

  // LOAD 数据格式化：从 32 位 dmem_rdata 中按地址低位选出 byte/half，并做符号/零扩展
  // 说明：testbench 的 RAM 通常按字寻址返回 32 位 word（忽略 addr[1:0]），
  //       所以这里用 alu_y[1:0] 选择对应字节 lane。
  always_comb begin
    // 选中目标字节（小端：addr[1:0]=0 对应最低字节 dmem_rdata[7:0]）
    unique case (alu_y[1:0])
      2'd0: load_byte = dmem_rdata[7:0];
      2'd1: load_byte = dmem_rdata[15:8];
      2'd2: load_byte = dmem_rdata[23:16];
      2'd3: load_byte = dmem_rdata[31:24];
      default: load_byte = dmem_rdata[7:0];
    endcase

    // 选中目标半字（addr[1]=0 -> 低 16 位；addr[1]=1 -> 高 16 位）
    load_half = alu_y[1] ? dmem_rdata[31:16] : dmem_rdata[15:0];

    // 按 funct3 做扩展/对齐
    unique case (funct3)
      3'b000: load_data = {{24{load_byte[7]}}, load_byte}; // LB  : 8 位符号扩展
      3'b001: load_data = {{16{load_half[15]}}, load_half}; // LH  : 16 位符号扩展
      3'b010: load_data = dmem_rdata;                      // LW  : 32 位原样
      3'b100: load_data = {24'h0, load_byte};              // LBU : 8 位零扩展
      3'b101: load_data = {16'h0, load_half};              // LHU : 16 位零扩展
      default: load_data = dmem_rdata;                     // 防御性默认
    endcase
  end

  // STORE 写数据与字节使能生成：将 SB/SH/SW 统一转成 (wstrb + wdata)
  // 小端约定：
  //   wstrb[0] -> 写入 word 的 byte0 (bits[7:0])
  //   wstrb[1] -> 写入 word 的 byte1 (bits[15:8])
  //   wstrb[2] -> 写入 word 的 byte2 (bits[23:16])
  //   wstrb[3] -> 写入 word 的 byte3 (bits[31:24])
  always_comb begin
    store_wstrb = 4'b0000; // 默认不写
    store_wdata = 32'h0;

    unique case (funct3)
      3'b000: begin // SB: 写 1 字节
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
      3'b001: begin // SH: 写 16 位半字
        if (alu_y[1] == 1'b0) begin
          store_wstrb = 4'b0011;                // 写低半字（byte0/byte1）
          store_wdata = {16'h0, rs2_val[15:0]};
        end else begin
          store_wstrb = 4'b1100;                // 写高半字（byte2/byte3）
          store_wdata = {rs2_val[15:0], 16'h0};
        end
      end
      3'b010: begin // SW: 写 32 位整字
        store_wstrb = 4'b1111;
        store_wdata = rs2_val;
      end
      default: begin
        store_wstrb = 4'b0000;
        store_wdata = 32'h0;
      end
    endcase
  end

  // 写回数据 mux：决定写入 rd 的数据来自哪里
  always_comb begin
    unique case (wb_sel)
      WB_SRC_ALU:   wb_data = alu_y;     // ALU 运算结果
      WB_SRC_MEM:   wb_data = load_data; // LOAD 读出并格式化后的数据
      WB_SRC_PC4:   wb_data = pc_plus4;  // PC+4（link 地址）
      WB_SRC_IMM_U: wb_data = imm_u;     // U-type 立即数（LUI）
      default:      wb_data = 32'h0;
    endcase
  end

  // PC 下一值 mux：决定下一周期执行哪条指令
  always_comb begin
    unique case (pc_sel)
      PC_SRC_PC4:    pc_n = pc_plus4;      // 默认顺序执行
      PC_SRC_BRANCH: pc_n = branch_target; // 分支
      PC_SRC_JAL:    pc_n = jal_target;    // JAL
      PC_SRC_JALR:   pc_n = jalr_target;   // JALR
      default:       pc_n = pc_plus4;
    endcase
  end

  // ----------------------------
  // 主控制器：根据 opcode/funct3/funct7 产生控制信号
  // ----------------------------
  always_comb begin
    // 默认值 = NOP（不写回、不访存、PC+4、ALU 默认 ADD）
    rf_we    = 1'b0;
    wb_sel   = WB_SRC_ALU;

    alu_src_a_sel = ALU_SRC_A_RS1;
    alu_src_b_sel = ALU_SRC_B_RS2;
    alu_op        = ALU_ADD;

    pc_sel     = PC_SRC_PC4;
    dmem_req   = 1'b0;
    dmem_write = 1'b0;

    unique case (opcode)

      OPC_LUI: begin // LUI: rd = imm_u
        rf_we    = 1'b1;
        wb_sel   = WB_SRC_IMM_U;
      end

      OPC_AUIPC: begin // AUIPC: rd = pc + imm_u
        rf_we         = 1'b1;
        wb_sel        = WB_SRC_ALU;
        alu_src_a_sel = ALU_SRC_A_PC;
        alu_src_b_sel = ALU_SRC_B_IMM_U;
      end

      OPC_JAL: begin // JAL: rd = pc+4; pc = pc + imm_j
        rf_we  = 1'b1;
        wb_sel = WB_SRC_PC4;
        pc_sel = PC_SRC_JAL;
      end

      OPC_JALR: begin // JALR: rd = pc+4; pc = (rs1 + imm_i) & ~1
        rf_we         = 1'b1;
        wb_sel        = WB_SRC_PC4;
        alu_src_a_sel = ALU_SRC_A_RS1;
        alu_src_b_sel = ALU_SRC_B_IMM_I;
        pc_sel        = PC_SRC_JALR;
      end

      OPC_BRANCH: begin // 条件分支：不写回；br_take=1 时选择 branch_target
        if (br_take) begin
          pc_sel = PC_SRC_BRANCH;
        end
      end

      OPC_OPIMM: begin // I-type ALU：rd = rs1 (op) imm_i
        rf_we         = 1'b1;
        wb_sel        = WB_SRC_ALU;
        alu_src_a_sel = ALU_SRC_A_RS1;
        alu_src_b_sel = ALU_SRC_B_IMM_I;

        unique case (funct3)
          3'b000: alu_op = ALU_ADD;                       // ADDI
          3'b010: alu_op = ALU_SLT;                       // SLTI
          3'b011: alu_op = ALU_SLTU;                      // SLTIU
          3'b100: alu_op = ALU_XOR;                       // XORI
          3'b110: alu_op = ALU_OR;                        // ORI
          3'b111: alu_op = ALU_AND;                       // ANDI
          3'b001: alu_op = ALU_SLL;                       // SLLI（移位量在 imm[4:0]）
          3'b101: alu_op = funct7[5] ? ALU_SRA : ALU_SRL; // SRLI/SRAI：bit30 区分
          default: begin
            rf_we = 1'b0;
          end
        endcase
      end

      OPC_OP: begin // R-type ALU：rd = rs1 (op) rs2
        rf_we         = 1'b1;
        wb_sel        = WB_SRC_ALU;
        alu_src_a_sel = ALU_SRC_A_RS1;
        alu_src_b_sel = ALU_SRC_B_RS2;

        unique case (funct3)
          3'b000: alu_op = funct7[5] ? ALU_SUB : ALU_ADD; // SUB/ADD：bit30 区分
          3'b001: alu_op = ALU_SLL;                       // SLL
          3'b010: alu_op = ALU_SLT;                       // SLT
          3'b011: alu_op = ALU_SLTU;                      // SLTU
          3'b100: alu_op = ALU_XOR;                       // XOR
          3'b101: alu_op = funct7[5] ? ALU_SRA : ALU_SRL; // SRA/SRL：bit30 区分
          3'b110: alu_op = ALU_OR;                        // OR
          3'b111: alu_op = ALU_AND;                       // AND
          default: begin
            rf_we = 1'b0;
          end
        endcase
      end

      OPC_LOAD: begin // LOAD：地址=rs1+imm_i；rd=mem[addr]（按 funct3 扩展）
        rf_we         = 1'b1;
        wb_sel        = WB_SRC_MEM;
        alu_src_a_sel = ALU_SRC_A_RS1;
        alu_src_b_sel = ALU_SRC_B_IMM_I;
        alu_op        = ALU_ADD;
        dmem_req      = 1'b1;

        // 这里只做 funct3 合法性过滤；具体的对齐/扩展在 load_data always_comb 完成
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

      OPC_STORE: begin // STORE：地址=rs1+imm_s；mem[addr]=rs2（按 funct3 生成 wstrb/wdata）
        alu_src_a_sel = ALU_SRC_A_RS1;
        alu_src_b_sel = ALU_SRC_B_IMM_S;
        alu_op        = ALU_ADD;
        dmem_req      = 1'b1;
        dmem_write    = 1'b1;

        // 这里只做 funct3 合法性过滤；具体的 wstrb/wdata 在 store_wstrb/store_wdata always_comb 完成
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

  // ----------------------------
  // 状态更新：PC 寄存器
  // ----------------------------
  always_ff @(posedge clk) begin
    if (!rst_n) pc_q <= 32'h0000_0000; // 复位后从地址 0 开始取指
    else        pc_q <= pc_n;          // 正常情况下更新为组合得到的下一 PC
  end

endmodule