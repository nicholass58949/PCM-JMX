`timescale 1ns / 1ns
module pcm_intf(
	input clk_i, 						//main clock
	input [3:0] rst_n_i, 				//reset signal
	input [3:0] lp_sel_i, 				//set send and receive loops
	input [3:0] rxd_ena_i, 				//set receive enable
	input [3:0] rxd_edge_i, 			//set receive edge
	// Pcm send control interface
	input txd_start_i, 					//start sending test data
	input txd_edge_i, 					//send edge
	input [15:0] txd_baudrate_i, 		//send baudrate
	input [15:0] txd_frame_i, 			//send framlength 
	input [31:0] txd_code_i, 			//send synchronous code
	input [2:0] txd_pattern_i, 			//send code pattern
	input [1:0] txd_number_i, 			//send synchronous code length
	input [31:0] txd_cntr_num_i, 		//send frame count
	input [31:0] txd_send_time_i, 		//send interval time
	// Pcm receive control interface 1
	input [1:0] rxd_number1_i, 			//synchronous code num
	input [2:0] rxd_pattern1_i,			//set code pattern	
	input [15:0] rxd_length1_i,			//set frame length
	input [31:0] rxd_code1_i, 			//set synchronous code
	input [15:0] rxd_divisor1_i, 		//calculate the time according to the master clock,make sure the frequency is 10khz
	input [15:0] rxd_filter_num1_i, 	//set filter number
	// Pcm receive control interface 2
	input [1:0] rxd_number2_i,
	input [2:0] rxd_pattern2_i,
	input [15:0] rxd_length2_i,
	input [31:0] rxd_code2_i,
	input [15:0] rxd_divisor2_i,
	input [15:0] rxd_filter_num2_i,
	// Pcm receive control interface 3
	input [1:0] rxd_number3_i,
	input [2:0] rxd_pattern3_i,
	input [15:0] rxd_length3_i,
	input [31:0] rxd_code3_i,
	input [15:0] rxd_divisor3_i,
	input [15:0] rxd_filter_num3_i,
	// Pcm receive control interface 4
	input [1:0] rxd_number4_i,
	input [2:0] rxd_pattern4_i,
	input [15:0] rxd_length4_i,
	input [31:0] rxd_code4_i,
	input [15:0] rxd_divisor4_i,
	input [15:0] rxd_filter_num4_i,
	// Fifo control interface
	output fifo_rst1_o,			        //high reset
	output fifo_rst2_o,
	output fifo_rst3_o,
	output fifo_rst4_o,
	output fifo_wr_req1_o,				//write the received data to the fifo
	output [7:0]fifo_wr_data1_o,
	output fifo_wr_req2_o,
	output [7:0]fifo_wr_data2_o,
	output fifo_wr_req3_o,
	output [7:0]fifo_wr_data3_o,
	output fifo_wr_req4_o,
	output [7:0]fifo_wr_data4_o,
	// Port 1(rs485)
(* MARK_DEBUG="true" *) input rx_data1_i,
(* MARK_DEBUG="true" *) input rx_clk1_i,
	output rx_en1_o,
	// Port 2(rs485)
(* MARK_DEBUG="true" *) input rx_data2_i,
(* MARK_DEBUG="true" *) input rx_clk2_i,
	output rx_en2_o,
	// Port 3(rs422)
(* MARK_DEBUG="true" *) input rx_data3_i,
(* MARK_DEBUG="true" *) input rx_clk3_i,
	output rx_en3_o,         
(* MARK_DEBUG="true" *) output tx_data3_o,
(* MARK_DEBUG="true" *) output tx_clk3_o,
	output tx_en3_o, 
	// Port 4(lvds)
(* MARK_DEBUG="true" *) input rx_data4_i,
(* MARK_DEBUG="true" *) input rx_clk4_i,
	output rx_en4_o,         
(* MARK_DEBUG="true" *) output tx_data4_o,
(* MARK_DEBUG="true" *) output tx_clk4_o,
	output tx_en4_o,
	output sync_flag_temp1,
	output sync_flag_temp2,
	output sync_flag_temp3,
	output sync_flag_temp4              
    );
// Reg
wire txd_data_sig;
wire txd_clk_sig;
// Convert to high reset
assign {fifo_rst4_o,fifo_rst3_o,fifo_rst2_o,fifo_rst1_o} = ~rst_n_i;
// Interface chip enable control
assign rx_en1_o = 1'b1;
assign rx_en2_o = 1'b1;
assign rx_en3_o = 1'b0;
assign rx_en4_o = 1'b1;
assign tx_en3_o = (lp_sel_i[2:0] >= 3'h1); //rs422,485
assign tx_en4_o = (lp_sel_i[3] == 1'b1); //lvds
// Loop test data
assign tx_data3_o = (lp_sel_i[2:0] >= 3'h1) ? txd_data_sig : 1'b1; 
assign tx_clk3_o  = (lp_sel_i[2:0] >= 3'h1) ? txd_clk_sig : 1'b1; 
assign tx_data4_o = (lp_sel_i[3] == 1'b1) ? txd_data_sig : 1'b1; 
assign tx_clk4_o  = (lp_sel_i[3] == 1'b1) ? txd_clk_sig : 1'b1;       

// PCM sending interface
pcm_txd_top pcm_txd_top_inst(
	.clk_i(clk_i),
	.rst_n_i(rst_n_i != 4'h0),	//Reset during global reset
	.start_i(txd_start_i),
	.edge_i(txd_edge_i),
	.baudrate_i(txd_baudrate_i),
	.length_i(txd_frame_i),
	.code_i(txd_code_i),
	.pattern_i(txd_pattern_i),
	.number_i(txd_number_i),
	.cntr_num_i(txd_cntr_num_i),
	.send_time_i(txd_send_time_i),
	.data_o(txd_data_sig),
	.clk_o(txd_clk_sig)
);
// PCM receiving interface 1
pcm_rxd_top pcm_rxd_top_inst1(
	.clk_i(clk_i),
	.rst_n_i(rst_n_i[0]),
	.rxd_en_i(rxd_ena_i[0]),
	.edge_i(rxd_edge_i[0]),
	.number_i(rxd_number1_i),
	.length_i(rxd_length1_i),
	.code_i(rxd_code1_i),
	.pattern_i(rxd_pattern1_i),
	.divisor_i(rxd_divisor1_i),
	.filter_num_i(rxd_filter_num1_i),
	.rxd_data_i(rx_data1_i),
	.rxd_clk_i(rx_clk1_i),
	.wr_data_o(fifo_wr_data1_o),
	.wr_req_o(fifo_wr_req1_o),
	.sync_flag_temp(sync_flag_temp1)
); 
// PCM receiving interface 2
pcm_rxd_top pcm_rxd_top_inst2(
	.clk_i(clk_i),
	.rst_n_i(rst_n_i[1]),
	.rxd_en_i(rxd_ena_i[1]),
	.edge_i(rxd_edge_i[1]),
	.number_i(rxd_number2_i),
	.length_i(rxd_length2_i),
	.code_i(rxd_code2_i),
	.pattern_i(rxd_pattern2_i),
	.divisor_i(rxd_divisor2_i),
	.filter_num_i(rxd_filter_num2_i),
	.rxd_data_i(rx_data2_i),
	.rxd_clk_i(rx_clk2_i),
	.wr_data_o(fifo_wr_data2_o),
	.wr_req_o(fifo_wr_req2_o),
	.sync_flag_temp(sync_flag_temp2)
);
// PCM receiving interface 3
pcm_rxd_top pcm_rxd_top_inst3(
	.clk_i(clk_i),
	.rst_n_i(rst_n_i[2]),
	.rxd_en_i(rxd_ena_i[2]),
	.edge_i(rxd_edge_i[2]),
	.number_i(rxd_number3_i),
	.length_i(rxd_length3_i),
	.code_i(rxd_code3_i),
	.pattern_i(rxd_pattern3_i),
	.divisor_i(rxd_divisor3_i),
	.filter_num_i(rxd_filter_num3_i),
	.rxd_data_i(rx_data3_i),
	.rxd_clk_i(rx_clk3_i),
	.wr_data_o(fifo_wr_data3_o),
	.wr_req_o(fifo_wr_req3_o),
	.sync_flag_temp(sync_flag_temp3)
);
// PCM receiving interface 4
pcm_rxd_top pcm_rxd_top_inst4(
	.clk_i(clk_i),
	.rst_n_i(rst_n_i[3]),
	.rxd_en_i(rxd_ena_i[3]),
	.edge_i(rxd_edge_i[3]),
	.number_i(rxd_number4_i),
	.length_i(rxd_length4_i),
	.code_i(rxd_code4_i),
	.pattern_i(rxd_pattern4_i),
	.divisor_i(rxd_divisor4_i),
	.filter_num_i(rxd_filter_num4_i),
	.rxd_data_i(rx_data4_i),
	.rxd_clk_i(rx_clk4_i),
	.wr_data_o(fifo_wr_data4_o),
	.wr_req_o(fifo_wr_req4_o),
	.sync_flag_temp(sync_flag_temp4)
); 
endmodule
