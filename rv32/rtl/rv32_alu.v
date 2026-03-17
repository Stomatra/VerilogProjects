module rv32_alu (
  input  logic [3:0]  alu_op,
  input  logic [31:0] a,
  input  logic [31:0] b,
  output logic [31:0] y
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

  always_comb begin
    unique case (alu_op)
      ALU_ADD:  y = a + b;
      ALU_SUB:  y = a - b;
      ALU_AND:  y = a & b;
      ALU_OR:   y = a | b;
      ALU_XOR:  y = a ^ b;
      ALU_SLT:  y = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
      ALU_SLTU: y = (a < b) ? 32'd1 : 32'd0;
      ALU_SLL:  y = a << b[4:0];
      ALU_SRL:  y = a >> b[4:0];
      ALU_SRA:  y = $signed(a) >>> b[4:0];
      default:  y = 32'h0;
    endcase
  end
endmodule