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
#include "cavlc.h"
#include "bitstream_header.h"
#include <math.h>
#include <assert.h>
#include <string.h>
#include <stdlib.h>

extern unsigned short mb_index;
extern unsigned short slice_num;
#define TRACE_CAVLC_MB_INDEX 315
#define TRACE_CAVLC_SLICE 92

// 除了cavlc之外其余bytes_offset,bits_offset都为值传递,cavlc程序长len的长度不好统计
int cavlc(unsigned char rbsp[], 
		  unsigned int& bytes_offset,
		  unsigned short& bits_offset,
		  short nC,
		  unsigned short max_coeff_num,	  
		  short* coeff_buf,
		  unsigned short buf_len)
{
	unsigned short TotalCoeff, TrailingOnes,TotalZeros, ZeroLeft = 0;
	unsigned short suffixLength = 0;
	// 这里level_suffix未初始化为0的话下面就使用,出现Debug Assert Fail
	unsigned short level_prefix = 0, level_suffix = 0, level_code = 0;
	short level[16] = { 0 };
	short runt[16] = { 0 }; // 每个非0系数之前的0的个数
	short run; // 每个非0系数之前的0的个数
	short i, j;
	unsigned short len = 0;
	short coeff_buf_t[16] = {0};	
	unsigned short t;
    // nC=-1仅仅用在求色度直流的时候
	memset(coeff_buf, 0, buf_len);

	RBSP_RECORD_START;
	read_total_coeffs(rbsp, 
		bytes_offset, 
		bits_offset, 
		len,
		nC, 		 
		TotalCoeff, 
		TrailingOnes);
	GotoNextNBits(len);

	if (TotalCoeff == 0)
	{
		if (c_cavlc_out){
			fprintf(c_cavlc_out, "mb_index:%-5dnC:%-5dTotalCoeff:%-5d\n", mb_index, nC, TotalCoeff);
			fprintf(c_cavlc_out, "%5d%5d%5d%5d\n", 0,0,0,0);
			fprintf(c_cavlc_out, "%5d%5d%5d%5d\n",0,0,0,0);
			fprintf(c_cavlc_out, "%5d%5d%5d%5d\n", 0,0,0,0);
			fprintf(c_cavlc_out, "%5d%5d%5d%5d\n\n", 0,0,0,0);
		}
		return 0;
	}

	if (TotalCoeff > 10 && TrailingOnes < 3)
	{
		suffixLength = 1;
	}
	else
	{
		suffixLength = 0;
	}

	for (i = 0; i < TotalCoeff; i++)
	{
		if (i < TrailingOnes)
		{
			level[i] = read_one_bit(rbsp, bytes_offset, bits_offset) ? -1 : 1;
			GotoNextBit;
		}
		else
		{
			level_prefix = read_level_prefix(rbsp, bytes_offset, bits_offset, len);
			GotoNextNBits(len);

			if (suffixLength > 0 && level_prefix <= 14)
			{
				level_suffix = read_bits(rbsp, bytes_offset, bits_offset, suffixLength);
				GotoNextNBits(suffixLength);
			}
			else if (level_prefix == 14)
			{
				level_suffix = read_bits(rbsp, bytes_offset, bits_offset, 4);
				GotoNextNBits(4);
			}
			else if (level_prefix == 15)	
			{
				level_suffix = read_bits(rbsp, bytes_offset, bits_offset, 12);
				GotoNextNBits(12);
			}

			level_code = (level_prefix << suffixLength) + level_suffix;
			

			if (suffixLength == 0 && level_prefix == 15)
			{
				level_code += 15;
			}
			if (TrailingOnes == i && TrailingOnes < 3)
			{
				level_code += 2;
			}

			if (level_code % 2 == 0)
			{
				level[i] = (level_code + 2) >> 1;
			}
			else
			{
				level[i] = (-level_code - 1) >> 1;
			}

			if (suffixLength == 0)
			{
				suffixLength = 1;
			}

			if (abs(level[i]) > (3 << (suffixLength - 1)) && suffixLength < 6)
			{
				suffixLength++;
			}

		} // else

	} // for

	if (TotalCoeff < max_coeff_num)
	{
		if (nC == -1) // nC=-1仅仅用在求色度直流的时候
		{
			ZeroLeft = TotalZeros = read_total_zeros_chroma_DC(rbsp,
				bytes_offset,
				bits_offset,
				len,
				TotalCoeff);
			GotoNextNBits(len);
		}
		else
		{
			// 最后一个非0系数之前0的个数
			ZeroLeft = TotalZeros = read_total_zeros(rbsp, 
				bytes_offset,
				bits_offset, 
				len,
				TotalCoeff);
			GotoNextNBits(len);
		}
	}
/*
	for (i = 0; i < TotalCoeff - 1 && ZeroLeft > 0; i++)
	{
		// 每个非0系数前0的个数
		run[i] = read_run_before(rbsp,
			bytes_offset,
			bits_offset,
			len,
			ZeroLeft);
		ZeroLeft -= run[i];
		GotoNextNBits(len);
	}
	run[TotalCoeff-1] = ZeroLeft;

	j = -1;
	for (i = TotalCoeff-1; i >= 0; i--)
	{
		j = j + run[i] + 1;
		coeff_buf[j] = level[i]; // coeff_buff : output buffer
	}
*/
	//每得到一个run就能得到一个coeff_buf
	for (i = TotalCoeff -1; i >= 0; i--)
	{	
		coeff_buf[i+ZeroLeft] = level[TotalCoeff-1-i]; // coeff_buff : output buffer
		if (ZeroLeft > 0 && i >  0)
		{
			run = read_run_before(rbsp,
				bytes_offset,
				bits_offset,
				len,
				ZeroLeft);
			GotoNextNBits(len);
		}
		if (ZeroLeft > 0 )
		{
			ZeroLeft -= run;
		}
		
	}
	t = 0;
	for (i=0;i<16;i++)
	{
		if(t<TotalCoeff && coeff_buf[i]!=0)
		{
			coeff_buf_t[i]= coeff_buf[i];
			t++;
		}
		else
		{
			coeff_buf_t[i]= 0;
		}
	}
	if (c_cavlc_out){
		fprintf(c_cavlc_out, "mb_index:%-5dnC:%-5dTotalCoeff:%-5d\n", mb_index, nC, TotalCoeff);
		fprintf(c_cavlc_out, "%5d%5d%5d%5d\n", coeff_buf_t[0], coeff_buf_t[1], coeff_buf_t[2], coeff_buf_t[3]);
		fprintf(c_cavlc_out, "%5d%5d%5d%5d\n", coeff_buf_t[4], coeff_buf_t[5], coeff_buf_t[6], coeff_buf_t[7]);
		fprintf(c_cavlc_out, "%5d%5d%5d%5d\n", coeff_buf_t[8], coeff_buf_t[9], coeff_buf_t[10], coeff_buf_t[11]);
		fprintf(c_cavlc_out, "%5d%5d%5d%5d\n\n", coeff_buf_t[12], coeff_buf_t[13], coeff_buf_t[14], coeff_buf_t[15]);
	}
	return TotalCoeff;

}


