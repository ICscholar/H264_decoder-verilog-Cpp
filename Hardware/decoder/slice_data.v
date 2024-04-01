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

module slice_data(
	input clk,
	input rst_n,
	input ena, 
	input[23:0] rbsp_in, // from rbsp_buffer output 
	input is_last_bit_of_rbsp,
	input[2:0] slice_type_mod5_in,
	input[`mb_x_bits + `mb_y_bits - 1:0] first_mb_in_slice,
	input[`mb_x_bits - 1:0] pic_width_in_mbs_minus1_sps_in,
	input[`mb_y_bits - 1:0] pic_height_in_map_units_minus1_sps_in,
	input[`mb_x_bits :0] pic_width_in_mbs,
	input[`mb_y_bits :0] pic_height_in_map_units,
	input[2:0] num_ref_idx_l0_active_minus1_in,
	input[3:0] CBP_luma_in,
	input[1:0] CBP_chroma_in,
	input signed [5:0] pic_init_qp_minus26_pps_in,
	input signed [5:0] slice_qp_delta_slice_header_in,
	
	input[11:0] exp_golomb_decoding_output_in,
	input[4:0] exp_golomb_decoding_len_in,
	input signed [15:0] exp_golomb_decoding_output_se_in,
	input[7:0] exp_golomb_decoding_output_te_in,
	output reg exp_golomb_decoding_me_intra4x4_out, //1=intra4x4, 0=intr
	output reg exp_golomb_decoding_te_sel_out,
	
	
	input signed [4:0] chroma_qp_index_offset_pps_in,
	input signed [3:0] slice_alpha_c0_offset_div2,
	input signed [2:0] disable_deblocking_filter_idc,

	output reg fpga_ram_intra4x4_pred_mode_wr_n,
	output reg [`mb_x_bits-1:0] fpga_ram_intra4x4_pred_mode_addr,     
	output reg [15:0] fpga_ram_intra4x4_pred_mode_data_in,
	input [15:0]  fpga_ram_intra4x4_pred_mode_data_out,
	
	output reg fpga_ram_mvx_wr_n,
	output reg [`mb_x_bits-1:0] fpga_ram_mvx_addr,     
	output reg [63:0]  fpga_ram_mvx_data_in,
	input [63:0]  fpga_ram_mvx_data_out,  
	 
	output reg fpga_ram_mvy_wr_n,
	output reg [`mb_x_bits-1:0] fpga_ram_mvy_addr,     
	output reg [63:0]  fpga_ram_mvy_data_in,
	input  [63:0]  fpga_ram_mvy_data_out,  
	 
	output reg fpga_ram_ref_idx_wr_n,
	output reg [`mb_x_bits-1:0] fpga_ram_ref_idx_addr,
	output reg [7:0] fpga_ram_ref_idx_data_in,
	input  [7:0] fpga_ram_ref_idx_data_out,
	
	output reg fpga_ram_qp_wr_n,
	output reg [`mb_x_bits-1:0] fpga_ram_qp_addr,
	output reg [7:0] fpga_ram_qp_data_in,
	input  [7:0] fpga_ram_qp_data_out,
	
	output reg fpga_ram_qp_c_wr_n,
	output reg [`mb_x_bits-1:0] fpga_ram_qp_c_addr,
	output reg [7:0] fpga_ram_qp_c_data_in,
	input  [7:0] fpga_ram_qp_c_data_out, 
	
	output reg fpga_ram_nnz_wr_n,
	output reg [`mb_x_bits-1:0] fpga_ram_nnz_addr,     
	output reg [31:0] fpga_ram_nnz_data_in,
	input  [31:0] fpga_ram_nnz_data_out,
	
	output reg fpga_ram_nnz_cb_wr_n,
	output reg [`mb_x_bits-1:0] fpga_ram_nnz_cb_addr,     
	output reg [15:0] fpga_ram_nnz_cb_data_in,
	input  [15:0] fpga_ram_nnz_cb_data_out,
	
	output reg fpga_ram_nnz_cr_wr_n,
	output reg [`mb_x_bits-1:0] fpga_ram_nnz_cr_addr,     
	output reg [15:0] fpga_ram_nnz_cr_data_in,
	input  [15:0] fpga_ram_nnz_cr_data_out,
	
	output reg signed[7:0] qp,
	output reg signed[7:0] qp_c,
	output reg [4:0] slice_data_state,
	output reg [3:0] residual_state,
	output reg [`mb_x_bits + `mb_y_bits - 1:0] mb_index_out,
	output reg [4:0] forward_len_out,
	
	output reg[`mb_x_bits - 1:0]  mb_x_out, 
	output reg[`mb_y_bits - 1:0]  mb_y_out,
	output reg[4:0] blk4x4_counter_sum, 
	output reg[4:0] blk4x4_counter_residual, 
	output reg[3:0] luma4x4BlkIdx,
	
	//get_mvp
	output reg mv_calc_ready,
	input mv_calc_valid,
	input signed [15:0] mvpx_l0_in,
	input signed [15:0] mvpy_l0_in,

	output reg[5 :0] ref_idx_l0_left_mb_out,
	output reg[11:0] ref_idx_l0_curr_mb_out,
	output reg[5 :0] ref_idx_l0_up_left_mb_out,
	output reg[5 :0] ref_idx_l0_up_mb_out,
	output reg[5 :0] ref_idx_l0_up_right_mb_out,
	
	output reg[63 :0] mvx_l0_left_mb_out,
	output reg[63 :0] mvy_l0_left_mb_out,
	output reg[15 :0] mvx_l0_up_left_mb_out,
	output reg[15 :0] mvy_l0_up_left_mb_out,
	output reg[63 :0] mvx_l0_up_mb_out,  // input from m9k, actually no, the input is fpga_ram_mvx_l0_in, output to get_mvp
	output reg[63 :0] mvy_l0_up_mb_out,
	output reg[63 :0] mvx_l0_up_right_mb_out,
	output reg[63 :0] mvy_l0_up_right_mb_out,
	output reg[255:0] mvx_l0_curr_mb_out, // 8x16=128
	output reg[255:0] mvy_l0_curr_mb_out,
	output is_mv_all_same,
	output reg[4:0] MbPartWidth,
	output reg[4:0] MbPartHeight,
	output reg[2:0] ref_idx_l0_out,
	
	output reg signed  [5:0]   nC, // input from nC_decoding, output to cavlc,  
	                                // fix nC_decoding and cavlc only allowed to put inside slice_data?
	                                // otherwise the signal nC will be inout, or nC use reg to store the output 
	                                // of nC_decoding, then output to cavlc    
	                                // put all code of nC_decoding inside slice_data
	                                // or declare nC_in, nC_out, assgin nC_out = Nc_in
	output reg start_of_MB,
	output reg end_of_MB,
	output reg end_of_frame,

	//residual
	output reg residual_start,
	input  residual_valid,
	output reg [4:0] max_coeff_num,
	input  [4:0]   TotalCoeff, 
	input  [4:0]   len_comb,
	input  cavlc_idle,
	
	//intra_pred
	output reg intra_pred_start,
	output reg [3:0] mb_pred_mode_out,
	output reg [1:0] I16_pred_mode_out,
	output reg [3:0] I4_pred_mode_out,
	output reg [1:0] intra_pred_mode_chroma,
	output reg [7:0] is_mb_intra,
	
	//inter_pred
	output reg inter_pred_start,
	output reg mv_l0_calc_done,

	//sum
	output reg sum_start,
	input   sum_valid,
	output reg mb_pred_inter_sel,
	output reg is_residual_not_dc,
	input bitstream_forwarded_rbsp,
	
	//deblock
	output reg deblock_start,
	input prev_mb_deblocking_done,
	output reg [3*16-1:0] bs_vertical,
	output reg [3*16-1:0] bs_horizontal,
	output reg [5:0] df_qp0,
	output reg [5:0] df_qp1,
	output reg [5:0] df_qp2,
	output reg [5:0] df_qp3,
	output reg [5:0] df_qp4,
	output reg [5:0] df_qp5,
//debug
	output reg [24:0] counter_stick_at_decode_a
);
 

//inter_pred

reg     residual_started;
reg     [2:0]   step;

reg[3:0] CBP_luma_reg;
reg[1:0] CBP_chroma_reg;

reg signed[7:0] qp_i;

reg[3:0] mb_pred_state;
reg[2:0] sub_mb_pred_state;
reg[1:0] p_skip_state;
reg p_skip_sel;

reg signed[7:0] qp_up;
reg signed[7:0] qp_c_up;
reg signed[7:0] qp_left_mb;
reg signed[7:0] qp_c_left_mb;



reg[4:0]  mb_type;
reg[15:0]  sub_mb_type;
reg[`mb_x_bits + `mb_y_bits - 1:0]  slice_mb_index;

reg[1:0] chroma4x4BlkIdx;


reg signed[15:0] mvdx_l0;
reg signed[15:0] mvdy_l0;

reg signed[15 :0] mvx_l0;
reg signed[15 :0] mvy_l0;

reg[(1<<`mb_x_bits) - 1:0] intra_mode;
reg intra_mode_left_mb;
reg intra_mode_up_mb;

reg[`mb_x_bits+`mb_y_bits-1:0] mb_skip_run;
reg      P_skip_mode;
reg signed [15:0] exp_golomb_decoding_output_se_in_reg;

reg[1:0] prefetch_counter;

reg[1:0] mbPartIdx; // 8x8,16x8,8x16 index in 16x16 block
reg[1:0] MbPartNum; // 4x4,8x4,4x8 index in 8x8 block
reg[1:0] subMbPartIdx; // sub mb index 4x4,8x4,4x8, used in inter pred
reg[2:0] SubMbPartNum;
// slice_check
reg[3:0] is_in_same_slice;
reg intra_mode_up_left_mb;
always @(posedge clk or negedge rst_n)
if(~rst_n)begin
	is_in_same_slice <= 0;
end 
else if (slice_data_state == `rst_macroblock_s) begin//0:up left 1:up 2:up right 3:left
	is_in_same_slice[0] <= slice_mb_index > pic_width_in_mbs &&  mb_y_out > 0 && mb_x_out > 0;
	is_in_same_slice[1] <= slice_mb_index >= pic_width_in_mbs && mb_y_out > 0;
	is_in_same_slice[2] <= (slice_mb_index >= pic_width_in_mbs - 1) && mb_y_out > 0 && (mb_x_out < pic_width_in_mbs-1);
	is_in_same_slice[3] <= slice_mb_index > 0 && mb_x_out > 0;
end

always @(posedge clk or negedge rst_n)//0 not avail 1 intra 2 inter
if(~rst_n)begin
	is_mb_intra[7:0] <= 0;
end 
else if (slice_data_state == `mb_pred && mb_pred_state == `rst_mb_pred ) begin//0:1 up left 2:3 up 4:5 up right 6:left
	is_mb_intra[1:0] <= is_in_same_slice[0] ? (intra_mode_up_left_mb ? 1 : 2) : 0;
	is_mb_intra[3:2] <= is_in_same_slice[1] ? (intra_mode[mb_x_out] ? 1 : 2) : 0;
	is_mb_intra[5:4] <= is_in_same_slice[2] ? (intra_mode[mb_x_out+1] ? 1 : 2) : 0;
	is_mb_intra[7:6] <= is_in_same_slice[3] ? (intra_mode[mb_x_out-1] ? 1 : 2) : 0;
end

//intra pred mode decode
reg prev_intra4x4_pred_mode_flag_out;
reg[2:0] rem_intra4x4_pred_mode_out;
reg[15:0] intra4x4_pred_mode_up_mb_out;
reg[15:0] intra4x4_pred_mode_left_mb_out;
reg[63:0] intra4x4_pred_mode_curr_mb_out;
wire[3:0] I4_pred_mode_in;

intra4x4_pred_mode_decoding I4_pred_dut
(
 .mb_x_in(mb_x_out),
 .mb_y_in(mb_y_out),
 .luma4x4BlkIdx_in(luma4x4BlkIdx),
 .slice_mb_index(slice_mb_index),
 .pic_width_in_mbs(pic_width_in_mbs),
 .prev_intra4x4_pred_mode_in(prev_intra4x4_pred_mode_flag_out),
 .rem_intra4x4_pred_mode_in(rem_intra4x4_pred_mode_out),
 .intra4x4_pred_mode_left_mb_in(intra4x4_pred_mode_left_mb_out),
 .intra4x4_pred_mode_up_mb_in(intra4x4_pred_mode_up_mb_out),
 .intra4x4_pred_mode_curr_mb_in(intra4x4_pred_mode_curr_mb_out),
 .I4_pred_mode_out(I4_pred_mode_in)
);

//nC decode
reg[127:0] nC_curr_mb_out; //nC_curr_mb is not neccessary to be declared as signed, only nC_curr_mb[7:0] is handled as signed
reg[31:0] nC_left_mb_out;
reg[31:0] nC_up_mb_out;
reg[31:0] nC_cb_curr_mb_out;
reg[15:0] nC_cb_left_mb_out;
reg[15:0] nC_cb_up_mb_out;
reg[31:0] nC_cr_curr_mb_out;
reg[15:0] nC_cr_left_mb_out;
reg[15:0] nC_cr_up_mb_out;
wire[4:0] nC_in;
wire[4:0] nC_cb_in;
wire[4:0] nC_cr_in;


nC_decoding nC_decoding
(
 .mb_x_in(mb_x_out),
 .mb_y_in(mb_y_out),
 .is_in_same_slice(is_in_same_slice),
 .luma4x4BlkIdx_in(blk4x4_counter_residual[3:0]),
 .chroma4x4BlkIdx_in(blk4x4_counter_residual[1:0]),
 .nC_up_mb_in(nC_up_mb_out),
 .nC_left_mb_in(nC_left_mb_out),
 .nC_curr_mb_in(nC_curr_mb_out),
 .nC_cb_up_mb_in(nC_cb_up_mb_out),
 .nC_cb_left_mb_in(nC_cb_left_mb_out),
 .nC_cb_curr_mb_in(nC_cb_curr_mb_out),
 .nC_cr_up_mb_in(nC_cr_up_mb_out),
 .nC_cr_left_mb_in(nC_cr_left_mb_out),
 .nC_cr_curr_mb_in(nC_cr_curr_mb_out), 
 .nC_out(nC_in),
 .nC_cb_out(nC_cb_in),
 .nC_cr_out(nC_cr_in)
);

always @(*)
	if (bitstream_forwarded_rbsp)
		forward_len_out <= 0;
	else
        case (slice_data_state)
            `rst_slice_data_s    : forward_len_out <= 0;
			`rst_macroblock_s    : forward_len_out <= 0;
            `mb_skip_run_s       : forward_len_out <= exp_golomb_decoding_len_in;
            `mb_type_s           : forward_len_out <= exp_golomb_decoding_len_in;
            `mb_pred:
                case(mb_pred_state)
                    `rst_mb_pred                    : forward_len_out <= 0;
                    `prev_intra4x4_pred_mode_flag_s : forward_len_out <= 1;
                    `ref_idx_l0_s                   : forward_len_out <= exp_golomb_decoding_len_in;
                    `rem_intra4x4_pred_mode_s       : forward_len_out <= 3;
                    `intra_pred_mode_chroma_s       : forward_len_out <= exp_golomb_decoding_len_in;
                    `mvdx_l0_s                      : forward_len_out <= exp_golomb_decoding_len_in;
                    `mvdy_l0_s                      : forward_len_out <= exp_golomb_decoding_len_in;
                    default : forward_len_out <= 0;
                endcase
            `coded_block_pattern_s: forward_len_out <= exp_golomb_decoding_len_in;
            `mb_qp_delta_s        : forward_len_out <= exp_golomb_decoding_len_in;
            `sub_mb_pred:
                case(sub_mb_pred_state)
                    `rst_sub_mb_pred  : forward_len_out <= 0;
                    `sub_mb_type_s    : forward_len_out <= exp_golomb_decoding_len_in;
                    `sub_ref_idx_l0_s : forward_len_out <= exp_golomb_decoding_len_in;
                    `sub_mvdx_l0_s    : forward_len_out <= exp_golomb_decoding_len_in;
                    `sub_mvdy_l0_s    : forward_len_out <= exp_golomb_decoding_len_in;
                    default : forward_len_out <= 0;
                endcase
            `residual:
                if (!cavlc_idle)
                    forward_len_out <= len_comb;
                else
                    forward_len_out <= 0;
            `rbsp_trailing_bits_slice_data: forward_len_out <= 5'b11111;
            default : forward_len_out <= 0;
		endcase
                                       

reg [3:0] mb_pred_mode;
always @(*)
	mb_pred_mode_out <= mb_pred_mode;

always @(posedge clk or negedge rst_n)           
if (~rst_n)
	mb_pred_inter_sel <= 0;
else if (|mb_pred_mode[3:1] || p_skip_sel) //only consider I4MB I16MB PRED_L0 P_REF0 P_SKIP
    mb_pred_inter_sel <= 1;
else
	mb_pred_inter_sel <= 0;


always @(posedge clk)
    case(luma4x4BlkIdx)
        0 : I4_pred_mode_out <= intra4x4_pred_mode_curr_mb_out[3 : 0]; 
        1 : I4_pred_mode_out <= intra4x4_pred_mode_curr_mb_out[7 : 4]; 
        2 : I4_pred_mode_out <= intra4x4_pred_mode_curr_mb_out[11: 8]; 
        3 : I4_pred_mode_out <= intra4x4_pred_mode_curr_mb_out[15:12]; 
        4 : I4_pred_mode_out <= intra4x4_pred_mode_curr_mb_out[19:16]; 
        5 : I4_pred_mode_out <= intra4x4_pred_mode_curr_mb_out[23:20]; 
        6 : I4_pred_mode_out <= intra4x4_pred_mode_curr_mb_out[27:24]; 
        7 : I4_pred_mode_out <= intra4x4_pred_mode_curr_mb_out[31:28]; 
        8 : I4_pred_mode_out <= intra4x4_pred_mode_curr_mb_out[35:32]; 
        9 : I4_pred_mode_out <= intra4x4_pred_mode_curr_mb_out[39:36]; 
        10: I4_pred_mode_out <= intra4x4_pred_mode_curr_mb_out[43:40]; 
        11: I4_pred_mode_out <= intra4x4_pred_mode_curr_mb_out[47:44]; 
        12: I4_pred_mode_out <= intra4x4_pred_mode_curr_mb_out[51:48]; 
        13: I4_pred_mode_out <= intra4x4_pred_mode_curr_mb_out[55:52]; 
        14: I4_pred_mode_out <= intra4x4_pred_mode_curr_mb_out[59:56]; 
        15: I4_pred_mode_out <= intra4x4_pred_mode_curr_mb_out[63:60]; 
    endcase

always @ (posedge clk)
    begin
        if (qp + chroma_qp_index_offset_pps_in < 0)
            qp_i <= 0;
        else if (qp + chroma_qp_index_offset_pps_in > 51)
            qp_i <= 51;
        else
            qp_i <= qp + chroma_qp_index_offset_pps_in;
    end

always @ (posedge clk)
    begin
        if(qp_i < 30)
            qp_c <= qp_i;
        else 
            case(qp_i)
                30      :qp_c <= 29;
                31      :qp_c <= 30;
                32      :qp_c <= 31;
                33,34   :qp_c <= 32;
                35      :qp_c <= 33;
                36,37   :qp_c <= 34;
                38,39   :qp_c <= 35;
                40,41   :qp_c <= 36;
                42,43,44:qp_c <= 37;
                45,46,47:qp_c <= 38;
                default :qp_c <= 39;
            endcase
    end

    
always @(posedge clk or negedge rst_n)
if (!rst_n)
    start_of_MB <= 0;
else if (slice_data_state == `rst_macroblock_s && ena)
    start_of_MB <= 1;
else if (ena)
    start_of_MB <= 0;   

always @(posedge clk or negedge rst_n)
if (!rst_n)
    end_of_MB <= 0;
else if (blk4x4_counter_sum == 23 && sum_valid)
    end_of_MB <= 1;
else
    end_of_MB <= 0; 

//blk4x4_counter_sum
always @(posedge clk or negedge rst_n)
if (!rst_n)begin
    blk4x4_counter_sum <= 0;
end
else begin
	if(start_of_MB)begin
        blk4x4_counter_sum <= 0;
	end	
	else if (slice_data_state == `residual || slice_data_state == `p_skip_s)begin
		if (sum_valid)
			blk4x4_counter_sum <= blk4x4_counter_sum + 1;
	end
