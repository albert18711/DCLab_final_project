module SRAMctrl(
	input  i_VGAclk,
    input  i_50clk,
	input  i_rst,
	input  i_store, //start store = 0
	input  i_VGAread, //into display mode = 1
    input  [31:0] i_RGB,
    output [29:0] o_RGB,
	output [19:0] o_SRAM_ADDR,
	output o_SRAM_CE_N, 
	output o_SRAM_OE_N,
	output o_SRAM_WE_N,
	output o_SRAM_UB_N, 
	output o_SRAM_LB_N,
	inout  [15:0] SRAM_DATA	
);

input  i_VGAclk;
input  i_50clk;
input  i_rst;
input  i_store; //start store = 0
input  i_VGAread; //into display mode = 1
input  [31:0] i_RGB;

input  VGA_read;     //VGA require data = 1
output [29:0] o_RGB; //send to VGA, R/G/B each 10'

output [19:0] o_SRAM_ADDR;
output o_SRAM_CE_N; 
output o_SRAM_OE_N;
output o_SRAM_WE_N;
output o_SRAM_UB_N; 
output o_SRAM_LB_N;
inout  [15:0] SRAM_DATA;
//
reg sram_wr_req;
reg sram_rd_req;

reg [2:0] state, next_state;

reg [2:0] counter;

reg [16:0] write_RGB_r, write_RGB_w;
reg [20:0] address_r, address_w;
reg [31:0] RGB_buf_r, RGB_buf_w;
reg [20:0] addr_pic_Head_r, addr_pic_Head_w;
//
assign o_SRAM_CE_N = 0; //sram chip select always enable
assign o_SRAM_UB_N = 0; //upper byte always available
assign o_SRAM_LB_N = 0; //lower byte always available

// assign sram_wr_req = ~i_flag; //write
// assign sram_rd_req = i_flag;  //read

//state
parameter S_IDLE     = 3'd0;
		  S_WAIT_VAL = 3'd1;
          S_WRITE_0  = 3'd2;
		  S_WRITE_1  = 3'd3;
          S_READ_0   = 3'd4;
		  S_READ_1   = 3'd5;

// `define DELAY_80NS (counter == 3'd7) //counter = 7 is about 140ns(?)...
//depend on the time SRAM need for writing data

// always@ (posedge i_clk or negedge i_rst) begin //counter for DELAY_80NS
//     if(!i_rst)
//         counter <= 0;
//     else if(state == S_IDLE)
//         counter <= 0;
//     else
//         counter <= counter + 1;
// end

assign SRAM_DATA = (S_READ)? 16'bz : write_RGB_r;

always@ (*) begin //state comb.
    case(state)
        S_IDLE: begin 
			if(!i_store)         next_state = S_WAIT_VAL;
            else if(i_display)   next_state = S_READ;
            else				 next_state = S_IDLE;
		end
        S_WAIT_VAL: begin
			if(i_DVAL)		 	 next_state = S_WRITE;
			else				 next_state = S_WAIT_VAL;
		end
        S_WRITE_0:               next_state = S_WRITE_1;
        S_WRITE_1:               next_state = S_IDLE;
        S_READ_0:                next_state = S_READ_1;
        S_READ_1: begin
            if(VGA_read)         next_state = S_READ_0;
            else                 
        end
        default:				 next_state = S_IDLE;
    endcase
end

always@ (posedge i_clk or negedge i_rst) begin //state seq.
	if(!i_rst) state <= S_IDLE;
	else	   state <= next_state;
end	  

always@ (*) begin //read enable
	if(!i_rst)					o_SRAM_OE_N = 1;
    else if(state == S_READ)	o_SRAM_OE_N = 0;
	else						o_SRAM_OE_N = 1;
end

always@ (*) begin //write enable
	if(!i_rst) o_SRAM_WE_N = 1;
    else case(state)
		S_IDLE: begin 
			if(sram_wr_req)      o_SRAM_WE_N = 0;
            else if(sram_rd_req) o_SRAM_WE_N = 1;
            else				 o_SRAM_WE_N = 1;
		end
		S_WRITE_0: o_SRAM_WE_N = 0;
		default: o_SRAM_WE_N = 1;
	endcase
end

always @(*) begin //read 32' RGB input, write 16' a time to SRAM
    RGB_buf_w = RGB_buf_r;
    write_RGB_w = write_RGB_r;
    case (state)
        S_WAIT_VAL: begin
            if(i_DVAL)          RGB_buf_w = i_RGB;
            else                RGB_buf_w = RGB_buf_r;
        end
        S_WRITE_0:              write_RGB_w = RGB_buf_r[31:16];
        S_WRITE_1:              write_RGB_w = RGB_buf_r[15:0];
        default : /* default */;
    endcase
end

always @(*) begin //read 2 * 16' from SRAM, combine to 32' to VGA
    case (state)
        S_READ_0: begin
            RGB_buf_w[31:16] = SRAM_DATA;
            RGB_buf_w[15:0] = RGB_buf_r[15:0];
            address_w = address_r + 1;
        end
        S_READ_1: begin
            RGB_buf_w[31:16] = RGB_buf_r[31:16];
            RGB_buf_w[15:0] = SRAM_DATA;
            if(address_r < addr_pic_Head_r)
                address_w = address_r + 1;
            else
                address_w = addr_pic_Head_r;
            end
        default : /* default */;
    endcase
end

endmodule
