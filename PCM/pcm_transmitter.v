/********************************************************************
* File: pcm_transmitter.v											*
* Author: Chen Cen													*
* History:															*
*	2018.10.11 setup												*
*	020.09.04 add comments and change the interface name			*
*	2022.01.20 change interval time counter							*
* Description:														*
*	pcm transmitter logic,data 0x00~0xff.							*
*********************************************************************/
module pcm_transmitter (
	input clk_i,						//main clock
	input rst_n_i,						//main reset
	input start_i,						//start send
	input edge_i,						//send edge selection 0:rising edge rollover,1:falling edge rollover
	input[15:0]baudrate_i,				//set baudrate  = clock_frequency / baudrate
	input[15:0]length_i,				//set send frame length 
	input[31:0]code_i,					//set synchronous code
	input[1:0] number_i,				//set send synchronous code length 0:4byte ~ 3:1byte
	input [31:0] cntr_num_i,			//send frame count
	input [31:0] send_time_i,			//interval time
	output reg data_o,					//send data
	output reg clk_o					//send clock
);
//----------------- count control ------------------//
reg [5:0] state;		//state machine
reg [15:0]baud_cntr;	//baud rate count
reg [3:0] bit_counter;	//send data bit count
reg [15:0]frame_counter;//send data frame count
reg [5:0] head_counter;	//send synchronous head bit count
reg [31:0]frame_num;	//send frame count 
wire baud_tick;			//baud rate flag
reg [1:0]start_sig;		//start signal temp 1
reg start_sig_old;		//start signal temp 2
reg ris_sig;			//detected start signal rising
reg [31:0]syn_head;		//pcm synchronous head
reg [7:0]shift;			//send data shift
reg [7:0]txd_temp;		//send data temp
reg [31:0]timer_count;	//interval time count
reg clk_sig;			//send clock temp
//------------ flow control state machine ----------//
localparam s_idle		 = 6'b00_0001;
localparam s_start		 = 6'b00_0010;
localparam s_send_scode	 = 6'b00_0100;
localparam s_send_data	 = 6'b00_1000;
localparam s_wait		 = 6'b01_0000;
localparam s_stop		 = 6'b10_0000;
//----------------- buand clock -------------------//
always @(posedge clk_i or negedge rst_n_i) begin
	if(~rst_n_i) baud_cntr <= 16'h1;
	else if(baud_cntr >= baudrate_i) baud_cntr <= 16'h1;
	else baud_cntr <= baud_cntr + 1'b1;
end
assign baud_tick = (baud_cntr >= baudrate_i) ? (edge_i) ? clk_o: ~clk_o: 1'b0;	//send flag
//------------------- send clock --------------------//
always @(posedge clk_i or negedge rst_n_i) begin
	if(~rst_n_i) begin 
		if(edge_i)clk_o <= 1'b1;
		else clk_o <= 1'b0; end
	else if(baud_cntr >= baudrate_i) clk_o <= ~clk_o;	//generate clock
	else clk_o <= clk_o;
end
//-------- detect start signal rising edge----------//
always @(posedge clk_i or negedge rst_n_i) begin 
	if(!rst_n_i) start_sig <= 2'b00;
	else start_sig <= {start_sig[0],start_i};
end 
always @(posedge clk_i or negedge rst_n_i) begin
	if(~rst_n_i) ris_sig <= 1'b0;
	else if((~start_sig[1]) && start_sig[0]) ris_sig <= 1'b1; //detected start signal rising edge
	else ris_sig <= 1'b0;
