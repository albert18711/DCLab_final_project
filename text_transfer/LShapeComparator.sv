// LShapeComparator
// calculate the similarity of L-shape neighbor
// The method is the same as mytextureTransfer.cpp
// The size is fixed to 4 since LOCAL_X and LOCAL_Y is fixed to 3

// reset when i_rst = RESET (local parameter)

// output is the similarity of neighbor

// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// LOOK LShapeComparator not LShapeComparator_comb

// ******************************************************


// Not sure whether one cycle is ok
module LShapeComparator_comb(
		input 			i_start,
		input 			i_clk,
		input				i_rst,
		input [7:0]		i_sL	[0:3],	// grayscale use 8 bits
		input [7:0]		i_rL	[0:3],	// grayscale use 8 bits
		output [31:0] 	o_Distance		// 4 bits for fractional -> 8 bits for fraction if divided by 4^2
												// that is, count^2 in C++ code
);

	logic signed [15:0] sMean, rMean;			// 2 bits for fractional part
	logic signed [31:0] Distance_r, Distance_w; 
	
	logic signed [31:0] partial_S [0:3];
	logic signed [31:0] partial_R [0:3];	// For (i_sL - sMean) and (i_rL - rMean)
	logic signed [31:0] squareTerm [0:3];	// For (partial_S - partial_R)^2
	
	assign o_Distance = Distance_r;
	
	always_comb begin
	
		Distance_w = Distance_r;
		sMean = 0;	// 2 bits for fraction
		rMean = 0;	// 2 bits for fraction
			
		for(int i = 0; i<4 ; i++) begin
			partial_S[i] = 0;
			partial_R[i] = 0;
			squareTerm[i] = 0;
		end
	
		if(i_start) begin	
			sMean = i_sL[0] + i_sL[1] + i_sL[2] + i_sL[3];	// 2 bits for fraction
			rMean = i_rL[0] + i_rL[1] + i_rL[2] + i_rL[3];	// 2 bits for fraction
			
			for(int i = 0; i<4 ; i++) begin
				partial_S[i] = $signed({i_sL[i], 2'b0}) - $signed(sMean);
			end
				
			for(int i = 0; i<4 ; i++) begin
				partial_R[i] = $signed({i_rL[i], 2'b0}) - $signed(rMean);
			end
			
			for(int i = 0; i<4 ; i++) begin
				squareTerm[i] = ($signed(partial_S[i]) - $signed(partial_R[i]))**2;
			end
			
			Distance_w = squareTerm[0] + squareTerm[1] + squareTerm[2] + squareTerm[3];
		end
		
		else begin end
	
	end
	
	always_ff @ (posedge i_clk) begin
		if(i_rst) begin
			Distance_r <= 0;
		end
		else begin
			Distance_r <= Distance_w;
		end
	end
	
endmodule




// Use several cycles to calculate the similarity
module LShapeComparator(
		input 			i_start,
		input 			i_clk,
		input			i_rst,
		input [7:0]		i_sL	[0:3],	// grayscale use 8 bits
		input [7:0]		i_rL	[0:3],	// grayscale use 8 bits
		output [31:0] 	o_Distance,		// [7:0]-> fractional part!!!
		output o_finish
);

	typedef enum {
       S_IDLE,
		 S_SQUARE,
       S_SUM,
		 S_FINISH
   } State;
	
	logic signed [15:0] sMean, rMean;			// 2 bits for fractional part
	logic signed [31:0] Distance_r, Distance_w; 
	
	logic signed [31:0] partial_S_r [0:3];
	logic signed [31:0] partial_R_r [0:3];	// For (i_sL - sMean) and (i_rL - rMean)
	logic signed [31:0] partial_S_w [0:3];
	logic signed [31:0] partial_R_w [0:3];	// For (i_sL - sMean) and (i_rL - rMean)
	
	logic signed [31:0] squareTerm_r [0:3];	// For (partial_S - partial_R)^2
	logic signed [31:0] squareTerm_w [0:3];	// For (partial_S - partial_R)^2
	
	
	logic finish_r, finish_w;
	State state_r, state_w;
	
	assign o_Distance = Distance_r;
	assign o_finish = finish_r;
	
	always_comb begin
	
		Distance_w = Distance_r;
		sMean = 0;	// 2 bits for fraction
		rMean = 0;	// 2 bits for fraction
			
		for(int i = 0; i<4; i++) begin
			partial_S_w[i] = 0;
			partial_R_w[i] = 0;
			squareTerm_w[i] = 0;
 		end

		
		state_w = state_r;
		finish_w = 0;
		
		case(state_r) 
		
			S_IDLE: begin
				if(i_start) begin	

					//$display("=====================================================");

					sMean = i_sL[0] + i_sL[1] + i_sL[2] + i_sL[3];	// 2 bits for fraction
					rMean = i_rL[0] + i_rL[1] + i_rL[2] + i_rL[3];	// 2 bits for fraction
					
					for(int i = 0; i<4; i++) begin
						partial_S_w[i] = $signed({6'd0, i_sL[i], 2'd0}) - $signed(sMean);
						partial_R_w[i] = $signed({6'd0, i_rL[i], 2'd0}) - $signed(rMean);
					end
					/*
					$display("rMean = %d", rMean);
					$display("Partial R [0]= %d", partial_R_w[0]);
					$display("Partial R [1]= %d", partial_R_w[1]);
					$display("Partial R [2]= %d", partial_R_w[2]);
					$display("Partial R [3]= %d\n", partial_R_w[3]);

					$display("sMean = %d", sMean);
					$display("Partial S [0]= %d", partial_S_w[0]);
					$display("Partial S [1]= %d", partial_S_w[1]);
					$display("Partial S [2]= %d", partial_S_w[2]);
					$display("Partial S [3]= %d", partial_S_w[3]);
					*/

					state_w = S_SQUARE;
				end
				
				else begin end
				
			end
			
			S_SQUARE: begin
					// 4 bits for fractional part
					for(int i = 0; i<4 ; i++) begin
						squareTerm_w[i] = $signed($signed(partial_S_r[i]) - $signed(partial_R_r[i]))*$signed($signed(partial_S_r[i]) - $signed(partial_R_r[i]));
					end
					/*
					$display("squareTerm [0]= %d", squareTerm_w[0]);
					$display("squareTerm [1]= %d", squareTerm_w[1]);
					$display("squareTerm [2]= %d", squareTerm_w[2]);
					$display("squareTerm [3]= %d\n", squareTerm_w[3]);
					*/
					state_w = S_SUM;
			end
			
			S_SUM: begin
					Distance_w = squareTerm_r[0] + squareTerm_r[1] + squareTerm_r[2] + squareTerm_r[3];
					// Divided by 4^2 -> (4+4) bits for fractional part
					state_w = S_FINISH;
					finish_w = 1;
			end
			
			S_FINISH: begin
				state_w = S_IDLE;
			end
		
		endcase
	
		//else begin end
	
	end
	
	always_ff @ (posedge i_clk) begin
		if(i_rst) begin
			Distance_r <= 0;
			state_r <= S_IDLE;
			finish_r <= 0;

			for(int i = 0; i<4; i++) begin
				partial_S_r[i] <= 0;
				partial_R_r[i] <= 0;
				squareTerm_r[i] <= 0;
 			end

		end
		else begin
			Distance_r <= Distance_w;
			state_r <= state_w;
			finish_r <= finish_w;

			for(int i = 0; i<4; i++) begin
				partial_S_r[i] = partial_S_w[i];
				partial_R_r[i] = partial_R_w[i];
				squareTerm_r[i] = squareTerm_w[i];
 			end

		end
	end

endmodule