end

reg [20:0] counter_stick_at_decode;
/* force to next frame when decode is stuck
always @(posedge clk or negedge rst_n)
if (!rst_n)begin
    counter_stick_at_decode <= 0;
end
else if (ena) begin
	if(slice_data_state == `rst_slice_data_s )
		counter_stick_at_decode <= 0;
	else if (counter_stick_at_decode < 'h1000000)
		counter_stick_at_decode <= counter_stick_at_decode + 1'b1;
	else
		counter_stick_at_decode <= 0;
end
*/
//reg [24:0] counter_stick_at_decode_a;
//
always @(posedge clk or negedge rst_n)
if (!rst_n)begin
    counter_stick_at_decode <= 0;
end
else if (ena) begin
	if(slice_data_state == `residual || slice_data_state == `p_skip_s) begin
		if (sum_valid)
			counter_stick_at_decode <= 0;		
		else
			counter_stick_at_decode <= counter_stick_at_decode + 1'b1;
	end
end

always @(posedge clk or negedge rst_n)
if (!rst_n)begin
    counter_stick_at_decode_a <= 0;
end
else if (ena) begin
	if(slice_data_state == `residual || slice_data_state == `p_skip_s) begin
		if (sum_valid)
			counter_stick_at_decode_a <= 0;		
		else
			counter_stick_at_decode_a <= counter_stick_at_decode_a + 1'b1;
	end
end


always @(*)
case (residual_state)
`ChromaACLevel_Cb_s,    
`ChromaACLevel_Cb_0_s: blk4x4_counter_residual <= 16 + chroma4x4BlkIdx;
`ChromaACLevel_Cr_s, 
`ChromaACLevel_Cr_0_s: blk4x4_counter_residual <= 20 + chroma4x4BlkIdx;
default:blk4x4_counter_residual <= luma4x4BlkIdx;
endcase

always @(posedge clk or negedge rst_n)
	if (!rst_n)begin
        residual_started <= 0;
		exp_golomb_decoding_output_se_in_reg <= 0;
	end
    else if (ena)begin
		exp_golomb_decoding_output_se_in_reg <= exp_golomb_decoding_output_se_in;
		if (residual_start)
			residual_started <= 1;
		else if (residual_valid)
			residual_started <= 0;
	end

