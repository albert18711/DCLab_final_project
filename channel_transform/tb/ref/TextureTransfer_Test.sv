// Texture Transfer Top Module
// reset when i_rst = RESET (local parameter)

// ******************************************************

// Use LOCAL_X and LOCAL_Y = 3
// Use HALF_WIDTH and HALF_HEIGHT = 1

// NOTE: this version is adapted to the testbench.
// That is, the valid random bits is different from /src/TextureTransfer.sv

module TextureTransfer(

		input 			i_clk,
		input 			i_start,
		input 			i_rst,
		
		input [8:0] 	i_SRC_h,		// 0~511: exactly use 300
		input [8:0]		i_SRC_w, 		//                    400
		input [8:0]		i_TRG_h,
		input [8:0]		i_TRG_w,
		
		input [2:0]		i_SRC_index,	// specify the beginning address of Source in SRAM
		input [2:0]		i_TRG_index,
		input [2:0]		i_Atlas_index,	// Atlas: the mapping of result pos(R_pos) to source pos(S_pos)
										// the result pixel at R_pos is from that in source at S_pos
		

		input [31:0]	i_wL,			// weight when calculating distance



		inout [15:0]	SRAM_DQ,			// SRAM data: read and write
		output [19:0] 	o_SRAM_ADDR,		// SRAM address
		output o_SRAM_OE,					// 0 -> read in from SRAM; 1 -> not read;
		output o_SRAM_WE,					// SRAM enable, 0 -> write
		
		output o_finish,				// Finish all
		output o_finish_row,			// Finish each row
		output o_finish_pixel,			// Finish one RES pixel 
		output o_finish_random_init,			// Finish Atlas random initialization

		output [31:0] o_global_counter,			// Check computation time
		output [3:0] o_state
		
);


// LOGIC:

	typedef enum {
		 S_IDLE,
		 S_GRAYSCALE_TRANSFORM,
		 S_RANDOM_INIT, // Initialize Atlas to Random using LFSRRandomSource
		 S_GENERATE_CANDIDATE,
		 S_ACCESS_GRAYSCALE_CENTER,
		 S_ACCESS_GRAYSCALE_NEIGHBOR,			// to access sL
		 S_ACCESS_GRAYSCALE_NEIGHBOR_ATLAS,		// to access rL, first access Atlas
		 S_CALCULATE_DISTANCE,
		 S_WRITE_ATLAS,
		 S_ACCESS_SOURCE,
		 S_WRITE_RESULT,
		 S_FINISH
   } State;
	
	State state_r, state_w;
	
	// LFSRRandomSource:
	logic random_next;
	logic [15:0] random_value;


	// source pixel counter:
	// (SRAM 1-D)
	// 	[0] [1] [2] [3] ... [i_SRC_w-1]	
	// 	[i_SRC_w] ...
	//
	logic [8:0] src_x_r, src_x_w, src_y_r, src_y_w;
	logic [8:0] trg_x_r, trg_x_w, trg_y_r, trg_y_w;
	logic [8:0] atlas_x_r, atlas_x_w, atlas_y_r, atlas_y_w;
	logic [8:0] res_x_r, res_x_w, res_y_r, res_y_w;
	
	// Record the current address of SRC, TRG, Atlas:
	logic signed [19:0]  SRC_addr_r, SRC_addr_w, TRG_addr_r, TRG_addr_w, Atlas_addr_r, Atlas_addr_w;
	logic atlas_access_y_r, atlas_access_y_w;			// Add 1 when accessing to candidate y
	logic [19:0] RES_addr_r, RES_addr_w;
	logic RES_write_B_r, RES_write_B_w;					// write RG or write B


	logic [15:0] sram_data_r, sram_data_w;
	logic [19:0] SRAM_addr_r, SRAM_addr_w;


	// Grayscale Transform:
	logic startGrayTrans_r, startGrayTrans_w;
	logic [19:0] SRAM_ADDR_GrayTrans;
	logic SRAM_OE_GrayTrans;
	logic SRAM_WE_GrayTrans;
	wire [15:0] SRAM_DQ_GrayTrans;
	logic finish_GrayTrans_r, finish_GrayTrans_w;
	logic [7:0] GrayValue;
	
	// Candidate:
	logic [3:0] cand_counter_r, cand_counter_w;
	logic signed [8:0] ax, ay;	// Defined as in C++ code, find atlas address
	logic signed [8:0] candx_r, candx_w, candy_r, candy_w;	// find candidate address in source
	logic signed [9:0] temp;
	logic signed [9:0] temp_y;
	logic signed [9:0] dx, dy;
	logic x_random_r, x_random_w;	// used when candx_r is random, then assign candy_r = rand()
	logic y_random_r, y_random_w;	// if y_random = 1 but x_rand = 0, then change candx_r = rand()
	logic modify_x_r, modify_x_w;

	// Grayscale Neighbor and Center:
	logic [7:0] SRC_center_r, SRC_center_w;	// source grayscale center -> dN
	logic [7:0] TRG_center_r, TRG_center_w;

	logic [7:0] SRC_neighbor_r [0:3];		// source grayscale neighbor 
	logic [7:0] SRC_neighbor_w [0:3];
	logic [7:0] TRG_neighbor_r [0:3];
	logic [7:0] TRG_neighbor_w [0:3];

	logic [31:0] dN_r, dN_w;

	logic access_gray_trg_r, access_gray_trg_w;		// Whether access grayscale of SRC(0) or TRG(1)

	logic [3:0] neighbor_counter_r, neighbor_counter_w;
	logic [8:0] src_N_y, src_N_x, trg_N_y, trg_N_x;
	logic Access_rL_r, Access_rL_w;					// Access rL once for one pixel in RES
	logic access_rL_src_r, access_rL_src_w;			// control for S_ACCESS_GRAYSCALE_NEIGHBOR_ATLAS



	// calculate Distance of neighbor and center:
	logic startLShape_r, startLShape_w;
	logic finish_Lshape;
	logic [31:0] dL_r, dL_w;

	// Compare distance and write:
	logic [63:0] Distance_r, Distance_w;
	logic [63:0] bestDistance_r, bestDistance_w;
	logic [8:0] best_x_r, best_x_w, best_y_r, best_y_w;
	logic [7:0] SRC_B_buffer_r, SRC_B_buffer_w;		// buffer B(Blue) of source when accessing grayscale of source
	logic [7:0] best_B_buffer_r, best_B_buffer_w;	// buffer B of the best candidate
	logic [15:0] best_RG_buffer_r, best_RG_buffer_w;
	
	// Control:
	logic finish_r, finish_w;
	logic finish_row_r, finish_row_w;
	logic finish_pixel_r, finish_pixel_w;
	logic finish_random_init_r, finish_random_init_w;

	logic [31:0] global_counter_r, global_counter_w;


	
