//--------------------------------------------------------------------------------------------------
// Copyright (C) 2013-2017 qiu bin 
// All rights reserved   
// Design    : bitstream_p
// Author(s) : qiu bin
// Email     : chat1@126.com
// Phone 15957074161
// QQ:1517642772             
//-------------------------------------------------------------------------------------------------
#ifndef __macroblock_h__
#define __macroblock_h__

#include "bitstream_header.h"
#include "slice.h"

typedef struct _tag_Picture_t
{
	short **Y;
	short **U;
	short **V;
} Picture_t;

typedef struct _tag_mv_parameter
{
	short refidx;
	unsigned short width;//µ¥Î»ÊÇ4x4¿é
	unsigned short height;
	short mv_x;
	short mv_y;
	short pos_x;
	short pos_y;
} mv_parameter_t;

typedef struct _tag_macroblock
{
	unsigned short par_num;
	struct _tag_mv_parameter mv_par[16];
} macroblock_t;

void Intra_Dec_One_Macroblock( 
							  unsigned char rbsp[], 
							  unsigned int& bytes_offset, 
							  unsigned short& bits_offset,
							  unsigned short mb_index,
							  int is_first_mb_in_slice,
							  SliceType st, 
							  const SliceHeader_t& slice_header,
							  const PPS_t& pps,
							  const SPS_t& sps);

void Dec_IPCM_Macroblock();

void Read_MB_Pred( unsigned char rbsp[], 
				  unsigned int& bytes_offset, 
				  unsigned short& bits_offset,
				  unsigned short mb_index,
				  const SliceHeader_t& slice_header,
				  const SPS_t& sps,
				  const PPS_t& pps, 
				  PredMode pred_mode,
				  unsigned short mb_type,
				  unsigned short& intra_pre_mode_chroma );

void Read_Sub_MB_Pred( unsigned char rbsp[],
					   unsigned int& bytes_offset,
					   unsigned short& bits_offset,
					   unsigned short mb_index,
					   const SliceHeader_t& slice_header,
					   const SPS_t& sps,
					   const PPS_t& pps,
					   PredMode pred_mode
					   );

unsigned short Get_MostProbableIntraPredMode(unsigned short i, unsigned short j);

void residual(unsigned char rbsp[], 
			  unsigned int& bytes_offset, 
			  unsigned short& bits_offset, 
			  unsigned short mb_index,
			  PredMode pred_mode,
			  unsigned short QP,
			  unsigned short QP_C,
			  unsigned short CBP);

bool test_block_available(unsigned short x, unsigned short y, int part_width, int part_height, int dir);

void get_mvp(unsigned short x, 
			 unsigned short y, 
			 unsigned short MbPartWidth, 
			 unsigned short MbPartHeight, 
			 unsigned short mb_index,
			 short ref_idx, 
			 short* mvp);

#endif
