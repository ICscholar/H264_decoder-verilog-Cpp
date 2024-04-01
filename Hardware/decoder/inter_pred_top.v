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

module inter_pred_top
(
	input  clk,
	input  rst_n,
	input  ena,
		
	input mv_l0_calc_done,
	input start_of_MB,
	input [4:0] blk4x4_counter,
	
	input  [2:0]    pic_num_2to0,
	input  [`mb_x_bits + `mb_y_bits:0] total_mbs_one_frame,
	input  [`mb_x_bits :0] pic_width_in_mbs, 
	input  [`mb_y_bits :0] pic_height_in_map_units,
		
	input [`mb_x_bits - 1:0] mb_x,
	input [`mb_y_bits - 1:0] mb_y,
	input is_mv_all_same,
	input [11:0]  ref_idx_l0_curr_mb,
	input [255:0] mvx_l0_curr_mb,
	input [255:0] mvy_l0_curr_mb,    
	
	input 									ext_mem_reader_clk,
	input 									ext_mem_reader_rst_n,
	input                                   ext_mem_reader_burst_ready,
	output									ext_mem_reader_burst, 
	output[4:0]								ext_mem_reader_burst_len_minus1,
	output[`ext_buf_mem_addr_width-1:0]		ext_mem_reader_burst_addr,
	output									ext_mem_reader_ready,
	input[`ext_buf_mem_rd_data_width-1:0]	ext_mem_reader_data,
	input									ext_mem_reader_valid,

	
	output [7:0] inter_pred_0,
	output [7:0] inter_pred_1,
	output [7:0] inter_pred_2,
	output [7:0] inter_pred_3,
	output [7:0] inter_pred_4,
	output [7:0] inter_pred_5,
	output [7:0] inter_pred_6,
	output [7:0] inter_pred_7,
	output [7:0] inter_pred_8,
	output [7:0] inter_pred_9,
	output [7:0] inter_pred_10,
	output [7:0] inter_pred_11,
	output [7:0] inter_pred_12,
	output [7:0] inter_pred_13,
	output [7:0] inter_pred_14,
	output [7:0] inter_pred_15,
	output [4:0] out_ram_wr_addr_reg,
	input out_ram_rd,
	
	output desc_fifo_wr,
	output desc_fifo_rd_empty,
	output [5:0] desc_fifo_rd_words_avail,
		output  [2:0] desc_fifo_state,
	output desc_fifo_rd,
	output ref_p_mem_avail
);
wire [7:0] ref_00;
wire [7:0] ref_01;
wire [7:0] ref_02;
wire [7:0] ref_03;
wire [7:0] ref_04;
wire [7:0] ref_05;
wire [7:0] ref_06;
wire [7:0] ref_07;
wire [7:0] ref_08;
wire [7:0] ref_10;
wire [7:0] ref_11;
wire [7:0] ref_12;
wire [7:0] ref_13;
wire [7:0] ref_14;
wire [7:0] ref_15;
wire [7:0] ref_16;
wire [7:0] ref_17;
wire [7:0] ref_18;
wire [7:0] ref_20;
wire [7:0] ref_21;
wire [7:0] ref_22;
wire [7:0] ref_23;
wire [7:0] ref_24;
wire [7:0] ref_25;
wire [7:0] ref_26;
wire [7:0] ref_27;
wire [7:0] ref_28;
wire [7:0] ref_30;
wire [7:0] ref_31;
wire [7:0] ref_32;
wire [7:0] ref_33;
wire [7:0] ref_34;
wire [7:0] ref_35;
wire [7:0] ref_36;
wire [7:0] ref_37;
wire [7:0] ref_38;
wire [7:0] ref_40;
wire [7:0] ref_41;
wire [7:0] ref_42;
wire [7:0] ref_43;
wire [7:0] ref_44;
wire [7:0] ref_45;
wire [7:0] ref_46;
wire [7:0] ref_47;
wire [7:0] ref_48;
wire [7:0] ref_50;
wire [7:0] ref_51;
wire [7:0] ref_52;
wire [7:0] ref_53;
wire [7:0] ref_54;
wire [7:0] ref_55;
wire [7:0] ref_56;
wire [7:0] ref_57;
wire [7:0] ref_58;
wire [7:0] ref_60;
wire [7:0] ref_61;
wire [7:0] ref_62;
wire [7:0] ref_63;
wire [7:0] ref_64;
wire [7:0] ref_65;
wire [7:0] ref_66;
wire [7:0] ref_67;
wire [7:0] ref_68;
wire [7:0] ref_70;
wire [7:0] ref_71;
wire [7:0] ref_72;
wire [7:0] ref_73;
wire [7:0] ref_74;
wire [7:0] ref_75;
wire [7:0] ref_76;
wire [7:0] ref_77;
wire [7:0] ref_78;
wire [7:0] ref_80;
wire [7:0] ref_81;
wire [7:0] ref_82;
wire [7:0] ref_83;
wire [7:0] ref_84;
wire [7:0] ref_85;
wire [7:0] ref_86;
wire [7:0] ref_87;
wire [7:0] ref_88;
wire [71:0] ref_p_mem_data_0;
wire [71:0] ref_p_mem_data_1;
wire [71:0] ref_p_mem_data_2;
wire [71:0] ref_p_mem_data_3;
wire [71:0] ref_p_mem_data_4;
wire [71:0] ref_p_mem_data_5;
wire [71:0] ref_p_mem_data_6;
wire [71:0] ref_p_mem_data_7;
wire [71:0] ref_p_mem_data_8;

