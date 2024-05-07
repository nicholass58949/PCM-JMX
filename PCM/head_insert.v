/****************************************************************************
* File: head_insert.v														*
* Author: Chen Cen															*
* History:																	*
*   2017.09.14 setup														*
*   2020.07.27 add comments and change the interface name					*
*   2023.07.27 added frame header 1 byte mode								*
* Description:																*
*   frame head insert logic.												*
*****************************************************************************/
module head_insert (
	input clk_i,						//main clock
	input rst_n_i,						//main reset
	input start_i,						//detect insert head signal
	input[1:0]number_i,					//synchronous code num,0:4byte ~ 3:1byte
	input[31:0]code_i,					//synchronous code
	output reg[7:0]wr_data_o,			//output frame head data
	output reg wr_req_o,				//output frame head wirte signal
	output reg flag_o					//output frame head wirte signal flag
);
//---------------reg control--------------
reg[3:0]state;	//state run
reg[31:0]shift;	//used to cache synchronization codes
reg[3:0]count;	//byte count
//----insert frame head state machine-----
localparam s_idle		 = 4'b0001;
localparam s_process	 = 4'b0010;
localparam s_delay		 = 4'b0100;
localparam s_data		 = 4'b1000;
//--------main state machine run----------
always@(posedge clk_i or negedge rst_n_i) begin
	if(~rst_n_i) state <= s_idle;
	else case(state)
		s_idle:			begin if(start_i) state <= s_process;
							  else state <= s_idle; end							//detect flag start
		s_process:		begin state <= s_delay; end								//data process
		s_delay:		begin state <= s_data;  end
		s_data:			begin if(count >= 4'b0011 - number_i) state <= s_idle;	//send data 
							  else state <= s_process; end
		default: begin state <= s_idle; end
	endcase
end
//-----------data process control---------
always@(posedge clk_i or negedge rst_n_i) begin
	if(~rst_n_i) shift <= 32'h0;
	else case(state)
		s_idle:begin shift <= code_i; end
		s_process: begin if(number_i == 2'b00) shift <= {shift[23:0],shift[31:24]};
						 else if(number_i == 2'b01) shift <= {shift[31:24],shift[15:0],shift[23:16]};
						 else if(number_i == 2'b10) shift <= {shift[31:16],shift[7:0],shift[15:8]};
						 else shift <= shift; end
		default: begin shift <= shift; end
	endcase
end
//----------------data send---------------
always@(posedge clk_i or negedge rst_n_i) begin
	if(~rst_n_i) wr_data_o <= 8'hff;
	else case(state)
		s_idle : begin wr_data_o <= 8'hff; end
		s_data : begin wr_data_o <= shift[7:0]; end
		default: begin wr_data_o <= wr_data_o; end
	endcase
end
//----------data write signal send--------
always@(posedge clk_i or negedge rst_n_i) begin
	if(~rst_n_i) wr_req_o <= 1'b0;
	else case(state)
		s_data : begin wr_req_o <= 1'b1; end
		default: begin wr_req_o <= 1'b0; end
	endcase
end
//------------write signal count----------
always@(posedge clk_i or negedge rst_n_i) begin
	if(~rst_n_i) count <= 4'b0000;
	else case(state)
		s_idle : begin count <= 4'b0000; end
		default: begin if(wr_req_o) count <= count + 1'b1;
					   else count <= count; end
	endcase
end
//----------write frame head flag---------
always@(posedge clk_i or negedge rst_n_i) begin
	if(~rst_n_i) flag_o <= 1'b0;
	else case(state)
		s_idle : begin flag_o <= 1'b0; end
		default: begin flag_o <= 1'b1; end
	endcase
end
endmodule 