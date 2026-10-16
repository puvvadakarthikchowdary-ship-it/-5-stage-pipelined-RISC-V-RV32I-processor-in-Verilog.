// ============================================================
// Instruction Decode Stage (Verilog-2001)
// ============================================================
module id_stage (
  input  wire        clk,
  input  wire        rst_n,
  input  wire [31:0] instr,
  input  wire [31:0] pc,
  input  wire [31:0] wb_data,
  input  wire [4:0]  wb_rd_addr,
  input  wire        wb_reg_write,
  output wire [31:0] rs1_data,
  output wire [31:0] rs2_data,
  output wire [31:0] imm,
  output wire [4:0]  rs1_addr,
  output wire [4:0]  rs2_addr,
  output wire [4:0]  rd_addr,
  output wire        reg_write,
  output wire        mem_read,
  output wire        mem_write,
  output wire        branch,
  output wire        jump,
  output wire [2:0]  alu_op,
  output wire [1:0]  alu_src,
  output wire [2:0]  funct3
);

  reg [31:0] regs [0:31];

  integer i;

  initial begin
    for (i = 0; i < 32; i = i + 1) regs[i] = 32'b0;
  end

  always @(posedge clk) begin
    if (wb_reg_write && wb_rd_addr != 5'b0)
      regs[wb_rd_addr] <= wb_data;
  end

  wire [6:0] opcode = instr[6:0];
  wire [4:0] rd     = instr[11:7];
  wire [2:0] f3     = instr[14:12];
  wire [4:0] rs1    = instr[19:15];
  wire [4:0] rs2    = instr[24:20];

  assign rs1_addr = rs1;
  assign rs2_addr = rs2;
  assign rd_addr  = rd;
  assign funct3   = f3;

  assign rs1_data = (rs1 != 5'b0) ? regs[rs1] : 32'b0;
  assign rs2_data = (rs2 != 5'b0) ? regs[rs2] : 32'b0;

  // Immediate generation
  reg [31:0] imm_reg;
  always @(*) begin
    case (opcode)
      7'b0010011, 7'b0000011:
        imm_reg = {{20{instr[31]}}, instr[31:20]};
      7'b0100011:
        imm_reg = {{20{instr[31]}}, instr[31:25], instr[11:7]};
      7'b1100011:
        imm_reg = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
      7'b0110111, 7'b0010111:
        imm_reg = {instr[31:12], 12'b0};
      7'b1101111:
        imm_reg = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
      default:
        imm_reg = 32'b0;
    endcase
  end
  assign imm = imm_reg;

  // Control signals
  reg reg_write_reg, mem_read_reg, mem_write_reg, branch_reg, jump_reg;
  reg [2:0] alu_op_reg;
  reg [1:0] alu_src_reg;

  always @(*) begin
    reg_write_reg = 1'b0;
    mem_read_reg  = 1'b0;
    mem_write_reg = 1'b0;
    branch_reg    = 1'b0;
    jump_reg      = 1'b0;
    alu_op_reg    = 3'b000;
    alu_src_reg   = 2'b00;

    case (opcode)
      7'b0110011: begin  // R-type
        reg_write_reg = 1'b1;
        alu_op_reg    = f3;
        alu_src_reg   = 2'b00;
      end
      7'b0010011: begin  // I-type
        reg_write_reg = 1'b1;
        alu_op_reg    = f3;
        alu_src_reg   = 2'b01;
      end
      7'b0000011: begin  // Load
        reg_write_reg = 1'b1;
        mem_read_reg  = 1'b1;
        alu_op_reg    = 3'b000;
        alu_src_reg   = 2'b01;
      end
      7'b0100011: begin  // Store
        mem_write_reg = 1'b1;
        alu_op_reg    = 3'b000;
        alu_src_reg   = 2'b01;
      end
      7'b1100011: begin  // Branch
        branch_reg    = 1'b1;
        alu_op_reg    = f3;
        alu_src_reg   = 2'b00;
      end
      7'b1101111: begin  // JAL
        reg_write_reg = 1'b1;
        jump_reg      = 1'b1;
        alu_src_reg   = 2'b10;
      end
      7'b1100111: begin  // JALR
        reg_write_reg = 1'b1;
        jump_reg      = 1'b1;
        alu_op_reg    = 3'b000;
        alu_src_reg   = 2'b01;
      end
      default: ;
    endcase
  end

  assign reg_write = reg_write_reg;
  assign mem_read  = mem_read_reg;
  assign mem_write = mem_write_reg;
  assign branch    = branch_reg;
  assign jump      = jump_reg;
  assign alu_op    = alu_op_reg;
  assign alu_src   = alu_src_reg;

endmodule
