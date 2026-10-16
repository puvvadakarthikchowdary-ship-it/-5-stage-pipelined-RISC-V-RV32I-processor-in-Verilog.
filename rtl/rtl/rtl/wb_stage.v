// ============================================================
// Write Back Stage (Verilog-2001)
// ============================================================
module wb_stage (
  input  wire [31:0] alu_result,
  input  wire [31:0] read_data,
  input  wire        mem_to_reg,
  output wire [31:0] wb_data
);

  assign wb_data = mem_to_reg ? read_data : alu_result;

endmodule
