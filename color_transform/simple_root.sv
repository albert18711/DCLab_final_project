module simple_root (
	input CLK,
	input RST,
	input [15:0] DATA_IN,
	output [15:0] DATA_OUT
);
	logic [23:0] DATA_IN_shift;
	logic [23:0] tmp;

	assign DATA_IN_shift = {DATA_IN, 8'b0};
	assign tmp = (DATA_IN_shift) ** 0.5;
	assign DATA_OUT = tmp[15:0];
endmodule