/********************************************************************
* File: pcm_decrypt.v												*
* Author: Chen Cen													*
* History:															*
*	2021.09.14  setup												*
*	2023.07.24	Added NRZ-M and NRZ-S code types					*
* Description:														*
*   pcm decrypt control logic.										*
*********************************************************************/
module pcm_decrypt(
	input clk_i,			//rxd data clock
	input rst_n_i,			//main reset
	input [2:0]pattern_i,	//0:RNRZL,1:NRZ-L,2:NRZ-M(0 holds,1 jumps),3:NRZ-S(1 holds,0 jumps)
	input edge_i,			//clock direction
	input data_i,			//rxd data
	output reg data_o		//decrypted data
);
//-------------- reg control ---------------//
wire clk_temp;
(* MARK_DEBUG="true" *) wire data_temp;
(* MARK_DEBUG="true" *) reg [14:0]data_reg;
//-------- clock direction control ---------//
assign clk_temp = (edge_i == 1'b0) ? clk_i : ~clk_i;
//------------ decrypt control -------------//
assign data_temp = data_i ^ data_reg[13] ^ data_reg[14];
always @(negedge clk_temp or negedge rst_n_i) begin
	if(!rst_n_i) data_o <= 1'b0;
	else case(pattern_i)
		3'b000	: begin data_o <= data_temp; end
		3'b001	: begin data_o <= data_i; end
		3'b010	: begin data_o <= data_reg[0] ^ data_i; end
		3'b011	: begin data_o <= data_reg[0] ^~ data_i; end
		default	: begin data_o <= data_i; end
	endcase
end
always @(negedge clk_temp or negedge rst_n_i) begin
	if(!rst_n_i) data_reg <= 15'd0;
	else data_reg[14:0] <= {data_reg[13:0],data_i};
end
endmodule