int read_total_coeffs(unsigned char rbsp[], 
					  unsigned int bytes_offset, 
					  unsigned short bits_offset, 					  
					  unsigned short& len, 
					  short nC, 
					  unsigned short& TotalCoeffs, 
					  unsigned short& TrailingOnes)
{
	unsigned short code, cod_len;
	unsigned short i, j, vlcnum;

	static unsigned short lentab_Chroma_DC[4][5] = {
		{2,6,6,6,6},{0,1,6,7,8},{0,0,3,7,8},{0,0,0,6,7}
	};
	static unsigned short codtab_Chroma_DC[4][5] = {
		{1,7,4,3,2},{0,1,6,3,3},{0,0,1,2,2},{0,0,0,5,0}
	};
	static unsigned short lentab[3][4][17] = {
		{{1, 6, 8, 9,10,11,13,13,13,14,14,15,15,16,16,16,16},
		{ 0, 2, 6, 8, 9,10,11,13,13,14,14,15,15,15,16,16,16},
		{ 0, 0, 3, 7, 8, 9,10,11,13,13,14,14,15,15,16,16,16},
		{ 0, 0, 0, 5, 6, 7, 8, 9,10,11,13,14,14,15,15,16,16},},

		{{2, 6, 6, 7, 8, 8, 9,11,11,12,12,12,13,13,13,14,14},
		{ 0, 2, 5, 6, 6, 7, 8, 9,11,11,12,12,13,13,14,14,14},
		{ 0, 0, 3, 6, 6, 7, 8, 9,11,11,12,12,13,13,13,14,14},
		{ 0, 0, 0, 4, 4, 5, 6, 6, 7, 9,11,11,12,13,13,13,14},},

		{{4, 6, 6, 6, 7, 7, 7, 7, 8, 8, 9, 9, 9,10,10,10,10},
		{ 0, 4, 5, 5, 5, 5, 6, 6, 7, 8, 8, 9, 9, 9,10,10,10},
		{ 0, 0, 4, 5, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9,10,10,10},
		{ 0, 0, 0, 4, 4, 4, 4, 4, 5, 6, 7, 8, 8, 9,10,10,10},},
	};

	// code table
	static unsigned short codtab[3][4][17] = {
		{{1, 5, 7, 7, 7, 7,15,11, 8,15,11,15,11,15,11, 7,4}, 
		{ 0, 1, 4, 6, 6, 6, 6,14,10,14,10,14,10, 1,14,10,6}, 
		{ 0, 0, 1, 5, 5, 5, 5, 5,13, 9,13, 9,13, 9,13, 9,5}, 
		{ 0, 0, 0, 3, 3, 4, 4, 4, 4, 4,12,12, 8,12, 8,12,8},},

		{{3,11, 7, 7, 7, 4, 7,15,11,15,11, 8,15,11, 7, 9,7}, 
		{ 0, 2, 7,10, 6, 6, 6, 6,14,10,14,10,14,10,11, 8,6}, 
		{ 0, 0, 3, 9, 5, 5, 5, 5,13, 9,13, 9,13, 9, 6,10,5}, 
		{ 0, 0, 0, 5, 4, 6, 8, 4, 4, 4,12, 8,12,12, 8, 1,4},},

		{{15,15,11, 8,15,11, 9, 8,15,11,15,11, 8,13, 9, 5,1}, 
		{ 0,14,15,12,10, 8,14,10,14,14,10,14,10, 7,12, 8,4},
		{ 0, 0,13,14,11, 9,13, 9,13,10,13, 9,13, 9,11, 7,3},
		{ 0, 0, 0,12,11,10, 9, 8,13,12,12,12, 8,12,10, 6,2},},
	};

	if (nC == -1)
	{
		for (i = 0; i < 4; i++)
		{
			for (j = 0; j < 5; j++)
			{
				cod_len = lentab_Chroma_DC[i][j];
				if (cod_len == 0)
				{
					continue;
				}
				if (read_bits(rbsp, bytes_offset, bits_offset, cod_len) == codtab_Chroma_DC[i][j])
				{
					len = cod_len;
					TotalCoeffs = j;
					TrailingOnes = i;
					return 1;
				}
			}
		}
		return 0;
	} 
	else if (nC >= 8)
	{
		// read 6 bit fix length coding
		code = read_bits(rbsp, bytes_offset, bits_offset, 6);
		if (code == 3)
		{
			TotalCoeffs = 0;
			TrailingOnes = 0;
		}
		else
		{
			TrailingOnes = code & 0x3;
			TotalCoeffs = (code >> 2) + 1;
		}
		len = 6;
		return 1;
	}
	else
	{
		vlcnum = 0;
		if (nC < 2)
		{
			vlcnum = 0;
		} 
		else if (nC < 4)
		{
			vlcnum = 1;
		}
		else if (nC < 8)
		{
			vlcnum = 2;
		}
		for (i = 0; i < 4; i++)
		{
			for (j = 0; j < 17; j++)
			{
				cod_len = lentab[vlcnum][i][j];
				if (cod_len == 0)
				{
					continue;
				}
				if (read_bits(rbsp, bytes_offset, bits_offset, cod_len) == codtab[vlcnum][i][j])
				{
					TotalCoeffs = j;
					TrailingOnes = i;
					len = cod_len;
					return 1;
				}
			}
		}
		assert(0);
		return 0;
	}

}


