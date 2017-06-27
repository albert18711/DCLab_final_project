module RGB2AC1C2(
	input i_rst,
	
	input [7:0] i_R, // 8 B
	input [7:0] i_G,
	input [7:0] i_B,
	
	output [31:0] o_A, // 16+16 B
	output [31:0] o_C1,
	output [31:0] o_C2
);


//====== reg/wire ===========================
	logic signed [15:0] matrix11, matrix12, matrix13;
	logic signed [15:0] matrix21, matrix22, matrix23;
	logic signed [15:0] matrix31, matrix32, matrix33;
	
	//output reg
	logic signed [24:0] reg_A; // 12+13 B
	logic signed [24:0] reg_C1;
	logic signed [24:0] reg_C2;

	//logic signed [24:0] temp_A, temp_C1, temp_C2;

//====== assign =============================
	//matrix 3+13 B

	assign matrix11 = 16'b0001111010111001;
	assign matrix12 = 16'b0011110001100110;
	assign matrix13 = 16'b0000011001101101;
	assign matrix21 = 16'b0000010101100111;
	assign matrix22 = 16'b1111100110011100;
	assign matrix23 = 16'b0000000011111110;
	assign matrix31 = 16'b0000000111011101;
	assign matrix32 = 16'b0000001110101110;
	assign matrix33 = 16'b1111101001111001;

	assign o_A = {4'b0, reg_A, 3'b0};
	assign o_C1 = {4'b0, reg_C1, 3'b0};
	assign o_C2 = {4'b0, reg_C2, 3'b0};
	
//====== combinational circuit ==============

always_comb begin
	if(i_rst) begin
		reg_A = 0;
		reg_C1 = 0;
		reg_C2 = 0;
	end else begin
		reg_A = $signed(matrix11)*$signed(i_R)+$signed(matrix12)*$signed(i_G)+$signed(matrix13)*$signed(i_B);
		reg_C1 = $signed(matrix21)*$signed(i_R)+$signed(matrix22)*$signed(i_G)+$signed(matrix23)*$signed(i_B);
		reg_C2 = $signed(matrix31)*$signed(i_R)+$signed(matrix32)*$signed(i_G)+$signed(matrix33)*$signed(i_B);
	end
end

/* //for condition when output is negative, then output 0
always_comb begin
	if(i_rst) begin
		temp_A = 0;
		temp_C1 = 0;
		temp_C2 = 0;
	end else begin
		temp_A = $signed(matrix11)*$signed(i_R)+$signed(matrix12)*$signed(i_G)+$signed(matrix13)*$signed(i_B);
		temp_C1 = $signed(matrix21)*$signed(i_R)+$signed(matrix22)*$signed(i_G)+$signed(matrix23)*$signed(i_B);
		temp_C2 = $signed(matrix31)*$signed(i_R)+$signed(matrix32)*$signed(i_G)+$signed(matrix33)*$signed(i_B);
	end
end

always_comb begin
	if(i_rst) begin
		reg_A = 0;
	end else if(temp_A[24] == 1) begin
		reg_A = 0;
	end else begin
		reg_A = temp_A
end

always_comb begin
	if(i_rst) begin
		reg_C1 = 0;
	end else if(temp_C1[24] == 1) begin
		reg_C1 = 0;
	end else begin
		reg_C1 = temp_C1;
	end
end

always_comb begin
	if(i_rst) begin
		reg_C2 = 0;
	end else if(temp_C2[24] == 1) begin
		reg_C2 = 0;
	end else begin
		reg_C2 = temp_C2;
	end
end*/


//====== sequential circuit =================


endmodule
