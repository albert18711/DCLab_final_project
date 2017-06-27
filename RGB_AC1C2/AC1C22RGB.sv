module AC1C22RGB(
	input i_rst,
	input [31:0] i_A, // 16+16 B
	input [31:0] i_C1,
	input [31:0] i_C2,
	output [7:0] o_R, // 8 B
	output [7:0] o_G,
	output [7:0] o_B

);


//====== reg/wire ===========================
	logic signed [15:0] matrix11, matrix12, matrix13;
	logic signed [15:0] matrix21, matrix22, matrix23;
	logic signed [15:0] matrix31, matrix32, matrix33;
	
	//output reg
	logic signed [47:0] reg_R; // 20+28 B
	logic signed [47:0] reg_G;
	logic signed [47:0] reg_B;

	logic signed [47:0] temp_R, temp_G, temp_B;

//====== assign =============================
	//matrix 4+12 B

	assign matrix11 = 16'b0000010100111110;
	assign matrix12 = 16'b0011101100101101;
	assign matrix13 = 16'b0001000010110011;
	assign matrix21 = 16'b0000010101000000;
	assign matrix22 = 16'b1110000111101000;
	assign matrix23 = 16'b0000000010110110;
	assign matrix31 = 16'b0000010101000011;
	assign matrix32 = 16'b1111111111101110;
	assign matrix33 = 16'b1010100101111011;

	assign o_R = reg_R[35:28];
	assign o_G = reg_G[35:28];
	assign o_B = reg_B[35:28];
	
//====== combinational circuit ==============

always_comb begin
	if(i_rst) begin
		temp_R = 0;
		temp_G = 0;
		temp_B = 0;
	end else begin
		temp_R = $signed(matrix11)*$signed(i_A)+$signed(matrix12)*$signed(i_C1)+$signed(matrix13)*$signed(i_C2);
		temp_G = $signed(matrix21)*$signed(i_A)+$signed(matrix22)*$signed(i_C1)+$signed(matrix23)*$signed(i_C2);
		temp_B = $signed(matrix31)*$signed(i_A)+$signed(matrix32)*$signed(i_C1)+$signed(matrix33)*$signed(i_C2);
	end
end

always_comb begin
	if(i_rst) begin
		reg_R = 0;
	end else if(temp_R[47] == 1) begin
		reg_R = 0;
	end else begin
		reg_R = temp_R;
	end
end

always_comb begin
	if(i_rst) begin
		reg_G = 0;
	end else if(temp_G[47] == 1) begin
		reg_G = 0;
	end else begin
		reg_G = temp_G;
	end
end

always_comb begin
	if(i_rst) begin
		reg_B = 0;
	end else if(temp_B[47] == 1) begin
		reg_B = 0;
	end else begin
		reg_B = temp_B;
	end
end


//====== sequential circuit =================


endmodule