wire ref_p_mem_rd;
wire [2:0] counter_ppl0;
wire [2:0] counter_ppl1;
wire [2:0] counter_ppl2;
wire [2:0] counter_ppl3;
wire [2:0] counter_ppl4;
wire [2:0] ref_x_ppl0;
wire [2:0] ref_x_ppl1;
wire [2:0] ref_x_ppl2;
wire [2:0] ref_x_ppl3;
wire [2:0] ref_x_ppl4;
wire [2:0] ref_y_ppl0;
wire [2:0] ref_y_ppl1;
wire [2:0] ref_y_ppl2;
wire [2:0] ref_y_ppl3;
wire [2:0] ref_y_ppl4;
wire chroma_cb_sel_ppl0;
wire chroma_cr_sel_ppl0;
wire chroma_cb_sel_ppl1;
wire chroma_cr_sel_ppl1;
wire chroma_cb_sel_ppl2;
wire chroma_cr_sel_ppl2;
wire chroma_cb_sel_ppl3;
wire chroma_cr_sel_ppl3;
wire chroma_cb_sel_ppl4;
wire chroma_cr_sel_ppl4;


wire mv_l0_calc_done_s;
wire [4:0] blk4x4_counter_s;

wire [2:0]    pic_num_2to0_s;
wire [`mb_x_bits + `mb_y_bits:0] total_mbs_one_frame_s;
wire [`mb_x_bits :0] pic_width_in_mbs_s;
wire [`mb_y_bits :0] pic_height_in_map_units_s;

wire [`mb_x_bits - 1:0] mb_x_s;
wire [`mb_y_bits - 1:0] mb_y_s;
wire is_mv_all_same_s;
wire [11:0]  ref_idx_l0_curr_mb_s;
wire start_of_MB_s;
wire [255:0] mvx_l0_curr_mb_s;
wire [255:0] mvy_l0_curr_mb_s;
reg mv_l0_calc_done_d;

always @(posedge clk)
	mv_l0_calc_done_d <= mv_l0_calc_done;
wire sync_fifo_rd_empty;

assign {ref_80, ref_70, ref_60, ref_50, ref_40, ref_30, ref_20, ref_10, ref_00} = ref_p_mem_data_0;
assign {ref_81, ref_71, ref_61, ref_51, ref_41, ref_31, ref_21, ref_11, ref_01} = ref_p_mem_data_1;
assign {ref_82, ref_72, ref_62, ref_52, ref_42, ref_32, ref_22, ref_12, ref_02} = ref_p_mem_data_2;
assign {ref_83, ref_73, ref_63, ref_53, ref_43, ref_33, ref_23, ref_13, ref_03} = ref_p_mem_data_3;
assign {ref_84, ref_74, ref_64, ref_54, ref_44, ref_34, ref_24, ref_14, ref_04} = ref_p_mem_data_4;
assign {ref_85, ref_75, ref_65, ref_55, ref_45, ref_35, ref_25, ref_15, ref_05} = ref_p_mem_data_5;
assign {ref_86, ref_76, ref_66, ref_56, ref_46, ref_36, ref_26, ref_16, ref_06} = ref_p_mem_data_6;
assign {ref_87, ref_77, ref_67, ref_57, ref_47, ref_37, ref_27, ref_17, ref_07} = ref_p_mem_data_7;
assign {ref_88, ref_78, ref_68, ref_58, ref_48, ref_38, ref_28, ref_18, ref_08} = ref_p_mem_data_8;

