/************************************************************************
* File: pcm_receiver.v													*
* Author: Chen Cen														*
* History:																*
*   2017.9.4 setup														*
*   2020.7.27 add comments and change the interface name				*
*   2024.1.25 change clock edge				                            *
* Description:															*
*   pcm receiver logic.													*
*************************************************************************/
module pcm_receiver (
	input rst_n_i,					//main reset
	input rxd_data_i,				//pcm input data
	input rxd_clk_i,				//pcm input clock
	input rxd_en_i,					//receive enable
	input edge_i,					//pcm edge selection 0:falling edge rollover,1:rising edge rollover
	input[1:0]number_i,				//synchronous code num
	input[15:0]length_i,			//set frame length
	input[31:0]code_i,				//set synchronous code
	output reg[7:0]wr_data_o,		//output pcm data
	output reg wr_req_o,			//output pcm wirte signal
	output reg sync_flag_o,			//output synchronous code flag
	output reg end_flag_o			//output end of frame flag
);
//---------------reg control--------------
(* MARK_DEBUG="true" *) reg[3:0]state;			//state machine
(* MARK_DEBUG="true" *) reg[7:0]shift;			//receive data shift
(* MARK_DEBUG="true" *) reg[31:0]syncode_rec;	//receive synchronous head
(* MARK_DEBUG="true" *) reg[3:0]edge_count;		//receive data bit count
(* MARK_DEBUG="true" *) reg[15:0]frame_count;	//receive frame count 
(* MARK_DEBUG="true" *) wire rxd_clk_sig;		//receive clock temp
//-------pcm receiver state machine-------
localparam s_idle				= 4'b0001;
localparam s_detect_syncode		= 4'b0010;
localparam s_receive_data		= 4'b0100;
localparam s_stop				= 4'b1000;
assign rxd_clk_sig = (edge_i == 1'b0) ? rxd_clk_i : ~rxd_clk_i;
//--------main state machine run----------
always@(posedge rxd_clk_sig or negedge rst_n_i) begin
	if(~rst_n_i) state <= s_idle;	
	else case(state)
		s_idle			: begin if(rxd_en_i) state <= s_detect_syncode;		//detect enable signal
								else state <= s_idle; end
		s_detect_syncode: begin if(sync_flag_o) state <= s_receive_data;	//detect synchronous code
								else state <= s_detect_syncode; end
		s_receive_data	: begin if(edge_count >= 4'b0111) state <= s_stop;
								else state <= s_receive_data; end
		s_stop			: begin	if(~rxd_en_i) state <= s_idle;
								else if(frame_count >= length_i + number_i) state <= s_detect_syncode;
								else state <= s_receive_data; end
		default: begin state <= s_idle; end
	endcase
end
//-------receive synchronous code---------
always@(posedge rxd_clk_sig or negedge rst_n_i) begin
	if(~rst_n_i) syncode_rec <= 32'h0;
	else case(state)
		s_detect_syncode: begin syncode_rec <= {syncode_rec[30:0],rxd_data_i}; end
		s_stop			: begin if(frame_count >= length_i + number_i)
									syncode_rec <= {syncode_rec[30:0],rxd_data_i};
								else syncode_rec <= 32'h0; end
		default			: begin syncode_rec <= 32'h0; end
	endcase
end
//-------judgment synchronous code--------
always@(negedge rxd_clk_sig or negedge rst_n_i) begin
	if(~rst_n_i) sync_flag_o <= 1'b0;	
	else case(state)
		s_detect_syncode: begin if(number_i == 2'b00) sync_flag_o = (code_i == syncode_rec);
								else if(number_i == 2'b01) sync_flag_o = (code_i[23:0] == syncode_rec[23:0]);
								else if(number_i == 2'b10) sync_flag_o = (code_i[15:0] == syncode_rec[15:0]);
								else sync_flag_o = (code_i[7:0] == syncode_rec[7:0]); end
		default			: begin  sync_flag_o <= 1'b0; end
	endcase
end
//---------receiving shift buffer---------
always @(posedge rxd_clk_sig or negedge rst_n_i) begin
	if(~rst_n_i) shift <= 8'hff;
	else case(state)
		s_detect_syncode: begin if(sync_flag_o) shift <= {shift[6:0],rxd_data_i};
								else shift <= 8'hff; end
		s_receive_data	: begin shift <= {shift[6:0],rxd_data_i}; end
		s_stop			: begin shift <= {shift[6:0],rxd_data_i}; end
		default			: begin shift <= 8'hff; end
	endcase
end
//-----------receive edge count-----------
always @(posedge rxd_clk_sig or negedge rst_n_i) begin
	if(~rst_n_i) edge_count <= 4'b0000;
	else case(state)
		s_detect_syncode: begin if(sync_flag_o) edge_count <= edge_count + 1'b1;
								else edge_count <= 4'b0000; end
		s_receive_data	: begin if(edge_count >= 4'b0111) edge_count <= 4'b0000;
								else edge_count <= edge_count + 1'b1; end
		s_stop			: begin edge_count <= edge_count + 1'b1; end
		default			: begin edge_count <= 4'b0000; end
	endcase
end
//-------output receive data 1byte--------
always@(posedge rxd_clk_sig or negedge rst_n_i) begin
	if(~rst_n_i) wr_data_o <= 8'hff;
	else case(state)
		s_stop : begin wr_data_o <= shift; end
		default: begin wr_data_o <= wr_data_o; end
	endcase
end
//--------output fifo wirte signal--------
always@(posedge rxd_clk_sig or negedge rst_n_i) begin
	if(~rst_n_i) wr_req_o <= 1'b0;
	else case(state)
		s_stop : begin wr_req_o <= 1'b1; end
		default: begin wr_req_o <= 1'b0; end
	endcase
end
//-----------frame length count-----------
always@(posedge rxd_clk_sig or negedge rst_n_i) begin
	if(~rst_n_i) frame_count <= 16'h5;	
	else case(state)
		s_receive_data: begin frame_count <= frame_count; end
		s_stop		  : begin frame_count <= frame_count + 1'b1; end
		default		  : begin frame_count <= 16'h5; end
	endcase
end
//------frame head wirte flag signal------
always@(posedge rxd_clk_sig or negedge rst_n_i) begin
	if(~rst_n_i) end_flag_o <= 1'b0;
	else case(state)
		s_stop : begin if(frame_count >= length_i + number_i) end_flag_o <= 1'b1;
					   else end_flag_o <= 1'b0; end
		default: begin end_flag_o <= 1'b0; end
	endcase
end
endmodule