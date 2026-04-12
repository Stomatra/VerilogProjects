#!/usr/bin/env python3
"""生成 RV32I 37 条指令的单元测试 hex 文件（教学脚本）。

输出位置:
    - 默认写入本文件同级目录下的 tests/*.hex

与 TB 的约定（非常重要）:
    - 这些测试程序会在末尾通过 store 向数据 RAM 写入“结果标志”：
        - 写 ram[1] = 1          表示 PASS
        - 写 ram[1] = 0xDEAD_BEEF 表示 FAIL
    - testbench 会在每个周期监视 ram[1]，一旦看到 PASS/FAIL 就结束仿真。

脚本结构概览:
    1) 指令编码器：r_type/i_type/s_type/b_type/u_type/j_type
    2) 常用指令包装：ADDI/LW/SW/BEQ/...（便于写测试用例）
    3) PASS/FAIL 序列：pass_seq()/fail_seq()
    4) 标准模板：alu_test() / branch_test() 快速拼装测试程序
    5) 为每条指令生成一个 tests/xxx.hex
"""

import os

# ---------- 指令编码器（拼 32 位指令字） ----------
# 说明：这些函数只负责把字段按 RISC-V 手册的 bit 位置打包成 32bit 指令。
#       立即数传入时会被 mask 到对应宽度（例如 I/S 的 imm12）。

def r_type(funct7, rs2, rs1, funct3, rd, opcode):
    return ((funct7 & 0x7F) << 25) | ((rs2 & 0x1F) << 20) | \
           ((rs1 & 0x1F) << 15) | ((funct3 & 0x7) << 12) | \
           ((rd & 0x1F) << 7) | (opcode & 0x7F)

def i_type(imm, rs1, funct3, rd, opcode):
    imm12 = imm & 0xFFF
    return (imm12 << 20) | ((rs1 & 0x1F) << 15) | ((funct3 & 0x7) << 12) | \
           ((rd & 0x1F) << 7) | (opcode & 0x7F)

def s_type(imm, rs2, rs1, funct3, opcode):
    imm12 = imm & 0xFFF
    return (((imm12 >> 5) & 0x7F) << 25) | ((rs2 & 0x1F) << 20) | \
           ((rs1 & 0x1F) << 15) | ((funct3 & 0x7) << 12) | \
           ((imm12 & 0x1F) << 7) | (opcode & 0x7F)

def b_type(imm, rs2, rs1, funct3, opcode):
    # B-type 偏移是 13bit，且 bit0 永远为 0（2 字节对齐），这里先把 imm 做对齐 mask。
    imm_val = imm & 0x1FFE  # 13-bit, bit0 always 0 (mask to keep even)
    imm12   = (imm_val >> 12) & 1
    imm10_5 = (imm_val >> 5)  & 0x3F
    imm4_1  = (imm_val >> 1)  & 0xF
    imm11   = (imm_val >> 11) & 1
    return (imm12 << 31) | (imm10_5 << 25) | ((rs2 & 0x1F) << 20) | \
           ((rs1 & 0x1F) << 15) | ((funct3 & 0x7) << 12) | \
           (imm4_1 << 8) | (imm11 << 7) | (opcode & 0x7F)

def u_type(imm20, rd, opcode):
    return ((imm20 & 0xFFFFF) << 12) | ((rd & 0x1F) << 7) | (opcode & 0x7F)

def j_type(imm, rd, opcode):
    # J-type 偏移是 21bit，且 bit0 永远为 0（2 字节对齐）
    imm_val  = imm & 0x1FFFFE  # 21-bit, bit0 always 0
    imm20    = (imm_val >> 20) & 1
    imm10_1  = (imm_val >> 1)  & 0x3FF
    imm11    = (imm_val >> 11) & 1
    imm19_12 = (imm_val >> 12) & 0xFF
    return (imm20 << 31) | (imm10_1 << 21) | (imm11 << 20) | \
           (imm19_12 << 12) | ((rd & 0x1F) << 7) | (opcode & 0x7F)

