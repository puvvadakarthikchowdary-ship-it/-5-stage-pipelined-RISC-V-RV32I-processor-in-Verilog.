// ============================================================
// Memory Stage (Verilog-2001)
// ============================================================
module mem_stage (
  input  wire        clk,
  input  wire        rst_n,
  input  wire [31:0] alu_result,
  input  wire [31:0] rs2_data,
  input  wire        mem_read,
  input  wire        mem_write,
  input  wire [2:0]  funct3,
  output wire [31:0] read_data
);

  reg [31:0] dmem [0:255];

  integer i;

  initial begin
    for (i = 0; i < 256; i = i + 1) dmem[i] = 32'b0;
  end

  // Write
  always @(posedge clk) begin
    if (mem_write) begin
      case (funct3)
        3'b000: dmem[alu_result[9:2]][7:0]  <= rs2_data[7:0];
        3'b001: dmem[alu_result[9:2]][15:0] <= rs2_data[15:0];
        3'b010: dmem[alu_result[9:2]]       <= rs2_data;
        default: ;
      endcase
    end
  end

  // Read
  reg [31:0] read_data_reg;
  always @(*) begin
    if (mem_read) begin
      case (funct3)
        3'b000: read_data_reg = {{24{dmem[alu_result[9:2]][7]}},  dmem[alu_result[9:2]][7:0]};
        3'b001: read_data_reg = {{16{dmem[alu_result[9:2]][15]}}, dmem[alu_result[9:2]][15:0]};
        3'b010: read_data_reg = dmem[alu_result[9:2]];
        3'b100: read_data_reg = {24'b0, dmem[alu_result[9:2]][7:0]};
        3'b101: read_data_reg = {16'b0, dmem[alu_result[9:2]][15:0]};
        default: read_data_reg = 32'b0;
      endcase
    end else begin
      read_data_reg = 32'b0;
    end
  end

  assign read_data = read_data_reg;

endmodule
