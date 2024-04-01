//--------------------------------------------------------------------------------------------------
// Copyright (C) 2013-2017 qiu bin 
// All rights reserved   
// Design    : bitstream_p
// Author(s) : qiu bin
// Email     : chat1@126.com
// Phone 15957074161
// QQ:1517642772             
//-------------------------------------------------------------------------------------------------

// bitstream.cpp : Defines the entry point for the console application.
//

//#define _USE_SDL
#define DUMP_DATA
#include <stdio.h>
#include <assert.h>
#include <memory.h>
#include <math.h>
#include <stdlib.h>
#include "bitstream_header.h"
#include "memalloc.h"
#include "macroblock.h"
#include "loopfilter.h"
#include <stdarg.h>
#include <string.h>
#ifdef _USE_SDL
  #include "sdl_pac.h"
#endif
unsigned short WIDTH, HEIGHT;
unsigned short **intra_pred_mode; // 4x4���9��ģʽ 4x4��Ϊ��λ ֻ�Ժ�����4x4��ʽʱ����,
unsigned short **intra_mode; // 1 : intra, 0 : inter 16x16��Ϊ��λ
unsigned short **qp_z;
unsigned short **qp_z_c;
unsigned short **nnz;
unsigned short ***nnz_chroma;
char slice_table[40000];

Picture_t current_pic;
Picture_t ref_pic[5];

short **RefIdx;
short ***MV;

unsigned short slice_num;
unsigned short mb_index;
unsigned short pic_num=0;
unsigned short slice_mb_index;
unsigned int rbsp_total_bits;
// ����ȫ�ֱ���FILE* log ���ֱ������,log��<math.h>�е�log����������
	int ref_all_same;
void openfile(const char* input_file_name, const char* output_file_name, FILE** fin, FILE** fout)
{
	*fin = fopen(input_file_name, "rb");
	assert(*fin != NULL);
	*fout = fopen(output_file_name, "wb");
	assert(*fout != NULL);
}

void closefile(FILE* fin, FILE* fout)
{
	assert(fin);
	assert(fout);
	fclose(fin);
	fclose(fout);
	fin = NULL;
	fout = NULL;
}
//return 0 if last nalu in bitstream,else 1
//rbsp is nalu exclude startcode and nalu_head
unsigned short read_one_nalu(FILE* fin, 
				  int offset, 
				  unsigned char* stream_buffer, 
				  Nalu_Head_t& nalu_header,
				  unsigned char* rbsp,
				  unsigned int& nalu_len) 
{
	int result = fseek(fin, offset, SEEK_SET);
	int i = 0;
	assert(result == 0);
	int read_len = fread((void*)stream_buffer, sizeof(char), MAX_NALU_LEN, fin); 
	int start_bytes;	
	while(!(stream_buffer[i+0] == 0x0 
		&& stream_buffer[i+1] == 0x0 
		&& stream_buffer[i+2] == 0x0
		&& stream_buffer[i+3] == 0x1 ||
		stream_buffer[i+0] == 0x0 
		&& stream_buffer[i+1] == 0x0 
		&& stream_buffer[i+2] == 0x1)){
		i++;
	} 
	/*
	assert(stream_buffer[0] == 0x0 
		&& stream_buffer[1] == 0x0 
		&& stream_buffer[2] == 0x0
		&& stream_buffer[3] == 0x1 ||
		stream_buffer[0] == 0x0 
		&& stream_buffer[1] == 0x0 
		&& stream_buffer[2] == 0x1); //assert offset position of file is start code
*/
	if (stream_buffer[i+0] == 0x0 
		&& stream_buffer[i+1] == 0x0 
		&& stream_buffer[i+2] == 0x0
		&& stream_buffer[i+3] == 0x1)
	{
		memcpy(&nalu_header, stream_buffer+i+4, sizeof(char));
		start_bytes = i+4;
	}
	else
	{
		memcpy(&nalu_header, stream_buffer+i+3, sizeof(char));
		start_bytes = i+3;
	}
	for (int i = 2; i < read_len - 3; i++)
	{
		if(stream_buffer[i] == 0x0 
			&& stream_buffer[i+1] == 0x0 
			&& stream_buffer[i+2] == 0x0 
			&& stream_buffer[i+3] == 0x1 ||
			stream_buffer[i] == 0x0 
			&& stream_buffer[i+1] == 0x0 
			&& stream_buffer[i+2] == 0x1)
		{
			nalu_len = i;
			EBSP2RBSP(stream_buffer + start_bytes - 4, rbsp, nalu_len + 4 - start_bytes);
			return 1;
		}

	}
	//otherwise there is no any more 0x00000001 in the readed bits, last nalu 
	nalu_len = read_len;
	EBSP2RBSP(stream_buffer + start_bytes - 4, rbsp, nalu_len + 4 - start_bytes);
	return 0;
	
}

