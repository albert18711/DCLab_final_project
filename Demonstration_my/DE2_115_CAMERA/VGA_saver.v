// Connect to VGA's side of SDRam. store RGB, each with 10 bits
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
	iVGA_VSYNC,
	
	//========= Read side ====================//
	iRead_Intern, // request for pixels stored in SRam
	iRead_Disp, // request for pixels stored in SRam
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
	oState
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
	input [23:0] iRGB;
	input iVGA_Read;
	input iVGA_VSYNC;
	
	//========= Read side ====================//
	input iRead_Disp; // request for pixels stored in SRam
	input [3:0] iPhoto_Index; // Index of stored photo, start from 0
	input [9:0] iRead_Col;
	input [9:0] iRead_Row;
	output [15:0] oRGB_half; // output RGB for specify (col, row), in {R, G, B}
	output [29:0] oRGB_full;

	//========= SRam side ====================//
	output [19:0] oSRAM_Addr;
	output [15:0] oSRAM_Data;
	output oSRAM_CE_N;
	output oSRAM_UB_N;
	output oSRAM_LB_N;
	output reg oSRAM_OE_N;
	output reg oSRAM_WE_N;
	//========= Debug info ===================//
	output oState;

	///////////////////////////////////////////
	//========= reg and wire ================//
	wire [9:0] col_max, rol_max;
	wire [19:0] address_max;

	reg [15:0] RGB_buffer_r, RGB_buffer_w;

	reg [19:0] sram_address_r, sram_address_w;
	reg [15:0] sram_data_in, sram_data_out; // sram_data_in: read from sram, sram_data_out: write sram

	reg [15:0] reg_RGB_half;

	reg [23:0] RGB_full_r, RGB_full_w;

	// typedef enum {S_IDLE, S_ACTIVE, S_WAIT_VALID, S_WRITE_0, S_WRITE_1, S_READ_0, S_READ_1} STATE;
	// STATE state_r, state_w;
	//state
	parameter S_IDLE     	= 3'd0;
	parameter S_ACTIVE 		= 3'd1;
	parameter S_WAIT_VALID	= 3'd2;
	parameter S_WRITE_0  	= 3'd3;
	parameter S_WRITE_1  	= 3'd4;
	parameter S_READ_0   	= 3'd5;
	parameter S_READ_1   	= 3'd6;

	reg [2:0] state_r, state_w;

	///////////////////////////////////////////
	//========= Comb part ===================//
	// parameters
	// assign col_max = iCol_MAX;
	// assign row_max = iRow_MAX;
	assign sram_addr_max = iCol_MAX * iRow_MAX * 3 * 10; // not quite shure...

	// FSM
	always @(*) begin
		case (state_r)
			S_IDLE: begin
				if(iTake_frame)      state_w = S_ACTIVE_W;
				else if(iRead_Disp || iRead_Intern) state_w = S_ACTIVE_R;
				else 				 state_w = S_IDLE;
			end
			S_ACTIVE_W: begin
				if(~iVGA_VSYNC)		 state_w = S_WAIT_VALID_W; // finish printing the whole frame
			end
			S_WAIT_VALID_W: begin
				if(~iVGA_VSYNC) 	 state_w = S_IDLE; // finish writing the whole graph
				else 				 state_w = S_WRITE_0;
			end
			S_WRITE_0:				 state_w = S_WRITE_1; // write RG
			S_WRITE_1:				 state_w = S_WAIT_VALID; // write B
			S_ACTIVE_R: begin
				if(~iVGA_VSYNC)		 state_w = S_WAIT_VALID_R; // finish printing the whole frame
			end
			S_WAIT_VALID_R: begin
				if(~iVGA_VSYNC) 	 state_w = S_IDLE; // finish the whole graph
				else 				 state_w = S_READ_0;
			end
			S_READ_0:				 state_w = S_READ_1; // read RG
			S_READ_1: 				 state_w = S_WAIT_VALID; // read B
			default : /* default */;
		endcase
	end

	// SRam control

	//// chip specifiction
	assign oSRAM_CE_N = 0; //sram chip select always enable
	assign oSRAM_UB_N = 0; //upper byte always available
	assign oSRAM_LB_N = 0; //lower byte always available
	
	//// inout port handle
	assign oSRAM_Data = (state_r == S_WRITE_0 || state_r == S_WRITE_1)? sram_data_out : 16'bz;
	
	//// SRAM address
	assign oSRAM_Addr = sram_address_r;
	always @(*) begin
		sram_address_w = sram_address_r;
		if(state_r == S_IDLE) begin
			if(iRead_Pixel) begin
				sram_address_w = (iPhoto_Index * iCol_MAX * iRow_MAX * 2) // size of a picture
							     + (iRead_Row * iCol_MAX + iRead_Col) * 2;
			end
		end
		else if(state_r == S_ACTIVE) begin // get data from sram after 2 cycles
			sram_address_w = sram_address_r + 1;
		end
		else if(state_r == S_WAIT_VALID) begin
			if(iRead_Pixel) begin
				sram_address_w = sram_address_r + 1;
			end
		end
		else if(state_r == S_WRITE_0) begin
			sram_address_w = sram_address_r + 1;
		end
	end

	//// RGB_buffer
	always @(*) begin
		RGB_buffer_w = RGB_buffer_r;
		if(state_r == S_WRITE_0) begin
			RGB_buffer_w = {8'b0, iRGB[7:0]};
		end
		else if(state_r == S_READ_0) begin
			RGB_buffer_w = sram_data_in;
		end
		else if(state_r == S_READ_1) begin
			RGB_full_w = {RGB_buffer_r[15:8], 2'b0, RGB_buffer_r[7:0], 2'b0, sram_data_in[7:0], 2'b0};
		end	
	end

	//// write
	always@ (*) begin //write enable
		oSRAM_WE_N = 1;
		if(!iRST_N) oSRAM_WE_N = 1;
	    else case(state_r)
			// S_WAIT_VALID: begin 
	  //           if(iVGA_Read)   	 oSRAM_WE_N = 0;
	  //           else				 oSRAM_WE_N = 1;
			// end
			S_WRITE_0: 				 oSRAM_WE_N = 0;
			S_WRITE_1: 				 oSRAM_WE_N = 0;
			default: 				 oSRAM_WE_N = 1;
		endcase
	end
	always @(*) begin
		sram_data_out = 0;
		// RGB_buffer_w = RGB_buffer_r;
		if(state_r == S_WRITE_0) begin
			// RGB_buffer_w = iRGB[29:16];
			sram_data_out = iRGB[23:8];
		end
		else if(state_r == S_WRITE_1) begin
			sram_data_out = RGB_buffer_r;
		end
	end
	
	//// read
	// assign oSRAM_Addr = iRead_Row * iCol_MAX + iRead_Col;
	assign oRGB_half = reg_RGB_half;
	// always@ (*) begin //read enable
	// 	if(!iRST_N)					oSRAM_OE_N = 1;
	// 	else if(state_r == S_IDLE && iRead_Pixel)
	// 								oSRAM_OE_N = 0;
	//     else if(state_r == S_READ_0 || state_r == S_READ_1)
	//     							oSRAM_OE_N = 0;
	// 	else						oSRAM_OE_N = 1;
	// end
	always @(*) begin
		oSRAM_OE_N = ~(iRead_Pixel);
	end
	always @(*) begin // RGB_half
		if(state_r == S_READ_0 || state_r == S_READ_1) begin
			reg_RGB_half = sram_data_in;
		end
	end
	always @(*) begin // RGB_full
		// RGB_buffer_w = RGB_buffer_r;
		RGB_full_w = RGB_full_r;
		// if(state_r == S_READ_0) begin
			// RGB_buffer_w = sram_data_in;
		// end
		if(state_r == S_READ_1) begin
			RGB_full_w = {RGB_buffer_r, sram_data_in};
		end	
	end


	///////////////////////////////////////////
	//========= Seq part ====================//
	always @(posedge iCLK or negedge iRST_N) begin
		if(~iRST_N) begin
			RGB_buffer_r <= 0;
			sram_address_r <= 0;
			RGB_full_r <= 0;
		end else begin
			RGB_buffer_r <= RGB_buffer_w;
			sram_address_r <= sram_address_w;
			RGB_full_r <= RGB_full_w;
		end
	end
endmodule