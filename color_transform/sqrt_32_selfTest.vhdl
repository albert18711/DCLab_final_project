//  Copyright (c) 1999 Stephen Williams (steve@icarus.com)


module sqrt32(clk, rdy, reset, x, .y(acc));
   input  clk;
   output rdy;
   input  reset;

   input [31:0] x;
   output [15:0] acc;


   // acc holds the accumulated result, and acc2 is the accumulated
   // square of the accumulated result.
   reg [15:0] acc;
   reg [31:0] acc2;

   // Keep track of which bit I'm working on.
   reg [4:0]  bitl;
   wire [15:0] bit;
   assign bit = (1 << bitl);
   wire [31:0] bit2;
   assign bit2 = 1 << (bitl << 1);

   // The output is ready when the bitl counter underflows.
   wire rdy = bitl[4];

   // guess holds the potential next values for acc, and guess2 holds
   // the square of that guess. The guess2 calculation is a little bit
   // subtle. The idea is that:
   //
   //      guess2 = (acc + bit) * (acc + bit)
   //             = (acc * acc) + 2*acc*bit + bit*bit
   //             = acc2 + 2*acc*bit + bit2
   //             = acc2 + 2 * (acc<<bitl) + bit
   //
   // This works out using shifts because bit and bit2 are known to
   // have only a single bit in them.
   wire [15:0] guess  = acc | bit;
   wire [31:0] guess2 = acc2 + bit2 + ((acc << bitl) << 1);

  always @(posedge reset or posedge clk) begin
    if (reset) begin
  	 acc <= 0;
  	 acc2 <= 0;
  	 bitl <= 15;     
    end
    else begin
    	if (guess2 <= x) begin
    	   acc  <= guess;
    	   acc2 <= guess2;
    	end
    	bitl <= bitl - 1;
    end
  end

endmodule

module main;

   reg clk, reset;
   reg [31:0] value;
   wire [15:0] result;
   wire rdy;

   sqrt32 root(.clk(clk), .rdy(rdy), .reset(reset), .x(value), .y(result));

   always #5 clk = ~clk;

   always @(posedge rdy) begin
      $display("sqrt(%d) --> %d", value, result);
      $finish;
   end


   initial begin
      clk = 0;
      reset = 1;
      $monitor($time,,"%m.acc = %b", root.acc);
      #100 value = 63;
      reset = 0;
   end
endmodule /* main */
