// source: photo 0
// target: photo 1
// output: photo 2
// reshape the color distribution of photo 0 to be like photo 1
// i.e. transform photo 0's color to photo 1's

// `include "sqrt.v"
// `include "simple_root.sv"
`include "sqrt_32.sv"
`include "main_RGB2lab.v"

module color_transform (
	input clk,    // Clock
	input rst_n,  // Asynchronous reset active low
	input start_transform,

	// Constant parameter/////
	input [9:0] iCol_Max,
	input [9:0] iRow_Max,


	// SRAM side ///////
	output reg oSRAM_OE_N,
	output reg oSRAM_WE_N,
	output reg [19:0] oSRAM_ADDR,
	inout  [15:0] oSRAM_DATA,
	output [15:0] gray_s_mean,
	output [15:0] gray_s_std,
	output [15:0] gray_t_mean,
	output [15:0] gray_t_std,

	// debug
	output [1:0] oStore_g
	// output state,
	// output now_photo
);

	logic [15:0] sram_wdata;

	logic [19:0] address_r, address_w;

	logic [47:0] lab;

	// static result store
	//// l
	logic [15:0] l_s, l_t;
	logic [31:0] l_s_sum_r,  l_s_sum_w;
	logic [31:0] l_t_sum_r,  l_t_sum_w;
	logic [31:0] l_s_mean,   l_t_mean;
	logic [31:0] l_s_dif2,   l_t_dif2;
	logic [31:0] l_s_std2_r, l_s_std2_w;
	logic [31:0] l_t_std2_r, l_t_std2_w;
	logic [15:0] l_s_std_r,  l_s_std_w;
	logic [15:0] l_t_std_r,  l_t_std_w;
	logic [15:0] l_s_std,    l_t_std;
	logic [15:0] l_trs;
	//// a
	logic [15:0] a_s, a_t;
	logic [31:0] a_s_sum_r,  a_s_sum_w;
	logic [31:0] a_t_sum_r,  a_t_sum_w;
	logic [31:0] a_s_mean,   a_t_mean;
	logic [31:0] a_s_dif2,   a_t_dif2;
	logic [31:0] a_s_std2_r, a_s_std2_w;
	logic [31:0] a_t_std2_r, a_t_std2_w;
	logic [15:0] a_s_std_r,  a_s_std_w;
	logic [15:0] a_t_std_r,  a_t_std_w;
	logic [15:0] a_s_std,    a_t_std;
	logic [15:0] a_trs;
	//// b
	logic [15:0] b_s, b_t;
	logic [31:0] b_s_sum_r,  b_s_sum_w;
	logic [31:0] b_t_sum_r,  b_t_sum_w;
	logic [31:0] b_s_mean,   b_t_mean;
	logic [31:0] b_s_dif2,   b_t_dif2;
	logic [31:0] b_s_std2_r, b_s_std2_w;
	logic [31:0] b_t_std2_r, b_t_std2_w;
	logic [15:0] b_s_std_r,  b_s_std_w;
	logic [15:0] b_t_std_r,  b_t_std_w;
	logic [15:0] b_s_std,    b_t_std;
	logic [15:0] b_trs;
	//// g
	logic [15:0] g_s, g_t;
	logic [31:0] g_s_sum_r,  g_s_sum_w;
	logic [31:0] g_t_sum_r,  g_t_sum_w;
	logic [31:0] g_s_mean,   g_t_mean;
	logic [31:0] g_s_dif2,   g_t_dif2;
	logic [31:0] g_s_std2_r, g_s_std2_w;
	logic [31:0] g_t_std2_r, g_t_std2_w;
	logic [15:0] g_s_std_r,  g_s_std_w;
	logic [15:0] g_t_std_r,  g_t_std_w;
	logic [15:0] g_s_std,    g_t_std;
	// logic [19:0] now_photo_start_r, now_photo_start_w;

	logic [31:0] buffer_r, buffer_w;

	logic [1:0]  store_g_r, store_g_w;
	logic rooted_r, rooted_w;

	enum {S_IDLE, S_HALF_R, S_PRE_R, S_FULL_R, S_ROOT, S_HALF_W, S_FULL_W} state_r, state_w;
	enum {SOURCE, TARGET, STD_S, STD_T, OUTPUT} now_photo_r, now_photo_w;

	logic sqrt_rst;
	logic sqrt_rst_r, sqrt_rst_w;
	// logic [1:0] sqrt_counter_r, sqrt_counter_w;

	logic [31:0] PHOTO_SIZE;
	assign PHOTO_SIZE = iCol_Max * iRow_Max;

	assign oStore_g = store_g_r;
	// assign state = state_r;
	// assign now_photo = now_photo_r;

	assign oSRAM_ADDR  = address_r;
	assign oSRAM_DATA  = (oSRAM_WE_N)? 16'bz : sram_wdata;
	assign gray_s_mean = g_s_mean;
	assign gray_s_std  = g_s_std;
	assign gray_t_mean = g_t_mean;
	assign gray_t_std  = g_t_std;

	// transform lab to 16'b, 8' fraction
	assign l_s = lab[47:32] >> 5;
	assign a_s = lab[31:16] >> 5;
	assign b_s = lab[15:0]  >> 5;
	assign g_s = {buffer_r[7:0], 8'b0};
	assign l_t = lab[47:32] >> 5;
	assign a_t = lab[31:16] >> 5;
	assign b_t = lab[15:0]  >> 5;
	assign g_t = {buffer_r[7:0], 8'b0};

	assign l_s_mean  = (l_s_sum_r << 8) / PHOTO_SIZE;
	assign l_s_dif2  = (l_s - l_s_mean) ** 2 / PHOTO_SIZE;
	assign a_s_mean  = (a_s_sum_r << 8) / PHOTO_SIZE;
	assign a_s_dif2  = (a_s - a_s_mean) ** 2 / PHOTO_SIZE;
	assign b_s_mean  = (b_s_sum_r << 8) / PHOTO_SIZE;
	assign b_s_dif2  = (b_s - b_s_mean) ** 2 / PHOTO_SIZE;
	assign g_s_mean  = (g_s_sum_r << 8) / PHOTO_SIZE;
	assign g_s_dif2  = (g_s - g_s_mean) ** 2 / PHOTO_SIZE;

	assign l_t_mean  = (l_t_sum_r << 8) / PHOTO_SIZE;
	assign l_t_dif2  = (l_t - l_t_mean) ** 2 / PHOTO_SIZE;
	assign a_t_mean  = (a_t_sum_r << 8) / PHOTO_SIZE;
	assign a_t_dif2  = (a_t - a_t_mean) ** 2 / PHOTO_SIZE;
	assign b_t_mean  = (b_t_sum_r << 8) / PHOTO_SIZE;
	assign b_t_dif2  = (b_t - b_t_mean) ** 2 / PHOTO_SIZE;
	assign g_t_mean  = (g_t_sum_r << 8) / PHOTO_SIZE;
	assign g_t_dif2  = (g_t - g_t_mean) ** 2 / PHOTO_SIZE;

	assign sqrt_rst = sqrt_rst_r;

	logic root_ready_ls, root_ready_as, root_ready_bs, root_ready_gs;
	logic root_ready_lt, root_ready_at, root_ready_bt, root_ready_gt;
	logic root_ready;
	assign root_ready = (root_ready_ls & root_ready_as & root_ready_bs &
						 root_ready_lt & root_ready_at & root_ready_bt &
						 root_ready_gs & root_ready_gt);

	sqrt32 rootsl (.clk(clk), .rdy(root_ready_ls), .reset(sqrt_rst), .x(l_s_std2_r), .y(l_s_std));
	sqrt32 rootsa (.clk(clk), .rdy(root_ready_as), .reset(sqrt_rst), .x(a_s_std2_r), .y(a_s_std));
	sqrt32 rootsb (.clk(clk), .rdy(root_ready_bs), .reset(sqrt_rst), .x(b_s_std2_r), .y(b_s_std));
	sqrt32 rootsg (.clk(clk), .rdy(root_ready_gs), .reset(sqrt_rst), .x(g_s_std2_r), .y(g_s_std));

	sqrt32 roottl (.clk(clk), .rdy(root_ready_lt), .reset(sqrt_rst), .x(l_t_std2_r), .y(l_t_std));
	sqrt32 rootta (.clk(clk), .rdy(root_ready_at), .reset(sqrt_rst), .x(a_t_std2_r), .y(a_t_std));
	sqrt32 roottb (.clk(clk), .rdy(root_ready_bt), .reset(sqrt_rst), .x(b_t_std2_r), .y(b_t_std));
	sqrt32 roottg (.clk(clk), .rdy(root_ready_gt), .reset(sqrt_rst), .x(g_t_std2_r), .y(g_t_std));

	// assign lab = {};

	RGB2lab rgb2lab (
		.i_rst(~rst_n),
		.i_R(buffer_r[31:24]),
		.i_G(buffer_r[23:16]),
		.i_B(buffer_r[15:8]),
		.o_l(lab[47:32]),
		.o_a(lab[31:16]),
		.o_b(lab[15:0])
		);

	assign l_trs = (l_s - l_s_mean) * l_t_std_r / l_s_std_r + l_t_mean;
	assign a_trs = (a_s - a_s_mean) * a_t_std_r / a_s_std_r + a_t_mean;
	assign b_trs = (b_s - b_s_mean) * b_t_std_r / b_s_std_r + b_t_mean;
	// assign g_trs = (g_s - b_s_mean) * g_t_std / g_s_std + g_t_mean;

	// control SRAM flow
	always_comb begin
		state_w     = state_r;
		address_w   = address_r;
		buffer_w    = buffer_r;
		now_photo_w = now_photo_r;
		oSRAM_WE_N  = 1;
		oSRAM_OE_N  = 1;
		store_g_w   = store_g_r;
		sqrt_rst_w  = 0;
		sram_wdata  = 0;
		rooted_w    = rooted_r;
		// sqrt_counter_w = sqrt_counter_r;

		// s
		l_s_sum_w = l_s_sum_r;
		a_s_sum_w = a_s_sum_r;
		b_s_sum_w = b_s_sum_r;
		g_s_sum_w = g_s_sum_r;

		l_s_std2_w = l_s_std2_r;
		a_s_std2_w = a_s_std2_r;
		b_s_std2_w = b_s_std2_r;
		g_s_std2_w = g_s_std2_r;
		
		l_s_std_w = l_s_std_r;
		a_s_std_w = a_s_std_r;
		b_s_std_w = b_s_std_r;
		g_s_std_w = g_s_std_r;

		// t
		l_t_sum_w = l_t_sum_r;
		a_t_sum_w = a_t_sum_r;
		b_t_sum_w = b_t_sum_r;
		g_t_sum_w = g_t_sum_r;

		l_t_std2_w = l_t_std2_r;
		a_t_std2_w = a_t_std2_r;
		b_t_std2_w = b_t_std2_r;
		g_t_std2_w = g_t_std2_r;

		l_t_std_w  = l_t_std_r;
		a_t_std_w  = a_t_std_r;
		b_t_std_w  = b_t_std_r;
		g_t_std_w  = g_t_std_r;

		case (state_r)
			S_IDLE: begin
				if(start_transform) begin
					state_w = S_HALF_R;
					address_w = 0; // start with photo num 0
					oSRAM_OE_N = 0;
					oSRAM_WE_N = 1;
					now_photo_w = SOURCE;
				end
			end
			S_PRE_R:  begin
				oSRAM_OE_N = 0;
				oSRAM_WE_N = 1;
				state_w = S_HALF_R;
			end
			S_HALF_R: begin
				state_w = S_FULL_R;
				buffer_w[31:16] = oSRAM_DATA; // read RG
				oSRAM_WE_N = 1;
				oSRAM_OE_N = 0;
				address_w = address_r + 1;
				// NOTICE: for the first half, buffer_r should be 0
				case (now_photo_r)
					SOURCE: begin
						l_s_sum_w = l_s_sum_r + lab[47:32];
						a_s_sum_w = a_s_sum_r + lab[31:16];
						b_s_sum_w = b_s_sum_r + lab[15:0];
						g_s_sum_w = g_s_sum_r + buffer_r[7:0];
					end
					TARGET: begin
						l_t_sum_w = l_t_sum_r + lab[47:32];
						a_t_sum_w = a_t_sum_r + lab[31:16];
						b_t_sum_w = b_t_sum_r + lab[15:0];
						g_t_sum_w = g_t_sum_r + buffer_r[7:0];
					end
					STD_S: begin
						l_s_std2_w = l_s_std2_r + (l_s_dif2 / PHOTO_SIZE);
						a_s_std2_w = a_s_std2_r + (a_s_dif2 / PHOTO_SIZE);
						b_s_std2_w = b_s_std2_r + (b_s_dif2 / PHOTO_SIZE);
						g_s_std2_w = g_s_std2_r + (g_s_dif2 / PHOTO_SIZE);
					end
					STD_T: begin
						l_t_std2_w = l_t_std2_r + (l_t_dif2 / PHOTO_SIZE);
						a_t_std2_w = a_t_std2_r + (a_t_dif2 / PHOTO_SIZE);
						b_t_std2_w = b_t_std2_r + (b_t_dif2 / PHOTO_SIZE);
						g_t_std2_w = g_t_std2_r + (g_t_dif2 / PHOTO_SIZE);
					end
					OUTPUT: begin
					end
					default : /* default */;
				endcase
			end
			S_FULL_R: begin
				buffer_w[15:0] = oSRAM_DATA;
				case (now_photo_r)
					SOURCE: begin
						oSRAM_WE_N = 1;
						oSRAM_OE_N = 0;
						address_w = address_r + 1;
						state_w = S_HALF_R;
						if( address_r == PHOTO_SIZE * 2 + 1) begin
							now_photo_w = TARGET;
						end
					end
					TARGET: begin
						oSRAM_WE_N = 1;
						oSRAM_OE_N = 0;
						address_w = address_r + 1;
						state_w = S_HALF_R;
						if( address_r == PHOTO_SIZE * 4 + 1) begin
							now_photo_w = STD_S;
							address_w = 0; // back to source
						end						
					end
					STD_S: begin
						oSRAM_WE_N = 1;
						oSRAM_OE_N = 0;
						address_w = address_r + 1;
						state_w = S_HALF_R;
						if( address_r == PHOTO_SIZE * 2 + 1) begin
							now_photo_w = STD_T;
							// address_w = 0;
						end						
					end
					STD_T: begin
						oSRAM_WE_N = 1;
						oSRAM_OE_N = 0;
						address_w = address_r + 1;
						state_w = S_HALF_R;
						if( address_r == PHOTO_SIZE * 4 + 1) begin
							now_photo_w = OUTPUT;
							// sqrt_rst_w = 1;
							address_w = 0;
						end
					end
					OUTPUT: begin

						oSRAM_WE_N = 1;
						oSRAM_OE_N = 0;
						address_w = address_r + PHOTO_SIZE * 4 - 1;
						if(rooted_r) begin
							state_w = S_HALF_W;
						end else begin
							state_w = S_ROOT;
							sqrt_rst_w = 1;
							rooted_w  = 1;
						end

						if(address_r == PHOTO_SIZE * 6 + 1) begin
							// state_w = S_IDLE;
							// address_w = 0;
							// oSRAM_WE_N = 1;
							// oSRAM_OE_N = 1;
							store_g_w = store_g_r + 1;
						end
					end
					default : /* default */;
				endcase
			end
			S_ROOT: begin // wait for root circuit to finish
				if(root_ready) begin
					l_s_std_w = l_s_std;
					a_s_std_w = a_s_std;
					b_s_std_w = b_s_std;
					g_s_std_w = g_s_std;

					l_t_std_w = l_t_std;
					a_t_std_w = a_t_std;
					b_t_std_w = b_t_std;
					g_t_std_w = g_t_std;
					state_w = S_HALF_W;
				end
			end
			S_HALF_W: begin
				sram_wdata = {l_trs, a_trs};
				state_w = S_FULL_W;
				oSRAM_WE_N = 0;
				oSRAM_OE_N = 1;
				address_w = address_r + 1;
				// sqrt_counter_w = 0;
				if(store_g_r == 1) begin
					sram_wdata = g_s_mean;
				end else if(store_g_r == 2) begin
					sram_wdata = g_t_mean;
				end
			end
			// 	if(root_ready) begin
			// 		state_w = S_FULL_W;
			// 		oSRAM_WE_N = 0;
			// 		oSRAM_OE_N = 1;
			// 		address_w = address_r + 1;
			// 		// sqrt_rst_w = 1;

			// 		// sqrt_counter_w = 0;
			// 		if(store_g_r == 1) begin
			// 			sram_wdata = g_s_mean;
			// 		end else if(store_g_r == 2) begin
			// 			sram_wdata = g_t_mean;
			// 		end else begin
			// 			sram_wdata = {l_trs, a_trs};
			// 		end
			// 	end
			// end
			S_FULL_W: begin
				sram_wdata = {b_trs, 8'b0};
				state_w = S_PRE_R;
				oSRAM_WE_N = 0;
				oSRAM_OE_N = 1;
				address_w = address_r - PHOTO_SIZE * 4 + 1;
				// sqrt_counter_w = 0;
				if(store_g_r == 1) begin
					sram_wdata = g_s_std;
					store_g_w = store_g_r + 1; // 1 + 1 = 2
				end else if(store_g_r == 2) begin
					sram_wdata = g_t_mean;
					store_g_w = 0;
					state_w = S_IDLE;
					oSRAM_OE_N = 1;
					oSRAM_WE_N = 1;
					address_w = 0;
				end
			end
			// 	if(root_ready) begin
			// 		state_w = S_PRE_R;
			// 		oSRAM_WE_N = 0;
			// 		oSRAM_OE_N = 1;
			// 		address_w = address_r - PHOTO_SIZE * 4 + 1;
			// 		// sqrt_counter_w = 0;
			// 		if(store_g_r == 1) begin
			// 			sram_wdata = g_s_std;
			// 			store_g_w = store_g_r + 1; // 1 + 1 = 2
			// 		end else if(store_g_r == 2) begin
			// 			sram_wdata = g_t_mean;
			// 			store_g_w = 0;
			// 			state_w = S_IDLE;
			// 			oSRAM_OE_N = 1;
			// 			oSRAM_WE_N = 1;
			// 			address_w = 0;
			// 		end else begin
			// 			sram_wdata = {b_trs, 8'b0};
			// 		end
			// 	end
			// end
			default : /* default */;
		endcase
	end

	always_ff @(posedge clk or negedge rst_n) begin
		if(~rst_n) begin
			// l
			l_s_sum_r   <= 0;
			l_t_sum_r   <= 0;
			l_s_std2_r  <= 0;
			l_t_std2_r  <= 0;
			l_s_std_r   <= 0;
			l_t_std_r   <= 0;
			// a
			a_s_sum_r   <= 0;
			a_t_sum_r   <= 0;
			a_s_std2_r  <= 0;
			a_t_std2_r  <= 0;
			a_s_std_r   <= 0;
			a_t_std_r   <= 0;
			// b
			b_s_sum_r   <= 0;
			b_t_sum_r   <= 0;
			b_s_std2_r  <= 0;
			b_t_std2_r  <= 0;
			b_s_std_r   <= 0;
			b_t_std_r   <= 0;
			//
			now_photo_r <= SOURCE;
			state_r     <= S_IDLE;
			address_r   <= 0;
			buffer_r	<= 0;
			store_g_r   <= 0;
			sqrt_rst_r  <= 0;
			rooted_r	<= rooted_w;
			// sqrt_counter_r <= 0;
		end else begin
			// l
			l_s_sum_r   <= l_s_sum_w;
			l_t_sum_r   <= l_t_sum_w;
			l_s_std2_r  <= l_s_std2_w;
			l_t_std2_r  <= l_t_std2_w;
			l_s_std_r   <= l_s_std_w;
			l_t_std_r   <= l_t_std_w;
			// a
			a_s_sum_r   <= a_s_sum_w;
			a_t_sum_r   <= a_t_sum_w;
			a_s_std2_r  <= a_s_std2_w;
			a_t_std2_r  <= a_t_std2_w;
			a_s_std_r   <= a_s_std_w;
			a_t_std_r   <= a_t_std_w;
			// b
			b_s_sum_r   <= b_s_sum_w;
			b_t_sum_r   <= b_t_sum_w;
			b_s_std2_r  <= b_s_std2_w;
			b_t_std2_r  <= b_t_std2_w;
			b_s_std_r   <= b_s_std_w;
			b_t_std_r   <= b_t_std_w;
			//
			now_photo_r <= now_photo_w;
			state_r		<= state_w;
			address_r	<= address_w;
			buffer_r	<= buffer_w;
			store_g_r	<= store_g_w;
			sqrt_rst_r	<= sqrt_rst_w;
			rooted_r    <= rooted_w;
			// sqrt_counter_r <= sqrt_counter_w;
		end
	end

endmodule
