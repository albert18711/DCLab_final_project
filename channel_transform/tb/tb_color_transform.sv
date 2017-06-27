`timescale 1ns/100ps
module tb_color_transform;

	localparam CLK = 10;
	localparam HCLK = CLK/2;
	localparam SIM_TIME = 10000;

	logic clk;
	initial clk = 0;
	always #HCLK clk = ~clk;

	logic rst_n;
	logic start;
	logic sram_oe_n;
	logic sram_we_n;
	logic [19:0] sram_addr;
	wire  [15:0] sram_data;
	logic [1:0] store_g;

	logic store_state;

	enum {S_INPUT, S_OUTPUT} state_r, state_w;
	logic [15:0] data_to_sram;

	color_transform cTrans(
			.clk(clk),    // Clock
			.rst_n(rst_n),  // Asynchronous reset active low
			.start_transform(start),

			// Constant parameter/////
			.iCol_Max(10'd40),
			.iRow_Max(10'd30),

			// SRAM side ///////
			.oSRAM_OE_N(sram_oe_n),
			.oSRAM_WE_N(sram_we_n),
			.oSRAM_ADDR(sram_addr),
			.oSRAM_DATA(sram_data),
			.oStore_g(store_g)
		);

	assign sram_data = (sram_we_n)? data_to_sram : 16'bz;
	assign data_to_sram = (sram_addr > 30*40*2)? {8'd64, 8'd64} : {8'd64, 8'd64};

	// always_comb begin
	// 	state_w = state_r;
	// 	case (state_r)
	// 		S_INPUT: begin
	// 			if(~sram_oe_n) begin
	// 				state_w = S_OUTPUT;
	// 			end
	// 		end
	// 		S_OUTPUT: begin
	// 		end
	// 		default : /* default */;
	// 	endcase
	
	// end

	// initial begin
	// 	#(SIM_TIME*CLK)
	// 	$finish;
	// end

	initial begin
		$fsdbDumpfile("colorTransform_tb.fsdb");
	   	$fsdbDumpvars;

		rst_n = 0;
		start = 0;
		#(2*CLK)
		rst_n = 1;
		start = 1;
		#(CLK)
		start = 0;
	end

	always_ff @(posedge clk or negedge rst_n) begin
		if(~sram_we_n) begin
			$display("color_transform of addr = %d, result = %h", sram_addr, sram_data);
		end
		if(sram_addr > 30 * 40 * 2 * 3 + 4) begin
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