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

module inter_pred_load
( 
	input  clk,
	input  rst_n,
	input  ena,
		
	input start,
	input start_s,
	input start_of_MB_s,

	(* KEEP = "TRUE" *)(*mark_debug = "true"*)input [4:0] blk4x4_counter,
		
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

	(* KEEP = "TRUE" *)(*mark_debug = "true"*)input                                   ext_mem_reader_burst_ready,
	(* KEEP = "TRUE" *)(*mark_debug = "true"*)output reg								ext_mem_reader_burst, 
	(* KEEP = "TRUE" *)(*mark_debug = "true"*)output reg [4:0]						ext_mem_reader_burst_len_minus1,
	output reg [`ext_buf_mem_addr_width-1:0]ext_mem_reader_burst_addr,
	(* KEEP = "TRUE" *)(*mark_debug = "true"*)output reg								ext_mem_reader_ready,
	input[`ext_buf_mem_rd_data_width-1:0]   ext_mem_reader_data,
	(* KEEP = "TRUE" *)(*mark_debug = "true"*)input									ext_mem_reader_valid,

	input ref_p_mem_clk,
	input ref_p_mem_rd,
	output logic ref_p_mem_avail,
	output logic [71:0] ref_p_mem_data_0,
	output logic [71:0] ref_p_mem_data_1,
	output logic [71:0] ref_p_mem_data_2,
	output logic [71:0] ref_p_mem_data_3,
	output logic [71:0] ref_p_mem_data_4,
	output logic [71:0] ref_p_mem_data_5,
	output logic [71:0] ref_p_mem_data_6,
	output logic [71:0] ref_p_mem_data_7,
	output logic [71:0] ref_p_mem_data_8,
	
	output desc_fifo_wr,
	output desc_fifo_rd_empty,
	output [5:0] desc_fifo_rd_words_avail,
	output reg [2:0] desc_fifo_state,
	output desc_fifo_rd
	
); 

reg  [`ext_buf_mem_addr_width-1:0]  luma_addr_base;
reg  [`ext_buf_mem_addr_width-1:0]  cb_addr_base;
reg  [`ext_buf_mem_addr_width-1:0]  cr_addr_base;
reg  [0:7][`ext_buf_mem_addr_width-1:0]  luma_addr_base_precalc;
reg  [0:7][`ext_buf_mem_addr_width-1:0]  cb_addr_base_precalc;
reg  [0:7][`ext_buf_mem_addr_width-1:0]  cr_addr_base_precalc;
reg  [`ext_buf_mem_addr_width-1:0]  luma_addr_base_prev;
reg  [`ext_buf_mem_addr_width-1:0]  cb_addr_base_prev;
reg  [`ext_buf_mem_addr_width-1:0]  cr_addr_base_prev;

reg  [`mb_x_bits + 3:0] pic_width_minus1; 
reg  [`mb_x_bits + 3:0] pic_width_minus1_chroma; 
reg  [`mb_y_bits + 3:0] pic_hight_minus1; 
reg  [`mb_y_bits + 3:0] pic_hight_minus1_chroma; 

(* KEEP = "TRUE" *)(*mark_debug = "true"*)reg  [8:0]                          ref_nword_left;    
reg [`ext_buf_mem_addr_width-1:0]   ref_mem_addr;
reg [12:0][12:0][7:0] ref_p_cache0; 
reg [12:0][20:8][7:0] ref_p_cache1; 
reg [3:0] cmd_state;
reg [3:0] cmd_state_d;
reg [3:0] cmd_state_dd;
reg [3:0] cmd_counter;
reg [7:0] cmd_counter_total;
reg [4:0] cmd_blk4x4_counter;
reg [4:0] cmd_blk4x4_counter_d;
reg [4:0] cmd_blk4x4_counter_dd;
reg [2:0] ref_idx;
parameter
CmdIdle = 4'd0,
CmdCombine4x4 = 4'd1,
CmdCombine4x9 = 4'd2,
CmdCombine9x4 = 4'd3,
CmdCombine9x9 = 4'd4,
CmdCombineChroma4x4 = 4'd5,
CmdCombineChroma5x5 = 4'd6,
CmdSeperate4x4 = 4'd8,
CmdSeperate4x9 = 4'd9,
CmdSeperate9x4 = 4'd10,
CmdSeperate9x9 = 4'd11,
CmdSeperateChroma4x4 = 4'd12,
CmdSeperateChroma5x5 = 4'd13,
CmdSeperateLastCycle = 4'd14;

reg signed [5:0] i;
reg signed [4:0] j;
reg signed [5:0] i_d;
reg signed [5:0] i_dd;
reg signed [4:0] j_d;
reg signed [4:0] j_dd;
reg signed [4:0] k;
reg is_cb;
reg is_cr;
wire signed [5:0] desc_fifo_i;
wire signed [4:0] desc_fifo_j;
wire [4:0] desc_fifo_k;
wire desc_fifo_is_clip_left;
wire desc_fifo_is_clip_right;
wire [4:0] desc_fifo_pixel_ref_x_clip_position;
wire [3:0] desc_fifo_cmd_state;
wire [7:0] desc_fifo_cmd_counter;
reg signed [`mb_x_bits + 4:0] pixel_ref_x_unclip; 
reg signed [`mb_y_bits + 4:0] pixel_ref_y_unclip;
reg [`mb_y_bits + 3:0] pixel_ref_y_clip;
reg [`mb_y_bits + 3:0] pixel_ref_y_clip_reg;
reg [`mb_y_bits + `mb_x_bits + 2:0] pixel_ref_y_clip_X_pic_width_in_mbs;

reg [`mb_x_bits + 3:0] pixel_ref_x_clip;
reg [4:0] pixel_ref_x_clip_position;
reg is_clip_left;
reg is_clip_right;

wire signed [`mb_x_bits + 4:0] ref_x_lt = mb_x << 4;
wire signed [`mb_y_bits + 4:0] ref_y_lt = mb_y << 4;
wire signed [`mb_x_bits + 3:0] chroma_ref_x_lt = mb_x << 3;
wire signed [`mb_y_bits + 3:0] chroma_ref_y_lt = mb_y << 3;
reg ext_mem_reader_burst_ena;

reg [4:0] k_d;
reg [4:0] k_dd;
reg is_cb_d;
reg is_cb_dd;
reg is_cr_d;
reg is_cr_dd;
reg ext_mem_reader_burst_ena_d;
reg ext_mem_reader_burst_ena_dd;
always @(posedge clk or negedge rst_n)
if (~rst_n) begin
	ext_mem_reader_burst_addr <= 0;
	ext_mem_reader_burst_len_minus1 <= 0;
	ext_mem_reader_burst <= 0;
end
else if (ena && ext_mem_reader_burst_ready) begin
	ext_mem_reader_burst_addr <= ref_mem_addr;
	ext_mem_reader_burst_len_minus1 <= ((k_dd+7) >> 3) - 1;
	ext_mem_reader_burst <= ext_mem_reader_burst_ena_dd;
end



always @(*)
if (is_cb_dd)
	ref_mem_addr <= cb_addr_base + pixel_ref_y_clip_X_pic_width_in_mbs * 8 + pixel_ref_x_clip;
else if (is_cr_dd)
	ref_mem_addr <= cr_addr_base + pixel_ref_y_clip_X_pic_width_in_mbs * 8 + pixel_ref_x_clip;
else
	ref_mem_addr <= luma_addr_base + pixel_ref_y_clip_X_pic_width_in_mbs * 16 + pixel_ref_x_clip;


always @(posedge clk or negedge rst_n)
if (~rst_n) begin
	pixel_ref_y_clip_reg <= 0;
	pixel_ref_y_clip_X_pic_width_in_mbs <= 0;
	cmd_state_dd <= 0;
	cmd_blk4x4_counter_d <= 0;
	cmd_blk4x4_counter_dd <= 0;
	i_d <= 0;
	i_dd <= 0;
	j_d <= 0;
	j_dd <= 0;
	k_dd <= 0;
	k_d <= 0;
	is_cb_d <= 0;
	is_cb_dd <= 0;
	is_cr_d <= 0;
	is_cr_dd <= 0;
	ext_mem_reader_burst_ena_dd <= 0;
	ext_mem_reader_burst_ena_d <= 0;
end
else if (ena && start_of_MB_s) begin
	pixel_ref_y_clip_reg <= 0;
	pixel_ref_y_clip_X_pic_width_in_mbs <= 0;
	cmd_state_dd <= 0;
	cmd_blk4x4_counter_d <= 0;
	cmd_blk4x4_counter_dd <= 0;
	i_d <= 0;
	i_dd <= 0;
	j_d <= 0;
	j_dd <= 0;
	k_dd <= 0;
	k_d <= 0;
	is_cb_d <= 0;
	is_cb_dd <= 0;
	is_cr_d <= 0;
	is_cr_dd <= 0;
	ext_mem_reader_burst_ena_dd <= 0;
	ext_mem_reader_burst_ena_d <= 0;
end
else if (ena && ext_mem_reader_burst_ready) begin
	pixel_ref_y_clip_reg <= pixel_ref_y_clip;
	pixel_ref_y_clip_X_pic_width_in_mbs <= pixel_ref_y_clip_reg * pic_width_in_mbs;
	cmd_state_d <= cmd_state;
	cmd_state_dd <= cmd_state_d;
	cmd_blk4x4_counter_d <= cmd_blk4x4_counter;
	cmd_blk4x4_counter_dd <= cmd_blk4x4_counter_d;
	if (cmd_blk4x4_counter > 15 && cmd_state != CmdCombineChroma4x4 && cmd_state != CmdCombineChroma5x5) begin
		if (cmd_blk4x4_counter[0])
			j_d <= 8;
		else 
			j_d <= 0;
	end
	else begin
		j_d <= j;
	end
	if (cmd_blk4x4_counter > 15 && cmd_state != CmdCombineChroma4x4 && cmd_state != CmdCombineChroma5x5) begin
		if (cmd_blk4x4_counter[1])
			i_d <= i + 4;
		else
			i_d <= i;
	end
	else begin
		i_d <= i;
	end
	i_dd <= i_d;
	j_dd <= j_d;
	k_d <= k;
	k_dd <= k_d;
	is_cb_d <= is_cb;
	is_cb_dd <= is_cb_d;
	is_cr_d <= is_cr;
	is_cr_dd <= is_cr_d;
	ext_mem_reader_burst_ena_d <= ext_mem_reader_burst_ena;
	ext_mem_reader_burst_ena_dd <= ext_mem_reader_burst_ena_d;
end

reg signed [15:0] mvx_l0;
reg signed [15:0] mvy_l0;
wire signed [10:0] mvx_l0_int;
wire signed [10:0] mvy_l0_int;

assign mvx_l0_int = {mvx_l0[15], mvx_l0[11:2]};
assign mvy_l0_int = {mvy_l0[15], mvy_l0[11:2]};

always @(posedge clk) //integer pixel positions
if (ena && ext_mem_reader_burst_ready && !is_cb && !is_cr) begin //luma
    pixel_ref_x_unclip <= ref_x_lt + mvx_l0_int + j;
end
else if (ena && ext_mem_reader_burst_ready) begin  //chroma
    pixel_ref_x_unclip <= chroma_ref_x_lt + (mvx_l0_int>>>1) + j;
end

always @(*) //integer pixel positions
if (!is_cb && !is_cr) begin //luma
    pixel_ref_y_unclip <= ref_y_lt + mvy_l0_int + i;
end
else begin  //chroma
    pixel_ref_y_unclip <= chroma_ref_y_lt + (mvy_l0_int>>>1) + i;
end

wire signed [5:0] minus_k_d_signed;
assign minus_k_d_signed = -k_d;
always @(posedge clk or negedge rst_n)
if (~rst_n) begin
	is_clip_left <= 0;
	is_clip_right <= 0;
	pixel_ref_x_clip <= 0;
	pixel_ref_x_clip_position <= 0; 
end
else if (ena && ext_mem_reader_burst_ready) begin
	if (pixel_ref_x_unclip[`mb_x_bits + 4]) begin   //out of left bound
	    pixel_ref_x_clip <= 0;
		if (cmd_state_d != CmdIdle) begin
			pixel_ref_x_clip_position <= pixel_ref_x_unclip > minus_k_d_signed ? -pixel_ref_x_unclip : k_d-1;
			is_clip_left <= 1'b1;
			is_clip_right <= 1'b0;
		end
	end
	else if ((!is_cb_d && !is_cr_d) &&
	        pixel_ref_x_unclip[`mb_x_bits + 3:0] + k_d > pic_width_in_mbs << 4) begin //luma out of right bound
	    pixel_ref_x_clip <= pixel_ref_x_unclip[`mb_x_bits + 3:0] > pic_width_minus1 ? pic_width_minus1 : pixel_ref_x_unclip[`mb_x_bits + 3:0];
		if (cmd_state_d != CmdIdle) begin
			pixel_ref_x_clip_position <= pixel_ref_x_unclip[`mb_x_bits + 3:0] > pic_width_minus1 ? 0 : 
												(pic_width_minus1 - pixel_ref_x_unclip[`mb_x_bits + 3:0]);
			is_clip_left <= 1'b0;
			is_clip_right <= 1'b1;
		end
	end
	else if ((is_cb_d || is_cr_d) &&
	        pixel_ref_x_unclip[`mb_x_bits + 3:0] + k_d > (pic_width_in_mbs << 3)) begin //chroma out of right bound
	    pixel_ref_x_clip <= pixel_ref_x_unclip[`mb_x_bits + 3:0] > pic_width_minus1_chroma ? pic_width_minus1_chroma : pixel_ref_x_unclip[`mb_x_bits + 3:0];
		if (cmd_state_d != CmdIdle) begin
			pixel_ref_x_clip_position <= pixel_ref_x_unclip[`mb_x_bits + 3:0] > pic_width_minus1_chroma ? 0 : 
												(pic_width_minus1_chroma - pixel_ref_x_unclip[`mb_x_bits + 3:0]);
			is_clip_left <= 1'b0;
			is_clip_right <= 1'b1;
		end
	end
	else begin
	    pixel_ref_x_clip <= pixel_ref_x_unclip[`mb_x_bits + 3:0];
		is_clip_left <= 1'b0;
		is_clip_right <= 1'b0;
	end
end

always @(*)
if (pixel_ref_y_unclip[`mb_y_bits + 4])//out of up bound
    pixel_ref_y_clip <= 0;