dc_fifo #(6,3) sync_fifo_inst0(
	.aclr(~rst_n),

	.wr_clk(clk),
	.wr(ena & (mv_l0_calc_done | mv_l0_calc_done_d)),
	.wr_data({mv_l0_calc_done, blk4x4_counter}),
	.wr_full(),
	.wr_words_avail(),
		
	.rd_clk(ext_mem_reader_clk),
	.rd(~sync_fifo_rd_empty),
	.rd_data({mv_l0_calc_done_s, blk4x4_counter_s}),
	.rd_words_avail(),
	.rd_empty(sync_fifo_rd_empty)
);

sync_ram #(3+`mb_x_bits +`mb_y_bits+1+`mb_x_bits+1 + `mb_y_bits+1) sync_ram_0(
	.aclr(~rst_n),
	.wrclk(clk),
	.data({pic_num_2to0,total_mbs_one_frame,pic_width_in_mbs,
		pic_height_in_map_units}),
	.rdclk(ext_mem_reader_clk),
	.q({pic_num_2to0_s,total_mbs_one_frame_s,pic_width_in_mbs_s,
		pic_height_in_map_units_s})
);

sync_ram #(`mb_x_bits+`mb_y_bits+1+12+1) sync_ram_1(
	.aclr(~rst_n),
	.wrclk(clk),
	.data({mb_x,mb_y,is_mv_all_same,ref_idx_l0_curr_mb,start_of_MB}),
	.rdclk(ext_mem_reader_clk),
	.q({mb_x_s,mb_y_s,is_mv_all_same_s,ref_idx_l0_curr_mb_s,start_of_MB_s})
);

sync_ram #(256) sync_ram_2(
	.aclr(~rst_n),
	.wrclk(clk),
	.data({mvx_l0_curr_mb}),
	.rdclk(ext_mem_reader_clk),
	.q({mvx_l0_curr_mb_s})
);

sync_ram #(256) sync_ram_3(
	.aclr(~rst_n),
	.wrclk(clk),
	.data({mvy_l0_curr_mb}),
	.rdclk(ext_mem_reader_clk),
	.q({mvy_l0_curr_mb_s})
);

inter_pred_load inter_pred_load(
	.clk(ext_mem_reader_clk),
	.rst_n(ext_mem_reader_rst_n),
	.ena(ena),
	
	.start_of_MB_s(start_of_MB_s),
	.start_s(mv_l0_calc_done_s),
	.start(mv_l0_calc_done),
	.blk4x4_counter(blk4x4_counter_s),

	.pic_num_2to0(pic_num_2to0_s),
	.total_mbs_one_frame(total_mbs_one_frame_s),
    .pic_width_in_mbs(pic_width_in_mbs_s),
    .pic_height_in_map_units(pic_height_in_map_units_s),
    
	.mb_x(mb_x_s),
	.mb_y(mb_y_s),
	.is_mv_all_same(is_mv_all_same_s),
	.ref_idx_l0_curr_mb(ref_idx_l0_curr_mb_s),
	.mvx_l0_curr_mb(mvx_l0_curr_mb_s),
	.mvy_l0_curr_mb(mvy_l0_curr_mb_s), 
	
	.ext_mem_reader_burst_ready(ext_mem_reader_burst_ready),
	.ext_mem_reader_burst(ext_mem_reader_burst), 
	.ext_mem_reader_burst_len_minus1(ext_mem_reader_burst_len_minus1),
	.ext_mem_reader_burst_addr(ext_mem_reader_burst_addr),
	.ext_mem_reader_ready(ext_mem_reader_ready),
	.ext_mem_reader_data(ext_mem_reader_data),
	.ext_mem_reader_valid(ext_mem_reader_valid),
	
	.ref_p_mem_clk(clk),
	.ref_p_mem_rd(ref_p_mem_rd),
	.ref_p_mem_avail(ref_p_mem_avail),
	
	.ref_p_mem_data_0(ref_p_mem_data_0),
	.ref_p_mem_data_1(ref_p_mem_data_1),
	.ref_p_mem_data_2(ref_p_mem_data_2),
	.ref_p_mem_data_3(ref_p_mem_data_3),
	.ref_p_mem_data_4(ref_p_mem_data_4),
	.ref_p_mem_data_5(ref_p_mem_data_5),
	.ref_p_mem_data_6(ref_p_mem_data_6),
	.ref_p_mem_data_7(ref_p_mem_data_7),
	.ref_p_mem_data_8(ref_p_mem_data_8),
	
	.desc_fifo_wr(desc_fifo_wr),
	.desc_fifo_rd_empty(desc_fifo_rd_empty),
	.desc_fifo_rd_words_avail(desc_fifo_rd_words_avail),
	.desc_fifo_state(desc_fifo_state),
	.desc_fifo_rd(desc_fifo_rd) 
);