void EBSP2RBSP(unsigned char* nalu, unsigned char* rbsp, unsigned int nalu_len)
{
	// startcode 4bytes, nalu head 1byte
	int rbsp_len = 0, r = 0;
	unsigned char v;
	for (int i = 5; i < nalu_len; i++)
	{
		if (nalu[i-2] == 0x0
			&& nalu[i-1] == 0x0
			&& nalu[i] == 0x3)
		{
			continue; // bug fix break->continue
		}
		rbsp_len++;
		rbsp[rbsp_len-1] = nalu[i];
	}
	v = rbsp[rbsp_len-1];
	for(r=1; r<9; r++){
        if(v&1) break;
        v>>=1;
    }
	rbsp_total_bits =  8*rbsp_len - r;
}



unsigned short read_ue_v(unsigned char rbsp[], 
						 unsigned int bytes_offset, 
						 unsigned short bits_offset, 
						 unsigned short& len)
{
	assert(bits_offset >= 0 && bits_offset <= 7);
	unsigned short leadingZerobits = 0;
	while (!read_one_bit(rbsp, bytes_offset, bits_offset))
	{
		leadingZerobits++;
		GotoNextBit_t;
	}
	len = leadingZerobits * 2 + 1;
	if (leadingZerobits)
	{
		//unsigned short val = (1 << leadingZerobits) - 1 + read_bits(rbsp, bytes_offset, bits_offset+1, leadingZerobits);
		unsigned short val = read_bits(rbsp, bytes_offset, bits_offset, leadingZerobits+1)-1;
		return val;
	}
	else
	{
		return 0;
	}
}

short read_se_v(unsigned char rbsp[], 
				unsigned int bytes_offset, 
				unsigned short bits_offset,
				unsigned short& len)
{
	assert(bits_offset >= 0 && bits_offset <= 7);
	unsigned short val = read_ue_v(rbsp, bytes_offset, bits_offset, len);
	unsigned short tmp = (val + 1) % 2;
	val = ((val + 1) >> 1);
	if (tmp)
	{
		return -val;
	}
	else
	{
		return val;
	}
}

unsigned short read_te_v(unsigned char rbsp[],
						 unsigned int bytes_offset,
						 unsigned short bits_offset,
						 unsigned short& len,
						 unsigned short range)
{
	unsigned short val;
	assert(range >= 1);

    if(range==1)      return 0;
    else if(range==2) {
    	len = 1;
    	return read_one_bit(rbsp, bytes_offset, bits_offset)^1;
	}
    else              return read_ue_v(rbsp, bytes_offset, bits_offset, len);
}


// intra_4x4 1 inter 0
unsigned short read_me_v(unsigned char rbsp[], 
						 unsigned int bytes_offset, 
						 unsigned short bits_offset, 
						 unsigned short intra_4x4, 
						 unsigned short& len)
{
	static unsigned short me_conversion[2][48] = {
		{0,16,1,2,4,8,32,3,5,10,12,15,47,7,11,13,14,6,9,31,35,37,42,44,
			33,34,36,40,39,43,45,46,17,18,20,24,19,21,26,28,23,27,29,30,22,25,38,41},
		{47,31,15,0,23,27,29,30,7,11,13,14,39,43,45,46,16,3,5,10,12,19,21,26,
		28,35,37,42,44,1,2,4,8,17,18,20,24,6,9,22,25,32,33,34,36,40,38,41}
	};

	unsigned short val = read_ue_v(rbsp, bytes_offset, bits_offset, len);
	assert( val >= 0 && val <= 47 );
	val = me_conversion[intra_4x4][val];
	return val;
}

