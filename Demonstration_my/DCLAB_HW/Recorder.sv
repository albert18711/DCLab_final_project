

// In module Recorder, we use I2S protocol to interact with WM8731
module Recorder (
	input i_record_start,			// start record process
	input i_ADCLRCK,				// data clk from I2C manager, read data at 1
	input i_ADCDAT,					// data (1 bit per time) from I2C manager
	input i_BCLK,					// act as clk 
	output o_SRAM_WE,				// SRAM enable, 0 -> write
	output [15:0] o_SRAM_DATA,		// 16 bit to SRAM
	output o_full,					// means storage full, exit record state
	output [19:0] o_SRAM_ADDR,		// address for SRAM
	output [1:0] o_REC_STATE,		// output FSM within Recorder
	output finish
);

	parameter SRAM_FULL = 1048575;
	typedef enum { S_IDLE, S_WAIT, S_WRITE, S_FINISH } STATE;
	STATE state_r, state_w;

	logic [15:0] data_buff_r, data_buff_w;
	logic [19:0] SRAM_addr_r, SRAM_addr_w;
	logic [3:0] bit_counter_r, bit_counter_w;

	logic memory_full_r, memory_full_w;
	logic finish_r, finish_w;
	logic pre_ADCLRCK_r, pre_ADCLRCK_w;
	logic write_SRAM_r, write_SRAM_w;

	assign o_full = memory_full_r;
	assign pre_ADCLRCK_w = i_ADCLRCK;
	assign o_REC_STATE = state_r;
	assign o_SRAM_DATA = data_buff_r;
	assign o_SRAM_ADDR = SRAM_addr_r;
	assign finish = finish_r;
	assign o_SRAM_WE = (state_r != S_WRITE);

	always_comb begin
		// default value
		state_w = state_r;
		data_buff_w = data_buff_r;
		SRAM_addr_w = SRAM_addr_r;
		bit_counter_w = bit_counter_r;
		memory_full_w = memory_full_r;
		//pre_ADCLRCK_w = pre_ADCLRCK_r;
		write_SRAM_w = 0;
		finish_w = 0;

		case (state_r)
			S_IDLE: begin
				if(i_record_start) begin
					state_w = S_WAIT;
					SRAM_addr_w = 0;
					memory_full_w = 0;
				end
				else begin
					state_w = S_IDLE;
				end
			end
			S_WAIT: begin
				data_buff_w = 0;
				bit_counter_w = 0;
				if(i_record_start) begin
					if(pre_ADCLRCK_r == 1 && i_ADCLRCK == 0) begin
						state_w = S_WRITE;
					end
					else begin end
				end
				else begin
					state_w = S_IDLE;
				end
			end
//			 _________
// ADCLRC:         |_________
//	       _   _   _   _   _
// BCLK:   |_| |_| |_| |_| |_
//		
// STATE:            [WAI][WRITE]  
// DATA:               [MSB]    			
/*
			S_DELAY: begin
				// for 1 bclk delay
				state_w = S_WRITE;
			end
			
*/

			S_WRITE: begin
				if(i_record_start) begin
					data_buff_w[bit_counter_r] = i_ADCDAT; 	// bit-reverse order, yet handled in player.sv
					bit_counter_w = bit_counter_r + 1;
					if(bit_counter_r == 15) begin
						if(SRAM_addr_r != SRAM_FULL) begin
							SRAM_addr_w = SRAM_addr_r + 1;
							state_w = S_WAIT;
						end
						else begin
							state_w = S_FINISH;
							memory_full_w = 1;
							finish_w = 1;
						end
						write_SRAM_w = 1;
					end
				end
				else begin
					state_w = S_IDLE;
				end
			end
			S_FINISH: begin
				state_w = S_IDLE;
			end
		endcase
	end

	always_ff @(posedge i_BCLK) begin
		bit_counter_r <= bit_counter_w;
		SRAM_addr_r <= SRAM_addr_w;
		data_buff_r <= data_buff_w;
		memory_full_r <= memory_full_w;
		state_r <= state_w;
		pre_ADCLRCK_r <= pre_ADCLRCK_w;
		write_SRAM_r <= write_SRAM_w;
		finish_r <= finish_w;
	end
endmodule


/*
module Recorder(
	input i_record_start,
	input i_ADCLRCK,
	input i_ADCDAT,
	input i_BCLK,
	output o_SRAM_WE,
	output [15:0] o_SRAM_DATA,
	output finish,
	output [19:0] o_SRAM_ADDR,
	output [1:0] o_REC_STATE
);
	enum { S_IDLE, S_WAIT, S_WRITE, S_DONE } state_r, state_w;
	logic pre_LRCLK_r, pre_LRCLK_w;
	logic done_r, done_w;
	logic [3:0] bitnum_r, bitnum_w;
	logic [15:0] data_r, data_w;
	logic [19:0] position_r, position_w;

	assign o_SRAM_WE = (state_r != S_WRITE);
	assign o_SRAM_DATA = data_r;
	assign finish = done_r;
	assign o_SRAM_ADDR = position_r;
	assign o_REC_STATE = state_r;

	// Assignments
	always_ff @( posedge i_BCLK ) begin
		state_r <= state_w;
		position_r <= position_w;
		data_r <= data_w;
		bitnum_r <= bitnum_w;
		done_r <= done_w;
		pre_LRCLK_r <= pre_LRCLK_w;
	end

	always_comb begin
		pre_LRCLK_w = i_ADCLRCK;
		data_w = data_r;
		state_w = state_r;
		done_w = done_r;
		position_w = position_r;
		bitnum_w = bitnum_r;

		case (state_r)
			S_IDLE: begin
				position_w = 0;
				bitnum_w = 0;
				done_w = 0;
				if (i_record_start) begin
					state_w = S_WAIT;
				end
			end

			S_WAIT: begin
				bitnum_w = 0;
				if(pre_LRCLK_r == 1 && i_ADCLRCK == 0) state_w = S_WRITE;
			end

			S_WRITE: begin
				if(i_record_start == 0) begin
					state_w = S_IDLE;
				end else begin
					data_w[bitnum_r] = i_ADCDAT;
					bitnum_w = bitnum_r + 1;
					if(bitnum_r == 15) begin
						state_w = S_WAIT;
						if(position_r == 1048575) begin
							state_w = S_DONE;
							done_w = 1;
						end else begin 
							position_w = position_r + 1;
						end
					end
				end
			end

			S_DONE: begin 
				state_w = S_IDLE;
			end
		endcase

	end

endmodule
*/