end
//----------- main state machine run ---------------//
always @(posedge clk_i or negedge rst_n_i) begin
	if(~rst_n_i) state <= s_idle;
	else case(state)
		s_idle		: begin if(ris_sig) state <= s_start;
							else state <= s_idle; end
		s_start		: begin state <= s_send_scode; end
		s_send_scode: begin if(baud_tick) begin 
								if((number_i == 2'b00) && (head_counter == 6'h1f)) state <= s_send_data;
								else if((number_i == 2'b01) && (head_counter == 6'h17)) state <= s_send_data;
								else if((number_i == 2'b10) && (head_counter == 6'h0f)) state <= s_send_data;
								else if((number_i == 2'b11) && (head_counter == 6'h07)) state <= s_send_data;
								else state <= s_send_scode; end
							else state <= s_send_scode; end
		s_send_data : begin if(baud_tick) begin 
								if (bit_counter >= 4'h7) state <= s_stop;
								else state <= s_send_data; end 
							else state <= s_send_data; end
		s_stop		: begin if(frame_counter >= length_i + number_i) begin
								if(frame_num >= cntr_num_i) state <= s_idle;
								else if(timer_count >= send_time_i) state <= s_send_scode;
								else state <= s_wait; end
							else state <= s_send_data; end
		s_wait 		: begin if(timer_count >= send_time_i) state <= s_send_scode;
							else state <= s_wait; end
		default		: begin state <= s_idle; end
	endcase
end
//----------- send synchronous head code -----------//
always @(posedge clk_i or negedge rst_n_i) begin
	if(~rst_n_i) syn_head <= 32'h0;
	else case(state)
		s_send_scode: begin if(baud_tick) syn_head <= {syn_head[30:0],1'b0};
							else syn_head <= syn_head; end
		default		: begin if(number_i == 2'b00) syn_head <= code_i;
 							else if(number_i == 2'b01) syn_head <= {code_i[23:0],8'h0}; 
							else if(number_i == 2'b10) syn_head <= {code_i[15:0],16'h0}; 
							else syn_head <= {code_i[7:0],24'h0}; end 
	endcase
end
//---------- send synchronous head count -----------//
always @(posedge clk_i or negedge rst_n_i) begin
	if(~rst_n_i) head_counter <= 6'h0;
	else case(state)
		s_send_scode: begin if(baud_tick) head_counter <= head_counter + 1'b1;
							else head_counter <= head_counter; end
		default		: begin head_counter <= 6'h0; end
	endcase
end
//----------------txd edge count--------------------//
always @(posedge clk_i or negedge rst_n_i) begin
	if(~rst_n_i) shift <= 8'h0;
	else case(state)
		s_idle		: begin shift <= 8'h0; end
		s_send_data : begin if(baud_tick) begin 
								if (bit_counter >= 4'h7) shift <= shift + 1'b1;
								else shift <= shift; end
							else shift <= shift; end
		default		: begin shift <= shift; end
  endcase
end
//---------------- send test data ------------------//
always @(posedge clk_i or negedge rst_n_i) begin
	if(~rst_n_i) txd_temp <= 8'h0;
	else case(state)
		s_idle		: begin txd_temp <= 8'h0; end
		s_start		: begin txd_temp <= shift; end	
		s_send_data	: begin if(baud_tick) txd_temp <= {txd_temp[7:0],1'b0};
							else txd_temp <= txd_temp; end
		s_stop		: begin txd_temp <= shift;end
		default		: begin txd_temp <= txd_temp; end
	endcase
end
//----------------txd edge count--------------------//
always @(posedge clk_i or negedge rst_n_i) begin
	if(~rst_n_i) bit_counter <= 4'h0;
	else case(state)
		s_send_data: begin if(baud_tick) bit_counter <= bit_counter + 1'b1;
						   else bit_counter <= bit_counter; end
		default		: begin bit_counter <= 4'h0; end
	endcase
end
//--------------frame length Count------------------//
always@(posedge clk_i or negedge rst_n_i) begin
	if(~rst_n_i) frame_counter <= 16'h5;
	else case(state)
		s_send_data	: begin frame_counter <= frame_counter; end
		s_stop		: begin frame_counter <= frame_counter + 1'b1; end
		default		: begin frame_counter <= 16'h5; end
	endcase
end
//------------------frame Count---------------------//
always@(posedge clk_i or negedge rst_n_i) begin
	if(~rst_n_i) frame_num <= 32'h1;
	else case(state)
	    s_idle,s_start: begin frame_num <= 32'h1; end
		s_stop		  : begin if(frame_counter >= length_i + number_i) frame_num <= frame_num + 1'b1; 
							  else frame_num <= frame_num;  end
		default		  : begin frame_num <= frame_num; end
	endcase
end
//----------------- clock Count --------------------//
always@(posedge clk_i or negedge rst_n_i) begin
	if(~rst_n_i) timer_count <= 32'h1;
	else case(state)
		s_idle,s_start	: begin timer_count <= 32'h1; end
		default			: begin if(timer_count >= send_time_i) timer_count <= 32'h1; 
								else timer_count <= timer_count + 1'b1; end
	endcase
end
//--------------- send data 1 bit ------------------//
always @(posedge clk_i or negedge rst_n_i) begin
	if(~rst_n_i) data_o <= 1'b1;
	else case(state)
		s_send_scode: begin if(baud_tick) data_o <= syn_head[31];
							else data_o <= data_o; end
		s_send_data : begin if(baud_tick) data_o <= txd_temp[7];
							else data_o <= data_o; end
		s_stop		: begin data_o <= data_o; end
		default		: begin data_o <= 1'b1; end
	endcase  
end
endmodule