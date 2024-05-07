`timescale 1ns / 1ns
module data_distr#
(
   parameter integer ADDR_MEM_OFFSET = 32'h3000_0000
)
(
    // Main clock
    input clk_i,
    // Main reset
    input rst_n_i,
    // PCI control reset
    input [3:0] pci_rst_n_i,    
    // Axi control reset
    input [3:0] fifo_rst_i,
	// Set receive enable
	input [3:0] rxd_ena_i,
    // FDMA write interface
    output [31:0] fdma_waddr,
    output reg fdma_wareq,
    output [15:0] fdma_wsize,
    input fdma_wbusy,
    output [31:0] fdma_wdata,
    input fdma_wvalid,
    output fdma_wready,
    // FDMA read interface
    output [31:0] fdma_raddr,
    output reg fdma_rareq,
    output [15:0] fdma_rsize,
    input fdma_rbusy,
    input [31:0] fdma_rdata,
    input fdma_rvalid,
    output fdma_rready,
    // Fifo control
    input [31:0] fifo_rd_data1_i,
    output fifo_rd_req1_o,
    output [31:0] fifo_wr_data1_o,
    output fifo_wr_req1_o,
    input [31:0] fifo_rd_data2_i,
    output fifo_rd_req2_o,
    output [31:0] fifo_wr_data2_o,
    output fifo_wr_req2_o,
    input [31:0] fifo_rd_data3_i,
    output fifo_rd_req3_o,
    output [31:0] fifo_wr_data3_o,
    output fifo_wr_req3_o,
    input [31:0] fifo_rd_data4_i,
    output fifo_rd_req4_o,
    output [31:0] fifo_wr_data4_o,
    output fifo_wr_req4_o,
    input [12:0] fifo_wr_usedw1_i, 		//the front end fifo usedw 
    input [13:0] fifo_rd_usedw1_i, 		//the back end fifo usedw(write count)
    input [12:0] fifo_wr_usedw2_i,
    input [13:0] fifo_rd_usedw2_i,
    input [12:0] fifo_wr_usedw3_i,
    input [13:0] fifo_rd_usedw3_i,
    input [12:0] fifo_wr_usedw4_i,
    input [13:0] fifo_rd_usedw4_i,
	output reg [24:0] ddr_wr_usedw1,
	input [24:0] ddr_rd_usedw1,
	output reg [24:0] ddr_wr_usedw2,
	input [24:0] ddr_rd_usedw2,
	output reg [24:0] ddr_wr_usedw3,
	input [24:0] ddr_rd_usedw3,
	output reg [24:0] ddr_wr_usedw4,
	input [24:0] ddr_rd_usedw4,
	output reg [24:0] clr_rd_usedw1,
	input [24:0] clr_wr_usedw1,
	output reg [24:0] clr_rd_usedw2,
	input [24:0] clr_wr_usedw2,
	output reg [24:0] clr_rd_usedw3,
	input [24:0] clr_wr_usedw3,
	output reg [24:0] clr_rd_usedw4,
	input [24:0] clr_wr_usedw4,
	input [24:0] del_rd_usedw1,
	input [24:0] del_rd_usedw2,
	input [24:0] del_rd_usedw3,
	input [24:0] del_rd_usedw4
    );
// Control signal
reg [4:0] state;
reg [1:0] pointersel;
reg [15:0] fdma2ddr_size;
reg [31:0] fdma2ddr_addr;
wire [3:0] rxd_ena_sig;
wire cond_wr1,cond_wr2,cond_wr3,cond_wr4;
wire cond_rd1,cond_rd2,cond_rd3,cond_rd4;
wire pos_write_ack,neg_write_ack;
wire pos_read_ack,neg_read_ack;
reg write_ack_latch;
reg read_ack_latch;
reg [24:0] fdma_write_pointer1,fdma_write_pointer2,fdma_write_pointer3,fdma_write_pointer4;
reg [24:0] fdma_read_pointer1,fdma_read_pointer2,fdma_read_pointer3,fdma_read_pointer4;
wire rst_rd_flag1,rst_rd_flag2,rst_rd_flag3,rst_rd_flag4;
wire rst_wr_flag1,rst_wr_flag2,rst_wr_flag3,rst_wr_flag4;
wire [3:0] pci_rst_n_sig;
// State machine definition
parameter s_idle                = 5'b0_0001;
parameter s_wait_write_ack      = 5'b0_0010;
parameter s_wait_write_over     = 5'b0_0100;
parameter s_wait_read_ack       = 5'b0_1000;
parameter s_wait_read_over      = 5'b1_0000;

// Sync receive enable signal
xpm_cdc_array_single #(
	.DEST_SYNC_FF(4),				// DECIMAL; range: 2-10
	.INIT_SYNC_FF(0),				// DECIMAL; 0=disable simulation init values, 1=enable simulation init values
	.SIM_ASSERT_CHK(0),				// DECIMAL; 0=disable simulation messages, 1=enable simulation messages
	.SRC_INPUT_REG(0), 				// DECIMAL; 0=do not register input, 1=register input
	.WIDTH(4) 						// DECIMAL; range: 1-1024
)
xpm_cdc_array_single_inst (

	.dest_out(rxd_ena_sig),			// WIDTH-bit output: src_in synchronized to the destination clock domain. This output is registered.
	.dest_clk(clk_i),				// 1-bit input: Clock signal for the destination clock domain.
	.src_clk(0),					// 1-bit input: optional; required when SRC_INPUT_REG = 1
	.src_in(rxd_ena_i)				// WIDTH-bit input: Input single-bit array to be synchronized to destination clock
									// domain. It is assumed that each bit of the array is unrelated to the others. This
									// is reflected in the constraints applied to this macro. To transfer a binary value
									// losslessly across the two clock domains, use the XPM_CDC_GRAY macro instead.
);
xpm_cdc_array_single #(
	.DEST_SYNC_FF(4),				// DECIMAL; range: 2-10
	.INIT_SYNC_FF(0),				// DECIMAL; 0=disable simulation init values, 1=enable simulation init values
	.SIM_ASSERT_CHK(0),				// DECIMAL; 0=disable simulation messages, 1=enable simulation messages
	.SRC_INPUT_REG(0), 				// DECIMAL; 0=do not register input, 1=register input
	.WIDTH(4) 						// DECIMAL; range: 1-1024
)
xpm_cdc_array_single_inst1 (

	.dest_out(pci_rst_n_sig),		// WIDTH-bit output: src_in synchronized to the destination clock domain. This output is registered.
	.dest_clk(clk_i),		        // 1-bit input: Clock signal for the destination clock domain.
	.src_clk(0),					// 1-bit input: optional; required when SRC_INPUT_REG = 1
	.src_in(pci_rst_n_i)			// WIDTH-bit input: Input single-bit array to be synchronized to destination clock
									// domain. It is assumed that each bit of the array is unrelated to the others. This
									// is reflected in the constraints applied to this macro. To transfer a binary value
									// losslessly across the two clock domains, use the XPM_CDC_GRAY macro instead.
);
// zynq & pci reset
assign rst_wr_flag1 = rst_n_i & pci_rst_n_sig[0];
assign rst_wr_flag2 = rst_n_i & pci_rst_n_sig[1];
assign rst_wr_flag3 = rst_n_i & pci_rst_n_sig[2];
assign rst_wr_flag4 = rst_n_i & pci_rst_n_sig[3];
assign rst_rd_flag1 = rst_n_i & pci_rst_n_sig[0] & (!fifo_rst_i[0]);
assign rst_rd_flag2 = rst_n_i & pci_rst_n_sig[1] & (!fifo_rst_i[1]);
assign rst_rd_flag3 = rst_n_i & pci_rst_n_sig[2] & (!fifo_rst_i[2]);
assign rst_rd_flag4 = rst_n_i & pci_rst_n_sig[3] & (!fifo_rst_i[3]);

// Set transmission length
assign fdma_wsize = fdma2ddr_size / 4; //transmit as 32 bits
assign fdma_rsize = fdma2ddr_size / 4;
// Set the master ready
assign fdma_wready = 1'b1;
assign fdma_rready = 1'b1; 
// FDMA operation address   
assign fdma_waddr = fdma2ddr_addr;
assign fdma_raddr = fdma2ddr_addr;
// FDMA busy state judgment
always @(posedge clk_i) begin
	if(!rst_n_i) write_ack_latch <= 1'b0;
	else write_ack_latch <= fdma_wbusy;
end
always @(posedge clk_i) begin
	if(!rst_n_i) read_ack_latch <= 1'b0;
	else read_ack_latch <= fdma_rbusy;
end
assign pos_write_ack = (!write_ack_latch) && fdma_wbusy;
assign neg_write_ack = write_ack_latch && (!fdma_wbusy);
assign pos_read_ack = (!read_ack_latch) && fdma_rbusy;
assign neg_read_ack = read_ack_latch && (!fdma_rbusy);

// State machine start condition

// The data is sufficient and the fdma is free
assign cond_wr1 = ((fifo_wr_usedw1_i >= 13'h400) || ((fifo_wr_usedw1_i > 13'h0) && (!rxd_ena_sig[0]))) && (!fdma_wbusy);
assign cond_wr2 = ((fifo_wr_usedw2_i >= 13'h400) || ((fifo_wr_usedw2_i > 13'h0) && (!rxd_ena_sig[1]))) && (!fdma_wbusy);
assign cond_wr3 = ((fifo_wr_usedw3_i >= 13'h400) || ((fifo_wr_usedw3_i > 13'h0) && (!rxd_ena_sig[2]))) && (!fdma_wbusy);
assign cond_wr4 = ((fifo_wr_usedw4_i >= 13'h400) || ((fifo_wr_usedw4_i > 13'h0) && (!rxd_ena_sig[3]))) && (!fdma_wbusy);
// The ddr store has data and the FMDA is free and the back-end fifo is empty
assign cond_rd1 = (fifo_rd_usedw1_i <= 14'h1000) && (!fdma_rbusy) && ((ddr_rd_usedw1 >= 25'h1000) || ((ddr_rd_usedw1 > 25'h0) && (!rxd_ena_sig[0]))); 
assign cond_rd2 = (fifo_rd_usedw2_i <= 14'h1000) && (!fdma_rbusy) && ((ddr_rd_usedw2 >= 25'h1000) || ((ddr_rd_usedw2 > 25'h0) && (!rxd_ena_sig[1])));
assign cond_rd3 = (fifo_rd_usedw3_i <= 14'h1000) && (!fdma_rbusy) && ((ddr_rd_usedw3 >= 25'h1000) || ((ddr_rd_usedw3 > 25'h0) && (!rxd_ena_sig[2])));
assign cond_rd4 = (fifo_rd_usedw4_i <= 14'h1000) && (!fdma_rbusy) && ((ddr_rd_usedw4 >= 25'h1000) || ((ddr_rd_usedw4 > 25'h0) && (!rxd_ena_sig[3])));

// Main state
always @(posedge clk_i) begin
	if(!rst_n_i) state <= s_idle;
	else case(state)
		s_idle: if(cond_wr1) state <= s_wait_write_ack;
				else if(cond_wr2) state <= s_wait_write_ack;
				else if(cond_wr3) state <= s_wait_write_ack;
				else if(cond_wr4) state <= s_wait_write_ack;
				else if(cond_rd1) state <= s_wait_read_ack;
				else if(cond_rd2) state <= s_wait_read_ack;
				else if(cond_rd3) state <= s_wait_read_ack;
				else if(cond_rd4) state <= s_wait_read_ack; 
				else state <= s_idle;
		s_wait_write_ack: if(pos_write_ack) state <= s_wait_write_over;
						  else state <= s_wait_write_ack;
		s_wait_write_over: if(neg_write_ack) state <= s_idle;
						   else state <= s_wait_write_over;
		s_wait_read_ack: if(pos_read_ack) state <= s_wait_read_over;
						 else state <= s_wait_read_ack;
		s_wait_read_over: if(neg_read_ack) state <= s_idle;
						  else state <= s_wait_read_over;
		default: state <= s_idle;
	endcase
end
// FDMA write start control
always @(posedge clk_i) begin
	if(!rst_n_i) fdma_wareq <= 1'b0;
	else case(state)
		s_wait_write_ack: fdma_wareq <= 1'b1;
		default: fdma_wareq <= 1'b0;
	endcase
end
// FDMA read start control
always @(posedge clk_i) begin
	if(!rst_n_i) fdma_rareq <= 1'b0;
	else case(state)
		s_wait_read_ack: fdma_rareq <= 1'b1;
		default: fdma_rareq <= 1'b0;
	endcase
end
// Pointer select
always @ (posedge clk_i) begin
	if(!rst_n_i) pointersel <= 2'h0;
	else case(state)	
		s_idle: if(cond_wr1) pointersel <= 2'h0;
				else if(cond_wr2) pointersel <= 2'h1;
				else if(cond_wr3) pointersel <= 2'h2;
				else if(cond_wr4) pointersel <= 2'h3;
				else if(cond_rd1) pointersel <= 2'h0;
				else if(cond_rd2) pointersel <= 2'h1;
				else if(cond_rd3) pointersel <= 2'h2;
				else if(cond_rd4) pointersel <= 2'h3;
				else pointersel <= 2'h0;
		default: pointersel <= pointersel;	
	endcase	
end
// FDMA operation length
always @(posedge clk_i) begin
	if(!rst_n_i) fdma2ddr_size <= 16'h0;
	else case(state)
		s_wait_write_ack: if(pointersel == 2'h0) begin
							if(fifo_wr_usedw1_i >= 13'h400) fdma2ddr_size <= 16'h1000;
							else fdma2ddr_size <= fifo_wr_usedw1_i * 4; end
						  else if(pointersel == 2'h1) begin
							if(fifo_wr_usedw2_i >= 13'h400) fdma2ddr_size <= 16'h1000;
							else fdma2ddr_size <= fifo_wr_usedw2_i * 4; end
						  else if(pointersel == 2'h2) begin
							if(fifo_wr_usedw3_i >= 13'h400) fdma2ddr_size <= 16'h1000;
							else fdma2ddr_size <= fifo_wr_usedw3_i * 4; end
						  else if(pointersel == 2'h3) begin
							if(fifo_wr_usedw4_i >= 13'h400) fdma2ddr_size <= 16'h1000;
							else fdma2ddr_size <= fifo_wr_usedw4_i * 4; end
						  else fdma2ddr_size <= fdma2ddr_size;
		s_wait_read_ack:  if(pointersel == 2'h0) begin
							if(ddr_rd_usedw1 >= 25'h1000) fdma2ddr_size <= 16'h1000;
							else fdma2ddr_size <= ddr_rd_usedw1; end
						  else if(pointersel == 2'h1) begin
							if(ddr_rd_usedw2 >= 25'h1000) fdma2ddr_size <= 16'h1000;
							else fdma2ddr_size <= ddr_rd_usedw2; end
						  else if(pointersel == 2'h2) begin
							if(ddr_rd_usedw3 >= 25'h1000) fdma2ddr_size <= 16'h1000;
							else fdma2ddr_size <= ddr_rd_usedw3; end
						  else if(pointersel == 2'h3) begin
							if(ddr_rd_usedw4 >= 25'h1000) fdma2ddr_size <= 16'h1000;
							else fdma2ddr_size <= ddr_rd_usedw4; end
						  else fdma2ddr_size <= fdma2ddr_size;
		default: fdma2ddr_size <= fdma2ddr_size; //hold previous value
	endcase
end
// FDMA Operation DDR address
always @(posedge clk_i) begin
	if(!rst_n_i) fdma2ddr_addr <= ADDR_MEM_OFFSET;
	else case(state)
		s_wait_write_ack: if(pointersel == 2'h0) fdma2ddr_addr <= ADDR_MEM_OFFSET + fdma_write_pointer1;
						  else if(pointersel == 2'h1) fdma2ddr_addr <= ADDR_MEM_OFFSET + 32'h0200_0000 + fdma_write_pointer2;
						  else if(pointersel == 2'h2) fdma2ddr_addr <= ADDR_MEM_OFFSET + 32'h0400_0000 + fdma_write_pointer3;
						  else if(pointersel == 2'h3) fdma2ddr_addr <= ADDR_MEM_OFFSET + 32'h0600_0000 + fdma_write_pointer4;
						  else fdma2ddr_addr <= fdma2ddr_addr;
		s_wait_read_ack:  if(pointersel == 2'h0) fdma2ddr_addr <= ADDR_MEM_OFFSET + 32'h0800_0000 + fdma_read_pointer1;
						  else if(pointersel == 2'h1) fdma2ddr_addr <= ADDR_MEM_OFFSET + 32'h0a00_0000 + fdma_read_pointer2;
						  else if(pointersel == 2'h2) fdma2ddr_addr <= ADDR_MEM_OFFSET + 32'h0c00_0000 + fdma_read_pointer3;
						  else if(pointersel == 2'h3) fdma2ddr_addr <= ADDR_MEM_OFFSET + 32'h0e00_0000 + fdma_read_pointer4;
						  else fdma2ddr_addr <= fdma2ddr_addr;
		default: fdma2ddr_addr <= fdma2ddr_addr; //hold previous value
	endcase
end
// FDMA write pointer1
always @(posedge clk_i or negedge rst_wr_flag1) begin
	if(!rst_wr_flag1) fdma_write_pointer1 <= 25'h0;
	else case(state)
		s_wait_write_over: if(pointersel == 2'h0) begin
							if(neg_write_ack) begin 
								if((fdma_write_pointer1 + fdma2ddr_size) >= 25'h1f0_0000) fdma_write_pointer1 <= 25'h0;
								else fdma_write_pointer1 <= fdma_write_pointer1 + fdma2ddr_size; end
							else fdma_write_pointer1 <= fdma_write_pointer1; end
						   else fdma_write_pointer1 <= fdma_write_pointer1;
		default: fdma_write_pointer1 <= fdma_write_pointer1;
	endcase
end
// FDMA read pointer1
always @(posedge clk_i or negedge rst_rd_flag1) begin
	if(!rst_rd_flag1) fdma_read_pointer1 <= 25'h0;
	else case(state)
		s_wait_read_over: if(pointersel == 2'h0) begin
							if(neg_read_ack) begin 
								if((fdma_read_pointer1 + fdma2ddr_size) >= 25'h1f0_0000) fdma_read_pointer1 <= 25'h0;
								else fdma_read_pointer1 <= fdma_read_pointer1 + fdma2ddr_size; end
							else fdma_read_pointer1 <= fdma_read_pointer1; end
						  else fdma_read_pointer1 <= fdma_read_pointer1;
		default: fdma_read_pointer1 <= fdma_read_pointer1;
	endcase
end
// FDMA write pointer2
always @(posedge clk_i or negedge rst_wr_flag2) begin
	if(!rst_wr_flag2) fdma_write_pointer2 <= 25'h0;
	else case(state)
		s_wait_write_over: if(pointersel == 2'h1) begin
							if(neg_write_ack) begin 
								if((fdma_write_pointer2 + fdma2ddr_size) >= 25'h1f0_0000) fdma_write_pointer2 <= 25'h0;
								else fdma_write_pointer2 <= fdma_write_pointer2 + fdma2ddr_size; end
							else fdma_write_pointer2 <= fdma_write_pointer2; end
						   else fdma_write_pointer2 <= fdma_write_pointer2;
		default: fdma_write_pointer2 <= fdma_write_pointer2;
	endcase
end
// FDMA read pointer2
always @(posedge clk_i or negedge rst_rd_flag2) begin
	if(!rst_rd_flag2) fdma_read_pointer2 <= 25'h0;
	else case(state)
		s_wait_read_over: if(pointersel == 2'h1) begin
							if(neg_read_ack) begin 
								if((fdma_read_pointer2 + fdma2ddr_size) >= 25'h1f0_0000) fdma_read_pointer2 <= 25'h0;
								else fdma_read_pointer2 <= fdma_read_pointer2 + fdma2ddr_size; end
							else fdma_read_pointer2 <= fdma_read_pointer2; end
						  else fdma_read_pointer2 <= fdma_read_pointer2;
		default: fdma_read_pointer2 <= fdma_read_pointer2;
	endcase
end
// FDMA write pointer3
always @(posedge clk_i or negedge rst_wr_flag3) begin
	if(!rst_wr_flag3) fdma_write_pointer3 <= 25'h0;
	else case(state)
		s_wait_write_over: if(pointersel == 2'h2) begin
							if(neg_write_ack) begin 
								if((fdma_write_pointer3 + fdma2ddr_size) >= 25'h1f0_0000) fdma_write_pointer3 <= 25'h0;
								else fdma_write_pointer3 <= fdma_write_pointer3 + fdma2ddr_size; end
							else fdma_write_pointer3 <= fdma_write_pointer3; end
						   else fdma_write_pointer3 <= fdma_write_pointer3;
		default: fdma_write_pointer3 <= fdma_write_pointer3;
	endcase
end
// FDMA read pointer3
always @(posedge clk_i or negedge rst_rd_flag3) begin
	if(!rst_rd_flag3) fdma_read_pointer3 <= 25'h0;
	else case(state)
		s_wait_read_over: if(pointersel == 2'h2) begin
							if(neg_read_ack) begin 
								if((fdma_read_pointer3 + fdma2ddr_size) >= 25'h1f0_0000) fdma_read_pointer3 <= 25'h0;
								else fdma_read_pointer3 <= fdma_read_pointer3 + fdma2ddr_size; end
							else fdma_read_pointer3 <= fdma_read_pointer3; end
						  else fdma_read_pointer3 <= fdma_read_pointer3;
		default: fdma_read_pointer3 <= fdma_read_pointer3;
	endcase
end
// FDMA write pointer4
always @(posedge clk_i or negedge rst_wr_flag4) begin
	if(!rst_wr_flag4) fdma_write_pointer4 <= 25'h0;
	else case(state)
		s_wait_write_over: if(pointersel == 2'h3) begin
							if(neg_write_ack) begin 
								if((fdma_write_pointer4 + fdma2ddr_size) >= 25'h1f0_0000) fdma_write_pointer4 <= 25'h0;
								else fdma_write_pointer4 <= fdma_write_pointer4 + fdma2ddr_size; end
							else fdma_write_pointer4 <= fdma_write_pointer4; end
						   else fdma_write_pointer4 <= fdma_write_pointer4;
		default: fdma_write_pointer4 <= fdma_write_pointer4;
	endcase
end
// FDMA read pointer4
always @(posedge clk_i or negedge rst_rd_flag4) begin
	if(!rst_rd_flag4) fdma_read_pointer4 <= 25'h0;
	else case(state)
		s_wait_read_over: if(pointersel == 2'h3) begin
							if(neg_read_ack) begin 
								if((fdma_read_pointer4 + fdma2ddr_size) >= 25'h1f0_0000) fdma_read_pointer4 <= 25'h0;
								else fdma_read_pointer4 <= fdma_read_pointer4 + fdma2ddr_size; end
							else fdma_read_pointer4 <= fdma_read_pointer4; end
						  else fdma_read_pointer4 <= fdma_read_pointer4;
		default: fdma_read_pointer4 <= fdma_read_pointer4;
	endcase
end

// DDR write usedw counter 1
always @(posedge clk_i or negedge rst_wr_flag1) begin
	if(!rst_wr_flag1) ddr_wr_usedw1 <= 25'h0;
	else case(state)
		s_wait_write_over: if(pointersel == 2'h0) begin
							if(neg_write_ack) ddr_wr_usedw1 <= ddr_wr_usedw1 + fdma2ddr_size - clr_wr_usedw1;
							else ddr_wr_usedw1 <= ddr_wr_usedw1 - clr_wr_usedw1; end
						   else ddr_wr_usedw1 <= ddr_wr_usedw1 - clr_wr_usedw1;
		default: ddr_wr_usedw1 <= ddr_wr_usedw1 - clr_wr_usedw1;
	endcase
end
// DDR write usedw counter 2
always @(posedge clk_i or negedge rst_wr_flag2) begin
	if(!rst_wr_flag2) ddr_wr_usedw2 <= 25'h0;
	else case(state)
		s_wait_write_over: if(pointersel == 2'h1) begin
							if(neg_write_ack) ddr_wr_usedw2 <= ddr_wr_usedw2 + fdma2ddr_size - clr_wr_usedw2;
							else ddr_wr_usedw2 <= ddr_wr_usedw2 - clr_wr_usedw2; end
						   else ddr_wr_usedw2 <= ddr_wr_usedw2 - clr_wr_usedw2;
		default: ddr_wr_usedw2 <= ddr_wr_usedw2 - clr_wr_usedw2;
	endcase
end
// DDR write usedw counter 3
always @(posedge clk_i or negedge rst_wr_flag3) begin
	if(!rst_wr_flag3) ddr_wr_usedw3 <= 25'h0;
	else case(state)
		s_wait_write_over: if(pointersel == 2'h2) begin
							if(neg_write_ack) ddr_wr_usedw3 <= ddr_wr_usedw3 + fdma2ddr_size - clr_wr_usedw3;
							else ddr_wr_usedw3 <= ddr_wr_usedw3 - clr_wr_usedw3; end
						   else ddr_wr_usedw3 <= ddr_wr_usedw3 - clr_wr_usedw3;
		default: ddr_wr_usedw3 <= ddr_wr_usedw3 - clr_wr_usedw3;
	endcase
end
// DDR write usedw counter 4
always @(posedge clk_i or negedge rst_wr_flag4) begin
	if(!rst_wr_flag4) ddr_wr_usedw4 <= 25'h0;
	else case(state)
		s_wait_write_over: if(pointersel == 2'h3) begin
							if(neg_write_ack) ddr_wr_usedw4 <= ddr_wr_usedw4 + fdma2ddr_size - clr_wr_usedw4;
							else ddr_wr_usedw4 <= ddr_wr_usedw4 - clr_wr_usedw4; end
						   else ddr_wr_usedw4 <= ddr_wr_usedw4 - clr_wr_usedw4;
		default: ddr_wr_usedw4 <= ddr_wr_usedw4 - clr_wr_usedw4;
	endcase
end
// DDR read usedw counter 1
always @(posedge clk_i or negedge rst_rd_flag1) begin
	if(!rst_rd_flag1) clr_rd_usedw1 <= 25'h0;
	else case(state)
		s_wait_read_over: if(pointersel == 2'h0) begin
							if(neg_read_ack) clr_rd_usedw1 <= clr_rd_usedw1 + fdma2ddr_size - del_rd_usedw1;
							else clr_rd_usedw1 <= clr_rd_usedw1 - del_rd_usedw1; end
						  else clr_rd_usedw1 <= clr_rd_usedw1 - del_rd_usedw1;
		default: clr_rd_usedw1 <= clr_rd_usedw1 - del_rd_usedw1;
	endcase
end
// DDR read usedw counter 2
always @(posedge clk_i or negedge rst_rd_flag2) begin
	if(!rst_rd_flag2) clr_rd_usedw2 <= 25'h0;
	else case(state)
		s_wait_read_over: if(pointersel == 2'h1) begin
							if(neg_read_ack) clr_rd_usedw2 <= clr_rd_usedw2 + fdma2ddr_size - del_rd_usedw2;
							else clr_rd_usedw2 <= clr_rd_usedw2 - del_rd_usedw2; end
						  else clr_rd_usedw2 <= clr_rd_usedw2 - del_rd_usedw2;
		default: clr_rd_usedw2 <= clr_rd_usedw2 - del_rd_usedw2;
	endcase
end
// DDR read usedw counter 3
always @(posedge clk_i or negedge rst_rd_flag3) begin
	if(!rst_rd_flag3) clr_rd_usedw3 <= 25'h0;
	else case(state)
		s_wait_read_over: if(pointersel == 2'h2) begin
							if(neg_read_ack) clr_rd_usedw3 <= clr_rd_usedw3 + fdma2ddr_size - del_rd_usedw3;
							else clr_rd_usedw3 <= clr_rd_usedw3 - del_rd_usedw3; end
						  else clr_rd_usedw3 <= clr_rd_usedw3 - del_rd_usedw3;
		default: clr_rd_usedw3 <= clr_rd_usedw3 - del_rd_usedw3;
	endcase
end
// DDR read usedw counter 4
always @(posedge clk_i or negedge rst_rd_flag4) begin
	if(!rst_rd_flag4) clr_rd_usedw4 <= 25'h0;
	else case(state)
		s_wait_read_over: if(pointersel == 2'h3) begin
							if(neg_read_ack) clr_rd_usedw4 <= clr_rd_usedw4 + fdma2ddr_size - del_rd_usedw4;
							else clr_rd_usedw4 <= clr_rd_usedw4 - del_rd_usedw4; end
						  else clr_rd_usedw4 <= clr_rd_usedw4 - del_rd_usedw4;
		default: clr_rd_usedw4 <= clr_rd_usedw4 - del_rd_usedw4;
	endcase
end
// Gating multiple channel data to FDMA     
assign fdma_wdata = (pointersel == 2'h0) ? fifo_rd_data1_i :
                    (pointersel == 2'h1) ? fifo_rd_data2_i :
                    (pointersel == 2'h2) ? fifo_rd_data3_i : fifo_rd_data4_i;
assign fifo_rd_req1_o = (pointersel == 2'h0) ? fdma_wvalid : 1'b0;
assign fifo_rd_req2_o = (pointersel == 2'h1) ? fdma_wvalid : 1'b0;
assign fifo_rd_req3_o = (pointersel == 2'h2) ? fdma_wvalid : 1'b0;
assign fifo_rd_req4_o = (pointersel == 2'h3) ? fdma_wvalid : 1'b0;
// Divide FDMA data among multiple channels
assign fifo_wr_data1_o = (pointersel == 2'h0) ? fdma_rdata : 32'h0;
assign fifo_wr_data2_o = (pointersel == 2'h1) ? fdma_rdata : 32'h0;
assign fifo_wr_data3_o = (pointersel == 2'h2) ? fdma_rdata : 32'h0;
assign fifo_wr_data4_o = (pointersel == 2'h3) ? fdma_rdata : 32'h0;
assign fifo_wr_req1_o = (pointersel == 2'h0) ? fdma_rvalid : 1'b0;
assign fifo_wr_req2_o = (pointersel == 2'h1) ? fdma_rvalid : 1'b0;
assign fifo_wr_req3_o = (pointersel == 2'h2) ? fdma_rvalid : 1'b0;
assign fifo_wr_req4_o = (pointersel == 2'h3) ? fdma_rvalid : 1'b0;

endmodule
