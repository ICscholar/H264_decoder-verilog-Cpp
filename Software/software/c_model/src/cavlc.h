//--------------------------------------------------------------------------------------------------
// Copyright (C) 2013-2017 qiu bin 
// All rights reserved   
// Design    : bitstream_p
// Author(s) : qiu bin
// Email     : chat1@126.com
// Phone 15957074161
// QQ:1517642772             
//-------------------------------------------------------------------------------------------------

#ifndef __CAVLC_H__
#define __CAVLC_H__

int cavlc(unsigned char rbsp[], 
		  unsigned int& bytes_offset,
		  unsigned short& bits_offset,
		  short nC,
		  unsigned short max_coff_num,	  
		  short* coeff_buf,
		  unsigned short buf_len);

int read_total_coeffs(unsigned char rbsp[], 
					  unsigned int bytes_offset, 
					  unsigned short bits_offset, 
					  unsigned short& len, 
					  short nC, 					  
					  unsigned short& TotalCoeffs, 
					  unsigned short& TrailingOnes);



unsigned short read_level_prefix(unsigned char rbsp[], 
								 unsigned int bytes_offset, 
								 unsigned short bits_offset, 
								 unsigned short& len);

unsigned short read_total_zeros_chroma_DC(unsigned char rbsp[], 
										   unsigned int bytes_offset, 
										   unsigned short bits_offset,
										   unsigned short& len,
										   unsigned short TotalCoeff);

unsigned short read_total_zeros(unsigned char rbsp[], 
								unsigned int bytes_offset,
								unsigned short bits_offset,
								unsigned short& len,
								unsigned short TotalCoeff);

unsigned short read_run_before(unsigned char rbsp[], 
							   unsigned int bytes_offset,
							   unsigned short bits_offset,
							   unsigned short& len,
							   unsigned short ZeroLeft);



#endif
