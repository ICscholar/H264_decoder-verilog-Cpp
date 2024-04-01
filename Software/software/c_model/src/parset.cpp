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
#include "parset.h"
#include "bitstream_header.h"

extern unsigned short WIDTH, HEIGHT;
extern unsigned short **intra_pred_mode;
extern unsigned short **intra_mode;
extern unsigned short **qp_z;
extern unsigned short **qp_z_c;
extern unsigned short **nnz;
extern unsigned short ***nnz_chroma;

//FREXT Profile IDC definitions
#define FREXT_HP        100      //!< YUV 4:2:0/8 "High"
#define FREXT_Hi10P     110      //!< YUV 4:2:0/10 "High 10"
#define FREXT_Hi422     122      //!< YUV 4:2:2/10 "High 4:2:2"
#define FREXT_Hi444     144      //!< YUV 4:4:4/12 "High 4:4:4"

void parse_pps(unsigned char rbsp[], PPS_t* pps)
{
	unsigned int bytes_offset = 0;
	unsigned short bits_offset = 0;
	unsigned short len = 0;
	pps->pic_parameter_set_id = read_ue_v(rbsp, bytes_offset, bits_offset, len);
	GotoNextNBits(len);
	pps->seq_parameter_set_id = read_ue_v(rbsp, bytes_offset, bits_offset, len);
	GotoNextNBits(len);
	pps->entropy_coding_mode_flag = read_one_bit(rbsp, bytes_offset, bits_offset);
	GotoNextBit;
	pps->pic_order_present_flag = read_one_bit(rbsp, bytes_offset, bits_offset);
	GotoNextBit;
	pps->num_slice_groups_minus1 = read_ue_v(rbsp, bytes_offset, bits_offset, len);
	GotoNextNBits(len);
	pps->num_ref_idx_l0_active_minus1 = read_ue_v(rbsp, bytes_offset, bits_offset, len);
	GotoNextNBits(len);
	pps->num_ref_idx_l1_active_minus1 = read_ue_v(rbsp, bytes_offset, bits_offset, len);
	GotoNextNBits(len);
	pps->weighted_prediction_flag = read_one_bit(rbsp, bytes_offset, bits_offset);
	GotoNextBit;
	pps->weighted_bipred_idc = read_bits(rbsp, bytes_offset, bits_offset, 2);
	GotoNextNBits(2);
	pps->pic_init_qp_minus26 = read_se_v(rbsp, bytes_offset, bits_offset, len);
	GotoNextNBits(len);
	pps->pic_init_qs_minus26 = read_se_v(rbsp, bytes_offset, bits_offset, len);
	GotoNextNBits(len);
	pps->chroma_qp_index_offset = read_se_v(rbsp, bytes_offset, bits_offset, len);
	GotoNextNBits(len);
	pps->deblocking_filter_control_present_flag = read_one_bit(rbsp, bytes_offset, bits_offset);
	GotoNextBit;
	pps->constrained_intra_pred_flag = read_one_bit(rbsp, bytes_offset, bits_offset);
	GotoNextBit;
	pps->redundant_pic_cnt_present_flag = read_one_bit(rbsp, bytes_offset, bits_offset);
	GotoNextBit;
/*
	pps->transform_8x8_mode_flag = read_one_bit(rbsp, bytes_offset, bits_offset);
	GotoNextBit;
	pps->pic_scaling_matrix_present_flag = read_one_bit(rbsp, bytes_offset, bits_offset);
	GotoNextBit;
	pps->second_chroma_qp_index_offset = read_se_v(rbsp, bytes_offset, bits_offset, len);
	GotoNextNBits(len);
*/
}


