`default_nettype none
`timescale 1ns/10ps

module xmit_clk(input clk, input reset, 
	    input [7:0] char, input sendchar, 
	    output 	txpin,output busy,input baud);

   parameter IDLELEVEL=1'b1;  // line idle is a 0 or 1? (before inversion if DATAINV=1)
   parameter DATAINV=1'b0;   // invert data=1
// Note: this MUST match clock source!
   parameter OVERSAMPLE=16;
   
// states   
   localparam IDLE=  5'b00001;
   localparam START= 5'b00010;
   localparam BIT=   5'b00100;
   localparam SEND=  5'b01000;
   localparam STOP=  5'b10000;

   

   reg [4:0]    state;
   reg [4:0] 	nextstate;
   reg [4:0] 	timer16x;
   reg [9:0] 	cbuf;
   reg [3:0] 	bitct;
   reg [3:0] 	newbitct;


// Send LSB data
   assign txpin=cbuf[0]^DATAINV;
// if not idle, we are busy
   assign busy=state!=IDLE;
   
// Calculate next state and next bit count
   always @(*)
     begin
	nextstate=state;  // default
	newbitct=bitct;
	case (state)
	  IDLE:
	    begin
	    if (sendchar)
	      begin
		 newbitct=9; // (start+stop+8)-1
		 nextstate=START;
	      end
	    end
	  
	  START:
	    begin
	    if (timer16x==0) 
	       begin
		  nextstate=BIT;
		  newbitct=bitct-1;
	       end
	    end
	       
	  BIT:
	     begin
		if (bitct)
		  begin
		     newbitct=bitct-1;
		     nextstate=SEND;
		  end
		else
		  nextstate=STOP;
	     end
	  SEND:
	    if (timer16x==0) nextstate=BIT;
	  
	  STOP:
	    if (timer16x==0) nextstate=IDLE;
	  default:
	    nextstate=IDLE;
	endcase // case (state)
     end

// Run the state machine
   always @(posedge clk)
     if (reset)
       begin
// Initial setup
	  cbuf<={10{IDLELEVEL}};
	  state<=IDLE;
	  timer16x<=OVERSAMPLE;
	  bitct<=9;
       end	  
     else
       begin
// If we are not busy and sendchar is high, grab character to send
	  if (busy==0 && sendchar==1 && reset==0)  cbuf<={ IDLELEVEL, char, ~IDLELEVEL };
// update baud rate divisor
	    if (timer16x!=0)
	      if (baud) 
		begin
		   timer16x<=timer16x-1;
		end
// this won't see the zero until next fast clock
	    if (timer16x==0||state==IDLE) 
		 begin
		    timer16x<=OVERSAMPLE;
		 end
// shift cbuf unless in idle
	  if (timer16x==0 && state!=IDLE) cbuf<={ IDLELEVEL, cbuf[9:1] };
// Update state and bitct	  
	  state<=nextstate;  
	  bitct<=newbitct;
       end

endmodule