# ---------- 主 opcode 常量（instr[6:0]） ----------
OPC_LUI    = 0b0110111
OPC_AUIPC  = 0b0010111
OPC_JAL    = 0b1101111
OPC_JALR   = 0b1100111
OPC_BRANCH = 0b1100011
OPC_LOAD   = 0b0000011
OPC_STORE  = 0b0100011
OPC_OPIMM  = 0b0010011
OPC_OP     = 0b0110011

# ---------- 常用指令包装（便于写测试用例） ----------
# 说明：下面这些函数返回 32bit 指令字（Python int），最终会被写入 .hex。
def NOP():                       return i_type(0, 0, 0, 0, OPC_OPIMM)  # addi x0,x0,0
def ADDI(rd, rs1, imm):          return i_type(imm, rs1, 0b000, rd, OPC_OPIMM)
def LUI_I(rd, imm20):            return u_type(imm20, rd, OPC_LUI)
def AUIPC_I(rd, imm20):          return u_type(imm20, rd, OPC_AUIPC)
def JAL_I(rd, offset):           return j_type(offset, rd, OPC_JAL)
def JAL_HALT():                  return j_type(0, 0, OPC_JAL)  # jal x0,0 -> infinite loop
def JALR_I(rd, rs1, imm):        return i_type(imm, rs1, 0b000, rd, OPC_JALR)
def BEQ(rs1, rs2, offset):       return b_type(offset, rs2, rs1, 0b000, OPC_BRANCH)
def BNE(rs1, rs2, offset):       return b_type(offset, rs2, rs1, 0b001, OPC_BRANCH)
def BLT(rs1, rs2, offset):       return b_type(offset, rs2, rs1, 0b100, OPC_BRANCH)
def BGE(rs1, rs2, offset):       return b_type(offset, rs2, rs1, 0b101, OPC_BRANCH)
def BLTU(rs1, rs2, offset):      return b_type(offset, rs2, rs1, 0b110, OPC_BRANCH)
def BGEU(rs1, rs2, offset):      return b_type(offset, rs2, rs1, 0b111, OPC_BRANCH)
def LB(rd, rs1, imm):            return i_type(imm, rs1, 0b000, rd, OPC_LOAD)
def LH(rd, rs1, imm):            return i_type(imm, rs1, 0b001, rd, OPC_LOAD)
def LW(rd, rs1, imm):            return i_type(imm, rs1, 0b010, rd, OPC_LOAD)
def LBU(rd, rs1, imm):           return i_type(imm, rs1, 0b100, rd, OPC_LOAD)
def LHU(rd, rs1, imm):           return i_type(imm, rs1, 0b101, rd, OPC_LOAD)
def SB(rs2, rs1, imm):           return s_type(imm, rs2, rs1, 0b000, OPC_STORE)
def SH(rs2, rs1, imm):           return s_type(imm, rs2, rs1, 0b001, OPC_STORE)
def SW(rs2, rs1, imm):           return s_type(imm, rs2, rs1, 0b010, OPC_STORE)
def SLTI(rd, rs1, imm):          return i_type(imm, rs1, 0b010, rd, OPC_OPIMM)
def SLTIU(rd, rs1, imm):         return i_type(imm, rs1, 0b011, rd, OPC_OPIMM)
def XORI(rd, rs1, imm):          return i_type(imm, rs1, 0b100, rd, OPC_OPIMM)
def ORI(rd, rs1, imm):           return i_type(imm, rs1, 0b110, rd, OPC_OPIMM)
def ANDI(rd, rs1, imm):          return i_type(imm, rs1, 0b111, rd, OPC_OPIMM)
def SLLI(rd, rs1, shamt):        return i_type(shamt & 0x1F, rs1, 0b001, rd, OPC_OPIMM)
def SRLI(rd, rs1, shamt):        return i_type(shamt & 0x1F, rs1, 0b101, rd, OPC_OPIMM)
def SRAI(rd, rs1, shamt):        return i_type(0x400 | (shamt & 0x1F), rs1, 0b101, rd, OPC_OPIMM)
def ADD(rd, rs1, rs2):           return r_type(0b0000000, rs2, rs1, 0b000, rd, OPC_OP)
def SUB(rd, rs1, rs2):           return r_type(0b0100000, rs2, rs1, 0b000, rd, OPC_OP)
def SLL(rd, rs1, rs2):           return r_type(0b0000000, rs2, rs1, 0b001, rd, OPC_OP)
def SLT(rd, rs1, rs2):           return r_type(0b0000000, rs2, rs1, 0b010, rd, OPC_OP)
def SLTU_R(rd, rs1, rs2):        return r_type(0b0000000, rs2, rs1, 0b011, rd, OPC_OP)
def XOR(rd, rs1, rs2):           return r_type(0b0000000, rs2, rs1, 0b100, rd, OPC_OP)
def SRL(rd, rs1, rs2):           return r_type(0b0000000, rs2, rs1, 0b101, rd, OPC_OP)
def SRA(rd, rs1, rs2):           return r_type(0b0100000, rs2, rs1, 0b101, rd, OPC_OP)
def OR(rd, rs1, rs2):            return r_type(0b0000000, rs2, rs1, 0b110, rd, OPC_OP)
def AND_R(rd, rs1, rs2):         return r_type(0b0000000, rs2, rs1, 0b111, rd, OPC_OP)