assign prev_mb_deblocking_done_or_mb0 = mb_index_out == 0 || prev_mb_deblocking_done;
always @ (posedge clk or negedge rst_n)
    if (rst_n == 0)
        begin
			mb_pred_mode                        <= 0;
			I16_pred_mode_out                   <= 0;
            prev_intra4x4_pred_mode_flag_out    <= 0;
            rem_intra4x4_pred_mode_out          <= 0;
            intra_pred_mode_chroma              <= 0;
            slice_data_state                    <= 0;
            mb_pred_state                       <= 0;
            sub_mb_pred_state                   <= 0;
            residual_state                      <= 0;
            mb_index_out                        <= 0;
            slice_mb_index                  	<= 0;
            mbPartIdx                           <= 0;
            mb_x_out                            <= 0;
            mb_y_out                            <= 0;
            luma4x4BlkIdx                   	<= 0;
            chroma4x4BlkIdx                 	<= 0;
            step                                <= 0;
            residual_start                      <= 0;
            intra_pred_start                    <= 0;
            inter_pred_start                    <= 0;
			mv_calc_ready                       <= 0;
			mvx_l0                              <= 0;
			mvy_l0                              <= 0;
            max_coeff_num                       <= 0;
            mb_skip_run                         <= 0;   
            P_skip_mode                         <= 0;
            exp_golomb_decoding_me_intra4x4_out <= 0;
            exp_golomb_decoding_te_sel_out      <= 0;
            intra_mode                          <= 0;
            intra4x4_pred_mode_curr_mb_out      <= 0;
			intra_mode_up_left_mb               <= 0;
			p_skip_sel                          <= 0;
            MbPartWidth                         <= 0;
            MbPartHeight                        <= 0;
			intra_mode_left_mb                  <= 0;
			intra_mode_up_mb                    <= 0;
			sub_mb_type                         <= 0;
            qp_c_up                             <= 0;
            qp_c_left_mb                        <= 0;
            fpga_ram_ref_idx_data_in            <= 0;
            subMbPartIdx                        <= 0;
            ref_idx_l0_up_right_mb_out          <= 0;
            ref_idx_l0_up_mb_out                <= 0;
            ref_idx_l0_up_left_mb_out           <= 0; 
            ref_idx_l0_out                      <= 0;
            ref_idx_l0_left_mb_out              <= 0;
            ref_idx_l0_curr_mb_out              <= 0; 
            qp_up                               <= 0;
            qp_left_mb                          <= 0;
            qp                                  <= 0;
            prefetch_counter                    <= 0;
            nC_up_mb_out                        <= 0;
            nC_left_mb_out                      <= 0;
            nC_cr_up_mb_out                     <= 0;
            nC_cr_left_mb_out                   <= 0;
            nC_cb_up_mb_out                     <= 0;
            nC_cb_left_mb_out                   <= 0;
            nC                                  <= 0;
            mvy_l0_up_right_mb_out              <= 0;
            mvy_l0_up_mb_out                    <= 0;
            mvy_l0_up_left_mb_out               <= 0;
            mvy_l0_left_mb_out                  <= 0;
            mvx_l0_up_right_mb_out              <= 0;
            mvx_l0_up_mb_out                    <= 0;
            mvx_l0_up_left_mb_out               <= 0;
            mvx_l0_left_mb_out                  <= 0;
            mvdy_l0                             <= 0;
            mvdx_l0                             <= 0;
            mb_type                             <= 0;
            intra4x4_pred_mode_up_mb_out        <= 0;
            intra4x4_pred_mode_left_mb_out      <= 0;
            fpga_ram_ref_idx_wr_n               <= 0;
            fpga_ram_ref_idx_addr               <= 0;
            fpga_ram_qp_wr_n                    <= 0;
            fpga_ram_qp_data_in                 <= 0;
            fpga_ram_qp_c_wr_n                  <= 0;
            fpga_ram_qp_c_data_in               <= 0;
            fpga_ram_qp_c_addr                  <= 0;
            fpga_ram_qp_addr                    <= 0;
            fpga_ram_nnz_wr_n                   <= 0;
            fpga_ram_nnz_data_in                <= 0;
            fpga_ram_nnz_cr_wr_n                <= 0;
            fpga_ram_nnz_cr_data_in             <= 0;
            fpga_ram_nnz_cr_addr                <= 0;
            fpga_ram_nnz_cb_wr_n                <= 0;
            fpga_ram_nnz_cb_data_in             <= 0;
            fpga_ram_nnz_cb_addr                <= 0;
            fpga_ram_nnz_addr                   <= 0;
            fpga_ram_mvy_wr_n                   <= 0;
            fpga_ram_mvy_data_in                <= 0;
            fpga_ram_mvy_addr                   <= 0;
            fpga_ram_mvx_wr_n                   <= 0;
            fpga_ram_mvx_data_in                <= 0; 
            fpga_ram_mvx_addr                   <= 0;
            fpga_ram_intra4x4_pred_mode_wr_n    <= 0;
            fpga_ram_intra4x4_pred_mode_data_in <= 0;
            fpga_ram_intra4x4_pred_mode_addr    <= 0;
            SubMbPartNum                        <= 0;
            MbPartNum                           <= 0;
            CBP_luma_reg                        <= 0;
            CBP_chroma_reg                      <= 0;
			end_of_frame                        <= 0;
		end
    else 
        begin	
			if (ena)begin
                case (slice_data_state)
					`rst_slice_data_s: begin
                        qp <= pic_init_qp_minus26_pps_in + 26 + slice_qp_delta_slice_header_in;
						slice_data_state <= `rst_macroblock_s;
						slice_mb_index <= 0;
						mb_index_out <= first_mb_in_slice;
                        P_skip_mode <= 0;
						mb_skip_run <= 0;
						end_of_frame <= 0;
						if (first_mb_in_slice == 0) begin
							mb_x_out <= 0;
							mb_y_out <= 0;
						end
						if (mb_index_out != first_mb_in_slice && first_mb_in_slice != 0 )begin
							slice_data_state <= `sd_forward_to_next_frame;
							//synopsys translate_off
							$display("state to sd_forward_to_next_frame,mb_index_out=%d,first_mb_in_slice=%d",mb_index_out, first_mb_in_slice);
							//$stop();
							//synopsys translate_on
						end
					end
                    `rst_macroblock_s: 
                        begin
	                        intra4x4_pred_mode_curr_mb_out   <=  64'h2222222222222222;
							step <= 0;                    
							if (mb_x_out == 0)begin
								intra_mode_left_mb <= 1'b1;
								intra_mode_up_mb <= intra_mode[0];
							end
							if (mb_y_out == 0)
								intra_mode_up_mb <= 1'b1;
                            if (mb_x_out != 0)
                                begin
                                    ref_idx_l0_left_mb_out <= {ref_idx_l0_curr_mb_out[11:9], ref_idx_l0_curr_mb_out[5:3]};
                                    mvx_l0_left_mb_out <= {mvx_l0_curr_mb_out[255:240],
                                                           mvx_l0_curr_mb_out[223:208],
                                                           mvx_l0_curr_mb_out[127:112], 
                                                           mvx_l0_curr_mb_out[95:80]
                                                           };
                                    mvy_l0_left_mb_out <= {mvy_l0_curr_mb_out[255:240],
                                                           mvy_l0_curr_mb_out[223:208],
                                                           mvy_l0_curr_mb_out[127:112], 
                                                           mvy_l0_curr_mb_out[95:80]
                                                            };
                                    intra4x4_pred_mode_left_mb_out <= {intra4x4_pred_mode_curr_mb_out[63:60],
                                                                       intra4x4_pred_mode_curr_mb_out[55:52],
                                                                       intra4x4_pred_mode_curr_mb_out[31:28],
                                                                       intra4x4_pred_mode_curr_mb_out[23:20] // 5,7,13,15
                                                                       };
                                    qp_left_mb <= qp;
                                    qp_c_left_mb <= qp_c;
                                    nC_left_mb_out <= {nC_curr_mb_out[127:120], nC_curr_mb_out[111:104],
                                                           nC_curr_mb_out[63:56],nC_curr_mb_out[47:40] };
                                    nC_cb_left_mb_out <= {nC_cb_curr_mb_out[31:24], nC_cb_curr_mb_out[15:8]};
                                    nC_cr_left_mb_out <= {nC_cr_curr_mb_out[31:24], nC_cr_curr_mb_out[15:8]};
                                end
                                
                            if (mb_y_out != 0)
                                begin
                                    slice_data_state <= `prefetch_from_fpga_ram;
                                    prefetch_counter <= 0;
                                    
                                    fpga_ram_intra4x4_pred_mode_wr_n <= 1;  
                                    fpga_ram_intra4x4_pred_mode_addr <= mb_x_out;
                                    fpga_ram_qp_wr_n      <= 1;
                                    fpga_ram_qp_c_wr_n    <= 1;
                                    fpga_ram_nnz_wr_n     <= 1;
                                    fpga_ram_nnz_cb_wr_n   <= 1;
                                    fpga_ram_nnz_cr_wr_n   <= 1;
                                    fpga_ram_qp_addr      <= mb_x_out; 
                                    fpga_ram_qp_c_addr    <= mb_x_out; 
                                    fpga_ram_nnz_addr     <= mb_x_out;
                                    fpga_ram_nnz_cb_addr   <= mb_x_out;
                                    fpga_ram_nnz_cr_addr   <= mb_x_out;
                                    
                                    fpga_ram_ref_idx_wr_n <= 1;
                                    fpga_ram_mvx_wr_n     <= 1;
                                    fpga_ram_mvy_wr_n     <= 1;
                                    // mb is in first column, retrieve ref_idx_l0_up_mb and ref_idx_l0_up_right_mb, otherwise retrieve ref_idx_l0_up_right_mb       
                                    if ( mb_x_out == 0 )
                                        begin
                                            fpga_ram_ref_idx_addr <= mb_x_out;
                                            fpga_ram_mvx_addr <= mb_x_out; 
                                            fpga_ram_mvy_addr <= mb_x_out;
                                        end
                                    else
                                        begin
                                            fpga_ram_ref_idx_addr <= mb_x_out + 1;
                                            fpga_ram_mvx_addr <= mb_x_out + 1; 
                                            fpga_ram_mvy_addr <= mb_x_out + 1;
                                        end
                                end
                            else if ( mb_skip_run != 0 ) 
                                slice_data_state <= `skip_run_duration;
                                 
                            else if(slice_type_mod5_in != `slice_type_I &&
                                    slice_type_mod5_in != `slice_type_SI && 
                                    !P_skip_mode)
                                begin                                                
                                    slice_data_state <= `mb_skip_run_s;
                                end    
                            else
                                begin                                                
                                    slice_data_state <= `mb_type_s;
                                end 
                        end

                    `prefetch_from_fpga_ram: 
                        if ( prefetch_counter == 0)
                        // fix: since it's not async read, it takes 2 clocks to read one data from fpga ram
                            begin
                                prefetch_counter <= 1;
                            end
                        else if (prefetch_counter == 1)
                            begin
                                intra4x4_pred_mode_up_mb_out <= fpga_ram_intra4x4_pred_mode_data_out;
                                qp_up <= fpga_ram_qp_data_out;
                                qp_c_up <= fpga_ram_qp_c_data_out;
                                nC_up_mb_out <= fpga_ram_nnz_data_out;
                                nC_cb_up_mb_out <= fpga_ram_nnz_cb_data_out;
                                nC_cr_up_mb_out <= fpga_ram_nnz_cr_data_out;

                                if (mb_x_out == 0)
                                    begin
                                        ref_idx_l0_up_mb_out[5:0] <= fpga_ram_ref_idx_data_out[5:0];
                                        mvx_l0_up_mb_out <= fpga_ram_mvx_data_out;
                                        mvy_l0_up_mb_out <= fpga_ram_mvy_data_out;
                                        prefetch_counter <= 2;
                                        fpga_ram_ref_idx_wr_n <= 1;
                                        fpga_ram_mvx_wr_n <= 1;
                                        fpga_ram_mvy_wr_n <= 1;
                                        fpga_ram_ref_idx_addr <= mb_x_out + 1 ;
                                        fpga_ram_mvx_addr <= mb_x_out + 1;
                                        fpga_ram_mvy_addr <= mb_x_out + 1;
                                    end
                                else
                                    begin

                                        mvx_l0_up_right_mb_out <= fpga_ram_mvx_data_out;
                                        mvy_l0_up_right_mb_out <= fpga_ram_mvy_data_out;

                                        ref_idx_l0_up_left_mb_out <= ref_idx_l0_up_mb_out;
                                        
                                        ref_idx_l0_up_mb_out <= ref_idx_l0_up_right_mb_out;
                                        ref_idx_l0_up_right_mb_out[5:0] <= fpga_ram_ref_idx_data_out[5:0];
                                                                                
                                        mvx_l0_up_left_mb_out <= mvx_l0_up_mb_out[63:48];
                                        mvx_l0_up_mb_out <= mvx_l0_up_right_mb_out;
                                        
                                        mvy_l0_up_left_mb_out <= mvy_l0_up_mb_out[63:48];
                                        mvy_l0_up_mb_out <= mvy_l0_up_right_mb_out;
                                        if ( mb_skip_run != 0 )
                                            slice_data_state <= `skip_run_duration; 
                                        else if(slice_type_mod5_in != `slice_type_I &&
                                         slice_type_mod5_in != `slice_type_SI && !P_skip_mode)
                                            begin                                                
                                                slice_data_state <= `mb_skip_run_s;
                                            end    
                                        else
                                            begin                                                
                                                slice_data_state <= `mb_type_s;
                                            end
                                    end
                            end
                        else if (prefetch_counter == 2)
                            begin
                                prefetch_counter <= 3;
                            end
                        else //prefetch_counter = 3
                            begin
                                ref_idx_l0_up_right_mb_out[5:0] <= fpga_ram_ref_idx_data_out[5:0];
                                mvx_l0_up_right_mb_out <= fpga_ram_mvx_data_out;
                                mvy_l0_up_right_mb_out <= fpga_ram_mvy_data_out;
                                
                                // not necessary?
                                intra4x4_pred_mode_left_mb_out <= 0;
                                ref_idx_l0_left_mb_out <= 0;
                                ref_idx_l0_up_left_mb_out <= 0;
                                
                                mvx_l0_left_mb_out <= 0;
                                mvx_l0_up_left_mb_out <= 0;
                                
                                mvy_l0_left_mb_out <= 0;
                                mvy_l0_up_left_mb_out <= 0;   
                                
                                if ( mb_skip_run != 0 )
                                    slice_data_state <= `skip_run_duration; 
                                else if(slice_type_mod5_in != `slice_type_I &&
                                 slice_type_mod5_in != `slice_type_SI && !P_skip_mode)
                                    begin                                                
                                        slice_data_state <= `mb_skip_run_s;
                                    end    
                                else
                                    begin                                                
                                        slice_data_state <= `mb_type_s;
                                    end                            
                            end
                            
                    `mb_skip_run_s:
                        begin
                            if (exp_golomb_decoding_output_in > 0)
                                begin
								//	if ( slice_type_mod5_in == `slice_type_P)
									mb_pred_mode <= `mb_pred_mode_P_SKIP;
                                    slice_data_state <= `skip_run_duration;
                                    MbPartWidth <= 16;
                                    MbPartHeight <= 16;
                                    luma4x4BlkIdx <= 0;
                                    mb_skip_run <= exp_golomb_decoding_output_in;
                                    ref_idx_l0_curr_mb_out <= 0;
                                    ref_idx_l0_out <= 0;                                    
                                end
                            else
                                begin
                                    slice_data_state <= `mb_type_s;
                                end
                        end
                    `skip_run_duration:
                        begin
							
                            P_skip_mode <= 1;
                            // P_skip 's mv, 
							if ( slice_mb_index < pic_width_in_mbs)
								begin
                                    mvx_l0 <= 0;
                                    mvy_l0 <= 0;
									slice_data_state <= `skip_run_save_mv;
								end
                            else if (ref_idx_l0_left_mb_out[2:0] == 0 &&
                                     mvx_l0_left_mb_out[15:0] == 0 &&
                                     mvy_l0_left_mb_out[15:0] == 0)
                                begin
                                    mvx_l0 <= 0;
                                    mvy_l0 <= 0;
									slice_data_state <= `skip_run_save_mv;
								end
                            else if (ref_idx_l0_up_mb_out[2:0] == 0 &&
                                     mvx_l0_up_mb_out[15:0] == 0 &&
                                     mvy_l0_up_mb_out[15:0] == 0)
                                begin
                                    mvx_l0 <= 0;
                                    mvy_l0 <= 0;
									slice_data_state <= `skip_run_save_mv;
                                end
                            else 
                                begin
									if (step < 3)
										step <= step + 1'b1;
									if (step == 0)
										mv_calc_ready <= 1'b1;
									else if (step == 3 && mv_calc_valid) begin
										slice_data_state <= `skip_run_save_mv;
										step <= 0;
										mv_calc_ready <= 0;
										mvx_l0 <= mvpx_l0_in;
										mvy_l0 <= mvpy_l0_in;
									end
                                end
                        end 
					`skip_run_save_mv:begin
						slice_data_state <= `p_skip_s;
						p_skip_state <= `rst_p_skip_s;
						p_skip_sel <= 1'b1;
					end
                    `mb_type_s:
                        begin
                        	mb_type <= exp_golomb_decoding_output_in;	
							slice_data_state <= `mb_pred;
                            mb_pred_state <= `rst_mb_pred;
							if ( slice_type_mod5_in == `slice_type_I )begin
								if (exp_golomb_decoding_output_in == 0)
									mb_pred_mode <= `mb_pred_mode_I4MB;
								else if (exp_golomb_decoding_output_in == 25 )
									mb_pred_mode <= `mb_pred_mode_IPCM;
								else
									mb_pred_mode <= `mb_pred_mode_I16MB;
							end	
							else if (slice_type_mod5_in == `slice_type_P)begin
								case ( exp_golomb_decoding_output_in )
								0,1,2,3:    mb_pred_mode <= `mb_pred_mode_PRED_L0;
								4:          mb_pred_mode <= `mb_pred_mode_P_REF0;
								5:          mb_pred_mode <= `mb_pred_mode_I4MB;
								default:    mb_pred_mode <= `mb_pred_mode_I16MB;
								endcase	
							end
							else begin
								mb_pred_mode <= 4'b1111;
							end
							if (slice_type_mod5_in == `slice_type_P &&
								exp_golomb_decoding_output_in > 5)
								I16_pred_mode_out <= (exp_golomb_decoding_output_in-6)%4;
							else
								I16_pred_mode_out <= (exp_golomb_decoding_output_in-1)%4;
						end
                    `mb_pred:
                        case(mb_pred_state)
                            `rst_mb_pred:begin
                                if(mb_pred_mode == `mb_pred_mode_I4MB)
                                    begin
                                        mb_pred_state <= `prev_intra4x4_pred_mode_flag_s;
                                        luma4x4BlkIdx <= 0;
                                        ref_idx_l0_curr_mb_out <= -1;
                                    end
                                else if(mb_pred_mode == `mb_pred_mode_I16MB &&
                                         slice_type_mod5_in != `slice_type_I &&
                                         slice_type_mod5_in != `slice_type_SI)
                                    begin
                                        CBP_luma_reg <= (mb_type >= 18 ? 15 : 0);
                                        //CBP_chroma_reg <= ((mb_type - 1) % 12) >> 2; divisor must be a positive constant power of 2
                                        if (mb_type >= 18)
                                            CBP_chroma_reg <= (mb_type - 18) >> 2;
                                        else
                                            CBP_chroma_reg <= (mb_type - 6) >> 2;
                                        mb_pred_state <= `intra_pred_mode_chroma_s;
                                        luma4x4BlkIdx <= 0; 
                                        ref_idx_l0_curr_mb_out <= -1;                                       
                                    end
                                else if (mb_pred_mode == `mb_pred_mode_I16MB)
                                    begin
                                        CBP_luma_reg <= (mb_type >= 13 ? 15 : 0);
                                        //CBP_chroma_reg <= ((mb_type - 1) % 12) >> 2; divisor must be a positive constant power of 2
                                        if (mb_type >= 13)
                                            CBP_chroma_reg <= (mb_type - 13) >> 2;
                                        else
                                            CBP_chroma_reg <= (mb_type - 1) >> 2;
                                        mb_pred_state <= `intra_pred_mode_chroma_s;
                                        luma4x4BlkIdx <= 0;
                                        ref_idx_l0_curr_mb_out <= -1;                                    
                                    end
                                else if (mb_pred_mode == `mb_pred_mode_PRED_L0 || 
                                         mb_pred_mode == `mb_pred_mode_P_REF0)
                                    begin
                                        luma4x4BlkIdx <= 0; 
                                        mbPartIdx <= 0;
                                        subMbPartIdx <= 0;
                                        if ( mb_type == 3 || mb_type == 4 ) // P_8x8, P_8x8ref0
                                            begin
                                                MbPartNum <= 4;
                                            end
                                        else if (mb_type == 1) // 16x8
                                            begin
                                                MbPartNum <= 2;
                                                MbPartWidth <= 16;
                                                MbPartHeight <= 8;
                                            end
                                        else if( mb_type == 2 ) // 8x16
                                            begin
                                                MbPartNum <= 2;
                                                MbPartWidth <= 8;
                                                MbPartHeight <= 16;
                                            end
                                        else
                                            begin
                                                MbPartNum <= 1;
                                                MbPartWidth <= 16;
                                                MbPartHeight <= 16;
                                            end
                                            
                                        if ( mb_type == 3 || mb_type == 4 ) // P_8x8, P_8x8ref0
                                            begin
                                                slice_data_state    <= `sub_mb_pred;
                                                sub_mb_pred_state   <= `rst_sub_mb_pred;
                                            end
                                        else
                                            begin
                                                if ( num_ref_idx_l0_active_minus1_in > 0 )
                                                    begin
                                                        mb_pred_state <= `ref_idx_l0_s;
                                                        exp_golomb_decoding_te_sel_out  <= 1;
                                                    end
                                                else
                                                    begin
                                                        ref_idx_l0_out <= 0;
                                                        ref_idx_l0_curr_mb_out <= 0;
                                                        mb_pred_state <= `mvdx_l0_s;
                                                    end
                                            end
                                    end 
								else begin
									slice_data_state <= `sd_forward_to_next_frame;
								end
                            end    
                            `prev_intra4x4_pred_mode_flag_s:
                                begin
                                    prev_intra4x4_pred_mode_flag_out <= rbsp_in[23];
                                    if (rbsp_in[23] == 0)
                                        mb_pred_state <= `rem_intra4x4_pred_mode_s;
                                    else
                                        mb_pred_state <= `luma_blk4x4_index_update;
                                end
                            `rem_intra4x4_pred_mode_s:
                                begin
                                    rem_intra4x4_pred_mode_out <= rbsp_in[23:21];
                                    mb_pred_state <= `luma_blk4x4_index_update;
                                end

                            `intra_pred_mode_chroma_s:
                                begin
                                    intra_pred_mode_chroma <= exp_golomb_decoding_output_in;
                                    if ( mb_pred_mode != `mb_pred_mode_I16MB )
                                        begin
                                            slice_data_state <= `coded_block_pattern_s;
                                            if ( mb_pred_mode == `mb_pred_mode_I4MB )
                                                exp_golomb_decoding_me_intra4x4_out <= 1;
                                            else // inter
                                                exp_golomb_decoding_me_intra4x4_out <= 0;
                                        end
                                    else if (CBP_luma_in || CBP_chroma_in || mb_pred_mode == `mb_pred_mode_I16MB)
                                        slice_data_state <= `mb_qp_delta_s;
                                    else
                                        begin
                                            slice_data_state <= `residual; 
                                            residual_state <= `rst_residual;
                                        end
                                end
                                
                            `luma_blk4x4_index_update:
                                begin
                                    case(luma4x4BlkIdx)
                                        0 : intra4x4_pred_mode_curr_mb_out[3 : 0] <= I4_pred_mode_in; 
                                        1 : intra4x4_pred_mode_curr_mb_out[7 : 4] <= I4_pred_mode_in; 
                                        2 : intra4x4_pred_mode_curr_mb_out[11: 8] <= I4_pred_mode_in; 
                                        3 : intra4x4_pred_mode_curr_mb_out[15:12] <= I4_pred_mode_in; 
                                        4 : intra4x4_pred_mode_curr_mb_out[19:16] <= I4_pred_mode_in; 
                                        5 : intra4x4_pred_mode_curr_mb_out[23:20] <= I4_pred_mode_in; 
                                        6 : intra4x4_pred_mode_curr_mb_out[27:24] <= I4_pred_mode_in; 
                                        7 : intra4x4_pred_mode_curr_mb_out[31:28] <= I4_pred_mode_in; 
                                        8 : intra4x4_pred_mode_curr_mb_out[35:32] <= I4_pred_mode_in; 
                                        9 : intra4x4_pred_mode_curr_mb_out[39:36] <= I4_pred_mode_in; 
                                        10: intra4x4_pred_mode_curr_mb_out[43:40] <= I4_pred_mode_in; 
                                        11: intra4x4_pred_mode_curr_mb_out[47:44] <= I4_pred_mode_in; 
                                        12: intra4x4_pred_mode_curr_mb_out[51:48] <= I4_pred_mode_in; 
                                        13: intra4x4_pred_mode_curr_mb_out[55:52] <= I4_pred_mode_in; 
                                        14: intra4x4_pred_mode_curr_mb_out[59:56] <= I4_pred_mode_in; 
                                        15: intra4x4_pred_mode_curr_mb_out[63:60] <= I4_pred_mode_in; 
                                    endcase
                                    if (luma4x4BlkIdx == 15)
                                        begin
                                            luma4x4BlkIdx <= 0;
                                            mb_pred_state <= `intra_pred_mode_chroma_s;
                                        end
                                    else
                                        begin
                                            luma4x4BlkIdx <= luma4x4BlkIdx + 1;
                                            mb_pred_state <= `prev_intra4x4_pred_mode_flag_s;
                                        end
                                end 
                            `ref_idx_l0_s:
                                begin
                                    ref_idx_l0_out <= exp_golomb_decoding_output_te_in;
                                    if ( mb_type == 0) // P_L0_16x16
                                        begin
                                            MbPartNum <= 1;
                                            MbPartWidth <= 16;
                                            MbPartHeight <= 16;
                                            ref_idx_l0_curr_mb_out[2:0] <= exp_golomb_decoding_output_te_in;
                                            ref_idx_l0_curr_mb_out[5:3] <= exp_golomb_decoding_output_te_in;
                                            ref_idx_l0_curr_mb_out[8:6] <= exp_golomb_decoding_output_te_in;
                                            ref_idx_l0_curr_mb_out[11:9] <= exp_golomb_decoding_output_te_in;
                                            exp_golomb_decoding_te_sel_out  <= 0;
                                            mb_pred_state <= `mvdx_l0_s;
                                        end
                                    else if ( mb_type == 1 ) // P_L0_L0_16x8
                                        begin
                                            MbPartNum <= 2;
                                            MbPartWidth <= 16;
                                            MbPartHeight <= 8;
                                            if (mbPartIdx == 0)
                                                begin
                                                    ref_idx_l0_curr_mb_out[2:0] <= exp_golomb_decoding_output_te_in;
                                                    ref_idx_l0_curr_mb_out[5:3] <= exp_golomb_decoding_output_te_in;
                                                    mbPartIdx <= 1;
                                                end
                                            else if (mbPartIdx == 1)
                                                begin
                                                    ref_idx_l0_curr_mb_out[8:6] <= exp_golomb_decoding_output_te_in;
                                                    ref_idx_l0_curr_mb_out[11:9] <= exp_golomb_decoding_output_te_in;
                                                    mbPartIdx <= 0;
                                                    mb_pred_state <= `mvdx_l0_s;
                                                    exp_golomb_decoding_te_sel_out  <= 0;
                                                end
                                        end
                                    else // mb_type = 2  P_L0_L0_8x16
                                        begin
                                            MbPartNum <= 2;
                                            MbPartWidth <= 8;
                                            MbPartHeight <= 16;
                                            if (mbPartIdx == 0)
                                                begin
                                                    ref_idx_l0_curr_mb_out[2:0] <= exp_golomb_decoding_output_te_in;
                                                    ref_idx_l0_curr_mb_out[8:6] <= exp_golomb_decoding_output_te_in;
                                                    mbPartIdx <= 1;
                                                end
                                            else if (mbPartIdx == 1)
                                                begin
                                                    ref_idx_l0_curr_mb_out[5:3] <= exp_golomb_decoding_output_te_in;
                                                    ref_idx_l0_curr_mb_out[11:9] <= exp_golomb_decoding_output_te_in;
                                                    mbPartIdx <= 0;
                                                    mb_pred_state <= `mvdx_l0_s;
                                                    exp_golomb_decoding_te_sel_out  <= 0;
                                                end
                                        end
                                end
                            `mvdx_l0_s:
                                begin
									mvdx_l0 <= exp_golomb_decoding_output_se_in;
									mb_pred_state <= `mvdy_l0_s; 
								end
                            `mvdy_l0_s:
                                begin
									mvdy_l0 <= exp_golomb_decoding_output_se_in;
									mb_pred_state <= `mv_calc_l0_s; 
									mv_calc_ready <= 1;
								end
							`mv_calc_l0_s:
						   		begin
									if (mv_calc_valid && mbPartIdx + 1 < MbPartNum)
                                        begin
											mv_calc_ready <= 0;
                                            mbPartIdx <= mbPartIdx + 1;
                                            mb_pred_state <= `mvdx_l0_s;
                                            if ( mb_type == 1) // P_L0_L0_16x8
                                                luma4x4BlkIdx <= 8; // In order to update pixel_y, pixel_x and for get_mvp
                                            else if ( mb_type == 2 )// P_L0_L0_8x16
                                                luma4x4BlkIdx <= 4;
                                        end
                                    else if (mv_calc_valid)
                                        begin
											mv_calc_ready <= 0;
                                            mb_pred_state <= `rst_mb_pred;
                                            if ( mb_pred_mode != `mb_pred_mode_I16MB )
                                                begin
                                                    slice_data_state <= `coded_block_pattern_s;
                                                    if ( mb_pred_mode == `mb_pred_mode_I4MB )
                                                        exp_golomb_decoding_me_intra4x4_out <= 1;
                                                    else // inter
                                                        exp_golomb_decoding_me_intra4x4_out <= 0;
                                                end
                                            else if (CBP_luma_reg || CBP_chroma_reg || mb_pred_mode == `mb_pred_mode_I16MB)
                                                slice_data_state <= `mb_qp_delta_s;
                                            else
                                                begin
                                                    slice_data_state <= `residual; 
                                                    residual_state <= `rst_residual; end
                                        end
                                end
                            default: mb_pred_state <= `rst_mb_pred;
                        endcase // case(mb_pred_state)
                        
                    `coded_block_pattern_s:
                        begin
                            CBP_luma_reg <= CBP_luma_in;
                            CBP_chroma_reg <= CBP_chroma_in;
                            if (CBP_luma_in || CBP_chroma_in || mb_pred_mode == `mb_pred_mode_I16MB)
                                begin
                                    slice_data_state <= `mb_qp_delta_s;
                                end
                            else
                                begin
                                    slice_data_state <= `residual; 
                                    residual_state <= `rst_residual;
                                end
                        end
                    
                    `mb_qp_delta_s:
                        begin
                            slice_data_state <= `mb_qp_delta_post_s;
						end
       				`mb_qp_delta_post_s:
                        begin
							if (qp  + exp_golomb_decoding_output_se_in_reg < 0)
                            	qp <= qp  + exp_golomb_decoding_output_se_in_reg + 52;
							else if (qp  + exp_golomb_decoding_output_se_in_reg > 51)
                            	qp <= qp  + exp_golomb_decoding_output_se_in_reg - 52;
							else
								qp <= qp  + exp_golomb_decoding_output_se_in_reg;
                            slice_data_state <= `residual;
                            residual_state <= `rst_residual;                            
                        end
                    `residual:
                        case(residual_state)
                            `rst_residual :
                                 begin
                                    step <= 0;
                                    luma4x4BlkIdx <= 0;
                                    chroma4x4BlkIdx <= 0;
                                    if (mb_pred_mode == `mb_pred_mode_I16MB) 
                                        residual_state <= `Intra16x16DCLevel_s;
                                    else if (CBP_luma_reg & 1)                                        
                                        residual_state <= `LumaLevel_s;
                                    else
                                        residual_state <= `LumaLevel_0_s;
                                end
                            `Intra16x16DCLevel_s:
                                begin
                                    if(step == 0)
                                    begin
                                        residual_start <= 1;
                                        nC <= nC_in;
                                        max_coeff_num <= 16;                                                    
                                        step <= 1;
                                    end
                                    else if (step == 1) begin
                                    	residual_start <= 0;
                                    	step <= 2;
                                    end
                                    else if (step == 2) begin                         
                                        if(residual_valid) begin
                                            step <= 0;
                                            if ( CBP_luma_reg & (1 << (luma4x4BlkIdx >> 2) ) )
                                                residual_state <= `Intra16x16ACLevel_s;
                                            else
                                                residual_state <= `Intra16x16ACLevel_0_s;
                                        end
                                    end
                                end
                                
                            `Intra16x16ACLevel_s:
                                begin
                                    if (step == 0) begin
                                        residual_start <= 1;
                                        nC <= nC_in;
                                        max_coeff_num <= 15;
                                        step <= 1;
                                        if (mb_pred_inter_sel) begin
                                            inter_pred_start <= 1;
                        				end
                                        else begin
                                        	intra_pred_start <= 1;
                        				end
                                    end
                                    else if (step == 1) begin
                                        residual_start <= 0;
                                        if (mb_pred_inter_sel)
                                        	inter_pred_start <= 0;
                                        else
                                        	intra_pred_start <= 0;
                                        step <= 4;
									end
                                    else if (step == 4) begin
                                        if(sum_valid && ~mb_pred_inter_sel || residual_valid && mb_pred_inter_sel ) begin
                                            step <= 0;
                                            if ( luma4x4BlkIdx == 15 )
                                                if ( CBP_chroma_reg )
                                                    residual_state <= `ChromaDCLevel_Cb_s;
                                                else begin
                                                    residual_state <= `ChromaACLevel_Cb_0_s;
                                                    chroma4x4BlkIdx <= 0;
                                                end
                                            else if (  CBP_luma_reg & (1 <<( (luma4x4BlkIdx +1) >> 2 ) ) )
                                                begin
                                                    luma4x4BlkIdx <= luma4x4BlkIdx + 1;
                                                    residual_state <= `Intra16x16ACLevel_s;
                                                end
                                            else
                                                begin
                                                    luma4x4BlkIdx <= luma4x4BlkIdx + 1;
                                                    residual_state <= `Intra16x16ACLevel_0_s;
                                                end
                                        end
                                    end                                   
                                end
                            
                            `Intra16x16ACLevel_0_s :
                                begin
                                    if (step == 0) begin
                                        residual_start <= 1;
                                        if (mb_pred_inter_sel) begin
                                            inter_pred_start <= 1;
                        				end
                                        else begin
                                        	intra_pred_start <= 1;
                        				end
                                        step <= 1;
                                    end
                                    else if (step == 1) begin
                                        residual_start <= 0;
                                        if (mb_pred_inter_sel)
                                        	inter_pred_start <= 0;
                                        else
                                        	intra_pred_start <= 0;
                                        step <= 4;
                                    end
                                    else if (step == 4) begin
                                        if(sum_valid && ~mb_pred_inter_sel ||residual_valid && mb_pred_inter_sel) begin
                                            step <= 0;  
                                            if (luma4x4BlkIdx == 15 )
                                                if ( CBP_chroma_reg )
                                                    residual_state <= `ChromaDCLevel_Cb_s;
                                                else begin
                                                    residual_state <= `ChromaACLevel_Cb_0_s;
                                                    chroma4x4BlkIdx <= 0;                                        
                                                end
                                            else if ( CBP_luma_reg & (1 <<( (luma4x4BlkIdx +1) >> 2 ) ) )
                                                begin
                                                    luma4x4BlkIdx <= luma4x4BlkIdx + 1;
                                                    residual_state <= `Intra16x16ACLevel_s;
                                                end
                                            else
                                                begin
                                                    luma4x4BlkIdx <= luma4x4BlkIdx + 1;
                                                    residual_state <= `Intra16x16ACLevel_0_s;
                                                end
                                        end
                                    end
                                end
                                
                            `LumaLevel_s:
                                begin
                                    if (step == 0) begin
                                        residual_start <= 1;
                                        nC <= nC_in;
                                        max_coeff_num <= 16;
                                        step <= 1;
                                        if (mb_pred_inter_sel) begin
                                            inter_pred_start <= 1;
                        				end
                                        else begin
                                        	intra_pred_start <= 1;
                        				end
                                    end
                                    else if (step == 1) begin
                                    	residual_start <= 0;
                                    	if (mb_pred_inter_sel)
                                        	inter_pred_start <= 0;
                                        else
                                        	intra_pred_start <= 0;
                                    	step <= 4;
                                    end
                                    else if (step == 4) begin 
                                        if(sum_valid && ~mb_pred_inter_sel ||residual_valid && mb_pred_inter_sel) begin                                   
                                            step <= 0;
                                            if ( luma4x4BlkIdx == 15 )
                                                if ( CBP_chroma_reg )
                                                    residual_state <= `ChromaDCLevel_Cb_s;
                                                else begin
                                                    residual_state <= `ChromaACLevel_Cb_0_s;
                                                    chroma4x4BlkIdx <= 0;                                             
                                                end
                                            else if (  CBP_luma_reg & (1 <<( (luma4x4BlkIdx +1) >> 2 ) ))
                                                begin
                                                    luma4x4BlkIdx <= luma4x4BlkIdx + 1;
                                                    residual_state <= `LumaLevel_s;
                                                end
                                            else
                                                begin
                                                    luma4x4BlkIdx <= luma4x4BlkIdx + 1;
                                                    residual_state <= `LumaLevel_0_s;
                                                end
                                        end
                                    end
                                end
    
                            `LumaLevel_0_s:
                                begin
                                    if (step == 0) begin
                                        residual_start <= 1;
                                        if (mb_pred_inter_sel) begin
                                            inter_pred_start <= 1;
                        				end
                                        else begin
                                        	intra_pred_start <= 1;
                        				end
                                        step <= 1;
                                    end
                                    else if (step == 1) begin
                                    	residual_start <= 0;
                                    	if (mb_pred_inter_sel)
                                        	inter_pred_start <= 0;
                                        else
                                        	intra_pred_start <= 0;
                                    	step <= 4;
                                    end
                                    else if (step == 4) begin 
                                        if(sum_valid && ~mb_pred_inter_sel ||residual_valid && mb_pred_inter_sel) begin                                   
                                            step <= 0;
                                            if ( luma4x4BlkIdx == 15 )
                                                if ( CBP_chroma_reg )
                                                    residual_state <= `ChromaDCLevel_Cb_s;
                                                else begin
                                                    residual_state <= `ChromaACLevel_Cb_0_s;
                                                    chroma4x4BlkIdx <= 0;                                            
                                                end
                                            else if (  CBP_luma_reg & (1 <<( (luma4x4BlkIdx +1) >> 2 ) ) )
                                                begin
                                                    luma4x4BlkIdx <= luma4x4BlkIdx + 1;
                                                    residual_state <= `LumaLevel_s;
                                               end
                                            else
                                                begin
                                                    luma4x4BlkIdx <= luma4x4BlkIdx + 1;
                                                    residual_state <= `LumaLevel_0_s;
                                                end
                                        end
                                    end
                                end
                                
                            `ChromaDCLevel_Cb_s:
                                begin
                                    if(step == 0)begin
                                        residual_start <= 1;
                                        nC <= -1;
                                        max_coeff_num <= 4;
                                        step <= 1;
                                    end
                                    else if (step == 1) begin
                                        residual_start <= 0;
                                        step <= 2;
                                    end
                                    else if (step == 2) begin
                                        if(residual_valid) begin
                                            step <= 0;
                                            residual_state <= `ChromaDCLevel_Cr_s;
                                        end
                                    end
                                end
    
                            `ChromaDCLevel_Cr_s:
                                begin
                                    if(step == 0)begin
                                        residual_start <= 1;
                                        nC <= -1;
                                        max_coeff_num <= 4;
                                        step <= 1;
                                    end
                                    else if (step == 1) begin
                                        residual_start <= 0;
                                        step <= 2;
                                    end
                                    else if (step == 2) begin
                                        if(residual_valid) begin
                                            step <= 0;
                                            if ( CBP_chroma_reg[1] )
                                                begin
                                                    residual_state <= `ChromaACLevel_Cb_s;
                                                end
                                            else
                                                begin
                                                    residual_state <= `ChromaACLevel_Cb_0_s;
                                                    chroma4x4BlkIdx <= 0;
                                                end
                                        end
                                    end
                                end
    
                            `ChromaACLevel_Cb_s:
                                begin
                                    if (step == 0) begin
                                        residual_start <= 1;
                                        nC <= nC_cb_in;
                                        max_coeff_num <= 15;
                                        step <= 1;
                                        if (mb_pred_inter_sel) begin
                                            inter_pred_start <= 1;
                        				end
                                        else begin
                                        	intra_pred_start <= 1;
                        				end
                                    end
                                    else if (step == 1) begin
                                    	residual_start <= 0;
                                    	if (mb_pred_inter_sel)
                                        	inter_pred_start <= 0;
                                        else
                                        	intra_pred_start <= 0;
                                    	step <= 4;
                                    end
                                    else if (step == 4) begin 
                                        if(sum_valid && ~mb_pred_inter_sel || 
											mb_pred_inter_sel &&residual_valid && blk4x4_counter_residual < 23 ||
											mb_pred_inter_sel && sum_valid && blk4x4_counter_sum == 23) begin                                           
                                            step <= 0; 
                                            if ( chroma4x4BlkIdx == 3 )
                                                begin
                                                    residual_state <= `ChromaACLevel_Cr_s;
                                                    chroma4x4BlkIdx <= 0;
                                                end
                                            else
                                                begin
                                                    residual_state <= `ChromaACLevel_Cb_s;
                                                    chroma4x4BlkIdx <= chroma4x4BlkIdx + 1;
                                                end
                                        end
                                    end
                                end
                                
                            `ChromaACLevel_Cr_s:
                                begin
                                    if (step == 0) begin
                                        residual_start <= 1;
                                        nC <= nC_cr_in;
                                        max_coeff_num <= 15;
                                        step <= 1;
                                    	if (mb_pred_inter_sel) begin
                                            inter_pred_start <= 1;
                        				end
                                        else begin
                                        	intra_pred_start <= 1;
                        				end
                                    end
                                    else if (step == 1) begin
                                    	residual_start <= 0;
                                    	if (mb_pred_inter_sel)
                                        	inter_pred_start <= 0;
                                        else
                                        	intra_pred_start <= 0;
                                    	step <= 4;
                                    end
                                    else if (step == 4) begin 
                                        if(sum_valid && ~mb_pred_inter_sel || 
											mb_pred_inter_sel &&residual_valid && blk4x4_counter_residual < 23 ||
											mb_pred_inter_sel && sum_valid && blk4x4_counter_sum == 23) begin                                           
                                            step <= 0;
                                            if ( chroma4x4BlkIdx == 3 )
                                                begin
                                                    residual_state <= `rst_residual;
                                                    slice_data_state <= `pre_store_to_fpga_ram; // temporary, should be `intra-pred or inter-polate
                                                end
                                            else
                                                begin
                                                    chroma4x4BlkIdx <= chroma4x4BlkIdx + 1;
                                                    residual_state <= `ChromaACLevel_Cr_s;
                                                end
                                        end
                                    end
                                end
                                              
                            `ChromaACLevel_Cb_0_s:
                                begin
	                                if (step == 0) begin
                                        residual_start <= 1;
                                        step <= 1;
                                        if (mb_pred_inter_sel) begin
                                            inter_pred_start <= 1;
                        				end
                                        else begin
                                        	intra_pred_start <= 1;
                        				end
                                    end
                                    else if (step == 1) begin
                                    	residual_start <= 0;
                                    	if (mb_pred_inter_sel)
                                        	inter_pred_start <= 0;
                                        else
                                        	intra_pred_start <= 0;
                                    	step <= 4;
                                    end
                                    else if (step == 4) begin 
                                        if(sum_valid && ~mb_pred_inter_sel || 
											mb_pred_inter_sel &&residual_valid && blk4x4_counter_residual < 23 ||
											mb_pred_inter_sel && sum_valid && blk4x4_counter_sum == 23) begin                                           
                                            step <= 0;                                
                                            if ( chroma4x4BlkIdx == 3) begin
                                                residual_state <= `ChromaACLevel_Cr_0_s;
                                                chroma4x4BlkIdx <= 0;
                                            end
                                            else begin
                                                 chroma4x4BlkIdx <= chroma4x4BlkIdx + 1;
                                            end
                                        end
                                    end
                                end
                            `ChromaACLevel_Cr_0_s:
                                begin
                                    if (step == 0) begin
                                        residual_start <= 1;
                                        step <= 1;
                                    	if (mb_pred_inter_sel) begin
                                            inter_pred_start <= 1;
                        				end
                                        else begin
                                        	intra_pred_start <= 1;
                        				end
                                    end
                                    else if (step == 1) begin
                                    	residual_start <= 0;
                                    	if (mb_pred_inter_sel)
                                        	inter_pred_start <= 0;
                                        else
                                        	intra_pred_start <= 0;
                                    	step <= 4;
                                    end
                                    else if (step == 4) begin 
                                        if(sum_valid && ~mb_pred_inter_sel || 
											mb_pred_inter_sel &&residual_valid && blk4x4_counter_residual < 23 ||
											mb_pred_inter_sel && sum_valid && blk4x4_counter_sum == 23) begin                                           
                                            step <= 0; 
                                            if ( chroma4x4BlkIdx == 3) begin
                                                residual_state <= `rst_residual;
                                                slice_data_state <= `pre_store_to_fpga_ram; // temporary, should be `intra-pred or inter-polate
                                            end
                                            else begin
                                                 chroma4x4BlkIdx <= chroma4x4BlkIdx + 1;
                                            end
                                        end
                                    end
                                end                                
                        endcase // case(residual_state)
                    `p_skip_s : begin
						if (blk4x4_counter_sum == 24) begin
							slice_data_state <= `pre_store_to_fpga_ram; //temporary, should be inter-polate
							p_skip_sel <= 1'b0;
						end
                    end
                    `sub_mb_pred: 
                        case(sub_mb_pred_state)
                            `rst_sub_mb_pred:
                                begin
                                    sub_mb_pred_state <= `sub_mb_type_s;
                                    mbPartIdx <= 0; // 4 8x8 sub mb, no possible 1 16x8 and 2 8x8
                                    subMbPartIdx <= 0;
                                end
                            `sub_mb_type_s: // stream format: 4 sub_mb_type, 4 ref_idx(if exist), mvds
                                begin
                                    if (mbPartIdx == 0)
                                        begin
                                            sub_mb_type[3:0] <= exp_golomb_decoding_output_in;
                                            mbPartIdx <= 1;
                                        end
                                    else if (mbPartIdx == 1)
                                        begin
                                            sub_mb_type[7:4] <= exp_golomb_decoding_output_in;
                                            mbPartIdx <= 2;
                                        end
                                    else if (mbPartIdx == 2)
                                        begin
                                            sub_mb_type[11:8] <= exp_golomb_decoding_output_in;
                                            mbPartIdx <= 3;
                                        end
                                    else if (mbPartIdx == 3)
                                        begin
                                            sub_mb_type[15:12] <= exp_golomb_decoding_output_in;
                                            mbPartIdx <= 0;
                                            if ( num_ref_idx_l0_active_minus1_in > 0 && mb_pred_mode != `mb_pred_mode_P_REF0 )
                                                begin
                                                    sub_mb_pred_state <= `sub_ref_idx_l0_s;
                                                    exp_golomb_decoding_te_sel_out  <= 1;
                                                end
                                            else
                                                begin
                                                    ref_idx_l0_out <= 0;
                                                    ref_idx_l0_curr_mb_out <= 0;
                                                    mbPartIdx <= 0;
                                                    subMbPartIdx <= 0;
                                                    luma4x4BlkIdx <= 0;                                                    
                                                    case(sub_mb_type[1:0])
                                                        0:begin MbPartWidth <= 8; MbPartHeight <= 8;SubMbPartNum <= 1;end
                                                        1:begin MbPartWidth <= 8; MbPartHeight <= 4;SubMbPartNum <= 2;end
                                                        2:begin MbPartWidth <= 4; MbPartHeight <= 8;SubMbPartNum <= 2;end
                                                        default:begin MbPartWidth <= 4; MbPartHeight <= 4;SubMbPartNum <= 4;end
                                                    endcase                                                    
                                                    sub_mb_pred_state <= `sub_mvdx_l0_s;
                                                end
                                        end
                                end
                                      
                            `sub_ref_idx_l0_s:
                                if (mbPartIdx == 0)
                                    begin
                                        ref_idx_l0_out <= exp_golomb_decoding_output_te_in;
                                        ref_idx_l0_curr_mb_out[2:0] <= exp_golomb_decoding_output_te_in;
                                        mbPartIdx <= 1;
                                    end
                                else if (mbPartIdx == 1)
                                    begin
                                        ref_idx_l0_out <= exp_golomb_decoding_output_te_in;
                                        ref_idx_l0_curr_mb_out[5:3] <= exp_golomb_decoding_output_te_in;
                                        mbPartIdx <= 2;
                                    end
                                else if (mbPartIdx == 2)
                                    begin
                                        ref_idx_l0_out <= exp_golomb_decoding_output_te_in;
                                        ref_idx_l0_curr_mb_out[8:6] <= exp_golomb_decoding_output_te_in;
                                        mbPartIdx <= 3;
                                    end
                                else //mbPartIdx = 3
                                    begin
                                        ref_idx_l0_out <= exp_golomb_decoding_output_te_in;
                                        ref_idx_l0_curr_mb_out[11:9] <= exp_golomb_decoding_output_te_in;
                                        sub_mb_pred_state <= `sub_mvdx_l0_s;
                                        exp_golomb_decoding_te_sel_out  <= 0;
                                        case(sub_mb_type[1:0])
                                            0:begin MbPartWidth <= 8; MbPartHeight <= 8;SubMbPartNum <= 1;end
                                            1:begin MbPartWidth <= 8; MbPartHeight <= 4;SubMbPartNum <= 2;end
                                            2:begin MbPartWidth <= 4; MbPartHeight <= 8;SubMbPartNum <= 2;end
                                            default:begin MbPartWidth <= 4; MbPartHeight <= 4;SubMbPartNum <= 4;end
                                        endcase
                                        mbPartIdx <= 0;
                                        subMbPartIdx <= 0;
                                        luma4x4BlkIdx <= 0;
                                    end
                
                            `sub_mvdx_l0_s:
                                begin
                                    mvdx_l0 <= exp_golomb_decoding_output_se_in;
                                    sub_mb_pred_state <= `sub_mvdy_l0_s;
                                end
                            `sub_mvdy_l0_s:
                                begin
									mvdy_l0 <= exp_golomb_decoding_output_se_in;
									sub_mb_pred_state <= `sub_mv_calc_l0_s; 
									mv_calc_ready <= 1;
								end
                            `sub_mv_calc_l0_s:
                                begin
                                    if (mv_calc_valid && subMbPartIdx + 1 < SubMbPartNum)
                                        begin
											mv_calc_ready <= 0;
                                            sub_mb_pred_state <= `sub_mvdx_l0_s;
                                            subMbPartIdx <= subMbPartIdx + 1;
                                            case (sub_mb_type[1:0]) // update luma4x4BlkIdx for get_mvp
                                                1:luma4x4BlkIdx <= (mbPartIdx << 2)+2;
                                                2:luma4x4BlkIdx <= (mbPartIdx << 2)+1;
                                                3:luma4x4BlkIdx <= (mbPartIdx << 2) + subMbPartIdx+1;
                                                default:luma4x4BlkIdx <= 0;
                                            endcase 
                                        end
                                    else if (mv_calc_valid)
                                        begin
											mv_calc_ready <= 0;
                                            if (mbPartIdx + 1 < 4)
                                                begin
                                                    sub_mb_pred_state <= `sub_mvdx_l0_s;
                                                    sub_mb_type <= sub_mb_type >> 4;    //last 2 bits -> curr_sub_mb_type
                                                    mbPartIdx <= mbPartIdx + 1;
                                                    subMbPartIdx <= 0;
                                                    luma4x4BlkIdx <= (mbPartIdx+1) << 2; // update luma4x4BlkIdx for get_mvp
                                                    case ((sub_mb_type>>4) & 4'hf)
                                                        0: 
                                                            begin
                                                                MbPartWidth <= 8;
                                                                MbPartHeight <= 8;
                                                                SubMbPartNum <= 1;
                                                            end
                                                        1:
                                                            begin
                                                                MbPartWidth <= 8;
                                                                MbPartHeight <= 4;
                                                                SubMbPartNum <= 2;
                                                            end
                                                        2:
                                                            begin
                                                                MbPartWidth <= 4;
                                                                MbPartHeight <= 8;
                                                                SubMbPartNum <= 2;
                                                            end
                                                        default://3:
                                                            begin
                                                                MbPartWidth <= 4;
                                                                MbPartHeight <= 4;
                                                                SubMbPartNum <= 4;
                                                            end
                                                    endcase                                                    
                                                end
                                            else
                                                begin
                                                    sub_mb_pred_state <= `rst_sub_mb_pred;
                                                    mbPartIdx <= 0;
                                                    if ( mb_pred_mode != `mb_pred_mode_I16MB )
                                                        begin
                                                            slice_data_state <= `coded_block_pattern_s;
                                                            if ( mb_pred_mode == `mb_pred_mode_I4MB )
                                                                exp_golomb_decoding_me_intra4x4_out <= 1;
                                                            else // inter
                                                                exp_golomb_decoding_me_intra4x4_out <= 0;
                                                        end
                                                    else if (CBP_luma_reg || CBP_chroma_reg || mb_pred_mode == `mb_pred_mode_I16MB)
                                                        slice_data_state <= `mb_qp_delta_s;
                                                    else
                                                        begin
                                                            slice_data_state <= `residual; 
                                                            residual_state <= `rst_residual;
                                                        end
                                                end
                                        end
                                end
                            default : sub_mb_pred_state <= `rst_sub_mb_pred;
                        endcase  //  case(sub_mb_pred_state)
					`pre_store_to_fpga_ram:begin
						if (prev_mb_deblocking_done_or_mb0)begin
							slice_data_state <= `store_to_fpga_ram;
						end
					end	
                    `store_to_fpga_ram: 
                        begin
                            fpga_ram_intra4x4_pred_mode_wr_n <= 0;
                            fpga_ram_ref_idx_wr_n <= 0;
                            fpga_ram_mvx_wr_n <= 0;
                            fpga_ram_mvy_wr_n <= 0;
                            fpga_ram_nnz_wr_n <= 0;
                            fpga_ram_nnz_cb_wr_n <= 0;
                            fpga_ram_nnz_cr_wr_n <= 0;
							fpga_ram_qp_wr_n <= 0;
							fpga_ram_qp_c_wr_n <= 0;
                            
                            
                            fpga_ram_intra4x4_pred_mode_addr <= mb_x_out;
                            fpga_ram_ref_idx_addr <= mb_x_out;
                            fpga_ram_mvx_addr <= mb_x_out;
                            fpga_ram_mvy_addr <= mb_x_out;
                            fpga_ram_nnz_addr <= mb_x_out;
                            fpga_ram_nnz_cb_addr <= mb_x_out;
                            fpga_ram_nnz_cr_addr <= mb_x_out;
                            fpga_ram_qp_addr <= mb_x_out;
                            fpga_ram_qp_c_addr <= mb_x_out;

                            fpga_ram_qp_data_in <= qp;
                            fpga_ram_qp_c_data_in <= qp_c;
                            
                            fpga_ram_intra4x4_pred_mode_data_in <= {intra4x4_pred_mode_curr_mb_out[63:60],
                                                                    intra4x4_pred_mode_curr_mb_out[59:56],
                                                                    intra4x4_pred_mode_curr_mb_out[47:44],
                                                                    intra4x4_pred_mode_curr_mb_out[43:40]
                                                                    }; // 10,11,14,15

                            fpga_ram_ref_idx_data_in[5:0] <= ref_idx_l0_curr_mb_out[11:6];
                            if( mb_skip_run > 0 ) //temporary
                                begin
                                    fpga_ram_mvx_data_in <= {mvx_l0, mvx_l0, 
                                                             mvx_l0, mvx_l0};     
                                    fpga_ram_mvy_data_in <= {mvy_l0,mvy_l0 , 
                                                             mvy_l0, mvy_l0};                                
                                end
                            else
                                begin
                                    fpga_ram_mvx_data_in <= {mvx_l0_curr_mb_out[255:240], 
                                                             mvx_l0_curr_mb_out[239:224], 
                                                             mvx_l0_curr_mb_out[191:176],
                                                             mvx_l0_curr_mb_out[175:160]
                                                             };     
                                    fpga_ram_mvy_data_in <= {mvy_l0_curr_mb_out[255:240], 
                                                             mvy_l0_curr_mb_out[239:224], 
                                                             mvy_l0_curr_mb_out[191:176],
                                                             mvy_l0_curr_mb_out[175:160]
                                                             };                                
                                end

                            
                            fpga_ram_nnz_data_in <= {nC_curr_mb_out[127:120], nC_curr_mb_out[119:112],
                                                     nC_curr_mb_out[95:88], nC_curr_mb_out[87:80]};
                            fpga_ram_nnz_cb_data_in <= {nC_cb_curr_mb_out[31:24], nC_cb_curr_mb_out[23:16]};
                            fpga_ram_nnz_cr_data_in <= {nC_cr_curr_mb_out[31:24], nC_cr_curr_mb_out[23:16]};
                            
                            intra_mode[mb_x_out] <= mb_pred_mode == `mb_pred_mode_I4MB || mb_pred_mode == `mb_pred_mode_I16MB ? 1 : 0;
							intra_mode_left_mb <= mb_pred_mode == `mb_pred_mode_I4MB || mb_pred_mode == `mb_pred_mode_I16MB;
							intra_mode_up_left_mb <= intra_mode[mb_x_out];
							intra_mode_up_mb <= intra_mode[mb_x_out+1];

                            slice_data_state <= `mb_num_update;
                        end

                    `mb_num_update:
                       begin
							fpga_ram_intra4x4_pred_mode_wr_n <= 1;
                            fpga_ram_ref_idx_wr_n <= 1;
                            fpga_ram_mvx_wr_n <= 1;
                            fpga_ram_mvy_wr_n <= 1;
                            fpga_ram_nnz_wr_n <= 1;
                            fpga_ram_nnz_cb_wr_n <= 1;
                            fpga_ram_nnz_cr_wr_n <= 1;
							fpga_ram_qp_wr_n <= 1;
							fpga_ram_qp_c_wr_n <= 1;
                            
					        slice_data_state <= `mb_num_update_post;
                            mb_index_out <= mb_index_out + 1;
                            slice_mb_index <= slice_mb_index + 1;
                           if ( mb_skip_run > 0) // the macroblock immediately follows the last P_skip macroblock is still in P_skip_mode
                                begin
                                    mb_skip_run <= mb_skip_run - 1;
									P_skip_mode <= 1;
                                    MbPartWidth <= 16;
                                    MbPartHeight <= 16;
                                    luma4x4BlkIdx <= 0;
                                end
                            else
                                begin
                                    P_skip_mode <= 0;
                                end                                          
							if (is_last_bit_of_rbsp)//last MB in slice,clear P_skip_mode
								P_skip_mode <= 0;
                            if (mb_x_out == pic_width_in_mbs_minus1_sps_in)
                                begin
                                    mb_x_out <= 0;
                                    if (mb_y_out == pic_height_in_map_units_minus1_sps_in)
                                        begin
                                            mb_index_out <= 0;
                                            mb_y_out <= 0; // end of a slice parsing
                                        end
                                    /*
                                    //for test
                                    //synthesis translate_off
                                    if (mb_y_out == 0)//pic_height_in_map_units_minus1_sps_in)
                                        begin
                                            mb_index_out <= 0;
                                            mb_y_out <= 0; // end of a slice parsing
                                            slice_data_state <= `rbsp_trailing_bits_slice_data;
                                            P_skip_mode <= 0;
                                        end
                                    //synthesis translate_on
                                    */
                                    else
                                        begin
                                            mb_y_out <= mb_y_out + 1;
                                        end
                                end
                            else
                                begin
                                    mb_x_out <= mb_x_out + 1;
                                end 
                            //if(mb_x_out==pic_width_in_mbs_minus1_sps_in &&
                            //   mb_y_out==pic_height_in_map_units_minus1_sps_in)
                            //    slice_data_state <= `rbsp_trailing_bits_slice_data;
                            //else 
                            //    slice_data_state <= `rst_slice_data;
                        end
					`mb_num_update_post:begin
						if (mb_index_out == 0) begin
							if (prev_mb_deblocking_done)begin
								slice_data_state <= `sd_forward_to_next_frame;
								end_of_frame <= 1'b1;
							end
						end
						else if (is_last_bit_of_rbsp && mb_skip_run == 0) begin
							slice_data_state <= `rbsp_trailing_bits_slice_data;
						end
						else
							slice_data_state <= `rst_macroblock_s;
						mb_pred_state <= `rst_mb_pred;
					end
					`rbsp_trailing_bits_slice_data:begin
						slice_data_state <= `rst_slice_data_s;
					end
					`sd_forward_to_next_frame:begin
						end_of_frame <= 1'b0;
						slice_data_state <= `rst_slice_data_s;
						mb_x_out <= 0;
						mb_y_out <= 0;
						mb_index_out <= 0;
						mb_skip_run <= 0;
					end
                    default: slice_data_state <= `rst_slice_data_s;
				endcase    
				if (slice_data_state != `sd_forward_to_next_frame && slice_data_state != `rst_slice_data_s) begin
					if (bitstream_forwarded_rbsp)
						slice_data_state <= `sd_forward_to_next_frame;
					else if ((is_last_bit_of_rbsp && forward_len_out != 5'b11111 && forward_len_out != 0 )
						|| &counter_stick_at_decode) begin
						slice_data_state <= `sd_forward_to_next_frame;
						//synopsys translate_off
						$display("state to sd_forward_to_next_frame, counter_stick_at_decode=%d",counter_stick_at_decode);
						//$stop();
						//synopsys translate_on
					end
				end
			end
        end        
always @(posedge clk)
if (residual_state != `Intra16x16DCLevel_s && 
	residual_state != `ChromaDCLevel_Cb_s && residual_state != `ChromaDCLevel_Cr_s)
	is_residual_not_dc <= 1'b1;
else
	is_residual_not_dc <= 1'b0;

reg [15:0] mvx_l0_cmp;
reg [15:0] mvy_l0_cmp;
reg is_mvx_all_same;
reg is_mvy_all_same;
assign is_mv_all_same = is_mvx_all_same && is_mvy_all_same;

wire signed [15:0] mvx_l0_left_mb0 =  mvx_l0_left_mb_out[15:0];
wire signed [15:0] mvx_l0_left_mb1 =  mvx_l0_left_mb_out[31:16];
wire signed [15:0] mvx_l0_left_mb2 =  mvx_l0_left_mb_out[47:32];
wire signed [15:0] mvx_l0_left_mb3 =  mvx_l0_left_mb_out[63:48];

wire signed [15:0] mvy_l0_left_mb0 =  mvy_l0_left_mb_out[15:0];
wire signed [15:0] mvy_l0_left_mb1 =  mvy_l0_left_mb_out[31:16];
wire signed [15:0] mvy_l0_left_mb2 =  mvy_l0_left_mb_out[47:32];
wire signed [15:0] mvy_l0_left_mb3 =  mvy_l0_left_mb_out[63:48];

reg  mvx_diff_to_left_a0c0;
reg  mvx_diff_to_left_a1c4;
reg  mvx_diff_to_left_a2c8;
reg  mvx_diff_to_left_a3c12;
reg  mvx_diff_to_left_c0c1;
reg  mvx_diff_to_left_c4c5;
reg  mvx_diff_to_left_c8c9;
reg  mvx_diff_to_left_c12c13;
reg  mvx_diff_to_left_c1c2;
reg  mvx_diff_to_left_c5c6;
reg  mvx_diff_to_left_c9c10; 
reg  mvx_diff_to_left_c13c14;
reg  mvx_diff_to_left_c2c3;
reg  mvx_diff_to_left_c6c7;
reg  mvx_diff_to_left_c10c11;
reg  mvx_diff_to_left_c14c15;

reg  mvy_diff_to_left_a0c0;
reg  mvy_diff_to_left_a1c4;
reg  mvy_diff_to_left_a2c8;
reg  mvy_diff_to_left_a3c12;
reg  mvy_diff_to_left_c0c1;
reg  mvy_diff_to_left_c4c5;
reg  mvy_diff_to_left_c8c9;
reg  mvy_diff_to_left_c12c13;
reg  mvy_diff_to_left_c1c2;
reg  mvy_diff_to_left_c5c6;
reg  mvy_diff_to_left_c9c10; 
reg  mvy_diff_to_left_c13c14;
reg  mvy_diff_to_left_c2c3;
reg  mvy_diff_to_left_c6c7;
reg  mvy_diff_to_left_c10c11;
reg  mvy_diff_to_left_c14c15;

wire signed [15:0] mvx_l0_up_mb0 =  mvx_l0_up_mb_out[15:0];
wire signed [15:0] mvx_l0_up_mb1 =  mvx_l0_up_mb_out[31:16];
wire signed [15:0] mvx_l0_up_mb2 =  mvx_l0_up_mb_out[47:32];
wire signed [15:0] mvx_l0_up_mb3 =  mvx_l0_up_mb_out[63:48];

wire signed [15:0] mvy_l0_up_mb0 =  mvy_l0_up_mb_out[15:0];
wire signed [15:0] mvy_l0_up_mb1 =  mvy_l0_up_mb_out[31:16];
wire signed [15:0] mvy_l0_up_mb2 =  mvy_l0_up_mb_out[47:32];
wire signed [15:0] mvy_l0_up_mb3 =  mvy_l0_up_mb_out[63:48];

reg  mvx_diff_to_up_b0c0;
reg  mvx_diff_to_up_b1c1;
reg  mvx_diff_to_up_b2c2;
reg  mvx_diff_to_up_b3c3;
reg  mvx_diff_to_up_c0c4;
reg  mvx_diff_to_up_c1c5;
reg  mvx_diff_to_up_c2c6;
reg  mvx_diff_to_up_c3c7;
reg  mvx_diff_to_up_c4c8;
reg  mvx_diff_to_up_c5c9;
reg  mvx_diff_to_up_c6c10; 
reg  mvx_diff_to_up_c7c11;
reg  mvx_diff_to_up_c8c12;
reg  mvx_diff_to_up_c9c13;
reg  mvx_diff_to_up_c10c14;
reg  mvx_diff_to_up_c11c15;

reg  mvy_diff_to_up_b0c0;
reg  mvy_diff_to_up_b1c1;
reg  mvy_diff_to_up_b2c2;
reg  mvy_diff_to_up_b3c3;
reg  mvy_diff_to_up_c0c4;
reg  mvy_diff_to_up_c1c5;
reg  mvy_diff_to_up_c2c6;
reg  mvy_diff_to_up_c3c7;
reg  mvy_diff_to_up_c4c8;
reg  mvy_diff_to_up_c5c9;
reg  mvy_diff_to_up_c6c10; 
reg  mvy_diff_to_up_c7c11;
reg  mvy_diff_to_up_c8c12;
reg  mvy_diff_to_up_c9c13;
reg  mvy_diff_to_up_c10c14;
reg  mvy_diff_to_up_c11c15;

wire signed [15:0] mvx_l0_final = mvdx_l0 + mvpx_l0_in;
wire signed [15:0] mvy_l0_final = mvdy_l0 + mvpy_l0_in;

function [15:0] mv_diff_abs_ge4;
	input signed[15:0] a;
	input signed[15:0] b;
	reg signed [15:0] diff;
	begin
		diff = a - b;
		if (diff < 0)
			mv_diff_abs_ge4 = diff <= -4;
		else
			mv_diff_abs_ge4 = diff >= 4;
	end
endfunction

always @(posedge clk)
if(ena) begin
	mv_l0_calc_done <= 0;
	if (slice_data_state == `rst_macroblock_s) begin
        mvx_l0_curr_mb_out <= 128'b0; 
		is_mvx_all_same <= 1'b1;
		mvx_diff_to_left_a0c0 <= 0;
		mvx_diff_to_left_a1c4 <= 0;
		mvx_diff_to_left_a2c8 <= 0;
		mvx_diff_to_left_a3c12 <= 0;
		mvx_diff_to_left_c0c1 <= 0;
		mvx_diff_to_left_c4c5 <= 0;
		mvx_diff_to_left_c8c9 <= 0;
		mvx_diff_to_left_c12c13 <= 0;
		mvx_diff_to_left_c1c2 <= 0;
		mvx_diff_to_left_c5c6 <= 0;
		mvx_diff_to_left_c9c10 <= 0;
		mvx_diff_to_left_c13c14 <= 0;
		mvx_diff_to_left_c2c3 <= 0;
		mvx_diff_to_left_c6c7 <= 0;
		mvx_diff_to_left_c10c11 <= 0;
		mvx_diff_to_left_c14c15 <= 0;
		mvx_diff_to_up_b0c0 <= 0;
		mvx_diff_to_up_b1c1 <= 0;
		mvx_diff_to_up_b2c2 <= 0;
		mvx_diff_to_up_b3c3 <= 0;
		mvx_diff_to_up_c0c4 <= 0;
		mvx_diff_to_up_c1c5 <= 0;
		mvx_diff_to_up_c2c6 <= 0;
		mvx_diff_to_up_c3c7 <= 0;
		mvx_diff_to_up_c4c8 <= 0;
		mvx_diff_to_up_c5c9 <= 0;
		mvx_diff_to_up_c6c10 <= 0; 
		mvx_diff_to_up_c7c11 <= 0;
		mvx_diff_to_up_c8c12 <= 0;
		mvx_diff_to_up_c9c13 <= 0;
		mvx_diff_to_up_c10c14 <= 0;
		mvx_diff_to_up_c11c15 <= 0;
    end
    else if ((slice_data_state == `mb_pred && mb_pred_state == `mv_calc_l0_s && mv_calc_valid) 
        || (slice_data_state == `sub_mb_pred && sub_mb_pred_state == `sub_mv_calc_l0_s && mv_calc_valid) 
		|| (slice_data_state == `skip_run_save_mv) )begin
		if (MbPartWidth == 16 && MbPartHeight == 16)
            if ( slice_data_state == `skip_run_save_mv) //temporary
                begin
					mvx_diff_to_left_a0c0 <= mv_diff_abs_ge4(mvx_l0, mvx_l0_left_mb0);
					mvx_diff_to_left_a1c4 <= mv_diff_abs_ge4(mvx_l0, mvx_l0_left_mb1);
					mvx_diff_to_left_a2c8 <= mv_diff_abs_ge4(mvx_l0, mvx_l0_left_mb2);
					mvx_diff_to_left_a3c12 <= mv_diff_abs_ge4(mvx_l0, mvx_l0_left_mb3);
					mvx_diff_to_up_b0c0 <= mv_diff_abs_ge4(mvx_l0, mvx_l0_up_mb0);
					mvx_diff_to_up_b1c1 <= mv_diff_abs_ge4(mvx_l0, mvx_l0_up_mb1);
					mvx_diff_to_up_b2c2 <= mv_diff_abs_ge4(mvx_l0, mvx_l0_up_mb2);
					mvx_diff_to_up_b3c3 <= mv_diff_abs_ge4(mvx_l0, mvx_l0_up_mb3);
					mv_l0_calc_done <= 1;
                    mvx_l0_curr_mb_out[255:0]    <= {16{mvx_l0}}; 
                end
            else
                begin
					mvx_diff_to_left_a0c0 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_left_mb0);
					mvx_diff_to_left_a1c4 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_left_mb1);
					mvx_diff_to_left_a2c8 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_left_mb2);
					mvx_diff_to_left_a3c12 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_left_mb3);
					mvx_diff_to_up_b0c0 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_up_mb0);
					mvx_diff_to_up_b1c1 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_up_mb1);
					mvx_diff_to_up_b2c2 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_up_mb2);
					mvx_diff_to_up_b3c3 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_up_mb3);
					mv_l0_calc_done <= 1;
                    mvx_l0_curr_mb_out[15:0]    <= mvx_l0_final; 
                    mvx_l0_curr_mb_out[31:16]   <= mvx_l0_final;
                    mvx_l0_curr_mb_out[47:32]   <= mvx_l0_final;
                    mvx_l0_curr_mb_out[63:48]   <= mvx_l0_final;
                    mvx_l0_curr_mb_out[79:64]   <= mvx_l0_final;
                    mvx_l0_curr_mb_out[95:80]   <= mvx_l0_final;
                    mvx_l0_curr_mb_out[111:96]  <= mvx_l0_final;
                    mvx_l0_curr_mb_out[127:112] <= mvx_l0_final;
                    mvx_l0_curr_mb_out[143:128] <= mvx_l0_final;
                    mvx_l0_curr_mb_out[159:144] <= mvx_l0_final;
                    mvx_l0_curr_mb_out[175:160] <= mvx_l0_final;
                    mvx_l0_curr_mb_out[191:176] <= mvx_l0_final;
                    mvx_l0_curr_mb_out[207:192] <= mvx_l0_final;
                    mvx_l0_curr_mb_out[223:208] <= mvx_l0_final;
                    mvx_l0_curr_mb_out[239:224] <= mvx_l0_final;
                    mvx_l0_curr_mb_out[255:240] <= mvx_l0_final;
                end            
        else if (MbPartWidth == 16 && MbPartHeight == 8)
            if (mbPartIdx == 0)                
                begin
					mvx_diff_to_left_a0c0 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_left_mb0);
					mvx_diff_to_left_a1c4 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_left_mb1);
					mvx_diff_to_up_b0c0 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_up_mb0);
					mvx_diff_to_up_b1c1 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_up_mb1);
					mvx_diff_to_up_b2c2 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_up_mb2);
					mvx_diff_to_up_b3c3 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_up_mb3);
					mvx_l0_cmp <= mvx_l0_final;
                    mvx_l0_curr_mb_out[15:0]     <= mvx_l0_final; 
                    mvx_l0_curr_mb_out[31:16]   <= mvx_l0_final;
                    mvx_l0_curr_mb_out[47:32]   <= mvx_l0_final;
                    mvx_l0_curr_mb_out[63:48]   <= mvx_l0_final;
                    mvx_l0_curr_mb_out[79:64]   <= mvx_l0_final;
                    mvx_l0_curr_mb_out[95:80]   <= mvx_l0_final;
                    mvx_l0_curr_mb_out[111:96]   <= mvx_l0_final;
                    mvx_l0_curr_mb_out[127:112]   <= mvx_l0_final;
                end                
            else //mbPartIdx = 1
                begin
					mvx_diff_to_left_a2c8 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_left_mb2);
					mvx_diff_to_left_a3c12 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_left_mb3);
					mvx_diff_to_up_c4c8 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[47:32]);
					mvx_diff_to_up_c5c9 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[63:48]);
					mvx_diff_to_up_c6c10 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[111:96]);
					mvx_diff_to_up_c7c11 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[127:112]);
					mv_l0_calc_done <= 1;
					is_mvx_all_same <= is_mvx_all_same && (mvx_l0_cmp ==  mvx_l0_final);
                    mvx_l0_curr_mb_out[143:128]   <= mvx_l0_final;
                    mvx_l0_curr_mb_out[159:144]   <= mvx_l0_final;
                    mvx_l0_curr_mb_out[175:160] <= mvx_l0_final;
                    mvx_l0_curr_mb_out[191:176] <= mvx_l0_final;
                    mvx_l0_curr_mb_out[207:192]<= mvx_l0_final;
                    mvx_l0_curr_mb_out[223:208] <= mvx_l0_final;
                    mvx_l0_curr_mb_out[239:224] <= mvx_l0_final;
                    mvx_l0_curr_mb_out[255:240] <= mvx_l0_final;
                end
        else if (MbPartWidth == 8 && MbPartHeight == 16)
            if (mbPartIdx == 0)
                begin
					mvx_diff_to_left_a0c0 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_left_mb0);
					mvx_diff_to_left_a1c4 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_left_mb1);
					mvx_diff_to_left_a2c8 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_left_mb2);
					mvx_diff_to_left_a3c12 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_left_mb3);
					mvx_diff_to_up_b0c0 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_up_mb0);
					mvx_diff_to_up_b1c1 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_up_mb1);
					mvx_l0_cmp <= mvx_l0_final;
                    mvx_l0_curr_mb_out[15:0]     <= mvx_l0_final; 
                    mvx_l0_curr_mb_out[31:16]    <= mvx_l0_final;
                    mvx_l0_curr_mb_out[47:32]   <= mvx_l0_final;
                    mvx_l0_curr_mb_out[63:48]   <= mvx_l0_final;
                    mvx_l0_curr_mb_out[143:128]   <= mvx_l0_final;
                    mvx_l0_curr_mb_out[159:144]   <= mvx_l0_final;
                    mvx_l0_curr_mb_out[175:160]   <= mvx_l0_final;
                    mvx_l0_curr_mb_out[191:176]   <= mvx_l0_final;
                end          
            else //mbPartIdx = 1                
                begin
					mvx_diff_to_left_c1c2 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[31:16]);
					mvx_diff_to_left_c5c6 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[63:48]);
					mvx_diff_to_left_c9c10 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[159:144]);
					mvx_diff_to_left_c13c14 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[191:176]);
					mvx_diff_to_up_b2c2 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_up_mb2);
					mvx_diff_to_up_b3c3 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_up_mb3);
					mv_l0_calc_done <= 1;
					is_mvx_all_same <= is_mvx_all_same && (mvx_l0_cmp ==  mvx_l0_final);
                    mvx_l0_curr_mb_out[79:64]   <= mvx_l0_final;
                    mvx_l0_curr_mb_out[95:80]   <= mvx_l0_final;
                    mvx_l0_curr_mb_out[111:96]   <= mvx_l0_final;
                    mvx_l0_curr_mb_out[127:112]   <= mvx_l0_final;
                    mvx_l0_curr_mb_out[207:192]<= mvx_l0_final;
                    mvx_l0_curr_mb_out[223:208] <= mvx_l0_final;
                    mvx_l0_curr_mb_out[239:224] <= mvx_l0_final;
                    mvx_l0_curr_mb_out[255:240] <= mvx_l0_final;
                end
        else if( MbPartWidth == 8 && MbPartHeight == 8)
            case(mbPartIdx)
                0:
                    begin
						mvx_diff_to_left_a0c0 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_left_mb0);
						mvx_diff_to_left_a1c4 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_left_mb1);
						mvx_diff_to_up_b0c0 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_up_mb0);
						mvx_diff_to_up_b1c1 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_up_mb1);
						mvx_l0_cmp <= mvx_l0_final;
                        mvx_l0_curr_mb_out[15:0]     <= mvx_l0_final; 
                        mvx_l0_curr_mb_out[31:16]    <= mvx_l0_final;
                        mvx_l0_curr_mb_out[47:32]   <= mvx_l0_final;
                        mvx_l0_curr_mb_out[63:48]   <= mvx_l0_final;
                    end
                1:
                    begin
						mvx_diff_to_left_c1c2 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[31:16]);
						mvx_diff_to_left_c5c6 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[63:48]);
						mvx_diff_to_up_b2c2 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_up_mb2);
						mvx_diff_to_up_b3c3 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_up_mb3);
						is_mvx_all_same <= is_mvx_all_same && (mvx_l0_cmp ==  mvx_l0_final);
                        mvx_l0_curr_mb_out[79:64]   <= mvx_l0_final;
                        mvx_l0_curr_mb_out[95:80]   <= mvx_l0_final;
                        mvx_l0_curr_mb_out[111:96]   <= mvx_l0_final;
                        mvx_l0_curr_mb_out[127:112]   <= mvx_l0_final;
                    end
                2:
                    begin
						mvx_diff_to_left_a2c8 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_left_mb2);
						mvx_diff_to_left_a3c12 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_left_mb3);
						mvx_diff_to_up_c4c8 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[47:32]);
						mvx_diff_to_up_c5c9 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[63:48]);
						is_mvx_all_same <= is_mvx_all_same && (mvx_l0_cmp ==  mvx_l0_final);
                        mvx_l0_curr_mb_out[143:128]   <= mvx_l0_final;
                        mvx_l0_curr_mb_out[159:144]   <= mvx_l0_final;
                        mvx_l0_curr_mb_out[175:160] <= mvx_l0_final;
                        mvx_l0_curr_mb_out[191:176] <= mvx_l0_final;
                    end
                3:                   
                    begin
						mvx_diff_to_left_c9c10 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[159:144]);
						mvx_diff_to_left_c13c14 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[191:176]);
						mvx_diff_to_up_c6c10 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[111:96]);
						mvx_diff_to_up_c7c11 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[127:112]);
						mv_l0_calc_done <= 1;
						is_mvx_all_same <= is_mvx_all_same && (mvx_l0_cmp ==  mvx_l0_final);
                        mvx_l0_curr_mb_out[207:192] <= mvx_l0_final;
                        mvx_l0_curr_mb_out[223:208] <= mvx_l0_final;
                        mvx_l0_curr_mb_out[239:224] <= mvx_l0_final;
                        mvx_l0_curr_mb_out[255:240] <= mvx_l0_final;
                    end
                default: mvx_l0_curr_mb_out <= 0;
            endcase  
        else if (MbPartWidth == 8 && MbPartHeight == 4)
            case(mbPartIdx)
                0:
                    if (subMbPartIdx == 0)
                        begin
							mvx_diff_to_left_a0c0 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_left_mb0);
							mvx_diff_to_up_b0c0 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_up_mb0);
							mvx_diff_to_up_b1c1 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_up_mb1);
                            mvx_l0_curr_mb_out[15:0]     <= mvx_l0_final; 
                            mvx_l0_curr_mb_out[31:16]   <= mvx_l0_final;
                        end     
                    else // subMbPartIdx = 1
                        begin
							mvx_diff_to_left_a1c4 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_left_mb1);
							mvx_diff_to_up_c0c4 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[15:0]);
							mvx_diff_to_up_c1c5 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[31:16]);
                            mvx_l0_curr_mb_out[47:32]   <= mvx_l0_final;
                            mvx_l0_curr_mb_out[63:48]   <= mvx_l0_final;
                        end                   
                1:
                    if (subMbPartIdx == 0)
                        begin
							mvx_diff_to_left_c1c2 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[31:16]);
							mvx_diff_to_up_b2c2 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_up_mb2);
							mvx_diff_to_up_b3c3 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_up_mb3);
                            mvx_l0_curr_mb_out[79:64]   <= mvx_l0_final;
                            mvx_l0_curr_mb_out[95:80]   <= mvx_l0_final;
                        end                        
                    else //subMbPartIdx = 1
                        begin
							mvx_diff_to_left_c5c6 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[63:48]);
							mvx_diff_to_up_c2c6 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[79:64]);
							mvx_diff_to_up_c3c7 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[95:80]);
                            mvx_l0_curr_mb_out[111:96]   <= mvx_l0_final;
                            mvx_l0_curr_mb_out[127:112]   <= mvx_l0_final;
                        end
                        
                2:
                    if (subMbPartIdx == 0)
                        begin
							mvx_diff_to_left_a2c8 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_left_mb2);
							mvx_diff_to_up_c4c8 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[47:32]);
							mvx_diff_to_up_c5c9 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[63:48]);
                            mvx_l0_curr_mb_out[143:128]   <= mvx_l0_final;
                            mvx_l0_curr_mb_out[159:144]   <= mvx_l0_final;
                        end
                    else //subMbPartIdx = 1
                        begin
							mvx_diff_to_left_a3c12 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_left_mb3);
							mvx_diff_to_up_c8c12 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[143:128]);
							mvx_diff_to_up_c9c13 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[159:144]);
                            mvx_l0_curr_mb_out[175:160] <= mvx_l0_final;
                            mvx_l0_curr_mb_out[191:176] <= mvx_l0_final;
                        end

                3:
                    if (subMbPartIdx == 0)
                        begin
							mvx_diff_to_left_c9c10 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[159:144]);
							mvx_diff_to_up_c6c10 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[111:96]);
							mvx_diff_to_up_c7c11 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[127:112]);
                            mvx_l0_curr_mb_out[207:192]<= mvx_l0_final;
                            mvx_l0_curr_mb_out[223:208] <= mvx_l0_final;
                        end
                    else //subMbPartIdx = 1
                        begin
							mvx_diff_to_left_c13c14 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[191:176]);
							mvx_diff_to_up_c10c14 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[207:192]);
							mvx_diff_to_up_c11c15 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[223:208]);
							mv_l0_calc_done <= 1;
                            mvx_l0_curr_mb_out[239:224] <= mvx_l0_final;
                            mvx_l0_curr_mb_out[255:240] <= mvx_l0_final;
                        end
            endcase             
        else if (MbPartWidth == 4 && MbPartHeight == 8)
            case(mbPartIdx)
                0:
                    if (subMbPartIdx == 0)
                        begin
							mvx_diff_to_left_a0c0 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_left_mb0);
							mvx_diff_to_left_a1c4 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_left_mb1);
							mvx_diff_to_up_b0c0 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_up_mb0);
                            mvx_l0_curr_mb_out[15:0]     <= mvx_l0_final; 
                            mvx_l0_curr_mb_out[47:32]   <= mvx_l0_final;
                        end
                    else //subMbPartIdx = 1
                        begin
							mvx_diff_to_left_c0c1 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[15:0]);
							mvx_diff_to_left_c4c5 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[47:32]);
							mvx_diff_to_up_b1c1 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_up_mb1);
                            mvx_l0_curr_mb_out[31:16]   <= mvx_l0_final;
                            mvx_l0_curr_mb_out[63:48]   <= mvx_l0_final;
                        end
                1:
                    if (subMbPartIdx == 0)
                        begin
							mvx_diff_to_left_c1c2 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[31:16]);
							mvx_diff_to_left_c5c6 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[63:48]);
							mvx_diff_to_up_b2c2 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_up_mb2);
                            mvx_l0_curr_mb_out[79:64]   <= mvx_l0_final;
                            mvx_l0_curr_mb_out[111:96]   <= mvx_l0_final;
                        end
                    else //subMbPartIdx = 1
                        begin
							mvx_diff_to_left_c2c3 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[79:64]);
							mvx_diff_to_left_c6c7 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[111:96]);
							mvx_diff_to_up_b3c3 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_up_mb3);
                            mvx_l0_curr_mb_out[95:80]   <= mvx_l0_final;
                            mvx_l0_curr_mb_out[127:112]   <= mvx_l0_final;
                        end
                2:
                    if (subMbPartIdx == 0)
                        begin
							mvx_diff_to_left_a2c8 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_left_mb2);
							mvx_diff_to_left_a3c12 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_left_mb3);
							mvx_diff_to_up_c4c8 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[47:32]);
                            mvx_l0_curr_mb_out[143:128]   <= mvx_l0_final;
                            mvx_l0_curr_mb_out[175:160] <= mvx_l0_final;
                        end    
                    else //subMbPartIdx = 1
                        begin
							mvx_diff_to_left_c8c9 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[143:128]);
							mvx_diff_to_left_c12c13 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[175:160]);
							mvx_diff_to_up_c5c9 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[63:48]);
                            mvx_l0_curr_mb_out[159:144]   <= mvx_l0_final;
                            mvx_l0_curr_mb_out[191:176] <= mvx_l0_final;
                        end
                3:
                    if (subMbPartIdx == 0)
                        begin
							mvx_diff_to_left_c9c10 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[159:144]);
							mvx_diff_to_left_c13c14 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[191:176]);
							mvx_diff_to_up_c6c10 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[111:96]);
                            mvx_l0_curr_mb_out[207:192]<= mvx_l0_final;
                            mvx_l0_curr_mb_out[239:224] <= mvx_l0_final;
                        end    
                    else //subMbPartIdx = 1
                        begin
							mvx_diff_to_left_c10c11 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[207:192]);
							mvx_diff_to_left_c14c15 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[239:224]);
							mvx_diff_to_up_c7c11 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[127:112]);
							mv_l0_calc_done <= 1;
                            mvx_l0_curr_mb_out[223:208] <= mvx_l0_final;
                            mvx_l0_curr_mb_out[255:240] <= mvx_l0_final;
                        end
                
            endcase             
        else // MbPartWidth = 4, MbPartHeight = 4
            case(mbPartIdx)
                0:
					if (subMbPartIdx == 0) begin
						mvx_diff_to_left_a0c0 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_left_mb0);
						mvx_diff_to_up_b0c0 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_up_mb0);
                        mvx_l0_curr_mb_out[15:0]     <= mvx_l0_final; 
					end
					else if (subMbPartIdx == 1) begin
						mvx_diff_to_left_c0c1 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[15:0]);
						mvx_diff_to_up_b1c1 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_up_mb1);
                        mvx_l0_curr_mb_out[31:16]   <= mvx_l0_final;
					end
					else if (subMbPartIdx == 2)begin
						mvx_diff_to_left_a1c4 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_left_mb1);
						mvx_diff_to_up_c0c4 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[15:0]);
                        mvx_l0_curr_mb_out[47:32]   <= mvx_l0_final;
					end
					else begin//subMbPartIdx = 3
						mvx_diff_to_left_c4c5 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[47:32]);
						mvx_diff_to_up_c1c5 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[31:16]);
                        mvx_l0_curr_mb_out[63:48]   <= mvx_l0_final;
					end
                1:
					if (subMbPartIdx == 0) begin
						mvx_diff_to_left_c1c2 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[31:16]);
						mvx_diff_to_up_b2c2 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_up_mb2);
                        mvx_l0_curr_mb_out[79:64]   <= mvx_l0_final;
					end
					else if (subMbPartIdx == 1)begin
						mvx_diff_to_left_c2c3 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[79:64]);
						mvx_diff_to_up_b3c3 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_up_mb3);
                        mvx_l0_curr_mb_out[95:80]   <= mvx_l0_final;
					end
					else if (subMbPartIdx == 2)begin
						mvx_diff_to_left_c5c6 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[63:48]);
						mvx_diff_to_up_c2c6 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[79:64]);
                        mvx_l0_curr_mb_out[111:96]   <= mvx_l0_final;
					end
                    else begin//subMbPartIdx = 3
						mvx_diff_to_left_c6c7 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[111:96]);
						mvx_diff_to_up_c3c7 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[95:80]);
                        mvx_l0_curr_mb_out[127:112]   <= mvx_l0_final;
					end
                2:
					if (subMbPartIdx == 0) begin
						mvx_diff_to_left_a2c8 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_left_mb2);
						mvx_diff_to_up_c4c8 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[47:32]);
                        mvx_l0_curr_mb_out[143:128]   <= mvx_l0_final;
					end
					else if (subMbPartIdx == 1)begin
						mvx_diff_to_left_c8c9 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[143:128]);
						mvx_diff_to_up_c5c9 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[63:48]);
                        mvx_l0_curr_mb_out[159:144]   <= mvx_l0_final;
					end
					else if (subMbPartIdx == 2)begin
						mvx_diff_to_left_a3c12 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_left_mb3);
						mvx_diff_to_up_c8c12 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[143:128]);
                        mvx_l0_curr_mb_out[175:160] <= mvx_l0_final;
					end
					else begin//subMbPartIdx = 3
						mvx_diff_to_left_c12c13 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[175:160]);
						mvx_diff_to_up_c9c13 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[159:144]);
                        mvx_l0_curr_mb_out[191:176] <= mvx_l0_final;
					end
				3:begin
					if (subMbPartIdx == 0) begin
						mvx_diff_to_left_c9c10 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[159:144]);
						mvx_diff_to_up_c6c10 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[111:96]);
                        mvx_l0_curr_mb_out[207:192]<= mvx_l0_final;
					end
					else if (subMbPartIdx == 1)begin
						mvx_diff_to_left_c10c11 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[207:192]);
						mvx_diff_to_up_c7c11 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[127:112]);
                        mvx_l0_curr_mb_out[223:208] <= mvx_l0_final;
					end
					else if (subMbPartIdx == 2)begin
						mvx_diff_to_left_c13c14 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[191:176]);
						mvx_diff_to_up_c10c14 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[207:192]);
                        mvx_l0_curr_mb_out[239:224] <= mvx_l0_final;
					end
					else begin //subMbPartIdx = 3
						mvx_diff_to_left_c14c15 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[239:224]);
						mvx_diff_to_up_c11c15 <= mv_diff_abs_ge4(mvx_l0_final, mvx_l0_curr_mb_out[223:208]);
                        mvx_l0_curr_mb_out[255:240] <= mvx_l0_final;
						mv_l0_calc_done <= 1;
					end
				end
               
            endcase
		end
	end

