`timescale 1ns/100ps
module tb_channel_SRAM;

	// Timing:
	localparam CLK = 10;
	localparam HCLK = CLK/2;
	localparam SIM_TIME = 6000;

	logic clk;
	initial clk = 0;
	always #HCLK clk = ~clk;

	logic [1:0] store_g;
	logic store_state;

	logic rst_n;
	logic start;
	logic [19:0] SRAM_ADDR;
	wire [15:0] SRAM_DQ;
	logic SRAM_WE_N;
	logic SRAM_OE_N;

	SRAM_init SRAM_sim (
 		.clk(clk), 						// Clock Input
 		.address(SRAM_ADDR), 			// Address Input
 		.data(SRAM_DQ), 				// Data bi-directional
 		.cs(1), 						// Chip Select
 		.we(SRAM_WE_N), 					// Write Enable/Read Enable
 		.oe(SRAM_OE_N),         			// Output Enable
 		.i_rst(~rst_n)
 	); 

	color_transform chTrans (
			.clk(clk),    // Clock
			.rst_n(rst_n),  // Asynchronous reset active low
			.start_transform(start),

			// Constant parameter/////
			.iCol_Max(5),
			.iRow_Max(5),

			// SRAM side ///////
			.oSRAM_OE_N(SRAM_OE_N),
			.oSRAM_WE_N(SRAM_WE_N),
			.oSRAM_ADDR(SRAM_ADDR),
			.oSRAM_DATA(SRAM_DQ),
			.gray_s_mean(),
			.gray_s_std(),
			.gray_t_mean(),
			.gray_t_std(),

			// debug
			.oStore_g(store_g)
			// output state,
			// output now_photo
		);

	initial begin
		$fsdbDumpfile("colorTransform_tb.fsdb");
	   	$fsdbDumpvars;
		rst_n = 0;
		#(2*CLK)
		rst_n = 1;
		start = 1;
	end

	// initial begin
	// 	#(SIM_TIME*CLK)
	// 	$finish;
	// end

	always_ff @(posedge clk or negedge rst_n) begin
		if(~SRAM_WE_N) begin
			$display("color_transform of addr = %d, result = %h", SRAM_ADDR, SRAM_DQ);
		end
		if(SRAM_ADDR > 5*5 * 2 * 3 + 4) begin
			$finish;
		end
		if(~rst_n) begin
			store_state <= 0;
		end else begin
			if(~store_state) begin
				if(store_g > 0) store_state <= 1;
			end else begin
				if(store_g == 0) $finish;
			end			
		end
	end

endmodule