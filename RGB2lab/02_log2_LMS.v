module log2(
i_rst,
i_index,
o_log2_index
);

input i_rst;
input [15:0] i_index; // 8+8 B
output [15:0] o_log2_index; // 3+13 B

reg [2:0] int; //整數部分 3bits
reg [12:0] fraction; //小數部分 13bits

assign o_log2_index = {int, fraction};

always @(*) begin
	if(i_rst) int = 0;
	else if(i_index > 1 && i_index < 4) int = 1;
	else if(i_index > 3 && i_index < 8) int = 2;
	else if(i_index > 7 && i_index < 16) int = 3;
	else if(i_index > 15 && i_index < 32) int = 4;
	else if(i_index > 31 && i_index < 64) int = 5;
	else if(i_index > 63 && i_index < 128) int = 6;
	else if(i_index > 127 && i_index < 256) int = 7;
	else int = 0;
end


always @(*) begin
	if(i_rst) begin
		fraction = 0;
	end	else begin
		case(i_index)
		129: fraction = 0000001011100;
		130, 65: fraction = 0000010110111;
		131: fraction = 0000100010010;
		132, 66, 33: fraction = 0000101101100;
		133: fraction = 0000111000101;
		134, 67: fraction = 0001000011101;
		135: fraction = 0001001110101;
		136, 68, 34, 17: fraction = 0001011001100;
		137: fraction = 0001100100011;
		138, 69: fraction = 0001101111001;
		139: fraction = 0001111001110;
		140, 70, 35: fraction = 0010000100011;
		141: fraction = 0010001110111;
		142, 71: fraction = 0010011001011;
		143: fraction = 0010100011110;
		144, 72, 36, 18, 9: fraction = 0010101110000;
		145: fraction = 0010111000010;
		146, 73: fraction = 0011000010011;
		147: fraction = 0011001100100;
		148, 74, 37: fraction = 0011010110100;
		149: fraction = 0011100000011;
		150, 75: fraction = 0011101010010;
		151: fraction = 0011110100001;
		152, 76, 38, 19: fraction = 0011111101111;
		153: fraction = 0100000111101;
		154, 77: fraction = 0100010001010;
		155: fraction = 0100011010110;
		156, 78, 39: fraction = 0100100100010;
		157: fraction = 0100101101110;
		158, 79: fraction = 0100110111001;
		159: fraction = 0101000000011;
		160, 80, 40, 20, 10, 5: fraction = 0101001001101;
		161: fraction = 0101010010111;
		162, 81: fraction = 0101011100000;
		163: fraction = 0101100101001;
		164, 82, 41: fraction = 0101101110001;
		165: fraction = 0101110111001;
		166, 83: fraction = 0110000000000;
		167: fraction = 0110001000111;
		168, 84, 42, 21: fraction = 0110010001110;
		169: fraction = 0110011010100;
		170, 85: fraction = 0110100011010;
		171: fraction = 0110101011111;
		172, 86, 43: fraction = 0110110100100;
		173: fraction = 0110111101000;
		174, 87: fraction = 0111000101101;
		175: fraction = 0111001110000;
		176, 88, 44, 22, 11: fraction = 0111010110100;
		177: fraction = 0111011110111;
		178, 89: fraction = 0111100111001;
		179: fraction = 0111101111011;
		180, 90, 45: fraction = 0111110111101;
		181: fraction = 0111111111111;
		182, 91: fraction = 1000001000000;
		183: fraction = 1000010000001;
		184, 92, 46, 23: fraction = 1000011000001;
		185: fraction = 1000100000001;
		186, 93: fraction = 1000101000001;
		187: fraction = 1000110000000;
		188, 94, 47: fraction = 1000110111111;
		189: fraction = 1000111111110;
		190, 95: fraction = 1001000111100;
		191: fraction = 1001001111010;
		192, 96, 48, 24, 12, 6, 3: fraction = 1001010111000;
		193: fraction = 1001011110101;
		194, 97: fraction = 1001100110010;
		195: fraction = 1001101101111;
		196, 98, 49: fraction = 1001110101100;
		197: fraction = 1001111101000;
		198, 99: fraction = 1010000100100;
		199: fraction = 1010001011111;
		200, 100, 50, 25: fraction = 1010010011010;
		201: fraction = 1010011010101;
		202, 101: fraction = 1010100010000;
		203: fraction = 1010101001010;
		204, 102, 51: fraction = 1010110000101;
		205: fraction = 1010110111110;
		206, 103: fraction = 1010111111000;
		207: fraction = 1011000110001;
		208, 104, 52, 26, 13: fraction = 1011001101010;
		209: fraction = 1011010100011;
		210, 105: fraction = 1011011011011;
		211: fraction = 1011100010011;
		212, 106, 53: fraction = 1011101001011;
		213: fraction = 1011110000011;
		214, 107: fraction = 1011110111010;
		215: fraction = 1011111110001;
		216, 108, 54, 27: fraction = 1100000101000;
		217: fraction = 1100001011111;
		218, 109: fraction = 1100010010101;
		219: fraction = 1100011001011;
		220, 110, 55: fraction = 1100100000001;
		221: fraction = 1100100110110;
		222, 111: fraction = 1100101101100;
		223: fraction = 1100110100001;
		224, 112, 56, 28, 14, 7: fraction = 1100111010110;
		225: fraction = 1101000001010;
		226, 113: fraction = 1101000111111;
		227: fraction = 1101001110011;
		228, 114, 57: fraction = 1101010100111;
		229: fraction = 1101011011011;
		230, 115: fraction = 1101100001110;
		231: fraction = 1101101000010;
		232, 116, 58, 29: fraction = 1101101110101;
		233: fraction = 1101110100111;
		234, 117: fraction = 1101111011010;
		235: fraction = 1110000001100;
		236, 118, 59: fraction = 1110000111111;
		237: fraction = 1110001110001;
		238, 119: fraction = 1110010100010;
		239: fraction = 1110011010100;
		240, 120, 60, 30, 15: fraction = 1110100000101;
		241: fraction = 1110100110110;
		242, 121: fraction = 1110101100111;
		243: fraction = 1110110011000;
		244, 122, 61: fraction = 1110111001001;
		245: fraction = 1110111111001;
		246, 123: fraction = 1111000101001;
		247: fraction = 1111001011001;
		248, 124, 62, 31: fraction = 1111010001001;
		249: fraction = 1111010111000;
		250, 125: fraction = 1111011101000;
		251: fraction = 1111100010111;
		252, 126, 63: fraction = 1111101000110;
		253: fraction = 1111101110101;
		254, 127: fraction = 1111110100011;
		255: fraction = 1111111010010;
		default: fraction = 13'b0;
		endcase
	end
end

endmodule
