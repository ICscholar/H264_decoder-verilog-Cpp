//--------------------------------------------------------------------------------------------------
// Copyright (C) 2013-2017 qiu bin 
// All rights reserved   
// Design    : bitstream_p
// Author(s) : qiu bin
// Email     : chat1@126.com
// Phone 15957074161
// QQ:1517642772             
//-------------------------------------------------------------------------------------------------

#ifndef _bitstream_header_
#define _bitstream_header_
#include <stdio.h>

#define DUMP_DATA
enum SliceType {P = 0, B, I,SP, SI};

enum PredMode {I4MB = 0, I16MB, IPCM, PRED_L0, PRED_L1, BI_PRED, B_DIRECT, P_REF0, P_SKIP, B_SKIP};

#define MAX_NALU_LEN (1024 * 500) // bug fix 有时一个nalu的长度大于8196

typedef struct _tag_Nalu_Head
{
	unsigned char nal_unit_type			: 5;
	unsigned char nal_ref_idc			: 2;
	unsigned char forbidden_zero_bit	: 1;           

} Nalu_Head_t;

//-----------------------------------------------------------------
extern unsigned rbsp_bit_counter;
extern char debug_stop;
extern FILE*	tracelog;
extern FILE*	c_cavlc_out;
extern FILE*	c_residual_out;
extern FILE*	c_sum_out_hex;
extern FILE*	c_sum_out;
extern FILE*	c_mv_out;
extern FILE*	fp_deblock_dbg;

#define RBSP_RECORD_START		{rbsp_record_start(bytes_offset, bits_offset);}
#define RBSP_RECORD_END(str)	{rbsp_record_end(rbsp,(str));}
extern void rbsp_record_read_bits(unsigned char rbsp[], 
					 unsigned int bytes_offset, 
					 unsigned short bits_offset, 
					 unsigned short len,
					 char *data);

extern void rbsp_record_start(unsigned int bytes_offset,unsigned short bits_offset);
extern void rbsp_record_end(unsigned char rbsp[], char *str);
extern void Log_mv(const char* format...);

#define GotoNextBit {rbsp_bit_counter++;bits_offset++; bytes_offset += (bits_offset / 8); bits_offset = bits_offset % 8;}

#define GotoNextBit_t {bits_offset++; bytes_offset += (bits_offset / 8); bits_offset = bits_offset % 8;}
#define GotoNextNBits(n) {rbsp_bit_counter+=n; bits_offset+=n; bytes_offset += (bits_offset / 8); bits_offset = bits_offset % 8;}




#define min(a, b) ((a < b) ? (a) : (b))
#define max(a, b) ((a > b) ? (a) : (b))
#define Clip3(Min,Max,val) ((val) > (Min)? ((val) < (Max)? (val):(Max)):(Min))
#define Median(a,b,c) ((a) > (b)) ? ((a) > (c) ? max(b,c):(a)):((a) > (c) ? (a) : min(b,c))

void openfile(const char* input_file_name, const char* output_file_name, FILE** fin, FILE** fout);
void closefile(FILE* fin, FILE* fout);
unsigned short read_one_nalu(FILE* fin, 
				  int offset, 
				  unsigned char* stream_buffer, 
				  Nalu_Head_t& nalu_header,
				  unsigned char* rbsp,
				  unsigned int& nalu_len) ;

void EBSP2RBSP(unsigned char* nalu, unsigned char* rbsp, unsigned int nalu_len);

// read from bytes_offset+1 bytes, bits_offset : start from low bit
// high bit ---> low bit
// 0  1  1  0  0  1  1  1
// <-- left shift  right shift -->
// in RAM low bit --- > high bit
// 1  1  1  0  0  1  1  0
// <-- right shift  left shift -->
unsigned short read_one_bit(unsigned char rbsp[], 
						   unsigned int bytes_offset, 
						   unsigned short bits_offset);

unsigned short read_byte(unsigned char rbsp[], 
						 unsigned int bytes_offset);

unsigned short read_bits(unsigned char rbsp[], 
						 unsigned int bytes_offset, 
						 unsigned short bits_offset, 
						 unsigned short len);

short read_se_v(unsigned char rbsp[], 
				unsigned int bytes_offset, 
				unsigned short bits_offset,
				unsigned short& len);

unsigned short read_ue_v(unsigned char rbsp[], 
						 unsigned int bytes_offset, 
						 unsigned short bits_offset,
						 unsigned short& len);

unsigned short read_me_v(unsigned char rbsp[],
						 unsigned int bytes_offset,
						 unsigned short bits_offset,
						 unsigned short intra_4x4,
						 unsigned short& len);

unsigned short read_te_v(unsigned char rbsp[],
						 unsigned int bytes_offset,
						 unsigned short bits_offset,
						 unsigned short& len,
						 unsigned short Max);

void InitDecoder();
void FreeDecoder();
void ResetDecoder();

void output_to_file(FILE* out);
void Log(const char* format...);

void InsertFrame();
void TraceBits(unsigned char rbsp[], 
								 unsigned int bytes_offset, 
								 unsigned short bits_offset, 
								 unsigned short len);
short get_qp_z_c(int qp_z, int chroma_qp_offset);

#endif
