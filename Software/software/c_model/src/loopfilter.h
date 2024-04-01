//--------------------------------------------------------------------------------------------------
// Copyright (C) 2013-2017 qiu bin 
// All rights reserved   
// Design    : bitstream_p
// Author(s) : qiu bin
// Email     : chat1@126.com
// Phone 15957074161
// QQ:1517642772             
//-------------------------------------------------------------------------------------------------

#ifndef __loop_filter_h__
#define __loop_filter_h__

#include "slice.h"

typedef struct _Index
{
	int indexA[6];
	int indexB[6];
	int alpha[6];
	int beta[6];
} Index_t;

void strength(unsigned short verticalFlag, unsigned short x, unsigned short y, unsigned short bs[4][4]);
void FilterProcess_bs4_hor( short **p, 
						   unsigned short x,
						   unsigned short y,
						   unsigned short chromaFlag,
						   unsigned short alpha,
						   unsigned short beta );

void FilterProcess_bs4_ver( short **p, 
						   unsigned short x,
						   unsigned short y, 
						   unsigned short chromaFlag,
						   unsigned short alpha,
						   unsigned short beta);

void FilterProcess_bs_lessthan4_ver( short **p, 
									unsigned short x,
									unsigned short y,
									unsigned short chromaFlag,
									unsigned short bs,
									unsigned short alpha,
									unsigned short beta,
									unsigned short tc_0
									);

void FilterProcess_bs_lessthan4_hor( short **p, 
									unsigned short x,
									unsigned short y,
									unsigned short chromaFlag,
									unsigned short bs,
									unsigned short alpha,
									unsigned short beta,
									unsigned short tc_0 );
void FilterEdge( unsigned short x,
				unsigned short y,
				unsigned short chromaFlag,
				unsigned short verticalFlag,
				short **p,
				unsigned short edgeFlag,
				unsigned short bs,
				unsigned short index_A, 
				unsigned short alpha,
				unsigned short beta );

void deblocking_mb( unsigned short mb_index, Index_t index, short **p_y, short **p_u, short **p_v);

void deblocking_filter( const SliceHeader_t &slice_header , const PPS_t& pps);


#endif

