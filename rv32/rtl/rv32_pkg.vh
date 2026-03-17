`ifndef RV32_PKG_VH
`define RV32_PKG_VH

// RISC-V RV32I opcodes
localparam logic [6:0] OPC_LUI    = 7'b0110111;
localparam logic [6:0] OPC_AUIPC  = 7'b0010111;
localparam logic [6:0] OPC_JAL    = 7'b1101111;
localparam logic [6:0] OPC_JALR   = 7'b1100111;
localparam logic [6:0] OPC_BRANCH = 7'b1100011;
localparam logic [6:0] OPC_LOAD   = 7'b0000011;
localparam logic [6:0] OPC_STORE  = 7'b0100011;
localparam logic [6:0] OPC_OPIMM  = 7'b0010011;
localparam logic [6:0] OPC_OP     = 7'b0110011;
localparam logic [6:0] OPC_MISC   = 7'b0001111; // FENCE
localparam logic [6:0] OPC_SYSTEM = 7'b1110011; // ECALL/EBREAK/CSR (not implemented in minimal)

`endif