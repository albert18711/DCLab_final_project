// Top: integrate initialization of WM through I2C protocol, recording sound,
//		  playing at different speeds, and stopping and pausing playing
 
// TODO: 1. I/O can be modified

// NOTE: 
// Player ans Recorder are active only when start_w signal remains high,
// so the terminating condition should be finish_w. That is, if finish_w
// is raised then start_w should be down. 
module Top(
	input i_start, 		// KEY[3], after debounce
	input i_stop,
	input i_up,				// For speed
	input i_down, 			// KEY[0]
	input ADCLRCK,
	input ADCDAT,
	input DACLRCK,
	input i_bclk, 			//BCLK
	input i_i2cclk, 		//100kHz for i2c
	input i_rst, 		
	input i_switch, 		// 0: record, 1: play, SW01
	input i_intpol, 		// 0 or 1 order, SW02

	inout I2C_SDAT,
	inout [15:0] SRAM_DQ,

	output I2C_SCLK,
	output [19:0] SRAM_ADDR,
	output SRAM_CE_N,
	output SRAM_OE_N,
	output SRAM_WE_N,
	output SRAM_UB_N,
	output SRAM_LB_N,
	output DACDAT,
	
	output [4:0] o_timer,
	output [2:0] o_state,
	output [1:0] o_speedStat,
	output [3:0] o_speed,
	output [1:0] o_ini_state,
	output [1:0] o_rec_state,
	output [2:0] o_play_state,
	output [3:0] o_speedtoDAC,
	
	// For warning display
	output speedWarning
	
	
);


	enum { S_INIT, S_IDLE, S_PLAY, S_RECORD, S_PAUSE } state_r, state_w;
	enum { S_NORMAL, S_FAST, S_SLOW } speed_state_r, speed_state_w;
	
	logic startI_r, startI_w;		// For I2C 
	logic finishI_r, finishI_w;
	logic startR_r, startR_w; 		// For Recorder
	logic finishR_r, finishR_w;
	logic startP_r, startP_w;		// For Player
	logic finishP_r, finishP_w;
	logic [3:0] speed_r, speed_w;					// 1 is normal, else depending on speed_state_r to 
															// see whether it is fast or slow (speed_r) times
							
	logic [3:0] speed_minus_1;
	logic [3:0] speedtoDAC;
	logic [19:0] playPos_r, playPos_w; 			// Record the address of playing
	logic [19:0] maxRecPos_r, maxRecPos_w;		// Record the maximal address of recording
	logic [19:0] p_addr, r_addr;
	logic speedWarning_w;
	logic[15:0] p_data, r_data;
	
	assign speed_minus_1 = speed_r - 1;			// For player format
	assign speedtoDAC = {speed_state_r[1], speed_minus_1[2:0]};
	assign speedWarning = speedWarning_w;
	assign o_timer = (state_r == S_PLAY)? playPos_r[19:15]:((state_r == S_RECORD)? maxRecPos_r[19:15]: playPos_r[19:15]); 				//	For displaying the progress of playing
	assign o_state = state_r;
	assign o_speedStat = speed_state_r;
	assign o_speed = speed_r;
	assign SRAM_CE_N = 0;
	assign SRAM_UB_N = 0;
	assign SRAM_LB_N = 0;
	assign SRAM_ADDR = (state_r == S_PLAY)? p_addr : r_addr;
	assign SRAM_DQ = (state_r == S_PLAY)? 16'bz : r_data;
	assign p_data = (state_r == S_PLAY)? SRAM_DQ : 16'bz;
	assign o_speedtoDAC = speedtoDAC;

	I2CManager i2cM(
		.i_start(startI_r),
		.i_clk(i_i2cclk),
		.i_rst(i_rst),
		.o_finish(finishI_w),
		.o_sclk(I2C_SCLK),
		.o_sdat(I2C_SDAT),
		.o_i2cm_state(o_ini_state)
	);

	Recorder adc(
		.i_record_start(startR_r),
		.i_ADCLRCK(ADCLRCK),
		.i_ADCDAT(ADCDAT),
		.i_BCLK(i_bclk),
		.o_SRAM_WE(SRAM_WE_N),
		.o_SRAM_DATA(r_data),
		.finish(finishR_w),
		.o_SRAM_ADDR(r_addr),
		.o_REC_STATE(o_rec_state)
	);

	
