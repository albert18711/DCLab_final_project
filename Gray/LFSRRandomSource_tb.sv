`timescale 1ns/100ps

module LFSRRandomSource_tb;
	localparam CLK = 10;
	localparam HCLK = CLK/2;
	localparam SIM_TIME = 100;

	logic clk;
	initial clk = 0;
	always #HCLK clk = ~clk;

	logic next, rst;
	logic [15:0] ans;

	LFSRRandomSource rand_Source(
		.i_next(next),
		.i_clk(clk),
		.i_rst(rst),
		.o_rand(ans)
	);

	initial begin
		$fsdbDumpfile("LFSRRandomSource_tb.fsdb");
	   	$fsdbDumpvars;

		rst = 1;
		next = 0;
		#(2*CLK)
		rst = 0;
		next = 1;
	end

	initial begin
		#(SIM_TIME*CLK)
		$finish;
	end

	always_ff @ (posedge clk) begin
		$display("Random value = %d, bin = %b", ans, ans);
	end

endmodule
