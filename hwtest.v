`timescale 1ns/10ps
`default_nettype none

module hwtest(input clk, output RS232_Tx, input RS232_Rx,
	      output LED1, output LED2, output LED3, output LED4, 
	      output LED5, input  PMOD10);

   wire 	     reset;
   reg [4:0] 	     pordone;
   wire 	     por;

   assign por=~&pordone;

   // Note at 12 Mhz 115200 isn't reliable
   // due to error rate
   // (you get 7 which is about 7% error at 16X)
   // 57600, on the other hand, is about .2% error)
   // You could use a PLL to go >12 MHz to reduce the error
   defparam tx.BAUD=57600;
   defparam tx.CLOCK=12_000_000;
   defparam tx.OVERSAMPLE=1;
   defparam recv.BAUD=57600;
   defparam recv.CLOCK=12_000_000;

   assign reset=PMOD10|por;
   assign {LED4, LED3, LED2, LED1} = char[3:0];
   assign LED5=framing;
   

   always @(posedge clk)
     begin
	if (por) pordone<=pordone+1;
     end


   wire [7:0] char;
   wire       busy;
   wire       readdata;
   wire      dataready;
   wire      sendchar;
   wire [7:0] uchar;
   wire       framing;
   

   assign uchar=(char>=8'h61&&char<=8'h7a)?(char&8'hDF):char;

   
// Note: you can't just feed the rx clock to the tx clock
//   because they both don't run all the time 
//   and both need to sync with their start bits

   rx recv(clk,reset,RS232_Rx,readdata,1'b1,char,dataready,framing);
   xmit tx(clk,reset,uchar,sendchar,RS232_Tx,busy);
   

   assign sendchar=busy?1'b0:dataready;
   assign readdata=sendchar;
   
   
endmodule