// 0000 0000 0000 0001=>15 读取码流直到为1,level_prefix即为0的个数
unsigned short read_level_prefix(unsigned char rbsp[], 
								 unsigned int bytes_offset, 
								 unsigned short bits_offset, 
								 unsigned short& len)
{
	unsigned short zero_number = 0;
	while(read_one_bit(rbsp, bytes_offset, bits_offset) == 0)
	{
		zero_number++;
		GotoNextBit_t;
	}
	len = zero_number+1;
	return zero_number;
}

unsigned short read_total_zeros_chroma_DC(unsigned char rbsp[], 
										   unsigned int bytes_offset, 
										   unsigned short bits_offset,
										   unsigned short& len,
										   unsigned short TotalCoeff)
{
	unsigned short i;
	unsigned short cod_len;
	assert(TotalCoeff < 4 && TotalCoeff > 0);
	// TotalCoeff 1,2,3
	static unsigned short lentab[3][4] = {
		{1,2,3,3},
		{1,2,2},
		{1,1}
	};
	static unsigned short codtab[3][4] = {
		{1,1,1,0},
		{1,1,0},
		{1,0}
	};

	for (i = 0; i < 4; i++)
	{
		
		cod_len = lentab[TotalCoeff-1][i];
		if (cod_len == 0)
		{
			continue;
		}
		if (read_bits(rbsp, bytes_offset, bits_offset, cod_len) == codtab[TotalCoeff-1][i])
		{
			len = cod_len;
			return i;
		}
		
	}
	assert(0);
	return 0xffff;

}

