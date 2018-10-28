`default_nettype none
`timescale 1ns/10ps

//`include "clog2.v"


module brg(input clk, input rst, output baudrate);
   parameter BAUD=9600;
   parameter OVERSAMPLE=16;  
   parameter CLOCK=12_000_000;
// cycles/sec / bit/sec = cycles/bit
// We need to factor in oversampling and
// to minimize error, we compute 10 x the delay, add 5 and then divide by 10
// So if the delay should be 20.7, we compute 207, add 5 divide by 10 and get 21.
   localparam SCLOCK=((CLOCK*10)/(BAUD*(OVERSAMPLE))+5)/10 - 1;
   localparam BAUDCLOCKWIDTH=$clog2(SCLOCK+1);

   reg [BAUDCLOCKWIDTH-1:0] counter=SCLOCK;

// Output fires when counter is 0   
   assign baudrate=counter==0;

   always @(posedge clk)
     if (rst)
       counter<=SCLOCK;
     else
       if (counter==0) counter<=SCLOCK; else counter<=counter-1;

endmodule
