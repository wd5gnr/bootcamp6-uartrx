`default_nettype none
`timescale 1ns/10ps

module xmit(input clk, input reset, 
	    input [7:0] char, input sendchar, 
	    output 	txpin,output busy);

   parameter IDLELEVEL=1'b1;  // line idle is a 0 or 1? (before inversion if DATAINV=1)
   parameter DATAINV=1'b0;   // invert data=1
   parameter BAUD=9600;
   parameter CLOCK=12_000_000;
   parameter OVERSAMPLE=16;
   
   defparam xbrg.BAUD=BAUD;
   defparam xbrg.CLOCK=CLOCK;
   defparam xbrg.OVERSAMPLE=OVERSAMPLE;
   defparam xmitter.OVERSAMPLE=OVERSAMPLE;


   wire brgreset;  // reset baud rate generator when in idle
   wire baud;      // baud rate tick


// Hold off BRG until needed
   assign brgreset=(~busy)|reset;
   

// Generate 16X baudrate clock
// You could generate a 1X clock, of course
// but errors show up less at 16X and
// easier to share BRG with receiver if you
// wanted to
   brg xbrg(clk,reset|brgreset,baud);

// transmitter
   xmit_clk #(.IDLELEVEL(IDLELEVEL),.DATAINV(DATAINV),.OVERSAMPLE(OVERSAMPLE)) 
      xmitter(clk,reset,char,sendchar,txpin,busy,baud);
   


endmodule
