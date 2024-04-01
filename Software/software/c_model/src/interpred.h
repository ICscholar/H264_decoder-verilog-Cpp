//--------------------------------------------------------------------------------------------------
// Copyright (C) 2013-2017 qiu bin 
// All rights reserved   
// Design    : bitstream_p
// Author(s) : qiu bin
// Email     : chat1@126.com
// Phone 15957074161
// QQ:1517642772             
//-------------------------------------------------------------------------------------------------

#ifndef __interpred_h__
#define __interpred_h__

void get_block_subpixel_c(short** p_u,
						  short** p_v,
						  short mv_x, 
						  short mv_y, 
						  unsigned short MbPartWidth, 
						  unsigned short MbPartHeight,
						  unsigned short x, 
						  unsigned short y,
						  short ref);

void get_block_subpixel(short** p, 
						short mv_x, 
						short mv_y, 
						unsigned short MbPartWidth, 
						unsigned short MbPartHeight,
						unsigned short x, 
						unsigned short y,
						short ref);

void InterPred(unsigned short mb_index);

void Dec_P_skip_MB(unsigned short mb_index);

#endif
