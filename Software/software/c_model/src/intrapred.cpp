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
#include "intrapred.h"
#include "bitstream_header.h"
#include "macroblock.h"
#include <assert.h>

extern unsigned short WIDTH, HEIGHT;
extern unsigned short **intra_pred_mode;
extern unsigned short **intra_mode;
extern unsigned short **qp_z;
extern unsigned short **qp_z_c;
extern unsigned short **nnz;
extern unsigned short ***nnz_chroma;
extern Picture_t current_pic;
extern unsigned short slice_num;
extern unsigned short slice_mb_index;
extern unsigned short pic_num;


	unsigned short	topleft_samples_available;
    unsigned short  top_samples_available;
    unsigned short  left_samples_available;
    unsigned short  topright_samples_available;
	unsigned short	top_type;
	unsigned short	left_type;
	unsigned short	top_left_type;
	unsigned short	top_right_type;

void pred_avail_check(unsigned short mb_index, const PPS_t& pps){
	unsigned short pos_y = mb_index / WIDTH;
	unsigned short pos_x = mb_index % WIDTH;
			topleft_samples_available=
        top_samples_available=
        left_samples_available= 0xFFFF;
        topright_samples_available= 0xEEEA;
		top_type = pos_y > 0 && slice_mb_index >= WIDTH ? (intra_mode[pos_y-1][pos_x] ? 1 : 2) : 0;
		left_type = pos_x > 0 && slice_mb_index >= 1 ? (intra_mode[pos_y][pos_x-1] ? 1 : 2) : 0; ;
		top_left_type = pos_y > 0 && pos_x >0 && slice_mb_index > WIDTH  ? (intra_mode[pos_y-1][pos_x-1] ? 1 : 2) : 0;;
		top_right_type = pos_y > 0 && pos_x < WIDTH-1 && slice_mb_index >= WIDTH - 1 ? (intra_mode[pos_y-1][pos_x+1] ? 1 : 2) : 0;


        if(top_type != 1 && (top_type==0 || pps.constrained_intra_pred_flag)){
            topleft_samples_available&= 0xB3FF;
            top_samples_available&= 0x33FF;
            topright_samples_available&= 0x26EA;
        }
        if(left_type != 1 && (left_type==0 || pps.constrained_intra_pred_flag)){
			topleft_samples_available&= 0xDF5F;
			left_samples_available&= 0x5F5F;
        }

        if(top_left_type != 1 && (top_left_type==0 || pps.constrained_intra_pred_flag))
           topleft_samples_available&= 0x7FFF;

        if(top_right_type != 1 && (top_right_type==0 || pps.constrained_intra_pred_flag))
           topright_samples_available&= 0xFBFF;
}