// read from bytes_offset+1 bytes, read from high bit in a byte
    // ����0x67,(memory high bit)0110 0111(memory low bit) ���λbit indexΪ0 ���λΪ7,Ҳ���Ƕ���˳���ǴӸ�λ���λ��,
unsigned short read_one_bit(unsigned char rbsp[], 
						   unsigned int bytes_offset, 
						   unsigned short bits_offset)
{
	assert(bits_offset >= 0 && bits_offset <= 7);
	return (rbsp[bytes_offset] >> (7 - bits_offset) & 0x1);
}

unsigned short read_bits(unsigned char rbsp[], 
						 unsigned int bytes_offset, 
						 unsigned short bits_offset, 
						 unsigned short len)
{
	assert(bits_offset >= 0 && bits_offset <= 7);
	unsigned  short val = 0; // set all the bit to 0
	for (int i = 0; i < len; i++)
	{		
		if (read_one_bit(rbsp, bytes_offset, bits_offset))
		{
			val = val | (1 << (len-1-i));
		}

		GotoNextBit_t;
	}

	return val;
}

unsigned short read_byte(unsigned char rbsp[], 
						 unsigned int bytes_offset)
{
	return rbsp[bytes_offset];
}

int main(int argc, char* argv[])
{
	printf("\nslice_num:%d\n",0);
	FILE* input = NULL;
	FILE* output = NULL;
	input = fopen("dance1080p.264", "rb");
	assert(input != NULL);
	output = fopen("out.yuv", "wb");
	assert(output != NULL);
	//fp_deblock_dbg = fopen("c_deblock_dbg.txt", "w+");
	//assert(fp_deblock_dbg != NULL);
			#ifdef DUMP_DATA
	//c_residual_out = fopen("c_residual_out.txt", "w+");
	//assert(c_residual_out != NULL);
	//c_cavlc_out = fopen("c_cavlc_out.txt", "w+");
	//assert(c_cavlc_out != NULL);
	//c_sum_out = fopen("c_sum_out.txt", "w+");
	//assert(c_sum_out != NULL);
	//c_sum_out_hex = fopen("c_sum_out_hex.txt", "w+");
	//assert(c_sum_out_hex != NULL);
	//c_mv_out = fopen("c_mv_out.txt", "w+");
	//assert(c_mv_out != NULL);
	
#endif

	unsigned char *stream_buffer;
	unsigned char *rbsp;
	stream_buffer = (unsigned char*)calloc(MAX_NALU_LEN, sizeof(unsigned char));
	rbsp = (unsigned char*)calloc(MAX_NALU_LEN, sizeof(unsigned char));
	int inited = 0;
	int last_ms;
	SPS_t sps;
	PPS_t pps;
	SliceHeader_t slice_header;
	
	// ������ײ��λ���в����ĺ���,���ຯ��bytes_offset,bits_offset��Ϊ���ô���,
	unsigned int bytes_offset = 0;
	unsigned short bits_offset = 0;

	Nalu_Head_t nalu_head = { 0 };
	unsigned int offset = 0;
	unsigned int nalu_len = 0;
	int ret = 0;
	int sps_found = 0;
	memset(&slice_header, 0xff, sizeof(SliceHeader_t));
    

	last_ms = 0;
	do 
	{
		ret = read_one_nalu(input, offset, stream_buffer, nalu_head, rbsp, nalu_len);
		offset += nalu_len;
		if (nalu_head.nal_unit_type == 7)
		{
			sps_found = 1;
			parse_sps(rbsp, &sps);
			if (inited == 0)
			{
				InitDecoder();
				inited = 1;
			}
			//SDL_init(WIDTH*16,HEIGHT*16);
			//slice_num++;
		}
		else if (nalu_head.nal_unit_type == 8)
		{
			parse_pps(rbsp, &pps);
			slice_num = 0;
			//slice_num++;
		}
		else if (sps_found && (nalu_head.nal_unit_type == 5 || nalu_head.nal_unit_type == 1))
		{
			if (pic_num == 1)
			{
				int abc =1;
			}
			bytes_offset = 0;
			bits_offset = 0;
			parse_slice_header(rbsp, bytes_offset, bits_offset, &slice_header, nalu_head, sps, pps);
			read_slice_data(rbsp, bytes_offset, bits_offset, rbsp_total_bits, slice_header, sps, pps);

			if (mb_index == WIDTH * HEIGHT ){
			//	deblocking_filter(slice_header, pps);
				slice_num = 0;
				pic_num++;
			//	printf("\n%d\n", ref_all_same);
				ref_all_same = 0;
#ifndef _USE_SDL			
				output_to_file( output );
#else
				WriteBlockYUV(0, 0, WIDTH * 16, HEIGHT * 16, current_pic.Y, current_pic.U, current_pic.V);
				Refresh();
				if (sdl_event())
					break;
				while (GetTicks() - last_ms < 40);//25fps
				last_ms = GetTicks();
#endif		
				//output_to_file( output );
;
				InsertFrame();
			}
			slice_num++;
			//printf("\nslice_num:%d\n",slice_num);
			//break;
		}
	}
	while (ret);
	FreeDecoder();
	closefile(input, output);
			#ifdef DUMP_DATA
	fclose(c_cavlc_out);
	fclose(c_residual_out);
	fclose(c_sum_out);
	fclose(c_sum_out_hex);
	fclose(c_mv_out);
			#endif
	return 0;
}