# ---------- 五级流水线辅助 ----------
# 当前 core 是 5-stage pipeline，且“暂时没有 forwarding / hazard detection”。
# 因此测试程序里需要在“写寄存器 -> 下一条读该寄存器”之间插入若干 NOP，
# 让写回先到达 WB 阶段，再让消费者在 ID 阶段读到新值。
PIPELINE_GAP = 3

def gap(n=PIPELINE_GAP):
    """Return n pipeline-bubble NOPs."""
    return [NOP()] * n

def pad_linear(instrs, after_last=True):
    """Insert PIPELINE_GAP NOPs after each instruction in a linear sequence."""
    out = []
    for idx, instr in enumerate(instrs):
        out.append(instr)
        if after_last or idx != len(instrs) - 1:
            out.extend(gap())
    return out

# ---------- PASS/FAIL 序列（与 TB 约定） ----------
# PASS: 向 ram[1]（地址 4）写入 1，然后进入死循环（JAL x0,0）
# FAIL: 向 ram[1]（地址 4）写入 0xDEAD_BEEF，然后进入死循环
#
# 注意：很多用例会用到 0xDEAD_BEEF 常量。
# 这里用两条指令构造它：
#   0xDEAD_BEEF = (LUI 0xDEADC -> 0xDEADC000) + (ADDI 0xEEF -> -273)
# 即 0xDEADC000 + (-273) = 0xDEADBEEF

def pass_seq(rd=5):
    """Pipeline-safe PASS sequence."""
    return [
        ADDI(rd, 0, 1),      # rd = 1
        *gap(),              # wait for rd to reach WB before SW reads it
        SW(rd, 0, 4),        # sw rd, 4(x0) -> ram[1] = 1 (PASS)
        JAL_HALT(),          # infinite loop
    ]

def fail_seq(rd=5):
    """Pipeline-safe FAIL sequence."""
    return [
        LUI_I(rd, 0xDEADC),  # rd = 0xDEADC000
        *gap(),              # wait before dependent ADDI reads rd
        ADDI(rd, rd, 0xEEF), # rd = 0xDEADC000 + (-273) = 0xDEADBEEF
        *gap(),              # wait before SW reads rd
        SW(rd, 0, 4),        # ram[1] = DEADBEEF (FAIL)
        JAL_HALT(),          # infinite loop
    ]

def write_hex(path, instrs):
    """Write list of 32-bit instruction words as hex file."""
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w') as f:
        for instr in instrs:
            f.write(f'{instr:08x}\n')