unsigned short read_total_zeros(unsigned char rbsp[], 
								unsigned int bytes_offset,
								unsigned short bits_offset,
								unsigned short& len,
								unsigned short TotalCoeff)
{
	static unsigned short lentab[15][16] = {
		{ 1,3,3,4,4,5,5,6,6,7,7,8,8,9,9,9},  
		{ 3,3,3,3,3,4,4,4,4,5,5,6,6,6,6},  
		{ 4,3,3,3,4,4,3,3,4,5,5,6,5,6},  
		{ 5,3,4,4,3,3,3,4,3,4,5,5,5},  
		{ 4,4,4,3,3,3,3,3,4,5,4,5},  
		{ 6,5,3,3,3,3,3,3,4,3,6},  
		{ 6,5,3,3,3,2,3,4,3,6},  
		{ 6,4,5,3,2,2,3,3,6},  
		{ 6,6,4,2,2,3,2,5},  
		{ 5,5,3,2,2,2,4},  
		{ 4,4,3,3,1,3},  
		{ 4,4,2,1,3},  
		{ 3,3,1,2},  
		{ 2,2,1},  
		{ 1,1},  
	};
	static unsigned short codtab[15][16] = {
		{1,3,2,3,2,3,2,3,2,3,2,3,2,3,2,1},
		{7,6,5,4,3,5,4,3,2,3,2,3,2,1,0},
		{5,7,6,5,4,3,4,3,2,3,2,1,1,0},
		{3,7,5,4,6,5,4,3,3,2,2,1,0},
		{5,4,3,7,6,5,4,3,2,1,1,0},
		{1,1,7,6,5,4,3,2,1,1,0},
		{1,1,5,4,3,3,2,1,1,0},
		{1,1,1,3,3,2,2,1,0},
		{1,0,1,3,2,1,1,1,},
		{1,0,1,3,2,1,1,},
		{0,1,1,2,1,3},
		{0,1,1,1,1},
		{0,1,1,1},
		{0,1,1},
		{0,1},  
	};

	unsigned short i;
	unsigned short cod_len;

	for (i = 0; i < 16; i++)
	{
		cod_len = lentab[TotalCoeff-1][i];
		if (cod_len == 0)
		{
			continue;
		}
		if (read_bits(rbsp, bytes_offset, bits_offset, cod_len) == codtab[TotalCoeff-1][i])
		{
			len = cod_len;
			return i;
		}
	}
	assert(0);
	return 0xffff;
}

unsigned short read_run_before(unsigned char rbsp[], 
							   unsigned int bytes_offset,
							   unsigned short bits_offset,
							   unsigned short& len,
							   unsigned short ZeroLeft)
{
	static unsigned short lentab[7][15] = {
		{1,1},
		{1,2,2},
		{2,2,2,2},
		{2,2,2,3,3},
		{2,2,3,3,3,3},
		{2,3,3,3,3,3,3},
		{3,3,3,3,3,3,3,4,5,6,7,8,9,10,11},
	};

	static unsigned short codtab[7][15] = {
		{1,0},
		{1,1,0},
		{3,2,1,0},
		{3,2,1,1,0},
		{3,2,3,2,1,0},
		{3,0,1,3,2,5,4},
		{7,6,5,4,3,2,1,1,1,1,1,1,1,1,1},
	};
	unsigned short i, cod_len;
	
	if (ZeroLeft > 6)
	{
		ZeroLeft = 7;
	}

	for (i = 0; i < 15; i++)
	{
		cod_len = lentab[ZeroLeft-1][i];
		if (cod_len == 0)
		{
			continue;
		}
		if (read_bits(rbsp, bytes_offset, bits_offset, cod_len) == codtab[ZeroLeft-1][i])
		{
			len = cod_len;
			return i;
		}
	}
	
	assert(0);
	return 0xffff;
}














