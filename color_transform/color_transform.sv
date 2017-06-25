// source: photo 0
// target: photo 1
// output: photo 2
// reshape the color distribution of photo 0 to be like photo 1
// i.e. transform photo 0's color to photo 1's

module color_transform (
	input clk,    // Clock
	input rst_n,  // Asynchronous reset active low
	input start_transform,

	// Constant parameter/////
	input [9:0] iCol_Max,
	input [9:0] iRow_Max,


	// SRAM side ///////
	output oSRAM_OE_N,
	output oSRAM_WE_N,
	output oSRAM_ADDR,
	inout  oSRAM_DATA
);

	logic [15:0] sram_wdata;

	logic [19:0] address_r, address_w;

	// static result store
	//// l
	logic [15:0] l_s_sum_r,  l_s_sum_w
	logic [15:0] l_t_sum_r,  l_t_sum_w;
	logic [15:0] l_s_mean,   l_t_mean;
	logic [15:0] l_s_dif2,   l_t_dif2;
	logic [15:0] l_s_std2_r, l_s_std2_w;
	logic [15:0] l_t_std2_r, l_t_std2_w;
	logic [15:0] l_s_std,    l_t_std;
	//// a
	logic [15:0] a_s_sum_r,  a_s_sum_w
	logic [15:0] a_t_sum_r,  a_t_sum_w;
	logic [15:0] a_s_mean,   a_t_mean;
	logic [15:0] a_s_dif2,   a_t_dif2;
	logic [15:0] a_s_std2_r, a_s_std2_w;
	logic [15:0] a_t_std2_r, a_t_std2_w;
	logic [15:0] a_s_std,    a_t_std;
	//// b
	logic [15:0] b_s_sum_r,  b_s_sum_w
	logic [15:0] b_t_sum_r,  b_t_sum_w;
	logic [15:0] b_s_mean,   b_t_mean;
	logic [15:0] b_s_dif2,   b_t_dif2;
	logic [15:0] b_s_std2_r, b_s_std2_w;
	logic [15:0] b_t_std2_r, b_t_std2_w;
	logic [15:0] b_s_std,    b_t_std;
	//// b
	logic [15:0] g_s_sum_r,  g_s_sum_w
	logic [15:0] g_t_sum_r,  g_t_sum_w;
	logic [15:0] g_s_mean,   g_t_mean;
	logic [15:0] g_s_dif2,   g_t_dif2;
	logic [15:0] g_s_std2_r, g_s_std2_w;
	logic [15:0] g_t_std2_r, g_t_std2_w;
	logic [15:0] g_s_std,    g_t_std;

	// logic [19:0] now_photo_start_r, now_photo_start_w;

	logic [31:0] buffer_r, buffer_w;

	logic [1:0]  store_g_r, store_g_w;

	enum STATE{S_IDLE, S_HALF_PRE, S_FULL_PRE, S_WRITE_RES} state_r, state_w;
	enum PHOTO_TYPE{SOURCE, TARGET} now_photo_r, now_photo_w;

	parameter PHOTO_SIZE = iCol_Max * iRow_Max;

	assign oSRAM_DATA = (oSRAM_WE_N)? 16'bz : sram_wdata;

	assign l_s = lab[23:16];
	assign a_s = lab[16:8];
	assign b_s = lab[7:0];
	assign g_s = buffer_r[7:0];
	assign l_t = lab[23:16];
	assign a_t = lab[16:8];
	assign b_t = lab[7:0];
	assign g_t = buffer_r[7:0];

	assign l_s_mean  = (l_s_sum_r << 8) / PHOTO_SIZE;
	assign l_s_dif2  = ((l_s << 8) - l_s_mean) ** 2 / PHOTO_SIZE;
	assign a_s_mean  = (a_s_sum_r << 8) / PHOTO_SIZE;
	assign a_s_dif2  = ((a_s << 8) - a_s_mean) ** 2 / PHOTO_SIZE;
	assign b_s_mean  = (b_s_sum_r << 8) / PHOTO_SIZE;
	assign b_s_dif2  = ((b_s << 8) - b_s_mean) ** 2 / PHOTO_SIZE;
	assign g_s_mean  = (g_s_sum_r << 8) / PHOTO_SIZE;
	assign g_s_dif2  = ((g_s << 8) - g_s_mean) ** 2 / PHOTO_SIZE;

	assign l_t_mean  = (l_t_sum_r << 8) / PHOTO_SIZE;
	assign l_t_dif2  = ((l_t << 8) - l_t_mean) ** 2 / PHOTO_SIZE;
	assign a_t_mean  = (a_t_sum_r << 8) / PHOTO_SIZE;
	assign a_t_dif2  = ((a_t << 8) - a_t_mean) ** 2 / PHOTO_SIZE;
	assign b_t_mean  = (b_t_sum_r << 8) / PHOTO_SIZE;
	assign b_t_dif2  = ((b_t << 8) - b_t_mean) ** 2 / PHOTO_SIZE;
	assign g_t_mean  = (g_t_sum_r << 8) / PHOTO_SIZE;
	assign g_t_dif2  = ((g_t << 8) - g_t_mean) ** 2 / PHOTO_SIZE;

	SQRT rootls (.CLK(clk), .RST(~rst_n), .DATA_IN(l_s_std2_r), .DATA_OUT(l_s_std) );
	SQRT rootas (.CLK(clk), .RST(~rst_n), .DATA_IN(a_s_std2_r), .DATA_OUT(a_s_std) );
	SQRT rootbs (.CLK(clk), .RST(~rst_n), .DATA_IN(b_s_std2_r), .DATA_OUT(b_s_std) );

	SQRT rootlt (.CLK(clk), .RST(~rst_n), .DATA_IN(l_t_std2_r), .DATA_OUT(l_t_std) );
	SQRT rootat (.CLK(clk), .RST(~rst_n), .DATA_IN(a_t_std2_r), .DATA_OUT(a_t_std) );
	SQRT rootbt (.CLK(clk), .RST(~rst_n), .DATA_IN(b_t_std2_r), .DATA_OUT(b_t_std) );

	main_RGB2lab rgb2lab (
		.i_rst(~rst_n),
		.i_R(buffer_r[31:24]),
		.i_G(buffer_r[23:16]),
		.i_B(buffer_r[15:8]),
		.o_l(lab[23:16]),
		.o_a(lab[15:8]),
		.o_b(lab[7:0])
		);

	assign l_trs = (l_s - l_s_mean) * l_t_std / l_s_std + l_t_mean;
	assign a_trs = (a_s - a_s_mean) * a_t_std / a_s_std + a_t_mean;
	assign b_trs = (b_s - g_s_mean) * b_t_std / b_s_std + b_t_mean;
	// assign g_trs = (g_s - b_s_mean) * g_t_std / g_s_std + g_t_mean;

	// control SRAM flow
	always_comb begin
		state_w = state_r;
		address_w = address_r;
		buffer_w = buffer_r;
		now_photo_w = now_photo_r;
		oSRAM_WE_N = 1;
		oSRAM_OE_N = 1;
		store_g_w = store_g_r;

		// s
		l_s_sum_w = l_s_sum_r;
		a_s_sum_w = a_s_sum_r;
		b_s_sum_w = b_s_sum_r;
		g_s_sum_w = g_s_sum_r;

		l_s_std2_w = l_s_std2_r;
		a_s_std2_w = a_s_std2_r;
		b_s_std2_w = b_s_std2_r;
		g_s_std2_w = g_s_std2_r;
		
		// t
		l_t_sum_w = l_t_sum_r;
		a_t_sum_w = a_t_sum_r;
		b_t_sum_w = b_t_sum_r;
		g_t_sum_w = g_t_sum_r;

		l_t_std2_w = l_t_std2_r;
		a_t_std2_w = a_t_std2_r;
		b_t_std2_w = b_t_std2_r;
		g_t_std2_w = g_t_std2_r;

		case (state_r)
			S_IDLE: begin
				if(start_transform) begin
					state_w = S_HALF_PRE;
					address_w = 0; // start with photo num 0
					oSRAM_OE_N = 0;
					oSRAM_WE_N = 1;
					now_photo_w = SOURCE;
				end
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
						l_s_sum_w = l_s_sum_r + lab[23:16];
						a_s_sum_w = a_s_sum_r + lab[15:8];
						b_s_sum_w = b_s_sum_r + lab[7:0];
						g_s_sum_w = g_s_sum_r + buffer_r[7:0];
					end
					TARGET: begin
						l_t_sum_w = l_t_sum_r + lab[23:16];
						a_t_sum_w = a_t_sum_r + lab[15:8];
						b_t_sum_w = b_t_sum_r + lab[7:0];
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
						end						
					end
					STD_T: begin
						oSRAM_WE_N = 1;
						oSRAM_OE_N = 0;
						address_w = address_r + 1;
						state_w = S_HALF_R;
						if( address_r == PHOTO_SIZE * 4 + 1) begin
							now_photo_w = OUTPUT;
							address_w = 0;
						end						
					end
					OUTPUT: begin
						oSRAM_WE_N = 0;
						oSRAM_OE_N = 1;
						address_w = address_r + PHOTO_SIZE * 4 - 1;
						state_w = S_HALF_W;
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
			S_HALF_W: begin
				sram_wdata = {l_trs, a_trs};
				oSRAM_WE_N = 0;
				oSRAM_OE_N = 1;
				address_w = address_r + 1;
				if(store_g_r == 1) begin
					sram_wdata = g_s_mean;
				end else if(store_g_r == 2) begin
					sram_wdata = g_t_mean;
				end
			end
			S_FULL_W: begin
				sram_wdata = {b_trs, g_trs};
				state_w = S_HALF_R;
				oSRAM_WE_N = 0;
				oSRAM_OE_N = 1;
				address_w = address_r - PHOTO_SIZE * 4 + 1;
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
			// a
			a_s_sum_r   <= 0;
			a_t_sum_r   <= 0;
			a_s_std2_r  <= 0;
			a_t_std2_r  <= 0;
			// b
			b_s_sum_r   <= 0;
			b_t_sum_r   <= 0;
			b_s_std2_r  <= 0;
			b_t_std2_r  <= 0;
			//
			now_photo_r <= 0;
			state_r     <= 0;
			address_r   <= 0;
			buffer_r	<= 0;
			store_g_r   <= 0;
		end else begin
			// l
			l_s_sum_r   <= l_s_sum_w;
			l_t_sum_r   <= l_t_sum_w;
			l_s_std2_r  <= l_s_std2_w;
			l_t_std2_r  <= l_t_std2_w;
			// a
			a_s_sum_r   <= a_s_sum_w;
			a_t_sum_r   <= a_t_sum_w;
			a_s_std2_r  <= a_s_std2_w;
			a_t_std2_r  <= a_t_std2_w;
			// b
			b_s_sum_r   <= b_s_sum_w;
			b_t_sum_r   <= b_t_sum_w;
			b_s_std2_r  <= b_s_std2_w;
			b_t_std2_r  <= b_t_std2_w;
			//
			now_photo_r <= now_photo_w;
			state_r		<= state_w;
			address_r	<= address_w;
			buffer_r	<= buffer_w;
			store_g_r	<= store_g_w;
		end
	end

endmodule