void IntraPred16(unsigned short mb_index, unsigned short I16_pred_mode, const PPS_t& pps)
{
	unsigned short pos_y = mb_index / WIDTH;
	unsigned short pos_x = mb_index % WIDTH;

	unsigned short i, j;

	bool left_avail = false;
	bool up_avail = false;
	bool up_left_avail = false;
	short H, V, a, b, c;

	short predL;

		up_avail = (top_samples_available<<0)&0x8000;
		left_avail = (left_samples_available<<0)&0x8000;
		up_left_avail = (topleft_samples_available<<0)&0x8000;

	pos_x = pos_x * 16;
	pos_y = pos_y * 16;
	if (mb_index == 116) {
		mb_index+=0;
	}
	switch ( I16_pred_mode )
	{
	case 0: // vertical
		assert(up_avail == true);
		for (i = 0; i < 16; i++)
		{
			for (j = 0; j < 16; j++)
			{
				current_pic.Y[pos_y + i][pos_x + j] += current_pic.Y[pos_y - 1][pos_x + j];
			}
		}
		break;
	case 1: // horizontal
		assert(left_avail == true);
		for (i = 0; i < 16; i++)
		{
			for (j = 0; j < 16; j++)
			{
				current_pic.Y[pos_y + i][pos_x + j] += current_pic.Y[pos_y + i][pos_x - 1];
			}
		}
		break;
	case 2: // DC
		if (up_avail == true && left_avail == true)
		{
			predL = 0;
			for (i = 0; i < 16; i++)
			{
				predL += current_pic.Y[pos_y - 1][pos_x + i];
				predL += current_pic.Y[pos_y + i][pos_x - 1];
			}
			predL = (predL + 16) >> 5; // +16???
		}
		else if ( up_avail == true && left_avail == false )
		{
			predL = 0;
			for (i = 0; i < 16; i++)
			{
				predL += current_pic.Y[pos_y - 1][pos_x + i];
			}
			predL = (predL + 8) >> 4;
		}
		else if ( up_avail == false && left_avail == true )
		{
			predL = 0;
			for (i = 0; i < 16; i++)
			{
				predL += current_pic.Y[pos_y + i][pos_x - 1];
			}
			predL = (predL + 8) >> 4;
		}
		else
		{
			predL = 128;
		}

		for ( i = 0; i < 16; i++ )
		{
			for ( j = 0; j < 16; j++ )
			{
				current_pic.Y[pos_y + i][pos_x + j] += predL;
			}
		}
		break;
	case 3: // Plain
		if (pic_num == 1){
			int abc = 1;
		}
		assert(up_avail == true && left_avail == true && up_left_avail == true);
		H = 0;
		V = 0;
		for (i = 0; i < 8; i++)
		{
			V += ( i + 1 ) * (current_pic.Y[pos_y + 8 + i][pos_x - 1] - current_pic.Y[pos_y + 6 - i][pos_x - 1]);
			H += ( i + 1 ) * (current_pic.Y[pos_y - 1][pos_x + 8 + i] - current_pic.Y[pos_y - 1][pos_x + 6 - i]);
		}
		a = 16 * (current_pic.Y[pos_y - 1][pos_x + 15] + current_pic.Y[pos_y + 15][pos_x - 1]);
		b = (5 * H + 32) >> 6;
		c = (5 * V + 32) >> 6;
		
		for (i = 0; i < 16; i++)
		{
			for (j = 0; j < 16; j++)
			{
				// 公式中predL[x, y]对应current.Y[y][x]的位置
				predL = (a + b * (j - 7) + c * (i - 7) + 16) >> 5;
				predL = Clip3(0, 255, predL);
				current_pic.Y[pos_y + i][pos_x + j] += predL;
			}
		}
		break;
	default:
		assert(0);

	}

	for (i = 0; i < 16; i++)
	{
		for (j = 0; j < 16; j++)
		{
			current_pic.Y[pos_y + i][pos_x + j] = Clip3(0, 255, current_pic.Y[pos_y + i][pos_x + j]);
		}
	}
			#ifdef DUMP_DATA
	int k,xx,yy;
	for(k = 0; k < 16; k++)
	{
		switch(k)
		{
			case 0:xx = 0 ;yy = 0; break;
			case 1:xx = 4 ;yy = 0;break;
			case 2:xx = 0 ;yy = 4; break;
			case 3:xx = 4 ;yy = 4; break;

			case 4:xx = 8 ;yy = 0; break;
			case 5:xx = 12 ;yy = 0; break;
			case 6:xx = 8 ;yy = 4; break;
			case 7:xx = 12 ;yy = 4; break;

			case 8:xx = 0 ;yy = 8; break;
			case 9:xx = 4 ;yy = 8; break;
			case 10:xx = 0 ;yy = 12; break;
			case 11:xx = 4 ;yy = 12; break;

			case 12:xx = 8 ;yy = 8; break;
			case 13:xx = 12 ;yy = 8; break;
			case 14:xx = 8 ;yy = 12; break;
			case 15:xx = 12 ;yy = 12; break;
		}
		if (c_sum_out && c_sum_out_hex){
			fprintf(c_sum_out_hex, "pic_num:%5d mb_index:%5d blk:%5d\n",pic_num, mb_index, k);
			fprintf(c_sum_out, "pic_num:%5d mb_index:%5d blk:%5d\n",pic_num, mb_index, k);
			for (i = 0; i < 4; i++)
			{
				for (j = 0; j < 4; j++)
				{
					fprintf(c_sum_out_hex, "%02x   ", current_pic.Y[pos_y + i + yy][pos_x + j+xx]);
					fprintf(c_sum_out, "%5d", current_pic.Y[pos_y + i + yy][pos_x + j+xx]);
				}
				fprintf(c_sum_out_hex, "\n");	
				fprintf(c_sum_out, "\n");
			}
			fprintf(c_sum_out_hex, "\n");	
			fprintf(c_sum_out, "\n");
		}

	}
#endif
}


