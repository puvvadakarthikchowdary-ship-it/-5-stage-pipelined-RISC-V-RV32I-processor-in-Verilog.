// ============================================================
// RV32I 5-Stage Pipelined Core - Top Level (Verilog-2001)
// ============================================================
module rv32i_core (
  input  wire        clk,
  input  wire        rst_n,
  output wire [31:0] pc_out,
  output wire [31:0] instr_out,
  output wire [31:0] alu_result_out
);

  // IF stage outputs
  wire [31:0] pc, pc_plus4, instr;

  // IF/ID pipeline register
  reg [31:0] if_id_pc, if_id_instr;
  reg        if_id_valid;

  // ID stage outputs
  wire [31:0] id_rs1_data, id_rs2_data, id_imm;
  wire [4:0]  id_rs1_addr, id_rs2_addr, id_rd_addr;
  wire        id_reg_write, id_mem_read, id_mem_write, id_branch, id_jump;
  wire [2:0]  id_alu_op;
  wire [1:0]  id_alu_src;
  wire [2:0]  id_funct3;

  // ID/EX pipeline register
  reg [31:0] id_ex_pc, id_ex_rs1_data, id_ex_rs2_data, id_ex_imm;
  reg [4:0]  id_ex_rs1_addr, id_ex_rs2_addr, id_ex_rd_addr;
  reg        id_ex_reg_write, id_ex_mem_read, id_ex_mem_write;
  reg        id_ex_branch, id_ex_jump;
  reg [2:0]  id_ex_alu_op;
  reg [1:0]  id_ex_alu_src;
  reg [2:0]  id_ex_funct3;

  // EX stage outputs
  wire [31:0] ex_alu_result, ex_rs2_data;
  wire        ex_branch_taken;
  wire [31:0] ex_branch_target;

  // EX/MEM pipeline register
  reg [31:0] ex_mem_alu_result, ex_mem_rs2_data;
  reg [4:0]  ex_mem_rd_addr;
  reg        ex_mem_reg_write, ex_mem_mem_read, ex_mem_mem_write;
  reg        ex_mem_branch_taken;
  reg [31:0] ex_mem_branch_target;

  // MEM stage outputs
  wire [31:0] mem_read_data;

  // MEM/WB pipeline register
  reg [31:0] mem_wb_alu_result, mem_wb_read_data;
  reg [4:0]  mem_wb_rd_addr;
  reg        mem_wb_reg_write, mem_wb_mem_to_reg;

  // WB stage output
  wire [31:0] wb_data;

  // Forwarding
  wire [1:0] forward_a, forward_b;

  // Hazard
  wire load_use_stall;

  // ============================================================
  // IF Stage
  // ============================================================
  if_stage if_stage_inst (
    .clk           (clk),
    .rst_n         (rst_n),
    .stall         (load_use_stall),
    .flush         (ex_mem_branch_taken),
    .branch_target (ex_mem_branch_target),
    .pc_out        (pc),
    .pc_plus4_out  (pc_plus4),
    .instr_out     (instr)
  );

  // ============================================================
  // IF/ID Pipeline Register
  // ============================================================
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      if_id_pc    <= 32'b0;
      if_id_instr <= 32'b0;
      if_id_valid <= 1'b0;
    end else if (ex_mem_branch_taken) begin
      if_id_pc    <= 32'b0;
      if_id_instr <= 32'b0;
      if_id_valid <= 1'b0;
    end else if (!load_use_stall) begin
      if_id_pc    <= pc;
      if_id_instr <= instr;
      if_id_valid <= 1'b1;
    end
  end

  // ============================================================
  // ID Stage
  // ============================================================
  id_stage id_stage_inst (
    .clk          (clk),
    .rst_n        (rst_n),
    .instr        (if_id_instr),
    .pc           (if_id_pc),
    .wb_data      (wb_data),
    .wb_rd_addr   (mem_wb_rd_addr),
    .wb_reg_write (mem_wb_reg_write),
    .rs1_data     (id_rs1_data),
    .rs2_data     (id_rs2_data),
    .imm          (id_imm),
    .rs1_addr     (id_rs1_addr),
    .rs2_addr     (id_rs2_addr),
    .rd_addr      (id_rd_addr),
    .reg_write    (id_reg_write),
    .mem_read     (id_mem_read),
    .mem_write    (id_mem_write),
    .branch       (id_branch),
    .jump         (id_jump),
    .alu_op       (id_alu_op),
    .alu_src      (id_alu_src),
    .funct3       (id_funct3)
  );

  // ============================================================
  // ID/EX Pipeline Register
  // ============================================================
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      id_ex_pc         <= 32'b0;
      id_ex_rs1_data   <= 32'b0;
      id_ex_rs2_data   <= 32'b0;
      id_ex_imm        <= 32'b0;
      id_ex_rs1_addr   <= 5'b0;
      id_ex_rs2_addr   <= 5'b0;
      id_ex_rd_addr    <= 5'b0;
      id_ex_reg_write  <= 1'b0;
      id_ex_mem_read   <= 1'b0;
      id_ex_mem_write  <= 1'b0;
      id_ex_branch     <= 1'b0;
      id_ex_jump       <= 1'b0;
      id_ex_alu_op     <= 3'b0;
      id_ex_alu_src    <= 2'b0;
      id_ex_funct3     <= 3'b0;
    end else if (ex_mem_branch_taken || load_use_stall) begin
      id_ex_pc         <= 32'b0;
      id_ex_rs1_data   <= 32'b0;
      id_ex_rs2_data   <= 32'b0;
      id_ex_imm        <= 32'b0;
      id_ex_rs1_addr   <= 5'b0;
      id_ex_rs2_addr   <= 5'b0;
      id_ex_rd_addr    <= 5'b0;
      id_ex_reg_write  <= 1'b0;
      id_ex_mem_read   <= 1'b0;
      id_ex_mem_write  <= 1'b0;
      id_ex_branch     <= 1'b0;
      id_ex_jump       <= 1'b0;
      id_ex_alu_op     <= 3'b0;
      id_ex_alu_src    <= 2'b0;
      id_ex_funct3     <= 3'b0;
    end else begin
      id_ex_pc         <= if_id_pc;
      id_ex_rs1_data   <= id_rs1_data;
      id_ex_rs2_data   <= id_rs2_data;
      id_ex_imm        <= id_imm;
      id_ex_rs1_addr   <= id_rs1_addr;
      id_ex_rs2_addr   <= id_rs2_addr;
      id_ex_rd_addr    <= id_rd_addr;
      id_ex_reg_write  <= id_reg_write;
      id_ex_mem_read   <= id_mem_read;
      id_ex_mem_write  <= id_mem_write;
      id_ex_branch     <= id_branch;
      id_ex_jump       <= id_jump;
      id_ex_alu_op     <= id_alu_op;
      id_ex_alu_src    <= id_alu_src;
      id_ex_funct3     <= id_funct3;
    end
  end

  // ============================================================
  // EX Stage
  // ============================================================
  ex_stage ex_stage_inst (
    .rs1_data      (id_ex_rs1_data),
    .rs2_data      (id_ex_rs2_data),
    .imm           (id_ex_imm),
    .pc            (id_ex_pc),
    .rs1_addr      (id_ex_rs1_addr),
    .rs2_addr      (id_ex_rs2_addr),
    .alu_op        (id_ex_alu_op),
    .alu_src       (id_ex_alu_src),
    .branch        (id_ex_branch),
    .jump          (id_ex_jump),
    .funct3        (id_ex_funct3),
    .forward_a     (forward_a),
    .forward_b     (forward_b),
    .ex_mem_result (ex_mem_alu_result),
    .mem_wb_result (wb_data),
    .alu_result    (ex_alu_result),
    .rs2_data_out  (ex_rs2_data),
    .branch_taken  (ex_branch_taken),
    .branch_target (ex_branch_target)
  );

  // ============================================================
  // EX/MEM Pipeline Register
  // ============================================================
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ex_mem_alu_result    <= 32'b0;
      ex_mem_rs2_data      <= 32'b0;
      ex_mem_rd_addr       <= 5'b0;
      ex_mem_reg_write     <= 1'b0;
      ex_mem_mem_read      <= 1'b0;
      ex_mem_mem_write     <= 1'b0;
      ex_mem_branch_taken  <= 1'b0;
      ex_mem_branch_target <= 32'b0;
    end else begin
      ex_mem_alu_result    <= ex_alu_result;
      ex_mem_rs2_data      <= ex_rs2_data;
      ex_mem_rd_addr       <= id_ex_rd_addr;
      ex_mem_reg_write     <= id_ex_reg_write;
      ex_mem_mem_read      <= id_ex_mem_read;
      ex_mem_mem_write     <= id_ex_mem_write;
      ex_mem_branch_taken  <= ex_branch_taken;
      ex_mem_branch_target <= ex_branch_target;
    end
  end

  // ============================================================
  // MEM Stage
  // ============================================================
  mem_stage mem_stage_inst (
    .clk         (clk),
    .rst_n       (rst_n),
    .alu_result  (ex_mem_alu_result),
    .rs2_data    (ex_mem_rs2_data),
    .mem_read    (ex_mem_mem_read),
    .mem_write   (ex_mem_mem_write),
    .funct3      (id_ex_funct3),
    .read_data   (mem_read_data)
  );

  // ============================================================
  // MEM/WB Pipeline Register
  // ============================================================
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      mem_wb_alu_result <= 32'b0;
      mem_wb_read_data  <= 32'b0;
      mem_wb_rd_addr    <= 5'b0;
      mem_wb_reg_write  <= 1'b0;
      mem_wb_mem_to_reg <= 1'b0;
    end else begin
      mem_wb_alu_result <= ex_mem_alu_result;
      mem_wb_read_data  <= mem_read_data;
      mem_wb_rd_addr    <= ex_mem_rd_addr;
      mem_wb_reg_write  <= ex_mem_reg_write;
      mem_wb_mem_to_reg <= ex_mem_mem_read;
    end
  end

  // ============================================================
  // WB Stage
  // ============================================================
  wb_stage wb_stage_inst (
    .alu_result (mem_wb_alu_result),
    .read_data  (mem_wb_read_data),
    .mem_to_reg (mem_wb_mem_to_reg),
    .wb_data    (wb_data)
  );

  // ============================================================
  // Hazard Unit
  // ============================================================
  hazard_unit hazard_unit_inst (
    .id_ex_mem_read (id_ex_mem_read),
    .id_ex_rd_addr  (id_ex_rd_addr),
    .if_id_rs1_addr (id_rs1_addr),
    .if_id_rs2_addr (id_rs2_addr),
    .load_use_stall (load_use_stall)
  );

  // ============================================================
  // Forwarding Unit
  // ============================================================
  forwarding_unit forwarding_unit_inst (
    .id_ex_rs1_addr   (id_ex_rs1_addr),
    .id_ex_rs2_addr   (id_ex_rs2_addr),
    .ex_mem_rd_addr   (ex_mem_rd_addr),
    .ex_mem_reg_write (ex_mem_reg_write),
    .mem_wb_rd_addr   (mem_wb_rd_addr),
    .mem_wb_reg_write (mem_wb_reg_write),
    .forward_a        (forward_a),
    .forward_b        (forward_b)
  );

  assign pc_out         = pc;
  assign instr_out      = instr;
  assign alu_result_out = ex_alu_result;

endmodule
