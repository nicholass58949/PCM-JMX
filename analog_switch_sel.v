`timescale 1ns / 1ns
module analog_switch_sel(
	//pci control
	input [3:0]pud_sel_i,			//set the pull-down/up resistance of an interface
	input [2:0]tr_sel_i,			//set the terminal resistance of the interface(lvds port, terminal match always have)
	input [3:0]lp_sel_i,			//set send and receive loops
	//analog switch interface
	output [4:0]pud_ctr_o,			//pull-up/down(the third and fourth bits are lvds)
	output [2:0]tr_ctr_o,			//terminal resistance(lvds port, terminal match always have)
	output [3:0]lph_ctr_o,			//loop P
	output [3:0]lpl_ctr_o			//loop N
    );

//channel 0,1:485
//channel 2:422
//channel 3:lvds

//pull-up/down control
assign pud_ctr_o = {pud_sel_i[3],pud_sel_i}; //one bit,one channel(0:close 1:open)
//terminal resistance control
assign tr_ctr_o = tr_sel_i; //one bit,one channel(0:close 1:open)
//loop control
assign lpl_ctr_o = ~lp_sel_i; //one bit,one channel(0:close 1:open)
assign lph_ctr_o = lp_sel_i; //one bit,one channel(0:open 1:close)
endmodule
