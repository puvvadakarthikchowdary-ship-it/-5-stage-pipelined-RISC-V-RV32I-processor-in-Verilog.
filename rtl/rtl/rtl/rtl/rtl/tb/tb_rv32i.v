// ============================================================
// Testbench for RV32I 5-Stage Pipelined Processor (Verilog-2001)
// ============================================================
`timescale 1ns/1ns

module tb_rv32i;

  reg         clk;
  reg         rst_n;
  wire [31:0] pc_out;
  wire [31:0] instr_out;
  wire [31:0] alu_result_out;

  rv32i_core dut (
    .clk            (clk),
    .rst_n          (rst_n),
    .pc_out         (pc_out),
    .instr_out      (instr_out),
    .alu_result_out (alu_result_out)
  );

  // Clock
  initial clk = 1'b0;
  always #5 clk = ~clk;

  // Reset
  initial begin
    rst_n = 1'b0;
    repeat (5) @(posedge clk);
    rst_n = 1'b1;
  end

  // Monitor
  initial begin
    $dumpfile("rv32i.vcd");
    $dumpvars(0, tb_rv32i);

    $display("========================================");
    $display("RV32I 5-Stage Pipelined Processor Test");
    $display("========================================");

    repeat (30) @(posedge clk);

    $display("PC = 0x%0h, Instr = 0x%0h, ALU = 0x%0h",
             pc_out, instr_out, alu_result_out);

    repeat (20) @(posedge clk);
    $display("Simulation complete.");
    $finish;
  end

endmodule
