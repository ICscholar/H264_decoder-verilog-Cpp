//--------------------------------------------------------------------------------------------------
// Copyright (C) 2013-2017 qiu bin 
// All rights reserved   
// Design    : bitstream_p
// Author(s) : qiu bin
// Email     : chat1@126.com
// Phone 15957074161
// QQ:1517642772             
//-------------------------------------------------------------------------------------------------


`include "defines.v"

module inter_pred_fsm
(
	input  clk,
	input  rst_n,
	input  ena,

	input start,
	input start_of_MB,
	input col_sel,
	output reg out_ram_wr_0,
	output reg out_ram_wr_1,
	output reg out_ram_wr_2,
	output reg out_ram_wr_3,
	output reg out_ram_wr_4,
	output reg out_ram_wr_5,
	output reg out_ram_wr_6,
	output reg out_ram_wr_7,
	output reg out_ram_wr_8,
	output reg out_ram_wr_9,
	output reg out_ram_wr_10,
	output reg out_ram_wr_11,
	output reg out_ram_wr_12,
	output reg out_ram_wr_13,
	output reg out_ram_wr_14,
	output reg out_ram_wr_15,
	(* KEEP = "TRUE" *)(*mark_debug = "true"*)output reg [4:0] out_ram_wr_addr,
	(* KEEP = "TRUE" *)(*mark_debug = "true"*)output reg [4:0] out_ram_wr_addr_reg,
	(* KEEP = "TRUE" *)(*mark_debug = "true"*)output reg [4:0] out_ram_rd_addr,
	(* KEEP = "TRUE" *)(*mark_debug = "true"*)input out_ram_rd,

	(* KEEP = "TRUE" *)(*mark_debug = "true"*)input ref_p_fifo_empty,
	(* KEEP = "TRUE" *)(*mark_debug = "true"*)output reg ref_p_fifo_rd,
	
	input [255:0] mvx_l0_curr_mb,
	input [255:0] mvy_l0_curr_mb,  
	
	output reg [2:0] counter_ppl0,
	output reg [2:0] counter_ppl1,
	output reg [2:0] counter_ppl2,
	output reg [2:0] counter_ppl3,
	output reg [2:0] counter_ppl4,
	output reg [2:0] ref_x_ppl0,
	output reg [2:0] ref_x_ppl1,
	output reg [2:0] ref_x_ppl2,
	output reg [2:0] ref_x_ppl3,
	output reg [2:0] ref_x_ppl4,
	output reg [2:0] ref_y_ppl0,
	output reg [2:0] ref_y_ppl1,
	output reg [2:0] ref_y_ppl2,
	output reg [2:0] ref_y_ppl3,
	output reg [2:0] ref_y_ppl4,
	output reg chroma_cb_sel_ppl0,
	output reg chroma_cr_sel_ppl0,
	output reg chroma_cb_sel_ppl1,
	output reg chroma_cr_sel_ppl1,
	output reg chroma_cb_sel_ppl2,
	output reg chroma_cr_sel_ppl2,
	output reg chroma_cb_sel_ppl3,
	output reg chroma_cr_sel_ppl3,
	output reg chroma_cb_sel_ppl4,
	output reg chroma_cr_sel_ppl4
);

//FF
(* KEEP = "TRUE" *)(*mark_debug = "true"*)reg [2:0] state;
(* KEEP = "TRUE" *)(*mark_debug = "true"*)reg [4:0] blk4x4_counter_module;


reg [2:0] next_state;


always @(*)begin
	out_ram_wr_0 <= 1'b0;
	out_ram_wr_1 <= 1'b0;
	out_ram_wr_2 <= 1'b0;
	out_ram_wr_3 <= 1'b0;
	out_ram_wr_4 <= 1'b0;
	out_ram_wr_5 <= 1'b0;
	out_ram_wr_6 <= 1'b0;
	out_ram_wr_7 <= 1'b0;
	out_ram_wr_8 <= 1'b0;
	out_ram_wr_9 <= 1'b0;
	out_ram_wr_10 <= 1'b0;
	out_ram_wr_11 <= 1'b0;
	out_ram_wr_12 <= 1'b0;
	out_ram_wr_13 <= 1'b0;
	out_ram_wr_14 <= 1'b0;
	out_ram_wr_15 <= 1'b0;
	if (col_sel) begin
		if (counter_ppl4 == 1 ) begin
			out_ram_wr_0 <= 1'b1;
			out_ram_wr_4 <= 1'b1;
			out_ram_wr_8 <= 1'b1;
			out_ram_wr_12<= 1'b1;
		end
		if (counter_ppl4 == 2 ) begin
			out_ram_wr_1 <= 1'b1;
			out_ram_wr_5 <= 1'b1;
			out_ram_wr_9 <= 1'b1;
			out_ram_wr_13<= 1'b1;
		end
		if (counter_ppl4 == 3 ) begin
			out_ram_wr_2 <= 1'b1;
			out_ram_wr_6 <= 1'b1;
			out_ram_wr_10<= 1'b1;
			out_ram_wr_14<= 1'b1;
		end
		if (counter_ppl4 == 4 ) begin
			out_ram_wr_3 <= 1'b1;
			out_ram_wr_7 <= 1'b1;
			out_ram_wr_11<= 1'b1;
			out_ram_wr_15<= 1'b1;
		end
	end
	else begin
		if (counter_ppl4 == 1 ) begin
			out_ram_wr_0 <= 1'b1;
			out_ram_wr_1 <= 1'b1;
			out_ram_wr_2 <= 1'b1;
			out_ram_wr_3 <= 1'b1;
		end
		if (counter_ppl4 == 2 ) begin
			out_ram_wr_4 <= 1'b1;
			out_ram_wr_5 <= 1'b1;
			out_ram_wr_6 <= 1'b1;
			out_ram_wr_7 <= 1'b1;
		end
		if (counter_ppl4 == 3 ) begin
			out_ram_wr_8 <= 1'b1;
			out_ram_wr_9 <= 1'b1;
			out_ram_wr_10<= 1'b1;
			out_ram_wr_11<= 1'b1;
		end
		if (counter_ppl4 == 4 ) begin
			out_ram_wr_12<= 1'b1;
			out_ram_wr_13<= 1'b1;
			out_ram_wr_14<= 1'b1;
			out_ram_wr_15<= 1'b1;
		end
	end
end

always @(posedge clk or negedge rst_n)
if (~rst_n)
	out_ram_rd_addr <= 0;
else if (out_ram_rd)
	out_ram_rd_addr <= out_ram_rd_addr + 1'b1;
else if (start_of_MB)
	out_ram_rd_addr <= 0;

//0  1  4  5
//2  3  6  7
//8  9  12 13
//10 11 14 15
reg [4:0] next_out_ram_wr_addr;
always @(*) begin
	case(out_ram_wr_addr)
	1:next_out_ram_wr_addr <= 4;
	5:next_out_ram_wr_addr <= 2;
	3:next_out_ram_wr_addr <= 6;
	9:next_out_ram_wr_addr <= 12;
	13:next_out_ram_wr_addr <= 10;
	11:next_out_ram_wr_addr <= 14;
	default:next_out_ram_wr_addr <= out_ram_wr_addr + 1'b1;
	endcase
end

always @(posedge clk or negedge rst_n)
if (~rst_n)
	out_ram_wr_addr <= 0;
else if (out_ram_wr_15)
	out_ram_wr_addr <= next_out_ram_wr_addr;
else if (start_of_MB)
	out_ram_wr_addr <= 0;

always @(posedge clk or negedge rst_n)
if (~rst_n)
	out_ram_wr_addr_reg <= 0;
else if (start_of_MB)
	out_ram_wr_addr_reg <= 0;
else begin 
	case(out_ram_wr_addr)
	4:out_ram_wr_addr_reg <= 2;
	8:out_ram_wr_addr_reg <= 8;
	12:out_ram_wr_addr_reg <= 10;
	16,17,18,19,
	20,21,22,23,24:out_ram_wr_addr_reg <= out_ram_wr_addr;
	endcase
end

parameter
InterPredIdle = 0,
InterPredWaitFirstRefP = 1,
InterPredCalc = 2,
InterPredWaitRefP = 3;
//
//0  1  2  3
//4  5  6  7
//8  9 10 11
//12 13 14 15
//16 17
//18 19
always @(posedge clk or negedge rst_n)
if (~rst_n) begin
	blk4x4_counter_module <= 0;
	chroma_cb_sel_ppl0 <= 1'b0;
	chroma_cr_sel_ppl0 <= 1'b0;
	ref_x_ppl0 <= 0;
	ref_y_ppl0 <= 0;
end
else if (ena && start )begin
	blk4x4_counter_module <= 0;
	chroma_cb_sel_ppl0 <= 1'b0;
	chroma_cr_sel_ppl0 <= 1'b0;
	ref_x_ppl0 <= mvx_l0_curr_mb[2:0];
	ref_y_ppl0 <= mvy_l0_curr_mb[2:0];
end
else if(ena) begin
	if (blk4x4_counter_module < 23 &&  counter_ppl0 == 4) begin
		blk4x4_counter_module <= blk4x4_counter_module + 1'b1;
	end
	else if (counter_ppl0 == 4) begin
		blk4x4_counter_module <= 0;
	end
	if (counter_ppl0 == 4)begin
		if (blk4x4_counter_module == 15)
			chroma_cb_sel_ppl0 <= 1'b1;
		else if (blk4x4_counter_module == 19)begin
			chroma_cb_sel_ppl0 <= 1'b0;
			chroma_cr_sel_ppl0 <= 1'b1;
		end
		case(blk4x4_counter_module)
		3,15,19:begin
			ref_x_ppl0 <= mvx_l0_curr_mb[2:0];
			ref_y_ppl0 <= mvy_l0_curr_mb[2:0];
		end
		1,5,16,20:begin
			ref_x_ppl0 <= mvx_l0_curr_mb[66:64];
			ref_y_ppl0 <= mvy_l0_curr_mb[66:64];
		end
		7,11,17,21:begin
			ref_x_ppl0 <= mvx_l0_curr_mb[130:128];
			ref_y_ppl0 <= mvy_l0_curr_mb[130:128];
		end
		9,13,18,22:begin
			ref_x_ppl0 <= mvx_l0_curr_mb[194:192];
			ref_y_ppl0 <= mvy_l0_curr_mb[194:192];
		end
		endcase
	end
end

always @(*) begin
	ref_p_fifo_rd <= 0;
	next_state <= state;
	case (state)
	InterPredIdle: begin
		if (start)
			next_state <= InterPredWaitFirstRefP;
	end
	InterPredWaitFirstRefP:begin
		if (~ref_p_fifo_empty) begin
			next_state <= InterPredCalc;
			ref_p_fifo_rd <= 1;
		end
	end
	InterPredCalc: begin
		if (counter_ppl0 == 3 && blk4x4_counter_module < 23)
			next_state <= InterPredWaitRefP;
		else if (counter_ppl0 == 4)
			next_state <= InterPredIdle;
	end
	InterPredWaitRefP:begin
		if (~ref_p_fifo_empty) begin
			next_state <= InterPredCalc;
			ref_p_fifo_rd <= 1;
		end
	end
	default: next_state <= InterPredIdle;
	endcase
end

always @(posedge clk or negedge rst_n)
if (!rst_n) begin
	state <= InterPredIdle;
end
else if (ena) begin
	state <= next_state;
end


parameter
FifoIdle = 0,
FifoWait = 1,
FifoRd = 2;

always @(posedge clk or negedge rst_n)
if (~rst_n) begin
	counter_ppl0 <= 0;
end
else if (ena) begin
	if (next_state == InterPredIdle) begin
		counter_ppl0 <= 0;
	end
	else if (state == InterPredWaitFirstRefP && next_state == InterPredCalc) begin
		counter_ppl0 <= 3'd1;
	end
	else if (state == InterPredCalc) begin
		counter_ppl0 <= counter_ppl0 + 1'b1;
	end
	else if (state == InterPredWaitRefP && next_state == InterPredWaitRefP) begin
		counter_ppl0 <= 3'd0;
	end
	else if (state == InterPredWaitRefP && next_state == InterPredCalc) begin
		counter_ppl0 <= 3'd1;
	end
end

always @(posedge clk or negedge rst_n)
if (~rst_n) begin
	counter_ppl1 <= 0;
	counter_ppl2 <= 0;
	counter_ppl3 <= 0;
	counter_ppl4 <= 0;
	ref_x_ppl1 <= 0;
	ref_x_ppl2 <= 0;
	ref_x_ppl3 <= 0;
	ref_x_ppl4 <= 0;
	ref_y_ppl1 <= 0;
	ref_y_ppl2 <= 0;
	ref_y_ppl3 <= 0;
	ref_y_ppl4 <= 0;
	chroma_cb_sel_ppl1 <= 0;
	chroma_cr_sel_ppl1 <= 0;
	chroma_cb_sel_ppl2 <= 0;
	chroma_cr_sel_ppl2 <= 0;
	chroma_cb_sel_ppl3 <= 0;
	chroma_cr_sel_ppl3 <= 0;
	chroma_cb_sel_ppl4 <= 0;
	chroma_cr_sel_ppl4 <= 0;
end
else if (ena) begin 
	counter_ppl1 <= counter_ppl0;
	counter_ppl2 <= counter_ppl1;
	counter_ppl3 <= counter_ppl2;
	counter_ppl4 <= counter_ppl3;
	if (counter_ppl0 != 0)begin
		ref_x_ppl1 <= ref_x_ppl0;
		ref_x_ppl2 <= ref_x_ppl1;
		ref_x_ppl3 <= ref_x_ppl2;
		ref_x_ppl4 <= ref_x_ppl3;
		ref_y_ppl1 <= ref_y_ppl0;
		ref_y_ppl2 <= ref_y_ppl1;
		ref_y_ppl3 <= ref_y_ppl2;
		ref_y_ppl4 <= ref_y_ppl3;
		chroma_cb_sel_ppl1 <= chroma_cb_sel_ppl0;
		chroma_cb_sel_ppl2 <= chroma_cb_sel_ppl1;
		chroma_cb_sel_ppl3 <= chroma_cb_sel_ppl2;
		chroma_cb_sel_ppl4 <= chroma_cb_sel_ppl3;
		chroma_cr_sel_ppl1 <= chroma_cr_sel_ppl0;
		chroma_cr_sel_ppl2 <= chroma_cr_sel_ppl1;
		chroma_cr_sel_ppl3 <= chroma_cr_sel_ppl2;
		chroma_cr_sel_ppl4 <= chroma_cr_sel_ppl3;
	end
end

endmodule
