There are several files here:

rx.v - The receiver
tbrx.v - Testbench for receiver
rx.save.gtkw - Save file for gtkwave (optional)
states.txt - State definition for gtkwave (optional)
brg.v - Baudrate generator
clog2.v - Include file to replace $clog2
*.pcf - Constrain files
ice40flow.env - Environment for ice40flow driver for icestorm
Makefile - File for building
README.txt - This file



In addition, all these files are associated with the transmitter which is needed for hwtest.
xmit.v - Transmitter with internal clock
xmit_clk.v - Transmitter with external clock (main code)
