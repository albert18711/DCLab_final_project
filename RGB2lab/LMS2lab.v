module LMS2lab(
	i_rst,
	i_logL,
	i_logM,
	i_logS,
	o_l,
	o_a,
	o_b
);

//====== I/O port ===========================

	input i_rst;
	
	input [15:0] i_logL; // 3+13 B
	input [15:0] i_logM;
	input [15:0] i_logS;
	
	output [15:0] o_l; // 3+13 B
	output [15:0] o_a;
	output [15:0] o_b;

//====== submodule ==========================

	
	
//====== reg/wire ===========================
	wire [15:0] matrix11, matrix12, matrix13;
	wire [15:0] matrix21, matrix22, matrix23;
	wire [15:0] matrix31, matrix32, matrix33;
	
	//output reg
	reg signed [31:0] reg_l; // 6+26 B
	reg signed [31:0] reg_a;
	reg signed [31:0] reg_b;

//====== assign =============================
	//matrix2 3+13 B

	assign matrix11 = 16'b0001001001111010;
	assign matrix12 = 16'b0001001001111010;
	assign matrix13 = 16'b0001001001111010;
	assign matrix21 = 16'b0000110100010000;
	assign matrix22 = 16'b0000110100010000;
	assign matrix23 = 16'b1110010111011111;
	assign matrix31 = 16'b0001011010100001;
	assign matrix32 = 16'b1110100101011111;
	assign matrix33 = 16'b0000000000000000;
	
	assign o_l = reg_l[28:13]; // 3+13B
	assign o_a = reg_a[28:13];
	assign o_b = reg_b[28:13];
	
//====== combinational circuit ==============
always@(*) begin
	if(!i_rst) begin
		reg_l = 0;
		reg_a = 0;
		reg_b = 0;
	end else begin
		reg_l = $signed(matrix11)*$signed(i_logL) + $signed(matrix12)*$signed(i_logM) + $signed(matrix13)*$signed(i_logS);
		reg_a = $signed(matrix21)*$signed(i_logL) + $signed(matrix22)*$signed(i_logM) + $signed(matrix23)*$signed(i_logS);
		reg_b = $signed(matrix31)*$signed(i_logL) + $signed(matrix32)*$signed(i_logM) + $signed(matrix33)*$signed(i_logS);
	end
end

//====== sequential circuit =================


endmodule