else if ((!is_cb && !is_cr) && 
        pixel_ref_y_unclip[`mb_y_bits + 3:0] >= pic_height_in_map_units << 4)//luma out of bottom bound
    pixel_ref_y_clip <= pic_hight_minus1;
else if ((is_cb || is_cr) && 
        pixel_ref_y_unclip[`mb_y_bits + 3:0] >= pic_height_in_map_units << 3)//chroma out of bottom bound
    pixel_ref_y_clip <= pic_hight_minus1_chroma;
else
    pixel_ref_y_clip <= pixel_ref_y_unclip[`mb_y_bits + 3:0];


//cb_addr_base & cr_addr_base
wire [2:0] ref_pic_num;
assign ref_pic_num = pic_num_2to0 - 1 - ref_idx;

reg  [`mb_x_bits + `mb_y_bits:0] prev_total_mbs_one_frame;
reg [3:0] addr_base_precalc_counter;
wire [`mb_x_bits + `mb_y_bits+9:0] pic_size;
assign pic_size = (total_mbs_one_frame << 8) + (total_mbs_one_frame << 7);
always @(posedge clk or negedge rst_n)
if (!rst_n) begin
    prev_total_mbs_one_frame <= 0;
    pic_width_minus1 <= 0;
    pic_width_minus1_chroma <= 0;
    addr_base_precalc_counter <= 0;
    luma_addr_base_precalc <= '0;
    cb_addr_base_precalc <= '0;
    cr_addr_base_precalc <= '0;
    luma_addr_base_prev <= '0;
    cb_addr_base_prev <= '0;
    cr_addr_base_prev <= '0;
end
else begin
	prev_total_mbs_one_frame <= total_mbs_one_frame;
	if (prev_total_mbs_one_frame == 0 && total_mbs_one_frame > 0) begin
		addr_base_precalc_counter <= 1;
	    pic_width_minus1 <= (pic_width_in_mbs << 4) - 1;
    	pic_width_minus1_chroma <= (pic_width_in_mbs << 3) - 1;
    	pic_hight_minus1 <= (pic_height_in_map_units << 4) - 1; 
    	pic_hight_minus1_chroma <= (pic_height_in_map_units << 3) - 1;
    	
    	luma_addr_base_precalc[0] <= 0;
	    cb_addr_base_precalc[0] <= total_mbs_one_frame * 256;
	    cr_addr_base_precalc[0] <= total_mbs_one_frame * 256 + total_mbs_one_frame * 64;
    	luma_addr_base_prev <= 0;
	    cb_addr_base_prev <= (total_mbs_one_frame <<8) ;
	    cr_addr_base_prev <= (total_mbs_one_frame <<8) + (total_mbs_one_frame <<6) ;	    
	end
	if (addr_base_precalc_counter > 0 && addr_base_precalc_counter < 8)
		addr_base_precalc_counter <= addr_base_precalc_counter + 1'b1;
	if (addr_base_precalc_counter > 0 && addr_base_precalc_counter < 8) begin
   		luma_addr_base_precalc[addr_base_precalc_counter[2:0]] <= luma_addr_base_prev + pic_size;
	    cb_addr_base_precalc[addr_base_precalc_counter[2:0]] <= cb_addr_base_prev + pic_size;
	    cr_addr_base_precalc[addr_base_precalc_counter[2:0]] <= cr_addr_base_prev + pic_size;
	    luma_addr_base_prev <= luma_addr_base_prev + pic_size;
	    cb_addr_base_prev <= cb_addr_base_prev + pic_size;
	    cr_addr_base_prev <= cr_addr_base_prev + pic_size;
	end
end

reg calc_addr_base_start;

always @(posedge clk or negedge rst_n)
if (!rst_n) begin
    luma_addr_base <= 0;
    cb_addr_base <= 0;
    cr_addr_base <= 0;

end
else if (ena && calc_addr_base_start) begin
    luma_addr_base <= luma_addr_base_precalc[ref_pic_num];
    cb_addr_base <= cb_addr_base_precalc[ref_pic_num];
    cr_addr_base <= cr_addr_base_precalc[ref_pic_num];
end

(* KEEP = "TRUE" *)(*mark_debug = "true"*)wire is_ref_mv_all_same;
assign is_ref_mv_all_same = is_mv_all_same &&
				ref_idx_l0_curr_mb[11:6] == ref_idx_l0_curr_mb[5:0] &&
				ref_idx_l0_curr_mb[5:3] == ref_idx_l0_curr_mb[2:0];

wire [4:0] blk4x4_counter_8X8_scan_order;
reg [4:0] cmd_seperate_next_blk4x4_counter;
wire signed [4:0] cmd_blk4x4_luma_i;
wire signed [4:0] cmd_blk4x4_luma_j;
wire signed [3:0] cmd_blk4x4_chroma_i;
wire signed [3:0] cmd_blk4x4_chroma_j;
assign cmd_blk4x4_luma_i = {1'b0,cmd_seperate_next_blk4x4_counter[3:2],2'b0};
assign cmd_blk4x4_luma_j = {1'b0,cmd_seperate_next_blk4x4_counter[1:0],2'b0};
assign cmd_blk4x4_chroma_i = {1'b0,cmd_seperate_next_blk4x4_counter[1],2'b0};
assign cmd_blk4x4_chroma_j = {1'b0,cmd_seperate_next_blk4x4_counter[0],2'b0};

reg [7:0] total_nword_seperate_luma_blk16X8_0;
reg [7:0] total_nword_seperate_luma_blk16X8_1;
reg [5:0] total_nword_seperate_chroma_blk16X8_0;
reg [5:0] total_nword_seperate_chroma_blk16X8_1;
//x0y0 16
//x1y0 01 32
//x0y1 10 26
//x1y1 11 52
 
always @(posedge clk) begin
	case ({|mvy_l0_curr_mb[65:64],   |mvx_l0_curr_mb[65:64],
		   |mvy_l0_curr_mb[1:0],     |mvx_l0_curr_mb[1:0]})
	{4'b0000}:total_nword_seperate_luma_blk16X8_0 <= 16+16;
	{4'b0100},
	{4'b0001}:total_nword_seperate_luma_blk16X8_0 <= 32+16;
	{4'b0010},
	{4'b1000}:total_nword_seperate_luma_blk16X8_0 <= 26+16;
	{4'b0011},
	{4'b1100}:total_nword_seperate_luma_blk16X8_0 <= 52+16;
	{4'b0101}:total_nword_seperate_luma_blk16X8_0 <= 32+32;
	{4'b1001},
	{4'b0110}:total_nword_seperate_luma_blk16X8_0 <= 32+26;
	{4'b1101},
	{4'b0111}:total_nword_seperate_luma_blk16X8_0 <= 52+32;
	{4'b1010}:total_nword_seperate_luma_blk16X8_0 <= 26+26;
	{4'b1110},
	{4'b1011}:total_nword_seperate_luma_blk16X8_0 <= 52+26;
	{4'b1111}:total_nword_seperate_luma_blk16X8_0 <= 52+52;
	endcase
end
	   
always @(posedge clk) begin
	case ({|mvy_l0_curr_mb[193:192], |mvx_l0_curr_mb[193:192], 
	       |mvy_l0_curr_mb[129:128], |mvx_l0_curr_mb[129:128]})
	{4'b0000}:total_nword_seperate_luma_blk16X8_1 <= 16+16;
	{4'b0100},
	{4'b0001}:total_nword_seperate_luma_blk16X8_1 <= 32+16;
	{4'b0010},
	{4'b1000}:total_nword_seperate_luma_blk16X8_1 <= 26+16;
	{4'b0011},
	{4'b1100}:total_nword_seperate_luma_blk16X8_1 <= 52+16;
	{4'b0101}:total_nword_seperate_luma_blk16X8_1 <= 32+32;
	{4'b1001},
	{4'b0110}:total_nword_seperate_luma_blk16X8_1 <= 32+26;
	{4'b1101},
	{4'b0111}:total_nword_seperate_luma_blk16X8_1 <= 52+32;
	{4'b1010}:total_nword_seperate_luma_blk16X8_1 <= 26+26;
	{4'b1110},
	{4'b1011}:total_nword_seperate_luma_blk16X8_1 <= 52+26;
	{4'b1111}:total_nword_seperate_luma_blk16X8_1 <= 52+52;
	endcase
end

always @(posedge clk) begin
	case ({|mvy_l0_curr_mb[66:64] | |mvx_l0_curr_mb[66:64],
		   |mvy_l0_curr_mb[2:0]   | |mvx_l0_curr_mb[2:0]})
	{2'b00}:total_nword_seperate_chroma_blk16X8_0 <= 8+8;
	{2'b01},
	{2'b10}:total_nword_seperate_chroma_blk16X8_0 <= 8+10;
	{2'b11}:total_nword_seperate_chroma_blk16X8_0 <= 10+10;
	endcase
end

always @(posedge clk) begin
	case ({|mvy_l0_curr_mb[194:192] | |mvx_l0_curr_mb[194:192], 
	       |mvy_l0_curr_mb[130:128] | |mvx_l0_curr_mb[130:128]})
	{2'b00}:total_nword_seperate_chroma_blk16X8_1 <= 8+8;
	{2'b01},
	{2'b10}:total_nword_seperate_chroma_blk16X8_1 <= 8+10;
	{2'b11}:total_nword_seperate_chroma_blk16X8_1 <= 10+10;
	endcase
end

//raster to 8*8 scan
always @(*)
if (cmd_blk4x4_counter < 16)
	cmd_seperate_next_blk4x4_counter <= cmd_blk4x4_counter + 2'd2;
else
	cmd_seperate_next_blk4x4_counter <= cmd_blk4x4_counter + 1'd1;

assign blk4x4_counter_8X8_scan_order ={cmd_seperate_next_blk4x4_counter[4:3],
										cmd_seperate_next_blk4x4_counter[1], 
										cmd_seperate_next_blk4x4_counter[2],
										cmd_seperate_next_blk4x4_counter[0]}; 

always @(posedge clk or negedge rst_n)
if (~rst_n)begin
	ref_nword_left <= 0;
end
else if (blk4x4_counter == 0 && start_s)begin
	if (is_ref_mv_all_same)begin
		case({|mvy_l0_curr_mb[1:0], |mvx_l0_curr_mb[1:0]})
		2'b00:ref_nword_left <= {mvx_l0_curr_mb[2]|mvy_l0_curr_mb[2]}? 32 + 36 :32 + 16;
		2'b01:ref_nword_left <= 48 + 36;
		2'b10:ref_nword_left <= 42 + 36;
		2'b11:ref_nword_left <= 63 + 36;
		default:ref_nword_left <= 'bx;
		endcase
	end
	else begin
		ref_nword_left <= (total_nword_seperate_luma_blk16X8_0 + total_nword_seperate_luma_blk16X8_1)/2 +
						total_nword_seperate_chroma_blk16X8_0 + total_nword_seperate_chroma_blk16X8_1;
	end
end
else if (ext_mem_reader_valid && ext_mem_reader_ready)begin
	ref_nword_left <= ref_nword_left - 1'b1;
end

always @(posedge clk or negedge rst_n)
if (~rst_n) begin
	cmd_state <= CmdIdle;
	cmd_counter <= 0;
	cmd_counter_total <= 0;
	ref_idx <= 0;
	ext_mem_reader_burst_ena <= 1'b0;
	cmd_blk4x4_counter <= 0;
	calc_addr_base_start <= 0;
	i <= 0;
	j <= 0;
	k <= 0;
	is_cb <= 0;
	is_cr <= 0;
	mvx_l0 <= 0;
	mvy_l0 <= 0;
end
else if (ena) begin
	calc_addr_base_start <= 0;
	casex({ext_mem_reader_burst_ready, cmd_state})
	{1'bx,CmdIdle}: begin
		if (start_s && is_ref_mv_all_same && blk4x4_counter == 0) begin		
			cmd_blk4x4_counter <= 0;
			ext_mem_reader_burst_ena <= 1'b1;
			is_cb <= 0;
			is_cr <= 0;
			ref_idx <= ref_idx_l0_curr_mb[2:0];
			mvx_l0 <= mvx_l0_curr_mb[16:0];
			mvy_l0 <= mvy_l0_curr_mb[16:0];
			cmd_counter_total <= 1;
			cmd_counter <= 0;
			calc_addr_base_start <= 1;
			if (mvx_l0_curr_mb[1:0] == 0 && mvy_l0_curr_mb[1:0] == 0) begin
				cmd_state <= CmdCombine4x4;
				i <= 0;
				j <= 0;
				k <= 16;
			end
			else if (mvx_l0_curr_mb[1:0] == 0) begin
				cmd_state <= CmdCombine9x4;
				i <= -2;
				j <= 0;
				k <= 16;
			end
			else if  (mvy_l0_curr_mb[1:0] == 0) begin
				cmd_state <= CmdCombine4x9;
				i <= 0;
				j <= -2;
				k <= 21;
			end
			else begin
				cmd_state <= CmdCombine9x9;
				i <= -2;
				j <= -2;
				k <= 21;
			end
		end	
		else if (start_s && blk4x4_counter == 0)begin
			is_cb <= 0;
			is_cr <= 0;
			ext_mem_reader_burst_ena <= 1'b1;
			cmd_counter_total <= 1;
			cmd_counter <= 0;
			calc_addr_base_start <= 1;
			mvx_l0 <= mvx_l0_curr_mb[15:0];
			mvy_l0 <= mvy_l0_curr_mb[15:0];
			ref_idx <= ref_idx_l0_curr_mb[2:0];
			if(mvx_l0_curr_mb[1:0] == 0 && mvy_l0_curr_mb[1:0] == 0) begin
				cmd_state <= CmdSeperate4x4;
				i <= 0;
				j <= 0;
				k <= 8;
			end
			else if (mvy_l0_curr_mb[1:0] == 0) begin
				cmd_state <= CmdSeperate4x9;
				i <= 0;
				j <= -2;
				k <= 13;
			end
			else if (mvx_l0_curr_mb[1:0] == 0) begin
				cmd_state <= CmdSeperate9x4;
				i <= -2;
				j <= 0;
				k <= 8;
			end
			else begin
				cmd_state <= CmdSeperate9x9;
				i <= -2;
				j <= -2;
				k <= 13;
			end
		end
/*
		else begin
			cmd_state <= SeperateCmd;
			cmd_counter <= 0;
		end
*/	end
	{1'b1, CmdCombine4x4}: begin
		cmd_counter <= cmd_counter + 1'b1;
		cmd_counter_total <= cmd_counter_total + 1'b1;
		i <= i + 1'b1;
		if (cmd_blk4x4_counter == 0 && cmd_counter == 3) begin
			cmd_blk4x4_counter <= 4;			
			cmd_counter <= 0;
		end
		else if (cmd_blk4x4_counter == 4 && cmd_counter == 3) begin
			cmd_blk4x4_counter <= 8;
			cmd_counter <= 0;
		end
		else if (cmd_blk4x4_counter == 8 && cmd_counter == 3) begin
			cmd_blk4x4_counter <= 12;
			cmd_counter <= 0;
		end
		else if (cmd_blk4x4_counter == 12 && cmd_counter == 3) begin
			if (mvx_l0_curr_mb[2] || mvy_l0_curr_mb[2]) begin
				cmd_state <= CmdCombineChroma5x5;
				k <= 9;
			end
			else begin
				cmd_state <= CmdCombineChroma4x4;
				k <= 8;
			end
			cmd_counter_total <= 1;
			cmd_blk4x4_counter <= 16;			
			cmd_counter <= 0;
			i <= 0;
			j <= 0;
			is_cb <= 1'b1;
			is_cr <= 1'b0;
		end	
	end
	{1'b1, CmdCombine4x9}: begin
		cmd_counter <= cmd_counter + 1'b1;
		cmd_counter_total <= cmd_counter_total + 1'b1;
		i <= i + 1'b1;
		if (cmd_blk4x4_counter == 0 && cmd_counter == 3) begin
			cmd_blk4x4_counter <= 4;			
			cmd_counter <= 0;
		end
		else if (cmd_blk4x4_counter == 4 && cmd_counter == 3) begin
			cmd_blk4x4_counter <= 8;			
			cmd_counter <= 0;
		end
		else if (cmd_blk4x4_counter == 8 && cmd_counter == 3) begin
			cmd_blk4x4_counter <= 12;			
			cmd_counter <= 0;
		end
		else if (cmd_blk4x4_counter == 12 && cmd_counter == 3) begin
			cmd_state <= CmdCombineChroma5x5;
			cmd_counter_total <= 1;
			cmd_blk4x4_counter <= 16;			
			cmd_counter <= 0;
			i <= 0;
			j <= 0;
			k <= 9;
			is_cb <= 1'b1;
			is_cr <= 1'b0;
		end
	end
	{1'b1,CmdCombine9x4}, {1'b1,CmdCombine9x9}:begin
		cmd_counter <= cmd_counter + 1'b1;
		cmd_counter_total <= cmd_counter_total + 1'b1;
		i <= i + 1'b1;
		if (cmd_blk4x4_counter == 0 && cmd_counter == 8) begin
			cmd_blk4x4_counter <= 4;			
			cmd_counter <= 0;
		end
		else if (cmd_blk4x4_counter == 4 && cmd_counter == 3) begin
			cmd_blk4x4_counter <= 8;			
			cmd_counter <= 0;
		end
		else if (cmd_blk4x4_counter == 8 && cmd_counter == 3) begin
			cmd_blk4x4_counter <= 12;			
			cmd_counter <= 0;
		end
		else if (cmd_blk4x4_counter == 12 && cmd_counter == 3) begin
			cmd_state <= CmdCombineChroma5x5;
			cmd_counter_total <= 1;
			cmd_blk4x4_counter <= 16;			
			cmd_counter <= 0;
			i <= 0;
			j <= 0;
			k <= 9;
			is_cb <= 1'b1;
			is_cr <= 1'b0;
		end
	end
	{1'b1,CmdCombineChroma4x4}:begin
		cmd_counter <= cmd_counter + 1'b1;
		cmd_counter_total <= cmd_counter_total + 1'b1;
		i <= i + 1'b1;
		if (cmd_blk4x4_counter == 16 && cmd_counter == 7) begin
			cmd_blk4x4_counter <= 20;			
			cmd_counter <= 0;
			i <= 0;
			j <= 0;
			is_cb <= 1'b0;
			is_cr <= 1'b1;
		end
		else if (cmd_blk4x4_counter == 20 && cmd_counter == 7) begin
			is_cb <= 1'b0;
			is_cr <= 1'b0;
			cmd_blk4x4_counter <= 0;
			cmd_counter <= 0;
			ext_mem_reader_burst_ena <= 0;
			cmd_state <= CmdIdle;
		end
	end
	{1'b1,CmdCombineChroma5x5}:begin
		cmd_counter <= cmd_counter + 1'b1;
		cmd_counter_total <= cmd_counter_total + 1'b1;
		i <= i + 1'b1;
		if (cmd_blk4x4_counter == 16 && cmd_counter == 4) begin
			cmd_blk4x4_counter <= 18;			
			cmd_counter <= 0;
		end
		else if (cmd_blk4x4_counter == 18 && cmd_counter == 3) begin
			cmd_blk4x4_counter <= 20;			
			cmd_counter <= 0;
			i <= 0;
			is_cb <= 1'b0;
			is_cr <= 1'b1;
		end
		else if (cmd_blk4x4_counter == 20 && cmd_counter == 4) begin
			cmd_blk4x4_counter <= 22;
			cmd_counter <= 0;
		end
		else if (cmd_blk4x4_counter == 22 && cmd_counter == 3) begin
			is_cb <= 1'b0;
			is_cr <= 1'b0;
			cmd_blk4x4_counter <= 0;
			cmd_counter <= 0;
			ext_mem_reader_burst_ena <= 0;
			cmd_state <= CmdIdle;
		end
	end
	{1'b1,CmdSeperate4x4}:begin
		cmd_counter_total <= cmd_counter_total + 1'b1;
		i <= i + 1'b1;
		if (cmd_counter_total == 3) begin
			cmd_state <= CmdSeperateLastCycle;
		end
	end
	{1'b1,CmdSeperate4x9}:begin
		cmd_counter_total <= cmd_counter_total + 1'b1;
		i <= i + 1'b1;
		if (cmd_counter_total == 3) begin
			cmd_state <= CmdSeperateLastCycle;
		end
	end
	{1'b1,CmdSeperate9x4}:begin
		cmd_counter_total <= cmd_counter_total + 1'b1;
		i <= i + 1'b1;
		if (cmd_blk4x4_counter[3:2] == 0 || cmd_blk4x4_counter[3:2] == 2) begin
			if (cmd_counter_total == 8)
				cmd_state <= CmdSeperateLastCycle;
		end
		else if(cmd_counter_total == 3)begin
			cmd_state <= CmdSeperateLastCycle;
		end
	end
	{1'b1,CmdSeperate9x9}:begin
		cmd_counter_total <= cmd_counter_total + 1'b1;
		i <= i + 1'b1;
		if (cmd_blk4x4_counter[3:2] == 0 || cmd_blk4x4_counter[3:2] == 2) begin
			if (cmd_counter_total == 8)
				cmd_state <= CmdSeperateLastCycle;
		end
		else if(cmd_counter_total == 3)begin
			cmd_state <= CmdSeperateLastCycle;
		end
	end
	{1'b1,CmdSeperateChroma4x4}:begin
		cmd_counter_total <= cmd_counter_total + 1'b1;
		i <= i + 1'b1;
		if (cmd_counter_total == 3 && cmd_blk4x4_counter < 24)begin
			cmd_state <= CmdSeperateLastCycle;
		end
	end
	{1'b1,CmdSeperateChroma5x5}:begin
		cmd_counter_total <= cmd_counter_total + 1'b1;
		i <= i + 1'b1;
		if (cmd_counter_total == 4 && cmd_blk4x4_counter < 24)begin
			cmd_state <= CmdSeperateLastCycle;
		end
	end
	{1'b1,CmdSeperateLastCycle}:begin
		cmd_blk4x4_counter <= cmd_seperate_next_blk4x4_counter;
		is_cb <= cmd_seperate_next_blk4x4_counter >= 16 && cmd_seperate_next_blk4x4_counter < 20;
		is_cr <= cmd_seperate_next_blk4x4_counter >= 20 && cmd_seperate_next_blk4x4_counter < 24;
		cmd_counter_total <= 1;
		calc_addr_base_start <= 1;
		if (cmd_seperate_next_blk4x4_counter == 24) begin
			cmd_state <= CmdIdle;
			cmd_blk4x4_counter <= 0;
			ext_mem_reader_burst_ena <= 0;
		end
		else if(cmd_seperate_next_blk4x4_counter < 16 ) begin
//0000  0001  0010 0011  
//0100  0101  0110 0111
//1000  1001  1010 1011  
//1100  1101  1110 1111
 

//0000  0001  0100 0101
//0010  0011  0110 0111
//1000  1001  1100 1101
//1010  1011  1110 1111

			ref_idx <= ref_idx_l0_curr_mb[2+(blk4x4_counter_8X8_scan_order[3:2]<<1)+ blk4x4_counter_8X8_scan_order[3:2]-:3];
			mvx_l0 <= mvx_l0_curr_mb[15+(blk4x4_counter_8X8_scan_order[3:2]<<6)-:16];
			mvy_l0 <= mvy_l0_curr_mb[15+(blk4x4_counter_8X8_scan_order[3:2]<<6)-:16];
			if( mvx_l0_curr_mb[1+(blk4x4_counter_8X8_scan_order[3:2]<<6)-:2] == 0 &&
					mvy_l0_curr_mb[1+(blk4x4_counter_8X8_scan_order[3:2]<<6)-:2] == 0) begin
				cmd_state <= CmdSeperate4x4;
				i <= cmd_blk4x4_luma_i;
				j <= cmd_blk4x4_luma_j;
				k <= 8;
			end
			else if (mvy_l0_curr_mb[1+(blk4x4_counter_8X8_scan_order[3:2]<<6)-:2] == 0) begin
				cmd_state <= CmdSeperate4x9;
				i <= cmd_blk4x4_luma_i;
				j <= cmd_blk4x4_luma_j - 2;
				k <= 13;
			end
			else if (mvx_l0_curr_mb[1+(blk4x4_counter_8X8_scan_order[3:2]<<6)-:2] == 0) begin
				cmd_state <= CmdSeperate9x4;
				if (cmd_seperate_next_blk4x4_counter[3:2] == 0 || cmd_seperate_next_blk4x4_counter[3:2] == 2)
					i <= cmd_blk4x4_luma_i - 2;
				else
					i <= cmd_blk4x4_luma_i + 3;
				j <= cmd_blk4x4_luma_j;
				k <= 8;
			end
			else begin
				cmd_state <= CmdSeperate9x9;
				if (cmd_seperate_next_blk4x4_counter[3:2] == 0 || cmd_seperate_next_blk4x4_counter[3:2] == 2)
					i <= cmd_blk4x4_luma_i - 2;
				else
					i <= cmd_blk4x4_luma_i + 3;
				j <= cmd_blk4x4_luma_j - 2;
				k <= 13;
			end
		end
		else begin
			ref_idx <= ref_idx_l0_curr_mb[2+(cmd_seperate_next_blk4x4_counter[1:0]<<1)+ cmd_seperate_next_blk4x4_counter[1:0]-:3];
			mvx_l0 <= mvx_l0_curr_mb[15+((cmd_seperate_next_blk4x4_counter[1:0]<<2)<<4)-:16];
			mvy_l0 <= mvy_l0_curr_mb[15+((cmd_seperate_next_blk4x4_counter[1:0]<<2)<<4)-:16];
			if (mvx_l0_curr_mb[2+((cmd_seperate_next_blk4x4_counter[1:0]<<2)<<4)-:3] == 0 &&
					mvy_l0_curr_mb[2+((cmd_seperate_next_blk4x4_counter[1:0]<<2)<<4)-:3] == 0) begin
				cmd_state <= CmdSeperateChroma4x4;
				i <= cmd_blk4x4_chroma_i;
				j <= cmd_blk4x4_chroma_j;
				k <= 4;
			end
			else begin
				cmd_state <= CmdSeperateChroma5x5;
				i <= cmd_blk4x4_chroma_i;
				j <= cmd_blk4x4_chroma_j;
				k <= 5;
			end
		end
	end
	//{1'bx,CmdDone}: begin
	//	cmd_state <= CmdIdle;
	//end
	endcase
	if (start_of_MB_s) begin
		cmd_state <= CmdIdle;
		cmd_counter <= 0;
		cmd_counter_total <= 0;
		ref_idx <= 0;
		ext_mem_reader_burst_ena <= 1'b0;
		cmd_blk4x4_counter <= 0;
		calc_addr_base_start <= 0;
		i <= 0;
		j <= 0;
		k <= 0;
		is_cb <= 0;
		is_cr <= 0;
		mvx_l0 <= 0;
		mvy_l0 <= 0;			
	end
end

logic [4:0] desc_fifo_cmd_blk4x4_counter;
logic [4:0] ref_p_mem_wr_blk4x4_counter;
reg signed [3:0] pixels_read_count;
reg signed [5:0] pixels_j;
reg [4:0] pixels_j_start;
reg [4:0] pixels_j_end;
parameter
DescFifoIdle = 0,
DescFifoPopFirst = 1,
DescFifoWorking = 2,
DescFifoLastWord = 3;

parameter
DescFifoDataWidth = 4+5+6+5+5+1+1+5;
wire [DescFifoDataWidth-1:0] desc_fifo_rd_data;

logic [4:0] ref_p_mem_rd_blk4x4_counter;

assign desc_fifo_wr = ext_mem_reader_burst_ena_dd && ext_mem_reader_burst_ready;
//cmd_state,i,j,k,is_clip_left,is_clip_right,pixel_ref_x_clip_position
dc_fifo #(DescFifoDataWidth,6) desc_fifo_inst(
	.aclr(~rst_n | start_of_MB_s),

	.wr_clk(clk),
	.wr(desc_fifo_wr),
	.wr_data({cmd_state_dd,cmd_blk4x4_counter_dd,i_dd,j_dd,k_dd,is_clip_left,is_clip_right,pixel_ref_x_clip_position}),
	.wr_full(),
	.wr_words_avail(),

	.rd_clk(clk),
	.rd(desc_fifo_rd),
	.rd_data(desc_fifo_rd_data),
	.rd_words_avail(desc_fifo_rd_words_avail),
	.rd_empty(desc_fifo_rd_empty)
);
        
always @(posedge clk or negedge rst_n)
if (!rst_n)
     ext_mem_reader_ready <= 0;
else if (ena) begin
	//if (ref_nword_left > 1)
	    ext_mem_reader_ready <= 1; 
	//else if (ext_mem_reader_valid)
	  //  ext_mem_reader_ready <= 0;
end 

always @(posedge clk or negedge rst_n)
if (~rst_n) begin
	desc_fifo_state <= DescFifoIdle;
	pixels_read_count <= 0;
	ref_p_mem_wr_blk4x4_counter <= 0;
end
else if (ena) begin
	case(desc_fifo_state)
	DescFifoIdle: begin
		if (~desc_fifo_rd_empty) begin
			desc_fifo_state <= DescFifoPopFirst;
			pixels_read_count <= 0;
		end
	end
	DescFifoPopFirst: begin
		desc_fifo_state <= DescFifoWorking;
	end
	DescFifoWorking:begin
		ref_p_mem_wr_blk4x4_counter <= desc_fifo_cmd_blk4x4_counter;
		if (ext_mem_reader_valid) begin
			pixels_read_count <= pixels_read_count + 1'b1;
			if (ref_nword_left == 2) begin
				desc_fifo_state <= DescFifoLastWord;
			end
			if (desc_fifo_rd) begin
				pixels_read_count <= 0;
			end
		end
	end
	DescFifoLastWord:begin
		if (ext_mem_reader_valid) begin
			desc_fifo_state <= DescFifoIdle;
			ref_p_mem_wr_blk4x4_counter <= 24;
		end
	end
	endcase
	if (start_of_MB_s) begin
		ref_p_mem_wr_blk4x4_counter <= 0;
		desc_fifo_state <= DescFifoIdle;
		pixels_read_count <= 0;
		ref_p_mem_wr_blk4x4_counter <= 0;
	end
end
wire [2:0] total_pixels_read_count;
wire [2:0] total_pixels_read_count_mod8 = desc_fifo_k[2:0];
wire is_read_last_cycle;
assign is_read_last_cycle = pixels_read_count + 1 == total_pixels_read_count;
assign total_pixels_read_count = ((desc_fifo_k+7)>>3);
assign desc_fifo_rd = desc_fifo_state == DescFifoPopFirst || desc_fifo_state == DescFifoWorking && ext_mem_reader_valid && is_read_last_cycle; 

assign {desc_fifo_cmd_state, desc_fifo_cmd_blk4x4_counter, desc_fifo_i, desc_fifo_j, desc_fifo_k, desc_fifo_is_clip_left,desc_fifo_is_clip_right,desc_fifo_pixel_ref_x_clip_position} = desc_fifo_rd_data;

reg [4:0] tmp0;
reg tmp1;
always @(*) begin
	tmp0 = desc_fifo_j + 2 + (pixels_read_count<<3) + 8;
	tmp1 = tmp0 > desc_fifo_k;
	pixels_j = desc_fifo_j + (pixels_read_count<<3);
	pixels_j_start = desc_fifo_j + 2 + (pixels_read_count<<3);
	pixels_j_end = tmp1 ? desc_fifo_j + 2 + desc_fifo_k: desc_fifo_j + 2 + (pixels_read_count<<3) + 8;

end

parameter
RegFileWidth = 13,
RegFileAddrWidth = 5,
RegFileWidthTotal = 21,
RegFileHeight = 21;

logic [RegFileAddrWidth-1:0] ref_ram_wr_addr;

logic [0:RegFileWidth-1][7:0] ref_ram_col_din0;
logic [0:RegFileWidth-1][7:0] ref_ram_col_din0_normal;
logic [0:RegFileWidth-1][8*RegFileHeight-1:0] ref_ram_col_dout0;
logic [0:RegFileWidth-1] ref_ram_col_wren0;

logic [RegFileWidthTotal-RegFileWidth:RegFileWidthTotal-1][7:0] ref_ram_col_din1;
logic [RegFileWidthTotal-RegFileWidth:RegFileWidthTotal-1][7:0] ref_ram_col_din1_normal;
logic [RegFileWidthTotal-RegFileWidth:RegFileWidthTotal-1][8*RegFileHeight-1:0] ref_ram_col_dout1;
logic [RegFileWidthTotal-RegFileWidth:RegFileWidthTotal-1] ref_ram_col_wren1;

genvar ii;
generate 
for (ii=0; ii < RegFileWidth; ii = ii + 1) begin
	reg [7:0] ref_ram_col_ii_din;
	reg ref_ram_col_ii_wren;
	wire [8*RegFileHeight-1:0] ref_ram_col_ii_dout;

	reg_file_be #(RegFileHeight,RegFileAddrWidth ) ref_ram_col_ii(
		.clk(clk),
		.data(ref_ram_col_ii_din),
		.wren(ref_ram_col_ii_wren),
		.q(ref_ram_col_ii_dout),
		.wr_addr(ref_ram_wr_addr)
	);

	always @(*) begin
		ref_ram_col_ii_din = ref_ram_col_din0[ii];
		ref_ram_col_ii_wren = ref_ram_col_wren0[ii];	
		ref_ram_col_dout0[ii] = ref_ram_col_ii_dout;
	end
end
endgenerate

generate 
for (ii=RegFileWidthTotal-RegFileWidth; ii < RegFileWidthTotal; ii = ii + 1) begin
	reg [7:0] ref_ram_col_ii_din;
	reg ref_ram_col_ii_wren;
	wire [8*RegFileHeight-1:0] ref_ram_col_ii_dout;

	reg_file_be #(RegFileHeight,RegFileAddrWidth) ref_ram_col_ii(
		.clk(clk),
		.data(ref_ram_col_ii_din),
		.wren(ref_ram_col_ii_wren),
		.q(ref_ram_col_ii_dout),
		.wr_addr(ref_ram_wr_addr)
	);

	always @(*) begin
		ref_ram_col_ii_din = ref_ram_col_din1[ii];
		ref_ram_col_ii_wren = ref_ram_col_wren1[ii];	
		ref_ram_col_dout1[ii] = ref_ram_col_ii_dout;
	end
end
endgenerate

always @(*) begin
	ref_ram_wr_addr = desc_fifo_i+2;
end

reg [63:0] ext_mem_reader_data_d;
reg [63:0] ext_mem_reader_data_dd;
reg [7:0] saved_clip_data;
reg [63:0] clip_data_muxout;
reg [7:0] clip_position_data;
reg [1:0] clip_position_cycle;
reg [4:0] clip_position_start;
reg [4:0] clip_position_end;

always @(posedge clk)
if (desc_fifo_is_clip_left && ext_mem_reader_valid)begin
	if (pixels_read_count == 0)
		saved_clip_data <= ext_mem_reader_data[7:0];
	ext_mem_reader_data_d <= ext_mem_reader_data;
	ext_mem_reader_data_dd <= ext_mem_reader_data_d;
end

always @(*)
if (desc_fifo_is_clip_left) begin
	case(desc_fifo_pixel_ref_x_clip_position[4:3])
	0: begin
		case(desc_fifo_pixel_ref_x_clip_position[2:0])
		0:clip_data_muxout = ext_mem_reader_data[63:0];
		1:clip_data_muxout = {ext_mem_reader_data[55:0],ext_mem_reader_data_d[63:56]};
		2:clip_data_muxout = {ext_mem_reader_data[47:0],ext_mem_reader_data_d[63:48]};
		3:clip_data_muxout = {ext_mem_reader_data[39:0],ext_mem_reader_data_d[63:40]};
		4:clip_data_muxout = {ext_mem_reader_data[31:0],ext_mem_reader_data_d[63:32]};
		5:clip_data_muxout = {ext_mem_reader_data[23:0],ext_mem_reader_data_d[63:24]};
		6:clip_data_muxout = {ext_mem_reader_data[15:0],ext_mem_reader_data_d[63:16]};
		7:clip_data_muxout = {ext_mem_reader_data[7:0],ext_mem_reader_data_d[63:8]};
		default:clip_data_muxout = 'bx;
		endcase
	end
	1: begin
		case(desc_fifo_pixel_ref_x_clip_position[2:0])
		0:clip_data_muxout = ext_mem_reader_data_d[63:0];
		1:clip_data_muxout = {ext_mem_reader_data_d[55:0],ext_mem_reader_data_dd[63:56]};
		2:clip_data_muxout = {ext_mem_reader_data_d[47:0],ext_mem_reader_data_dd[63:48]};
		3:clip_data_muxout = {ext_mem_reader_data_d[39:0],ext_mem_reader_data_dd[63:40]};
		4:clip_data_muxout = {ext_mem_reader_data_d[31:0],ext_mem_reader_data_dd[63:32]};
		5:clip_data_muxout = {ext_mem_reader_data_d[23:0],ext_mem_reader_data_dd[63:24]};
		6:clip_data_muxout = {ext_mem_reader_data_d[15:0],ext_mem_reader_data_dd[63:16]};
		7:clip_data_muxout = {ext_mem_reader_data_d[7:0],ext_mem_reader_data_dd[63:8]};
		default:clip_data_muxout = 'bx;
		endcase
	end
	default:begin
		case(desc_fifo_pixel_ref_x_clip_position[2:0])
		0:clip_data_muxout = ext_mem_reader_data_dd[63:0];
		1:clip_data_muxout = {ext_mem_reader_data_dd[55:0],8'd0};
		2:clip_data_muxout = {ext_mem_reader_data_dd[47:0],16'd0};
		3:clip_data_muxout = {ext_mem_reader_data_dd[39:0],24'd0};
		4:clip_data_muxout = {ext_mem_reader_data_dd[31:0],32'd0};
		5:clip_data_muxout = {ext_mem_reader_data_dd[23:0],40'd0};
		6:clip_data_muxout = {ext_mem_reader_data_dd[15:0],48'd0};
		7:clip_data_muxout = {ext_mem_reader_data_dd[7:0],56'd0};
		default:clip_data_muxout = 'bx;
		endcase
	end
	endcase
end
else begin
	clip_data_muxout = ext_mem_reader_data;
end



always @(*) begin
	clip_position_data = 0;
	clip_position_cycle = 0;
	clip_position_start = 0;
	clip_position_end = 0;
	if (desc_fifo_pixel_ref_x_clip_position < 8)
		clip_position_cycle = 0;
	else if (desc_fifo_pixel_ref_x_clip_position < 16)
		clip_position_cycle = 1;
	else
		clip_position_cycle = 2;
	if (desc_fifo_is_clip_right) begin
		case (desc_fifo_pixel_ref_x_clip_position)
		0,8,16:clip_position_data = ext_mem_reader_data[7:0];
		1,9,17:clip_position_data = ext_mem_reader_data[15:8];
		2,10,18:clip_position_data = ext_mem_reader_data[23:16];
		3,11,19:clip_position_data = ext_mem_reader_data[31:24];
		4,12,20:clip_position_data = ext_mem_reader_data[39:32];
		5,13:clip_position_data = ext_mem_reader_data[47:40];
		6,14:clip_position_data = ext_mem_reader_data[55:48];
		default:clip_position_data = ext_mem_reader_data[63:56];
		endcase

		clip_position_start = desc_fifo_pixel_ref_x_clip_position + desc_fifo_j + 2;

		if (pixels_read_count == clip_position_cycle)
			clip_position_end = desc_fifo_j + 2 + desc_fifo_k;
	end
	else if (desc_fifo_is_clip_left) begin
		if (pixels_read_count == 0)
			clip_position_data = ext_mem_reader_data[7:0];
		else
			clip_position_data = saved_clip_data[7:0];

		clip_position_start = desc_fifo_j + 2;		

		if (pixels_read_count == clip_position_cycle)
			clip_position_end = desc_fifo_j + 2 + desc_fifo_pixel_ref_x_clip_position;
	end
end


integer tt;
always @(*) begin
	for(tt = 0; tt < 13; tt = tt + 1)
		ref_ram_col_wren0[tt] = ext_mem_reader_valid && tt >= pixels_j_start && tt < pixels_j_end;
	for(tt = 0; tt < 13; tt = tt + 1)
		ref_ram_col_wren0[tt] = ref_ram_col_wren0[tt] || (ext_mem_reader_valid && tt >= clip_position_start && tt < clip_position_end);
	for(tt = 0; tt < 13; tt = tt + 1)
		ref_ram_col_wren0[tt] = ref_ram_col_wren0[tt] && (~desc_fifo_is_clip_right || desc_fifo_is_clip_right && pixels_read_count <= clip_position_cycle) && (is_ref_mv_all_same || ~is_ref_mv_all_same && (desc_fifo_cmd_blk4x4_counter[1] == 0 || desc_fifo_cmd_blk4x4_counter[4]));

	for(tt = 8; tt < 21; tt = tt + 1)
		ref_ram_col_wren1[tt] = ext_mem_reader_valid && tt >= pixels_j_start && tt < pixels_j_end;
	for(tt = 8; tt < 21; tt = tt + 1)
		ref_ram_col_wren1[tt] = ref_ram_col_wren1[tt] || (ext_mem_reader_valid && tt >= clip_position_start && tt < clip_position_end);
	for(tt = 8; tt < 21; tt = tt + 1)
		ref_ram_col_wren1[tt] = ref_ram_col_wren1[tt] && (~desc_fifo_is_clip_right || desc_fifo_is_clip_right && pixels_read_count <= clip_position_cycle) && (is_ref_mv_all_same || ~is_ref_mv_all_same && (desc_fifo_cmd_blk4x4_counter[1] == 1 || desc_fifo_cmd_blk4x4_counter[4]));
	
end

always @(*) begin
	ref_ram_col_din0_normal[0]  = clip_data_muxout[7:0];
	ref_ram_col_din0_normal[1]  = clip_data_muxout[15:8];
	ref_ram_col_din0_normal[2]  = pixels_j == -2 ? clip_data_muxout[23:16] : clip_data_muxout[7:0] ;
	ref_ram_col_din0_normal[3]  = pixels_j == -2 ? clip_data_muxout[31:24] : clip_data_muxout[15:8];
	ref_ram_col_din0_normal[4]  = pixels_j == -2 ? clip_data_muxout[39:32] : clip_data_muxout[23:16];
	ref_ram_col_din0_normal[5]  = pixels_j == -2 ? clip_data_muxout[47:40] : clip_data_muxout[31:24];
	ref_ram_col_din0_normal[6]  = pixels_j == -2 ? clip_data_muxout[55:48] : clip_data_muxout[39:32];
	ref_ram_col_din0_normal[7]  = pixels_j == -2 ? clip_data_muxout[63:56] : clip_data_muxout[47:40];

	ref_ram_col_din0_normal[8]  = pixels_j ==  6 ? clip_data_muxout[07:00] : clip_data_muxout[55:48];
	ref_ram_col_din0_normal[9]  = pixels_j ==  6 ? clip_data_muxout[15:08] : clip_data_muxout[63:56];
	ref_ram_col_din0_normal[10] = pixels_j ==  6 ? clip_data_muxout[23:16] : clip_data_muxout[7:0] ;
	ref_ram_col_din0_normal[11] = pixels_j ==  6 ? clip_data_muxout[31:24] : clip_data_muxout[15:8];
	ref_ram_col_din0_normal[12] = pixels_j ==  6 ? clip_data_muxout[39:32] : clip_data_muxout[23:16];
	
	ref_ram_col_din1_normal[8]  = pixels_j ==  6 ? clip_data_muxout[07:00] : clip_data_muxout[55:48];
	ref_ram_col_din1_normal[9]  = pixels_j ==  6 ? clip_data_muxout[15:08] : clip_data_muxout[63:56];
	ref_ram_col_din1_normal[10] = pixels_j ==  6 ? clip_data_muxout[23:16] : clip_data_muxout[7:0] ;
	ref_ram_col_din1_normal[11] = pixels_j ==  6 ? clip_data_muxout[31:24] : clip_data_muxout[15:8];
	ref_ram_col_din1_normal[12] = pixels_j ==  6 ? clip_data_muxout[39:32] : clip_data_muxout[23:16];
	
	ref_ram_col_din1_normal[13] = pixels_j ==  6 ? clip_data_muxout[47:40] : clip_data_muxout[31:24];
	ref_ram_col_din1_normal[14] = pixels_j ==  6 ? clip_data_muxout[55:48] : clip_data_muxout[39:32];
	ref_ram_col_din1_normal[15] = pixels_j ==  6 ? clip_data_muxout[63:56] : clip_data_muxout[47:40];
	ref_ram_col_din1_normal[16] = pixels_j == 14 ? clip_data_muxout[07:00] : clip_data_muxout[55:48];
	ref_ram_col_din1_normal[17] = pixels_j == 14 ? clip_data_muxout[15:08] : clip_data_muxout[63:56];
	ref_ram_col_din1_normal[18] = pixels_j == 14 ? clip_data_muxout[23:16] : clip_data_muxout[7:0] ;
	ref_ram_col_din1_normal[19] = pixels_j == 14 ? clip_data_muxout[31:24] : clip_data_muxout[15:8];
	ref_ram_col_din1_normal[20] = pixels_j == 14 ? clip_data_muxout[39:32] : clip_data_muxout[23:16] ;
end


always @(*) begin
	for (tt = 0; tt < 13; tt = tt + 1)
		ref_ram_col_din0[tt]  = tt >= clip_position_start && tt < clip_position_end ? clip_position_data : ref_ram_col_din0_normal[tt];
	for (tt = 8; tt < 21; tt = tt + 1)
		ref_ram_col_din1[tt]  = tt >= clip_position_start && tt < clip_position_end ? clip_position_data : ref_ram_col_din1_normal[tt];
end

logic [4:0] ref_pixels_mem_blk4x4_counter;
logic ref_pixels_mem_wr;

always @(*)
if (ref_pixels_mem_blk4x4_counter < ref_p_mem_wr_blk4x4_counter)
	ref_pixels_mem_wr <= 1'b1;
else
	ref_pixels_mem_wr <= 1'b0;

always @(posedge clk or negedge rst_n)
if (~rst_n)
	ref_pixels_mem_blk4x4_counter <= 0;
else if (ena && start && blk4x4_counter == 0)
	ref_pixels_mem_blk4x4_counter <= 0;
else if (ena && ref_pixels_mem_wr)
	ref_pixels_mem_blk4x4_counter <= ref_pixels_mem_blk4x4_counter + 1'b1;

logic [0:20][8*RegFileHeight-1:0] ref_ram_col_dout_mux_out;
assign ref_ram_col_dout_mux_out[0:7] = ref_ram_col_dout0[0:7];
assign ref_ram_col_dout_mux_out[8:12] = (~is_ref_mv_all_same && ref_pixels_mem_blk4x4_counter[1] == 1) ?
									ref_ram_col_dout1[8:12] : ref_ram_col_dout0[8:12];
assign ref_ram_col_dout_mux_out[13:20] = ref_ram_col_dout1[13:20];

parameter
RefPMemDataWidth = 72,
RefPMemAddrWidth = 5;

reg [RefPMemDataWidth-1:0] wr_data_0;
reg [RefPMemDataWidth-1:0] wr_data_1;
reg [RefPMemDataWidth-1:0] wr_data_2;
reg [RefPMemDataWidth-1:0] wr_data_3;
reg [RefPMemDataWidth-1:0] wr_data_4;
reg [RefPMemDataWidth-1:0] wr_data_5;
reg [RefPMemDataWidth-1:0] wr_data_6;
reg [RefPMemDataWidth-1:0] wr_data_7;
reg [RefPMemDataWidth-1:0] wr_data_8;

always @(*) begin
	wr_data_0 = 72'd0;
	wr_data_1 = 72'd0;
	wr_data_2 = 72'd0;
	wr_data_3 = 72'd0;
	wr_data_4 = 72'd0;
	wr_data_5 = 72'd0;
	wr_data_6 = 72'd0;
	wr_data_7 = 72'd0;
	wr_data_8 = 72'd0;
	case(ref_pixels_mem_blk4x4_counter)
	0: begin
		tt = 0;
		wr_data_0 = {ref_ram_col_dout_mux_out[0+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_1 = {ref_ram_col_dout_mux_out[1+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_2 = {ref_ram_col_dout_mux_out[2+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_3 = {ref_ram_col_dout_mux_out[3+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_4 = {ref_ram_col_dout_mux_out[4+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_5 = {ref_ram_col_dout_mux_out[5+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_6 = {ref_ram_col_dout_mux_out[6+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_7 = {ref_ram_col_dout_mux_out[7+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_8 = {ref_ram_col_dout_mux_out[8+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
	end
	1: begin
		tt = 1;
		wr_data_0 = {ref_ram_col_dout_mux_out[0+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_1 = {ref_ram_col_dout_mux_out[1+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_2 = {ref_ram_col_dout_mux_out[2+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_3 = {ref_ram_col_dout_mux_out[3+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_4 = {ref_ram_col_dout_mux_out[4+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_5 = {ref_ram_col_dout_mux_out[5+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_6 = {ref_ram_col_dout_mux_out[6+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_7 = {ref_ram_col_dout_mux_out[7+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_8 = {ref_ram_col_dout_mux_out[8+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
	end
	2: begin
		tt = 2;
		wr_data_0 = {ref_ram_col_dout_mux_out[0+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_1 = {ref_ram_col_dout_mux_out[1+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_2 = {ref_ram_col_dout_mux_out[2+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_3 = {ref_ram_col_dout_mux_out[3+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_4 = {ref_ram_col_dout_mux_out[4+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_5 = {ref_ram_col_dout_mux_out[5+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_6 = {ref_ram_col_dout_mux_out[6+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_7 = {ref_ram_col_dout_mux_out[7+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_8 = {ref_ram_col_dout_mux_out[8+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
	end
	3: begin
		tt = 3;
		wr_data_0 = {ref_ram_col_dout_mux_out[0+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_1 = {ref_ram_col_dout_mux_out[1+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_2 = {ref_ram_col_dout_mux_out[2+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_3 = {ref_ram_col_dout_mux_out[3+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_4 = {ref_ram_col_dout_mux_out[4+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_5 = {ref_ram_col_dout_mux_out[5+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_6 = {ref_ram_col_dout_mux_out[6+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_7 = {ref_ram_col_dout_mux_out[7+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_8 = {ref_ram_col_dout_mux_out[8+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
	end
	4: begin
		tt = 4;
		wr_data_0 = {ref_ram_col_dout_mux_out[0+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_1 = {ref_ram_col_dout_mux_out[1+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_2 = {ref_ram_col_dout_mux_out[2+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_3 = {ref_ram_col_dout_mux_out[3+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_4 = {ref_ram_col_dout_mux_out[4+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_5 = {ref_ram_col_dout_mux_out[5+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_6 = {ref_ram_col_dout_mux_out[6+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_7 = {ref_ram_col_dout_mux_out[7+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_8 = {ref_ram_col_dout_mux_out[8+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
	end
	5: begin
		tt = 5;
		wr_data_0 = {ref_ram_col_dout_mux_out[0+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_1 = {ref_ram_col_dout_mux_out[1+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_2 = {ref_ram_col_dout_mux_out[2+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_3 = {ref_ram_col_dout_mux_out[3+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_4 = {ref_ram_col_dout_mux_out[4+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_5 = {ref_ram_col_dout_mux_out[5+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_6 = {ref_ram_col_dout_mux_out[6+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_7 = {ref_ram_col_dout_mux_out[7+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_8 = {ref_ram_col_dout_mux_out[8+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
	end
	6: begin
		tt = 6;
		wr_data_0 = {ref_ram_col_dout_mux_out[0+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_1 = {ref_ram_col_dout_mux_out[1+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_2 = {ref_ram_col_dout_mux_out[2+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_3 = {ref_ram_col_dout_mux_out[3+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_4 = {ref_ram_col_dout_mux_out[4+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_5 = {ref_ram_col_dout_mux_out[5+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_6 = {ref_ram_col_dout_mux_out[6+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_7 = {ref_ram_col_dout_mux_out[7+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_8 = {ref_ram_col_dout_mux_out[8+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
	end
	7: begin
		tt = 7;
		wr_data_0 = {ref_ram_col_dout_mux_out[0+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_1 = {ref_ram_col_dout_mux_out[1+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_2 = {ref_ram_col_dout_mux_out[2+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_3 = {ref_ram_col_dout_mux_out[3+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_4 = {ref_ram_col_dout_mux_out[4+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_5 = {ref_ram_col_dout_mux_out[5+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_6 = {ref_ram_col_dout_mux_out[6+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_7 = {ref_ram_col_dout_mux_out[7+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_8 = {ref_ram_col_dout_mux_out[8+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
	end
	8: begin
		tt = 8;
		wr_data_0 = {ref_ram_col_dout_mux_out[0+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_1 = {ref_ram_col_dout_mux_out[1+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_2 = {ref_ram_col_dout_mux_out[2+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_3 = {ref_ram_col_dout_mux_out[3+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_4 = {ref_ram_col_dout_mux_out[4+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_5 = {ref_ram_col_dout_mux_out[5+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_6 = {ref_ram_col_dout_mux_out[6+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_7 = {ref_ram_col_dout_mux_out[7+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_8 = {ref_ram_col_dout_mux_out[8+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
	end
	9: begin
		tt = 9;
		wr_data_0 = {ref_ram_col_dout_mux_out[0+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_1 = {ref_ram_col_dout_mux_out[1+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_2 = {ref_ram_col_dout_mux_out[2+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_3 = {ref_ram_col_dout_mux_out[3+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_4 = {ref_ram_col_dout_mux_out[4+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_5 = {ref_ram_col_dout_mux_out[5+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_6 = {ref_ram_col_dout_mux_out[6+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_7 = {ref_ram_col_dout_mux_out[7+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_8 = {ref_ram_col_dout_mux_out[8+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
	end
	10: begin
		tt = 10;
		wr_data_0 = {ref_ram_col_dout_mux_out[0+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_1 = {ref_ram_col_dout_mux_out[1+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_2 = {ref_ram_col_dout_mux_out[2+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_3 = {ref_ram_col_dout_mux_out[3+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_4 = {ref_ram_col_dout_mux_out[4+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_5 = {ref_ram_col_dout_mux_out[5+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_6 = {ref_ram_col_dout_mux_out[6+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_7 = {ref_ram_col_dout_mux_out[7+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_8 = {ref_ram_col_dout_mux_out[8+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
	end
	11: begin
		tt = 11;
		wr_data_0 = {ref_ram_col_dout_mux_out[0+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_1 = {ref_ram_col_dout_mux_out[1+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_2 = {ref_ram_col_dout_mux_out[2+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_3 = {ref_ram_col_dout_mux_out[3+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_4 = {ref_ram_col_dout_mux_out[4+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_5 = {ref_ram_col_dout_mux_out[5+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_6 = {ref_ram_col_dout_mux_out[6+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_7 = {ref_ram_col_dout_mux_out[7+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_8 = {ref_ram_col_dout_mux_out[8+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
	end
	12: begin
		tt = 12;
		wr_data_0 = {ref_ram_col_dout_mux_out[0+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_1 = {ref_ram_col_dout_mux_out[1+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_2 = {ref_ram_col_dout_mux_out[2+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_3 = {ref_ram_col_dout_mux_out[3+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_4 = {ref_ram_col_dout_mux_out[4+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_5 = {ref_ram_col_dout_mux_out[5+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_6 = {ref_ram_col_dout_mux_out[6+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_7 = {ref_ram_col_dout_mux_out[7+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_8 = {ref_ram_col_dout_mux_out[8+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
	end
	13: begin
		tt = 13;
		wr_data_0 = {ref_ram_col_dout_mux_out[0+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_1 = {ref_ram_col_dout_mux_out[1+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_2 = {ref_ram_col_dout_mux_out[2+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_3 = {ref_ram_col_dout_mux_out[3+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_4 = {ref_ram_col_dout_mux_out[4+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_5 = {ref_ram_col_dout_mux_out[5+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_6 = {ref_ram_col_dout_mux_out[6+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_7 = {ref_ram_col_dout_mux_out[7+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_8 = {ref_ram_col_dout_mux_out[8+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
	end
	14: begin
		tt = 14;
		wr_data_0 = {ref_ram_col_dout_mux_out[0+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_1 = {ref_ram_col_dout_mux_out[1+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_2 = {ref_ram_col_dout_mux_out[2+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_3 = {ref_ram_col_dout_mux_out[3+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_4 = {ref_ram_col_dout_mux_out[4+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_5 = {ref_ram_col_dout_mux_out[5+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_6 = {ref_ram_col_dout_mux_out[6+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_7 = {ref_ram_col_dout_mux_out[7+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_8 = {ref_ram_col_dout_mux_out[8+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
	end
	15: begin
		tt = 15;
		wr_data_0 = {ref_ram_col_dout_mux_out[0+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_1 = {ref_ram_col_dout_mux_out[1+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_2 = {ref_ram_col_dout_mux_out[2+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_3 = {ref_ram_col_dout_mux_out[3+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_4 = {ref_ram_col_dout_mux_out[4+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_5 = {ref_ram_col_dout_mux_out[5+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_6 = {ref_ram_col_dout_mux_out[6+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_7 = {ref_ram_col_dout_mux_out[7+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
		wr_data_8 = {ref_ram_col_dout_mux_out[8+tt[1:0]*4][71+tt[3:2]*4*8-:72]};
	end
	16,20:begin
		if (is_ref_mv_all_same)begin
			wr_data_2 = {ref_ram_col_dout_mux_out[2+0*4][71+0*4*8-:72]};
			wr_data_3 = {ref_ram_col_dout_mux_out[3+0*4][71+0*4*8-:72]};
			wr_data_4 = {ref_ram_col_dout_mux_out[4+0*4][71+0*4*8-:72]};
			wr_data_5 = {ref_ram_col_dout_mux_out[5+0*4][71+0*4*8-:72]};
			wr_data_6 = {ref_ram_col_dout_mux_out[6+0*4][71+0*4*8-:72]};
		end
		else begin
			wr_data_2 = {ref_ram_col_dout_mux_out[2+0*4][71+0*4*8-:72]};
			wr_data_3 = {ref_ram_col_dout_mux_out[3+0*4][71+0*4*8-:72]};
			wr_data_4 = {ref_ram_col_dout_mux_out[4+0*4][71+0*4*8-:72]};
			wr_data_5 = {ref_ram_col_dout_mux_out[5+0*4][71+0*4*8-:72]};
			wr_data_6 = {ref_ram_col_dout_mux_out[6+0*4][71+0*4*8-:72]};
		end
	end
	17,21:begin
		if (is_ref_mv_all_same)begin
			wr_data_2 = {ref_ram_col_dout_mux_out[2+1*4][71+0*4*8-:72]};
			wr_data_3 = {ref_ram_col_dout_mux_out[3+1*4][71+0*4*8-:72]};
			wr_data_4 = {ref_ram_col_dout_mux_out[4+1*4][71+0*4*8-:72]};
			wr_data_5 = {ref_ram_col_dout_mux_out[5+1*4][71+0*4*8-:72]};
			wr_data_6 = {ref_ram_col_dout_mux_out[6+1*4][71+0*4*8-:72]};
		end
		else begin
			wr_data_2 = {ref_ram_col_dout_mux_out[2+2*4][71+0*4*8-:72]};
			wr_data_3 = {ref_ram_col_dout_mux_out[3+2*4][71+0*4*8-:72]};
			wr_data_4 = {ref_ram_col_dout_mux_out[4+2*4][71+0*4*8-:72]};
			wr_data_5 = {ref_ram_col_dout_mux_out[5+2*4][71+0*4*8-:72]};
			wr_data_6 = {ref_ram_col_dout_mux_out[6+2*4][71+0*4*8-:72]};
		end
	end
	18,22:begin
		if (is_ref_mv_all_same)begin
			wr_data_2 = {ref_ram_col_dout_mux_out[2+0*4][71+1*4*8-:72]};
			wr_data_3 = {ref_ram_col_dout_mux_out[3+0*4][71+1*4*8-:72]};
			wr_data_4 = {ref_ram_col_dout_mux_out[4+0*4][71+1*4*8-:72]};
			wr_data_5 = {ref_ram_col_dout_mux_out[5+0*4][71+1*4*8-:72]};
			wr_data_6 = {ref_ram_col_dout_mux_out[6+0*4][71+1*4*8-:72]};
		end
		else begin
			wr_data_2 = {ref_ram_col_dout_mux_out[2+0*4][71+2*4*8-:72]};
			wr_data_3 = {ref_ram_col_dout_mux_out[3+0*4][71+2*4*8-:72]};
			wr_data_4 = {ref_ram_col_dout_mux_out[4+0*4][71+2*4*8-:72]};
			wr_data_5 = {ref_ram_col_dout_mux_out[5+0*4][71+2*4*8-:72]};
			wr_data_6 = {ref_ram_col_dout_mux_out[6+0*4][71+2*4*8-:72]};
		end
	end
	19,23:begin
		if (is_ref_mv_all_same)begin
			wr_data_2 = {ref_ram_col_dout_mux_out[2+1*4][71+1*4*8-:72]};
			wr_data_3 = {ref_ram_col_dout_mux_out[3+1*4][71+1*4*8-:72]};
			wr_data_4 = {ref_ram_col_dout_mux_out[4+1*4][71+1*4*8-:72]};
			wr_data_5 = {ref_ram_col_dout_mux_out[5+1*4][71+1*4*8-:72]};
			wr_data_6 = {ref_ram_col_dout_mux_out[6+1*4][71+1*4*8-:72]};
		end
		else begin
			wr_data_2 = {ref_ram_col_dout_mux_out[2+2*4][71+2*4*8-:72]};
			wr_data_3 = {ref_ram_col_dout_mux_out[3+2*4][71+2*4*8-:72]};
			wr_data_4 = {ref_ram_col_dout_mux_out[4+2*4][71+2*4*8-:72]};
			wr_data_5 = {ref_ram_col_dout_mux_out[5+2*4][71+2*4*8-:72]};
			wr_data_6 = {ref_ram_col_dout_mux_out[6+2*4][71+2*4*8-:72]};
		end
	end
	endcase
	
end
/*
	17: begin
		wr_data_0 = {ref_ram_col_dout0[0+ii[1:0]*4][71+ii[3:2]*4*8-:72]};
		wr_data_1 = {ref_ram_col_dout0[1+ii[1:0]*4][71+ii[3:2]*4*8-:72]};
		wr_data_2 = {ref_ram_col_dout0[2+ii[1:0]*4][71+ii[3:2]*4*8-:72]};
		wr_data_3 = {ref_ram_col_dout0[3+ii[1:0]*4][71+ii[3:2]*4*8-:72]};
		wr_data_4 = {ref_ram_col_dout0[4+ii[1:0]*4][71+ii[3:2]*4*8-:72]};
		wr_data_5 = {ref_ram_col_dout0[5+ii[1:0]*4][71+ii[3:2]*4*8-:72]};
		wr_data_6 = {ref_ram_col_dout0[6+ii[1:0]*4][71+ii[3:2]*4*8-:72]};
		wr_data_7 = {ref_ram_col_dout0[7+ii[1:0]*4][71+ii[3:2]*4*8-:72]};
		wr_data_8 = {ref_ram_col_dout0[8+ii[1:0]*4][71+ii[3:2]*4*8-:72]};
	end
	if (ref_pixels_mem_blk4x4_counter[2:0] == 0)
		wr_data_0 = {ref_ram_col_dout0[0+0*4][71+0*4*8-:72]};
	else if (ref_pixels_mem_blk4x4_counter[2:0] == 1)
		wr_data_0 = {ref_ram_col_dout0[0+1*4][71+0*4*8-:72]};
	else if (ref_pixels_mem_blk4x4_counter[2:0] == 2)
		wr_data_0 = {ref_ram_col_dout0[0+2*4][71+0*4*8-:72]};
	else if (ref_pixels_mem_blk4x4_counter[2:0] == 3)
		wr_data_0 = {ref_ram_col_dout0[0+3*4][71+0*4*8-:72]};
	else if (ref_pixels_mem_blk4x4_counter[2:0] == 4)
		wr_data_0 = {ref_ram_col_dout0[0+0*4][71+1*4*8-:72]};
	else if (ref_pixels_mem_blk4x4_counter[2:0] == 5)
		wr_data_0 = {ref_ram_col_dout0[0+1*4][71+1*4*8-:72]};
	else if (ref_pixels_mem_blk4x4_counter[2:0] == 6)
		wr_data_0 = {ref_ram_col_dout0[0+2*4][71+1*4*8-:72]};
	else// if (ref_pixels_mem_blk4x4_counter[2:0] == 7)
		wr_data_0 = {ref_ram_col_dout0[0+3*4][71+1*4*8-:72]};
end

always @(*) begin
	if (ref_pixels_mem_blk4x4_counter[2:0] == 0)
		wr_data_0 = {ref_ram_col_dout0[1+0*4][71+0*4*8-:72]};
	else if (ref_pixels_mem_blk4x4_counter[2:0] == 1)
		wr_data_0 = {ref_ram_col_dout0[1+1*4][71+0*4*8-:72]};
	else if (ref_pixels_mem_blk4x4_counter[2:0] == 2)
		wr_data_0 = {ref_ram_col_dout0[1+2*4][71+0*4*8-:72]};
	else if (ref_pixels_mem_blk4x4_counter[2:0] == 3)
		wr_data_0 = {ref_ram_col_dout0[1+3*4][71+0*4*8-:72]};
	else if (ref_pixels_mem_blk4x4_counter[2:0] == 4)
		wr_data_0 = {ref_ram_col_dout0[1+0*4][71+1*4*8-:72]};
	else if (ref_pixels_mem_blk4x4_counter[2:0] == 5)
		wr_data_0 = {ref_ram_col_dout0[1+1*4][71+1*4*8-:72]};
	else if (ref_pixels_mem_blk4x4_counter[2:0] == 6)
		wr_data_0 = {ref_ram_col_dout0[1+2*4][71+1*4*8-:72]};
	else// if (ref_pixels_mem_blk4x4_counter[2:0] == 7)
		wr_data_0 = {ref_ram_col_dout0[1+3*4][71+1*4*8-:72]};
end
*/
dc_fifo #(RefPMemDataWidth,RefPMemAddrWidth) ref_pixels_mem_inst0(
	.aclr(start_of_MB_s),

	.wr_clk(clk),
	.wr(ref_pixels_mem_wr),
	.wr_data(wr_data_0),
	.wr_words_avail(),
	.wr_full(),

	.rd_clk(ref_p_mem_clk),
	.rd(ref_p_mem_rd),
	.rd_data(ref_p_mem_data_0),
	.rd_words_avail(),
	.rd_empty()
);

dc_fifo #(RefPMemDataWidth,RefPMemAddrWidth) ref_pixels_mem_inst1(
	.aclr(start_of_MB_s),

	.wr_clk(clk),
	.wr(ref_pixels_mem_wr),
	.wr_data(wr_data_1),
	.wr_words_avail(),
	.wr_full(),

	.rd_clk(ref_p_mem_clk),
	.rd(ref_p_mem_rd),
	.rd_data(ref_p_mem_data_1),
	.rd_words_avail(),
	.rd_empty()
);

dc_fifo #(RefPMemDataWidth,RefPMemAddrWidth) ref_pixels_mem_inst2(
	.aclr(start_of_MB_s),

	.wr_clk(clk),
	.wr(ref_pixels_mem_wr),
	.wr_data(wr_data_2),
	.wr_words_avail(),
	.wr_full(),

	.rd_clk(ref_p_mem_clk),
	.rd(ref_p_mem_rd),
	.rd_data(ref_p_mem_data_2),
	.rd_words_avail(),
	.rd_empty()
);

dc_fifo #(RefPMemDataWidth,RefPMemAddrWidth) ref_pixels_mem_inst3(
	.aclr(start_of_MB_s),

	.wr_clk(clk),
	.wr(ref_pixels_mem_wr),
	.wr_data(wr_data_3),
	.wr_words_avail(),
	.wr_full(),

	.rd_clk(ref_p_mem_clk),
	.rd(ref_p_mem_rd),
	.rd_data(ref_p_mem_data_3),
	.rd_words_avail(),
	.rd_empty()
);

dc_fifo #(RefPMemDataWidth,RefPMemAddrWidth) ref_pixels_mem_inst4(
	.aclr(start_of_MB_s),

	.wr_clk(clk),
	.wr(ref_pixels_mem_wr),
	.wr_data(wr_data_4),
	.wr_words_avail(),
	.wr_full(),

	.rd_clk(ref_p_mem_clk),
	.rd(ref_p_mem_rd),
	.rd_data(ref_p_mem_data_4),
	.rd_words_avail(),
	.rd_empty()
);

dc_fifo #(RefPMemDataWidth,RefPMemAddrWidth) ref_pixels_mem_inst5(
	.aclr(start_of_MB_s),

	.wr_clk(clk),
	.wr(ref_pixels_mem_wr),
	.wr_data(wr_data_5),
	.wr_words_avail(),
	.wr_full(),

	.rd_clk(ref_p_mem_clk),
	.rd(ref_p_mem_rd),
	.rd_data(ref_p_mem_data_5),
	.rd_words_avail(),
	.rd_empty()
);

dc_fifo #(RefPMemDataWidth,RefPMemAddrWidth) ref_pixels_mem_inst6(
	.aclr(start_of_MB_s),

	.wr_clk(clk),
	.wr(ref_pixels_mem_wr),
	.wr_data(wr_data_6),
	.wr_words_avail(),
	.wr_full(),

	.rd_clk(ref_p_mem_clk),
	.rd(ref_p_mem_rd),
	.rd_data(ref_p_mem_data_6),
	.rd_words_avail(),
	.rd_empty()
);

dc_fifo #(RefPMemDataWidth,RefPMemAddrWidth) ref_pixels_mem_inst7(
	.aclr(start_of_MB_s),

	.wr_clk(clk),
	.wr(ref_pixels_mem_wr),
	.wr_data(wr_data_7),
	.wr_words_avail(),
	.wr_full(),

	.rd_clk(ref_p_mem_clk),
	.rd(ref_p_mem_rd),
	.rd_data(ref_p_mem_data_7),
	.rd_words_avail(),
	.rd_empty()
);

dc_fifo #(RefPMemDataWidth,RefPMemAddrWidth) ref_pixels_mem_inst8(
	.aclr(start_of_MB_s),

	.wr_clk(clk),
	.wr(ref_pixels_mem_wr),
	.wr_data(wr_data_8),
	.wr_words_avail(),
	.wr_full(),

	.rd_clk(ref_p_mem_clk),
	.rd(ref_p_mem_rd),
	.rd_data(ref_p_mem_data_8),
	.rd_words_avail(),
	.rd_empty(ref_p_mem_empty)
);
assign ref_p_mem_avail = ~ref_p_mem_empty;

endmodule   