// MODULE:
	LFSRRandomSource Rand(
			.i_next(random_next),
			.i_clk(i_clk),
			.i_rst(i_rst),
		 	.o_rand(random_value)
	);	
	
	Candidate_Atlas candidateAtlas(
		.i_TRG_h(i_TRG_h),
		.i_TRG_w(i_TRG_w),
		.candidate_counter(cand_counter_w), // Use _w !!!!!!!!! for S_CALCULATE_DISTANCE to S_GENERATE_CANDIDATE
		.i_trg_y(res_y_w),					// for S_WRITE_RESULT to S_GENERATE_CANDIDATE
		.i_trg_x(res_x_w),
		.o_atlas_y(ay),
		.o_atlas_x(ax)
	);

	
	// For source grayscale neighbor access
	// ex. neighbor_counter_r == 0 -> o_atlas_y = i_trg_y -1 and o_atlas_x = i_trg_x -1
	// No cyclic fix here
	Candidate_Atlas SourceNeighbor(
		.i_TRG_h(i_SRC_h),
		.i_TRG_w(i_SRC_w),
		.candidate_counter(neighbor_counter_w),	// Use _w !!!!
		.i_trg_y(candy_r),
		.i_trg_x(candx_r), 	// Prevent the center depending on src_y_r or src_x_r, which must change to access
							// source data
		.o_atlas_y(src_N_y),
		.o_atlas_x(src_N_x)
	);

	// For target grayscale neighbor access
	// Same as SourceNeighbor
	Candidate_Atlas TargetNeighbor(
		.i_TRG_h(i_TRG_h),
		.i_TRG_w(i_TRG_w),
		.candidate_counter(neighbor_counter_w),
		.i_trg_y(res_y_r),
		.i_trg_x(res_x_r),	// Prevent the center depending on trg_y_r or trg_x_r, which must change to access
							// target data
		.o_atlas_y(trg_N_y),
		.o_atlas_x(trg_N_x)
	);

	LShapeComparator_fast LshapeCompare(
		.i_start(startLShape_r),
		.i_clk(i_clk),
		.i_rst(i_rst),
		.i_sL(SRC_neighbor_r),	// grayscale use 8 bits
		.i_rL(TRG_neighbor_r),	// grayscale use 8 bits
		.o_Distance(dL_w),		// fractional part: 8 bits
		.o_finish(finish_Lshape)
	);

