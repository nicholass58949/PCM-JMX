/********************************************************************
* File: shake_filter.v												*
* Author: Chencen													*
* History:															*
*	2021.09.05 setup												*
*	2023.10.07 Add filter number 0 operation						*
* Description:														*
*	shake elimination filter.  										*
*	1.Set up a filter counter.  									*
*	2.compare each sample value with the current valid value.		*
*	3.if the sample value = current valid value,					*
*	the counter is cleared.											*
*	4.if the sample value != is currently valid,					*
*	the counter +1 and determines									*
*	if the counter >= upper limit N(overflow).						*
*	5.if the counter overflows, this value is replaced by			*
*	the current valid value and the counter is cleared.				*
*********************************************************************/
module shake_filter(
	input clk_i,		//input filter clock signal
	input rst_n_i,		//input reset signal
	input [15:0] num_i,	//filter number
	input data_i,		//input data signal
	output data_o	    //filtered data
);
//------------------ reg control -------------------//
reg [15:0]count_sig;	//count register
reg [1:0]temp_sig;		//signal cache
reg data_reg;
//----------------- signal filter ------------------//
always @(posedge clk_i or negedge rst_n_i) begin 
	if(!rst_n_i) temp_sig <= 2'b00;
	else temp_sig <= {temp_sig[0],data_i};
end
always @(posedge clk_i or negedge rst_n_i) begin
	if(!rst_n_i) count_sig <= 16'h1;
	else if((data_reg != temp_sig[1]) && (temp_sig[1] != temp_sig[0])) count_sig <= 16'h1;	//count reset
	else if((data_reg != temp_sig[1]) && (temp_sig[1] == temp_sig[0])) begin 
		if(count_sig >= num_i) count_sig <= 16'h1;	//count reset
		else count_sig <= count_sig + 1'b1; end	//count + 1
	else count_sig <= count_sig;
end
always @(posedge clk_i or negedge rst_n_i) begin
	if(!rst_n_i) data_reg <= data_i;
	else if(count_sig >= num_i) data_reg <= temp_sig[1];	//update when the threshold is reached
	else data_reg <= data_reg;
end
assign data_o = (num_i != 16'h0) ? data_reg : data_i; //if the number of filters is 0, no filtering is performed
endmodule 