void parse_sps(unsigned char rbsp[], SPS_t* sps) // sps are not only one
{
	unsigned int bytes_offset = 0;
	unsigned short bits_offset = 0;
	unsigned short len = 0;
	unsigned int i;
	sps->profile_idc = read_byte(rbsp, bytes_offset);
	GotoNextNBits(8);
	sps->constrained_set0_flag = read_one_bit(rbsp, bytes_offset, bits_offset);
	GotoNextBit;
	sps->constrained_set1_flag = read_one_bit(rbsp, bytes_offset, bits_offset);
	GotoNextBit;
	sps->constrained_set2_flag = read_one_bit(rbsp, bytes_offset, bits_offset);
	GotoNextBit;
	sps->constrained_set3_flag = read_one_bit(rbsp, bytes_offset, bits_offset);
	GotoNextBit;
	sps->reserved_zero_4bits = read_bits(rbsp, bytes_offset, bits_offset, 4);
	GotoNextNBits(4);
	sps->level_idc = read_bits(rbsp, bytes_offset, bits_offset, 8);
	GotoNextNBits(8);
	sps->seq_parameter_set_id = read_ue_v(rbsp, bytes_offset, bits_offset, len);
	GotoNextNBits(len);

	if((sps->profile_idc==FREXT_HP   ) ||
     (sps->profile_idc==FREXT_Hi10P) ||
     (sps->profile_idc==FREXT_Hi422) ||
     (sps->profile_idc==FREXT_Hi444))
	{	
		sps->chroma_format_idc = read_ue_v(rbsp, bytes_offset, bits_offset, len);
		GotoNextNBits(len);
		sps->bit_depth_luma_minus8 = read_ue_v(rbsp, bytes_offset, bits_offset, len);
		GotoNextNBits(len);
		sps->bit_depth_chroma_minus8 = read_ue_v(rbsp, bytes_offset, bits_offset, len);
		GotoNextNBits(len);
		sps->lossless_qpprime_y_zero_flag = read_one_bit(rbsp, bytes_offset, bits_offset);
		GotoNextBit;
		sps->seq_scaling_matrix_present_falg = read_one_bit(rbsp, bytes_offset, bits_offset);
		GotoNextBit;
	}


	sps->log2_max_fram_num_minus4 = read_ue_v(rbsp, bytes_offset, bits_offset, len);
	GotoNextNBits(len);
	
	sps->pic_order_cnt_type = read_ue_v(rbsp, bytes_offset, bits_offset, len);
	GotoNextNBits(len);
    if ( sps->pic_order_cnt_type == 0 )
	{
		sps->log2_max_pic_order_cnt_lsb_minus4 = read_ue_v(rbsp, bytes_offset, bits_offset, len);
		GotoNextNBits(len);
	}
	else if ( sps->pic_order_cnt_type == 1 )
	{
        sps->delta_pic_order_always_zero_flag = read_one_bit(rbsp, bytes_offset, bits_offset);
		GotoNextBit;
		sps->offset_for_non_ref_pic = read_se_v(rbsp, bytes_offset, bits_offset, len);
		GotoNextNBits(len);
		sps->offset_for_top_to_bottom_field = read_se_v(rbsp, bytes_offset,bits_offset, len);
		GotoNextNBits(len);
		sps->num_ref_frames_in_pic_order_cnt_cycle = read_ue_v(rbsp, bytes_offset, bits_offset, len);
		GotoNextNBits(len);
        if ( sps->num_ref_frames_in_pic_order_cnt_cycle )
		{
			sps->offset_for_ref_frame = new short[sps->num_ref_frames_in_pic_order_cnt_cycle];
			for ( i = 0; i < sps->num_ref_frames_in_pic_order_cnt_cycle; i++ )
			{
				sps->offset_for_ref_frame[i] = read_se_v(rbsp, bytes_offset, bits_offset, len);
				GotoNextNBits(len);
			}
		}
	}

	sps->num_ref_frames = read_ue_v(rbsp, bytes_offset, bits_offset, len);
	GotoNextNBits(len);
	sps->gaps_in_frame_num_value_allowed_flag = read_one_bit(rbsp, bytes_offset, bits_offset);
	GotoNextBit;
	sps->pic_width_in_mbs_minus1 = read_ue_v(rbsp, bytes_offset, bits_offset, len);
	GotoNextNBits(len);
	sps->pic_height_in_map_units_minus1 = read_ue_v(rbsp, bytes_offset, bits_offset, len);
	GotoNextNBits(len);
	sps->frame_mbs_only_flag = read_one_bit(rbsp, bytes_offset, bits_offset);
	GotoNextBit;
	if (!sps->frame_mbs_only_flag)
	{
		sps->mb_adaptive_frame_field_flag = read_one_bit(rbsp, bytes_offset, bits_offset);
		GotoNextBit;
	}
	sps->direct_8x8_inference_flag = read_one_bit(rbsp, bytes_offset, bits_offset);
	GotoNextBit;
	sps->frame_cropping_flag = read_one_bit(rbsp, bytes_offset, bits_offset);
	GotoNextBit;

	if (sps->frame_cropping_flag)
	{
		sps->frame_crop_left_offset = read_ue_v(rbsp, bytes_offset, bits_offset, len);
		GotoNextNBits(len);
		sps->frame_crop_right_offset  = read_ue_v(rbsp, bytes_offset, bits_offset, len);
		GotoNextNBits(len);
		sps->frame_crop_top_offset    = read_ue_v(rbsp, bytes_offset, bits_offset, len);
		GotoNextNBits(len);
		sps->frame_crop_bottom_offset = read_ue_v(rbsp, bytes_offset, bits_offset, len);
		GotoNextNBits(len);
	}
	sps->vui_parameters_present_flag = read_one_bit(rbsp, bytes_offset, bits_offset);
	GotoNextBit;
	if(sps->vui_parameters_present_flag)
	{
		parse_vui(rbsp, &(sps->vui), bytes_offset, bits_offset);
	}

	WIDTH = sps->pic_width_in_mbs_minus1+1;
	HEIGHT = sps->pic_height_in_map_units_minus1+1;

}







