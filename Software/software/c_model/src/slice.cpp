//--------------------------------------------------------------------------------------------------
// Copyright (C) 2013-2017 qiu bin 
// All rights reserved   
// Design    : bitstream_p
// Author(s) : qiu bin
// Email     : chat1@126.com
// Phone 15957074161
// QQ:1517642772             
//-------------------------------------------------------------------------------------------------

#include "stdafx.h"
#include "slice.h"
#include "bitstream_header.h"
#include "macroblock.h"
#include "interpred.h"
#include <assert.h>

extern unsigned short WIDTH, HEIGHT;
extern unsigned short **intra_pred_mode;
extern unsigned short **intra_mode;
extern unsigned short **qp_z;
extern unsigned short **qp_z_c;
extern unsigned short **nnz;
extern unsigned short ***nnz_chroma;
extern unsigned short slice_num;
extern unsigned short mb_index;
extern unsigned short first_mb_index_in_slice;
extern unsigned short slice_mb_index;
extern unsigned short pic_num;
extern char slice_table[40000];
int debug_flag;

extern unsigned short qp_z_a;
extern unsigned short qp_z_c_a;

void parse_slice_header(unsigned char rbsp[], 
						unsigned int& bytes_offset,
						unsigned short& bits_offset,
						SliceHeader_t* slice_header, 
						const Nalu_Head_t& nalu_header,
						const SPS_t& sps,
						const PPS_t& pps
						)
{
	unsigned short len = 0;
	slice_header->first_mb_in_slice = 
		read_ue_v(rbsp, bytes_offset,bits_offset, len);
	GotoNextNBits(len);
	slice_header->slice_type = 
		read_ue_v(rbsp, bytes_offset, bits_offset, len);
	
	SliceType st = static_cast<SliceType>(slice_header->slice_type % 5);

	GotoNextNBits(len);
	slice_header->pic_parameter_set_id = 
		read_ue_v(rbsp, bytes_offset, bits_offset, len); //图像参数集的索引，范围为0~255
	GotoNextNBits(len);
	slice_header->frame_num = 
		read_bits(rbsp, bytes_offset, bits_offset, sps.log2_max_fram_num_minus4 + 4);//会翻转
	GotoNextNBits(sps.log2_max_fram_num_minus4 + 4);

	
	//if (!frame_mbs_only_flag) from sps frame_mbs_only_flag =1 只有幀，没有场
    //    field_pic_flag
    //    if(field_pic_flag)
    //        bottom_field_flag
	slice_header->field_pic_flag = 0xff;
	slice_header->bottom_field_flag = 0xff;

	if (nalu_header.nal_unit_type == 5)
	{
		slice_header->idr_pic_id = 
			read_ue_v(rbsp, bytes_offset, bits_offset, len);
		GotoNextNBits(len);
	}

	if (sps.pic_order_cnt_type == 0)
	{
		// POC
		slice_header->pic_order_cnt_lsb = 
			read_bits(rbsp, bytes_offset, bits_offset, sps.log2_max_pic_order_cnt_lsb_minus4 + 4);
		GotoNextNBits(sps.log2_max_pic_order_cnt_lsb_minus4 + 4);
		if ( pps.pic_order_present_flag && !slice_header->field_pic_flag ) 
	    // pic_order_present_flag, POC的三种计算方法在片层还各需要用一些句法元素作为参数，pic_order_present_flag=1表示在片头会有句法元素指明这些参数
		{
			slice_header->delta_pic_order_cnt_bottom = read_se_v(rbsp, bytes_offset, bits_offset, len);
			GotoNextNBits(len);
		}
	}

	// the two fields set to default 0
    // if ( pic_order_cnt_type == 1 && !delta_pic_order_always_zero_flag )
	//     delta_pic_order_cnt[0]
	//     if (pic_order_present_flag && !field_pic_flag)
	//         delta_pic_order_cnt[1]
	if ( sps.pic_order_cnt_type == 1 && !sps.delta_pic_order_always_zero_flag )
	{
		slice_header->delta_pic_order_cnt[0] = read_se_v(rbsp, bytes_offset, bits_offset, len);
		GotoNextNBits(len);
		if ( pps.pic_order_present_flag && !slice_header->field_pic_flag )
		{
			slice_header->delta_pic_order_cnt[1] = read_se_v(rbsp, bytes_offset,bits_offset, len);
			GotoNextNBits(len);
		}
	}

	slice_header->delta_pic_order_cnt[0] = 0xffff;
	slice_header->delta_pic_order_cnt[1] = 0xffff;

	if (pps.redundant_pic_cnt_present_flag) // redundant_pic_cnt_present_flag 指明是否会出现redundant_pic_cnt句法元素
	{
		slice_header->redundant_pic_cnt = read_ue_v(rbsp, bytes_offset, bits_offset, len);
		GotoNextNBits(len);
	}

	// B slice
	if (st == B)
	{
		slice_header->direct_spatial_mv_pred_flag = 
			read_one_bit(rbsp, bytes_offset, bits_offset);
		GotoNextBit;
	}

	// B, P, SP slice
	if (st == B || st == P || st == SP)
	{
		slice_header->num_ref_idx_active_override_flag = 
			read_one_bit(rbsp, bytes_offset, bits_offset);
		GotoNextBit;
		if (slice_header->num_ref_idx_active_override_flag)
		{
			slice_header->num_ref_idx_l0_active_minus1 = 
				read_ue_v(rbsp, bytes_offset, bits_offset, len);
			GotoNextNBits(len);
			if (slice_header->slice_type == 1 || slice_header->slice_type == 6)
			{
				slice_header->num_ref_idx_l1_active_minus1 = 
					read_ue_v(rbsp, bytes_offset, bits_offset, len);
				GotoNextNBits(len);
			}
		}
		else
		{
			slice_header->num_ref_idx_l0_active_minus1 = pps.num_ref_idx_l0_active_minus1;
			if (st == B)
			{
				slice_header->num_ref_idx_l1_active_minus1 = pps.num_ref_idx_l1_active_minus1;
			}
		}
	}

	ref_pic_list_reordering(rbsp, bytes_offset, bits_offset, slice_header);

	if ((pps.weighted_prediction_flag && (st == P || st == SP)) 
		|| (pps.weighted_bipred_idc && (st == B)))
	{
		pred_weight_table(slice_header);
	}

	if (nalu_header.nal_ref_idc)
	{
		dec_ref_pic_marking(rbsp, bytes_offset, bits_offset, slice_header, nalu_header);
	}

	slice_header->cabac_init_idc = 0;

	slice_header->slice_qp_delta = read_se_v(rbsp, bytes_offset, bits_offset, len);
	GotoNextNBits(len);

	if (st == SP || st == SI)
	{
		if (st == SP)
		{
			slice_header->sp_for_switch_flag = 
				read_one_bit(rbsp, bytes_offset, bits_offset);
			GotoNextBit;
		}
		slice_header->slice_qs_dalta = 
			read_se_v(rbsp, bytes_offset, bits_offset, len);
		GotoNextNBits(len);
	}

	// 在去方块滤波时要用到
	slice_header->disable_deblocking_filter_idc = 0;
	slice_header->slice_alpha_c0_offset_div2 = 0;
	slice_header->slice_beta_offset_div2 = 0;
	if (pps.deblocking_filter_control_present_flag)
	{
		slice_header->disable_deblocking_filter_idc = 
			read_ue_v(rbsp, bytes_offset, bits_offset, len);
		GotoNextNBits(len);
		if (slice_header->disable_deblocking_filter_idc != 1)
		{
			slice_header->slice_alpha_c0_offset_div2 = 
				read_se_v(rbsp, bytes_offset, bits_offset, len);
			GotoNextNBits(len);
			slice_header->slice_beta_offset_div2 = 
				read_se_v(rbsp, bytes_offset, bits_offset, len);
			GotoNextNBits(len);
		}
	}

	// set default
	slice_header->slice_group_change_cycle = 0xffff;
}

