
DEVICE = hx4k
PACKAGE = tq144
PIN_DEF = ../pins-hx4k-all.pcf

TOP = fidget
LIBRARIES = \
	busdebugger_serial.v \
	../libraries/computie_bus/computie_bus_snooper.v \
	../libraries/computie_bus/computie_bus_dumper.v \
	../libraries/usart/usart_tx.v \
	../libraries/usart/usart_rx.v \
	../libraries/utils/async_fifo.v \
	../libraries/utils/synchronizer.v


LIBRARIES_SYNTH = \
	../libraries/utils/dual_port_memory_ice40.v
	#../libraries/utils/dual_port_memory.v

LIBRARIES_TEST = \
	../libraries/utils/dual_port_memory.v

all: $(TOP).bin

##############
# Synthesis  #
##############

%.json: %.v $(LIBRARIES) $(LIBRARIES_SYNTH)
	yosys -p 'synth_ice40 -top $* -blif $*.blif -json $*.json' $^

%.asc: $(PIN_DEF) %.json
	nextpnr-ice40 --$(DEVICE) --package $(PACKAGE) --pcf $(PIN_DEF) --json $*.json --asc $@ 

%.bin: %.asc
	icepack $< $@

%.rpt: %.asc
	icetime -d $(DEVICE) -mtr $@ $<

##############
# Simulation #
##############

%.wave: %.vcd
	gtkwave $<

%.vcd: %.sim
	vvp $<

%.sim: %.v %_tb.v $(LIBRARIES) $(LIBRARIES_TEST)
	iverilog -o $@ $^

%.sim: %.sv %_tb.sv $(LIBRARIES) $(LIBRARIES_TEST)
	iverilog -g2012 -o $@ $^


upload:
	tinyprog -p $(TOP).bin

check:
	verible-verilog-lint *.v ../libraries/**/*.v

clean:
	find . \( -name "*.vcd" -or -name "*.sim" -or -name "*.json" -or -name "*.blif" -or -name "*.rpt" -or -name "*.asc" -or -name "*.bin" \) -delete -print

.SECONDARY: # Make all targets secondary targets, so they won't be deleted

