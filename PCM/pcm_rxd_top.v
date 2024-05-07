/********************************************************************
* File: pcm_rxd_top.v												*
* Author: Chen Cen													*
* History:															*
*	2020.07.27 setup												*
*	2021.09.05 add filter number settings							*
*	2021.09.14 add data decrypt										*
* Description:														*
*   pcm receive control logic.										*
*   the data format is time code, data, and frame header.			*
*********************************************************************/
module pcm_rxd_top(
//control interface
	input clk_i,				//main clock
	input rst_n_i,				//main reset
	input rxd_en_i,				//receive enable
	input edge_i,				//pcm edge selection 0:falling edge rollover,1:rising edge rollover
	input[1:0]number_i,			//synchronous code num
	input[15:0]length_i,		//set frame length
	input[31:0]code_i,			//set synchronous code
	input [2:0]pattern_i,		//set code pattern
    input [15:0]divisor_i,		//calculate the time according to the master clock,make sure the frequency is 10khz	
	input [15:0]filter_num_i,	//set filter number
	input rxd_data_i,			//pcm input data
	input rxd_clk_i,			//pcm input clock
	output[7:0]wr_data_o,		//output pcm received data
	output wr_req_o,		    //output pcm received request
	output sync_flag_temp	//detected synchronous code flag
);
//-------------- reg control ---------------//
(* MARK_DEBUG="true" *) wire lv_rxd_data;		//filtered data
(* MARK_DEBUG="true" *) wire lv_rxd_clk;		//filtered clock
(* MARK_DEBUG="true" *) wire de_rxd_data;		//decrypt data
wire [7:0]pcm_data;		//pcm receive data
wire pcm_req_temp;		//pcm request
wire end_flag_temp;		//receive complete 1 frame flag
wire [7:0]head_data;	//frame head data
wire head_req;			//frame head request
wire head_flag;			//inset head flag
wire [7:0]timer_data;	//timer data
wire timer_req;			//timer request
wire timer_flag;		//inset time flag
wire pcm_req;			//synchronous pcm write request
wire sync_flag;			//inset time start flag
wire end_flag;			//inset frame head start flag
//---------- signal filter control ----------//
shake_filter shake_filter_data(
	.clk_i(clk_i),
	.rst_n_i(rst_n_i),
	.num_i(filter_num_i),
	.data_i(rxd_data_i),
	.data_o(lv_rxd_data)	//output filter data
);
shake_filter shake_filter_clk(
	.clk_i(clk_i),
	.rst_n_i(rst_n_i),
	.num_i(filter_num_i),
	.data_i(rxd_clk_i),
	.data_o(lv_rxd_clk)	//output filter data
);
//------------ decrypt control -------------//
pcm_decrypt pcm_decrypt_inst(
	.clk_i(lv_rxd_clk),
	.rst_n_i(rst_n_i),
	.pattern_i(pattern_i),
	.edge_i(edge_i),
	.data_i(lv_rxd_data),
	.data_o(de_rxd_data)
); 
//---------- pcm receive control -----------//
pcm_receiver pcm_receiver_inst
(
	.rst_n_i(rst_n_i) ,
	.rxd_data_i(de_rxd_data) ,
	.rxd_clk_i(lv_rxd_clk) ,
	.rxd_en_i(rxd_en_i) ,
	.edge_i(edge_i),
	.number_i(number_i) ,
	.length_i(length_i) ,
	.code_i(code_i) ,
	.wr_data_o(pcm_data) ,
	.wr_req_o(pcm_req_temp), 
	.sync_flag_o(sync_flag_temp), 
	.end_flag_o(end_flag_temp)
);
//------- frame head inset control ---------//
head_insert head_insert_inst
(
	.clk_i(clk_i) ,
	.rst_n_i(rst_n_i) ,
	.start_i(end_flag) ,
	.number_i(number_i) ,
	.code_i(code_i) ,
	.wr_data_o(head_data) ,
	.wr_req_o(head_req) ,
	.flag_o(head_flag)
);
//---------- timer inset control -----------//
timer_insert timer_insert_inst
(
	.clk_i(clk_i) ,
	.rst_n_i(rst_n_i) ,
	.start_i(sync_flag) ,
	.divisor_i(divisor_i),
	.wr_data_o(timer_data) ,
	.wr_req_o(timer_req) ,
	.flag_o(timer_flag)
);
//---------- status flag control -----------//
detect_edge detect_edge1
(
	.clk_i(clk_i) ,
	.rst_n_i(rst_n_i) ,
	.signal_i(pcm_req_temp) ,
	.signal_o(pcm_req) 
);
detect_edge detect_edge2
(
	.clk_i(clk_i) ,
	.rst_n_i(rst_n_i) ,
	.signal_i(sync_flag_temp) ,
	.signal_o(sync_flag) 
);
detect_edge detect_edge3
(
	.clk_i(clk_i) ,
	.rst_n_i(rst_n_i) ,
	.signal_i(end_flag_temp) ,
	.signal_o(end_flag)
);
//------- control data or frame head -------//
assign wr_data_o  = (head_flag  == 1'b1) ? head_data:
					(timer_flag == 1'b1) ? timer_data: pcm_data;
assign wr_req_o   = (head_flag  == 1'b1) ? head_req :
					(timer_flag == 1'b1) ? timer_req: pcm_req;
endmodule 