//------------------------------------------------------------------------

void parse_vui(unsigned char rbsp[], VUI_t *vui, unsigned int& bytes_offset, unsigned short& bits_offset)
{ 
	unsigned short len = 0;
	vui->matrix_coefficients = 2;
	vui->aspect_ratio_info_present_flag = read_bits(rbsp, bytes_offset, bits_offset, 1);
	GotoNextNBits(1);
	if(vui->aspect_ratio_info_present_flag) 
	{     
		vui->aspect_ratio_idc = read_bits(rbsp, bytes_offset, bits_offset, 8);
		GotoNextNBits(8);
		if(vui->aspect_ratio_idc == 0xff)
		{    
			vui->sar_width  = read_bits(rbsp, bytes_offset, bits_offset, 16);
			GotoNextNBits(16);
			vui->sar_height = read_bits(rbsp, bytes_offset, bits_offset, 16);
			GotoNextNBits(16);
		}     
	}    
	vui->overscan_info_present_flag = read_bits(rbsp, bytes_offset, bits_offset, 1);
	GotoNextNBits(1); 
	if(vui->overscan_info_present_flag)
	{
		vui->overscan_appropriate_flag = read_bits(rbsp, bytes_offset, bits_offset, 1);
		GotoNextNBits(1);
	}
	vui->video_signal_type_present_flag = read_bits(rbsp, bytes_offset, bits_offset, 1);
	GotoNextNBits(1);
	if(vui->video_signal_type_present_flag)
	{     
		vui->video_format = read_bits(rbsp, bytes_offset, bits_offset, 3);
		GotoNextNBits(3); 
		vui->video_full_range_flag = read_bits(rbsp, bytes_offset, bits_offset, 1);
		GotoNextNBits(1); 
		vui->colour_description_present_flag = read_bits(rbsp, bytes_offset, bits_offset, 1);
		GotoNextNBits(1);
		if(vui->colour_description_present_flag)
		{    
			vui->colour_primaries = read_bits(rbsp, bytes_offset, bits_offset, 8);
			GotoNextNBits(8);
			vui->transfer_characteristics = read_bits(rbsp, bytes_offset, bits_offset, 8);
			GotoNextNBits(8); 
			vui->matrix_coefficients = read_bits(rbsp, bytes_offset, bits_offset, 8);
			GotoNextNBits(8); 
		}   
	}    
	vui->chroma_loc_info_present_flag = read_bits(rbsp, bytes_offset, bits_offset, 1);
	GotoNextNBits(1); 
	if(vui->chroma_loc_info_present_flag)
	{     
		vui->chroma_sample_loc_type_top_field = read_ue_v(rbsp, bytes_offset, bits_offset, len);
		GotoNextNBits(len);
		vui->chroma_sample_loc_type_bottom_field = read_ue_v(rbsp, bytes_offset, bits_offset, len);
		GotoNextNBits(len);
	}    
	vui->timing_info_present_flag = read_bits(rbsp, bytes_offset, bits_offset, 1);
	GotoNextNBits(1); 
	if(vui->timing_info_present_flag)
	{     
		vui->num_units_in_tick = read_bits(rbsp, bytes_offset, bits_offset, 32);
		GotoNextNBits(32); 
		vui->time_scale = read_bits(rbsp, bytes_offset, bits_offset, 32);
		GotoNextNBits(32); 
		vui->fixed_frame_rate_flag = read_bits(rbsp, bytes_offset, bits_offset, 1);
		GotoNextNBits(1);
	}    
	vui->nal_hrd_parameters_present_flag = read_bits(rbsp, bytes_offset, bits_offset, 1);
	GotoNextNBits(1);
	if(vui->nal_hrd_parameters_present_flag)
	{
		parse_hrd(rbsp, &(vui->nal_hrd), bytes_offset, bits_offset);
	}
	vui->vcl_hrd_parameters_present_flag = read_bits(rbsp, bytes_offset, bits_offset, 1);
	GotoNextNBits(1); 
	if(vui->vcl_hrd_parameters_present_flag)
	{
      parse_hrd(rbsp, &(vui->vcl_hrd), bytes_offset, bits_offset);
	}
	if(vui->nal_hrd_parameters_present_flag || vui->vcl_hrd_parameters_present_flag)
	{
		vui->low_delay_hrd_flag = read_bits(rbsp, bytes_offset, bits_offset, 1);
		GotoNextNBits(1);
	}
	vui->pic_struct_present_flag = read_bits(rbsp, bytes_offset, bits_offset, 1);
	GotoNextNBits(1);  
	vui->bitstream_restriction_flag = read_bits(rbsp, bytes_offset, bits_offset, 1);
	GotoNextNBits(1); 
	if(vui->bitstream_restriction_flag)
	{     
		vui->motion_vectors_over_pic_boundaries_flag = read_bits(rbsp, bytes_offset, bits_offset, 1);
		GotoNextNBits(1); 
		vui->max_bytes_per_pic_denom = read_ue_v(rbsp, bytes_offset, bits_offset, len);
		GotoNextNBits(len);
		vui->max_bits_per_mb_denom = read_ue_v(rbsp, bytes_offset, bits_offset, len);
		GotoNextNBits(len);
		vui->log2_max_mv_length_horizontal = read_ue_v(rbsp, bytes_offset, bits_offset, len);
		GotoNextNBits(len);
		vui->log2_max_mv_length_vertical = read_ue_v(rbsp, bytes_offset, bits_offset, len);
		GotoNextNBits(len);
		vui->num_reorder_frames = read_ue_v(rbsp, bytes_offset, bits_offset, len);
		GotoNextNBits(len);
		vui->max_dec_frame_buffering = read_ue_v(rbsp, bytes_offset, bits_offset, len);
		GotoNextNBits(len);
	} 
} 