void ref_pic_list_reordering(unsigned char rbsp[], 
							 unsigned int& bytes_offset, 
							 unsigned short& bits_offset,
							 SliceHeader_t* slice_header
							 )
{
	SliceType st = static_cast<SliceType>(slice_header->slice_type % 5);
	unsigned short len = 0;
	if (st == B || st == P || st == SP) 
	{
		slice_header->ref_pic_list_reordering_flag_l0 = 
			read_one_bit(rbsp, bytes_offset, bits_offset);
		GotoNextBit;
		if (st == B)
		{
			slice_header->ref_pic_list_reordering_flag_l1 = 
				read_one_bit(rbsp, bytes_offset, bits_offset);
			GotoNextBit;
		}

	}

}

void pred_weight_table(SliceHeader_t* slice_header)
{

}

void dec_ref_pic_marking(unsigned char rbsp[], 
						 unsigned int& bytes_offset, 
						 unsigned short& bits_offset,
						 SliceHeader_t* slice_header, 
						 const Nalu_Head_t& nalu_header
						)
{
	if (nalu_header.nal_unit_type == 5)
	{
		slice_header->no_output_of_prior_pics_flag = read_one_bit(rbsp, bytes_offset, bits_offset);
		GotoNextBit;
		slice_header->long_term_reference_flag = read_one_bit(rbsp, bytes_offset, bits_offset);
		GotoNextBit;
	}
	else
	{
		slice_header->adaptive_ref_pic_marking_mode_flag = read_one_bit(rbsp, bytes_offset,bits_offset);
		GotoNextBit;
	}

}