always @(posedge clk)
if(ena) begin
	if (slice_data_state == `rst_macroblock_s) begin
        mvy_l0_curr_mb_out <= 128'b0; 
		is_mvy_all_same <= 1'b1;
		mvy_diff_to_left_a0c0 <= 0;
		mvy_diff_to_left_a1c4 <= 0;
		mvy_diff_to_left_a2c8 <= 0;
		mvy_diff_to_left_a3c12 <= 0;
		mvy_diff_to_left_c0c1 <= 0;
		mvy_diff_to_left_c4c5 <= 0;
		mvy_diff_to_left_c8c9 <= 0;
		mvy_diff_to_left_c12c13 <= 0;
		mvy_diff_to_left_c1c2 <= 0;
		mvy_diff_to_left_c5c6 <= 0;
		mvy_diff_to_left_c9c10 <= 0;
		mvy_diff_to_left_c13c14 <= 0;
		mvy_diff_to_left_c2c3 <= 0;
		mvy_diff_to_left_c6c7 <= 0;
		mvy_diff_to_left_c10c11 <= 0;
		mvy_diff_to_left_c14c15 <= 0;
		mvy_diff_to_up_b0c0 <= 0;
		mvy_diff_to_up_b1c1 <= 0;
		mvy_diff_to_up_b2c2 <= 0;
		mvy_diff_to_up_b3c3 <= 0;
		mvy_diff_to_up_c0c4 <= 0;
		mvy_diff_to_up_c1c5 <= 0;
		mvy_diff_to_up_c2c6 <= 0;
		mvy_diff_to_up_c3c7 <= 0;
		mvy_diff_to_up_c4c8 <= 0;
		mvy_diff_to_up_c5c9 <= 0;
		mvy_diff_to_up_c6c10 <= 0; 
		mvy_diff_to_up_c7c11 <= 0;
		mvy_diff_to_up_c8c12 <= 0;
		mvy_diff_to_up_c9c13 <= 0;
		mvy_diff_to_up_c10c14 <= 0;
		mvy_diff_to_up_c11c15 <= 0;
    end
    else if ((slice_data_state == `mb_pred && mb_pred_state == `mv_calc_l0_s && mv_calc_valid) 
        || (slice_data_state == `sub_mb_pred && sub_mb_pred_state == `sub_mv_calc_l0_s && mv_calc_valid) 
		|| (slice_data_state == `skip_run_save_mv) )begin
		if (MbPartWidth == 16 && MbPartHeight == 16)
            if ( slice_data_state == `skip_run_save_mv) //temporary
                begin
					mvy_diff_to_left_a0c0 <= mv_diff_abs_ge4(mvy_l0, mvy_l0_left_mb0);
					mvy_diff_to_left_a1c4 <= mv_diff_abs_ge4(mvy_l0, mvy_l0_left_mb1);
					mvy_diff_to_left_a2c8 <= mv_diff_abs_ge4(mvy_l0, mvy_l0_left_mb2);
					mvy_diff_to_left_a3c12 <= mv_diff_abs_ge4(mvy_l0, mvy_l0_left_mb3);
					mvy_diff_to_up_b0c0 <= mv_diff_abs_ge4(mvy_l0, mvy_l0_up_mb0);
					mvy_diff_to_up_b1c1 <= mv_diff_abs_ge4(mvy_l0, mvy_l0_up_mb1);
					mvy_diff_to_up_b2c2 <= mv_diff_abs_ge4(mvy_l0, mvy_l0_up_mb2);
					mvy_diff_to_up_b3c3 <= mv_diff_abs_ge4(mvy_l0, mvy_l0_up_mb3);
                    mvy_l0_curr_mb_out[255:0]    <= {16{mvy_l0}}; 
                end
            else
                begin
					mvy_diff_to_left_a0c0 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_left_mb0);
					mvy_diff_to_left_a1c4 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_left_mb1);
					mvy_diff_to_left_a2c8 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_left_mb2);
					mvy_diff_to_left_a3c12 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_left_mb3);
					mvy_diff_to_up_b0c0 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_up_mb0);
					mvy_diff_to_up_b1c1 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_up_mb1);
					mvy_diff_to_up_b2c2 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_up_mb2);
					mvy_diff_to_up_b3c3 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_up_mb3);
                    mvy_l0_curr_mb_out[15:0]    <= mvy_l0_final; 
                    mvy_l0_curr_mb_out[31:16]   <= mvy_l0_final;
                    mvy_l0_curr_mb_out[47:32]   <= mvy_l0_final;
                    mvy_l0_curr_mb_out[63:48]   <= mvy_l0_final;
                    mvy_l0_curr_mb_out[79:64]   <= mvy_l0_final;
                    mvy_l0_curr_mb_out[95:80]   <= mvy_l0_final;
                    mvy_l0_curr_mb_out[111:96]  <= mvy_l0_final;
                    mvy_l0_curr_mb_out[127:112] <= mvy_l0_final;
                    mvy_l0_curr_mb_out[143:128] <= mvy_l0_final;
                    mvy_l0_curr_mb_out[159:144] <= mvy_l0_final;
                    mvy_l0_curr_mb_out[175:160] <= mvy_l0_final;
                    mvy_l0_curr_mb_out[191:176] <= mvy_l0_final;
                    mvy_l0_curr_mb_out[207:192] <= mvy_l0_final;
                    mvy_l0_curr_mb_out[223:208] <= mvy_l0_final;
                    mvy_l0_curr_mb_out[239:224] <= mvy_l0_final;
                    mvy_l0_curr_mb_out[255:240] <= mvy_l0_final;
                end            
        else if (MbPartWidth == 16 && MbPartHeight == 8)
            if (mbPartIdx == 0)                
                begin
					mvy_diff_to_left_a0c0 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_left_mb0);
					mvy_diff_to_left_a1c4 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_left_mb1);
					mvy_diff_to_up_b0c0 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_up_mb0);
					mvy_diff_to_up_b1c1 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_up_mb1);
					mvy_diff_to_up_b2c2 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_up_mb2);
					mvy_diff_to_up_b3c3 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_up_mb3);
					mvy_l0_cmp <= mvy_l0_final;
                    mvy_l0_curr_mb_out[15:0]     <= mvy_l0_final; 
                    mvy_l0_curr_mb_out[31:16]   <= mvy_l0_final;
                    mvy_l0_curr_mb_out[47:32]   <= mvy_l0_final;
                    mvy_l0_curr_mb_out[63:48]   <= mvy_l0_final;
                    mvy_l0_curr_mb_out[79:64]   <= mvy_l0_final;
                    mvy_l0_curr_mb_out[95:80]   <= mvy_l0_final;
                    mvy_l0_curr_mb_out[111:96]   <= mvy_l0_final;
                    mvy_l0_curr_mb_out[127:112]   <= mvy_l0_final;
                end                
            else //mbPartIdx = 1
                begin
					mvy_diff_to_left_a2c8 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_left_mb2);
					mvy_diff_to_left_a3c12 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_left_mb3);
					mvy_diff_to_up_c4c8 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[47:32]);
					mvy_diff_to_up_c5c9 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[63:48]);
					mvy_diff_to_up_c6c10 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[111:96]);
					mvy_diff_to_up_c7c11 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[127:112]);
					is_mvy_all_same <= is_mvy_all_same && (mvy_l0_cmp ==  mvy_l0_final);
                    mvy_l0_curr_mb_out[143:128]   <= mvy_l0_final;
                    mvy_l0_curr_mb_out[159:144]   <= mvy_l0_final;
                    mvy_l0_curr_mb_out[175:160] <= mvy_l0_final;
                    mvy_l0_curr_mb_out[191:176] <= mvy_l0_final;
                    mvy_l0_curr_mb_out[207:192]<= mvy_l0_final;
                    mvy_l0_curr_mb_out[223:208] <= mvy_l0_final;
                    mvy_l0_curr_mb_out[239:224] <= mvy_l0_final;
                    mvy_l0_curr_mb_out[255:240] <= mvy_l0_final;
                end
        else if (MbPartWidth == 8 && MbPartHeight == 16)
            if (mbPartIdx == 0)
                begin
					mvy_diff_to_left_a0c0 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_left_mb0);
					mvy_diff_to_left_a1c4 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_left_mb1);
					mvy_diff_to_left_a2c8 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_left_mb2);
					mvy_diff_to_left_a3c12 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_left_mb3);
					mvy_diff_to_up_b0c0 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_up_mb0);
					mvy_diff_to_up_b1c1 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_up_mb1);
					mvy_l0_cmp <= mvy_l0_final;
                    mvy_l0_curr_mb_out[15:0]     <= mvy_l0_final; 
                    mvy_l0_curr_mb_out[31:16]    <= mvy_l0_final;
                    mvy_l0_curr_mb_out[47:32]   <= mvy_l0_final;
                    mvy_l0_curr_mb_out[63:48]   <= mvy_l0_final;
                    mvy_l0_curr_mb_out[143:128]   <= mvy_l0_final;
                    mvy_l0_curr_mb_out[159:144]   <= mvy_l0_final;
                    mvy_l0_curr_mb_out[175:160]   <= mvy_l0_final;
                    mvy_l0_curr_mb_out[191:176]   <= mvy_l0_final;
                end          
            else //mbPartIdx = 1                
                begin
					mvy_diff_to_left_c1c2 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[31:16]);
					mvy_diff_to_left_c5c6 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[63:48]);
					mvy_diff_to_left_c9c10 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[159:144]);
					mvy_diff_to_left_c13c14 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[191:176]);
					mvy_diff_to_up_b2c2 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_up_mb2);
					mvy_diff_to_up_b3c3 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_up_mb3);
					is_mvy_all_same <= is_mvy_all_same && (mvy_l0_cmp ==  mvy_l0_final);
                    mvy_l0_curr_mb_out[79:64]   <= mvy_l0_final;
                    mvy_l0_curr_mb_out[95:80]   <= mvy_l0_final;
                    mvy_l0_curr_mb_out[111:96]   <= mvy_l0_final;
                    mvy_l0_curr_mb_out[127:112]   <= mvy_l0_final;
                    mvy_l0_curr_mb_out[207:192]<= mvy_l0_final;
                    mvy_l0_curr_mb_out[223:208] <= mvy_l0_final;
                    mvy_l0_curr_mb_out[239:224] <= mvy_l0_final;
                    mvy_l0_curr_mb_out[255:240] <= mvy_l0_final;
                end
        else if( MbPartWidth == 8 && MbPartHeight == 8)
            case(mbPartIdx)
                0:
                    begin
						mvy_diff_to_left_a0c0 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_left_mb0);
						mvy_diff_to_left_a1c4 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_left_mb1);
						mvy_diff_to_up_b0c0 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_up_mb0);
						mvy_diff_to_up_b1c1 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_up_mb1);
						mvy_l0_cmp <= mvy_l0_final;
                        mvy_l0_curr_mb_out[15:0]     <= mvy_l0_final; 
                        mvy_l0_curr_mb_out[31:16]    <= mvy_l0_final;
                        mvy_l0_curr_mb_out[47:32]   <= mvy_l0_final;
                        mvy_l0_curr_mb_out[63:48]   <= mvy_l0_final;
                    end
                1:
                    begin
						mvy_diff_to_left_c1c2 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[31:16]);
						mvy_diff_to_left_c5c6 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[63:48]);
						mvy_diff_to_up_b2c2 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_up_mb2);
						mvy_diff_to_up_b3c3 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_up_mb3);
						is_mvy_all_same <= is_mvy_all_same && (mvy_l0_cmp ==  mvy_l0_final);
                        mvy_l0_curr_mb_out[79:64]   <= mvy_l0_final;
                        mvy_l0_curr_mb_out[95:80]   <= mvy_l0_final;
                        mvy_l0_curr_mb_out[111:96]   <= mvy_l0_final;
                        mvy_l0_curr_mb_out[127:112]   <= mvy_l0_final;
                    end
                2:
                    begin
						mvy_diff_to_left_a2c8 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_left_mb2);
						mvy_diff_to_left_a3c12 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_left_mb3);
						mvy_diff_to_up_c4c8 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[47:32]);
						mvy_diff_to_up_c5c9 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[63:48]);
						is_mvy_all_same <= is_mvy_all_same && (mvy_l0_cmp ==  mvy_l0_final);
                        mvy_l0_curr_mb_out[143:128]   <= mvy_l0_final;
                        mvy_l0_curr_mb_out[159:144]   <= mvy_l0_final;
                        mvy_l0_curr_mb_out[175:160] <= mvy_l0_final;
                        mvy_l0_curr_mb_out[191:176] <= mvy_l0_final;
                    end
                3:                   
                    begin
						mvy_diff_to_left_c9c10 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[159:144]);
						mvy_diff_to_left_c13c14 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[191:176]);
						mvy_diff_to_up_c6c10 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[111:96]);
						mvy_diff_to_up_c7c11 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[127:112]);
						is_mvy_all_same <= is_mvy_all_same && (mvy_l0_cmp ==  mvy_l0_final);
                        mvy_l0_curr_mb_out[207:192] <= mvy_l0_final;
                        mvy_l0_curr_mb_out[223:208] <= mvy_l0_final;
                        mvy_l0_curr_mb_out[239:224] <= mvy_l0_final;
                        mvy_l0_curr_mb_out[255:240] <= mvy_l0_final;
                    end
                default: mvy_l0_curr_mb_out <= 0;
            endcase  
        else if (MbPartWidth == 8 && MbPartHeight == 4)
            case(mbPartIdx)
                0:
                    if (subMbPartIdx == 0)
                        begin
							mvy_diff_to_left_a0c0 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_left_mb0);
							mvy_diff_to_up_b0c0 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_up_mb0);
							mvy_diff_to_up_b1c1 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_up_mb1);
                            mvy_l0_curr_mb_out[15:0]     <= mvy_l0_final; 
                            mvy_l0_curr_mb_out[31:16]   <= mvy_l0_final;
                        end     
                    else // subMbPartIdx = 1
                        begin
							mvy_diff_to_left_a1c4 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_left_mb1);
							mvy_diff_to_up_c0c4 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[15:0]);
							mvy_diff_to_up_c1c5 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[31:16]);
                            mvy_l0_curr_mb_out[47:32]   <= mvy_l0_final;
                            mvy_l0_curr_mb_out[63:48]   <= mvy_l0_final;
                        end                   
                1:
                    if (subMbPartIdx == 0)
                        begin
							mvy_diff_to_left_c1c2 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[31:16]);
							mvy_diff_to_up_b2c2 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_up_mb2);
							mvy_diff_to_up_b3c3 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_up_mb3);
                            mvy_l0_curr_mb_out[79:64]   <= mvy_l0_final;
                            mvy_l0_curr_mb_out[95:80]   <= mvy_l0_final;
                        end                        
                    else //subMbPartIdx = 1
                        begin
							mvy_diff_to_left_c5c6 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[63:48]);
							mvy_diff_to_up_c2c6 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[79:64]);
							mvy_diff_to_up_c3c7 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[95:80]);
                            mvy_l0_curr_mb_out[111:96]   <= mvy_l0_final;
                            mvy_l0_curr_mb_out[127:112]   <= mvy_l0_final;
                        end
                        
                2:
                    if (subMbPartIdx == 0)
                        begin
							mvy_diff_to_left_a2c8 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_left_mb2);
							mvy_diff_to_up_c4c8 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[47:32]);
							mvy_diff_to_up_c5c9 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[63:48]);
                            mvy_l0_curr_mb_out[143:128]   <= mvy_l0_final;
                            mvy_l0_curr_mb_out[159:144]   <= mvy_l0_final;
                        end
                    else //subMbPartIdx = 1
                        begin
							mvy_diff_to_left_a3c12 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_left_mb3);
							mvy_diff_to_up_c8c12 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[143:128]);
							mvy_diff_to_up_c9c13 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[159:144]);
                            mvy_l0_curr_mb_out[175:160] <= mvy_l0_final;
                            mvy_l0_curr_mb_out[191:176] <= mvy_l0_final;
                        end

                3:
                    if (subMbPartIdx == 0)
                        begin
							mvy_diff_to_left_c9c10 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[159:144]);
							mvy_diff_to_up_c6c10 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[111:96]);
							mvy_diff_to_up_c7c11 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[127:112]);
                            mvy_l0_curr_mb_out[207:192]<= mvy_l0_final;
                            mvy_l0_curr_mb_out[223:208] <= mvy_l0_final;
                        end
                    else //subMbPartIdx = 1
                        begin
							mvy_diff_to_left_c13c14 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[191:176]);
							mvy_diff_to_up_c10c14 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[207:192]);
							mvy_diff_to_up_c11c15 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[223:208]);
                            mvy_l0_curr_mb_out[239:224] <= mvy_l0_final;
                            mvy_l0_curr_mb_out[255:240] <= mvy_l0_final;
                        end
            endcase             
        else if (MbPartWidth == 4 && MbPartHeight == 8)
            case(mbPartIdx)
                0:
                    if (subMbPartIdx == 0)
                        begin
							mvy_diff_to_left_a0c0 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_left_mb0);
							mvy_diff_to_left_a1c4 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_left_mb1);
							mvy_diff_to_up_b0c0 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_up_mb0);
                            mvy_l0_curr_mb_out[15:0]     <= mvy_l0_final; 
                            mvy_l0_curr_mb_out[47:32]   <= mvy_l0_final;
                        end
                    else //subMbPartIdx = 1
                        begin
							mvy_diff_to_left_c0c1 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[15:0]);
							mvy_diff_to_left_c4c5 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[47:32]);
							mvy_diff_to_up_b1c1 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_up_mb1);
                            mvy_l0_curr_mb_out[31:16]   <= mvy_l0_final;
                            mvy_l0_curr_mb_out[63:48]   <= mvy_l0_final;
                        end
                1:
                    if (subMbPartIdx == 0)
                        begin
							mvy_diff_to_left_c1c2 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[31:16]);
							mvy_diff_to_left_c5c6 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[63:48]);
							mvy_diff_to_up_b2c2 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_up_mb2);
                            mvy_l0_curr_mb_out[79:64]   <= mvy_l0_final;
                            mvy_l0_curr_mb_out[111:96]   <= mvy_l0_final;
                        end
                    else //subMbPartIdx = 1
                        begin
							mvy_diff_to_left_c2c3 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[79:64]);
							mvy_diff_to_left_c6c7 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[111:96]);
							mvy_diff_to_up_b3c3 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_up_mb3);
                            mvy_l0_curr_mb_out[95:80]   <= mvy_l0_final;
                            mvy_l0_curr_mb_out[127:112]   <= mvy_l0_final;
                        end
                2:
                    if (subMbPartIdx == 0)
                        begin
							mvy_diff_to_left_a2c8 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_left_mb2);
							mvy_diff_to_left_a3c12 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_left_mb3);
							mvy_diff_to_up_c4c8 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[47:32]);
                            mvy_l0_curr_mb_out[143:128]   <= mvy_l0_final;
                            mvy_l0_curr_mb_out[175:160] <= mvy_l0_final;
                        end    
                    else //subMbPartIdx = 1
                        begin
							mvy_diff_to_left_c8c9 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[143:128]);
							mvy_diff_to_left_c12c13 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[175:160]);
							mvy_diff_to_up_c5c9 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[63:48]);
                            mvy_l0_curr_mb_out[159:144]   <= mvy_l0_final;
                            mvy_l0_curr_mb_out[191:176] <= mvy_l0_final;
                        end
                3:
                    if (subMbPartIdx == 0)
                        begin
							mvy_diff_to_left_c9c10 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[159:144]);
							mvy_diff_to_left_c13c14 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[191:176]);
							mvy_diff_to_up_c6c10 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[111:96]);
                            mvy_l0_curr_mb_out[207:192]<= mvy_l0_final;
                            mvy_l0_curr_mb_out[239:224] <= mvy_l0_final;
                        end    
                    else //subMbPartIdx = 1
                        begin
							mvy_diff_to_left_c10c11 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[207:192]);
							mvy_diff_to_left_c14c15 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[239:224]);
							mvy_diff_to_up_c7c11 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[127:112]);
                            mvy_l0_curr_mb_out[223:208] <= mvy_l0_final;
                            mvy_l0_curr_mb_out[255:240] <= mvy_l0_final;
                        end
                
            endcase             
        else // MbPartWidth = 4, MbPartHeight = 4
            case(mbPartIdx)
                0:
					if (subMbPartIdx == 0) begin
						mvy_diff_to_left_a0c0 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_left_mb0);
						mvy_diff_to_up_b0c0 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_up_mb0);
                        mvy_l0_curr_mb_out[15:0]     <= mvy_l0_final; 
					end
					else if (subMbPartIdx == 1) begin
						mvy_diff_to_left_c0c1 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[15:0]);
						mvy_diff_to_up_b1c1 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_up_mb1);
                        mvy_l0_curr_mb_out[31:16]   <= mvy_l0_final;
					end
					else if (subMbPartIdx == 2)begin
						mvy_diff_to_left_a1c4 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_left_mb1);
						mvy_diff_to_up_c0c4 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[15:0]);
                        mvy_l0_curr_mb_out[47:32]   <= mvy_l0_final;
					end
					else begin//subMbPartIdx = 3
						mvy_diff_to_left_c4c5 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[47:32]);
						mvy_diff_to_up_c1c5 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[31:16]);
                        mvy_l0_curr_mb_out[63:48]   <= mvy_l0_final;
					end
                1:
					if (subMbPartIdx == 0) begin
						mvy_diff_to_left_c1c2 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[31:16]);
						mvy_diff_to_up_b2c2 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_up_mb2);
                        mvy_l0_curr_mb_out[79:64]   <= mvy_l0_final;
					end
					else if (subMbPartIdx == 1)begin
						mvy_diff_to_left_c2c3 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[79:64]);
						mvy_diff_to_up_b3c3 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_up_mb3);
                        mvy_l0_curr_mb_out[95:80]   <= mvy_l0_final;
					end
					else if (subMbPartIdx == 2)begin
						mvy_diff_to_left_c5c6 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[63:48]);
						mvy_diff_to_up_c2c6 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[79:64]);
                        mvy_l0_curr_mb_out[111:96]   <= mvy_l0_final;
					end
                    else begin//subMbPartIdx = 3
						mvy_diff_to_left_c6c7 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[111:96]);
						mvy_diff_to_up_c3c7 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[95:80]);
                        mvy_l0_curr_mb_out[127:112]   <= mvy_l0_final;
					end
                2:
					if (subMbPartIdx == 0) begin
						mvy_diff_to_left_a2c8 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_left_mb2);
						mvy_diff_to_up_c4c8 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[47:32]);
                        mvy_l0_curr_mb_out[143:128]   <= mvy_l0_final;
					end
					else if (subMbPartIdx == 1)begin
						mvy_diff_to_left_c8c9 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[143:128]);
						mvy_diff_to_up_c5c9 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[63:48]);
                        mvy_l0_curr_mb_out[159:144]   <= mvy_l0_final;
					end
					else if (subMbPartIdx == 2)begin
						mvy_diff_to_left_a3c12 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_left_mb3);
						mvy_diff_to_up_c8c12 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[143:128]);
                        mvy_l0_curr_mb_out[175:160] <= mvy_l0_final;
					end
					else begin//subMbPartIdx = 3
						mvy_diff_to_left_c12c13 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[175:160]);
						mvy_diff_to_up_c9c13 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[159:144]);
                        mvy_l0_curr_mb_out[191:176] <= mvy_l0_final;
					end
				3:begin
					if (subMbPartIdx == 0) begin
						mvy_diff_to_left_c9c10 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[159:144]);
						mvy_diff_to_up_c6c10 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[111:96]);
                        mvy_l0_curr_mb_out[207:192]<= mvy_l0_final;
					end
					else if (subMbPartIdx == 1)begin
						mvy_diff_to_left_c10c11 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[207:192]);
						mvy_diff_to_up_c7c11 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[127:112]);
                        mvy_l0_curr_mb_out[223:208] <= mvy_l0_final;
					end
					else if (subMbPartIdx == 2)begin
						mvy_diff_to_left_c13c14 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[191:176]);
						mvy_diff_to_up_c10c14 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[207:192]);
                        mvy_l0_curr_mb_out[239:224] <= mvy_l0_final;
					end
					else begin //subMbPartIdx = 3
						mvy_diff_to_left_c14c15 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[239:224]);
						mvy_diff_to_up_c11c15 <= mv_diff_abs_ge4(mvy_l0_final, mvy_l0_curr_mb_out[223:208]);
                        mvy_l0_curr_mb_out[255:240] <= mvy_l0_final;
					end
				end
               
            endcase
		end
	end

	
always @(posedge clk)
    if (slice_data_state == `residual && (residual_state == `Intra16x16ACLevel_s ||
                                          residual_state == `LumaLevel_s)
        && residual_started == 1 && residual_valid == 1)        
        case(luma4x4BlkIdx)
            0:  nC_curr_mb_out[7:0] <= TotalCoeff;
            1:  nC_curr_mb_out[15:8] <= TotalCoeff;
            2:  nC_curr_mb_out[23:16] <= TotalCoeff;
            3:  nC_curr_mb_out[31:24] <= TotalCoeff;
            4:  nC_curr_mb_out[39:32] <= TotalCoeff;
            5:  nC_curr_mb_out[47:40] <= TotalCoeff;
            6:  nC_curr_mb_out[55:48] <= TotalCoeff;
            7:  nC_curr_mb_out[63:56] <= TotalCoeff;
            8:  nC_curr_mb_out[71:64] <= TotalCoeff;
            9:  nC_curr_mb_out[79:72] <= TotalCoeff;
            10: nC_curr_mb_out[87:80] <= TotalCoeff;
            11: nC_curr_mb_out[95:88] <= TotalCoeff;
            12: nC_curr_mb_out[103:96] <= TotalCoeff;
            13: nC_curr_mb_out[111:104] <= TotalCoeff;
            14: nC_curr_mb_out[119:112] <= TotalCoeff;
            15: nC_curr_mb_out[127:120] <= TotalCoeff;
        endcase
    else if (slice_data_state == `residual && (residual_state == `Intra16x16ACLevel_0_s || 
                                               residual_state == `LumaLevel_0_s))
        case(luma4x4BlkIdx)
            0:  nC_curr_mb_out[31:0] <= 0;
            4:  nC_curr_mb_out[63:32] <= 0;
            8:  nC_curr_mb_out[95:64] <= 0;
            12: nC_curr_mb_out[127:96] <= 0;
        endcase
    else if (slice_data_state == `residual &&  residual_state == `ChromaACLevel_Cb_s && 
        residual_started == 1 && residual_valid == 1)
        case(chroma4x4BlkIdx)
            0: nC_cb_curr_mb_out[7:0] <= TotalCoeff;
            1: nC_cb_curr_mb_out[15:8] <= TotalCoeff;
            2: nC_cb_curr_mb_out[23:16] <= TotalCoeff;
            3: nC_cb_curr_mb_out[31:24] <= TotalCoeff;      
        endcase
   else if (slice_data_state == `residual && residual_state == `ChromaACLevel_Cr_s &&
        residual_started == 1 && residual_valid == 1)
        case(chroma4x4BlkIdx)
            0: nC_cr_curr_mb_out[7:0] <= TotalCoeff;
            1: nC_cr_curr_mb_out[15:8] <= TotalCoeff;
            2: nC_cr_curr_mb_out[23:16] <= TotalCoeff;
            3: nC_cr_curr_mb_out[31:24] <= TotalCoeff;      
        endcase
    else if (slice_data_state == `residual && (residual_state == `ChromaACLevel_Cb_0_s || residual_state == `ChromaACLevel_Cr_0_s))
        begin nC_cb_curr_mb_out[31:0] <= 0;   nC_cr_curr_mb_out[31:0] <= 0; end
    else if (slice_data_state == `mb_qp_delta_s && CBP_luma_reg == 0 && CBP_chroma_reg == 0 && mb_pred_mode != `mb_pred_mode_I16MB ||
    slice_data_state == `skip_run_duration)
        begin
            nC_curr_mb_out <= 0;
            nC_cb_curr_mb_out <= 0;
            nC_cr_curr_mb_out <= 0;
        end

/*
function [15:0] abs_ab;
	input [15:0] a;
	input [15:0] b;
	if (a >= b)
		abs_ab = a - b;
	else
		abs_ab = b - a;
endfunction
*/

//deblocking
reg [3:0] df_qp_thresh;
reg df_qp_le_than_thresh;
reg df_v_start;
reg df_h_start;

always @(*)begin
	if (chroma_qp_index_offset_pps_in)
		df_qp_thresh <= 15 - (slice_alpha_c0_offset_div2 <<< 1) - chroma_qp_index_offset_pps_in;
	else
		df_qp_thresh <= 15 - (slice_alpha_c0_offset_div2 <<< 1);
end

always @(posedge clk)
if (blk4x4_counter_sum == 20 && sum_valid) begin
	if (chroma_qp_index_offset_pps_in > 0)
		df_qp_thresh <= 15 - (slice_alpha_c0_offset_div2 <<< 1) - chroma_qp_index_offset_pps_in;
	else
		df_qp_thresh <= 15 - (slice_alpha_c0_offset_div2 <<< 1);


	if (mb_x_out == 0 || disable_deblocking_filter_idc == 2 && ~is_in_same_slice[3])
		df_v_start <= 1;
	else
		df_v_start <= 0;
	
	if (mb_y_out == 0 || disable_deblocking_filter_idc == 2 && ~is_in_same_slice[1])
		df_h_start <= 1;
	else
		df_h_start <= 0;
end

always @(posedge clk or negedge rst_n)
if (~rst_n) begin
	df_qp0 <= 0;
	df_qp1 <= 0;
	df_qp2 <= 0;
	df_qp3 <= 0;
	df_qp4 <= 0;
	df_qp5 <= 0;
end
else if (blk4x4_counter_sum == 21 && sum_valid) begin
	if (qp <= df_qp_thresh 
		&& (mb_x_out == 0 || ((qp + qp_left_mb + 1) >> 1) <= df_qp_thresh) 
		&& (mb_y_out == 0 || ((qp + qp_up + 1) >> 1) <= df_qp_thresh) )
		df_qp_le_than_thresh <= 1'b1;
	else
		df_qp_le_than_thresh <= 1'b0;

	df_qp0 <= qp[5:0];
	df_qp3 <= qp_c[5:0];
	if (df_v_start == 1)
		df_qp2 <= qp[5:0];
	else
		df_qp2 <= (qp_left_mb[5:0] + qp[5:0] + 1) >> 1;
		
	if (df_h_start == 1)
		df_qp1 <= qp[5:0];
	else
		df_qp1 <= (qp_up[5:0] + qp[5:0] + 1) >> 1;
	
	if (df_v_start == 1)
		df_qp5 <= qp_c[5:0];
	else
		df_qp5 <= (qp_c_left_mb[5:0] + qp_c[5:0] + 1) >> 1;
		
	if (df_h_start == 1)
		df_qp4 <= qp_c[5:0];
	else
		df_qp4 <= (qp_c_up[5:0] + qp_c[5:0] + 1) >> 1;
end

always @(posedge clk) begin
	deblock_start <= 1'b0;
	if (blk4x4_counter_sum ==21 && sum_valid)begin
		bs_vertical[11:0] <= 0;
		bs_vertical[23:12] <= 0;
		bs_vertical[35:24] <= 0;
		bs_vertical[47:36] <= 0;
	end
	else if (ena && slice_data_state == `pre_store_to_fpga_ram && prev_mb_deblocking_done_or_mb0) begin
		deblock_start <= 1'b1;
		if(df_qp_le_than_thresh || disable_deblocking_filter_idc == 1)begin
				bs_vertical <= bs_vertical;
		end
		else if (mb_pred_mode == `mb_pred_mode_I4MB || mb_pred_mode == `mb_pred_mode_I16MB)begin
			bs_vertical[11:0] <= {3'd3,3'd3,3'd3,3'd4};
			bs_vertical[23:12] <= {3'd3,3'd3,3'd3,3'd4};
			bs_vertical[35:24] <= {3'd3,3'd3,3'd3,3'd4};
			bs_vertical[47:36] <= {3'd3,3'd3,3'd3,3'd4};
			if (df_v_start) begin
				bs_vertical[2:0] <= 3'd0;
				bs_vertical[14:12] <= 3'd0;
				bs_vertical[26:24] <= 3'd0;
				bs_vertical[38:36] <= 3'd0;
			end
		end
		else begin	
			if (df_v_start) begin
				bs_vertical[2:0] <= 3'd0;
				bs_vertical[14:12] <= 3'd0;
				bs_vertical[26:24] <= 3'd0;
				bs_vertical[38:36] <= 3'd0;
			end
			else if(intra_mode_left_mb)begin
				bs_vertical[2:0] <= 3'd4;
				bs_vertical[14:12] <= 3'd4;
				bs_vertical[26:24] <= 3'd4;
				bs_vertical[38:36] <= 3'd4;
			end 
			else begin
				if (nC_curr_mb_out[7:0] || nC_left_mb_out[7:0])
					bs_vertical[2:0] <= 3'd2;
				else if (ref_idx_l0_curr_mb_out[2:0] != ref_idx_l0_left_mb_out[2:0] || 
					mvx_diff_to_left_a0c0 || mvy_diff_to_left_a0c0 )
					bs_vertical[2:0] <= 3'd1;

				if (nC_curr_mb_out[23:16] || nC_left_mb_out[15:8])
					bs_vertical[14:12] <= 3'd2;
				else if (ref_idx_l0_curr_mb_out[2:0] != ref_idx_l0_left_mb_out[2:0] || 
					mvx_diff_to_left_a1c4 || mvy_diff_to_left_a1c4 )
					bs_vertical[14:12] <= 3'd1;

				if (nC_curr_mb_out[71:64] || nC_left_mb_out[23:16])
					bs_vertical[26:24] <= 3'd2;
				else if (ref_idx_l0_curr_mb_out[8:6] != ref_idx_l0_left_mb_out[5:3] || 
					mvx_diff_to_left_a2c8 || mvy_diff_to_left_a2c8 )
					bs_vertical[26:24] <= 3'd1;
				
				if (nC_curr_mb_out[87:80] || nC_left_mb_out[31:24])
					bs_vertical[38:36] <= 3'd2;
				else if (ref_idx_l0_curr_mb_out[8:6] != ref_idx_l0_left_mb_out[5:3] || 
					mvx_diff_to_left_a3c12 || mvy_diff_to_left_a3c12)
					bs_vertical[38:36] <= 3'd1;
			end // blk4x4 x == 0

			if (nC_curr_mb_out[15:8] || nC_curr_mb_out[7:0])
				bs_vertical[5:3] <= 3'd2;
			else if (
				mvx_diff_to_left_c0c1 || mvy_diff_to_left_c0c1)
				bs_vertical[5:3] <= 3'd1;

			if (nC_curr_mb_out[31:24] || nC_curr_mb_out[23:16])
				bs_vertical[17:15] <= 3'd2;
			else if (
				mvx_diff_to_left_c4c5 || mvy_diff_to_left_c4c5)
				bs_vertical[17:15] <= 3'd1;

			if (nC_curr_mb_out[79:72] || nC_curr_mb_out[71:64])
				bs_vertical[29:27] <= 3'd2;
			else if (
				mvx_diff_to_left_c8c9 || mvy_diff_to_left_c8c9)
				bs_vertical[29:27] <= 3'd1;

			if (nC_curr_mb_out[95:88] || nC_curr_mb_out[87:80])
				bs_vertical[42:39] <= 3'd2;
			else if (
				mvx_diff_to_left_c12c13 || mvy_diff_to_left_c12c13)
				bs_vertical[42:39] <= 3'd1; //end blk4x4 x == 1

			if (nC_curr_mb_out[39:32] || nC_curr_mb_out[15:8])
				bs_vertical[8:6] <= 3'd2;
			else if (ref_idx_l0_curr_mb_out[5:3] != ref_idx_l0_curr_mb_out[2:0] || 
				mvx_diff_to_left_c1c2 || mvy_diff_to_left_c1c2)
				bs_vertical[8:6] <= 3'd1;

			if (nC_curr_mb_out[55:48] || nC_curr_mb_out[31:24])
				bs_vertical[20:18] <= 3'd2;
			else if (ref_idx_l0_curr_mb_out[5:3] != ref_idx_l0_curr_mb_out[2:0] || 
				mvx_diff_to_left_c5c6 || mvy_diff_to_left_c5c6)
				bs_vertical[20:18] <= 3'd1;

			if (nC_curr_mb_out[103:96] || nC_curr_mb_out[79:72])
				bs_vertical[32:30] <= 3'd2;
			else if (ref_idx_l0_curr_mb_out[11:9] != ref_idx_l0_curr_mb_out[8:6] || 
				mvx_diff_to_left_c9c10 || mvy_diff_to_left_c9c10)
				bs_vertical[32:30] <= 3'd1;

			if (nC_curr_mb_out[119:112] || nC_curr_mb_out[95:88])
				bs_vertical[44:42] <= 3'd2;
			else if (ref_idx_l0_curr_mb_out[11:9] != ref_idx_l0_curr_mb_out[8:6] || 
				mvx_diff_to_left_c13c14 || mvy_diff_to_left_c13c14)
				bs_vertical[44:42] <= 3'd1; //end blk4x4 x == 2

			if (nC_curr_mb_out[47:40] || nC_curr_mb_out[39:32])
				bs_vertical[11:9] <= 3'd2;
			else if (
				mvx_diff_to_left_c2c3 || mvy_diff_to_left_c2c3)
				bs_vertical[11:9] <= 3'd1;

			if (nC_curr_mb_out[63:56] || nC_curr_mb_out[55:48])
				bs_vertical[23:21] <= 3'd2;
			else if (
				mvx_diff_to_left_c6c7 || mvy_diff_to_left_c6c7)
				bs_vertical[23:21] <= 3'd1;

			if (nC_curr_mb_out[111:104] || nC_curr_mb_out[103:96])
				bs_vertical[35:33] <= 3'd2;
			else if (
				mvx_diff_to_left_c10c11 || mvy_diff_to_left_c10c11)
				bs_vertical[35:33] <= 3'd1;

			if (nC_curr_mb_out[127:120] || nC_curr_mb_out[119:112])
				bs_vertical[47:45] <= 3'd2;
			else if (
				mvx_diff_to_left_c14c15 || mvy_diff_to_left_c14c15)
				bs_vertical[47:45] <= 3'd1; //end blk4x4 x == 3
		end
	end

