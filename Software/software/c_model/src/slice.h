//--------------------------------------------------------------------------------------------------
// Copyright (C) 2013-2017 qiu bin 
// All rights reserved   
// Design    : bitstream_p
// Author(s) : qiu bin
// Email     : chat1@126.com
// Phone 15957074161
// QQ:1517642772             
//-------------------------------------------------------------------------------------------------

#ifndef __slice_header__
#define __slice_header__

#include "bitstream_header.h"
#include "parset.h"

typedef struct _tag_SliceHeader
{
	unsigned short first_mb_in_slice;
	unsigned short slice_type;
	unsigned short pic_parameter_set_id;
	unsigned short frame_num;
	unsigned short field_pic_flag;
	unsigned short bottom_field_flag;
	unsigned short idr_pic_id;
	unsigned short pic_order_cnt_lsb;
	short delta_pic_order_cnt_bottom;
	short delta_pic_order_cnt[2];
	unsigned short redundant_pic_cnt;
	unsigned short direct_spatial_mv_pred_flag;
	unsigned short num_ref_idx_active_override_flag;
	unsigned short num_ref_idx_l0_active_minus1;
	unsigned short num_ref_idx_l1_active_minus1;

	// ref_pic_list_reordering
	unsigned short ref_pic_list_reordering_flag_l0;
	unsigned short ref_pic_list_reordering_flag_l1;

	// dec_ref_pic_marking
	unsigned short no_output_of_prior_pics_flag;
	unsigned short long_term_reference_flag;
	unsigned short adaptive_ref_pic_marking_mode_flag;

	unsigned short cabac_init_idc;
	short slice_qp_delta;
	unsigned short sp_for_switch_flag;
	short slice_qs_dalta;
	unsigned short disable_deblocking_filter_idc;
	short slice_alpha_c0_offset_div2;
	short slice_beta_offset_div2;
	unsigned short slice_group_change_cycle;

} SliceHeader_t;

void parse_slice_header(unsigned char rbsp[], 
						unsigned int& bytes_offset,
						unsigned short& bits_offset,
						SliceHeader_t* slice_header, 
						const Nalu_Head_t& nalu_header,
						const SPS_t& sps,
						const PPS_t& pps
						);

void ref_pic_list_reordering(unsigned char rbsp[], 
							 unsigned int& bytes_offset, 
							 unsigned short& bits_offset,
							 SliceHeader_t* slice_header
							 );

void pred_weight_table(SliceHeader_t* slice_header);

void dec_ref_pic_marking(unsigned char rbsp[], 
						 unsigned int& bytes_offset, 
						 unsigned short& bits_offset,
						 SliceHeader_t* slice_header, 
						 const Nalu_Head_t& nalu_header
						 );

void read_slice_data(unsigned char rbsp[], 
					 unsigned int& bytes_offset, 
					 unsigned short& bits_offset, 
					 unsigned int rbsp_total_bits,
					 const SliceHeader_t& slice_header,
					 const SPS_t& sps,
					 const PPS_t& pps
					 );


#endif
