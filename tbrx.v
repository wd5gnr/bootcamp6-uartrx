// Code your testbench here
// or browse Examples
`timescale 1ns/10ps
`default_nettype none

module tb();
   reg clock=0;
   reg reset=0;
   reg rx=1;
   reg readdata=0;
   reg clearerr=0;
  wire [7:0] data;
  wire dataready;
  wire framing;
  wire overrun;
  
  
  rx #(.BAUD(115200),.CLOCK(50_000_000)) dut(clock,reset, rx, readdata, clearerr,
             data, dataready, framing, overrun);
  
  always #10 clock=~clock;  // 50 Mhz clock
  
  initial
    begin
      $dumpfile("dumpvars.vcd");
      $dumpvars;
      reset=1;
      #80 reset=0;
// General test (55h)
       #8681;  // let it settle one bit period
       rx=0;  // start bit
       #8680.6 rx=1;
       #8680.6 rx=0;
       #8680.6 rx=1;
       #8680.6 rx=0;
       #8680.6 rx=1;
       #8680.6 rx=0;
       #8680.6 rx=1;
       #8680.6 rx=0;
       #8680.6 rx=1;   // stop bit
       #8680.6;
       #10000;  // dead time
       readdata<=1;
       #20 readdata<=0;
       #5000 ;
       

  // Test Noise in central bit (ASCII 9 = 39h)
       rx=0;  // start bit
       #8680.6 rx=1;
       #8680.6 rx=0;
       #8680.6 rx=0;
       #8680.6 rx=1;
       #8680.6 rx=1;
       #5000   rx=0;  // noise
       #1000   rx=1;
       #2680.6 rx=1;
       #8680.6 rx=0;
       #8680.6 rx=0;
       #8680.6 rx=1;   // stop bit
       #8680.6;
       #10000;  // dead time
       readdata<=1;
       #20 readdata<=0;
       #5000;
       
// Noisy start

       rx=0;  // start bit
       #2000 rx=1;
       #1500 rx=0;
       #5180.6 rx=1;
       #8680.6 rx=0;
       #8680.6 rx=1;
       #8680.6 rx=0;
       #8680.6 rx=1;
       #8680.6 rx=0;
       #8680.6 rx=1;
       #8680.6 rx=0;
       #8680.6 rx=1;   // stop bit
       #8680.6;
       #10000;  // dead time
       readdata<=1;
       #20 readdata<=0;
       #5000 ;

// Test Overrun
              rx=0;  // start bit
       #8680.6 rx=1;
       #8680.6 rx=0;
       #8680.6 rx=0;
       #8680.6 rx=0;
       #8680.6 rx=0;
       #8680.6 rx=0;
       #8680.6 rx=1;
       #8680.6 rx=0;
       #8680.6 rx=1;   // stop bit
       #8680.6;
       #10000;  // dead time
       rx=0;  // start bit
       #8680.6 rx=1;
       #8680.6 rx=0;
       #8680.6 rx=1;
       #8680.6 rx=0;
       #8680.6 rx=1;
       #8680.6 rx=0;
       #8680.6 rx=1;
       #8680.6 rx=0;
       #8680.6 rx=1;   // stop bit
       #8680.6;
       #10000;  // dead time
       readdata<=1;
       #20 readdata<=0;
       #5000 ;
              
// Framing error
       rx=0;  // start bit
       #8680.6 rx=0;
       #8680.6 rx=0;
       #8680.6 rx=0;
       #8680.6 rx=1;
       #8680.6 rx=1;
       #8680.6 rx=1;
       #8680.6 rx=0;
       #8680.6 rx=0;
       #8680.6 rx=0;   // bad stop bit
       #8680.6;
       #10000;  // dead time
       readdata=1;
       clearerr=1;
       
       #20 readdata=0;
       clearerr=0;
       #5000;
       $finish;
       
    end
endmodule


/*
 Note: at 50 Mhz and 115200 (x16) baud
 You have a "slide" error in timing.
 
 Each x16 bit time should be 542.5nS (aprox)
 However, the divisor can only be 27 which gives you 540nS.
 
 So you are off about 2.5nS per 1/16 of a bit
 That works out to 40nS per full bit, and over a 10 bit word
 (1 start + 8 data + 1 stop) that is 400nS or 0.4uS of accumulated 
 error. If you notice at the end of the sim,
 Mask changes to 100 376.4nS before the edge of the big 
 because of this error.
 
 However, because we filter out "noise" this does not
 impact the correct operation of the module.
 
 */