wire [7:0] inter_pred_0_i;
wire [7:0] inter_pred_1_i;
wire [7:0] inter_pred_2_i;
wire [7:0] inter_pred_3_i;
wire col_sel;

inter_pred_calc inter_pred_calc(
	.clk(clk),
	.rst_n(rst_n),
	.ena(ena),
	
	.counter_ppl0(counter_ppl0),
	.counter_ppl1(counter_ppl1),
	.counter_ppl2(counter_ppl2),
	.counter_ppl3(counter_ppl3),
	.counter_ppl4(counter_ppl4),
	
    .chroma_cb_sel_ppl0(chroma_cb_sel_ppl0),
    .chroma_cr_sel_ppl0(chroma_cr_sel_ppl0),
    .chroma_cb_sel_ppl1(chroma_cb_sel_ppl1),
    .chroma_cr_sel_ppl1(chroma_cr_sel_ppl1),
    .chroma_cb_sel_ppl2(chroma_cb_sel_ppl2),
    .chroma_cr_sel_ppl2(chroma_cr_sel_ppl2),
    .chroma_cb_sel_ppl3(chroma_cb_sel_ppl3),
    .chroma_cr_sel_ppl3(chroma_cr_sel_ppl3),
    .chroma_cb_sel_ppl4(chroma_cb_sel_ppl4),
    .chroma_cr_sel_ppl4(chroma_cr_sel_ppl4),
	
	.ref_x_ppl0(ref_x_ppl0),
	.ref_y_ppl0(ref_y_ppl0),
	.ref_x_ppl1(ref_x_ppl1),
	.ref_y_ppl1(ref_y_ppl1),
	.ref_x_ppl2(ref_x_ppl2),
	.ref_y_ppl2(ref_y_ppl2),
	.ref_x_ppl3(ref_x_ppl3),
	.ref_y_ppl3(ref_y_ppl3),
	.ref_x_ppl4(ref_x_ppl4),
	.ref_y_ppl4(ref_y_ppl4),
	
	.ref_00(ref_00),
	.ref_01(ref_01),
	.ref_02(ref_02),
	.ref_03(ref_03),
	.ref_04(ref_04),
	.ref_05(ref_05),
	.ref_06(ref_06),
	.ref_07(ref_07),
	.ref_08(ref_08),
	.ref_10(ref_10),
	.ref_11(ref_11),
	.ref_12(ref_12),
	.ref_13(ref_13),
	.ref_14(ref_14),
	.ref_15(ref_15),
	.ref_16(ref_16),
	.ref_17(ref_17),
	.ref_18(ref_18),
	.ref_20(ref_20),
	.ref_21(ref_21),
	.ref_22(ref_22),
	.ref_23(ref_23),
	.ref_24(ref_24),
	.ref_25(ref_25),
	.ref_26(ref_26),
	.ref_27(ref_27),
	.ref_28(ref_28),
	.ref_30(ref_30),
	.ref_31(ref_31),
	.ref_32(ref_32),
	.ref_33(ref_33),
	.ref_34(ref_34),
	.ref_35(ref_35),
	.ref_36(ref_36),
	.ref_37(ref_37),
	.ref_38(ref_38),
	.ref_40(ref_40),
	.ref_41(ref_41),
	.ref_42(ref_42),
	.ref_43(ref_43),
	.ref_44(ref_44),
	.ref_45(ref_45),
	.ref_46(ref_46),
	.ref_47(ref_47),
	.ref_48(ref_48),
	.ref_50(ref_50),
	.ref_51(ref_51),
	.ref_52(ref_52),
	.ref_53(ref_53),
	.ref_54(ref_54),
	.ref_55(ref_55),
	.ref_56(ref_56),
	.ref_57(ref_57),
	.ref_58(ref_58),
	.ref_60(ref_60),
	.ref_61(ref_61),
	.ref_62(ref_62),
	.ref_63(ref_63),
	.ref_64(ref_64),
	.ref_65(ref_65),
	.ref_66(ref_66),
	.ref_67(ref_67),
	.ref_68(ref_68),
	.ref_70(ref_70),
	.ref_71(ref_71),
	.ref_72(ref_72),
	.ref_73(ref_73),
	.ref_74(ref_74),
	.ref_75(ref_75),
	.ref_76(ref_76),
	.ref_77(ref_77),
	.ref_78(ref_78),
	.ref_80(ref_80),
	.ref_81(ref_81),
	.ref_82(ref_82),
	.ref_83(ref_83),
	.ref_84(ref_84),
	.ref_85(ref_85),
	.ref_86(ref_86),
	.ref_87(ref_87),
	.ref_88(ref_88),
	
	.inter_pred_0(inter_pred_0_i),
	.inter_pred_1(inter_pred_1_i),
	.inter_pred_2(inter_pred_2_i),
	.inter_pred_3(inter_pred_3_i),
	.col_sel(col_sel)
);
wire out_ram_wr_0;
wire out_ram_wr_1;
wire out_ram_wr_2;
wire out_ram_wr_3;
wire out_ram_wr_4;
wire out_ram_wr_5;
wire out_ram_wr_6;
wire out_ram_wr_7;
wire out_ram_wr_8;
wire out_ram_wr_9;
wire out_ram_wr_10;
wire out_ram_wr_11;
wire out_ram_wr_12;
wire out_ram_wr_13;
wire out_ram_wr_14;
wire out_ram_wr_15;
wire [4:0] out_ram_rd_addr;
wire [4:0] out_ram_wr_addr;


