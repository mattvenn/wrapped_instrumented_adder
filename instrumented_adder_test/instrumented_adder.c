/*
 * SPDX-FileCopyrightText: 2020 Efabless Corporation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * SPDX-License-Identifier: Apache-2.0
 */

#include <defs.h>
#include <stub.c>

// change to your project's ID - ask Matt
#define PROJECT_ID 3

// input control pins
#define RESET           0
#define STOP_B          1
#define EXTRA_INV       2
#define BYPASS_B        3
#define CONTROL_B       4
#define COUNTER_EN      5
#define COUNTER_LOAD    6 
// output status pin
#define DONE            8

#define SET(PIN,N) (PIN |=  (1<<N))
#define CLR(PIN,N) (PIN &= ~(1<<N))
#define GET(PIN,N) (PIN &   (1<<N))

void main()
{
	/* 
	IO Control Registers
	| DM     | VTRIP | SLOW  | AN_POL | AN_SEL | AN_EN | MOD_SEL | INP_DIS | HOLDH | OEB_N | MGMT_EN |
	| 3-bits | 1-bit | 1-bit | 1-bit  | 1-bit  | 1-bit | 1-bit   | 1-bit   | 1-bit | 1-bit | 1-bit   |

	Output: 0000_0110_0000_1110  (0x1808) = GPIO_MODE_USER_STD_OUTPUT
	| DM     | VTRIP | SLOW  | AN_POL | AN_SEL | AN_EN | MOD_SEL | INP_DIS | HOLDH | OEB_N | MGMT_EN |
	| 110    | 0     | 0     | 0      | 0      | 0     | 0       | 1       | 0     | 0     | 0       |
	
	 
	Input: 0000_0001_0000_1111 (0x0402) = GPIO_MODE_USER_STD_INPUT_NOPULL
	| DM     | VTRIP | SLOW  | AN_POL | AN_SEL | AN_EN | MOD_SEL | INP_DIS | HOLDH | OEB_N | MGMT_EN |
	| 001    | 0     | 0     | 0      | 0      | 0     | 0       | 0       | 0     | 1     | 0       |

	*/
    reg_mprj_io_8 = GPIO_MODE_MGMT_STD_OUTPUT; // ready
    reg_mprj_io_9 = GPIO_MODE_MGMT_STD_OUTPUT; // done

    reg_mprj_io_10 = GPIO_MODE_MGMT_STD_OUTPUT; // ring osc counter out
    reg_mprj_io_11 = GPIO_MODE_MGMT_STD_OUTPUT; // ring osc counter out
    reg_mprj_io_12 = GPIO_MODE_MGMT_STD_OUTPUT; // ring osc counter out
    reg_mprj_io_13 = GPIO_MODE_MGMT_STD_OUTPUT; // ring osc counter out
    reg_mprj_io_14 = GPIO_MODE_MGMT_STD_OUTPUT; // ring osc counter out
    reg_mprj_io_15 = GPIO_MODE_MGMT_STD_OUTPUT; // ring osc counter out
    reg_mprj_io_16 = GPIO_MODE_MGMT_STD_OUTPUT; // ring osc counter out
    reg_mprj_io_17 = GPIO_MODE_MGMT_STD_OUTPUT; // ring osc counter out

    reg_mprj_xfer = 1;
    while (reg_mprj_xfer == 1);

    // activate the project by setting the 0th bit of 1st bank of LA
    reg_la0_iena = 0; // input enable on
    reg_la0_oenb = 0xFFFFFFFF; // enable logic analyser output (ignore the name, 1 is on, 0 off)
    reg_la0_data |= (1 << PROJECT_ID); // enable the project

    // tell the test bench we're ready
	reg_mprj_datal |= 1 << 8;

    reg_la1_oenb = 0xFFFFFFFF; // enable
    reg_la1_iena = 0;          // enable

    reg_la2_oenb = 0xFFFFFFFF; // enable
    reg_la2_iena = 0;          // enable

    reg_la3_oenb = 0xFFFFFFFF; // enable
    reg_la3_iena = 0;

    // reproduce test_bypass in the test_adder.py to measure the ring oscillator
    // it doesn't work here for some reason. The ring never resolves from x
    // the bypass input is defined, but the output of the first bypass tristate is always x

    // hold in reset
    SET(reg_la1_data, RESET);
    // stop the ring
    CLR(reg_la1_data, STOP_B);
    // enable extra inverter
    SET(reg_la1_data, EXTRA_INV);
    // set a & b input to be 0
    reg_la3_data = 0;

    // disable adder sum connection and inputs
    /*
    .a_input_ext_bit_b      (la1_data_in[15:8]),     // which bit of the adder's a input to connect to external a_input (inverted)
    .a_input_ring_bit_b     (la1_data_in[23:16]),    // which bit of the adder's a input to connect to the ring (inverted)
    .s_output_bit_b         (la1_data_in[31:24]),    // which bit of sum to connect back to the ring (inverted)
    */
    reg_la1_data |= 0xFFFF00 << 8;

    // disable control loop
    SET(reg_la1_data, CONTROL_B);

    // enable bypass loop
    CLR(reg_la1_data, BYPASS_B);

    // load the integration counter
    reg_la2_data = 100;
    SET(reg_la1_data, COUNTER_LOAD);
    CLR(reg_la1_data, RESET);
    CLR(reg_la1_data, COUNTER_LOAD);

    // start the loop & enable in the same cycle
    reg_la1_data |= ((1 << STOP_B) | (1 << COUNTER_EN));

    // wait for done to go high
    while(1) 
    {
        if(GET(reg_la1_data_in, DONE))
            break;
    }

    // set the ring osc value onto the pins
    reg_mprj_datal = reg_la2_data_in << 10;

    // set done on the mprj pins
	reg_mprj_datal |= 1 << 9;
}

