/************************************************************************
* File: timer_insert.v													*
* Author: Chen Cen														*
* History:																*
*   2017.9.14 setup														*
*   2020.7.27 add comments and change the interface name				*
*   2021.12.10 change counting mode										*
* Description:															*
*   timer insert logic,decimalism.										*
*************************************************************************/
module timer_insert (
	input clk_i,					//main clock
	input rst_n_i,					//main reset
	input start_i,					//detect synchronous code flag
	input [15:0]divisor_i,			//calculate the time according to the master clock,make sure the frequency is 10khz
	output reg[7:0]wr_data_o,		//output frame head data
	output reg wr_req_o,			//output frame head wirte signal
	output reg flag_o				//output frame head wirte signal flag
);
//---------------reg control--------------
reg[3:0]state;			//state run
reg[3:0]count;			//byte count
reg[15:0]timer_count;	//time count
reg[63:0]timer_d;
reg[3:0]timer_d7l;
reg[3:0]timer_d7h;
reg[3:0]timer_d6l;
reg[3:0]timer_d6h;
reg[3:0]timer_d5l;
reg[3:0]timer_d5h;
reg[3:0]timer_d4l;
reg[3:0]timer_d4h;
reg[3:0]timer_d3l;
reg[3:0]timer_d3h;
//------insert timer state machine--------
localparam s_idle		= 2'b01;
localparam s_data		= 2'b10;
//--------main state machine run----------
always@(posedge clk_i or negedge rst_n_i) begin
	if(~rst_n_i) state <= s_idle;
	else case(state)
		s_idle		: begin if(start_i) state <= s_data; 
							else state <= s_idle; end	//detect flag start
		s_data		: begin if(count >= 4'b0111) state <= s_idle;	//send data
							else state <= s_data; end
		default		: begin state <= s_idle; end
	endcase
end
//-----------data process control---------
always@(posedge clk_i or negedge rst_n_i) begin
	if(~rst_n_i) timer_d <= 64'hffff_ffff_ffff_ffff;
	else case(state)
		s_idle : begin if(start_i) timer_d <= {24'h0,timer_d3h,timer_d3l,timer_d4h,timer_d4l,timer_d5h,timer_d5l,timer_d6h,timer_d6l,timer_d7h,timer_d7l};
					   else timer_d <= 64'hffff_ffff_ffff_ffff; end
		s_data : timer_d <= {timer_d[7:0],timer_d[63:8]};
		default: begin timer_d <= timer_d; end
	endcase
end
//----------------data send---------------
always@(posedge clk_i or negedge rst_n_i) begin
	if(~rst_n_i) wr_data_o <=  8'hff;
	else case(state)
		s_idle : begin wr_data_o <= 8'hff; end
		s_data : begin wr_data_o <= timer_d[7:0]; end
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
		s_data : begin count <= count + 1'b1; end
		default: begin count <= count; end
	endcase
end
//------------write timer flag------------
always@(posedge clk_i or negedge rst_n_i) begin
	if(~rst_n_i) flag_o <= 1'b0;
	else case(state)
		s_idle : begin flag_o <= 1'b0; end
		default: begin flag_o <= 1'b1; end
	endcase
end
//--------main clock to 10khz count-------
always@(posedge clk_i or negedge rst_n_i) begin
	if(~rst_n_i)  timer_count <= 16'h1;
	else begin if(timer_count >= divisor_i) timer_count <= 16'h1;
			   else timer_count <= timer_count+1'b1; end
end
//---------------100us count--------------
always@(posedge clk_i or negedge rst_n_i) begin
	if(~rst_n_i) timer_d7l <= 4'b0000;
	else begin  if((timer_d7l >= 4'b1001) && (timer_count >= divisor_i)) timer_d7l <= 4'b0000;
				else if(timer_count >= divisor_i) timer_d7l <= timer_d7l + 1'b1;
				else timer_d7l <= timer_d7l; end
end
always@(posedge clk_i or negedge rst_n_i) begin
	if(~rst_n_i) timer_d7h <= 4'b0000;
	else begin if((timer_d7h >= 4'b1001) && (timer_d7l >= 4'b1001) && (timer_count >= divisor_i)) timer_d7h <= 4'b0000;
			   else if((timer_d7l >= 4'b1001) && (timer_count >= divisor_i)) timer_d7h <= timer_d7h + 1'b1;
			   else timer_d7h <= timer_d7h; end
end
//----------------10ms count--------------
always@(posedge clk_i or negedge rst_n_i) begin
	if(~rst_n_i) timer_d6l <= 4'b0000;
	else begin if((timer_d6l >= 4'b1001) && (timer_d7h >= 4'b1001) && (timer_d7l >= 4'b1001) && (timer_count >= divisor_i)) timer_d6l <= 4'b0000;
			   else if((timer_d7h >= 4'b1001) && (timer_d7l >= 4'b1001) && (timer_count >= divisor_i)) timer_d6l <= timer_d6l + 1'b1;
			   else timer_d6l <= timer_d6l; end
end
always@(posedge clk_i or negedge rst_n_i) begin
	if(~rst_n_i) timer_d6h <= 4'b0000;
	else begin if((timer_d6h >= 4'b1001) && (timer_d6l >= 4'b1001) && (timer_d7h >= 4'b1001) && (timer_d7l >= 4'b1001) && (timer_count >= divisor_i)) timer_d6h <= 4'b0000;
			   else if((timer_d6l >= 4'b1001) && (timer_d7h >= 4'b1001) && (timer_d7l >= 4'b1001) && (timer_count >= divisor_i)) timer_d6h <= timer_d6h + 1'b1;
			   else timer_d6h <= timer_d6h; end
end
//-----------------1s count---------------
always@(posedge clk_i or negedge rst_n_i) begin
	if(~rst_n_i) timer_d5l <= 4'b0000;
	else begin if((timer_d5l >= 4'b1001) && (timer_d6h >= 4'b1001) && (timer_d6l >= 4'b1001) && (timer_d7h >= 4'b1001) && (timer_d7l >= 4'b1001) && (timer_count >= divisor_i)) timer_d5l <= 4'b0000;
			   else if((timer_d6h >= 4'b1001) && (timer_d6l >= 4'b1001) && (timer_d7h >= 4'b1001) && (timer_d7l >= 4'b1001) && (timer_count >= divisor_i)) timer_d5l <= timer_d5l + 1'b1;
			   else timer_d5l <= timer_d5l; end
end
always@(posedge clk_i or negedge rst_n_i) begin
	if(~rst_n_i) timer_d5h <= 4'b0000;
	else begin if((timer_d5h >= 4'b0101) && (timer_d5l >= 4'b1001) && (timer_d6h >= 4'b1001) && (timer_d6l >= 4'b1001) && (timer_d7h >= 4'b1001) && (timer_d7l >= 4'b1001) && (timer_count >= divisor_i)) timer_d5h <= 4'b0000;
			   else if((timer_d5l >= 4'b1001) && (timer_d6h >= 4'b1001) && (timer_d6l >= 4'b1001) && (timer_d7h >= 4'b1001) && (timer_d7l >= 4'b1001) && (timer_count >= divisor_i)) timer_d5h <= timer_d5h + 1'b1;
			   else timer_d5h <= timer_d5h;end
end
//--------------1miniute count------------
always@(posedge clk_i or negedge rst_n_i) begin
	if(~rst_n_i) timer_d4l <= 4'b0000;
	else begin if((timer_d4l >= 4'b1001) && (timer_d5h >= 4'b0101) && (timer_d5l >= 4'b1001) && (timer_d6h >= 4'b1001) && (timer_d6l >= 4'b1001) && (timer_d7h >= 4'b1001) && (timer_d7l >= 4'b1001) && (timer_count >= divisor_i)) timer_d4l <= 4'b0000;
			   else if((timer_d5h >= 4'b0101) && (timer_d5l >= 4'b1001) && (timer_d6h >= 4'b1001) && (timer_d6l >= 4'b1001) && (timer_d7h >= 4'b1001) && (timer_d7l >= 4'b1001) && (timer_count >= divisor_i)) timer_d4l <= timer_d4l + 1'b1;
			   else timer_d4l <= timer_d4l; end
end
always@(posedge clk_i or negedge rst_n_i) begin
	if(~rst_n_i) timer_d4h <= 4'b0000;
	else begin if((timer_d4h >= 4'b0101) && (timer_d4l >= 4'b1001) && (timer_d5h >= 4'b0101) && (timer_d5l >= 4'b1001) && (timer_d6h >= 4'b1001) && (timer_d6l >= 4'b1001) && (timer_d7h >= 4'b1001) && (timer_d7l >= 4'b1001) && (timer_count >= divisor_i)) timer_d4h <= 4'b0000;
			   else if((timer_d4l >= 4'b1001) && (timer_d5h >= 4'b0101) && (timer_d5l >= 4'b1001) && (timer_d6h >= 4'b1001) && (timer_d6l >= 4'b1001) && (timer_d7h >= 4'b1001) && (timer_d7l >= 4'b1001) && (timer_count >= divisor_i)) timer_d4h <= timer_d4h + 1'b1;
			   else timer_d4h <= timer_d4h; end
end
//----------------1hour count-------------
always@(posedge clk_i or negedge rst_n_i) begin
	if(~rst_n_i) timer_d3l <= 4'b0000;	
	else begin if((timer_d3h >= 4'b0010) && (timer_d3l >= 4'b0011) && (timer_d4h >= 4'b0101) && (timer_d4l >= 4'b1001) && (timer_d5h >= 4'b0101) && (timer_d5l >= 4'b1001) && (timer_d6h >= 4'b1001) && (timer_d6l >= 4'b1001) && (timer_d7h >= 4'b1001) && (timer_d7l >= 4'b1001) && (timer_count >= divisor_i)) timer_d3l <= 4'b0000;
			   else if((timer_d3l >= 4'b1001) && (timer_d4h >= 4'b0101) && (timer_d4l >= 4'b1001) && (timer_d5h >= 4'b0101) && (timer_d5l >= 4'b1001) && (timer_d6h >= 4'b1001) && (timer_d6l >= 4'b1001) && (timer_d7h >= 4'b1001) && (timer_d7l >= 4'b1001) && (timer_count >= divisor_i)) timer_d3l <= 4'b0000;
			   else if((timer_d4h >= 4'b0101) && (timer_d4l >= 4'b1001) && (timer_d5h >= 4'b0101) && (timer_d5l >= 4'b1001) && (timer_d6h >= 4'b1001) && (timer_d6l >= 4'b1001) && (timer_d7h >= 4'b1001) && (timer_d7l >= 4'b1001) && (timer_count >= divisor_i)) timer_d3l <= timer_d3l + 1'b1;
			   else timer_d3l <= timer_d3l; end
end
always@(posedge clk_i or negedge rst_n_i) begin
	if(~rst_n_i) timer_d3h <= 4'b0000;	
	else begin if((timer_d3h >= 4'b0010) && (timer_d3l >= 4'b0011) && (timer_d4h >= 4'b0101) && (timer_d4l >= 4'b1001) && (timer_d5h >= 4'b0101) && (timer_d5l >= 4'b1001) && (timer_d6h >= 4'b1001) && (timer_d6l >= 4'b1001) && (timer_d7h >= 4'b1001) && (timer_d7l >= 4'b1001) && (timer_count >= divisor_i)) timer_d3h <= 4'b0000;
			   else if((timer_d3l >= 4'b1001) && (timer_d4h >= 4'b0101) && (timer_d4l >= 4'b1001) && (timer_d5h >= 4'b0101) && (timer_d5l >= 4'b1001) && (timer_d6h >= 4'b1001) && (timer_d6l >= 4'b1001) && (timer_d7h >= 4'b1001) && (timer_d7l >= 4'b1001) && (timer_count >= divisor_i)) timer_d3h <= timer_d3h + 1'b1;
			   else timer_d3h <= timer_d3h; end
end
endmodule 