def alu_test(setup_instrs, result_reg, expected_reg):
    """Build a pipeline-safe ALU-style test program."""
    setup = pad_linear(setup_instrs, after_last=True)
    pass_ = pass_seq()
    fail_ = fail_seq()
    bne_to_fail = 4 * (1 + len(pass_))
    bne_instr = BNE(result_reg, expected_reg, bne_to_fail)
    return setup + [bne_instr] + pass_ + fail_

# =============================================
# 生成测试程序（每个指令 1 个 .hex）
# =============================================
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'tests')

# ---- 1. LUI ----
# lui x1, 0x12345 -> x1 = 0x12345000
# expected: lui x2, 0x12345 -> x2 = 0x12345000
write_hex(f'{OUT}/lui.hex', alu_test(
    [LUI_I(1, 0x12345),
     LUI_I(2, 0x12345)],   # expected same LUI result
    result_reg=1, expected_reg=2
))

# ---- 2. AUIPC ----
# auipc x1, 1 at PC=0 -> x1 = 0 + 0x1000 = 0x1000
# lui x2, 1 -> x2 = 0x1000
write_hex(f'{OUT}/auipc.hex', alu_test(
    [AUIPC_I(1, 1),         # x1 = PC + 0x1000 = 0x1000 (at PC=0)
     LUI_I(2, 1)],          # x2 = 0x1000
    result_reg=1, expected_reg=2
))

# ---- 3. JAL ----
# 跳转成功后：
#   - x1 应写回返回地址 4
#   - 跳到检查块，再用 BNE 判定 PASS/FAIL
jal_fail_fallthrough = fail_seq(5)
jal_pass = pass_seq(5)
jal_fail_check = fail_seq(5)
jal_check = pad_linear([ADDI(2, 0, 4)], after_last=True) + [
    BNE(1, 2, 4 * (1 + len(jal_pass)))
] + jal_pass + jal_fail_check
jal_prog = [
    JAL_I(1, 4 * (1 + len(jal_fail_fallthrough))),  # jump over fallthrough FAIL block
] + jal_fail_fallthrough + jal_check
write_hex(f'{OUT}/jal.hex', jal_prog)

# ---- 4. JALR ----
# 先把目标地址写进 x1，再通过 JALR 跳过去。
# 由于写 x1 与读 x1 之间存在 RAW hazard，这里显式插入气泡。
jalr_fail_fallthrough = fail_seq(5)
jalr_pass = pass_seq(5)
jalr_fail_check = fail_seq(5)
jalr_prefix_len = 1 + PIPELINE_GAP + 1  # addi target + bubbles + jalr
jalr_target_pc = 4 * (jalr_prefix_len + len(jalr_fail_fallthrough))
jalr_return_pc = 4 * jalr_prefix_len
jalr_check = pad_linear([ADDI(3, 0, jalr_return_pc)], after_last=True) + [
    BNE(2, 3, 4 * (1 + len(jalr_pass)))
] + jalr_pass + jalr_fail_check
jalr_prog = [
    ADDI(1, 0, jalr_target_pc),  # x1 = target PC
    *gap(),                      # wait before JALR reads x1
    JALR_I(2, 1, 0),             # x2 = return PC, PC = x1
] + jalr_fail_fallthrough + jalr_check
write_hex(f'{OUT}/jalr.hex', jalr_prog)

# ---- 分支测试 (5-10): beq, bne, blt, bge, bltu, bgeu ----
# 测试思路：这些分支都“应该被执行为跳转成立（TAKEN）”。
#   - 如果分支成立：跳过 FAIL，落到 PASS。
#   - 如果分支不成立：顺序执行会落入 FAIL。
#
def branch_test(setup1, setup2, branch_instr_fn, comment=""):
    """Branch should be TAKEN in the pipeline-safe test."""
    fail = fail_seq(5)
    pass_ = pass_seq(5)
    branch_pass_offset = 4 * (1 + len(fail))
    prog = pad_linear([
        setup1,                                  # PC=0
        setup2,                                  # PC=4
    ], after_last=True) + [
        branch_instr_fn(branch_pass_offset),     # 跳过 FAIL block 落到 PASS
    ] + fail + pass_
    return prog

