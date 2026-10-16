// ============================================================
// Hazard Detection Unit (Verilog-2001)
// ============================================================
module hazard_unit (
  input  wire        id_ex_mem_read,
  input  wire [4:0]  id_ex_rd_addr,
  input  wire [4:0]  if_id_rs1_addr,
  input  wire [4:0]  if_id_rs2_addr,
  output wire        load_use_stall
);

  assign load_use_stall = id_ex_mem_read &&
                          (id_ex_rd_addr != 5'b0) &&
                          ((id_ex_rd_addr == if_id_rs1_addr) ||
                           (id_ex_rd_addr == if_id_rs2_addr));

endmodule
