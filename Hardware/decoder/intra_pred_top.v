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

module intra_pred_top(
	input clk,
	input rst_n,
	input ena,
	input start,
	input start_of_MB,
	input sum_valid,

	input [`mb_x_bits - 1:0] mb_x,
	input [4:0] blk4x4_counter,
	input [31:0] sum_right_colum,
	input [31:0] sum_bottom_row,
	input [3:0] mb_pred_mode,
	input mb_pred_inter_sel,
	input [3:0] I4_pred_mode,
	input [1:0] I16_pred_mode,
	input [1:0] intra_pred_mode_chroma,
	input [7:0] is_mb_intra,
	input constrained_intra_pred_flag,
	
	output [`mb_x_bits + 1:0] line_ram_luma_addr,
	output [`mb_x_bits :0]    line_ram_chroma_addr,
	output line_ram_luma_wr_n,
	output line_ram_cb_wr_n,
	output line_ram_cr_wr_n,
	input  [31:0] line_ram_luma_data,
	input  [31:0] line_ram_cb_data,
	input  [31:0] line_ram_cr_data,
	
	output [7:0] intra_pred_0,
	output [7:0] intra_pred_1, 
	output [7:0] intra_pred_2, 
	output [7:0] intra_pred_3, 
	output [7:0] intra_pred_4, 
	output [7:0] intra_pred_5, 
	output [7:0] intra_pred_6, 
	output [7:0] intra_pred_7, 
	output [7:0] intra_pred_8, 
	output [7:0] intra_pred_9, 
	output [7:0] intra_pred_10,
	output [7:0] intra_pred_11,
	output [7:0] intra_pred_12,
	output [7:0] intra_pred_13,
	output [7:0] intra_pred_14,
	output [7:0] intra_pred_15,
	output valid
);

//
//intra_pred_calc
//
wire [5:0] calc_ena;
wire precalc_ena;
wire [12:0] b;
wire [12:0] c;
wire [14:0] seed;

wire [7:0] up_mb_muxout_0;
wire [7:0] up_mb_muxout_1;
wire [7:0] up_mb_muxout_2;
wire [7:0] up_mb_muxout_3;

wire [7:0] left_mb_muxout_0;
wire [7:0] left_mb_muxout_1;
wire [7:0] left_mb_muxout_2;
wire [7:0] left_mb_muxout_3;

wire [7:0] up_left_muxout;

wire [7:0] up_right_muxout_0;
wire [7:0] up_right_muxout_1;
wire [7:0] up_right_muxout_2;
wire [7:0] up_right_muxout_3;

wire [11:0] DC_sum_up;
wire [11:0] DC_sum_left;
wire [4:0] DC_sum_round_value;

wire [13:0] plane_sum_0_out;
wire [13:0] plane_sum_3_out;

intra_pred_calc intra_pred_calc_inst (
	.clk(clk),
	.rst_n(rst_n),
	.start(start),
	.calc_ena(calc_ena),
	.blk4x4_counter(blk4x4_counter),
	.mb_pred_mode(mb_pred_mode),
	.I16_pred_mode(I16_pred_mode),
	.I4_pred_mode(I4_pred_mode),
	.intra_pred_mode_chroma(intra_pred_mode_chroma),


	.b(b),
	.c(c),
	.seed(seed),
	
	.up_mb_muxout_0(up_mb_muxout_0),
	.up_mb_muxout_1(up_mb_muxout_1),
	.up_mb_muxout_2(up_mb_muxout_2),
	.up_mb_muxout_3(up_mb_muxout_3),
	
	.left_mb_muxout_0(left_mb_muxout_0),
	.left_mb_muxout_1(left_mb_muxout_1),
	.left_mb_muxout_2(left_mb_muxout_2),
	.left_mb_muxout_3(left_mb_muxout_3),

	.up_left_muxout(up_left_muxout),
	
	.up_right_muxout_0(up_right_muxout_0),
	.up_right_muxout_1(up_right_muxout_1),
	.up_right_muxout_2(up_right_muxout_2),
	.up_right_muxout_3(up_right_muxout_3),              

	.DC_sum_up(DC_sum_up),
	.DC_sum_left(DC_sum_left),
	.DC_sum_round_value(DC_sum_round_value),

	.plane_sum_0_out(plane_sum_0_out),
	.plane_sum_3_out(plane_sum_3_out),

	.intra_pred_0(intra_pred_0),
	.intra_pred_1(intra_pred_1),
	.intra_pred_2(intra_pred_2),
	.intra_pred_3(intra_pred_3),
	.intra_pred_4(intra_pred_4),
	.intra_pred_5(intra_pred_5),
	.intra_pred_6(intra_pred_6),
	.intra_pred_7(intra_pred_7),
	.intra_pred_8(intra_pred_8),
	.intra_pred_9(intra_pred_9), 
	.intra_pred_10(intra_pred_10),
	.intra_pred_11(intra_pred_11),
	.intra_pred_12(intra_pred_12),
	.intra_pred_13(intra_pred_13),
	.intra_pred_14(intra_pred_14),
	.intra_pred_15(intra_pred_15)
);

//
//intra_pred_regs
//


wire [2:0] preload_counter;
wire [2:0] up_left_addr;

wire top_left_blk_avail;
wire top_blk_avail;
wire top_right_blk_avail;
wire left_blk_avail;

wire left_mb_luma_wr;
wire up_mb_luma_wr;
wire up_left_wr;
wire up_left_cb_wr;
wire up_left_cr_wr;
wire left_mb_cb_wr;
wire left_mb_cr_wr;

wire [3:0] precalc_counter;
wire abc_latch;
wire seed_latch;
wire seed_wr;

intra_pred_regs intra_pred_regs_inst(
	.clk(clk),         
	.rst_n(rst_n),       
	.ena(ena),         

	//for plane
	.precalc_ena(precalc_ena),
	.precalc_counter(precalc_counter),
	.abc_latch(abc_latch),
	.seed_latch(seed_latch),
	.seed_wr(seed_wr),

	.blk4x4_counter(blk4x4_counter),
	.mb_pred_mode(mb_pred_mode),
    .I16_pred_mode(I16_pred_mode),
    .I4_pred_mode(I4_pred_mode),
    .intra_pred_mode_chroma(intra_pred_mode_chroma),

	.line_ram_luma_data(line_ram_luma_data),
	.line_ram_cb_data(line_ram_cb_data),
	.line_ram_cr_data(line_ram_cr_data),
	.sum_right_colum(sum_right_colum),
	.sum_bottom_row(sum_bottom_row),

	.preload_counter(preload_counter),

	.up_mb_luma_wr(up_mb_luma_wr),
	.left_mb_luma_wr(left_mb_luma_wr),
	.up_left_wr(up_left_wr),
	.up_left_cb_wr(up_left_cb_wr),
	.up_left_cr_wr(up_left_cr_wr),
	.left_mb_cb_wr(left_mb_cb_wr),
	.left_mb_cr_wr(left_mb_cr_wr),
	
	.top_left_blk_avail(top_left_blk_avail),
	.top_blk_avail(top_blk_avail),
	.top_right_blk_avail(top_right_blk_avail),
	.left_blk_avail(left_blk_avail),

    .up_mb_muxout_0(up_mb_muxout_0),
    .up_mb_muxout_1(up_mb_muxout_1),
    .up_mb_muxout_2(up_mb_muxout_2),
    .up_mb_muxout_3(up_mb_muxout_3),

	.left_mb_muxout_0(left_mb_muxout_0),
	.left_mb_muxout_1(left_mb_muxout_1), 
	.left_mb_muxout_2(left_mb_muxout_2), 
	.left_mb_muxout_3(left_mb_muxout_3), 

	.up_left_muxout(up_left_muxout),
    
    .up_right_muxout_0(up_right_muxout_0),
    .up_right_muxout_1(up_right_muxout_1),
    .up_right_muxout_2(up_right_muxout_2),
    .up_right_muxout_3(up_right_muxout_3),

	.DC_sum_up(DC_sum_up),
	.DC_sum_left(DC_sum_left),
	.DC_sum_round_value(DC_sum_round_value),
	
	.sum0_reg(plane_sum_0_out),
	.sum3_reg(plane_sum_3_out),
	
	.b(b),
	.c(c),
	.seed(seed)

);

intra_pred_fsm intra_pred_fsm_inst(
	.clk(clk),
	.rst_n(rst_n),
	.ena(ena),
	.start(start),
	.start_of_MB(start_of_MB),
	.mb_x(mb_x),
	.mb_pred_mode(mb_pred_mode),
	.mb_pred_inter_sel(mb_pred_inter_sel),
	.I4_pred_mode(I4_pred_mode),
	.I16_pred_mode(I16_pred_mode),
	.intra_pred_mode_chroma(intra_pred_mode_chroma),
	.blk4x4_counter(blk4x4_counter),
	.is_mb_intra(is_mb_intra),
	.constrained_intra_pred_flag(constrained_intra_pred_flag),
	.sum_valid(sum_valid),
	
	.top_left_blk_avail(top_left_blk_avail),
	.top_blk_avail(top_blk_avail),
	.top_right_blk_avail(top_right_blk_avail),
	.left_blk_avail(left_blk_avail),

	.precalc_ena(precalc_ena),
	.preload_counter(preload_counter),
	.precalc_counter(precalc_counter),
	.up_left_addr(up_left_addr),
	.left_mb_luma_wr(left_mb_luma_wr),
	.up_mb_luma_wr(up_mb_luma_wr),
	.up_left_wr(up_left_wr),
	.up_left_cb_wr(up_left_cb_wr),
	.up_left_cr_wr(up_left_cr_wr),
	.left_mb_cb_wr(left_mb_cb_wr),
	.left_mb_cr_wr(left_mb_cr_wr),
	.calc_ena(calc_ena),
	.abc_latch(abc_latch),
	.seed_latch(seed_latch),
	.seed_wr(seed_wr),
	.line_ram_luma_wr_n(line_ram_luma_wr_n),
	.line_ram_cb_wr_n(line_ram_cb_wr_n),
	.line_ram_cr_wr_n(line_ram_cr_wr_n),
	.line_ram_luma_addr(line_ram_luma_addr),
	.line_ram_chroma_addr(line_ram_chroma_addr),
	.valid(valid)
);

  //  initial $fsdbInteractive;
/*initial 
begin 
    $fsdbDumpfile("intra_pred.fsdb"); 
    $fsdbDumpvars; 
end
*/ 
endmodule