dp_ram #(8, 5) inter_pred_out_ram_0(
	.aclr(~rst_n),
	.data(inter_pred_0_i),
	.rdaddress(out_ram_rd_addr),	
	.wraddress(out_ram_wr_addr),
	.wren(out_ram_wr_0),
	.rdclock(clk),
	.wrclock(clk),
	.q(inter_pred_0)
);

dp_ram #(8, 5) inter_pred_out_ram_1(
	.aclr(~rst_n),
	.data(col_sel ? inter_pred_0_i : inter_pred_1_i),
	.rdaddress(out_ram_rd_addr),	
	.wraddress(out_ram_wr_addr),
	.wren(out_ram_wr_1),
	.rdclock(clk),
	.wrclock(clk),
	.q(inter_pred_1)
);

dp_ram #(8, 5) inter_pred_out_ram_2(
	.aclr(~rst_n),
	.data(col_sel ? inter_pred_0_i : inter_pred_2_i),
	.rdaddress(out_ram_rd_addr),	
	.wraddress(out_ram_wr_addr),
	.wren(out_ram_wr_2),
	.rdclock(clk),
	.wrclock(clk),
	.q(inter_pred_2)
);

dp_ram #(8, 5) inter_pred_out_ram_3(
	.aclr(~rst_n),
	.data(col_sel ? inter_pred_0_i : inter_pred_3_i),
	.rdaddress(out_ram_rd_addr),	
	.wraddress(out_ram_wr_addr),
	.wren(out_ram_wr_3),
	.rdclock(clk),
	.wrclock(clk),
	.q(inter_pred_3)
);

