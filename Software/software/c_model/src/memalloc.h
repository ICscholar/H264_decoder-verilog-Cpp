//--------------------------------------------------------------------------------------------------
// Copyright (C) 2013-2017 qiu bin 
// All rights reserved   
// Design    : bitstream_p
// Author(s) : qiu bin
// Email     : chat1@126.com
// Phone 15957074161
// QQ:1517642772             
//-------------------------------------------------------------------------------------------------

#ifndef __mem_alloc_h__
#define __mem_alloc_h__

int get_mem2Dshort(unsigned short ***array2D, unsigned short rows, unsigned short columns, unsigned short init_value);
void free_mem2D(unsigned char** array2D);

void free_mem2Dshort(unsigned short** array2D);

int get_mem3Dshort(unsigned short ****array3D, 
				   unsigned short frames, 
				   unsigned short rows,
				   unsigned short columns);

int get_mem3Dpixel( short **** array3D,
				    unsigned short frames,
					unsigned short rows,
					unsigned short columns );

void free_mem3Dshort(unsigned short ***array3D, unsigned short frames);

int get_mem2Dpixel(short ***array2D, unsigned short rows, unsigned short columns, short init_value);

void free_mem2Dpixel(short** array2D);

void free_mem3Dpixel(short*** array3D, unsigned short frames);

#endif
