module RGB2LMS(
	i_rst,
	i_R,
	i_G,
	i_B,
	o_L,
	o_M,
	o_S
);

//====== I/O port ===========================

	input i_rst;
	
	input [7:0] i_R; // 8 B
	input [7:0] i_G;
	input [7:0] i_B;
	
	output [15:0] o_L; // 8+8 B
	output [15:0] o_M;
	output [15:0] o_S;

//====== submodule ==========================

	
	
//====== reg/wire ===========================
	wire [15:0] matrix11, matrix12, matrix13;
	wire [15:0] matrix21, matrix22, matrix23;
	wire [15:0] matrix31, matrix32, matrix33;
	
	//output reg
	reg [23:0] reg_L; //24B = 11B + 13B
	reg [23:0] reg_M;
	reg [23:0] reg_S;

//====== assign =============================
	//matrix1 3+13 B

	assign matrix11 = 16'b0000110000110010;
	assign matrix12 = 16'b0001001010000001;
	assign matrix13 = 16'b0000000101001001;
	assign matrix21 = 16'b0000011001001011;
	assign matrix22 = 16'b0001011100101110;
	assign matrix23 = 16'b0000001010000001;
	assign matrix31 = 16'b0000000011000101;
	assign matrix32 = 16'b0000010000011111;
	assign matrix33 = 16'b0001101100000101;
	
	assign o_L = reg_L[21:6]; //取 8B + 8B
	assign o_M = reg_M[21:6];
	assign o_S = reg_S[21:6];
	
//====== combinational circuit ==============
always@(*) begin
	if(i_rst) begin
		reg_L = 0;
		reg_M = 0;
		reg_S = 0;
	end else begin
		reg_L = matrix11*i_R + matrix12*i_G + matrix13*i_B;
		reg_M = matrix21*i_R + matrix22*i_G + matrix23*i_B;
		reg_S = matrix31*i_R + matrix32*i_G + matrix33*i_B;
	end
end

//====== sequential circuit =================


endmodule
