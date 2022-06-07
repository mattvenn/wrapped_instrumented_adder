`default_nettype none
`ifdef FORMAL
    `define MPRJ_IO_PADS 38    
`endif

//`define USE_WB  1
`define USE_LA  1
`define USE_IO  1
//`define USE_SHARED_OPENRAM 1
//`define USE_MEM 1
//`define USE_IRQ 1

// update this to the name of your module
module wrapped_instrumented_adder_brent(
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif
    input wire wb_clk_i,                            // clock, runs at system clock
 // caravel wishbone peripheral
`ifdef USE_WB
    input wire          wb_rst_i,                   // main system reset
    input wire          wbs_stb_i,                  // wishbone write strobe
    input wire          wbs_cyc_i,                  // wishbone cycle
    input wire          wbs_we_i,                   // wishbone write enable
    input wire [3:0]    wbs_sel_i,                  // wishbone write word select
    input wire [31:0]   wbs_dat_i,                  // wishbone data in
    input wire [31:0]   wbs_adr_i,                  // wishbone address
    inout wire          wbs_ack_o,                  // wishbone ack
    inout wire [31:0]   wbs_dat_o,                  // wishbone data out
`endif

// shared RAM wishbone controller
`ifdef USE_SHARED_OPENRAM
    inout wire          rambus_wb_clk_o,            // clock
    inout wire          rambus_wb_rst_o,            // reset
    inout wire          rambus_wb_stb_o,            // write strobe
    inout wire          rambus_wb_cyc_o,            // cycle
    inout wire          rambus_wb_we_o,             // write enable
    inout wire [3:0]    rambus_wb_sel_o,            // write word select
    inout wire [31:0]   rambus_wb_dat_o,            // ram data out
    inout wire [9:0]    rambus_wb_adr_o,            // 10bit address
    input wire          rambus_wb_ack_i,            // ack
    input wire [31:0]   rambus_wb_dat_i,            // ram data in
`endif

    // Logic Analyzer Signals
    // only provide first 32 bits to reduce wiring congestion
`ifdef USE_LA
    input wire [31:0]   la1_data_in,                // from CPU to your project
    inout wire [31:0]   la1_data_out,               // from your project to CPU
    input wire [31:0]   la1_oenb,                   // output enable bar (low for active)
    input wire [31:0]   la2_data_in,                // from CPU to your project
    inout wire [31:0]   la2_data_out,               // from your project to CPU
    input wire [31:0]   la2_oenb,                   // output enable bar (low for active)
    input wire [31:0]   la3_data_in,                // from CPU to your project
    inout wire [31:0]   la3_data_out,               // from your project to CPU
    input wire [31:0]   la3_oenb,                   // output enable bar (low for active)
`endif

    // IOs
`ifdef USE_IO
    input wire [`MPRJ_IO_PADS-1:0] io_in,           // in to your project
    inout wire [`MPRJ_IO_PADS-1:0] io_out,          // out from your project
    inout wire [`MPRJ_IO_PADS-1:0] io_oeb,          // out enable bar (low active)
`endif

    // IRQ
`ifdef USE_IRQ
    inout wire [2:0] user_irq,                      // interrupt from project to CPU
`endif

`ifdef USE_CLK2
    // extra user clock
    input wire user_clock2,
