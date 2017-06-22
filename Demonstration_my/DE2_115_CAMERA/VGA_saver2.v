// Connect to VGA's side of SDRam. store RGB, each with 10 bits
// usage description



module VGA_saver (
	//========= Basic ========================//
	iCLK,    // Clock = VGA's clock
	iRST_N,  // Asynchronous reset active low

	//========= Setting ======================//
	iCol_MAX, // Photo width
	iRow_MAX, // Photo height

	//========= Take Photo ===================//
	iTake_frame, // Take this frame if 1

	//========= VGA side =====================//
	iRGB,
	iVGA_Read,
	iVGA_VSYNC_N,
	iVGA_HSYNC_N,
	
	//========= Read side ====================//
	iRead_Intern, // request for pixels stored in SRam
	iRead_Disp, // request for pixels stored in SRam, and fed to VGA
	iPhoto_Index, // Index of stored photo, start from 0
	iRead_Col,
	iRead_Row,
	oRGB_half, // output RGB for specify (col, row), in {R, G, B}
	oRGB_full,

	//========= SRam side ====================//
	oSRAM_Addr, // 20 bits
	oSRAM_Data, // 16 bits
	oSRAM_CE_N,
	oSRAM_UB_N,
	oSRAM_LB_N,
	oSRAM_OE_N,
	oSRAM_WE_N,

	//========= Debug info ===================//
	oState,
	oSram_buffer,
	ostore_finish
);

	//========= Basic ========================//
	input iCLK;    // Clock = VGA's clock
	input iRST_N;  // Asynchronous reset active low

	//========= Setting ======================//
	input [9:0] iCol_MAX; // Photo width
	input [9:0] iRow_MAX; // Photo height

	//========= Take Photo ===================//
	input iTake_frame; // Take this frame if 1

	//========= VGA side =====================//
	input [29:0] iRGB;
	input iVGA_Read;
	input iVGA_VSYNC_N;
	input iVGA_HSYNC_N;
	
	//========= Read side ====================//
	input iRead_Intern; // read from SRAM for internal usage
	input iRead_Disp; // fed VGA with VGA_saver instead of SDRam when 1
	input [3:0] iPhoto_Index; // Index of stored photo, start from 0
	input [9:0] iRead_Col;
	input [9:0] iRead_Row;
	output [15:0] oRGB_half; // output RGB for specify (col, row), in {R, G, B}
	output [29:0] oRGB_full;

	//========= SRam side ====================//
	output [19:0] oSRAM_Addr;
	inout  [15:0] oSRAM_Data;
	output oSRAM_CE_N;
	output oSRAM_UB_N;
	output oSRAM_LB_N;
	output oSRAM_OE_N;
	output oSRAM_WE_N;
	//========= Debug info ===================//
	output [3:0] oState;
	output [15:0] oSram_buffer;
	output ostore_finish;

	reg pre_iVGA_VSYNC_N_r, pre_iVGA_VSYNC_N_w;
	reg pre_iVGA_HSYNC_N_r, pre_iVGA_HSYNC_N_w;
	reg pre_iTake_Frame_r, pre_iTake_Frame_w;

	reg [29:0] RGB_full_r, RGB_full_w;

	reg [15:0] sram_buffer_r, sram_buffer_w;
	reg [19:0] sram_address_r, sram_address_w;
	// reg [15:0] sram_data_in, sram_data_out; // sram_data_in: read from sram, sram_data_out: write sram
	reg [15:0] sram_data_out; // oSRAM_Data: read from sram, sram_data_out: write sram

	reg [2:0]  state_r, state_w;
	reg [1:0]  read_0_prefetched_r, read_0_prefetched_w; // _prefetched_r = 2: already read out complete RGB for pixel(0, 0)
	reg        store_finish_r, store_finish_w; // prevent overwrite the stored image
	reg		   row_valid_r, row_valid_w;

	//state
	parameter S_IDLE     	= 3'd0;
	parameter S_ACTIVE_W 	= 3'd1;
	parameter S_WH			= 3'd2;
	parameter S_WF  		= 3'd3;
	parameter S_ACTIVE_R  	= 3'd4;
	parameter S_RH  	 	= 3'd5;
	parameter S_RF 		  	= 3'd6;
	// parameter S_RHold 		= 3'd7;

	assign oRGB_full = RGB_full_r;
	assign oState = {1'b0, state_r};
	assign oSram_buffer = sram_buffer_r;

	assign oSRAM_Data = (state_r == S_WH || state_r == S_WF)? sram_data_out : 16'bz;
	assign oSRAM_Addr = sram_address_r;
	assign oSRAM_WE_N = ~(state_r == S_WH || state_r == S_WF);
	assign oSRAM_OE_N = (state_r == S_WH || state_r == S_WF);

	assign ostore_finish = store_finish_r;

	//// chip specifiction
	assign oSRAM_CE_N = 0; //sram chip select always enable
	assign oSRAM_UB_N = 0; //upper byte always available
	assign oSRAM_LB_N = 0; //lower byte always available

	// FSM
	always @(*) begin
		// default
		sram_address_w = sram_address_r;
		pre_iVGA_VSYNC_N_w = iVGA_VSYNC_N; // for VSYNC edge detect
		pre_iVGA_HSYNC_N_w = iVGA_HSYNC_N; // for HSYNC edge detect
		pre_iTake_Frame_w = iTake_frame;
		read_0_prefetched_w = read_0_prefetched_r;
		sram_address_w = sram_address_r;
		sram_data_out = 0;
		state_w = state_r;
		RGB_full_w = RGB_full_r;
		sram_buffer_w = sram_buffer_r;
		store_finish_w = store_finish_r;
		row_valid_w = row_valid_r;

		case (state_r)
			S_IDLE: begin
				// sram_address_w = 0;
				sram_address_w = (iPhoto_Index * iCol_MAX * iRow_MAX) * 2 // size of a picture
							     + (iRead_Row * iCol_MAX + iRead_Col) * 2;
				row_valid_w = 1;

				if(~pre_iTake_Frame_r & ~iTake_frame) // neg edge
					store_finish_w = 0;
				if(iTake_frame & ~iVGA_VSYNC_N & ~store_finish_r) begin
					state_w = S_ACTIVE_W;
				end
				else if((iRead_Intern | iRead_Disp) & ~iVGA_VSYNC_N) begin
					state_w = S_ACTIVE_R;
					read_0_prefetched_w = 0; // not prefetched pixel(0, 0) yet
				end
				else begin
					state_w = S_IDLE;
				end
			end
//============ write =========================//
			S_ACTIVE_W: begin // wait until iVGA_Read
				// sram addr stay
				if(iVGA_Read & row_valid_r) begin
					state_w = S_WH;
				end
				else if(pre_iVGA_VSYNC_N_r & ~iVGA_VSYNC_N) begin // VSYNC_N neg edge detection
					state_w = S_IDLE;
					store_finish_w = 1;
				end
				else if(pre_iVGA_HSYNC_N_r & ~iVGA_HSYNC_N) begin
					row_valid_w = ~row_valid_r;
				end
				else
					state_w = S_ACTIVE_W;
			end
			S_WH: begin // WE_N = 0 for the exact state that write to SRAM
				state_w = S_WF;
				sram_data_out = {iRGB[29:22], iRGB[19:12]};
				sram_buffer_w = {iRGB[9:2], 8'd0};
				sram_address_w = sram_address_r + 1;
			end
			S_WF: begin // WE_N = 0 for the exact state that write to SRAM
				if(iVGA_Read) begin
					state_w = S_WH;
				end
				else begin
					state_w = S_ACTIVE_W; // row finish, go wait for valid row begin
				end
				sram_data_out = sram_buffer_r;
				sram_address_w = sram_address_r + 1;
			end

//============ read =========================//
			S_ACTIVE_R: begin
				if(iVGA_Read && read_0_prefetched_r) begin // need wait until pixel(0, 0) prefetched finish
					state_w = S_RF;
				end
				else if(pre_iVGA_VSYNC_N_r & ~iVGA_VSYNC_N) begin // VSYNC_N neg edge detection
					state_w = S_IDLE;
					read_0_prefetched_w = 0;
				end
				else
					state_w = S_ACTIVE_R;
				if(read_0_prefetched_r == 0) begin
					sram_buffer_w = oSRAM_Data;
					sram_address_w = sram_address_r + 1;
					read_0_prefetched_w = 1;
				end
			end
			S_RF: begin // got full of pixel(1, 0)
				// if(iVGA_Read) begin
				state_w = S_RH;
				RGB_full_w = {sram_buffer_r[15:8], 2'b00, sram_buffer_r[7:0], 2'b00, oSRAM_Data[15:8], 2'b00};
				sram_address_w  = sram_address_r + 1;
				// end
			end
			S_RH: begin // got full pixel(1, 0) and output to VGA
				if(iVGA_Read) begin
					// RGB_full_w = RGB_full_r;
					sram_buffer_w = oSRAM_Data;
					state_w = S_RF;
					sram_address_w = sram_address_r + 1;
				end else if(iVGA_VSYNC_N) begin // back to S_ACTIVE_R here, for even pixel in a row
					row_valid_w = ~row_valid_r;
					if(~row_valid_r) sram_address_w = sram_address_r - iCol_MAX * 2;
					state_w = S_ACTIVE_R;
					read_0_prefetched_w = 0;
				end
				else
					state_w = S_IDLE;
			end

			default : /* default */;
		endcase
	end

	always @(posedge iCLK or negedge iRST_N) begin
		if(~iRST_N) begin
			pre_iVGA_VSYNC_N_r <= 0;
			pre_iVGA_HSYNC_N_r <= 0;
			sram_buffer_r <= 0;
			sram_address_r <= 0;
			state_r <= 0;
			read_0_prefetched_r <= 0;
			RGB_full_r <= 0;
			store_finish_r <= 0;
			row_valid_r <= 1;
		end else begin
			pre_iVGA_VSYNC_N_r <= pre_iVGA_VSYNC_N_w;
			pre_iVGA_HSYNC_N_r <= pre_iVGA_HSYNC_N_w;
			sram_buffer_r <= sram_buffer_w;
			sram_address_r <= sram_address_w;
			state_r <= state_w;
			read_0_prefetched_r <= read_0_prefetched_w;
			RGB_full_r <= RGB_full_w;
			store_finish_r <= store_finish_w;
			row_valid_r <= row_valid_w;
		end
	end

endmodule // VGA_saver