`timescale 1ns/100ps

// NOTE: Data 2: SRC: PurpleFlower
//               TRG: EiffelTower
// NOTE: The grayscale here is not transformed !!!!!!!!!!!!!!!!!


module SRAM_init #(		parameter DATA_WIDTH = 16,
                   			parameter ADDR_WIDTH = 10,
                   			parameter RAM_DEPTH = (1 << ADDR_WIDTH))
 (
 	    input  clk, // Clock Input
 	    input  [ADDR_WIDTH-1:0] address, // Address Input
 	    inout  [DATA_WIDTH-1:0] data, // Data bi-directional
 	    input                    cs, // Chip Select
 	    input                    we, // Write Enable/Read Enable
 	    input                    oe,        // Output Enable
      input                    i_rst

 ); 

 //--------------Internal variables---------------- 
 	logic [DATA_WIDTH-1:0]   data_out;

 // Use Associative array to save memory footprint
 	//typedef logic [ADDR_WIDTH-1:0] mem_addr;
 	logic [DATA_WIDTH-1:0] mem_buffer [0:2**ADDR_WIDTH-1];
  logic [DATA_WIDTH-1:0] mem_r      [0:2**ADDR_WIDTH-1];
  logic [DATA_WIDTH-1:0] mem_w      [0:2**ADDR_WIDTH-1];
  
 //--------------Code Starts Here------------------ 
 // Tri-State Buffer control 
 // output : When we = 1, oe = 0, cs = 1
 	assign data = (cs && !oe && we)? data_out : 16'bz; 
 
 // Memory Write Block 
 // Write Operation : When we = 0, cs = 1
 // Memory Read Block 
 // Read Operation : When we = 0, oe = 1, cs = 1
 	always_comb
 	begin

      for(int i=0; i<2**ADDR_WIDTH; i++) begin
        mem_w[i] = mem_r[i];
      end
    	if (cs && we && !oe) begin
        	data_out = mem_r[address];
    	end
      else if ( cs && !we) begin
          mem_w[address] = data;
      end
      else begin end
 	end

 	initial begin	// initialize using Matlab data

 	  // TRG: 
  		mem_buffer[0:49] = '{	
      // (R,G)    (B, Gray)

      // Data 1:
      /*
          16'd57836, 16'd62441,
          16'd58092, 16'd62697,
          16'd59375, 16'd63213,
          16'd60657, 16'd63216,
          16'd60915, 16'd63985,
          16'd57579, 16'd62184,
          16'd58092, 16'd62697,
          16'd58862, 16'd62956,
          16'd59375, 16'd63213,
          16'd59633, 16'd63727,
          16'd56809, 16'd62182,
          16'd57066, 16'd62439,
          16'd58092, 16'd62954,
          16'd58862, 16'd62956,
          16'd59120, 16'd63725,
          16'd56295, 16'd61924,
          16'd56552, 16'd62181,
          16'd58091, 16'd62697,
          16'd59117, 16'd62955,
          16'd59376, 16'd63470,
          16'd55780, 16'd61666,
          16'd56037, 16'd61923,
          16'd57064, 16'd62182,
          16'd58090, 16'd62440,
          16'd58605, 16'd63211
      */
      // Data no overflow
            16'd53467,  16'd60352,
            16'd53980,  16'd60583,
            16'd53214,  16'd61072,
            16'd53727,  16'd61067,
            16'd53984,  16'd61061,
            16'd52955,  16'd60344,
            16'd53468,  16'd60581,
            16'd53212,  16'd60818,
            16'd53726,  16'd60811,
            16'd53983,  16'd60805,
            16'd52442,  16'd60319,
            16'd52699,  16'd60564,
            16'd53211,  16'd60302,
            16'd53724,  16'd60296,
            16'd53981,  16'd60552,
            16'd52700,  16'd60560,
            16'd52957,  16'd60807,
            16'd53211,  16'd60301,
            16'd53725,  16'd60554,
            16'd53982,  16'd60560,
            16'd53214,  16'd60823,
            16'd53214,  16'd60812,
            16'd53215,  16'd60817,
            16'd53729,  16'd61070,
            16'd53986,  16'd61079

      // Data 2:
          // 16'd52189, 16'd60889,
          // 16'd55001, 16'd59865,
          // 16'd52184, 16'd59862,
          // 16'd50134, 16'd59858,
          // 16'd47052, 16'd58056,
          // 16'd51161, 16'd60373,
          // 16'd51411, 16'd59345,
          // 16'd49875, 16'd59600,
          // 16'd47569, 16'd59340,
          // 16'd46536, 16'd57541,
          // 16'd50645, 16'd59346,
          // 16'd50899, 16'd59345,
          // 16'd49877, 16'd59857,
          // 16'd45778, 16'd60107,
          // 16'd46284, 16'd58823,
          // 16'd49617, 16'd58830,
          // 16'd49614, 16'd58060,
          // 16'd50643, 16'd59345,
          // 16'd46033, 16'd60106,
          // 16'd43979, 16'd60100,
          // 16'd49359, 16'd58829,
          // 16'd49871, 16'd58573,
          // 16'd48848, 16'd59085,
          // 16'd46799, 16'd59850,
          // 16'd43462, 16'd59072
          };


/*
      $display("\nTRG in SRAM");
      for(int i = 0; i<25 ; i++) begin
        $display("pixel = %d: (%d, %d, %d, %d)", i, mem_buffer[2*i][15:8], mem_buffer[2*i][7:0], mem_buffer[2*i+1][15:8], mem_buffer[2*i+1][7:0]);
      end
*/
 

  	// SRC:
  		mem_buffer[50:99] = '{
      // (R, G)   (B, Gray)
      // Data 1:
      /*
          16'd30271, 16'd46685,
          16'd32564, 16'd45912,
          16'd31013, 16'd34633,
          16'd29472, 16'd31299,
          16'd33343, 16'd40029,
          16'd4352, 16'd8969,
          16'd24369, 16'd31815,
          16'd31290, 16'd39512,
          16'd27171, 16'd35139,
          16'd37457, 16'd46960,
          16'd13086, 16'd6435,
          16'd17439, 16'd18990,
          16'd27446, 16'd36944,
          16'd19475, 16'd29230,
          16'd24359, 16'd33346,
          16'd27958, 16'd37713,
          16'd30272, 16'd41563,
          16'd19228, 16'd25650,
          16'd8192, 16'd1802,
          16'd12812, 16'd2839,
          16'd27939, 16'd38470,
          16'd23837, 16'd36156,
          16'd9472, 16'd10255,
          16'd17444, 16'd3370,
          16'd15125, 16'd2078
      */
      // Data no overflow
          16'd54866,   16'd52359,
          16'd55899,   16'd49804,
          16'd53336,   16'd50312,
          16'd3843,    16'd1286,
          16'd1573,    16'd1560,
          16'd28438,   16'd35389,
          16'd21767,   16'd23848,
          16'd45421,   16'd47241,
          16'd17166,   16'd22054,
          16'd13,      16'd7,
          16'd27170,   16'd34370,
          16'd34108,   16'd45407,
          16'd55448,   16'd59060,
          16'd37162,   16'd45400,
          16'd 3605,   16'd784,
          16'd36148,   16'd41050,
          16'd40506,   16'd39522,
          16'd36890,   16'd44109,
          16'd39737,   16'd42594,
          16'd1308,    16'd530,
          16'd27700,   16'd36174,
          16'd34105,   16'd42332,
          16'd39490,   16'd42599,
          16'd39263,   16'd34676,
          16'd1349,    16'd2347
      // Data 2
          // 16'd49517, 16'd47758,
          // 16'd52090, 16'd50842,
          // 16'd49547, 16'd51618,
          // 16'd58806, 16'd60874,
          // 16'd42598, 16'd41599,
          // 16'd53126, 16'd52643,
          // 16'd50286, 16'd47504,
          // 16'd52875, 16'd52902,
          // 16'd33598, 16'd33114,
          // 16'd23042, 16'd19492,
          // 16'd50311, 16'd51872,
          // 16'd55961, 16'd56243,
          // 16'd63153, 16'd62669,
          // 16'd43871, 16'd43390,
          // 16'd24851, 16'd24370,
          // 16'd60082, 16'd62410,
          // 16'd54708, 16'd59843,
          // 16'd59574, 16'd62411,
          // 16'd41060, 16'd43645,
          // 16'd54945, 16'd59320,
          // 16'd52123, 16'd55216,
          // 16'd61317, 16'd59824,
          // 16'd63328, 16'd49560,
          // 16'd60903, 16'd65771,
          // 16'd55504, 16'd58836
        };

/*
      $display("\nSRC in SRAM");
      for(int i = 25; i<50 ; i++) begin
        $display("pixel = %d: (%d, %d, %d, %d)", i, mem_buffer[2*i][15:8], mem_buffer[2*i][7:0], mem_buffer[2*i+1][15:8], mem_buffer[2*i+1][7:0]);
      end

      #(210*10)
      $display("\nAtlas in SRAM");
      for(int i = 50; i<75 ; i++) begin
        $display("pixel = %d: (%d, %d, %d, %d)", i, mem_r[2*i][15:8], mem_r[2*i][7:0], mem_r[2*i+1][15:8], mem_r[2*i+1][7:0]);
      end
*/


  end


  always_ff @(posedge clk) begin
    if(i_rst) begin
      for(int i=0; i<2**ADDR_WIDTH; i++) begin
        mem_r[i] <= mem_buffer[i];
      end
    end 
    else begin
      for(int i = 0; i<2**ADDR_WIDTH; i++) begin
        mem_r[i] <= mem_w[i];
      end
    end
  end


 endmodule // End of Module ram_sp_sr_sw