`timescale 1ns/100ps

module TextureTransfer_tb;

	// 1. print SRAM data
	// 2. texture transfer
	// 3. print result

// Timing:
	localparam CLK = 10;
	localparam HCLK = CLK/2;
	localparam SIM_TIME = 6000;

	logic clk;
	initial clk = 0;
	always #HCLK clk = ~clk;


// Texture Transfer:
	logic rst;

	// Top control:
	typedef enum {
		S_IDLE,
		S_PRINT_SRAM_DATA,
		S_WAIT,
		S_TEXTURE_TRANSFER,
		S_FINISH_TEXTURE_TRANSFER,
		S_PRINT_RESULT,
		S_FINISH
   	} State;

   	State state_r, state_w;
   	logic [31:0] global_counter_r, global_counter_w;
   	logic [19:0] addr_r, addr_w;	// for printing result

   	logic [8:0] H_max, W_max;
   	logic [8:0] x_r, x_w, y_r, y_w;
   	logic [8:0] index_r, index_w;	// 0: TRG, 1: SRC, 2: Atlas, 3: RES
   	logic access_B_r, access_B_w;
   	logic print_sram_r, print_sram_w;

   	logic [7:0] R_r, R_w, G_r, G_w, B_r, B_w, Gray_r, Gray_w;
   	logic [4:0] state_debug_r, state_debug_w;


	// SRAM:
	wire [15:0] SRAM_DQ;
	logic [10:0] SRAM_ADDR;
	logic SRAM_OE, SRAM_WE;

	// TextureTransfer_Module:
	logic start_r, start_w;
	logic finish_r, finish_w;
	logic finish_row_r, finish_row_w;
	logic finish_pixel_r, finish_pixel_w;
	logic finish_random_init_r, finish_random_init_w;
	logic [4:0] state_debug;

	wire [15:0] SRAM_DQ_text;
	logic [19:0] SRAM_ADDR_text;
	logic SRAM_OE_text, SRAM_WE_text;


	// assign:
	assign H_max = 9'd5;
	assign W_max = 9'd5;

	assign SRAM_WE = (state_r == S_TEXTURE_TRANSFER)? SRAM_WE_text : 1;
	assign SRAM_OE = (state_r == S_TEXTURE_TRANSFER)? SRAM_OE_text : 0;		// read only
	//assign SRAM_DQ = (state_r == S_TEXTURE_TRANSFER)? SRAM_DQ_text : 16'bz;	
								// read only if not in texture transfer
	assign SRAM_ADDR = (state_r == S_TEXTURE_TRANSFER)? SRAM_ADDR_text[10:0] : addr_r[10:0];

	//assign SRAM_DQ_text = (state_r == S_TEXTURE_TRANSFER)? SRAM_DQ : 16'bz; 

	assign addr_w = (H_max*W_max*index_w + W_max*y_w + x_w)*2 + (access_B_w);
	assign state_debug_w = state_debug;


	TextureTransfer textureTransfer_Module(

		.i_clk(clk),
		.i_start(start_r),
		.i_rst(rst),
		
		.i_SRC_h(H_max),	// 0~511: exactly use 300 -> use 5 for testbench
		.i_SRC_w(W_max), 	//                    400 -> use 5 for testbench
		.i_TRG_h(H_max),
		.i_TRG_w(W_max),
		
		.i_SRC_index(3'd1),		// specify the beginning address of Source in SRAM
		.i_TRG_index(3'd0),
		.i_Atlas_index(3'd2),	// Atlas: the mapping of result pos(R_pos) to source pos(S_pos)
										// the result pixel at R_pos is from that in source at S_pos
		
		.i_wL(32'd32),			// weight when calculating distance

		.i_SRC_Mean({16'b0, 16'b1001111010100100}),
		.i_SRC_Std( {16'b0, 16'b0010111111011000}),
		.i_TRG_Mean({16'b0, 16'b1100110111001101}),
		.i_TRG_Std( {16'b0, 16'b0000011001000010}),

		.SRAM_DQ(SRAM_DQ),						// SRAM data: read and write
		.o_SRAM_ADDR(SRAM_ADDR_text),			// SRAM address
		.o_SRAM_OE(SRAM_OE_text),					// 0 -> read in from SRAM; 1 -> not read;
		.o_SRAM_WE(SRAM_WE_text),					// SRAM enable, 0 -> write
		
		.o_finish(finish_w),									// Finish all
		.o_finish_row(finish_row_w),							// Finish each row
		.o_finish_pixel(finish_pixel_w),						// Finish one RES pixel 
		.o_finish_random_init(finish_random_init_w),			// Finish Atlas random initialization
		.o_state(state_debug),

		.o_global_counter(global_counter_w)			// Check computation time
	);

	SRAM_init SRAM_sim
 	(
 		.clk(clk), 						// Clock Input
 		.address(SRAM_ADDR), 			// Address Input
 		.data(SRAM_DQ), 				// Data bi-directional
 		.cs(1), 						// Chip Select
 		.we(SRAM_WE), 					// Write Enable/Read Enable
 		.oe(SRAM_OE),         			// Output Enable
 		.i_rst(rst)
 	); 

	initial begin
		$fsdbDumpfile("TextureTransfer_tb.fsdb");
	   	$fsdbDumpvars;
		rst = 1;
		#(2*CLK)
		rst = 0;
	end

	initial begin
		#(SIM_TIME*CLK)
		$finish;
	end

	always_ff @ (posedge clk) begin
		if(rst == 1) begin
			state_r <= S_IDLE;
   			global_counter_r <= 0;
   			addr_r 		<= 0;	// for printing result
   			start_r 	<= 0;
			finish_r 	<= 0;
			finish_row_r 	<= 0;
			finish_pixel_r 	<= 0;
			finish_random_init_r <= 0;
			x_r <= 0;
			y_r <= 0;
			index_r <= 0;	// 0: TRG, 1: SRC, 2: Atlas, 3: RES
			access_B_r <= 0;
			print_sram_r <= 0;

			R_r <= 0;
			G_r <= 0;
			B_r <= 0;
			Gray_r <= 0;
			state_debug_r <= 0;
		end

		else begin
			state_r <= state_w;
			global_counter_r <= global_counter_w;
			addr_r 		<= addr_w;	// for printing result
			start_r 	<= start_w;
			finish_r 	<= finish_w;
			finish_row_r 		<= finish_row_w;
			finish_pixel_r 		<= finish_pixel_w;
			finish_random_init_r <= finish_random_init_w;
			x_r <= x_w;
			y_r <= y_w;
			index_r <= index_w;	// 0: TRG, 1: SRC, 2: Atlas, 3: RES
			access_B_r <= access_B_w;
			print_sram_r <= print_sram_w;

			R_r <= R_w;
			G_r <= G_w;
			B_r <= B_w;
			Gray_r <= Gray_w;
			state_debug_r <= state_debug_w;
		end
	end


	always_comb begin
			state_w = state_r;
			//global_counter_w = global_counter_r + 1;
			start_w 	= 0;
			x_w = x_r;
			y_w = y_r;
			index_w = index_r;	// 0: TRG, 1: SRC, 2: Atlas, 3: RES
			access_B_w = access_B_r;
			print_sram_w = 0;

			R_w = R_r; G_w = G_r; B_w = B_r; Gray_w = Gray_r;

			case(state_r) 

				S_IDLE: begin
					state_w = S_PRINT_SRAM_DATA;
					x_w = 0;
					y_w = 0;
					access_B_w = 0;
					index_w = 0;
				end

				S_PRINT_SRAM_DATA: begin

					if(access_B_r == 0 && !print_sram_r) begin
						R_w = SRAM_DQ[15:8];
						G_w = SRAM_DQ[7:0];

						access_B_w = 1;
					end
					else if(access_B_r == 1 && !print_sram_r) begin
						B_w = SRAM_DQ[15:8];
						Gray_w = SRAM_DQ[7:0];
						
						access_B_w = 0;
						print_sram_w = 1;
					end
					else begin
						print_sram_w = 0;
						//$display("\t%d: (x,y) = (%d, %d): (R, G, B, Gray) = (%d, %d, %d, %d)", addr_r, x_r, y_r, R_r, G_r, B_r, Gray_r);
						if(x_r == W_max - 1) begin
							x_w = 0;
							if(y_r == H_max - 1) begin
								y_w = 0;
								if(index_r == 0) begin
									index_w = 1;
								end
								else begin
									index_w = 0;
									state_w = S_WAIT;
								end

							end
							else begin
								y_w = y_r + 1;
							end
						end
						else begin
							x_w = x_r + 1;
						end
					end
				end

				S_WAIT: begin
					start_w = 1;
					state_w = S_TEXTURE_TRANSFER;
				end

				S_TEXTURE_TRANSFER: begin

					if(finish_w) begin
						state_w = S_FINISH_TEXTURE_TRANSFER;
						index_w = 3;		// For Result
					end
				end

				S_FINISH_TEXTURE_TRANSFER: begin
					x_w = 0;
					y_w = 0;
					index_w = 3;
					access_B_w = 0;
					state_w = S_PRINT_RESULT;

					$display("\nTimer: %d: enter S_PRINT_RESULT", global_counter_r);
					$display("==============");
					$display("    RESULT    ");
					$display("==============");
				end


				S_PRINT_RESULT: begin

					if(access_B_r == 0 && !print_sram_r) begin
						R_w = SRAM_DQ[15:8];
						G_w = SRAM_DQ[7:0];

						access_B_w = 1;
					end
					else if(access_B_r == 1 && !print_sram_r) begin
						B_w = SRAM_DQ[15:8];
						Gray_w = SRAM_DQ[7:0];
					
						access_B_w = 0;
						print_sram_w = 1;
					end
					else begin
						print_sram_w = 0;
						//$display("\t(x,y) = (%d, %d): (R, G, B) = (%d, %d, %d)", x_r, y_r, R_r, G_r, B_r);
						if(x_r == W_max - 1) begin
							x_w = 0;
							if(y_r == H_max - 1) begin
								y_w = 0;
								state_w = S_FINISH;
							end
							else begin
								y_w = y_r + 1;
							end
						end
						else begin
							x_w = x_r + 1;
						end
					end
				end


				S_FINISH: begin

					$display("\n");
					$display("===========================================");
					$display("Finish. Timer = %d", global_counter_r);
					$display("===========================================");
					state_w = S_IDLE;

					$finish;
				end
			endcase

	end

	always_ff @(posedge clk) begin

		if(state_r == S_PRINT_SRAM_DATA && x_r == 0 && y_r == 0) begin
			$display("\n=================");
			if(index_r == 0) begin
				$display("   TRG   ");
			end
			else if(index_r == 1) begin
				$display("   SRC   ");
			end
			$display("=================");
		end
		else begin end


		if(finish_random_init_w) begin
			$display("Timer: %d. Finish random init\n", global_counter_r);
		end

		if(state_w == S_TEXTURE_TRANSFER && state_r != S_TEXTURE_TRANSFER) begin
			$display("\nTimer: %d: enter S_TEXTURE_TRANSFER", global_counter_r);
		end

		if(print_sram_w) begin
			$display("\t%d: (x,y) = (%d, %d): (R, G, B, Gray) = (%d, %d, %d, %d)", addr_w, x_w, y_w, R_w, G_w, B_w, Gray_w);
		end

/*
		if(state_r == S_TEXTURE_TRANSFER) begin

			if(state_debug_r != state_debug_w) begin
				case(state_debug)
					0: begin $display("S_IDLE:"); end
			 		//1: begin $display("S_RANDOM_INIT: "); end// Initialize Atlas to Random using LFSRRandomSource
			 		2: begin $display("S_GENERATE_CANDIDATE: "); end
			 		3: begin $display("S_ACCESS_GRAYSCALE_CENTER:"); end
			 		4: begin $display("S_ACCESS_GRAYSCALE_NEIGHBOR:"); end			// to access sL
			 		5: begin $display("S_ACCESS_GRAYSCALE_NEIGHBOR_ATLAS:"); end	// to access rL, first access Atlas
					6: begin $display("S_CALCULATE_DISTANCE:"); end
			 		7: begin $display("S_WRITE_ATLAS:"); end
			 		8: begin $display("S_ACCESS_SOURCE:"); end
			 		9: begin $display("S_WRITE_RESULT:"); end
					10: begin $display("S_FINISH:"); end
					default: begin end
				endcase
			end



			//if(state_debug != 0 && state_debug != 1) begin
				$display("\tstate_debug = %d, SRAM_ADDR = %d, SRAM_WE = %d, SRAM_OE = %d, SRAM_DQ = %d", state_debug, SRAM_ADDR_text, SRAM_WE_text, SRAM_OE_text, SRAM_DQ_text);
				$display("\tSRAM: ADDR = %d, WE = %d, OE = %d, DQ = %d\n", SRAM_ADDR, SRAM_WE, SRAM_OE, SRAM_DQ);
			//end
		end
*/



	end

endmodule
