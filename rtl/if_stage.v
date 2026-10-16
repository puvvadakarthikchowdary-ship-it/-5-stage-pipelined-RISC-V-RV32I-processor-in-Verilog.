// ============================================================
// Instruction Fetch Stage (Verilog-2001)
// ============================================================
module if_stage (
  input  wire        clk,
  input  wire        rst_n,
  input  wire        stall,
  input  wire        flush,
  input  wire [31:0] branch_target,
  output wire [31:0] pc_out,
  output wire [31:0] pc_plus4_out,
  output wire [31:0] instr_out
);

  reg  [31:0] pc;
  wire [31:0] pc_next;
  reg  [31:0] imem [0:255];

  integer i;

  initial begin
    imem[0]  = 32'h00500093;  // addi x1, x0, 5
    imem[1]  = 32'h00A00113;  // addi x2, x0, 10
    imem[2]  = 32'h002081B3;  // add x3, x1, x2
    imem[3]  = 32'h40310233;  // sub x4, x2, x1
    imem[4]  = 32'h0020F2B3;  // and x5, x1, x2
    imem[5]  = 32'h0020E333;  // or x6, x1, x2
    imem[6]  = 32'h0020C3B3;  // xor x7, x1, x2
    imem[7]  = 32'h00000013;  // nop
    imem[8]  = 32'h00000013;
    imem[9]  = 32'h00000013;
    imem[10] = 32'h00000013;
    for (i = 11; i < 256; i = i + 1)
      imem[i] = 32'h00000013;
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) pc <= 32'b0;
    else if (flush) pc <= branch_target;
    else if (!stall) pc <= pc_next;
  end

  assign pc_next      = pc + 32'd4;
  assign pc_out       = pc;
  assign pc_plus4_out = pc + 32'd4;
  assign instr_out    = imem[pc[9:2]];

endmodule