# ---- 5. BEQ ----
# x1==x2 -> taken
write_hex(f'{OUT}/beq.hex', branch_test(
    ADDI(1, 0, 7),
    ADDI(2, 0, 7),
    lambda off: BEQ(1, 2, off)
))

# ---- 6. BNE ----
# x1!=x2 -> taken
write_hex(f'{OUT}/bne.hex', branch_test(
    ADDI(1, 0, 3),
    ADDI(2, 0, 5),
    lambda off: BNE(1, 2, off)
))

# ---- 7. BLT ----
# x1 < x2 signed -> taken: x1=-1, x2=1
write_hex(f'{OUT}/blt.hex', branch_test(
    ADDI(1, 0, 0xFFF),   # x1 = -1 (sign-extended 12-bit all-ones)
    ADDI(2, 0, 1),
    lambda off: BLT(1, 2, off)
))

# ---- 8. BGE ----
# x1 >= x2 signed -> taken: x1=5, x2=-1
write_hex(f'{OUT}/bge.hex', branch_test(
    ADDI(1, 0, 5),
    ADDI(2, 0, 0xFFF),   # x2 = -1
    lambda off: BGE(1, 2, off)
))

# ---- 9. BLTU ----
# x1 < x2 unsigned -> taken: x1=1, x2=0xFFFFFFFF (x2=-1 as signed=max uint)
write_hex(f'{OUT}/bltu.hex', branch_test(
    ADDI(1, 0, 1),
    ADDI(2, 0, 0xFFF),   # x2 = 0xFFFFFFFF unsigned
    lambda off: BLTU(1, 2, off)
))

# ---- 10. BGEU ----
# x1 >= x2 unsigned -> taken: x1=0xFFFFFFFF, x2=1
write_hex(f'{OUT}/bgeu.hex', branch_test(
    ADDI(1, 0, 0xFFF),   # x1 = 0xFFFFFFFF
    ADDI(2, 0, 1),
    lambda off: BGEU(1, 2, off)
))

# ---- 11. LB ----
# Store 0xFF (as byte) at addr 8, load with LB -> -1 (0xFFFFFFFF)
# Expected: addi x4, x0, -1 = 0xFFFFFFFF
write_hex(f'{OUT}/lb.hex', alu_test(
    [ADDI(1, 0, 0xFFF),  # x1 = 0xFFFFFFFF (byte[7:0]=0xFF)
     SB(1, 0, 8),        # store byte 0xFF at addr 8
     LB(3, 0, 8),        # x3 = sign_ext(0xFF) = 0xFFFFFFFF
     ADDI(4, 0, 0xFFF)], # x4 = -1 = 0xFFFFFFFF (expected)
    result_reg=3, expected_reg=4
))

# ---- 12. LH ----
# Store 0xFFFF (as halfword) at addr 8, load with LH -> -1
write_hex(f'{OUT}/lh.hex', alu_test(
    [ADDI(1, 0, 0xFFF),  # x1 = 0xFFFFFFFF (half[15:0]=0xFFFF)
     SH(1, 0, 8),        # store halfword 0xFFFF at addr 8
     LH(3, 0, 8),        # x3 = sign_ext(0xFFFF) = 0xFFFFFFFF
     ADDI(4, 0, 0xFFF)], # x4 = -1 (expected)
    result_reg=3, expected_reg=4
))

# ---- 13. LW ----
# Store 42 at addr 8, load with LW -> 42
write_hex(f'{OUT}/lw.hex', alu_test(
    [ADDI(1, 0, 42),    # x1 = 42
     SW(1, 0, 8),       # store word 42 at addr 8
     LW(3, 0, 8),       # x3 = 42
     ADDI(4, 0, 42)],   # x4 = 42 (expected)
    result_reg=3, expected_reg=4
))

