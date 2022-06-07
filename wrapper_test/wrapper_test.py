import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles, Timer
from rich.progress import Progress 
import random

# input control pins
RESET         =  0
STOP_B        =  1
EXTRA_INV     =  2
BYPASS_B      =  3
CONTROL_B     =  4
COUNTER_EN    =  5
COUNTER_LOAD  =  6 
FORCE_COUNT   =  7
MUX_WRITE     =  8 

# output
DONE          =  0

# la_data_3 MUX
A_INPUT          = 0
B_INPUT          = 1
S_OUTPUT_BIT     = 2
A_INPUT_EXT_BIT  = 3
A_INPUT_RING_BIT = 4
SUM              = 5

async def set_mux(dut, reg_sel, value):
    dut.la1_data_in[12].value = (0b1000 & reg_sel) >> 3
    dut.la1_data_in[11].value = (0b0100 & reg_sel) >> 2
    dut.la1_data_in[10].value = (0b0010 & reg_sel) >> 1
    dut.la1_data_in[ 9].value = (0b0001 & reg_sel)

    dut.la3_data_in.value = value
    dut.la1_data_in[MUX_WRITE].value = 1
    await ClockCycles(dut.wb_clk_i, 1)
    dut.la1_data_in[MUX_WRITE].value = 0
    await ClockCycles(dut.wb_clk_i, 1)

async def wait_till_done(dut):
    while True:
        await ClockCycles(dut.wb_clk_i, 1)
        if dut.la1_data_out[DONE]:
            break

@cocotb.test()
async def test_bypass_minimal(dut):

    clock = Clock(dut.wb_clk_i, 100, units="ns")
    cocotb.fork(clock.start())
    dut.active.value = 1
    dut.la1_data_in[RESET].value = 1
    await ClockCycles(dut.wb_clk_i, 10)
    dut.la1_data_in[RESET].value = 0
    dut.la1_data_in[FORCE_COUNT].value = 0

    dut.la1_data_in[STOP_B].value = 0

    dut.la1_data_in[EXTRA_INV].value = 1

    # set the wrapper's registers
    await set_mux(dut, A_INPUT, 0)
    await set_mux(dut, B_INPUT, 0)
    # enable a input ext bit
    await set_mux(dut, A_INPUT_EXT_BIT,     0x0)
    # disable others
    await set_mux(dut, S_OUTPUT_BIT,        0xFFFFFFFF)
    await set_mux(dut, A_INPUT_RING_BIT,    0xFFFFFFFF)

    # disable control loop
    dut.la1_data_in[CONTROL_B].value = 1

    # enable bypass loop
    dut.la1_data_in[BYPASS_B].value = 0

    # load the integration counter
    dut.la2_data_in.value = 100
    dut.la1_data_in[COUNTER_LOAD].value = 1
    await ClockCycles(dut.wb_clk_i, 1)
    dut.la1_data_in[COUNTER_LOAD].value = 0

    # start the loop & enable in the same cycle
    dut.la1_data_in[STOP_B].value = 1
    dut.la1_data_in[COUNTER_EN].value = 1

    await wait_till_done(dut)
    await ClockCycles(dut.wb_clk_i, 1000)

    # this is the ring oscillator count
    count = int(dut.la2_data_out.value)
    assert count == 81

@cocotb.test()
async def test_adder_minimal(dut):

    clock = Clock(dut.wb_clk_i, 100, units="ns")
    cocotb.fork(clock.start())
    dut.active.value = 1
    dut.la1_data_in[RESET].value = 1
    await ClockCycles(dut.wb_clk_i, 10)
    dut.la1_data_in[RESET].value = 0
    dut.la1_data_in[FORCE_COUNT].value = 0

    dut.la1_data_in[STOP_B].value = 0

    dut.la1_data_in[EXTRA_INV].value = 1

    # set the wrapper's registers
    await set_mux(dut, A_INPUT, 0)
    await set_mux(dut, B_INPUT, 0)
    # set control bits for 1st bit of counter as in and out
    await set_mux(dut, A_INPUT_EXT_BIT,     0x00000001)
    await set_mux(dut, S_OUTPUT_BIT,        0xFFFFFFFE)
    await set_mux(dut, A_INPUT_RING_BIT,    0xFFFFFFFE)

    # disable control loop
    dut.la1_data_in[CONTROL_B].value = 1

    # disable bypass loop
    dut.la1_data_in[BYPASS_B].value = 1

    # load the integration counter
    dut.la2_data_in.value = 100
    dut.la1_data_in[COUNTER_LOAD].value = 1
    await ClockCycles(dut.wb_clk_i, 1)
    dut.la1_data_in[COUNTER_LOAD].value = 0

    # start the loop & enable in the same cycle
    dut.la1_data_in[STOP_B].value = 1
    dut.la1_data_in[COUNTER_EN].value = 1

    await wait_till_done(dut)
    await ClockCycles(dut.wb_clk_i, 1000)

    # this is the ring oscillator count
    count = int(dut.la2_data_out.value)
    assert count == 81

# constrained random
@cocotb.test()
async def test_adder(dut):
    clock = Clock(dut.wb_clk_i, 100, units="ns")
    cocotb.fork(clock.start())
    dut.la1_data_in[RESET].value = 1
    await ClockCycles(dut.wb_clk_i, 10)
    dut.la1_data_in[RESET].value = 0

    dut.la1_data_in[STOP_B].value = 0

    # set the wrapper's registers
    # enable a input ext bit
    await set_mux(dut, A_INPUT_EXT_BIT,     0x0)
    # disable others
    await set_mux(dut, S_OUTPUT_BIT,        0xFFFFFFFF)
    await set_mux(dut, A_INPUT_RING_BIT,    0xFFFFFFFF)

    num_tests = 100
    with Progress() as progress:
        test_progress = progress.add_task("[green]Processing...", total=num_tests)
        for test in range(num_tests):
            a = random.randint(0, 0xFFFFFFF)
            b = random.randint(0, 0xFFFFFFF)
            await set_mux(dut, A_INPUT, a)
            await set_mux(dut, B_INPUT, b)
            await ClockCycles(dut.wb_clk_i, 1)

            await set_mux(dut, SUM, 0)
            assert (int(dut.la3_data_out) == (a+b))
            progress.update(test_progress, advance=1)
