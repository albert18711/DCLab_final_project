`include "01_RGB2LMS.v"
`include "02_log2_LMS.v"
`include "03_LMS2lab.v"

module RGB2lab(
	i_rst,
	i_R,
	i_G,
	i_B,
	o_l,
	o_a,
	o_b
);

//====== I/O port ===========================

	input i_rst;
	input [7:0] i_R; // 8 B
	input [7:0] i_G;
	input [7:0] i_B;
	output [15:0] o_l; // 3+13 B
	output [15:0] o_a;
	output [15:0] o_b;

//====== reg/wire ===========================

wire [15:0] wire_L, wire_M, wire_S; // 8+8 B 
wire [15:0] log2_L, log2_M, log2_S; // 3+13 B

//====== submodule ==========================

RGB2LMS step1(
	.i_rst(i_rst),
	.i_R(i_R),
	.i_G(i_G),
	.i_B(i_B),
	.o_L(wire_L),
	.o_M(wire_M),
	.o_S(wire_S)
);

log2 step2_log2L(
	.i_rst(i_rst),
	.i_index(wire_L),
	.o_log2_index(log2_L)
);

log2 step2_log2M(
	.i_rst(i_rst),
	.i_index(wire_M),
	.o_log2_index(log2_M)
);

log2 step2_log2S(
	.i_rst(i_rst),
	.i_index(wire_S),
	.o_log2_index(log2_S)
);

LMS2lab step3(
	.i_rst(i_rst),
	.i_logL(log2_L),
	.i_logM(log2_M),
	.i_logS(log2_S),
	.o_l(o_l),
	.o_a(o_a),
	.o_b(o_b)
);

endmodule // RGB2lab