# ---- 14. LBU ----
# Store 0xFF byte at addr 8, load with LBU -> 0xFF = 255 (zero-extended)
write_hex(f'{OUT}/lbu.hex', alu_test(
    [ADDI(1, 0, 0xFFF),  # x1 = 0xFFFFFFFF (byte 0xFF)
     SB(1, 0, 8),        # store byte 0xFF at addr 8
     LBU(3, 0, 8),       # x3 = 0x000000FF = 255
     ADDI(4, 0, 255)],   # x4 = 255 (expected, fits in 12-bit)
    result_reg=3, expected_reg=4
))

# ---- 15. LHU ----
# Store 0x7FF halfword at addr 8, load with LHU -> 0x7FF = 2047 (zero-extended)
write_hex(f'{OUT}/lhu.hex', alu_test(
    [ADDI(1, 0, 0x7FF),  # x1 = 2047 (halfword 0x07FF)
     SH(1, 0, 8),        # store halfword 0x07FF at addr 8
     LHU(3, 0, 8),       # x3 = 0x000007FF = 2047
     ADDI(4, 0, 0x7FF)], # x4 = 2047 (expected)
    result_reg=3, expected_reg=4
))

# ---- 16. SB ----
# Store byte 0xAB at addr 8, reload with LBU -> 0xAB = 171
write_hex(f'{OUT}/sb.hex', alu_test(
    [ADDI(1, 0, 171),    # x1 = 0xAB = 171 (byte value to store)
     SB(1, 0, 8),        # store byte at addr 8
     LBU(3, 0, 8),       # reload as unsigned byte -> 171
     ADDI(4, 0, 171)],   # expected 171
    result_reg=3, expected_reg=4
))

# ---- 17. SH ----
# Store halfword 1234 at addr 8, reload with LHU -> 1234
write_hex(f'{OUT}/sh.hex', alu_test(
    [ADDI(1, 0, 1234),   # x1 = 1234 (fits in 12-bit signed: <2047)
     SH(1, 0, 8),        # store halfword at addr 8
     LHU(3, 0, 8),       # reload as unsigned halfword -> 1234
     ADDI(4, 0, 1234)],  # expected 1234
    result_reg=3, expected_reg=4
))

# ---- 18. SW ----
# Store word 2047 at addr 8, reload with LW -> 2047
write_hex(f'{OUT}/sw.hex', alu_test(
    [ADDI(1, 0, 2047),   # x1 = 2047
     SW(1, 0, 8),        # store word at addr 8
     LW(3, 0, 8),        # reload -> 2047
     ADDI(4, 0, 2047)],  # expected 2047
    result_reg=3, expected_reg=4
))

# ---- 19. ADDI ----
# addi x3, x1, 3 where x1=5 -> x3=8
write_hex(f'{OUT}/addi.hex', alu_test(
    [ADDI(1, 0, 5),
     ADDI(3, 1, 3),      # x3 = 5 + 3 = 8
     ADDI(4, 0, 8)],     # expected = 8
    result_reg=3, expected_reg=4
))

# ---- 20. SLTI ----
# slti x3, x1, 0 where x1=-1 -> x3=1 (-1 < 0 signed)
write_hex(f'{OUT}/slti.hex', alu_test(
    [ADDI(1, 0, 0xFFF),  # x1 = -1
     SLTI(3, 1, 0),      # x3 = (-1 < 0) = 1
     ADDI(4, 0, 1)],     # expected = 1
    result_reg=3, expected_reg=4
))

# ---- 21. SLTIU ----
# sltiu x3, x1, -1(=0xFFF) where x1=0 -> x3=1 (0 < 0xFFFFFFFF unsigned)
write_hex(f'{OUT}/sltiu.hex', alu_test(
    [ADDI(1, 0, 0),
     SLTIU(3, 1, 0xFFF), # x3 = (0 < 0xFFFFFFFF) = 1
     ADDI(4, 0, 1)],     # expected = 1
    result_reg=3, expected_reg=4
))

