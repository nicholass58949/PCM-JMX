/********************************************************************
* File: detect_edge.v												*
* Author: Chencen													*
* History:															*
*	2018.10.23 setup												*
*	2023.07.27 add comments and change the interface name			*
* Description:														*
*   detect the rising edge of the signal logic.						*
*********************************************************************/
module detect_edge(
	input clk_i,			//main clock(consistent with the signal clock that needs to be output) 
	input rst_n_i,			//main reset
	input signal_i,			//input signal
	output reg signal_o		//the detected rising edge signal
);
//------------------ reg control -------------------//
reg [1:0]signal_reg;  //sync signal
//---------- detected rising edge signal -----------//
always @(posedge clk_i or negedge rst_n_i) begin 
	if(!rst_n_i) signal_reg <= 2'b00;
	else signal_reg <= {signal_reg[0],signal_i};
end 
always @(posedge clk_i or negedge rst_n_i) begin 
	if(!rst_n_i) signal_o <= 1'b0;
	else if(signal_reg[0] && (!signal_reg[1])) signal_o <= 1'b1; //detect rising edge
	else signal_o <= 1'b0;
end 
endmodule 