# COCOTB variables
export COCOTB_REDUCED_LOG_FMT=1
export PYTHONPATH := wrapper_test:$(PYTHONPATH)
export LIBPYTHON_LOC=$(shell cocotb-config --libpython)

all: test_wrapper

test_wrapper:
	rm -rf sim_build/
	mkdir sim_build/
	iverilog -DMPRJ_IO_PADS=38 -DCOCOTB_SIM -o sim_build/sim.vvp -s wrapped_instrumented_adder_sklansky -g2012 wrapper.v instrumented_adder/src/instrumented_adder.v  instrumented_adder/src/sklansky.v
	PYTHONOPTIMIZE=${NOASSERT} MODULE=wrapper_test.wrapper_test vvp -M $$(cocotb-config --prefix)/cocotb/libs -m libcocotbvpi_icarus sim_build/sim.vvp
	! grep failure results.xml

clean::
	rm -rf *vcd sim_build test/__pycache__

.PHONY: clean harden