dp_ram #(8, 5) inter_pred_out_ram_4(
	.aclr(~rst_n),
	.data(col_sel ? inter_pred_1_i : inter_pred_0_i),
	.rdaddress(out_ram_rd_addr),	
	.wraddress(out_ram_wr_addr),
	.wren(out_ram_wr_4),
	.rdclock(clk),
	.wrclock(clk),
	.q(inter_pred_4)
);

dp_ram #(8, 5) inter_pred_out_ram_5(
	.aclr(~rst_n),
	.data(inter_pred_1_i),
	.rdaddress(out_ram_rd_addr),	
	.wraddress(out_ram_wr_addr),
	.wren(out_ram_wr_5),
	.rdclock(clk),
	.wrclock(clk),
	.q(inter_pred_5)
);

dp_ram #(8, 5) inter_pred_out_ram_6(
	.aclr(~rst_n),
	.data(col_sel ? inter_pred_1_i : inter_pred_2_i),
	.rdaddress(out_ram_rd_addr),	
	.wraddress(out_ram_wr_addr),
	.wren(out_ram_wr_6),
	.rdclock(clk),
	.wrclock(clk),
	.q(inter_pred_6)
);

dp_ram #(8, 5) inter_pred_out_ram_7(
	.aclr(~rst_n),
	.data(col_sel ? inter_pred_1_i : inter_pred_3_i),
	.rdaddress(out_ram_rd_addr),	
	.wraddress(out_ram_wr_addr),
	.wren(out_ram_wr_7),
	.rdclock(clk),
	.wrclock(clk),
	.q(inter_pred_7)
);

dp_ram #(8, 5) inter_pred_out_ram_8(
	.aclr(~rst_n),
	.data(col_sel ? inter_pred_2_i : inter_pred_0_i),
	.rdaddress(out_ram_rd_addr),	
	.wraddress(out_ram_wr_addr),
	.wren(out_ram_wr_8),
	.rdclock(clk),
	.wrclock(clk),
	.q(inter_pred_8)
);

dp_ram #(8, 5) inter_pred_out_ram_9(
	.aclr(~rst_n),
	.data(col_sel ? inter_pred_2_i : inter_pred_1_i),
	.rdaddress(out_ram_rd_addr),	
	.wraddress(out_ram_wr_addr),
	.wren(out_ram_wr_9),
	.rdclock(clk),
	.wrclock(clk),
	.q(inter_pred_9)
);

dp_ram #(8, 5) inter_pred_out_ram_10(
	.aclr(~rst_n),
	.data(inter_pred_2_i),
	.rdaddress(out_ram_rd_addr),	
	.wraddress(out_ram_wr_addr),
	.wren(out_ram_wr_10),
	.rdclock(clk),
	.wrclock(clk),
	.q(inter_pred_10)
);

dp_ram #(8, 5) inter_pred_out_ram_11(
	.aclr(~rst_n),
	.data(col_sel ? inter_pred_2_i : inter_pred_3_i),
	.rdaddress(out_ram_rd_addr),	
	.wraddress(out_ram_wr_addr),
	.wren(out_ram_wr_11),
	.rdclock(clk),
	.wrclock(clk),
	.q(inter_pred_11)
);

dp_ram #(8, 5) inter_pred_out_ram_12(
	.aclr(~rst_n),
	.data(col_sel ? inter_pred_3_i : inter_pred_0_i),
	.rdaddress(out_ram_rd_addr),	
	.wraddress(out_ram_wr_addr),
	.wren(out_ram_wr_12),
	.rdclock(clk),
	.wrclock(clk),
	.q(inter_pred_12)
);

dp_ram #(8, 5) inter_pred_out_ram_13(
	.aclr(~rst_n),
	.data(col_sel ? inter_pred_3_i : inter_pred_1_i),
	.rdaddress(out_ram_rd_addr),	
	.wraddress(out_ram_wr_addr),
	.wren(out_ram_wr_13),
	.rdclock(clk),
	.wrclock(clk),
	.q(inter_pred_13)
);