void IntraPred4(unsigned short mb_index, unsigned short block_idx, const PPS_t& pps)
{
	static const unsigned short i_blockidx[16] = {0,0,1,1,0,0,1,1,2,2,3,3,2,2,3,3};
	static const unsigned short j_blockidx[16] = {0,1,0,1,2,3,2,3,0,1,0,1,2,3,2,3};
    // 0  1  4  5
	// 2  3  6  7
	// 8  9  12 13
	// 10 11 14 15
	// blockidx=12 i_blockidx=2 j_blockidx=2 即blockidx对应的4x4块的x,y偏移
	static const bool up_right[16] = {true,true,true,false,
										true,true,true,false,
										true,true,true,false,
										true,false,true,false};
	unsigned short pos_y = mb_index / WIDTH;
	unsigned short pos_x = mb_index % WIDTH;

	unsigned short i, j;

	short ref[13] = { 0 };
	short predL;

	unsigned short offset_i = pos_y * 4;
	unsigned short offset_j = pos_x * 4;

	bool up_avail       = false;
	bool left_avail     = false;
	bool up_left_avail  = false;
	bool up_right_avail = false;
	
	offset_i += i_blockidx[block_idx];
	offset_j += j_blockidx[block_idx];
	if (mb_index == 704 && pic_num == 0)
{
	mb_index += 0;
}
	unsigned short intra4x4_pred_mode = intra_pred_mode[offset_i][offset_j];


	// offset_i 4n+0, 4n+1, 4n+2, 4n+3 除了第一行4n+0其余上面都是4x4帧内预测块
	// 第二三四行的上面必可用 第二三四列左边必可用


		up_avail = (top_samples_available<<block_idx)&0x8000;
		left_avail = (left_samples_available<<block_idx)&0x8000;
		up_left_avail = (topleft_samples_available<<block_idx)&0x8000;
		up_right_avail = (topright_samples_available<<block_idx)&0x8000;

	offset_i = offset_i * 4;
	offset_j = offset_j * 4;

	//	ref[0]	ref[1]	ref[2]	ref[3]	ref[4]	ref[5] ref[6] ref[7] ref[8]
	//	ref[9]	x		x		x		x
	//	ref[10]	x		x		x		x
	//	ref[11]	x		x		x		x
	//	ref[12]	x		x		x		x
	if(up_left_avail == true)
	{
		ref[0]	= current_pic.Y[offset_i -1][offset_j -1];
	}

	if(up_avail == true) 
	{
		ref[1]	= current_pic.Y[offset_i -1][offset_j   ];
		ref[2]	= current_pic.Y[offset_i -1][offset_j +1];
		ref[3]	= current_pic.Y[offset_i -1][offset_j +2];
		ref[4]	= current_pic.Y[offset_i -1][offset_j +3];
	}

	if(left_avail == true) 
	{
		ref[9]	= current_pic.Y[offset_i   ][offset_j -1];
		ref[10] = current_pic.Y[offset_i +1][offset_j -1];
		ref[11] = current_pic.Y[offset_i +2][offset_j -1];
		ref[12] = current_pic.Y[offset_i +3][offset_j -1];
	}

	if(up_right_avail == true) 
	{
		ref[5] = current_pic.Y[offset_i -1][offset_j +4];
		ref[6] = current_pic.Y[offset_i -1][offset_j +5];
		ref[7] = current_pic.Y[offset_i -1][offset_j +6];
		ref[8] = current_pic.Y[offset_i -1][offset_j +7];
	}
	else if(up_avail == true) 
	{
		ref[5] = 
		ref[6] = 
		ref[7] = 
		ref[8] = current_pic.Y[offset_i -1][offset_j +3];
		up_right_avail = true; // ??
	}


	// 填充从current_pic.Y[offset_i][offset_j]到current_pic.Y[offset_i+4][offset_j+4]的区域
	switch (intra4x4_pred_mode)
	{
	case 0: // vertical
		assert(up_avail == true);
		for (i = 0; i < 4; i++)
		{
			for (j = 0; j < 4; j++)
			{
				current_pic.Y[offset_i+i][offset_j+j] += ref[j+1]; 
			}
		}
		break;
	case 1: // horizontal
		assert(left_avail == true);
		for (i = 0; i < 4; i++)
		{
			for (j = 0; j < 4; j++)
			{
				current_pic.Y[offset_i+i][offset_j+j] += ref[9+i];
			}
		}
		break;
	case 2: // DC
		if (up_avail && left_avail)
		{
			predL = 0;
			for (i = 0; i < 4; i++) // ref[1 - 4] ref[9 - 12]
			{
				predL += ref[i + 9];
				predL += ref[i + 1];
			}
			predL = (predL + 4) / 8;

		}
		else if (up_avail)
		{
			predL = 0;
			for (i = 0; i < 4; i++)
			{
				predL += ref[i+1];
			}
			predL = (predL + 2) / 4;

		}
		else if (left_avail)
		{
			predL = 0;
			for (i = 0; i < 4; i++)
			{
				predL += ref[i + 9];
			}
			predL = (predL + 2) / 4;

		}
		else
		{
			predL = 128;
		}

		for (i = 0; i < 4; i++)
		{
			for (j = 0; j < 4; j++)
			{
				current_pic.Y[offset_i+i][offset_j+j] += predL;
			}
		}
		break;
	case 3: // diagonal down left
		assert(up_avail == true);
		assert(up_right_avail == true);
		predL = (ref[1] + ref[3] + 2 * ref[2] + 2) >> 2;
		current_pic.Y[offset_i][offset_j] += predL;
		
		predL = (ref[2] + ref[4] + 2 * ref[3] + 2) >> 2;
		current_pic.Y[offset_i  ][offset_j+1] += predL;
		current_pic.Y[offset_i+1][offset_j  ] += predL;

		predL = (ref[3] + ref[5] + 2 * ref[4] + 2) >> 2;
		current_pic.Y[offset_i  ][offset_j+2] += predL;
		current_pic.Y[offset_i+1][offset_j+1] += predL;
		current_pic.Y[offset_i+2][offset_j  ] += predL;

		predL = (ref[4] + ref[6] + 2 * ref[5] + 2) >> 2;
		current_pic.Y[offset_i  ][offset_j+3] += predL;
		current_pic.Y[offset_i+1][offset_j+2] += predL;
		current_pic.Y[offset_i+2][offset_j+1] += predL;
		current_pic.Y[offset_i+3][offset_j  ] += predL;

		predL = (ref[5] + ref[7] + 2 * ref[6] + 2) >> 2;
		current_pic.Y[offset_i+1][offset_j+3] += predL;
		current_pic.Y[offset_i+2][offset_j+2] += predL;
		current_pic.Y[offset_i+3][offset_j+1] += predL;

		predL = (ref[6] + ref[8] + 2 * ref[7] + 2) >> 2;
		current_pic.Y[offset_i+2][offset_j+3] += predL;
		current_pic.Y[offset_i+3][offset_j+2] += predL;

		predL = (ref[7] + 3 * ref[8] + 2) >> 2;
		current_pic.Y[offset_i+3][offset_j+3] += predL;

		break;
	case 4: // diagonal down right
		assert(up_avail == true);
		assert(up_left_avail == true);
		assert(left_avail == true);
		
		predL = (2 * ref[0] + ref[1] + ref[9] + 2) >> 2;
		current_pic.Y[offset_i+1][offset_j+1] += predL;
		current_pic.Y[offset_i+2][offset_j+2] += predL;
		current_pic.Y[offset_i+3][offset_j+3] += predL;
		current_pic.Y[offset_i  ][offset_j  ] += predL;

		predL = (2 * ref[9] + ref[0] + ref[10] + 2) >> 2;
		current_pic.Y[offset_i+3][offset_j+2] += predL;
		current_pic.Y[offset_i+2][offset_j+1] += predL;
		current_pic.Y[offset_i+1][offset_j  ] += predL;

		predL = (2 * ref[10] + ref[9] + ref[11] + 2) >> 2;
		current_pic.Y[offset_i+3][offset_j+1] += predL;
		current_pic.Y[offset_i+2][offset_j  ] += predL;

		current_pic.Y[offset_i+3][offset_j  ] += (ref[11] * 2 + ref[12] + ref[10] + 2) >> 2;

		predL = (2 * ref[1] + ref[0] + ref[2] + 2) >> 2;
		current_pic.Y[offset_i+1][offset_j+2] += predL;
		current_pic.Y[offset_i+2][offset_j+3] += predL;
		current_pic.Y[offset_i  ][offset_j+1] += predL;

		predL = (2 * ref[2] + ref[1] + ref[3] + 2) >> 2;
		current_pic.Y[offset_i+1][offset_j+3] += predL;
		current_pic.Y[offset_i  ][offset_j+2] += predL;

		current_pic.Y[offset_i  ][offset_j+3] += (2 * ref[3] + ref[2] + ref[4] + 2) >> 2;

		break;
	case 5: // vertical right
		assert(up_left_avail == true);
		assert(up_avail == true);
		assert(left_avail == true);
		
		predL = (ref[0] + ref[1] + 1) >> 1;
		current_pic.Y[offset_i  ][offset_j  ] += predL;
		current_pic.Y[offset_i+2][offset_j+1] += predL;

		predL = (ref[1] + ref[2] + 1) >> 1;
		current_pic.Y[offset_i  ][offset_j+1] += predL;
		current_pic.Y[offset_i+2][offset_j+2] += predL;

		predL = (ref[2] + ref[3] + 1) >> 1;
		current_pic.Y[offset_i  ][offset_j+2] += predL;
		current_pic.Y[offset_i+2][offset_j+3] += predL;

		predL = (ref[9] + 2 * ref[0] + ref[1] + 2) >> 2;
		current_pic.Y[offset_i+1][offset_j  ] += predL;
		current_pic.Y[offset_i+3][offset_j+1] += predL;

		predL = (ref[0] + 2 * ref[1] + ref[2] + 2) >> 2;
		current_pic.Y[offset_i+1][offset_j+1] += predL;
		current_pic.Y[offset_i+3][offset_j+2] += predL;

		predL = (ref[1] + 2 * ref[2] + ref[3] + 2) >> 2;
		current_pic.Y[offset_i+1][offset_j+2] += predL;
		current_pic.Y[offset_i+3][offset_j+3] += predL;

		current_pic.Y[offset_i  ][offset_j+3] += (ref[3] + ref[4 ] + 1) >> 1;
		current_pic.Y[offset_i+1][offset_j+3] += (ref[2] + ref[3 ] * 2 + ref[4 ] + 2) >> 2;
		current_pic.Y[offset_i+2][offset_j  ] += (ref[0] + ref[9 ] * 2 + ref[10] + 2) >> 2;
		current_pic.Y[offset_i+3][offset_j  ] += (ref[9] + ref[10] * 2 + ref[11] + 2) >> 2;	

		break;
	case 6: // horizontal down
		assert(up_avail == true);
		assert(up_left_avail == true);
		assert(left_avail == true);

		predL = (ref[0] + ref[9] + 1) >> 1;
		current_pic.Y[offset_i  ][offset_j  ] += predL;
		current_pic.Y[offset_i+1][offset_j+2] += predL;

		predL = (ref[9] + ref[0] * 2 + ref[1] + 2) >> 2;
		current_pic.Y[offset_i  ][offset_j+1] += predL;
		current_pic.Y[offset_i+1][offset_j+3] += predL;

		predL = (ref[9] + ref[10] + 1) >> 1;
		current_pic.Y[offset_i+1][offset_j  ] += predL;
		current_pic.Y[offset_i+2][offset_j+2] += predL;

		predL = (ref[0] + ref[9] * 2 + ref[10] + 2) >> 2;
		current_pic.Y[offset_i+1][offset_j+1] += predL;
		current_pic.Y[offset_i+2][offset_j+3] += predL;

		predL = (ref[10] + ref[11] + 1) >> 1;
		current_pic.Y[offset_i+2][offset_j  ] += predL;
		current_pic.Y[offset_i+3][offset_j+2] += predL;

		predL = (ref[9] + ref[10] * 2 + ref[11] + 2) >> 2;
		current_pic.Y[offset_i+2][offset_j+1] += predL;
		current_pic.Y[offset_i+3][offset_j+3] += predL;

		current_pic.Y[offset_i+3][offset_j  ] += (ref[11] + ref[12] + 1) >> 1;
		current_pic.Y[offset_i+3][offset_j+1] += (ref[10] + ref[11] * 2 + ref[12] + 2) >> 2;
		current_pic.Y[offset_i  ][offset_j+3] += (ref[1 ] + ref[2 ] * 2 + ref[3 ] + 2) >> 2;
		current_pic.Y[offset_i  ][offset_j+2] += (ref[0 ] + ref[1 ] * 2 + ref[2 ] + 2) >> 2;

		break;
	case 7: // vertical left
		assert(up_avail == true);
		assert(up_right_avail == true);
		
		predL = (ref[2] + ref[3] + 1) >> 1;
		current_pic.Y[offset_i  ][offset_j+1] += predL;
		current_pic.Y[offset_i+2][offset_j  ] += predL;

		predL = (ref[3] + ref[4] + 1) >> 1;
		current_pic.Y[offset_i  ][offset_j+2] += predL;
		current_pic.Y[offset_i+2][offset_j+1] += predL;

		predL = (ref[4] + ref[5] + 1) >> 1;
		current_pic.Y[offset_i  ][offset_j+3] += predL;
		current_pic.Y[offset_i+2][offset_j+2] += predL;

		predL = (ref[2] + 2 * ref[3] + ref[4] + 2) >> 2;
		current_pic.Y[offset_i+1][offset_j+1] += predL;
		current_pic.Y[offset_i+3][offset_j  ] += predL;

		predL = (ref[3] + 2 * ref[4] + ref[5] + 2) >> 2;
		current_pic.Y[offset_i+1][offset_j+2] += predL;
		current_pic.Y[offset_i+3][offset_j+1] += predL;

		predL = (ref[4] + 2 * ref[5] + ref[6] + 2) >> 2;
		current_pic.Y[offset_i+1][offset_j+3] += predL;
		current_pic.Y[offset_i+3][offset_j+2] += predL;

		current_pic.Y[offset_i+2][offset_j+3] += (ref[5] + ref[6] + 1) >> 1;
		current_pic.Y[offset_i+1][offset_j  ] += (ref[1] + ref[2] * 2 + ref[3] + 2) >> 2;
		current_pic.Y[offset_i  ][offset_j  ] += (ref[1] + ref[2] + 1) >> 1;		
		current_pic.Y[offset_i+3][offset_j+3] += (ref[5] + ref[6] * 2 + ref[7] + 2) >> 2;

		break;
	case 8: // horizontal up
		assert(left_avail == true);
		
		current_pic.Y[offset_i][offset_j  ] += (ref[9] + ref[10] + 1) >> 1;
		current_pic.Y[offset_i][offset_j+1] += (ref[9] + 2 * ref[10] + ref[11] + 2) >> 2;

		predL = (ref[10] + ref[11] + 1) >> 1;
		current_pic.Y[offset_i  ][offset_j+2] += predL;
		current_pic.Y[offset_i+1][offset_j  ] += predL;

		predL = (ref[10] + 2 * ref[11] + ref[12] + 2) >> 2;
		current_pic.Y[offset_i  ][offset_j+3] += predL;
		current_pic.Y[offset_i+1][offset_j+1] += predL;

		predL = (ref[11] + ref[12] + 1) >> 1;
		current_pic.Y[offset_i+1][offset_j+2] += predL;
		current_pic.Y[offset_i+2][offset_j  ] += predL;

		predL = (ref[11] + 3 * ref[12] + 2) >> 2;
		current_pic.Y[offset_i+1][offset_j+3] += predL;
		current_pic.Y[offset_i+2][offset_j+1] += predL;

		predL = ref[12];
		current_pic.Y[offset_i+3][offset_j  ] += predL;
		current_pic.Y[offset_i+2][offset_j+2] += predL;
		current_pic.Y[offset_i+2][offset_j+3] += predL;
		current_pic.Y[offset_i+3][offset_j+1] += predL;
		current_pic.Y[offset_i+3][offset_j+2] += predL;
		current_pic.Y[offset_i+3][offset_j+3] += predL;

		break;
	default:
		assert(0);
	}
	for (i = 0; i < 4; i++)
	{
		for (j = 0; j < 4; j++)
		{
			current_pic.Y[offset_i + i][offset_j + j] = Clip3(0, 255, current_pic.Y[offset_i + i][offset_j + j]);
		}
	}
	if (c_sum_out && c_sum_out_hex){
		fprintf(c_sum_out_hex, "pic_num:%5d mb_index:%5d blk:%5d\n",pic_num, mb_index, block_idx);
		fprintf(c_sum_out, "pic_num:%5d mb_index:%5d blk:%5d\n",pic_num, mb_index, block_idx);
		for (i = 0; i < 4; i++)
		{
			for (j = 0; j < 4; j++)
			{
				fprintf(c_sum_out_hex, "%02x   ", current_pic.Y[offset_i + i][offset_j + j]);
				fprintf(c_sum_out, "%5d", current_pic.Y[offset_i + i][offset_j + j]);
			}
			fprintf(c_sum_out_hex, "\n");	
			fprintf(c_sum_out, "\n");
		}
		fprintf(c_sum_out_hex, "\n");	
		fprintf(c_sum_out, "\n");
	} 
}

