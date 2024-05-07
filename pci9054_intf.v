`timescale 1ns / 1ns
module pci9054_intf#
(
		// Users to add parameters here
	
		// User parameters ends
		// Do not modify the parameters beyond this line

		// Carries the upper 30 bits of physical Address Bus.
		parameter  integer C_PCI_ADDR_WIDTH	= 8
)
(
	// Users to add ports here
	
	// Unix signal
	input [3:0] fifo_rst_i,
	// System startup flag
	input sys_flag_i,
	// Module reset signal
	output reg [3:0] rst_n_o,
	// Set the pull-down/up resistance of an interface
	output reg [3:0] pud_sel_o,
	// Set the terminal resistance of the interface(lvds port, terminal match always have)
	output reg [2:0] tr_sel_o,
	// Set send and receive loops
	output reg [3:0] lp_sel_o,
	// Set receive enable
	output reg [3:0] rxd_ena_o,
	// Set receive edge
	output reg [3:0] rxd_edge_o,
	// Allocate memory size
	output reg [31:0] alloc_mem_o,
	// Read mode
	output reg [3:0] rd_mode_o,
		
	// Pcm send control interface
	output reg txd_start_o, 			//start sending test data
	output reg txd_edge_o, 				//send edge
	output reg [15:0] txd_baudrate_o, 	//send baudrate
	output reg [15:0] txd_frame_o, 		//send framlength 
	output reg [31:0] txd_code_o, 		//send synchronous code
	output reg [2:0] txd_pattern_o, 	//send code pattern
	output reg [1:0] txd_number_o, 		//send synchronous code length
	output reg [31:0] txd_cntr_num_o, 	//send frame count
	output reg [31:0] txd_send_time_o, 	//send interval time
	// Pcm receive control interface 1
	output reg [1:0] rxd_number1_o, 	//synchronous code num
	output reg [2:0] rxd_pattern1_o,	//set code pattern	
	output reg [15:0] rxd_length1_o,	//set frame length
	output reg [31:0] rxd_code1_o, 		//set synchronous code
    output reg [15:0] rxd_divisor1_o, 	//calculate the time according to the master clock,make sure the frequency is 10khz
	output reg [15:0] rxd_filter_num1_o,//set filter number
	// Pcm receive control interface 2
	output reg [1:0] rxd_number2_o,
	output reg [2:0] rxd_pattern2_o,
	output reg [15:0] rxd_length2_o,
	output reg [31:0] rxd_code2_o,
    output reg [15:0] rxd_divisor2_o,
	output reg [15:0] rxd_filter_num2_o,
	// Pcm receive control interface 3
	output reg [1:0] rxd_number3_o,
	output reg [2:0] rxd_pattern3_o,
	output reg [15:0] rxd_length3_o,
	output reg [31:0] rxd_code3_o,
    output reg [15:0] rxd_divisor3_o,
	output reg [15:0] rxd_filter_num3_o,
	// Pcm receive control interface 4
	output reg [1:0] rxd_number4_o,
	output reg [2:0] rxd_pattern4_o,
	output reg [15:0] rxd_length4_o,
	output reg [31:0] rxd_code4_o,
    output reg [15:0] rxd_divisor4_o,
	output reg [15:0] rxd_filter_num4_o,
	// Read data interface 1
	input [12:0] fifo_wr_usedw1_i, 		//the front end fifo usedw 
	input [13:0] fifo_rd_usedw1_i, 		//the back end fifo usedw 
	input [63:0] fifo_usedw1_i, 		//nvme usedw + ddr usedw + front end usedw + back end fifo usedw
	output fifo_rd_req1_o, 				//fifo data read request
	input [31:0] fifo_rd_data1_i, 		//fifo data read data
	// Read data interface 2
	input [12:0] fifo_wr_usedw2_i,
	input [13:0] fifo_rd_usedw2_i,
	input [63:0] fifo_usedw2_i,
	output fifo_rd_req2_o,
	input [31:0] fifo_rd_data2_i,
	// Read data interface 3
	input [12:0] fifo_wr_usedw3_i,
	input [13:0] fifo_rd_usedw3_i,
	input [63:0] fifo_usedw3_i,
	output fifo_rd_req3_o,
	input [31:0] fifo_rd_data3_i,
	// Read data interface 4
	input [12:0] fifo_wr_usedw4_i,
	input [13:0] fifo_rd_usedw4_i,
	input [63:0] fifo_usedw4_i,
	output fifo_rd_req4_o,
	input [31:0] fifo_rd_data4_i,
	
	input PXI_trig0,
	input clk100M,	
	input sync_flag_temp1,
	input sync_flag_temp2,
	input sync_flag_temp3,
	input sync_flag_temp4,
	
	// Converted back end FIFO reset signal
	output reg fifo_back_rst1_o,
	output reg fifo_back_rst2_o,
	output reg fifo_back_rst3_o,
	output reg fifo_back_rst4_o,
	
	// User ports ends
	// Do not modify the ports beyond this line	

	// PCI9054 Clock Signal
	input p_clk_i,
	// PCI9054 Reset Signal. This Signal is Active LOW
	input p_rst_n_i,
	// Address Bus
	input [C_PCI_ADDR_WIDTH-1 : 0] p_addr_i,
	// Data Bus, Carries 8-, 16-, or 32-bit data quantities, depending upon bus-width configuration.
	inout [31 : 0] p_data_io,
	// Hold Request, Asserted to request use of the Local Bus.
	input p_lhold_i,
	// Write/Read, Asserted low for reads and high for writes.
	input p_lwr_i,
	// Address Strobe, Indicates valid address and start of new Bus access. Asserted for first clock of Bus access.
	input p_ads_n_i,
	// Burst Last, Signal driven by the current Local Bus Master to indicate the last transfer in a Bus access.
	input p_blast_i,
	// Burst Terminate
	output p_bterm_o,
	// Hold Acknowledge, Asserted by the Local Bus arbiter when control is granted in response to LHOLD.
	output reg p_lholda_o,
	// Ready Input/Output
	output reg p_ready_n_o
);
// IOBUF control
genvar i;
wire lwr_sel;
wire [31 : 0] ldata_i;
wire [31 : 0] ldata_o;

BUFG BUFG_inst(.O(lwr_sel),.I(p_lwr_i));
// function called IOBUF_loop, Used for inout type data
generate 
    for(i = 0;i < 32;i = i + 1)
    begin : IOBUF_loop
        IOBUF IOBUF_inst(.I(ldata_i[i]),.IO(p_data_io[i]),.O(ldata_o[i]),.T(lwr_sel));
    end    
endgenerate	

// Register define
// State variable
reg [1 : 0] cstate;
reg [1 : 0] nstate;
// Control read or write operate. low valid
reg data_ctrl;
// Initiates write operate
wire w_operate;
// Initiates read operate
wire r_operate;
// Test register
reg [31 : 0]test_reg; 
wire [31:0]n_second_rx1,n_second_rx2,n_second_rx3,n_second_rx4;
wire [31:0]second_rx1,second_rx2,second_rx3,second_rx4;
// Sync unix signal
wire [3:0] fifo_rst_sig;
wire sync_flag1,sync_flag2,sync_flag3,sync_flag4;
// Define the states of state machine
parameter	s_idle    = 2'b01, // Idle 
			s_operate = 2'b10; // Read or write

// Control state machine implementation
always @(posedge p_clk_i or negedge p_rst_n_i) begin
	if(!p_rst_n_i) cstate <= s_idle;
	else cstate <= nstate;
end
always @(*) begin
	case(cstate)
		s_idle    : begin if(!p_ads_n_i) nstate = s_operate;
					      else nstate = s_idle; end
		s_operate : begin if(p_blast_i) nstate = s_operate;
					      else nstate = s_idle; end
		default   : begin nstate = s_idle; end
	endcase
end
always @(*) begin
	case(cstate)
		s_idle    :begin p_ready_n_o  = 1'b1; end
		s_operate :begin p_ready_n_o  = 1'b0; end
		default   :begin p_ready_n_o  = 1'b1; end
	endcase
end
always @(*) begin
    case(cstate)
        s_idle    :begin data_ctrl= 1'b1; end
        s_operate :begin data_ctrl= 1'b0; end
        default   :begin data_ctrl= 1'b1; end
    endcase
end
always @(posedge p_clk_i or negedge p_rst_n_i)begin
	if(!p_rst_n_i) p_lholda_o <= 1'b1;
	else if(!p_lhold_i) p_lholda_o <= 1'b0;
	else p_lholda_o <= 1'b1;
end
// Burst Terminate is disabled
assign p_bterm_o = 1'b1;
// Generate a pulse to initiate write operate.
assign w_operate = (p_lwr_i) && (!data_ctrl);
// Generate a pulse to initiate read operate.
assign r_operate = (!p_lwr_i) && (!data_ctrl);

	// Add user logic here
// Reset sync
xpm_cdc_array_single #(
	.DEST_SYNC_FF(4),				// DECIMAL; range: 2-10
	.INIT_SYNC_FF(0),				// DECIMAL; 0=disable simulation init values, 1=enable simulation init values
	.SIM_ASSERT_CHK(0),				// DECIMAL; 0=disable simulation messages, 1=enable simulation messages
	.SRC_INPUT_REG(0), 				// DECIMAL; 0=do not register input, 1=register input
	.WIDTH(4) 						// DECIMAL; range: 1-1024
)
xpm_cdc_array_single_inst (

	.dest_out(fifo_rst_sig),		// WIDTH-bit output: src_in synchronized to the destination clock domain. This output is registered.
	.dest_clk(p_clk_i),				// 1-bit input: Clock signal for the destination clock domain.
	.src_clk(0),					// 1-bit input: optional; required when SRC_INPUT_REG = 1
	.src_in(fifo_rst_i)				// WIDTH-bit input: Input single-bit array to be synchronized to destination clock
									// domain. It is assumed that each bit of the array is unrelated to the others. This
									// is reflected in the constraints applied to this macro. To transfer a binary value
									// losslessly across the two clock domains, use the XPM_CDC_GRAY macro instead.
);
always@(posedge p_clk_i or negedge p_rst_n_i) begin
	if(!p_rst_n_i) {fifo_back_rst4_o,fifo_back_rst3_o,fifo_back_rst2_o,fifo_back_rst1_o} <= 4'h0; //high reset
	else {fifo_back_rst4_o,fifo_back_rst3_o,fifo_back_rst2_o,fifo_back_rst1_o} <= fifo_rst_sig;
end
// Pci write operate
always@(posedge p_clk_i or negedge p_rst_n_i) begin
	if(!p_rst_n_i) test_reg <= 32'h2024_0321; //change the date of the logic
	else if((p_addr_i == 0) && (w_operate)) test_reg <= ldata_o; //test register
	else test_reg <= test_reg;
end
always@(posedge p_clk_i or negedge p_rst_n_i) begin
	if(!p_rst_n_i) rst_n_o <= 4'hf;
	else if((p_addr_i == 1) && (w_operate)) rst_n_o <= ldata_o; //reset signal
	else rst_n_o <= rst_n_o;
end
always@(posedge p_clk_i or negedge p_rst_n_i) begin
	if(!p_rst_n_i) {pud_sel_o,tr_sel_o,lp_sel_o} <= 11'h0;
	else if((p_addr_i == 2) && (w_operate)) {pud_sel_o,tr_sel_o,lp_sel_o} <= ldata_o; //interface matching
	else {pud_sel_o,tr_sel_o,lp_sel_o} <= {pud_sel_o,tr_sel_o,lp_sel_o};
end
always@(posedge p_clk_i or negedge p_rst_n_i) begin
	if(!p_rst_n_i) rxd_ena_o <= 4'h0; //disable
	else if((p_addr_i == 3) && (w_operate)) rxd_ena_o <= ldata_o;
	else rxd_ena_o <= rxd_ena_o;
end
always@(posedge p_clk_i or negedge p_rst_n_i) begin
	if(!p_rst_n_i) rxd_edge_o <= 4'h0; //negedge
	else if((p_addr_i == 4) && (w_operate)) rxd_edge_o <= ldata_o;
	else rxd_edge_o <= rxd_edge_o;
end
always@(posedge p_clk_i or negedge p_rst_n_i) begin
	if(!p_rst_n_i) alloc_mem_o <= 32'h0; //equal distribution
	else if((p_addr_i == 5) && (w_operate)) alloc_mem_o <= ldata_o;
	else alloc_mem_o <= alloc_mem_o;
end
always@(posedge p_clk_i or negedge p_rst_n_i) begin
	if(!p_rst_n_i) rd_mode_o <= 4'h0; //normal
	else if((p_addr_i == 6) && (w_operate)) rd_mode_o <= ldata_o;
	else rd_mode_o <= rd_mode_o;
end
// Pcm send control interface
always@(posedge p_clk_i or negedge p_rst_n_i) begin
	if(!p_rst_n_i) txd_start_o <= 1'b0;
	else if((p_addr_i == 16) && (w_operate)) txd_start_o <= ldata_o;
	else txd_start_o <= 1'b0;
end
always@(posedge p_clk_i or negedge p_rst_n_i) begin
	if(!p_rst_n_i) txd_edge_o <= 1'b0; //posedge
	else if((p_addr_i == 17) && (w_operate)) txd_edge_o <= ldata_o;
	else txd_edge_o <= txd_edge_o;
end
always@(posedge p_clk_i or negedge p_rst_n_i) begin
	if(!p_rst_n_i) txd_baudrate_o <= 16'h5; //10Mhz
	else if((p_addr_i == 18) && (w_operate)) txd_baudrate_o <= ldata_o;
	else txd_baudrate_o <= txd_baudrate_o;
end
always@(posedge p_clk_i or negedge p_rst_n_i) begin
	if(!p_rst_n_i) txd_frame_o <= 16'h400; //1024Byte
	else if((p_addr_i == 19) && (w_operate)) txd_frame_o <= ldata_o;
	else txd_frame_o <= txd_frame_o;
end
always@(posedge p_clk_i or negedge p_rst_n_i) begin
	if(!p_rst_n_i) txd_code_o <= 32'h9abcb52c; //0x9abcb52c
	else if((p_addr_i == 20) && (w_operate)) txd_code_o <= ldata_o;
	else txd_code_o <= txd_code_o;
end
always@(posedge p_clk_i or negedge p_rst_n_i) begin
	if(!p_rst_n_i) txd_pattern_o <= 2'h0; //RNRZL
	else if((p_addr_i == 21) && (w_operate)) txd_pattern_o <= ldata_o;
	else txd_pattern_o <= txd_pattern_o;
end
always@(posedge p_clk_i or negedge p_rst_n_i) begin
	if(!p_rst_n_i) txd_number_o <= 2'h0; //4Byte
	else if((p_addr_i == 22) && (w_operate)) txd_number_o <= ldata_o;
	else txd_number_o <= txd_number_o;
end
always@(posedge p_clk_i or negedge p_rst_n_i) begin
	if(!p_rst_n_i) txd_cntr_num_o <= 32'ha; //10Packs
	else if((p_addr_i == 23) && (w_operate)) txd_cntr_num_o <= ldata_o;
	else txd_cntr_num_o <= txd_cntr_num_o;
end
always@(posedge p_clk_i or negedge p_rst_n_i) begin
	if(!p_rst_n_i) txd_send_time_o <= 32'h7a120; //500000(5ms)
	else if((p_addr_i == 24) && (w_operate)) txd_send_time_o <= ldata_o;
	else txd_send_time_o <= txd_send_time_o;
end
// Pcm receive control interface 1
always@(posedge p_clk_i or negedge p_rst_n_i) begin
	if(!p_rst_n_i) rxd_number1_o <= 2'h0; //4Byte
	else if((p_addr_i == 37) && (w_operate)) rxd_number1_o <= ldata_o;
	else rxd_number1_o <= rxd_number1_o;
end
always@(posedge p_clk_i or negedge p_rst_n_i) begin
	if(!p_rst_n_i) rxd_pattern1_o <= 2'h0; //RNRZL
	else if((p_addr_i == 38) && (w_operate)) rxd_pattern1_o <= ldata_o;
	else rxd_pattern1_o <= rxd_pattern1_o;
end
always@(posedge p_clk_i or negedge p_rst_n_i) begin
	if(!p_rst_n_i) rxd_length1_o <= 16'h400; //1024Byte
	else if((p_addr_i == 39) && (w_operate)) rxd_length1_o <= ldata_o;
	else rxd_length1_o <= rxd_length1_o;
end
always@(posedge p_clk_i or negedge p_rst_n_i) begin
	if(!p_rst_n_i) rxd_code1_o <= 32'h9abcb52c; //0x9abcb52c
	else if((p_addr_i == 40) && (w_operate)) rxd_code1_o <= ldata_o;
	else rxd_code1_o <= rxd_code1_o;
end
always@(posedge p_clk_i or negedge p_rst_n_i) begin
	if(!p_rst_n_i) rxd_divisor1_o <= 16'h2710; //10000(10us)
	else if((p_addr_i == 41) && (w_operate)) rxd_divisor1_o <= ldata_o;
	else rxd_divisor1_o <= rxd_divisor1_o;
end
always@(posedge p_clk_i or negedge p_rst_n_i) begin
	if(!p_rst_n_i) rxd_filter_num1_o <= 16'h3; //3 clock cycles
	else if((p_addr_i == 42) && (w_operate)) rxd_filter_num1_o <= ldata_o;
	else rxd_filter_num1_o <= rxd_filter_num1_o;
end
// Pcm receive control interface 2
always@(posedge p_clk_i or negedge p_rst_n_i) begin
	if(!p_rst_n_i) rxd_number2_o <= 2'h0; //4Byte
	else if((p_addr_i == 53) && (w_operate)) rxd_number2_o <= ldata_o;
	else rxd_number2_o <= rxd_number2_o;
end
always@(posedge p_clk_i or negedge p_rst_n_i) begin
	if(!p_rst_n_i) rxd_pattern2_o <= 2'h0; //RNRZL
	else if((p_addr_i == 54) && (w_operate)) rxd_pattern2_o <= ldata_o;
	else rxd_pattern2_o <= rxd_pattern2_o;
end
always@(posedge p_clk_i or negedge p_rst_n_i) begin
	if(!p_rst_n_i) rxd_length2_o <= 16'h400; //1024Byte
	else if((p_addr_i == 55) && (w_operate)) rxd_length2_o <= ldata_o;
	else rxd_length2_o <= rxd_length2_o;
end
always@(posedge p_clk_i or negedge p_rst_n_i) begin
	if(!p_rst_n_i) rxd_code2_o <= 32'h9abcb52c; //0x9abcb52c
	else if((p_addr_i == 56) && (w_operate)) rxd_code2_o <= ldata_o;
	else rxd_code2_o <= rxd_code2_o;
end
always@(posedge p_clk_i or negedge p_rst_n_i) begin
	if(!p_rst_n_i) rxd_divisor2_o <= 16'h2710; //10000(10us)
	else if((p_addr_i == 57) && (w_operate)) rxd_divisor2_o <= ldata_o;
	else rxd_divisor2_o <= rxd_divisor2_o;
end
always@(posedge p_clk_i or negedge p_rst_n_i) begin
	if(!p_rst_n_i) rxd_filter_num2_o <= 16'h3; //3 clock cycles
	else if((p_addr_i == 58) && (w_operate)) rxd_filter_num2_o <= ldata_o;
	else rxd_filter_num2_o <= rxd_filter_num2_o;
end
// Pcm receive control interface 3
always@(posedge p_clk_i or negedge p_rst_n_i) begin
	if(!p_rst_n_i) rxd_number3_o <= 2'h0; //4Byte
	else if((p_addr_i == 69) && (w_operate)) rxd_number3_o <= ldata_o;
	else rxd_number3_o <= rxd_number3_o;
end
always@(posedge p_clk_i or negedge p_rst_n_i) begin
	if(!p_rst_n_i) rxd_pattern3_o <= 2'h0; //RNRZL
	else if((p_addr_i == 70) && (w_operate)) rxd_pattern3_o <= ldata_o;
	else rxd_pattern3_o <= rxd_pattern3_o;
end
always@(posedge p_clk_i or negedge p_rst_n_i) begin
	if(!p_rst_n_i) rxd_length3_o <= 16'h400; //1024Byte
	else if((p_addr_i == 71) && (w_operate)) rxd_length3_o <= ldata_o;
	else rxd_length3_o <= rxd_length3_o;
end
always@(posedge p_clk_i or negedge p_rst_n_i) begin
	if(!p_rst_n_i) rxd_code3_o <= 32'h9abcb52c; //0x9abcb52c
	else if((p_addr_i == 72) && (w_operate)) rxd_code3_o <= ldata_o;
	else rxd_code3_o <= rxd_code3_o;
end
always@(posedge p_clk_i or negedge p_rst_n_i) begin
	if(!p_rst_n_i) rxd_divisor3_o <= 16'h2710; //10000(10us)
	else if((p_addr_i == 73) && (w_operate)) rxd_divisor3_o <= ldata_o;
	else rxd_divisor3_o <= rxd_divisor3_o;
end
always@(posedge p_clk_i or negedge p_rst_n_i) begin
	if(!p_rst_n_i) rxd_filter_num3_o <= 16'h3; //3 clock cycles
	else if((p_addr_i == 74) && (w_operate)) rxd_filter_num3_o <= ldata_o;
	else rxd_filter_num3_o <= rxd_filter_num3_o;
end
// Pcm receive control interface 4
always@(posedge p_clk_i or negedge p_rst_n_i) begin
	if(!p_rst_n_i) rxd_number4_o <= 2'h0; //4Byte
	else if((p_addr_i == 85) && (w_operate)) rxd_number4_o <= ldata_o;
	else rxd_number4_o <= rxd_number4_o;
end
always@(posedge p_clk_i or negedge p_rst_n_i) begin
	if(!p_rst_n_i) rxd_pattern4_o <= 2'h0; //RNRZL
	else if((p_addr_i == 86) && (w_operate)) rxd_pattern4_o <= ldata_o;
	else rxd_pattern4_o <= rxd_pattern4_o;
end
always@(posedge p_clk_i or negedge p_rst_n_i) begin
	if(!p_rst_n_i) rxd_length4_o <= 16'h400; //1024Byte
	else if((p_addr_i == 87) && (w_operate)) rxd_length4_o <= ldata_o;
	else rxd_length4_o <= rxd_length4_o;
end
always@(posedge p_clk_i or negedge p_rst_n_i) begin
	if(!p_rst_n_i) rxd_code4_o <= 32'h9abcb52c; //0x9abcb52c
	else if((p_addr_i == 88) && (w_operate)) rxd_code4_o <= ldata_o;
	else rxd_code4_o <= rxd_code4_o;
end
always@(posedge p_clk_i or negedge p_rst_n_i) begin
	if(!p_rst_n_i) rxd_divisor4_o <= 16'h2710; //10000(10us)
	else if((p_addr_i == 89) && (w_operate)) rxd_divisor4_o <= ldata_o;
	else rxd_divisor4_o <= rxd_divisor4_o;
end
always@(posedge p_clk_i or negedge p_rst_n_i) begin
	if(!p_rst_n_i) rxd_filter_num4_o <= 16'h3; //3 clock cycles
	else if((p_addr_i == 90) && (w_operate)) rxd_filter_num4_o <= ldata_o;
	else rxd_filter_num4_o <= rxd_filter_num4_o;
end

// Pci read operate
assign ldata_i = ((p_addr_i == 0) && (r_operate)) ? test_reg : //test register
				 ((p_addr_i == 1) && (r_operate)) ? {28'h0,rst_n_o} :
				 ((p_addr_i == 2) && (r_operate)) ? {21'h0,pud_sel_o,tr_sel_o,lp_sel_o} :
				 ((p_addr_i == 3) && (r_operate)) ? {28'h0,rxd_ena_o} :
				 ((p_addr_i == 4) && (r_operate)) ? {28'h0,rxd_edge_o} :
				 ((p_addr_i == 5) && (r_operate)) ? alloc_mem_o :
				 ((p_addr_i == 6) && (r_operate)) ? {28'h0,rd_mode_o} :
				 // Pcm send control interface status
				 ((p_addr_i == 16) && (r_operate)) ? {31'h0,txd_start_o} :
				 ((p_addr_i == 17) && (r_operate)) ? {31'h0,txd_edge_o} :
				 ((p_addr_i == 18) && (r_operate)) ? {16'h0,txd_baudrate_o} :
				 ((p_addr_i == 19) && (r_operate)) ? {16'h0,txd_frame_o} :
				 ((p_addr_i == 20) && (r_operate)) ? txd_code_o :
				 ((p_addr_i == 21) && (r_operate)) ? {29'h0,txd_pattern_o} :
				 ((p_addr_i == 22) && (r_operate)) ? {30'h0,txd_number_o} :
				 ((p_addr_i == 23) && (r_operate)) ? txd_cntr_num_o :
				 ((p_addr_i == 24) && (r_operate)) ? txd_send_time_o :
				 // Pcm receive control interface 1 status
				 ((p_addr_i == 32) && (r_operate)) ? {19'h0,fifo_wr_usedw1_i} :
				 ((p_addr_i == 33) && (r_operate)) ? {18'h0,fifo_rd_usedw1_i} :
				 ((p_addr_i == 34) && (r_operate)) ? fifo_usedw1_i[31:0] :
				 ((p_addr_i == 35) && (r_operate)) ? fifo_usedw1_i[63:32] :
				 ((p_addr_i == 36) && (r_operate)) ? {fifo_rd_data1_i[7:0],fifo_rd_data1_i[15:8],fifo_rd_data1_i[23:16],fifo_rd_data1_i[31:24]} :
				 ((p_addr_i == 37) && (r_operate)) ? {30'h0,rxd_number1_o} :
				 ((p_addr_i == 38) && (r_operate)) ? {29'h0,rxd_pattern1_o} :
				 ((p_addr_i == 39) && (r_operate)) ? {16'h0,rxd_length1_o} :
				 ((p_addr_i == 40) && (r_operate)) ? rxd_code1_o :
				 ((p_addr_i == 41) && (r_operate)) ? {16'h0,rxd_divisor1_o} :
				 ((p_addr_i == 42) && (r_operate)) ? {16'h0,rxd_filter_num1_o} :
				 // Pcm receive control interface 2 status
				 ((p_addr_i == 48) && (r_operate)) ? {19'h0,fifo_wr_usedw2_i} :
				 ((p_addr_i == 49) && (r_operate)) ? {18'h0,fifo_rd_usedw2_i} :
				 ((p_addr_i == 50) && (r_operate)) ? fifo_usedw2_i[31:0] :
				 ((p_addr_i == 51) && (r_operate)) ? fifo_usedw2_i[63:32] :
				 ((p_addr_i == 52) && (r_operate)) ? {fifo_rd_data2_i[7:0],fifo_rd_data2_i[15:8],fifo_rd_data2_i[23:16],fifo_rd_data2_i[31:24]} :
				 ((p_addr_i == 53) && (r_operate)) ? {30'h0,rxd_number2_o} :
				 ((p_addr_i == 54) && (r_operate)) ? {29'h0,rxd_pattern2_o} :
				 ((p_addr_i == 55) && (r_operate)) ? {16'h0,rxd_length2_o} :
				 ((p_addr_i == 56) && (r_operate)) ? rxd_code2_o :
				 ((p_addr_i == 57) && (r_operate)) ? {16'h0,rxd_divisor2_o} :
				 ((p_addr_i == 58) && (r_operate)) ? {16'h0,rxd_filter_num2_o} :
				 // Pcm receive control interface 3 status
				 ((p_addr_i == 64) && (r_operate)) ? {19'h0,fifo_wr_usedw3_i} :
				 ((p_addr_i == 65) && (r_operate)) ? {18'h0,fifo_rd_usedw3_i} :
				 ((p_addr_i == 66) && (r_operate)) ? fifo_usedw3_i[31:0] :
				 ((p_addr_i == 67) && (r_operate)) ? fifo_usedw3_i[63:32] :
				 ((p_addr_i == 68) && (r_operate)) ? {fifo_rd_data3_i[7:0],fifo_rd_data3_i[15:8],fifo_rd_data3_i[23:16],fifo_rd_data3_i[31:24]} :
				 ((p_addr_i == 69) && (r_operate)) ? {30'h0,rxd_number3_o} :
				 ((p_addr_i == 70) && (r_operate)) ? {29'h0,rxd_pattern3_o} :
				 ((p_addr_i == 71) && (r_operate)) ? {16'h0,rxd_length3_o} :
				 ((p_addr_i == 72) && (r_operate)) ? rxd_code3_o :
				 ((p_addr_i == 73) && (r_operate)) ? {16'h0,rxd_divisor3_o} :
				 ((p_addr_i == 74) && (r_operate)) ? {16'h0,rxd_filter_num3_o} :
				 // Pcm receive control interface 4 status
				 ((p_addr_i == 80) && (r_operate)) ? {19'h0,fifo_wr_usedw4_i} :
				 ((p_addr_i == 81) && (r_operate)) ? {18'h0,fifo_rd_usedw4_i} :
				 ((p_addr_i == 82) && (r_operate)) ? fifo_usedw4_i[31:0] :
				 ((p_addr_i == 83) && (r_operate)) ? fifo_usedw4_i[63:32] :
				 ((p_addr_i == 84) && (r_operate)) ? {fifo_rd_data4_i[7:0],fifo_rd_data4_i[15:8],fifo_rd_data4_i[23:16],fifo_rd_data4_i[31:24]} :
				 ((p_addr_i == 85) && (r_operate)) ? {30'h0,rxd_number4_o} :
				 ((p_addr_i == 86) && (r_operate)) ? {29'h0,rxd_pattern4_o} :
				 ((p_addr_i == 87) && (r_operate)) ? {16'h0,rxd_length4_o} :
				 ((p_addr_i == 88) && (r_operate)) ? rxd_code4_o :
				 ((p_addr_i == 89) && (r_operate)) ? {16'h0,rxd_divisor4_o} :
				 ((p_addr_i == 90) && (r_operate)) ? {16'h0,rxd_filter_num4_o} :
				 ((p_addr_i == 91) && (r_operate)) ?  second_rx1 :
				 ((p_addr_i == 92) && (r_operate)) ?  n_second_rx1 :
				 ((p_addr_i == 93) && (r_operate)) ?  second_rx2 :
				 ((p_addr_i == 94) && (r_operate)) ?  n_second_rx2 :
				 ((p_addr_i == 95) && (r_operate)) ?  second_rx3 :
				 ((p_addr_i == 96) && (r_operate)) ?  n_second_rx3 :
				 ((p_addr_i == 97) && (r_operate)) ?  second_rx4 :
				 ((p_addr_i == 98) && (r_operate)) ?  n_second_rx4 :
				 ((p_addr_i == 253) && (r_operate)) ? {28'h0,fifo_back_rst4_o,fifo_back_rst3_o,fifo_back_rst2_o,fifo_back_rst1_o} :
				 ((p_addr_i == 254) && (r_operate)) ? {31'h0,sys_flag_i} :
				 ((p_addr_i == 255) && (r_operate)) ? 32'hfee5_0311 : 32'h5555_5555;        
assign fifo_rd_req1_o = ((p_addr_i == 36) && (r_operate)); //1 channel fifo read request
assign fifo_rd_req2_o = ((p_addr_i == 52) && (r_operate)); //2 channel fifo read request
assign fifo_rd_req3_o = ((p_addr_i == 68) && (r_operate)); //3 channel fifo read request
assign fifo_rd_req4_o = ((p_addr_i == 84) && (r_operate)); //4 channel fifo read request
detect_edge detect_edge1
(
	.clk_i(p_clk_i) ,
	.rst_n_i(p_rst_n_i) ,
	.signal_i(sync_flag_temp1) ,
	.signal_o(sync_flag1) 
);
detect_edge detect_edge2
(
	.clk_i(p_clk_i) ,
	.rst_n_i(p_rst_n_i) ,
	.signal_i(sync_flag_temp2) ,
	.signal_o(sync_flag2) 
);
detect_edge detect_edge3
(
	.clk_i(p_clk_i) ,
	.rst_n_i(p_rst_n_i) ,
	.signal_i(sync_flag_temp3) ,
	.signal_o(sync_flag3) 
);
detect_edge detect_edge4
(
	.clk_i(p_clk_i) ,
	.rst_n_i(p_rst_n_i) ,
	.signal_i(sync_flag_temp4) ,
	.signal_o(sync_flag4) 
);
punctual_time punctual_time_inst1(
    .local_clk_i(p_clk_i),
    .local_rst_n_i(p_rst_n_i),
    .PXI_trig0(PXI_trig0),
	.action_flag(sync_flag_temp1),
    .second(second_rx1),
    .n_second(n_second_rx1)
 );
punctual_time punctual_time_inst2(
    .local_clk_i(p_clk_i),
    .local_rst_n_i(p_rst_n_i),
    .PXI_trig0(PXI_trig0),
	.action_flag(sync_flag_temp2),
    .second(second_rx2),
    .n_second(n_second_rx2)
 );
 punctual_time punctual_time_inst3(
    .local_clk_i(p_clk_i),
    .local_rst_n_i(p_rst_n_i),
    .PXI_trig0(PXI_trig0),
	.action_flag(sync_flag_temp3),
    .second(second_rx3),
    .n_second(n_second_rx3)
 );
 punctual_time punctual_time_inst4(
    .local_clk_i(p_clk_i),
    .local_rst_n_i(p_rst_n_i),
    .PXI_trig0(PXI_trig0),
	.action_flag(sync_flag_temp4),
    .second(second_rx4),
    .n_second(n_second_rx4)
 );
	// User logic ends
ila_0 ila9054(
.clk(clk100M),
.probe0(PXI_trig0),
.probe1(sync_flag_temp1),
.probe2(n_second_rx1),
.probe3(second_rx1),
.probe4(pud_sel_o),
.probe5(tr_sel_o),
.probe6(lp_sel_o),
.probe7(rxd_ena_o),
.probe8(rxd_edge_o),
.probe9(txd_start_o),
.probe10(txd_edge_o),
.probe11(txd_baudrate_o),
.probe12(txd_code_o),
.probe13(txd_pattern_o),
.probe14(txd_number_o),
.probe15(fifo_rd_usedw1_i),
.probe16({fifo_rd_data1_i[7:0],fifo_rd_data1_i[15:8],fifo_rd_data1_i[23:16],fifo_rd_data1_i[31:24]}),
.probe17(rxd_number1_o),
.probe18(rxd_pattern1_o),
.probe19(rxd_length1_o),
.probe20(rxd_code1_o),
.probe21(rxd_filter_num1_o)
);
endmodule 