dp_ram #(8, 5) inter_pred_out_ram_14(
	.aclr(~rst_n),
	.data(col_sel ? inter_pred_3_i : inter_pred_2_i),
	.rdaddress(out_ram_rd_addr),	
	.wraddress(out_ram_wr_addr),
	.wren(out_ram_wr_14),
	.rdclock(clk),
	.wrclock(clk),
	.q(inter_pred_14)
);

dp_ram #(8, 5) inter_pred_out_ram_15(
	.aclr(~rst_n),
	.data(col_sel ? inter_pred_3_i : inter_pred_3_i),
	.rdaddress(out_ram_rd_addr),	
	.wraddress(out_ram_wr_addr),
	.wren(out_ram_wr_15),
	.rdclock(clk),
	.wrclock(clk),
	.q(inter_pred_15)
);

inter_pred_fsm inter_pred_fsm_inst(
	.clk(clk),
	.rst_n(rst_n),
	.ena(ena),

	.start(mv_l0_calc_done),
	.start_of_MB(start_of_MB),
	.col_sel(col_sel),
	.out_ram_wr_0(out_ram_wr_0),
	.out_ram_wr_1(out_ram_wr_1),
	.out_ram_wr_2(out_ram_wr_2),
	.out_ram_wr_3(out_ram_wr_3),
	.out_ram_wr_4(out_ram_wr_4),
	.out_ram_wr_5(out_ram_wr_5),
	.out_ram_wr_6(out_ram_wr_6),
	.out_ram_wr_7(out_ram_wr_7),
	.out_ram_wr_8(out_ram_wr_8),
	.out_ram_wr_9(out_ram_wr_9),
	.out_ram_wr_10(out_ram_wr_10),
	.out_ram_wr_11(out_ram_wr_11),
	.out_ram_wr_12(out_ram_wr_12),
	.out_ram_wr_13(out_ram_wr_13),
	.out_ram_wr_14(out_ram_wr_14),
	.out_ram_wr_15(out_ram_wr_15),
	.out_ram_wr_addr(out_ram_wr_addr),
	.out_ram_wr_addr_reg(out_ram_wr_addr_reg),
	.out_ram_rd_addr(out_ram_rd_addr),
	.out_ram_rd(out_ram_rd),

	.ref_p_fifo_empty(~ref_p_mem_avail),
	.ref_p_fifo_rd(ref_p_mem_rd),

	.mvx_l0_curr_mb(mvx_l0_curr_mb),
	.mvy_l0_curr_mb(mvy_l0_curr_mb),
	
	.counter_ppl0(counter_ppl0),
	.counter_ppl1(counter_ppl1),
	.counter_ppl2(counter_ppl2),
	.counter_ppl3(counter_ppl3),
	.counter_ppl4(counter_ppl4),
	
    .chroma_cb_sel_ppl0(chroma_cb_sel_ppl0),
    .chroma_cr_sel_ppl0(chroma_cr_sel_ppl0),
    .chroma_cb_sel_ppl1(chroma_cb_sel_ppl1),
    .chroma_cr_sel_ppl1(chroma_cr_sel_ppl1),
    .chroma_cb_sel_ppl2(chroma_cb_sel_ppl2),
    .chroma_cr_sel_ppl2(chroma_cr_sel_ppl2),
    .chroma_cb_sel_ppl3(chroma_cb_sel_ppl3),
    .chroma_cr_sel_ppl3(chroma_cr_sel_ppl3),
    .chroma_cb_sel_ppl4(chroma_cb_sel_ppl4),
    .chroma_cr_sel_ppl4(chroma_cr_sel_ppl4),
	
	.ref_x_ppl0(ref_x_ppl0),
	.ref_y_ppl0(ref_y_ppl0),
	.ref_x_ppl1(ref_x_ppl1),
	.ref_y_ppl1(ref_y_ppl1),
	.ref_x_ppl2(ref_x_ppl2),
	.ref_y_ppl2(ref_y_ppl2),
	.ref_x_ppl3(ref_x_ppl3),
	.ref_y_ppl3(ref_y_ppl3),
	.ref_x_ppl4(ref_x_ppl4),
	.ref_y_ppl4(ref_y_ppl4)
);

endmodule
