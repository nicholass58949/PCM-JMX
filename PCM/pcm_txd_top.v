/********************************************************************
* File: pcm_txd_top.v												*
* Author: Chen Cen													*
* History:															*
*	2021.09.14 setup												*
* Description:														*
*   pcm send control logic.data 0x00~0xff.							*
*   test receiver using.											*
*********************************************************************/
module pcm_txd_top(
//control interface
	input clk_i,				//main clock
	input rst_n_i,				//main reset
(* MARK_DEBUG="true" *)	input start_i,				//start send
	input edge_i,				//send edge selection 0:rising edge rollover,1:falling edge rollover
	input[15:0]baudrate_i,		//set baudrate  = clock_frequency / baudrate
	input[15:0]length_i,		//set send framlength 
	input[31:0]code_i,			//set synchronous code
	input [2:0]pattern_i,		//set code pattern
	input[1:0] number_i,		//set send synchronous code length 0:4byte,1:3byte,2:2byte
	input [31:0] cntr_num_i,	//send frame count
	input [31:0] send_time_i,	//interval time
	output data_o,				//send data
	output clk_o				//send clock
);
//-------------- reg control ---------------//
(* MARK_DEBUG="true" *) wire data_temp;
//------------ encrypt control -------------//
pcm_encrypt pcm_encrypt_inst(
	.clk_i(clk_o),
	.rst_n_i(rst_n_i),
	.pattern_i(pattern_i),
	.edge_i(edge_i),
	.data_i(data_temp),
	.data_o(data_o)
); 
//------------ pcm send control ------------//
pcm_transmitter pcm_transmitter_inst
(
	.clk_i(clk_i) ,
	.rst_n_i(rst_n_i) ,
	.start_i(start_i) ,
	.edge_i(edge_i),
	.baudrate_i(baudrate_i) ,
	.length_i(length_i) ,
	.code_i(code_i) ,
	.number_i(number_i) ,
	.cntr_num_i(cntr_num_i),
	.send_time_i(send_time_i),
	.data_o(data_temp) ,
	.clk_o(clk_o)
);
endmodule 