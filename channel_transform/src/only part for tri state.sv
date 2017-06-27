// sub part for tri state wire handle
logic SRAM_WE_N_reg;
logic SRAM_OE_N_reg;
logic SRAM_ADDR_reg;

logic sram_in;
// VGA saver
logic to_sram_VGA, from_sram_VGA;
logic sram_we_n_VGA, sram_oe_n_VGA;
logic [19:0] sram_addr_VGA;
// color transfer
logic to_sram_COL, from_sram_COL;
logic sram_we_n_COL, sram_oe_n_COL;
logic [19:0] sram_addr_COL;
// text transfer
logic to_sram_TEXT, from_sram_TEXT;
logic sram_we_n_TEXT, sram_oe_n_TEXT;
logic [19:0] sram_addr_TEXT;

assign SRAM_WE_N = SRAM_WE_N_reg;
assign SRAM_OE_N = SRAM_OE_N_reg;
assign SRAM_ADDR = SRAM_ADDR_reg;

assign SRAM_DQ = (~SRAM_WE_N)? sram_in : 16'bz;

always @(*) begin
	case (state_r)
		S_DISPLAY: begin
			SRAM_WE_N_reg = sram_we_n_VGA;
			SRAM_OE_N_reg = sram_oe_n_VGA;
			SRAM_ADDR_reg = sram_addr_VGA;
			if(~SRAM_WE_N) begin
				sram_in = to_sram_VGA;
			end else begin
				from_sram_VGA = SRAM_DQ;
			end
		end
		S_COLOR_TRANSFER: begin
			SRAM_WE_N_reg = sram_we_n_COL;
			SRAM_OE_N_reg = sram_oe_n_COL;
			SRAM_ADDR_reg = sram_addr_COL;
			if(~SRAM_WE_N) begin
				sram_in = to_sram_COL;
			end else begin
				from_sram_COL = SRAM_DQ;
			end
		end
		S_TEXTURE_TRANSFER: begin
			SRAM_WE_N_reg = sram_we_n_TEXT;
			SRAM_OE_N_reg = sram_oe_n_TEXT;
			SRAM_ADDR_reg = sram_addr_TEXT;
			if(~SRAM_WE_N) begin
				sram_in = to_sram_TEXT;
			end else begin
				from_sram_TEXT = SRAM_DQ;
			end
		end
		default : /* default */;
	endcase
end

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

		// .SRAM_DQ(SRAM_DQ),						// SRAM data: read and write
		.SRAM_data_in(from_sram_TEXT),
		.SRAM_data_out(to_sram_TEXT),
		.o_SRAM_ADDR(sram_addr_TEXT),				// SRAM address
		.o_SRAM_OE(sram_oe_n_TEXT),					// 0 -> read in from SRAM; 1 -> not read;
		.o_SRAM_WE(sram_we_n_TEXT),					// SRAM enable, 0 -> write
		
		.o_finish(finish_w),									// Finish all
		.o_finish_row(finish_row_w),							// Finish each row
		.o_finish_pixel(finish_pixel_w),						// Finish one RES pixel 
		.o_finish_random_init(finish_random_init_w),			// Finish Atlas random initialization
		.o_state(state_debug),

		.o_global_counter(global_counter_w)			// Check computation time
	);

	VGA_saver 		vgaSaver (
		//========= Basic ========================//
		.iCLK(VGA_CTRL_CLK),    // Clock = VGA's clock
		// .iRST_N(KEY[0]),  // Asynchronous reset active low
		.iRST_N(~SW[0]),  // Asynchronous reset active low

		//========= Setting ======================//
		.iCol_MAX(400), // Photo width
		.iRow_MAX(300), // Photo height, same. since every row would store
						// half of VGA's size
		//========= Take Photo ===================//
		// .iTake_frame(SW[3]), // Take this frame if 1
		.iTake_frame(SW[1]), // Take this frame if 1

		//========= VGA side =====================//
		.iRGB(RGB_bus),
		.iVGA_Read(Read),
		.iVGA_VSYNC_N(w_VGA_VS),
		.iVGA_HSYNC_N(w_VGA_HS),
		
		//========= Read side ====================//
		.iRead_Intern(SW[4]), // read from SRAM for internal usage
		.iRead_Disp(SW[5]), // fed VGA with VGA_saver instead of SDRam when 1
		.iPhoto_Index(SW[6]), // Index of stored photo, first photo = #0
		.iRead_Col(0),
		.iRead_Row(0),
		.oRGB_half(), // output RGB for specify (col, row), in {R, G, B}
		.oRGB_full(sRGB_full), // return RGB all once, but stay same for one clock
					   		   // (since need two cycles to get all 30bits RGB)	
		//========= SRam side ====================//
		.oSRAM_Addr(sram_addr_VGA), // 20 bits
		// .oSRAM_Data(SRAM_DQ), // 16 bits
		.iSRAM_In(from_sram_VGA),
		.oSRAM_Out(to_sram_VGA),
		.oSRAM_CE_N(SRAM_CE_N),
		.oSRAM_UB_N(SRAM_UB_N),
		.oSRAM_LB_N(SRAM_LB_N),
		.oSRAM_OE_N(sram_oe_n_VGA),
		.oSRAM_WE_N(sram_we_n_VGA),

		//========= Debug info ===================//
		.oState(VGAsaver_state),
		.oSram_buffer(VGAsaver_buffer),
		.ostore_finish(store_finish)
	);