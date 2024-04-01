//--------------------------------------------------------------------------------------------------
// Copyright (C) 2013-2017 qiu bin 
// All rights reserved   
// Design    : bitstream_p
// Author(s) : qiu bin
// Email     : chat1@126.com
// Phone 15957074161
// QQ:1517642772             
//-------------------------------------------------------------------------------------------------

#ifndef __parset_header__
#define __parset_header__
//---------------------------------------

#define MAXIMUMVALUEOFcpb_cnt   32
typedef struct
{
	unsigned  cpb_cnt_minus1;                                   
	unsigned  bit_rate_scale;                                  
	unsigned  cpb_size_scale;                                  
	unsigned  bit_rate_value_minus1 [MAXIMUMVALUEOFcpb_cnt]; 
	unsigned  cpb_size_value_minus1 [MAXIMUMVALUEOFcpb_cnt]; 
	unsigned  cbr_flag              [MAXIMUMVALUEOFcpb_cnt]; 
	unsigned  initial_cpb_removal_delay_length_minus1;         
	unsigned  cpb_removal_delay_length_minus1;                 
	unsigned  dpb_output_delay_length_minus1;                  
	unsigned  time_offset_length;                              
} HRD_t;

typedef struct
{
	unsigned short   aspect_ratio_info_present_flag; 
	unsigned  aspect_ratio_idc;                  
	unsigned  sar_width;                         
	unsigned  sar_height;                        
	unsigned short   overscan_info_present_flag;     
	unsigned short   overscan_appropriate_flag;      
	unsigned short   video_signal_type_present_flag; 
	unsigned  video_format;                      
	unsigned short   video_full_range_flag;          
	unsigned short   colour_description_present_flag;
	unsigned  colour_primaries;                  
	unsigned  transfer_characteristics;          
	unsigned  matrix_coefficients;               
	unsigned short   chroma_loc_info_present_flag; 
	unsigned  chroma_sample_loc_type_top_field;    
	unsigned  chroma_sample_loc_type_bottom_field; 
	unsigned short   timing_info_present_flag;          
	unsigned  num_units_in_tick;                    
	unsigned  time_scale;                           
	unsigned short   fixed_frame_rate_flag;             
	unsigned short   nal_hrd_parameters_present_flag;          
	HRD_t nal_hrd;                     
	unsigned short   vcl_hrd_parameters_present_flag;          
	HRD_t  vcl_hrd;                  
	unsigned short   low_delay_hrd_flag;                       
	unsigned short   pic_struct_present_flag;                  
	unsigned short   bitstream_restriction_flag;               
	unsigned short   motion_vectors_over_pic_boundaries_flag;  
	unsigned  max_bytes_per_pic_denom;                     
	unsigned  max_bits_per_mb_denom;                       
	unsigned  log2_max_mv_length_vertical;                 
	unsigned  log2_max_mv_length_horizontal;               
	unsigned  num_reorder_frames;                          
	unsigned  max_dec_frame_buffering;                     
} VUI_t;
//-----------------------------------------------------




typedef struct _tag_SPS
{
	unsigned short profile_idc;

	unsigned short constrained_set0_flag;	
	unsigned short constrained_set1_flag;	
	unsigned short constrained_set2_flag;	
	unsigned short constrained_set3_flag;
	unsigned short reserved_zero_4bits;

	unsigned short level_idc;

	unsigned short seq_parameter_set_id;	
	unsigned short chroma_format_idc;	
	unsigned short bit_depth_luma_minus8;
	unsigned short bit_depth_chroma_minus8;	
	unsigned short lossless_qpprime_y_zero_flag;
	unsigned short seq_scaling_matrix_present_falg;

	unsigned short log2_max_fram_num_minus4;	
	
	unsigned short pic_order_cnt_type;	
	  unsigned short log2_max_pic_order_cnt_lsb_minus4;
	  unsigned short delta_pic_order_always_zero_flag;
	  short offset_for_non_ref_pic;
	  short offset_for_top_to_bottom_field;
	  unsigned short num_ref_frames_in_pic_order_cnt_cycle;
	  short* offset_for_ref_frame;
	
	
	unsigned short num_ref_frames;

	unsigned short gaps_in_frame_num_value_allowed_flag;
	unsigned short pic_width_in_mbs_minus1;
	unsigned short pic_height_in_map_units_minus1;
    unsigned short mb_adaptive_frame_field_flag;                   // u(1)

	unsigned short frame_mbs_only_flag;
	unsigned short direct_8x8_inference_flag;	
	unsigned short frame_cropping_flag;

    unsigned  frame_crop_left_offset;
    unsigned  frame_crop_right_offset;
    unsigned  frame_crop_top_offset; 
    unsigned  frame_crop_bottom_offset;

	unsigned short vui_parameters_present_flag;
    VUI_t vui;               

} SPS_t;

typedef struct _tag_PPS
{
	unsigned short pic_parameter_set_id;
	unsigned short seq_parameter_set_id;

	unsigned short entropy_coding_mode_flag; // 0 : CAVLC, 1 : CABAC
	unsigned short pic_order_present_flag;
	unsigned short num_slice_groups_minus1;

	unsigned short	num_ref_idx_l0_active_minus1;
	unsigned short	num_ref_idx_l1_active_minus1;
	unsigned short	weighted_prediction_flag;
	unsigned short	weighted_bipred_idc;
	short			pic_init_qp_minus26;
	short			pic_init_qs_minus26;
	short			chroma_qp_index_offset;
	unsigned short	deblocking_filter_control_present_flag;
	 
	unsigned short	constrained_intra_pred_flag;// 1 : 在P片B片中帧内编码不能用邻近帧间编码的宏块作为预测, 0 : 可以
	unsigned short	redundant_pic_cnt_present_flag;
	unsigned short	transform_8x8_mode_flag;
	unsigned short	pic_scaling_matrix_present_flag;
	short			second_chroma_qp_index_offset;

} PPS_t;

//----------------------------------
void parse_vui(unsigned char rbsp[], VUI_t* vui, unsigned int& bytes_offset, unsigned short& bits_offset);
void parse_hrd(unsigned char rbsp[], HRD_t* hrd, unsigned int& bytes_offset, unsigned short& bits_offset);

//----------------------------------
void parse_pps(unsigned char rbsp[], PPS_t* pps);

void parse_sps(unsigned char rbsp[], SPS_t* sps); // sps are not only one

#endif