void parse_hrd(unsigned char rbsp[], HRD_t* hrd, unsigned int& bytes_offset, unsigned short& bits_offset)
{
	unsigned short len = 0;
	unsigned SchedSelIdx;
	hrd->cpb_cnt_minus1 = read_ue_v(rbsp, bytes_offset, bits_offset, len);
	GotoNextNBits(len); 
	hrd->bit_rate_scale = read_bits(rbsp, bytes_offset, bits_offset, 4);
	GotoNextNBits(4);  
	hrd->cpb_size_scale = read_bits(rbsp, bytes_offset, bits_offset, 4);
	GotoNextNBits(4);  
	for(SchedSelIdx = 0; SchedSelIdx <= hrd->cpb_cnt_minus1; SchedSelIdx++ )
	{ 
		hrd->bit_rate_value_minus1[SchedSelIdx] = read_ue_v(rbsp, bytes_offset, bits_offset, len);
		GotoNextNBits(len);
		hrd->cpb_size_value_minus1[SchedSelIdx] = read_ue_v(rbsp, bytes_offset, bits_offset, len);
		GotoNextNBits(len);
		hrd->cbr_flag[SchedSelIdx] = read_bits(rbsp, bytes_offset, bits_offset, 1);
		GotoNextNBits(1);  
	} 
	hrd->initial_cpb_removal_delay_length_minus1 = read_bits(rbsp, bytes_offset, bits_offset, 5);
	GotoNextNBits(5);  
	hrd->cpb_removal_delay_length_minus1 = read_bits(rbsp, bytes_offset, bits_offset, 5);
	GotoNextNBits(5);  
	hrd->dpb_output_delay_length_minus1 = read_bits(rbsp, bytes_offset, bits_offset, 5);
	GotoNextNBits(5);  
	hrd->time_offset_length = read_bits(rbsp, bytes_offset, bits_offset, 5);
	GotoNextNBits(5);  
} 