void InitDecoder()
{
	// number of rows : HEIGHT, number of columns : HEIGHT
	unsigned short i;
	get_mem2Dshort(&intra_pred_mode, HEIGHT * 4, WIDTH * 4, 2);
	
	get_mem2Dshort(&intra_mode, HEIGHT, WIDTH, 0);
	get_mem2Dshort(&qp_z, HEIGHT, WIDTH, 0);
	get_mem2Dshort(&qp_z_c, HEIGHT, WIDTH, 0);
	get_mem2Dshort(&nnz, HEIGHT * 4, WIDTH * 4, 0);
	get_mem3Dshort(&nnz_chroma, 2, HEIGHT * 2, WIDTH * 2);
	get_mem2Dpixel(&current_pic.Y, HEIGHT * 16, WIDTH * 16, 0);
	get_mem2Dpixel(&current_pic.U, HEIGHT * 8, WIDTH * 8, 0);
	get_mem2Dpixel(&current_pic.V, HEIGHT * 8, WIDTH * 8, 0);
	get_mem2Dpixel(&RefIdx, HEIGHT * 2, WIDTH * 2, -1);//8x8Ϊ��λ
	get_mem3Dpixel(&MV, 2, HEIGHT * 4, WIDTH * 4);

	for ( i = 0; i < 5; i++ )
	{
		get_mem2Dpixel(&ref_pic[i].Y, HEIGHT * 16, WIDTH * 16, 0);
		get_mem2Dpixel(&ref_pic[i].U, HEIGHT * 8, WIDTH * 8, 0);
		get_mem2Dpixel(&ref_pic[i].V, HEIGHT * 8, WIDTH * 8, 0); //fix by binqiu *6 to *8
	}
}

void FreeDecoder()
{
	unsigned short i;
	free_mem2Dshort(intra_mode);
	free_mem2Dshort(intra_pred_mode);
	free_mem2Dshort(qp_z_c);
	free_mem2Dshort(qp_z);
	free_mem2Dshort(nnz);
	free_mem3Dshort(nnz_chroma, 2);
	free_mem2Dpixel(current_pic.Y);
	free_mem2Dpixel(current_pic.U);
	free_mem2Dpixel(current_pic.V);

	free_mem2Dpixel(RefIdx);
	free_mem3Dpixel(MV, 2);

	for ( i = 0; i < 5; i++ )
	{
		free_mem2Dpixel(ref_pic[i].Y);
		free_mem2Dpixel(ref_pic[i].U);
		free_mem2Dpixel(ref_pic[i].V);
	}
}

void output_to_file(FILE* out)
{
	unsigned short i, j;	
	int k; /* WIDTH * HEIGHT * 128 * 3�ķ�Χ������unsigned short�ܱ�ʾ�ķ�Χ  */
	unsigned char* p = (unsigned char*) calloc(WIDTH * HEIGHT * 128 * 3, sizeof(unsigned char));
	assert(out);

	k = 0;
	for (i = 0; i < HEIGHT * 16; i++)
	{
		for (j = 0; j < WIDTH * 16; j++,k++)
		{
			p[k] = (unsigned char)current_pic.Y[i][j];
		}
	}

	for (i = 0; i < HEIGHT * 8; i++)
	{
		for (j = 0; j < WIDTH * 8; j++, k++)
		{
			p[k] = (unsigned char)current_pic.U[i][j];
		}
	}

	for (i = 0; i < HEIGHT * 8; i++)
	{
		for (j = 0; j < WIDTH * 8; j++, k++)
		{
			p[k] = (unsigned char)current_pic.V[i][j];
		}
	}

	fwrite(p, sizeof(unsigned char), HEIGHT * WIDTH * 128 * 3, out);
	free( p );
}