# ---- 22. XORI ----
# xori x3, x1, 0xFF where x1=0xAA -> x3=0x55
write_hex(f'{OUT}/xori.hex', alu_test(
    [ADDI(1, 0, 0xAA),   # x1 = 0xAA = 170
     XORI(3, 1, 0xFF),   # x3 = 0xAA ^ 0xFF = 0x55 = 85
     ADDI(4, 0, 0x55)],  # expected = 85
    result_reg=3, expected_reg=4
))

# ---- 23. ORI ----
# ori x3, x1, 0xF0 where x1=0x0F -> x3=0xFF
write_hex(f'{OUT}/ori.hex', alu_test(
    [ADDI(1, 0, 0x0F),   # x1 = 0x0F = 15
     ORI(3, 1, 0xF0),    # x3 = 0x0F | 0xF0 = 0xFF = 255
     ADDI(4, 0, 255)],   # expected = 255
    result_reg=3, expected_reg=4
))

# ---- 24. ANDI ----
# andi x3, x1, 0xF0 where x1=0xFF -> x3=0xF0
write_hex(f'{OUT}/andi.hex', alu_test(
    [ADDI(1, 0, 255),    # x1 = 0xFF
     ANDI(3, 1, 0xF0),   # x3 = 0xFF & 0xF0 = 0xF0 = 240
     ADDI(4, 0, 240)],   # expected = 240
    result_reg=3, expected_reg=4
))

# ---- 25. SLLI ----
# slli x3, x1, 3 where x1=5 -> x3=40
write_hex(f'{OUT}/slli.hex', alu_test(
    [ADDI(1, 0, 5),
     SLLI(3, 1, 3),      # x3 = 5 << 3 = 40
     ADDI(4, 0, 40)],    # expected = 40
    result_reg=3, expected_reg=4
))

# ---- 26. SRLI ----
# srli x3, x1, 2 where x1=20 -> x3=5
write_hex(f'{OUT}/srli.hex', alu_test(
    [ADDI(1, 0, 20),
     SRLI(3, 1, 2),      # x3 = 20 >> 2 = 5
     ADDI(4, 0, 5)],     # expected = 5
    result_reg=3, expected_reg=4
))

# ---- 27. SRAI ----
# srai x3, x1, 1 where x1=-4 (0xFFFFFFFC) -> x3=-2 (0xFFFFFFFE)
write_hex(f'{OUT}/srai.hex', alu_test(
    [ADDI(1, 0, 0xFFC),  # x1 = -4 (sign-ext 0xFFC = -4)
     SRAI(3, 1, 1),      # x3 = -4 >> 1 = -2 (arithmetic)
     ADDI(4, 0, 0xFFE)], # x4 = -2 (0xFFE sign-ext = -2)
    result_reg=3, expected_reg=4
))

# ---- 28. ADD ----
# add x3, x1, x2 where x1=100, x2=200 -> x3=300
write_hex(f'{OUT}/add.hex', alu_test(
    [ADDI(1, 0, 100),
     ADDI(2, 0, 200),
     ADD(3, 1, 2),       # x3 = 300
     ADDI(4, 0, 300)],   # expected = 300
    result_reg=3, expected_reg=4
))

# ---- 29. SUB ----
# sub x3, x1, x2 where x1=10, x2=3 -> x3=7
write_hex(f'{OUT}/sub.hex', alu_test(
    [ADDI(1, 0, 10),
     ADDI(2, 0, 3),
     SUB(3, 1, 2),       # x3 = 10 - 3 = 7
     ADDI(4, 0, 7)],     # expected = 7
    result_reg=3, expected_reg=4
))

# ---- 30. SLL ----
# sll x3, x1, x2 where x1=1, x2=8 -> x3=256
write_hex(f'{OUT}/sll.hex', alu_test(
    [ADDI(1, 0, 1),
     ADDI(2, 0, 8),
     SLL(3, 1, 2),       # x3 = 1 << 8 = 256
     ADDI(4, 0, 256)],   # expected = 256
    result_reg=3, expected_reg=4
))

