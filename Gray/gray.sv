module gray (
	input 	[7:0] iR,
	input 	[7:0] iG,
	input 	[7:0] iB,

	output 	[7:0] oGray
);


// function I_gray = myRGB2gray(I)

// grayVector = [0.299 0.587 0.114];
// [H, W, ch] = size(I);
// I_gray = zeros(H, W);
// for x = 1:W
//     for y = 1:H
//         I_gray(y, x) = ceil(grayVector*reshape(256*I(y, x, :), 3, 1))/256;
//     end
// end

// end
// 01001100100010110100001110010110
// 10010110010001011010000111001011
// 00011101001011110001101010100000
// vector

	logic [31:0] vector_1, vector_2, vector_3;
	logic [39:0] temp_Gray;

	assign vector_1 = 32'b0100_1100_1000_1011_0100_0011_1001_0110;
	assign vector_2 = 32'b1001_0110_0100_0101_1010_0001_1100_1011;
	assign vector_3 = 32'b0001_1101_0010_1111_0001_1010_1010_0000;
	
	assign temp_Gray = iR * vector_1 + iG * vector_2 + iB * vector_3;
	assign oGray = temp_Gray[39 -: 8];

endmodule