end

always @(posedge clk) begin
	if (blk4x4_counter_sum == 21 && sum_valid)begin
		bs_horizontal[11:0] <= 0;
		bs_horizontal[23:12] <= 0;
		bs_horizontal[35:24] <= 0;
		bs_horizontal[47:36] <= 0;
	end
	else if (ena && slice_data_state == `pre_store_to_fpga_ram && prev_mb_deblocking_done_or_mb0) begin
		if(df_qp_le_than_thresh  || disable_deblocking_filter_idc == 1)begin
				bs_horizontal <= bs_horizontal;
		end
		else if (mb_pred_mode == `mb_pred_mode_I4MB || mb_pred_mode == `mb_pred_mode_I16MB)begin
			bs_horizontal[11:0] <= {3'd4,3'd4,3'd4,3'd4};
			bs_horizontal[23:12] <= {3'd3,3'd3,3'd3,3'd3};
			bs_horizontal[35:24] <= {3'd3,3'd3,3'd3,3'd3};
			bs_horizontal[47:36] <= {3'd3,3'd3,3'd3,3'd3};
			if (df_h_start)begin
				bs_horizontal[2:0] <= 3'd0;
				bs_horizontal[5:3] <= 3'd0;
				bs_horizontal[8:6] <= 3'd0;
				bs_horizontal[11:9] <= 3'd0;
			end
		end
		else begin	
			if (df_h_start)begin
				bs_horizontal[2:0] <= 3'd0;
				bs_horizontal[5:3] <= 3'd0;
				bs_horizontal[8:6] <= 3'd0;
				bs_horizontal[11:9] <= 3'd0;
			end
			else if(intra_mode_up_mb)begin
				bs_horizontal[2:0] <= 3'd4;
				bs_horizontal[5:3] <= 3'd4;
				bs_horizontal[8:6] <= 3'd4;
				bs_horizontal[11:9] <= 3'd4;
			end 
			else begin
				if (nC_curr_mb_out[7:0] || nC_up_mb_out[7:0])
					bs_horizontal[2:0] <= 3'd2;
				else if (ref_idx_l0_curr_mb_out[2:0] != ref_idx_l0_up_mb_out[2:0] || 
					mvx_diff_to_up_b0c0 || mvy_diff_to_up_b0c0 )
					bs_horizontal[2:0] <= 3'd1;

				if (nC_curr_mb_out[15:8] || nC_up_mb_out[15:8])
					bs_horizontal[5:3] <= 3'd2;
				else if (ref_idx_l0_curr_mb_out[2:0] != ref_idx_l0_up_mb_out[2:0] || 
					mvx_diff_to_up_b1c1 || mvy_diff_to_up_b1c1 )
					bs_horizontal[5:3] <= 3'd1;

				if (nC_curr_mb_out[37:32] || nC_up_mb_out[23:16])
					bs_horizontal[8:6] <= 3'd2;
				else if (ref_idx_l0_curr_mb_out[5:3] != ref_idx_l0_up_mb_out[5:3] || 
					mvx_diff_to_up_b2c2 || mvy_diff_to_up_b2c2 )
					bs_horizontal[8:6] <= 3'd1;
				
				if (nC_curr_mb_out[47:40] || nC_up_mb_out[31:24])
					bs_horizontal[11:9] <= 3'd2;
				else if (ref_idx_l0_curr_mb_out[5:3] != ref_idx_l0_up_mb_out[5:3] || 
					mvx_diff_to_up_b3c3 || mvy_diff_to_up_b3c3)
					bs_horizontal[11:9] <= 3'd1;
			end // blk4x4 y == 0

			if (nC_curr_mb_out[23:16] || nC_curr_mb_out[7:0])
				bs_horizontal[14:12] <= 3'd2;
			else if (
				mvx_diff_to_up_c0c4 || mvy_diff_to_up_c0c4)
				bs_horizontal[14:12] <= 3'd1;

			if (nC_curr_mb_out[31:24] || nC_curr_mb_out[15:8])
				bs_horizontal[17:15] <= 3'd2;
			else if (
				mvx_diff_to_up_c1c5 || mvy_diff_to_up_c1c5)
				bs_horizontal[17:15] <= 3'd1;

			if (nC_curr_mb_out[55:48] || nC_curr_mb_out[37:32])
				bs_horizontal[20:18] <= 3'd2;
			else if (
				mvx_diff_to_up_c2c6 || mvy_diff_to_up_c2c6)
				bs_horizontal[20:18] <= 3'd1;

			if (nC_curr_mb_out[63:56] || nC_curr_mb_out[47:40])
				bs_horizontal[23:21] <= 3'd2;
			else if (
				mvx_diff_to_up_c3c7 || mvy_diff_to_up_c3c7)
				bs_horizontal[23:21] <= 3'd1; //end blk4x4 y == 1

			if (nC_curr_mb_out[71:64] || nC_curr_mb_out[23:16])
				bs_horizontal[26:24] <= 3'd2;
			else if (ref_idx_l0_curr_mb_out[8:6] != ref_idx_l0_curr_mb_out[2:0] || 
				mvx_diff_to_up_c4c8 || mvy_diff_to_up_c4c8)
				bs_horizontal[26:24] <= 3'd1;

			if (nC_curr_mb_out[79:72] || nC_curr_mb_out[31:24])
				bs_horizontal[29:27] <= 3'd2;
			else if (ref_idx_l0_curr_mb_out[8:6] != ref_idx_l0_curr_mb_out[2:0] || 
				mvx_diff_to_up_c5c9 || mvy_diff_to_up_c5c9)
				bs_horizontal[29:27] <= 3'd1;

			if (nC_curr_mb_out[103:96] || nC_curr_mb_out[55:48])
				bs_horizontal[32:30] <= 3'd2;
			else if (ref_idx_l0_curr_mb_out[11:9] != ref_idx_l0_curr_mb_out[5:3] || 
				mvx_diff_to_up_c6c10 || mvy_diff_to_up_c6c10)
				bs_horizontal[32:30] <= 3'd1;

			if (nC_curr_mb_out[111:104] || nC_curr_mb_out[63:56])
				bs_horizontal[35:33] <= 3'd2;
			else if (ref_idx_l0_curr_mb_out[11:9] != ref_idx_l0_curr_mb_out[5:3] || 
				mvx_diff_to_up_c7c11 || mvy_diff_to_up_c7c11)
				bs_horizontal[35:33] <= 3'd1; //end blk4x4 y == 2

			if (nC_curr_mb_out[87:80] || nC_curr_mb_out[71:64])
				bs_horizontal[38:36] <= 3'd2;
			else if (
				mvx_diff_to_up_c8c12 || mvy_diff_to_up_c8c12)
				bs_horizontal[38:36] <= 3'd1;

			if (nC_curr_mb_out[95:88] || nC_curr_mb_out[79:72])
				bs_horizontal[41:39] <= 3'd2;
			else if (
				mvx_diff_to_up_c9c13 || mvy_diff_to_up_c9c13)
				bs_horizontal[41:39] <= 3'd1;

			if (nC_curr_mb_out[119:112] || nC_curr_mb_out[103:96])
				bs_horizontal[44:42] <= 3'd2;
			else if (
				mvx_diff_to_up_c10c14 || mvy_diff_to_up_c10c14)
				bs_horizontal[44:42] <= 3'd1;

			if (nC_curr_mb_out[127:120] || nC_curr_mb_out[111:104])
				bs_horizontal[47:45] <= 3'd2;
			else if (
				mvx_diff_to_up_c11c15 || mvy_diff_to_up_c11c15)
				bs_horizontal[47:45] <= 3'd1; //end blk4x4 y == 3
		end
	end

end

endmodule