/*
	GrayscaleChannelTransform grayscaleTransform(
		.i_start(startGrayTrans_r),
		.i_clk(i_clk),
		.i_rst(i_rst),

		.i_SRC_h(i_SRC_h),		// 0~511: exactly use 300
		.i_SRC_w(i_SRC_w), 		//                    400
		.i_TRG_h(i_TRG_h),
		.i_TRG_w(i_TRG_w),

		.SRC_mean(32'd256),		// 8 bits for fractional part
		.SRC_std(32'd256),
		.TRG_mean(32'd256),
		.TRG_std(32'd256),
		
		.i_SRC_index(i_SRC_index),	// specify the beginning address of Source in SRAM
		.i_TRG_index(i_TRG_index),

		.SRAM_DQ(SRAM_DQ_GrayTrans),			// SRAM data: read and write
		.o_SRAM_ADDR(SRAM_ADDR_GrayTrans),		// SRAM address
		.o_SRAM_OE(SRAM_OE_GrayTrans),			// 0 -> read in from SRAM; 1 -> not read;
		.o_SRAM_WE(SRAM_WE_GrayTrans),			// SRAM enable, 0 -> write
		
		.o_finish(finish_GrayTrans_w),				// Finish all
		.o_finish_row(),				// Finish each row
		.o_finish_pixel(),				// Finish one SRC pixel 

		.o_global_counter(),			// Check computation time
		.o_state()
			
	);
*/
GrayscaleChannelTransform_comb grayTransform_comb(

		.i_gray(SRAM_DQ[7:0]),			// original grayscale

		.SRC_mean(32'd256),
		.SRC_std(32'd256),
		.TRG_mean(32'd256),
		.TRG_std(32'd256),
		
		.o_gray(GrayValue)		
);

	
	
// PARAM:
	localparam START_RANDOM_VALUE = 16'b0001_0001_0001_0001;
	localparam DBL_MAX = 64'b1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111;
	
	
//ASSIGN:

	// assign o_address 	= i_offset 	+ i_counter_x 	+ i_counter_y*i_w;	
	assign SRC_addr_w 	= (i_TRG_w*i_TRG_h	+ src_x_w		+ src_y_w*i_SRC_w)*2 + 1;  
						// grayscale only 
						// accessing RG is handled in the following code
	assign TRG_addr_w 	= (0			+ trg_x_w 		+ trg_y_w*i_TRG_w)*2 + 1;// grayscale only
	assign Atlas_addr_w = ((i_SRC_h*i_SRC_w+i_TRG_h*i_TRG_w) + atlas_x_w + atlas_y_w*i_TRG_w)*2+ atlas_access_y_w;
	assign RES_addr_w = ((i_SRC_h*i_SRC_w+i_TRG_h*i_TRG_w*2)+res_x_w + res_y_w*i_TRG_w)*2+ RES_write_B_w;
	
	assign o_SRAM_ADDR = SRAM_addr_r;
	assign o_SRAM_OE = ( state_r == S_GENERATE_CANDIDATE || state_r == S_ACCESS_SOURCE || state_r == S_ACCESS_GRAYSCALE_CENTER || state_r == S_ACCESS_GRAYSCALE_NEIGHBOR || state_r == S_ACCESS_GRAYSCALE_NEIGHBOR_ATLAS )? 0 : 1;

	assign o_SRAM_WE = ( state_r == S_RANDOM_INIT || state_r == S_WRITE_ATLAS || state_r == S_WRITE_RESULT )? 0 : 1;

	assign SRAM_DQ = ( state_r == S_RANDOM_INIT || state_r == S_WRITE_ATLAS || state_r == S_WRITE_RESULT )? sram_data_w : 16'bz ;
	
	assign o_finish = finish_r;
	assign o_finish_row = finish_row_r;
	assign o_finish_pixel = finish_pixel_r;
	assign o_finish_random_init = finish_random_init_r;

	assign o_global_counter = global_counter_r;
	assign o_state = state_r;
	

	
// COMB:
	always_comb begin
	
		state_w = state_r;
		//o_SRAM_OE = 1;
		//o_SRAM_WE = 1;
		//SRAM_DQ = 16'bz;
		finish_w = 0;
		finish_row_w = 0;
		finish_pixel_w = 0;
		finish_random_init_w = 0;
		
		// LFSRRandomSource:
		random_next = 0;

		src_x_w 	= src_x_r;
		src_y_w 	= src_y_r;
		trg_x_w 	= trg_x_r;
		trg_y_w 	= trg_y_r;
		atlas_x_w 	= atlas_x_r;
		atlas_y_w 	= atlas_y_r;
		res_x_w 	= res_x_r;
		res_y_w 	= res_y_r;

		atlas_access_y_w 	= atlas_access_y_r;			// Add 1 when accessing to candidate y

		RES_write_B_w 		= RES_write_B_r;					// write RG or write B
		SRAM_addr_w 		= SRAM_addr_r;
		sram_data_w			= 0;
		
		startGrayTrans_w = 0;

		cand_counter_w 		= cand_counter_r;

		candx_w = candx_r;
		candy_w = candy_r;	// find candidate address in source

		temp = 0;
		temp_y = 0;
		dx = 0; dy = 0;
		x_random_w = 0;
		y_random_w = 0;
		modify_x_w = 0;

		// Grayscale Neighbor and Center:
		SRC_center_w = SRC_center_r;	// source grayscale center -> dN
		TRG_center_w = TRG_center_r;

		for(int i = 0; i<4; i++) begin 		// source grayscale neighbor
			SRC_neighbor_w[i] = SRC_neighbor_r[i];
			TRG_neighbor_w[i] = TRG_neighbor_r[i];
		end

		dN_w = dN_r;
		access_gray_trg_w = access_gray_trg_r;		// Whether access grayscale of SRC(0) or TRG(1)

		neighbor_counter_w = neighbor_counter_r;

		// For rL
		Access_rL_w = Access_rL_r;
		access_rL_src_w = access_rL_src_r;

		// calculate Distance of neighbor and center:
		startLShape_w = 0;

		// Compare distance and write:
		Distance_w = Distance_r;
		bestDistance_w = bestDistance_r;
		best_x_w = best_x_r;
		best_y_w = best_y_r;
		SRC_B_buffer_w = SRC_B_buffer_r;		// buffer B(Blue) of source when accessing grayscale of source
		best_B_buffer_w = best_B_buffer_r;		// buffer B of the best candidate
		best_RG_buffer_w = best_RG_buffer_r;

		global_counter_w = global_counter_r + 1;

		case(cand_counter_r)
			4'b0000: begin
				dx = -1; dy = -1;
			end
			4'b0001: begin
				dx = 0; dy = -1;
			end
			4'b0010: begin
				dx = 1; dy = -1;
			end
			4'b0011: begin
				dx = -1; dy = 0;
			end
			default: begin
				dx = 0; dy = 0;
			end
		endcase

		case(state_r)
		
			S_IDLE: begin
				if(i_start) begin
					state_w = S_RANDOM_INIT;	// initialize Atlas first

					//state_w = S_GRAYSCALE_TRANSFORM;
					//startGrayTrans_w = 1;

					src_x_w = 0; src_y_w = 0;
					trg_x_w = 0; trg_y_w = 0;
					atlas_x_w = 0; atlas_y_w = 0; atlas_access_y_w = 0;
					res_x_w = 0; res_y_w = 0;
					SRAM_addr_w = Atlas_addr_w;
					
					cand_counter_w = 0;

					bestDistance_w = DBL_MAX;

					Access_rL_w = 0;

				end
				else begin end
			end

/*
			S_GRAYSCALE_TRANSFORM: begin
				if(finish_GrayTrans_w) begin
					state_w = S_RANDOM_INIT;
				end
				else begin end
			end
*/	
		
			// initialize Atlas to random elements
			S_RANDOM_INIT: begin
				random_next = 1;
				// Write SRAM
				// Store 16-bit random value but use only the upper 9 bits
				
				// SRAM Data
				// NOTE: change x in random[16-:x] according to i_SRC_w and i_SRC_h
				if(atlas_access_y_r == 0) begin
					if(random_value[15-:2] >= i_SRC_w-2) // x: 0 ~ 4 for testbench
						//SRAM_DQ = {14'b0, random_value[15-:2] - (i_SRC_w-2) + 1};
						sram_data_w = {14'b0, random_value[15-:2] - (i_SRC_w-2) + 1};
					else 
						//SRAM_DQ = {14'b0, random_value[15-:2] + 1};
						sram_data_w = {14'b0, random_value[15-:2] + 1};

				end
				else begin
					if(random_value[15-:2] >= i_SRC_h-2) //y: 0~299
						sram_data_w = {14'b0, random_value[15-:2] - (i_SRC_h-2) + 1};
					else
						sram_data_w = {14'b0, random_value[15-:2] + 1};
				end
				
				
				// SRAM Address
				SRAM_addr_w = Atlas_addr_w;
				if(atlas_access_y_r == 0) begin
					atlas_access_y_w = 1;			// currently write x, next cycle write y
				end
				else begin
					atlas_access_y_w = 0;	

					// Currently write address _r	
					if(atlas_x_r == i_TRG_w - 1) begin
						atlas_x_w = 0;
						
						if(atlas_y_r == i_TRG_h -1) begin
						// Change state
							state_w = S_GENERATE_CANDIDATE;
							atlas_y_w = ay;
							atlas_x_w = ax;
							atlas_access_y_w = 0;
							SRAM_addr_w = Atlas_addr_w;

							finish_random_init_w = 1;
						end
						else begin
							atlas_y_w = atlas_y_r + 1;
						end
					end
					else begin
						atlas_x_w = atlas_x_r + 1;
					end
				end
			end
			
/*
// candidtate counter: ex. candidate counter = 0 -> dx = -1, dy = -1 
//	[0] [1] [2]
//  [3] [4]
//
// [4] is random pos
*/			
// begin at trg_x_r = 0 and trg_y_r = 0:
// void generateSingleCandidate
// (const int& i, const int& j, const int& dy, const int& dx, int & candy, int & candx)
			S_GENERATE_CANDIDATE: begin

				x_random_w = x_random_r;
				y_random_w = y_random_r;
				//modify_x_w = modify_x_r;

				if(atlas_access_y_r == 0) begin
				// access Atlas to generate candx
				// check whether candx is within the valid range
					if(cand_counter_r == 4'b0100) begin
						x_random_w = 1;
						random_next = 1;
						if(random_value[15-:2] >= i_SRC_w-2) begin //x: 0~399 // candx: 1~398
							candx_w = random_value[15-:2]-(i_SRC_w -2) + 1;
						end
						else begin
							candx_w = random_value[15-:2] + 1;
						end
					end

					else begin
						temp = $signed({1'b0, SRAM_DQ[8:0]}) - $signed(dx);
						if(temp < 1 || temp > i_SRC_w - 2) begin

							x_random_w = 1;
							//candx_w = random_value[16-:9];
							random_next = 1;
							if(random_value[15-:2] >= i_SRC_w-2) begin//x: 0~319 // candx: 1~318
								candx_w = random_value[15-:2]-(i_SRC_w -2) + 1;
							end
							else begin
								candx_w = random_value[15-:2] + 1;
							end
						end
						
						else begin
							x_random_w = 0;
							random_next = 0;
							candx_w = temp[8:0];
						end
					end

					atlas_access_y_w = 1;
					SRAM_addr_w = Atlas_addr_w;
				end
				
				else begin 	// generate candy
					//candy_w = SRAM_DQ[7:0];
					//atlas_access_y_w = 0;

					if(cand_counter_r == 4'b0100 && !modify_x_r) begin
						y_random_w = 1;
						random_next = 1;
						if(random_value[15-:2] >= i_SRC_h - 2) begin 	//y: 0~299
							candy_w = random_value[15-:2]-(i_SRC_h-2) + 1;
						end
						else begin
							candy_w = random_value[15-:2] + 1;
						end
						src_y_w = candy_w;
						src_x_w = candx_w;
						SRAM_addr_w = SRC_addr_w;
						state_w = S_ACCESS_GRAYSCALE_CENTER;
						access_gray_trg_w = 0;
					end

					else if(!modify_x_r) begin // from SRAM or rand() if exceeding index

						if(x_random_r) begin
							y_random_w = 1;
							random_next = 1;
							if(random_value[15-:2] >= i_SRC_h-2) begin//y: 0~239
								candy_w = random_value[15-:2]-(i_SRC_h-2) + 1;
							end
							else begin
								candy_w = random_value[15-:2] + 1;
							end

							src_y_w = candy_w;
							src_x_w = candx_w;
							SRAM_addr_w = SRC_addr_w;
							state_w = S_ACCESS_GRAYSCALE_CENTER;
							access_gray_trg_w = 0;
						end

						else begin
							temp_y = $signed({1'b0, SRAM_DQ[8:0]}) - $signed(dy);

							if(temp_y < 1 || temp_y > i_SRC_h - 2) begin
								y_random_w = 1;
								random_next = 1;
								if(random_value[15-:2] >= i_SRC_h-2) begin//y: 0~239
									candy_w = random_value[15-:2]-(i_SRC_h-2) + 1;
								end
								else begin
									candy_w = random_value[15-:2] + 1;
								end

								atlas_access_y_w = 1;
								state_w = state_r;
								modify_x_w = 1;
								
							end

							else begin
								y_random_w = 0;
								random_next = 0;
								candy_w = temp_y[8:0];

								src_y_w = candy_w;
								src_x_w = candx_w;
								SRAM_addr_w = SRC_addr_w;
								state_w = S_ACCESS_GRAYSCALE_CENTER;
								access_gray_trg_w = 0;
							end
						end

					end

					else begin // change candx to rand() for candy is from rand()
						x_random_w = 1;
						y_random_w = 1;
						random_next = 1;

						candx_w = candy_r;
						if(random_value[15-:2] >= i_SRC_h-2) begin//x: 0~319 // candx: 1~318
							candy_w = random_value[15-:2]-(i_SRC_h -2) + 1;
						end
						else begin
							candy_w = random_value[15-:2] + 1;
						end

						src_y_w = candy_w;
						src_x_w = candx_w;
						SRAM_addr_w = SRC_addr_w;
						state_w = S_ACCESS_GRAYSCALE_CENTER;
						access_gray_trg_w = 0;
					end

				end
			end
			

			// access SRC_gray[candy][candx] and TRG[res_y_r][res_x_r]
			S_ACCESS_GRAYSCALE_CENTER: begin
				neighbor_counter_w = 0;

				// access source center
				if(access_gray_trg_r == 0) begin

					SRC_center_w = GrayValue; //SRAM_DQ[7:0];
					SRC_B_buffer_w = SRAM_DQ[15:8];
					access_gray_trg_w = 1;
					state_w = S_ACCESS_GRAYSCALE_CENTER;

					// Access TRG grayscale
					// Target address : j, i -> res_x_r and res_y_r
					trg_x_w = res_x_r;
					trg_y_w = res_y_r;
					SRAM_addr_w = TRG_addr_w;
				end

				// access target center
				else begin
					TRG_center_w = SRAM_DQ[7:0];
					access_gray_trg_w = 0;
					state_w = S_ACCESS_GRAYSCALE_NEIGHBOR;

					// access source grayscale neighbor(sL)
					src_x_w = src_N_x;
					src_y_w = src_N_y;
					SRAM_addr_w = SRC_addr_w;
				end
			end


			// First access source neighbor: access_gray_trg_r == 0, neighbor_counter_r: 0~3
			S_ACCESS_GRAYSCALE_NEIGHBOR: begin

				dN_w = $signed($signed({24'd0, SRC_center_r}) - $signed({24'd0, TRG_center_r}))*$signed($signed({24'd0, SRC_center_r}) - $signed({24'd0, TRG_center_r}));

				state_w = S_ACCESS_GRAYSCALE_NEIGHBOR;

				// source neighbor-> sL
				if(access_gray_trg_r == 0) begin
					SRC_neighbor_w[neighbor_counter_r] = GrayValue; //SRAM_DQ[7:0];

					// address:
					if(neighbor_counter_r == 4'h3) begin
						access_gray_trg_w = 1;
						neighbor_counter_w = 0;
						atlas_x_w = trg_N_x;
						atlas_y_w = trg_N_y;
						atlas_access_y_w = 0;
						SRAM_addr_w = Atlas_addr_w;
						if(Access_rL_r) begin
							state_w = S_CALCULATE_DISTANCE;
							access_gray_trg_w = 0;
							startLShape_w = 1;
						end
						else begin  // access Atlas to get rL
							state_w = S_ACCESS_GRAYSCALE_NEIGHBOR_ATLAS; // to get rL
							access_rL_src_w = 0;		// access Atlas, instead of SRC
						end
					end
					else begin 
						neighbor_counter_w = neighbor_counter_r + 1;
						src_x_w = src_N_x;
						src_y_w = src_N_y;
						SRAM_addr_w = SRC_addr_w;
					end
				end

			end
			
			// to get rL, first access Atlas
			// once for one pixel in RES
			// int originx = Atlas[2*(rx*TRG_h+ry)];
            // int originy = Atlas[2*(rx*TRG_h+ry)+1];
            // rL[count] = SRC_gray[originx*SRC_h+originy];
			S_ACCESS_GRAYSCALE_NEIGHBOR_ATLAS: begin

				//o_SRAM_WE = 1;
				//o_SRAM_OE = 0;	// only read

				//SRAM_DQ = 16'bz;

				Access_rL_w = 1;

				state_w = S_ACCESS_GRAYSCALE_NEIGHBOR_ATLAS;

				if(atlas_access_y_r == 0 && access_rL_src_r == 0) begin
					atlas_access_y_w = 1;
					src_x_w = SRAM_DQ[8:0];
					SRAM_addr_w = Atlas_addr_w;
				end
				else if(atlas_access_y_r == 1 && access_rL_src_r == 0) begin
					atlas_access_y_w = 0;
					src_y_w = SRAM_DQ[8:0];
					SRAM_addr_w = SRC_addr_w;
					access_rL_src_w = 1;
				end
				else if(access_rL_src_r == 1) begin
					TRG_neighbor_w[neighbor_counter_r] = GrayValue; //SRAM_DQ[7:0];

					if(neighbor_counter_r != 4'h3) begin
						neighbor_counter_w = neighbor_counter_r + 1;

						access_rL_src_w = 0;
						atlas_access_y_w = 0;
						atlas_x_w = trg_N_x;
						atlas_y_w = trg_N_y;
						SRAM_addr_w = Atlas_addr_w;
					end
					else begin
						neighbor_counter_w = 0;
						state_w = S_CALCULATE_DISTANCE;
						startLShape_w = 1;
					end
				end
			end


			S_CALCULATE_DISTANCE: begin
				if(finish_Lshape) begin
					Distance_w = dL_w*i_wL + {24'd0, dN_r, 8'd0};
					if(Distance_w < bestDistance_r) begin
						bestDistance_w = Distance_w;
						best_x_w = candx_r;
						best_y_w = candy_r;
						best_B_buffer_w = SRC_B_buffer_r;
					end
					else begin end

					// TODO:
					// Whether to write or continuing find bestDistance?
					if(cand_counter_r == 4'h4) begin
						state_w = S_WRITE_ATLAS;
						cand_counter_w = 0;

						atlas_y_w = res_y_r;
						atlas_x_w = res_x_r;
						atlas_access_y_w = 0;
						SRAM_addr_w = Atlas_addr_w;

					end
					else begin
						cand_counter_w = cand_counter_r + 1;
						state_w = S_GENERATE_CANDIDATE;
						atlas_y_w = ay;
						atlas_x_w = ax;
						atlas_access_y_w = 0;
						SRAM_addr_w = Atlas_addr_w;
					end
				end
				else begin 
					state_w = S_CALCULATE_DISTANCE;
				end
			end

			S_WRITE_ATLAS: begin
				//o_SRAM_WE = 0; // Write SRAM (Atlas)
				//o_SRAM_OE = 1;

				Access_rL_w = 0; 	// After accessing all neighbors of a given RES pixel

				if(atlas_access_y_r == 0) begin
					//SRAM_DQ = {7'b0, best_x_r};
					sram_data_w = {7'b0, best_x_r};
					state_w = S_WRITE_ATLAS;
					atlas_access_y_w = 1;
					SRAM_addr_w = Atlas_addr_w;
				end
				else begin
					//SRAM_DQ = {7'b0, best_y_r};
					sram_data_w = {7'b0, best_y_r};
					state_w = S_ACCESS_SOURCE;
					src_y_w = best_y_r;
					src_x_w = best_x_r;
					SRAM_addr_w = SRC_addr_w - 1; //SRC_addr_w is the address of B and grayscale
				end

			end

			// only access R and G in source since best_B_buffer_r stores B
			S_ACCESS_SOURCE: begin
				//o_SRAM_OE = 0;	// only read
				//o_SRAM_WE = 1;
				//SRAM_DQ = 16'bz;

				state_w = S_WRITE_RESULT;
				best_RG_buffer_w = SRAM_DQ;

				RES_write_B_w = 0;
				SRAM_addr_w = RES_addr_w;

			end
			// write source to result:
			// update Atlas:
			S_WRITE_RESULT: begin
				bestDistance_w = DBL_MAX;
				//o_SRAM_WE = 0; // Write SRAM (Result)
				//o_SRAM_OE = 1;

				if(RES_write_B_r == 0) begin
					//SRAM_DQ = best_RG_buffer_r;
					sram_data_w = best_RG_buffer_r;
					RES_write_B_w = 1;
					SRAM_addr_w = RES_addr_w;

					state_w = S_WRITE_RESULT;
				end
				else begin
					//SRAM_DQ = {best_B_buffer_r, 8'd0};
					sram_data_w = {best_B_buffer_r, 8'd0};
					RES_write_B_w = 0;

					finish_pixel_w = 1;

					// Check:
					if(res_x_r == i_TRG_w - 1)begin
						res_x_w = 0;
						finish_row_w = 1;

						if(res_y_r == i_TRG_h - 1) begin
							//finish_w = 1;
							res_y_w = 0;
							state_w = S_FINISH;
							//$display("Go to S_FINISH");
						end
						else begin
							res_y_w = res_y_r + 1;
							state_w = S_GENERATE_CANDIDATE;
						end
					end
					else begin
						res_x_w = res_x_r + 1;
						state_w = S_GENERATE_CANDIDATE;
					end

					
					atlas_y_w = ay;
					atlas_x_w = ax;
					atlas_access_y_w = 0;
					SRAM_addr_w = Atlas_addr_w;
				end

			end

			S_FINISH: begin
				state_w = S_IDLE;
				finish_w = 1;
			end
			
			
		endcase
	
	end
	

	
// FF:
	always_ff @(posedge i_clk) begin
	
		if(i_rst) begin
			state_r <= S_IDLE;
			src_x_r <= 0;
			src_y_r <= 0;
			trg_x_r <= 0;
			trg_y_r <= 0;
			atlas_x_r <= 0;
			atlas_y_r <= 0;
			res_x_r <= 0;
			res_y_r <= 0;
			SRC_addr_r <= 0;
			TRG_addr_r <= 0;
			Atlas_addr_r <= 0;
			atlas_access_y_r 	<= 0;			// Add 1 when accessing to candidate y
			RES_addr_r 			<= 0;
			RES_write_B_r 		<= 0;					// write RG or write B
			SRAM_addr_r <= 0;
	
	// Grayscale Transform:
			startGrayTrans_r <= 0;

			cand_counter_r <= 0;
			candx_r <= 0;
			candy_r <= 0;	// find candidate address in source
			x_random_r <= 0;
			y_random_r <= 0;
			modify_x_r <= 0;

	// Grayscale Neighbor and Center:
			SRC_center_r <= 0;	// source grayscale center -> dN
			TRG_center_r <= 0;

			for(int i = 0; i<4 ;i++) begin
				SRC_neighbor_r[i] <= 0;
				TRG_neighbor_r[i] <= 0;
			end

			dN_r <= 0;

			access_gray_trg_r <= 0;		// Whether access grayscale of SRC(0) or TRG(1)

			neighbor_counter_r <= 0;

			Access_rL_r <= 0;
			access_rL_src_r <= 0;

	// calculate Distance of neighbor and center:
			startLShape_r <= 0;

			dL_r <= 0;

	// Compare distance and write:
			Distance_r 		<= 0;
			bestDistance_r 	<= 0;
			best_x_r <= 0;
			best_y_r <= 0;
			SRC_B_buffer_r 		<= 0;		// buffer B(Blue) of source when accessing grayscale of source
			best_B_buffer_r 	<= 0;	// buffer B of the best candidate
			best_RG_buffer_r 	<= 0;
	
	// Control:
			finish_r 		<= 0;
			finish_row_r 	<= 0;
			finish_pixel_r 	<= 0;
			finish_random_init_r <= 0;

			global_counter_r <= 0;
		end


		else begin
			state_r <= state_w;
			src_x_r <= src_x_w;
			src_y_r <= src_y_w;
			trg_x_r <= trg_x_w;
			trg_y_r <= trg_y_w;
			atlas_x_r <= atlas_x_w;
			atlas_y_r <= atlas_y_w;
			res_x_r <= res_x_w;
			res_y_r <= res_y_w;
			SRC_addr_r <= SRC_addr_w;
			TRG_addr_r <= TRG_addr_w;
			Atlas_addr_r <= Atlas_addr_w;
			atlas_access_y_r 	<= atlas_access_y_w;			// Add 1 when accessing to candidate y
			RES_addr_r 			<= RES_addr_w;
			RES_write_B_r 		<= RES_write_B_w;					// write RG or write B
			SRAM_addr_r 		<= SRAM_addr_w;
	
	// Grayscale Transform:
			startGrayTrans_r <= startGrayTrans_w;

			cand_counter_r <= cand_counter_w;
			candx_r <= candx_w;
			candy_r <= candy_w;	// find candidate address in source
			x_random_r <= x_random_w;
			y_random_r <= y_random_w;
			modify_x_r <= modify_x_w;

	// Grayscale Neighbor and Center:
			SRC_center_r <= SRC_center_w;	// source grayscale center -> dN
			TRG_center_r <= TRG_center_w;

			for(int i = 0; i<4 ;i++) begin
				SRC_neighbor_r[i] <= SRC_neighbor_w[i];
				TRG_neighbor_r[i] <= TRG_neighbor_w[i];
			end

			dN_r <= dN_w;

			access_gray_trg_r <= access_gray_trg_w;		// Whether access grayscale of SRC(0) or TRG(1)

			neighbor_counter_r <= neighbor_counter_w;

			Access_rL_r <= Access_rL_w;
			access_rL_src_r <= access_rL_src_w;

	// calculate Distance of neighbor and center:
			startLShape_r <= startLShape_w;

			dL_r <= dL_w;

	// Compare distance and write:
			Distance_r 		<= Distance_w;
			bestDistance_r 	<= bestDistance_w;
			best_x_r 		<= best_x_w;
			best_y_r 		<= best_y_w;
			SRC_B_buffer_r 		<= SRC_B_buffer_w;		// buffer B(Blue) of source when accessing grayscale of source
			best_B_buffer_r 	<= best_B_buffer_w;	// buffer B of the best candidate
			best_RG_buffer_r 	<= best_RG_buffer_w;
	
	// Control:
			finish_r 		<= finish_w;
			finish_row_r 	<= finish_row_w;
			finish_pixel_r 	<= finish_pixel_w;
			finish_random_init_r <= finish_random_init_w;

			global_counter_r <= global_counter_w;
		end

	end



	// This part is for debug:
	always_ff @(posedge i_clk) begin

		if(state_w != state_r && res_x_r == 4 && res_y_r == 1) begin

			if(state_r == S_CALCULATE_DISTANCE) 
				//$display("\tDistance = %d, dN = %d, dL = %d", Distance_w, dN_r, dL_w);

			if(state_r == S_GENERATE_CANDIDATE) begin
				$display("res(%d, %d): ", res_x_r, res_y_r);
				$display("\tCandidate #%d: candx = %d, candy = %d", cand_counter_r, candx_w, candy_w);
			end
		end
	end

endmodule

// NOTE: C++ <-> System Verilog
    //  double dN = SRC_gray[candx*SRC_h+candy] - TRG_gray[j*TRG_h+i];    dN = dN * dN;
    // j, i -> res_x_r and res_y_r
