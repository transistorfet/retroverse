
TOOLS = ../../../../tools
RUN_YOSYS = $(TOOLS)/atf15xx_yosys/run_yosys.sh
RUN_FITTER = $(TOOLS)/atf15xx_yosys/run_fitter.sh

buslogic: buslogic.jed
buslogic_test: buslogic_test.jed

buslogic.edif: vmebus_interface.v interrupts.v
buslogic_test.edif: vmebus_interface.v interrupts.v

##############
# Synthesis  #
##############

%.jed: %.edif
	$(RUN_FITTER) -d ATF1508AS -p TQFP100 $(basename $<)

%.edif: %.v
	$(RUN_YOSYS) $(basename $<)

##############
# Simulation #
##############

%.wave: %.vcd
	gtkwave $<

%.vcd: %.sim
	vvp $<

%.sim: %.v %_tb.v
	iverilog -o $@ $^

#################
# Miscellaneous #
#################

clean:
	find . \( -name "*.jed" -or -name "*.tt3" -or -name "*.edif" -or -name "*.fit" -or -name "*.io" \) -delete -print

