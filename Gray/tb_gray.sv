`timescale 1ns/100ps

module LFSRRandomSource_tb;
	localparam CLK = 10;
	localparam HCLK = CLK/2;
	localparam SIM_TIME = 100;

	logic clk;
	initial clk = 0;
	always #HCLK clk = ~clk;

	logic [7:0] gray_output;

	gray lab2gray (
			.iR(8'd10),
			.iG(8'd20),
			.iB(8'd30),
			.oGray(gray_output)
		);

	initial begin
		$fsdbDumpfile("LFSRRandomSource_tb.fsdb");
	   	$fsdbDumpvars;
	end

	initial begin
		#(SIM_TIME*CLK)
		$display("gray_output = %d", gray_output);
		$finish;
	end

	// initial begin

	// end

endmodule // LFSRRandomSource_tb