void read_slice_data(unsigned char rbsp[], 
					 unsigned int& bytes_offset, 
					 unsigned short& bits_offset,
					 unsigned int rbsp_total_bits,
					 const SliceHeader_t& slice_header,
					 const SPS_t& sps,
					 const PPS_t& pps
					 )
{
	unsigned short i, k;
	unsigned short len = 0;
	int is_first_mb_in_slice = 1;
	slice_mb_index = 0;

	SliceType st = static_cast<SliceType>(slice_header.slice_type % 5);


	if (slice_header.first_mb_in_slice == 0)
		ResetDecoder();
	mb_index = slice_header.first_mb_in_slice;
	qp_z_a = pps.pic_init_qp_minus26 + 26 + slice_header.slice_qp_delta ;
	qp_z_c_a = get_qp_z_c(qp_z_a, pps.chroma_qp_index_offset);
	first_mb_index_in_slice = slice_header.first_mb_in_slice;
			printf("pic_num:%06d  mb:%06d\n",pic_num, mb_index);
	do
	{
		if (pic_num == 1 && mb_index >=300){
			i = 2;
		}
		if (st != I && st != SI)
		{
			unsigned short mb_skip_run = read_ue_v(rbsp, bytes_offset, bits_offset, len);
		
			GotoNextNBits(len);
 			for ( k = 0; k < mb_skip_run; k++, mb_index++, slice_mb_index++ )
			{
				                				if (pic_num == 0 && mb_index >= 3580){
			i = 2;
		}
				if( mb_index >= HEIGHT*WIDTH)
					return;
				slice_table[mb_index] = slice_num;
				qp_z[mb_index/WIDTH][mb_index%WIDTH] = qp_z_a;
				qp_z_c[mb_index/WIDTH][mb_index%WIDTH] = qp_z_c_a;
                Dec_P_skip_MB(mb_index); 

			debug_flag = 1;
 			}	
		}
		if((bytes_offset*8+bits_offset) == rbsp_total_bits || mb_index >= HEIGHT*WIDTH)
			break;
	//	printf("pic_num:%06d  mb:%06d\n",pic_num, mb_index);
		debug_flag = 0;
				if (pic_num == 1 && mb_index >= 3599){
			i = 2;
			debug_flag = 1;
		}
	//	printf("%d\n",rbsp_bit_counter);
		Intra_Dec_One_Macroblock(rbsp, bytes_offset, bits_offset, mb_index, is_first_mb_in_slice, st, slice_header, pps, sps);
		if (is_first_mb_in_slice)
			is_first_mb_in_slice  = 0;
		slice_table[mb_index] = slice_num;
		mb_index++;
		slice_mb_index++;
		if((bytes_offset*8+bits_offset) == rbsp_total_bits || mb_index >= HEIGHT*WIDTH)
			break;
		//if ( slice_num == 92 && *(char*)(rbsp+13521) )
	}while(1);

}