void Log(const char* format...)
{
	return;
	if ( slice_num == 92 )
	{
		FILE* log_info = fopen("log_trace.txt", "a+");
		char tp[1024] = { 0 };
		va_list param;
		va_start(param, format);
		vsprintf(tp, format, param);
		va_end(param);
		fwrite(tp, strlen(tp), sizeof(char), log_info);
		fclose(log_info);
	}
}

void TraceBits(unsigned char rbsp[], 
								 unsigned int bytes_offset, 
								 unsigned short bits_offset, 
								 unsigned short len)
{
	unsigned short i,j;
	i = 0;
	for(i = 0; i < len; i++)
	{
	    j = read_one_bit(rbsp, bytes_offset, bits_offset);
		GotoNextBit;
		printf("%d",j);
	}

}

void InsertFrame()
{
	free_mem2Dpixel(ref_pic[4].Y);
	free_mem2Dpixel(ref_pic[4].U);
	free_mem2Dpixel(ref_pic[4].V);

	ref_pic[4].Y = ref_pic[3].Y;
	ref_pic[4].U = ref_pic[3].U;
	ref_pic[4].V = ref_pic[3].V;
	
	ref_pic[3].Y = ref_pic[2].Y;
	ref_pic[3].U = ref_pic[2].U;
	ref_pic[3].V = ref_pic[2].V;
	
	ref_pic[2].Y = ref_pic[1].Y;
	ref_pic[2].U = ref_pic[1].U;
	ref_pic[2].V = ref_pic[1].V;
	
	ref_pic[1].Y = ref_pic[0].Y;
	ref_pic[1].U = ref_pic[0].U;
	ref_pic[1].V = ref_pic[0].V;
	
	ref_pic[0].Y = current_pic.Y;
	ref_pic[0].U = current_pic.U;
	ref_pic[0].V = current_pic.V;

	get_mem2Dpixel(&current_pic.Y, HEIGHT * 16, WIDTH * 16, 0);
	get_mem2Dpixel(&current_pic.U, HEIGHT * 8, WIDTH * 8, 0);
	get_mem2Dpixel(&current_pic.V, HEIGHT * 8, WIDTH * 8, 0);
}


void ResetDecoder()
{
	unsigned i;
	// ��Ϊ��unsigned short���ͣ�ÿ��unsigned short��ռ�����ֽڣ�memsetֻset��һ����ڴ�
	memset(intra_mode[0], 0, HEIGHT * WIDTH * 2);
	for (i = 0; i < HEIGHT * 4 * WIDTH * 4; i++)
	{
		intra_pred_mode[0][i] = 2;
	}
    memset(qp_z[0], 0, HEIGHT * WIDTH * 2);
	memset(qp_z_c[0], 0, HEIGHT * WIDTH * 2);
	memset(nnz[0], 0, HEIGHT * WIDTH * 16*2);
	memset(nnz_chroma[0][0], 0, HEIGHT * WIDTH * 8);
	memset(nnz_chroma[1][0], 0, HEIGHT * WIDTH * 8);
	memset(slice_table, 0xff, 10000);
	/*
	for (i = 0; i < HEIGHT * 4 * WIDTH * 4; i++)
	{
		nnz[0][i] = 64;
	}
	for (i = 0; i < HEIGHT * 2 * WIDTH * 2; i++)
	{
		nnz_chroma[0][0][i] = 64;
		nnz_chroma[1][0][i] = 64;
	}
	*/
	for ( i = 0; i < HEIGHT * 2 * WIDTH * 2; i++ )
	{
		RefIdx[0][i] = -1;
	}
	memset(MV[0][0], 0, HEIGHT * 4 * WIDTH * 4 * 2);
	memset(MV[1][0], 0, HEIGHT * 4 * WIDTH * 4 * 2);
}