# ---- 31. SLT ----
# slt x3, x1, x2 where x1=-1, x2=0 -> x3=1 (-1 < 0 signed)
write_hex(f'{OUT}/slt.hex', alu_test(
    [ADDI(1, 0, 0xFFF),  # x1 = -1
     ADDI(2, 0, 0),
     SLT(3, 1, 2),       # x3 = (-1 < 0) = 1
     ADDI(4, 0, 1)],     # expected = 1
    result_reg=3, expected_reg=4
))

# ---- 32. SLTU ----
# sltu x3, x1, x2 where x1=0, x2=0xFFFFFFFF -> x3=1
write_hex(f'{OUT}/sltu.hex', alu_test(
    [ADDI(1, 0, 0),
     ADDI(2, 0, 0xFFF),  # x2 = 0xFFFFFFFF
     SLTU_R(3, 1, 2),    # x3 = (0 < 0xFFFFFFFF) = 1
     ADDI(4, 0, 1)],     # expected = 1
    result_reg=3, expected_reg=4
))

# ---- 33. XOR ----
# xor x3, x1, x2 where x1=0xF0, x2=0x0F -> x3=0xFF
write_hex(f'{OUT}/xor.hex', alu_test(
    [ADDI(1, 0, 0xF0),   # x1 = 240
     ADDI(2, 0, 0x0F),   # x2 = 15
     XOR(3, 1, 2),       # x3 = 0xF0 ^ 0x0F = 0xFF = 255
     ADDI(4, 0, 255)],   # expected = 255
    result_reg=3, expected_reg=4
))

# ---- 34. SRL ----
# srl x3, x1, x2 where x1=256, x2=4 -> x3=16
write_hex(f'{OUT}/srl.hex', alu_test(
    [ADDI(1, 0, 256),
     ADDI(2, 0, 4),
     SRL(3, 1, 2),       # x3 = 256 >> 4 = 16 (logical)
     ADDI(4, 0, 16)],    # expected = 16
    result_reg=3, expected_reg=4
))

# ---- 35. SRA ----
# sra x3, x1, x2 where x1=-8 (0xFFFFFFF8), x2=2 -> x3=-2 (0xFFFFFFFE)
write_hex(f'{OUT}/sra.hex', alu_test(
    [ADDI(1, 0, 0xFF8),  # x1 = -8 (sign-ext 0xFF8 = -8)
     ADDI(2, 0, 2),
     SRA(3, 1, 2),       # x3 = -8 >> 2 = -2 (arithmetic)
     ADDI(4, 0, 0xFFE)], # x4 = -2 (sign-ext 0xFFE = -2)
    result_reg=3, expected_reg=4
))

# ---- 36. OR ----
# or x3, x1, x2 where x1=0xA0, x2=0x0B -> x3=0xAB
write_hex(f'{OUT}/or.hex', alu_test(
    [ADDI(1, 0, 0xA0),   # x1 = 160
     ADDI(2, 0, 0x0B),   # x2 = 11
     OR(3, 1, 2),        # x3 = 0xA0 | 0x0B = 0xAB = 171
     ADDI(4, 0, 0xAB)],  # expected = 171
    result_reg=3, expected_reg=4
))

# ---- 37. AND ----
# and x3, x1, x2 where x1=0xFF, x2=0x0F -> x3=0x0F
write_hex(f'{OUT}/and.hex', alu_test(
    [ADDI(1, 0, 255),    # x1 = 0xFF
     ADDI(2, 0, 0x0F),   # x2 = 15
     AND_R(3, 1, 2),     # x3 = 0xFF & 0x0F = 0x0F = 15
     ADDI(4, 0, 15)],    # expected = 15
    result_reg=3, expected_reg=4
))

print("Generated all test hex files in:", OUT)
import glob
files = sorted(glob.glob(f'{OUT}/*.hex'))
print(f"Total files: {len(files)}")
for f in files:
    print(f"  {os.path.basename(f)}")
