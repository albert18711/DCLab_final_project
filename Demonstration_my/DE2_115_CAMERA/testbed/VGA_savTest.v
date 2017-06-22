`timescale 1 ns/10 ps
`define CYCLE 10
`define	H_CYCLE  5

module VGA_savTest;

logic VGA_CTRL_CLK;
logic DLY_RST_2;
logid SW_16;
logic Read;
// logic [15:0] Read_DATA1, Read_DATA2;
logic [29:0] RGB_bus;
logic [9:0]  oVGA_R, oVGA_G, oVGA_B;
logic VGA_HS, VGA_VS, VGA_SYNC_N, VGA_BLANK_N;
logic [12:0] H_Cont, V_Cont;
logic [29:0] sRGB_full;

logic KEY_3;

//fed to VGA_saver
// assign  RGB_bus = {ReadData2[9:0], ReadData1[14:10], ReadData2[14:10], ReadData1[9:0]};

VGA_Controller		u1	(	//	Host Side
							.oRequest(Read),
							.iRed(RGB_bus[29:20]),
							.iGreen(RGB_bus[19:10]),
							.iBlue(RGB_bus[9:0]),
							//	VGA Side
							.oVGA_R(oVGA_R),
							.oVGA_G(oVGA_G),
							.oVGA_B(oVGA_B),
							.oVGA_H_SYNC(VGA_HS),
							.oVGA_V_SYNC(VGA_VS),
							.oVGA_SYNC(VGA_SYNC_N),
							.oVGA_BLANK(VGA_BLANK_N),
							//	Control Signal
							.iCLK(VGA_CTRL_CLK),
							.iRST_N(DLY_RST_2),
							.iZOOM_MODE_SW(SW_16),
							//  Pixel Counter
							.oH_Cont(H_Cont),
							.oV_Cont(V_Cont)
						);

VGA_saver 			vgaSaver (
							//========= Basic ========================//
							.iCLK(VGA_CTRL_CLK),    // Clock = VGA's clock
							.iRST_N(DLY_RST_2),  // Asynchronous reset active low

							//========= Setting ======================//
							.iCol_MAX(320), // Photo width
							.iRol_MAX(240), // Photo height
											// half of VGA's size
							//========= Take Photo ===================//
							.iTake_frame(KEY_3), // Take this frame if 1

							//========= VGA side =====================//
							.iRGB(RGB_bus),
							.iVGA_Read(Read),
							.iVGA_VSYNC(VGA_SYNC_N),
							
							//========= Read side ====================//
							.iRead_Pixel(SW_3), // fed VGA with VGA_saver instead of SDRam when 1
							.iPhoto_Index(0), // Index of stored photo, first photo = #0
							.iRead_Col(H_Cont),
							.iRead_Row(V_Cont),
							.oRGB_half(), // output RGB for specify (col, row), in {R, G, B}
							.oRGB_full(sRGB_full), // return RGB all once, but stay same for one clock
										   		   // (since need two cycles to get all 30bits RGB)	
							//========= SRam side ====================//
							.oSRAM_Addr(SRAM_ADDR), // 20 bits
							.oSRAM_Data(SRAM_DQ), // 16 bits
							.oSRAM_CE_N(SRAM_CE_N),
							.oSRAM_UB_N(SRAM_UB_N),
							.oSRAM_LB_N(SRAM_LB_N),

							//========= Debug info ===================//
							.oState()
						);

	always begin
		#`H_CYCLE VGA_CTRL_CLK = ~VGA_CTRL_CLK;
	end

	initial begin
		$dumpfile("VGA_saver.vcd");
		$dumpvars;

		VGA_CTRL_CLK = 0;

	end

endmodule