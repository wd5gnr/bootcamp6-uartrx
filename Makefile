# It doesn't make sense to program the chip with test and test.pll
# So the default targets are xmit, testbrg, and testxmit
# If you want xmitpll, specify it yourself on the command line
# also note the Makefile moves the dumpvars.vcd files to keep them from conflicting

# Assumes you have icestorm, icarus, and ice40flow (https://github.com/wd5gnr/ice40flow) installed

all : tbrx hwtest.txt

tbrx: rx.vcd

rx.vcd : tbrx.v rx.v brg.v clog2.v 
	iverilog -o rx tbrx.v rx.v brg.v
	vvp rx
	mv dumpvars.vcd rx.vcd

rx: hwtest.txt

hwtest.txt : hwtest.v rx.v brg.v xmit.v xmit_clk.v clog2.v 
	ice40flow hwtest

clean:
	rm rx.vcd hwtest.txt hwtest.bin hwtest.blif hwtest.rpt rx; true