/*
	
	Player_ref dac(
		.i_play(startP_r),
		.i_start_pos(playPos_r),
		.i_end_pos(maxRecPos_r),
		//.i_play_mode(speedtoDAC),
	.i_speed(speedtoDAC),
		.i_DACLRCK(DACLRCK),
		.i_BCLK(i_bclk),
		.i_SRAM_DATA(p_data),
		//.i_interpolate_order(i_intpol),
	.i_intpol(i_intpol),
		.o_SRAM_OE(SRAM_OE_N),
		.o_SRAM_ADDR(p_addr),
		.o_DACDAT(DACDAT),
		//.o_finish(finishP_w),
	.o_done(finishP_w),
		.o_state(o_play_state)
		
	// add an input to determine whether 0 or 1 order interpolation is used 
	//	.(...)(i_intpol)
	
	);
*/


	Player dac(
		.i_play(startP_r),
		.i_start_pos(playPos_r),
		.i_end_pos(maxRecPos_r),
		.i_play_mode(speedtoDAC),
	//.i_speed(speedtoDAC),
		.i_DACLRCK(DACLRCK),
		.i_BCLK(i_bclk),
		.i_SRAM_DATA(p_data),
		.i_interpolate_order(i_intpol),
	//.i_intpol(i_intpol),
		.o_SRAM_OE(SRAM_OE_N),
		.o_SRAM_ADDR(p_addr),
		.o_DACDAT(DACDAT),
		.o_finish(finishP_w),
	//.o_done(finishP_w),
		.o_state(o_play_state)
		
	// add an input to determine whether 0 or 1 order interpolation is used 
	//	.(...)(i_intpol)
	
	);


	
	always_ff @ (posedge i_bclk) begin

		if(i_rst) begin
			state_r <= S_INIT;
			speed_state_r <= S_NORMAL;
			startI_r <= 0;
			finishI_r <= 0;
			startP_r <= 0;
			finishP_r <= 0;
			startR_r <= 0;
			finishR_r <= 0;
			speed_r <= 1;
			playPos_r <= 0;
			maxRecPos_r <= 0;
		end
		else begin
			state_r <= state_w;
			speed_state_r <= speed_state_w;
			startI_r <= startI_w;
			finishI_r <= finishI_w;
			startP_r <= startP_w;
			finishP_r <= finishP_w;
			startR_r <= startR_w;
			finishR_r <= finishR_w;
			speed_r <= speed_w;
			playPos_r <= playPos_w;
			maxRecPos_r <= maxRecPos_w;
		end
	end
	
	always_comb begin
	
			state_w = state_r;
			speed_state_w = speed_state_r;
			startI_w = 0;
			startP_w = 0;
			startR_w = 0;
			speed_w = speed_r;
			playPos_w = playPos_r;
			maxRecPos_w = maxRecPos_r;
			
			speedWarning_w = 0;
			
			case(state_r) 
				S_INIT: begin
					startI_w = 1;
					if(finishI_r) begin
						state_w = S_IDLE;
						startI_w = 0;
					end
				end
			
				S_IDLE: begin
				
					playPos_w = 0;
					if(i_start) begin
					
						if(i_switch) begin		// play
							state_w = S_PLAY;
						end
						else begin					// Record
							state_w = S_RECORD;
						end
					end
					else begin end
					
					// For speed control:
					case(speed_state_r) 
						S_NORMAL: begin
							if(i_up) begin
								speed_state_w = S_FAST;
								speed_w = speed_r + 1;
							end
							else if(i_down) begin
								speed_state_w = S_SLOW;
								speed_w = speed_r + 1;
							end
							else begin end
						end
					
						S_FAST: begin
							if(i_up) begin
								if(speed_r != 8) begin
									speed_w = speed_r + 1;
								end
								else begin
									speedWarning_w = 1;
								end
							end
							else if(i_down) begin
								if(speed_r == 2) begin
									speed_w = 1;
									speed_state_w = S_NORMAL;
								end
								else begin
									speed_w = speed_r - 1;
								end
							end
						end
						
						S_SLOW: begin
							if(i_up) begin
								if(speed_r == 2) begin
									speed_w = 1;
									speed_state_w = S_NORMAL;
								end
								else
									speed_w = speed_r - 1;
							end
							else if(i_down) begin
								if(speed_r != 8) begin
									speed_w = speed_r + 1;
								end
								else begin
									speedWarning_w = 1;
								end
							end
						end
						
					endcase
				
				end
				
				S_PLAY: begin
					startP_w = 1;
					playPos_w = p_addr;	//Record for pause
					if(i_start) begin
						state_w = S_PAUSE;
						startP_w = 0;		// playing only when startP_r remains high
					end
					else begin end
					
					if(finishP_w || i_stop) begin
						state_w = S_IDLE;
						startP_w = 0;
					end
					
					
					
					// For speed control:
					case(speed_state_r) 
						S_NORMAL: begin
							if(i_up) begin
								speed_state_w = S_FAST;
								speed_w = speed_r + 1;
							end
							else if(i_down) begin
								speed_state_w = S_SLOW;
								speed_w = speed_r + 1;
							end
							else begin end
						end
					
						S_FAST: begin
							if(i_up) begin
								if(speed_r != 8) begin
									speed_w = speed_r + 1;
								end
								else begin
									speedWarning_w = 1;
								end
							end
							else if(i_down) begin
								if(speed_r == 2) begin
									speed_w = 1;
									speed_state_w = S_NORMAL;
								end
								else begin
									speed_w = speed_r - 1;
								end
							end
						end
						
						S_SLOW: begin
							if(i_up) begin
								if(speed_r == 2) begin
									speed_w = 1;
									speed_state_w = S_NORMAL;
								end
								else
									speed_w = speed_r - 1;
							end
							else if(i_down) begin
								if(speed_r != 8) begin
									speed_w = speed_r + 1;
								end
								else begin
									speedWarning_w = 1;
								end
							end
						end
						
					endcase
				end
				
				S_RECORD: begin
					startR_w = 1;
					maxRecPos_w = r_addr;
					if(finishR_w || i_stop) begin
						state_w = S_IDLE;
						startR_w = 0;
					end
					else begin end
				end
				
				S_PAUSE: begin
					if(i_start) begin
						state_w = S_PLAY;
					end
					else if(i_stop) begin
						state_w = S_IDLE;
					end
					
					// For speed control:
					case(speed_state_r) 
						S_NORMAL: begin
							if(i_up) begin
								speed_state_w = S_FAST;
								speed_w = speed_r + 1;
							end
							else if(i_down) begin
								speed_state_w = S_SLOW;
								speed_w = speed_r + 1;
							end
							else begin end
						end
					
						S_FAST: begin
							if(i_up) begin
								if(speed_r != 8) begin
									speed_w = speed_r + 1;
								end
								else begin
									speedWarning_w = 1;
								end
							end
							else if(i_down) begin
								if(speed_r == 2) begin
									speed_w = 1;
									speed_state_w = S_NORMAL;
								end
								else begin
									speed_w = speed_r - 1;
								end
							end
						end
						
						S_SLOW: begin
							if(i_up) begin
								if(speed_r == 2) begin
									speed_w = 1;
									speed_state_w = S_NORMAL;
								end
								else
									speed_w = speed_r - 1;
							end
							else if(i_down) begin
								if(speed_r != 8) begin
									speed_w = speed_r + 1;
								end
								else begin
									speedWarning_w = 1;
								end
							end
						end
						
					endcase
				end		
			endcase
	end
endmodule
	
	