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
	logic [15:0] sram_data;

	enum {S_INPUT, S_OUTPUT} state_r, state_w;
	logic [15:0] data_to_sram;

	color_transform cTrans(
			.clk(clk),    // Clock
			.rst_n(rst_n),  // Asynchronous reset active low
			.start_transform(start),

			// Constant parameter/////
			.iCol_Max(400),
			.iRow_Max(300),

			// SRAM side ///////
			.oSRAM_OE_N(sram_oe_n),
			.oSRAM_WE_N(sram_we_n),
			.oSRAM_ADDR(sram_addr),
			.oSRAM_DATA(sram_data)
		);

	assign sram_data = (sram_we_n)? data_to_sram : 16'bz;
	assign data_to_sram = (sram_addr > 300*400*2)? 3 : {sram_addr[7:1], sram_addr[7:1]};

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

	initial begin
		#(SIM_TIME*CLK)
		$finish;
	end

	always_ff @(posedge clk) begin
		if(~sram_we_n) begin
			$display("color_transform of addr = %d, result = %d", sram_addr, sram_data);
		end
	end

endmodule