void IntraPredChroma(unsigned short mb_index, unsigned short chroma_pred_mode, const PPS_t& pps)
{
	unsigned short i, j;
	unsigned short pos_y, pos_x;
	short H[2], V[2], a[2], b[2], c[2];
	short predC[2] = { 0 };
	short temp[8] = { 0 };
	//				temp[0]	temp[1]				temp[4]	temp[5]
	//		temp[2]	Cb					temp[6]	Cr
	//		temp[3]						temp[7]
	

	pos_y = mb_index / WIDTH;
	pos_x = mb_index % WIDTH;
	
	bool left_avail = false;
	bool up_avail = false;
	bool up_left_avail = false;

		up_avail = (top_samples_available<<0)&0x8000;
		left_avail = (left_samples_available<<0)&0x8000;
		up_left_avail = (topleft_samples_available<<0)&0x8000;


	pos_x = pos_x * 8;
	pos_y = pos_y * 8;

	switch (chroma_pred_mode)
	{
	case 2: // vertical 
		assert(up_avail == true);
		for (i = 0; i < 8; i++)
		{
			for (j = 0; j < 8; j++)
			{
				current_pic.U[pos_y+i][pos_x+j] += current_pic.U[pos_y-1][pos_x+j];
				current_pic.V[pos_y+i][pos_x+j] += current_pic.V[pos_y-1][pos_x+j];
			}
		}
		break;
	case 1: // horizontal
		assert(left_avail == true);
		for (i = 0; i < 8; i++)
		{
			for (j = 0; j < 8; j++)
			{
				current_pic.U[pos_y+i][pos_x+j] += current_pic.U[pos_y+i][pos_x-1];
				current_pic.V[pos_y+i][pos_x+j] += current_pic.V[pos_y+i][pos_x-1];
			}
		}
		break;
	case 0: // DC
		if (up_avail)
		{
			for (i = 0; i < 4; i++)
			{
				temp[0] += current_pic.U[pos_y - 1][pos_x + i];
				temp[1] += current_pic.U[pos_y - 1][pos_x + 4 + i];
				temp[4] += current_pic.V[pos_y - 1][pos_x + i];
				temp[5] += current_pic.V[pos_y - 1][pos_x + 4 + i];
			}
		}

		if (left_avail)
		{
			for (i = 0; i < 4; i++)
			{
				temp[2] += current_pic.U[pos_y + i][pos_x - 1];
				temp[3] += current_pic.U[pos_y + 4 + i][pos_x - 1];
				temp[6] += current_pic.V[pos_y + i][pos_x - 1];
				temp[7] += current_pic.V[pos_y + 4 + i][pos_x - 1];
			}
		}

		if (up_avail && left_avail)
		{
			predC[0] = (temp[0] + temp[2] + 4) >> 3;
			predC[1] = (temp[4] + temp[6] + 4) >> 3;		
			for (i = 0; i < 4; i++)
			{
				for (j = 0; j < 4; j++)
				{
					current_pic.U[pos_y + i][pos_x + j] += predC[0];
					current_pic.V[pos_y + i][pos_x + j] += predC[1];
				}
			}
			
			predC[0] = (temp[1] + 2) >> 2;
			predC[1] = (temp[5] + 2) >> 2;
			for (i = 0; i < 4; i++)
			{
				for (j = 4; j < 8; j++)
				{
					current_pic.U[pos_y + i][pos_x + j] += predC[0];
					current_pic.V[pos_y + i][pos_x + j] += predC[1];
				}
			}

			predC[0] = (temp[3] + 2) >> 2;
			predC[1] = (temp[7] + 2) >> 2;
			for (i = 4; i < 8; i++)
			{
				for (j = 0; j < 4; j++)
				{
					current_pic.U[pos_y + i][pos_x + j] += predC[0];
					current_pic.V[pos_y + i][pos_x + j] += predC[1];
				}
			}

			predC[0] = (temp[1] + temp[3] + 4) >> 3;
			predC[1] = (temp[5] + temp[7] + 4) >> 3;
			for (i = 4; i < 8; i++)
			{
				for (j = 4; j < 8; j++)
				{
					current_pic.U[pos_y + i][pos_x + j] += predC[0];
					current_pic.V[pos_y + i][pos_x + j] += predC[1];
				}
			}

		}
		else if (up_avail)
		{
			predC[0] = (temp[0] + 2) >> 2;
			predC[1] = (temp[4] + 2) >> 2;
			for (i = 0; i < 8; i++)
			{
				for (j = 0; j < 4; j++)
				{
					current_pic.U[pos_y + i][pos_x + j] += predC[0];
					current_pic.V[pos_y + i][pos_x + j] += predC[1];
				}
			}

			predC[0] = (temp[1] + 2) >> 2;
			predC[1] = (temp[5] + 2) >> 2;
			for (i = 0; i < 8; i++)
			{
				for (j = 4; j < 8; j++)
				{
					current_pic.U[pos_y + i][pos_x + j] += predC[0];
					current_pic.V[pos_y + i][pos_x + j] += predC[1];
				}
			}
		}
		else if (left_avail)
		{
			predC[0] = (temp[2] + 2) >> 2;
			predC[1] = (temp[6] + 2) >> 2;
			for (i = 0; i < 4; i++)
			{
				for (j = 0; j < 8; j++)
				{
					current_pic.U[pos_y + i][pos_x + j] += predC[0];
					current_pic.V[pos_y + i][pos_x + j] += predC[1];
				}
			}

			predC[0] = (temp[3] + 2) >> 2;
			predC[1] = (temp[7] + 2) >> 2;
			for (i = 4; i < 8; i++)
			{
				for (j = 0; j < 8; j++)
				{
					current_pic.U[pos_y + i][pos_x + j] += predC[0];
					current_pic.V[pos_y + i][pos_x + j] += predC[1];
				}
			}
		}
		else
		{
			for (i = 0; i < 8; i++)
			{
				for (j = 0; j < 8; j++)
				{
					current_pic.U[pos_y + i][pos_x + j] += 128;
					current_pic.V[pos_y + i][pos_x + j] += 128;
				}
			}
		}

		break;
	case 3: // plain

		assert(up_avail == true && left_avail == true && up_left_avail == true);
		H[0] = H[1] = 0;
		V[0] = V[1] = 0;
		for (i = 0; i < 4; i++)
		{
			V[0] += (i + 1) * (current_pic.U[pos_y + 4 + i][pos_x - 1] - current_pic.U[pos_y + 2 - i][pos_x - 1]);
			H[0] += (i + 1) * (current_pic.U[pos_y - 1][pos_x + 4 + i] - current_pic.U[pos_y - 1][pos_x + 2 - i]);

			V[1] += (i + 1) * (current_pic.V[pos_y + 4 + i][pos_x - 1] - current_pic.V[pos_y + 2 - i][pos_x - 1]);
			H[1] += (i + 1) * (current_pic.V[pos_y - 1][pos_x + 4 + i] - current_pic.V[pos_y - 1][pos_x + 2 - i]);
		}

		a[0] = 16 * (current_pic.U[pos_y - 1][pos_x + 7] + current_pic.U[pos_y + 7][pos_x - 1]);
		b[0] = (34 * H[0] + 32) >> 6;
		c[0] = (34 * V[0] + 32) >> 6;
		
		a[1] = 16 * (current_pic.V[pos_y - 1][pos_x + 7] + current_pic.V[pos_y + 7][pos_x - 1]);
		b[1] = (34 * H[1] + 32) >> 6;
		c[1] = (34 * V[1] + 32) >> 6;	

		for (i = 0; i < 8; i++)
		{
			for (j = 0; j < 8; j++)
			{
				predC[0] = (a[0] + b[0] * (j - 3) + c[0] * (i - 3) + 16) >> 5;
				predC[0] = Clip3(0, 255, predC[0]);
				predC[1] = (a[1] + b[1] * (j - 3) + c[1] * (i - 3) + 16) >> 5;
				predC[1] = Clip3(0, 255, predC[1]);

				current_pic.U[pos_y+i][pos_x+j] += predC[0];
				current_pic.V[pos_y+i][pos_x+j] += predC[1];
			}
		}
		break;
	default :{
		int abcd = 1;
		break;
	}
		assert(0);

	}

	for (i = 0; i < 8; i++)
	{
		for (j = 0; j < 8; j++)
		{
			current_pic.U[pos_y+i][pos_x+j] = Clip3(0, 255, current_pic.U[pos_y+i][pos_x+j]);
			current_pic.V[pos_y+i][pos_x+j] = Clip3(0, 255, current_pic.V[pos_y+i][pos_x+j]);
		}
	}
	if (c_sum_out && c_sum_out_hex){
		int k,xx,yy;
		for(k = 16; k < 20; k++)
		{
			switch(k)
			{
				case 16:xx = 0 ;yy = 0; break;
				case 17:xx = 4 ;yy = 0;break;
				case 18:xx = 0 ;yy = 4; break;
				case 19:xx = 4 ;yy = 4; break;
			}
			fprintf(c_sum_out_hex, "pic_num:%5d mb_index:%5d blk:%5d\n",pic_num, mb_index, k);
			fprintf(c_sum_out, "pic_num:%5d mb_index:%5d blk:%5d\n",pic_num, mb_index, k);
	
			for (i = 0; i < 4; i++)
			{
				for (j = 0; j < 4; j++)
				{
					fprintf(c_sum_out_hex, "%02x   ", current_pic.U[pos_y + i + yy][pos_x + j+xx]);
					fprintf(c_sum_out, "%5d", current_pic.U[pos_y + i + yy][pos_x + j+xx]);
				}
				fprintf(c_sum_out_hex, "\n");	
				fprintf(c_sum_out, "\n");
			}
			fprintf(c_sum_out_hex, "\n");	
			fprintf(c_sum_out, "\n"); 
		}
		for(k = 20; k < 24; k++)
		{
			switch(k)
			{
				case 20:xx = 0 ;yy = 0; break;
				case 21:xx = 4 ;yy = 0;break;
				case 22:xx = 0 ;yy = 4; break;
				case 23:xx = 4 ;yy = 4; break;
			}
			fprintf(c_sum_out_hex, "pic_num:%5d mb_index:%5d blk:%5d\n",pic_num, mb_index, k);
			fprintf(c_sum_out, "pic_num:%5d mb_index:%5d blk:%5d\n",pic_num, mb_index, k);
			for (i = 0; i < 4; i++)
			{
				for (j = 0; j < 4; j++)
				{
					fprintf(c_sum_out_hex, "%02x   ", current_pic.V[pos_y + i + yy][pos_x + j+xx]);
					fprintf(c_sum_out, "%5d", current_pic.V[pos_y + i + yy][pos_x + j+xx]);
				}
				fprintf(c_sum_out_hex, "\n");	
				fprintf(c_sum_out, "\n");
			}
			fprintf(c_sum_out_hex, "\n");	
			fprintf(c_sum_out, "\n");
		}
	}
}





















