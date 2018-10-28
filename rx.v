`timescale 1ns/10ps
`default_nettype none


module rx(input clk, input reset, input rx_pin, input readdata, input clearerr,
              output reg  [7:0] data, output reg dataready, output reg framing, output reg overrun);
   parameter BAUD=9600;
   parameter CLOCK=12_000_000;
   parameter IDLELEVEL=1'b1;
   parameter DATAINV=1'b0;
   
   
   localparam STARTTHRESH=8;  // 8 of 16 start bits for start
   localparam BITTHRESH=8;   // 8 of 16 1 bits for a 1
   

   reg [15:0] 	     bitstream;  // shift register for bits
   reg [3:0] 	     mark;  // this is the "end" of the bitstream circular buffer
   reg [3:0] 	     point;  // this is the "current" of the bitstream circular buffer
// yosys is ok with this being a wire
// but icarus wants a reg
   reg [4:0] 	     bitsum;  // sum of the bitstream
   wire baudclk;
   wire brgreset;

   reg [8:0] rbyte;    // extra bit for stop bit (MSB)
   reg [8:0] mask;     // current bit in byte
   reg predataready;  // make data avaialble on IDLE state
   
   
   
// Generate 16X clock
  brg #(.BAUD(BAUD),.CLOCK(CLOCK)) bitclock(clk,brgreset|reset, baudclk);
  
//  assign bitsum=bitstream[15]+bitstream[14]+bitstream[13]+bitstream[12]+bitstream[11]+bitstream[10]+bitstream[9]+bitstream[8]+bitstream[7]+bitstream[6]+bitstream[5]+bitstream[4]+bitstream[3]+bitstream[2]+bitstream[1]+bitstream[0];
/* The below runs at compile time and does the same thing
   as the long assign, above */
   integer i;
   always @(*)
     begin
        bitsum=4'b0;
	for (i=0;i<16;i++) bitsum=bitsum+bitstream[i];
     end

// When IDLE stop the clock
   assign brgreset=state==IDLE;

  reg [2:0] 	     state;
	     
// States
   localparam IDLE=1;
   localparam STARTING=2;
   localparam READ=4;


   always @(posedge clk)
     begin
	if (reset)
	  begin
	     bitstream<=16'hffff;
	     state<=1;
	     mark<=15;
	     point<=15;
	     dataready<=1'b0;
	     predataready<=1'b0;
             overrun<=1'b0;
	     framing<=1'b0;
	  end
	else 
	  begin
// Clear dataready as soon as the other side gets the data
	     if (readdata) dataready<=1'b0;
// Clear errors on request
	     if (clearerr)
	       begin
		  overrun<=1'b0;
		  framing<=1'b0;
	       end
	     case (state)
	       IDLE:
		 begin
		    // If data ready, make it so
		    if (predataready)
		      begin
			 predataready<=1'b0;
			 dataready<=1'b1;
			 data<=rbyte[7:0];
// handle errors
			 if (framing==0 && (rbyte[8]!=(IDLELEVEL^DATAINV))) framing<=1'b1;
			 if (dataready) overrun<=1;
		      end
			 
// If we get a start bit slice, we  already know what the 
// first bit slice is (0) so start with  one slice in the oven
// Note that we just set up speculatively
// But unless we change state to STARTING, it doesn't matter
		  mark<=15;
		  point<=14;
		  rbyte<=8'b0;  // assume zero bits
		  mask<=8'b1;
		  bitstream<={~(IDLELEVEL^DATAINV),{15{IDLELEVEL^DATAINV}}};
		  if (rx_pin!=(IDLELEVEL^DATAINV)) 
		    begin 
		       state<=STARTING;
		    end
		       
               end
// We might have a full start bit, let's see
	       STARTING:
		 begin
		 if (baudclk==1'b1)  // sync on baud clock
		   begin
		      bitstream[point]<=rx_pin; 
		      point<=point-4'b1;	
// if we are done, see if it was really a start bit?
		      if (point==mark)
			begin
			   if ((bitsum>=STARTTHRESH)!=(IDLELEVEL^DATAINV)) 
			     begin 
				state<=READ;
			     end
			   else
			     begin
				mark<=mark-4'b1;
			     end
			end
		   end // if (baudclk==1'b1)
		 else
// If we are back to no 0 bits for 16 slices, go back to idle		   
		 if (bitstream==16'hffff) state<=IDLE;
		 end // case: STARTING
// Ok now read bits
	       READ:
		 begin
		    if (baudclk==1'b1)  // sync to baud clk
		      begin
			 bitstream[point]<=rx_pin;
			 point<=point-1'b1;
			 if (point==mark)
			   begin
			      if ((bitsum<BITTHRESH)==DATAINV) rbyte<=rbyte|mask;
			      mask<={mask[7:0],1'b0};
// if no more bits, tell IDLE to shut down and set data
			      if (mask==9'h100)
				begin
				   state<=IDLE;
				   predataready<=1'b1;
				end
			   end

		      end // if (baudclk==1'b1)
		 end // case: READ

		default:  // What?
		begin
		   dataready<=1'b0;
		   state<=IDLE;
		end
     endcase
          end // else: !if(reset)
     end // always @ (posedge clk)
endmodule
