// ============================================================
// Execute Stage (Verilog-2001)
// ============================================================
module ex_stage (
  input  wire [31:0] rs1_data,
  input  wire [31:0] rs2_data,
  input  wire [31:0] imm,
  input  wire [31:0] pc,
  input  wire [4:0]  rs1_addr,
  input  wire [4:0]  rs2_addr,
  input  wire [2:0]  alu_op,
  input  wire [1:0]  alu_src,
  input  wire        branch,
  input  wire        jump,
  input  wire [2:0]  funct3,
  input  wire [1:0]  forward_a,
  input  wire [1:0]  forward_b,
  input  wire [31:0] ex_mem_result,
  input  wire [31:0] mem_wb_result,
  output wire [31:0] alu_result,
  output wire [31:0] rs2_data_out,
  output wire        branch_taken,
  output wire [31:0] branch_target
);

  reg [31:0] alu_a, alu_b;
  reg [31:0] alu_out;
  reg [31:0] alu_in_b;
  reg        branch_cond;

  // Forwarding muxes
  always @(*) begin
    case (forward_a)
      2'b00: alu_a = rs1_data;
      2'b01: alu_a = mem_wb_result;
      2'b10: alu_a = ex_mem_result;
      default: alu_a = rs1_data;
    endcase
  end

  always @(*) begin
    case (forward_b)
      2'b00: alu_b = rs2_data;
      2'b01: alu_b = mem_wb_result;
      2'b10: alu_b = ex_mem_result;
      default: alu_b = rs2_data;
    endcase
  end

  assign rs2_data_out = alu_b;

  // ALU source mux
  always @(*) begin
    case (alu_src)
      2'b00: alu_in_b = alu_b;
      2'b01: alu_in_b = imm;
      2'b10: alu_in_b = 32'd4;
      default: alu_in_b = alu_b;
    endcase
  end

  // ALU
  always @(*) begin
    case (alu_op)
      3'b000: alu_out = alu_a + alu_in_b;
      3'b001: alu_out = alu_a << alu_in_b[4:0];
      3'b010: alu_out = ($signed(alu_a) < $signed(alu_in_b)) ? 32'd1 : 32'd0;
      3'b011: alu_out = (alu_a < alu_in_b) ? 32'd1 : 32'd0;
      3'b100: alu_out = alu_a ^ alu_in_b;
      3'b101: alu_out = alu_a >> alu_in_b[4:0];
      3'b110: alu_out = alu_a | alu_in_b;
      3'b111: alu_out = alu_a & alu_in_b;
      default: alu_out = 32'b0;
    endcase
  end

  assign alu_result = alu_out;

  // Branch logic
  always @(*) begin
    case (funct3)
      3'b000: branch_cond = (alu_a == alu_b);
      3'b001: branch_cond = (alu_a != alu_b);
      3'b100: branch_cond = ($signed(alu_a) < $signed(alu_b));
      3'b101: branch_cond = ($signed(alu_a) >= $signed(alu_b));
      3'b110: branch_cond = (alu_a < alu_b);
      3'b111: branch_cond = (alu_a >= alu_b);
      default: branch_cond = 1'b0;
    endcase
  end

  assign branch_taken  = (branch && branch_cond) || jump;
  assign branch_target = (jump && alu_src == 2'b10) ? (pc + imm) :
                         (jump)                    ? (alu_a + imm) :
                                                     (pc + imm);

endmodule
