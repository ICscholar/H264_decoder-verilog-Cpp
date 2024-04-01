//--------------------------------------------------------------------------------------------------
// Copyright (C) 2013-2017 qiu bin 
// All rights reserved   
// Design    : bitstream_p
// Author(s) : qiu bin
// Email     : chat1@126.com
// Phone 15957074161
// QQ:1517642772             
//-------------------------------------------------------------------------------------------------

#include <stdio.h>
#include <assert.h>
#include <string.h>
#include <stdarg.h>

#include "bitstream_header.h"

unsigned rbsp_bit_counter		  = 0;
unsigned rbsp_record_bit_counter  =	0;
unsigned rbsp_record_bytes_offset =	0;
unsigned rbsp_record_bits_offset  =	0;
char	 rbsp_in_record_flag	  =	0;
char	 rbsp_record_data[255];

char debug_stop = 0;

FILE* c_cavlc_out = NULL;
FILE* c_residual_out = NULL;
FILE* c_sum_out_hex = NULL;
FILE* c_sum_out = NULL;
FILE* tracelog = NULL;
FILE* c_mv_out = NULL;
FILE* fp_deblock_dbg = NULL;

//-------------rbsp record-------------------------

void rbsp_record_read_bits(unsigned char rbsp[], 
					 unsigned int bytes_offset, 
					 unsigned short bits_offset, 
					 unsigned short len,
					 char *data)
{
	assert(bits_offset >= 0 && bits_offset <= 7);
	int i;
	for (i = 0; i < len; i++)
	{		
		if (read_one_bit(rbsp, bytes_offset, bits_offset))
		{
			data[i] = '1';
		}
		else
		{
			data[i] = '0';
		}

		GotoNextBit_t;
	}
	data[i] = 0;
}

void rbsp_record_start(unsigned int bytes_offset,unsigned short bits_offset)
{
	rbsp_record_bit_counter		=	rbsp_bit_counter;
	rbsp_record_bytes_offset	=	bytes_offset;
	rbsp_record_bits_offset		=	bits_offset;
 	rbsp_in_record_flag			=	1;
}

void rbsp_record_end(unsigned char rbsp[], char * str)
{
	unsigned recorded_bits_len;

	recorded_bits_len = rbsp_bit_counter - rbsp_record_bit_counter;
	if (rbsp_in_record_flag == 0)
	{
		fprintf(tracelog, "@%-7d:	>>rbsp record is not started!\n", rbsp_bit_counter);
		return;
	}
	else if (recorded_bits_len > 255)
	{
		fprintf(tracelog, "@%-7d:	>>recorded bits length(%d) is larger than 255!\n", 
				recorded_bits_len, rbsp_bit_counter);
	}
	else
	{
		rbsp_record_read_bits(rbsp, 
					rbsp_record_bytes_offset, 
					rbsp_record_bits_offset,
					recorded_bits_len,
					rbsp_record_data);
		fprintf(tracelog, "%s %-3d %s\n", str, recorded_bits_len, rbsp_record_data);
		rbsp_in_record_flag			=	0;
	}

}



void Log_mv(const char* format...)
{
	char tp[1024] = { 0 };
	va_list param;
	va_start(param, format);
	vsprintf(tp, format, param);
	va_end(param);
	//fwrite(tp, strlen(tp), sizeof(char), c_mv_out);
}