`endif
    
    // active input, only connect tristated outputs if this is high
    input wire active
);

    // all outputs must be tristated before being passed onto the project
    wire                        buf_wbs_ack_o;
    wire [31:0]                 buf_wbs_dat_o;
    wire [31:0]                 buf_la1_data_out;
    wire [31:0]                 buf_la2_data_out;
    wire [31:0]                 buf_la3_data_out;
    wire [`MPRJ_IO_PADS-1:0]    buf_io_out;
    wire [`MPRJ_IO_PADS-1:0]    buf_io_oeb;
    wire [2:0]                  buf_user_irq;
    wire                        buf_rambus_wb_clk_o;
    wire                        buf_rambus_wb_rst_o;
    wire                        buf_rambus_wb_stb_o;
    wire                        buf_rambus_wb_cyc_o;
    wire                        buf_rambus_wb_we_o;
    wire [3:0]                  buf_rambus_wb_sel_o;
    wire [31:0]                 buf_rambus_wb_dat_o;
    wire [9:0]                  buf_rambus_wb_adr_o;

    `ifdef FORMAL
    // formal can't deal with z, so set all outputs to 0 if not active
    `ifdef USE_WB
    assign wbs_ack_o    = active ? buf_wbs_ack_o    : 1'b0;
    assign wbs_dat_o    = active ? buf_wbs_dat_o    : 32'b0;
    `endif
    `ifdef USE_SHARED_OPENRAM
    assign rambus_wb_clk_o = active ? buf_rambus_wb_clk_o : 1'b0;
    assign rambus_wb_rst_o = active ? buf_rambus_wb_rst_o : 1'b0;
    assign rambus_wb_stb_o = active ? buf_rambus_wb_stb_o : 1'b0;
    assign rambus_wb_cyc_o = active ? buf_rambus_wb_cyc_o : 1'b0;
    assign rambus_wb_we_o  = active ? buf_rambus_wb_we_o  : 1'b0;
    assign rambus_wb_sel_o = active ? buf_rambus_wb_sel_o : 4'b0;
    assign rambus_wb_dat_o = active ? buf_rambus_wb_dat_o : 32'b0;
    assign rambus_wb_adr_o = active ? buf_rambus_wb_adr_o : 10'b0;
    `endif
    `ifdef USE_LA
    assign la1_data_out = active ? buf_la1_data_out  : 32'b0;
    `endif
    `ifdef USE_IO
    assign io_out       = active ? buf_io_out       : {`MPRJ_IO_PADS{1'b0}};
    assign io_oeb       = active ? buf_io_oeb       : {`MPRJ_IO_PADS{1'b0}};
    `endif
    `ifdef USE_IRQ
    assign user_irq     = active ? buf_user_irq          : 3'b0;
    `endif
    `include "properties.v"
    `else
    // tristate buffers
    
    `ifdef USE_WB
    assign wbs_ack_o    = active ? buf_wbs_ack_o    : 1'bz;
    assign wbs_dat_o    = active ? buf_wbs_dat_o    : 32'bz;
    `endif
    `ifdef USE_SHARED_OPENRAM
    assign rambus_wb_clk_o = active ? buf_rambus_wb_clk_o : 1'bz;
    assign rambus_wb_rst_o = active ? buf_rambus_wb_rst_o : 1'bz;
    assign rambus_wb_stb_o = active ? buf_rambus_wb_stb_o : 1'bz;
    assign rambus_wb_cyc_o = active ? buf_rambus_wb_cyc_o : 1'bz;
    assign rambus_wb_we_o  = active ? buf_rambus_wb_we_o  : 1'bz;
    assign rambus_wb_sel_o = active ? buf_rambus_wb_sel_o : 4'bz;
    assign rambus_wb_dat_o = active ? buf_rambus_wb_dat_o : 32'bz;
    assign rambus_wb_adr_o = active ? buf_rambus_wb_adr_o : 10'bz;
    `endif
    `ifdef USE_LA
    assign la1_data_out  = active ? buf_la1_data_out  : 32'bz;
    assign la2_data_out  = active ? buf_la2_data_out  : 32'bz;
    assign la3_data_out  = active ? buf_la3_data_out  : 32'bz;
    `endif
    `ifdef USE_IO
    assign io_out       = active ? buf_io_out       : {`MPRJ_IO_PADS{1'bz}};
    assign io_oeb       = active ? buf_io_oeb       : {`MPRJ_IO_PADS{1'bz}};
    `endif
    `ifdef USE_IRQ
    assign user_irq     = active ? buf_user_irq          : 3'bz;
    `endif
    `endif

    // causes loads of warnings but otherwise can't easily get the vcd
    `ifdef COCOTB_SIM
    initial begin
        $dumpfile ("wrapped_instrumented_adder_brent.vcd");
        $dumpvars (0, wrapped_instrumented_adder_brent);
        #1;
    end
    `endif

    // permanently set oeb so that outputs are always enabled: 0 is output, 1 is high-impedance
    assign buf_io_oeb = {`MPRJ_IO_PADS{1'b0}};

    parameter WIDTH = 32;
    reg [WIDTH-1:0] a_input;
    reg [WIDTH-1:0] b_input;
    reg [WIDTH-1:0] s_output_bit_b;
    reg [WIDTH-1:0] a_input_ext_bit_b;
    reg [WIDTH-1:0] a_input_ring_bit_b;
    wire [WIDTH-1:0] sum_out;
    wire write          = la1_data_in[8];
    wire [3:0] reg_sel  = la1_data_in[12:9];

    // multiplex la3_data_in/out to the 32 bit wide registers
    always @(posedge wb_clk_i) begin
        if(write)
            case(reg_sel)
            0: a_input            <= la3_data_in;    
            1: b_input            <= la3_data_in;
            2: s_output_bit_b     <= la3_data_in;
            3: a_input_ext_bit_b  <= la3_data_in;
            4: a_input_ring_bit_b <= la3_data_in;
            endcase
    end 

    assign buf_la3_data_out = reg_sel == 0 ? a_input :
                              reg_sel == 1 ? b_input :
                              reg_sel == 2 ? s_output_bit_b :
                              reg_sel == 3 ? a_input_ext_bit_b :
                              reg_sel == 4 ? a_input_ring_bit_b :
                                             sum_out;

    instrumented_adder_brent instrumented_adder(

    .clk                    (wb_clk_i),              // clocks the time counter
    .reset                  (la1_data_in[0]),        // resets the counters

    // loop control
    .stop_b                 (la1_data_in[1]),        // stops the ring oscillator (inverted)
    .extra_inverter         (la1_data_in[2]),        // adds an extra inverter into the ring
    .bypass_b               (la1_data_in[3]),        // bypass the adder (inverted)
    .control_b              (la1_data_in[4]),        // enables an additional control loop (inverted)
    .a_input_ext_bit_b      (a_input_ext_bit_b),       // which bit of the adder's a input to connect to external a_input (inverted)
    .a_input_ring_bit_b     (a_input_ring_bit_b),      // which bit of the adder's a input to connect to the ring (inverted)
    .s_output_bit_b         (s_output_bit_b),          // which bit of sum to connect back to the ring (inverted)

    // counter control
    .counter_enable         (la1_data_in[5]),
    .counter_load           (la1_data_in[6]),
    .force_count            (la1_data_in[7]),       // force counter to count even without integration counter
    .integration_time       (la2_data_in),
    
    // adder inputs
    .a_input                (a_input),
    .b_input                (b_input),

    // outputs
    //.ring_osc_out           (la1_data_out),         // used for spice sims
    .sum_out                (sum_out),                // output of the adder
    .done                   (buf_la1_data_out[0]),    // when the integration counter gets to zero
    .ring_osc_counter_out   (buf_la2_data_out)        // number of ring cycles / 2 counted
    );

    assign buf_io_out[8] = la1_data_in[1];            // stop control
    assign buf_io_out[9] = buf_la2_data_out[3];       // 4th bit of ring osc counter
    assign buf_io_out[10]= buf_la1_data_out[0];       // when the counter is done

endmodule 
`default_nettype wire
