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

#include "bitstream_header.h"
#include "macroblock.h"
#include <assert.h>
#include "slice.h"
#include "interpred.h"

extern unsigned short WIDTH, HEIGHT;
extern unsigned short **intra_pred_mode;
extern unsigned short **intra_mode;
extern unsigned short **qp_z;
extern unsigned short **qp_z_c;
extern unsigned short **nnz;
extern unsigned short ***nnz_chroma;
extern short **RefIdx;
extern short ***MV;
extern unsigned short slice_mb_index;
extern unsigned short ref_all_same;

extern Picture_t current_pic;
extern Picture_t ref_pic[5];
extern macroblock_t cur_mb;
extern unsigned short pic_num;
extern unsigned short mb_index;

#define FIR_filter(a,b,c) ( ((c) << 4 ) + (a) - (b) - (( (b)-(c) ) << 2 ) )
//这里的height ,width可以在函数中定义
#define C4(val) Clip3(0, height, val)
#define C5(val) Clip3(0, width, val)


void InterPred(unsigned short mb_index)
{
    unsigned short x0 = mb_index % WIDTH;
	unsigned short y0 = mb_index / WIDTH;
	unsigned short i, j,k, x, y;
	short mv_x;
	short mv_y;
	short ref;
	short mv_x_t;
	short mv_y_t;
	short ref_t;
	int block_idx = 0;
	int count = 0;
	
	static int mv_x_min = 0;
	static int mv_x_max = 0;
	static int mv_y_min = 0;
	static int mv_y_max = 0;
	if (pic_num == 1 && mb_index == 3){
		int abc =1;
	}
	for ( k = 0; k < 16; k++ )
	{
		switch (k)
		{
			case 0 : j = 0; i = 0; break;
			case 1 : j = 0; i = 1; break;
			case 2 : j = 1; i = 0; break;
			case 3 : j = 1; i = 1; break;
			case 4 : j = 0; i = 2; break;
			case 5 : j = 0; i = 3; break;
			case 6 : j = 1; i = 2; break;
			case 7 : j = 1; i = 3; break;
			case 8 : j = 2; i = 0; break;
			case 9 : j = 2; i = 1; break;
			case 10: j = 3; i = 0; break;
			case 11: j = 3; i = 1; break;
			case 12: j = 2; i = 2; break;
			case 13: j = 2; i = 3; break;
			case 14: j = 3; i = 2; break;
			case 15: j = 3; i = 3; break;
		}
		x = x0 * 16 + i * 4;
		y = y0 * 16 + j * 4;
		mv_x = (x << 2) + MV[0][(y + j) / 4][(x + i) / 4];
		mv_y = (y << 2) + MV[1][(y + j) / 4][(x + i) / 4];

		if (mv_x < mv_x_min){
			mv_x_min = mv_x;
		//	printf("out of bound %d,%d ----------------------\n",mv_x, mv_y);
		}
		if (mv_x > mv_x_max){
			mv_x_max = mv_x;
		//	printf("out of bound %d,%d ----------------------\n",mv_x, mv_y);
		}
		if (mv_y < mv_y_min){
			mv_y_min = mv_y;
		//	printf("out of bound %d,%d ----------------------\n",mv_x, mv_y);
		}
		if (mv_y > mv_y_max){
			mv_y_max = mv_y;
		//	printf("out of bound %d,%d ----------------------\n",mv_x, mv_y);
		}
		ref = RefIdx[y / 8 ][x / 8];
		
		get_block_subpixel(current_pic.Y, mv_x, mv_y, 4, 4, x, y, ref);
		
		if (count == 0){
			mv_x_t = MV[0][(y + j) / 4][(x + i) / 4];
			mv_y_t = MV[1][(y + j) / 4][(x + i) / 4];
			ref_t = RefIdx[y / 8 ][x / 8];
			count++;
		}
		else {
			if (MV[0][(y + j) / 4][(x + i) / 4] == mv_x_t && 
				MV[1][(y + j) / 4][(x + i) / 4] == mv_y_t && 
				ref_t == RefIdx[y / 8 ][x / 8]){
				count++;
			}
		}		
	}
	
	for ( i = 0; i < 2; i++ )
	{
		for (j = 0; j < 2; j++)
		{
			x = x0 * 16 + i * 8;
			y = y0 * 16 + j * 8;
			mv_x = (x << 2) + MV[0][(y + j) / 4][(x + i) / 4];
			mv_y = (y << 2) + MV[1][(y + j) / 4][(x + i) / 4];
			ref = RefIdx[y / 8 ][x / 8];
			get_block_subpixel_c(current_pic.U, current_pic.V, mv_x, mv_y, 4, 4, x / 2, y / 2, ref);
		}
	}
	int xx,yy;
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
					fprintf(c_sum_out_hex, "%02x   ", current_pic.Y[y0 * 16 + i + yy][x0 * 16 + j+xx]);
					fprintf(c_sum_out, "%5d", current_pic.Y[y0 * 16 + i + yy][x0 * 16 + j+xx]);
				}
				fprintf(c_sum_out_hex, "\n");	
				fprintf(c_sum_out, "\n");
			}
			fprintf(c_sum_out_hex, "\n");	
			fprintf(c_sum_out, "\n");
		}
	}
	if (c_sum_out && c_sum_out_hex){
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
					fprintf(c_sum_out_hex, "%02x   ", current_pic.U[y0 * 8 + i + yy][x0 * 8 + j+xx]);
					fprintf(c_sum_out, "%5d", current_pic.U[y0*8 + i + yy][x0*8 + j+xx]);
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
					fprintf(c_sum_out_hex, "%02x   ", current_pic.V[y0 * 8 + i + yy][x0 * 8 + j+xx]);
					fprintf(c_sum_out, "%5d", current_pic.V[y0*8 + i + yy][x0*8 + j+xx]);
				}
				fprintf(c_sum_out_hex, "\n");	
				fprintf(c_sum_out, "\n");
			}
			fprintf(c_sum_out_hex, "\n");	
			fprintf(c_sum_out, "\n");
		}
	}
}

// mv_x, mv_y : 运动向量指向的位置，以像素的四倍为单位
// x,y : 原来的位置
void get_block_subpixel(short** p, 
						short mv_x, 
						short mv_y, 
						unsigned short MbPartWidth, 
						unsigned short MbPartHeight,
						unsigned short x, 
						unsigned short y,
						short ref)
{
	unsigned short height = HEIGHT * 16 - 1;
	unsigned short width = WIDTH * 16 - 1;
	
	short pixel_mv_x = mv_x >> 2;// 运动向量指向的整像素位置 -2 >> 2 = -1 -2 / 4 = 0 右移2位和除四不能替换
	short pixel_mv_y = mv_y >> 2;
	short dx = (mv_x & 0x3);// 运动向量指向的1/4,1/2位置
	short dy = (mv_y & 0x3);
	short x_tp, y_tp;


	unsigned short i, j;
	static short sub_pixel[21][21] = { 0 };
	int b, h, j1, m, s; // b,h,j1,m,s的数值可能超过short所能表达的范围

	if (pic_num == 209 && mb_index== 3274){
		int abc = 1;
	}
	if ( dx == 0 && dy == 0 )
	{
				if (pic_num == 197 && mb_index== 1858){
					int abc=1;
				}
        for ( i = 0; i < MbPartHeight; i++ )
		{
			for ( j = 0; j < MbPartWidth; j++ )
			{
				y_tp = C4(pixel_mv_y + i);
				x_tp = C5(pixel_mv_x + j);
                p[y + i][x + j] += ref_pic[ref].Y[y_tp][x_tp];
			}
		}
	}
	else if ( dx == 1 && dy == 0 )
	{
        for ( i = 0; i < MbPartHeight; i++ )
		{
			for ( j = 0; j < MbPartWidth; j++ )
			{
                b = FIR_filter(ref_pic[ref].Y[C4(pixel_mv_y + i)][C5(pixel_mv_x + j - 2)] + ref_pic[ref].Y[C4(pixel_mv_y + i)][C5(pixel_mv_x + j + 3)],
					           ref_pic[ref].Y[C4(pixel_mv_y + i)][C5(pixel_mv_x + j - 1)] + ref_pic[ref].Y[C4(pixel_mv_y + i)][C5(pixel_mv_x + j + 2)],
							   ref_pic[ref].Y[C4(pixel_mv_y + i)][C5(pixel_mv_x + j    )] + ref_pic[ref].Y[C4(pixel_mv_y + i)][C5(pixel_mv_x + j + 1)]);
				b = Clip3(0, 255, (b + 16) >> 5);
				
                p[y + i][x + j] += ( ref_pic[ref].Y[C4(pixel_mv_y + i)][C5(pixel_mv_x + j)] + b + 1 ) >> 1;
	
			}
		}
	}
	else if ( dx == 2 && dy == 0 )
	{
        for ( i = 0; i < MbPartHeight; i++ )
		{
			for ( j = 0; j < MbPartWidth; j++ )
			{
                b = FIR_filter(ref_pic[ref].Y[C4(pixel_mv_y + i)][C5(pixel_mv_x + j - 2)] + ref_pic[ref].Y[C4(pixel_mv_y + i)][C5(pixel_mv_x + j + 3)],
					           ref_pic[ref].Y[C4(pixel_mv_y + i)][C5(pixel_mv_x + j - 1)] + ref_pic[ref].Y[C4(pixel_mv_y + i)][C5(pixel_mv_x + j + 2)],
							   ref_pic[ref].Y[C4(pixel_mv_y + i)][C5(pixel_mv_x + j    )] + ref_pic[ref].Y[C4(pixel_mv_y + i)][C5(pixel_mv_x + j + 1)]);
				b = Clip3(0, 255, (b + 16) >> 5);
				
                p[y + i][x + j] += b;
			}
		}
	}
	else if ( dx == 3 && dy == 0 )
	{
        for ( i = 0; i < MbPartHeight; i++ )
		{
			for ( j = 0; j < MbPartWidth; j++ )
			{
                b = FIR_filter(ref_pic[ref].Y[C4(pixel_mv_y + i)][C5(pixel_mv_x + j - 2)] + ref_pic[ref].Y[C4(pixel_mv_y + i)][C5(pixel_mv_x + j + 3)],
					           ref_pic[ref].Y[C4(pixel_mv_y + i)][C5(pixel_mv_x + j - 1)] + ref_pic[ref].Y[C4(pixel_mv_y + i)][C5(pixel_mv_x + j + 2)],
							   ref_pic[ref].Y[C4(pixel_mv_y + i)][C5(pixel_mv_x + j    )] + ref_pic[ref].Y[C4(pixel_mv_y + i)][C5(pixel_mv_x + j + 1)]);
				b = Clip3(0, 255, (b + 16) >> 5);
				
                p[y + i][x + j] += ( ref_pic[ref].Y[C4(pixel_mv_y + i)][C5(pixel_mv_x + j + 1)] + b + 1 ) >> 1;
			}
		}
	}
	else if ( dx == 0 && dy == 1 )
	{
		for ( i = 0; i < MbPartHeight; i++ )
		{
			for ( j = 0; j < MbPartWidth; j++ )
			{
				h = FIR_filter(	ref_pic[ref].Y[C4(pixel_mv_y + i - 2)][C5(pixel_mv_x + j)] + ref_pic[ref].Y[C4(pixel_mv_y + i + 3)][C5(pixel_mv_x + j)],
					            ref_pic[ref].Y[C4(pixel_mv_y + i - 1)][C5(pixel_mv_x + j)] + ref_pic[ref].Y[C4(pixel_mv_y + i + 2)][C5(pixel_mv_x + j)],
					            ref_pic[ref].Y[C4(pixel_mv_y + i    )][C5(pixel_mv_x + j)] + ref_pic[ref].Y[C4(pixel_mv_y + i + 1)][C5(pixel_mv_x + j)]);
				h = Clip3(0, 255, (h + 16) >> 5);

                p[y + i][x + j] += (ref_pic[ref].Y[C4(pixel_mv_y + i)][C5(pixel_mv_x + j)] + h + 1) >> 1;
			}
		}
	}
	else if ( dx == 0 && dy == 2 )
	{
		for ( i = 0; i < MbPartHeight; i++ )
		{
			for ( j = 0; j < MbPartWidth; j++ )
			{
				h = FIR_filter(	ref_pic[ref].Y[C4(pixel_mv_y + i - 2)][C5(pixel_mv_x + j)] + ref_pic[ref].Y[C4(pixel_mv_y + i + 3)][C5(pixel_mv_x + j)],
					            ref_pic[ref].Y[C4(pixel_mv_y + i - 1)][C5(pixel_mv_x + j)] + ref_pic[ref].Y[C4(pixel_mv_y + i + 2)][C5(pixel_mv_x + j)],
					            ref_pic[ref].Y[C4(pixel_mv_y + i    )][C5(pixel_mv_x + j)] + ref_pic[ref].Y[C4(pixel_mv_y + i + 1)][C5(pixel_mv_x + j)]);
				h = Clip3(0, 255, (h + 16) >> 5);

                p[y + i][x + j] += h;
			}
		}
	}
	else if ( dx == 0 && dy == 3 )
	{
		for ( i = 0; i < MbPartHeight; i++ )
		{
			for ( j = 0; j < MbPartWidth; j++ )
			{
				h = FIR_filter(	ref_pic[ref].Y[C4(pixel_mv_y + i - 2)][C5(pixel_mv_x + j)] + ref_pic[ref].Y[C4(pixel_mv_y + i + 3)][C5(pixel_mv_x + j)],
					            ref_pic[ref].Y[C4(pixel_mv_y + i - 1)][C5(pixel_mv_x + j)] + ref_pic[ref].Y[C4(pixel_mv_y + i + 2)][C5(pixel_mv_x + j)],
					            ref_pic[ref].Y[C4(pixel_mv_y + i    )][C5(pixel_mv_x + j)] + ref_pic[ref].Y[C4(pixel_mv_y + i + 1)][C5(pixel_mv_x + j)]);
				h = Clip3(0, 255, (h + 16) >> 5);

                p[y + i][x + j] += (ref_pic[ref].Y[C4(pixel_mv_y + i + 1)][C5(pixel_mv_x + j)] + h + 1) >> 1;
			}
		}
	}
	else if ( dx == 2 ) // x在半像素位置
	{
		for(j = 0;j < MbPartWidth; j++) 
		{
			for( i = 0; i < MbPartHeight + 5; i++ )
			{

				sub_pixel[i][j] = FIR_filter( ref_pic[ref].Y[C4(pixel_mv_y + i - 2)][C5(pixel_mv_x + j - 2)] + ref_pic[ref].Y[C4(pixel_mv_y + i - 2)][C5(pixel_mv_x + j + 3)],
					                          ref_pic[ref].Y[C4(pixel_mv_y + i - 2)][C5(pixel_mv_x + j - 1)] + ref_pic[ref].Y[C4(pixel_mv_y + i - 2)][C5(pixel_mv_x + j + 2)],
					                          ref_pic[ref].Y[C4(pixel_mv_y + i - 2)][C5(pixel_mv_x + j    )] + ref_pic[ref].Y[C4(pixel_mv_y + i - 2)][C5(pixel_mv_x + j + 1)] );	
			}
			for( i = 0; i < MbPartHeight; i++)
			{
				j1 = FIR_filter(sub_pixel[i][j] + sub_pixel[i + 5][j], sub_pixel[i + 1][j] + sub_pixel[i + 4][j], sub_pixel[i + 2][j] + sub_pixel[i + 3][j]);
				j1 = Clip3(0, 255, (j1 + 512) >> 10); 

				if ( dy == 1 )
				{
					b = Clip3(0, 255, (sub_pixel[i + 2][j] + 16) >> 5);
					p[y + i][x + j] += (j1 + b + 1) >> 1;
				}
				else if ( dy == 2 )
				{
					p[y + i][x + j] += j1;
				}
				else if ( dy == 3 )
				{
					s = Clip3(0, 255, (sub_pixel[i + 3][j] + 16) >> 5);
					p[y + i][x + j] += (j1 + s + 1) >> 1;
				}
				else 
				{
					assert(0);
				}
			}		
		}

	}
	else if ( dy == 2 ) // y在半像素位置
	{
		for ( i = 0; i < MbPartHeight; i++ )
		{
			for(j = 0; j < MbPartWidth + 5; j++) 
			{
				sub_pixel[i][j] = FIR_filter( ref_pic[ref].Y[C4(pixel_mv_y + i - 2)][C5(pixel_mv_x + j - 2)] + ref_pic[ref].Y[C4(pixel_mv_y + i + 3)][C5(pixel_mv_x + j - 2)],
					                          ref_pic[ref].Y[C4(pixel_mv_y + i - 1)][C5(pixel_mv_x + j - 2)] + ref_pic[ref].Y[C4(pixel_mv_y + i + 2)][C5(pixel_mv_x + j - 2)],
					                          ref_pic[ref].Y[C4(pixel_mv_y + i    )][C5(pixel_mv_x + j - 2)] + ref_pic[ref].Y[C4(pixel_mv_y + i + 1)][C5(pixel_mv_x + j - 2)]);
			}
			for (j = 0; j < MbPartWidth; j++) 
			{
				j1 = FIR_filter(sub_pixel[i][j] + sub_pixel[i][j + 5], sub_pixel[i][j + 1] + sub_pixel[i][j + 4], sub_pixel[i][j + 2] + sub_pixel[i][j + 3]);
				j1 = Clip3(0, 255, (j1 + 512) >> 10); 

				if ( dx == 1 )
				{
					h = Clip3(0, 255,(sub_pixel[i][j + 2] + 16) >> 5);	
					p[y + i][x + j] += (j1 + h + 1) >> 1;
				}
				else if ( dx == 3 )
				{
					m = Clip3(0, 255, (sub_pixel[i][j + 3] + 16) >> 5);	
					p[y + i][x + j] += (j1 + m + 1) >> 1;
				}
				else 
				{
					assert(0);
				}
			}
		}
	}
	else
	{
		for( i = 0; i < MbPartHeight; i++ )
		{
			for( j = 0; j < MbPartWidth; j++) 
			{
				if( dx == 1 && dy == 1 )
				{
					b = FIR_filter(	ref_pic[ref].Y[C4(pixel_mv_y + i)][C5(pixel_mv_x + j - 2)] + ref_pic[ref].Y[C4(pixel_mv_y + i)][C5(pixel_mv_x + j + 3)],
						            ref_pic[ref].Y[C4(pixel_mv_y + i)][C5(pixel_mv_x + j - 1)] + ref_pic[ref].Y[C4(pixel_mv_y + i)][C5(pixel_mv_x + j + 2)],
						            ref_pic[ref].Y[C4(pixel_mv_y + i)][C5(pixel_mv_x + j    )] + ref_pic[ref].Y[C4(pixel_mv_y + i)][C5(pixel_mv_x + j + 1)] );
					b = Clip3(0, 255, (b + 16) >> 5);

					h = FIR_filter( ref_pic[ref].Y[C4(pixel_mv_y + i - 2)][C5(pixel_mv_x + j)] + ref_pic[ref].Y[C4(pixel_mv_y + i + 3)][C5(pixel_mv_x + j)],
						            ref_pic[ref].Y[C4(pixel_mv_y + i - 1)][C5(pixel_mv_x + j)] + ref_pic[ref].Y[C4(pixel_mv_y + i + 2)][C5(pixel_mv_x + j)],
						            ref_pic[ref].Y[C4(pixel_mv_y + i    )][C5(pixel_mv_x + j)] + ref_pic[ref].Y[C4(pixel_mv_y + i + 1)][C5(pixel_mv_x + j)] );
					h = Clip3(0, 255, (h + 16) >> 5);

					p[y + i][x + j] += (b + h + 1) >> 1;
				}
				else if( dx == 3 && dy == 1 ) 
				{
					m = FIR_filter( ref_pic[ref].Y[C4(pixel_mv_y + i - 2)][C5(pixel_mv_x + j + 1)] + ref_pic[ref].Y[C4(pixel_mv_y + i + 3)][C5(pixel_mv_x + j + 1)],
						            ref_pic[ref].Y[C4(pixel_mv_y + i - 1)][C5(pixel_mv_x + j + 1)] + ref_pic[ref].Y[C4(pixel_mv_y + i + 2)][C5(pixel_mv_x + j + 1)],
						            ref_pic[ref].Y[C4(pixel_mv_y + i    )][C5(pixel_mv_x + j + 1)] + ref_pic[ref].Y[C4(pixel_mv_y + i + 1)][C5(pixel_mv_x + j + 1)]);
					m = Clip3(0, 255, (m + 16) >> 5);

					b = FIR_filter(	ref_pic[ref].Y[C4(pixel_mv_y + i)][C5(pixel_mv_x + j - 2)] + ref_pic[ref].Y[C4(pixel_mv_y + i)][C5(pixel_mv_x + j + 3)],
						            ref_pic[ref].Y[C4(pixel_mv_y + i)][C5(pixel_mv_x + j - 1)] + ref_pic[ref].Y[C4(pixel_mv_y + i)][C5(pixel_mv_x + j + 2)],
						            ref_pic[ref].Y[C4(pixel_mv_y + i)][C5(pixel_mv_x + j    )] + ref_pic[ref].Y[C4(pixel_mv_y + i)][C5(pixel_mv_x + j + 1)]);
					b = Clip3(0, 255, (b + 16) >> 5);

					p[y + i][x + j] += (b + m + 1) >> 1;
				}
				else if( dx == 1 && dy == 3 )
				{
					h = FIR_filter( ref_pic[ref].Y[C4(pixel_mv_y + i - 2)][C5(pixel_mv_x + j)]  + ref_pic[ref].Y[C4(pixel_mv_y + i + 3)][C5(pixel_mv_x + j)],
						            ref_pic[ref].Y[C4(pixel_mv_y + i - 1)][C5(pixel_mv_x + j)]  + ref_pic[ref].Y[C4(pixel_mv_y + i + 2)][C5(pixel_mv_x + j)],
						            ref_pic[ref].Y[C4(pixel_mv_y + i    )][C5(pixel_mv_x + j)]  + ref_pic[ref].Y[C4(pixel_mv_y + i + 1)][C5(pixel_mv_x + j)]);
					h = Clip3(0, 255, (h + 16) >> 5);

					s = FIR_filter( ref_pic[ref].Y[C4(pixel_mv_y + i + 1)][C5(pixel_mv_x + j - 2)] + ref_pic[ref].Y[C4(pixel_mv_y + i + 1)][C5(pixel_mv_x + j + 3)],
						            ref_pic[ref].Y[C4(pixel_mv_y + i + 1)][C5(pixel_mv_x + j - 1)] + ref_pic[ref].Y[C4(pixel_mv_y + i + 1)][C5(pixel_mv_x + j + 2)],
						            ref_pic[ref].Y[C4(pixel_mv_y + i + 1)][C5(pixel_mv_x + j    )] + ref_pic[ref].Y[C4(pixel_mv_y + i + 1)][C5(pixel_mv_x + j + 1)]);
					s = Clip3(0, 255, (s + 16) >> 5);
					
					
					p[y + i][x + j] += (h + s + 1) >> 1;
					
				}
				else if( dx == 3 && dy == 3 ) 
				{
					m = FIR_filter( ref_pic[ref].Y[C4(pixel_mv_y + i - 2)][C5(pixel_mv_x + j + 1)] + ref_pic[ref].Y[C4(pixel_mv_y + i + 3)][C5(pixel_mv_x + j + 1)],
						            ref_pic[ref].Y[C4(pixel_mv_y + i - 1)][C5(pixel_mv_x + j + 1)] + ref_pic[ref].Y[C4(pixel_mv_y + i + 2)][C5(pixel_mv_x + j + 1)],
						            ref_pic[ref].Y[C4(pixel_mv_y + i    )][C5(pixel_mv_x + j + 1)] + ref_pic[ref].Y[C4(pixel_mv_y + i + 1)][C5(pixel_mv_x + j + 1)]);
					m = Clip3(0, 255, (m + 16) >> 5);

					s = FIR_filter( ref_pic[ref].Y[C4(pixel_mv_y + i + 1)][C5(pixel_mv_x + j - 2)] + ref_pic[ref].Y[C4(pixel_mv_y + i + 1)][C5(pixel_mv_x + j + 3)],
						            ref_pic[ref].Y[C4(pixel_mv_y + i + 1)][C5(pixel_mv_x + j - 1)] + ref_pic[ref].Y[C4(pixel_mv_y + i + 1)][C5(pixel_mv_x + j + 2)],
						            ref_pic[ref].Y[C4(pixel_mv_y + i + 1)][C5(pixel_mv_x + j    )] + ref_pic[ref].Y[C4(pixel_mv_y + i + 1)][C5(pixel_mv_x + j + 1)]);
					s = Clip3(0, 255, (s + 16) >> 5);
	
					p[y + i][x + j] += (m + s + 1) >> 1;
				}
				else 
				{
					assert(0);
				}
			}		
		}
	}

	for ( i = 0; i < MbPartHeight; i++ )
	{
		for ( j = 0; j < MbPartWidth; j++ )
		{
			p[y + i][x + j] = Clip3(0,255,p[y + i][x + j]);
		}	
	}
}

void get_block_subpixel_c(short** p_u,
						  short** p_v,
						  short mv_x, 
						  short mv_y, 
						  unsigned short MbPartWidth, 
						  unsigned short MbPartHeight,
						  unsigned short x, 
						  unsigned short y,
						  short ref)
{
    unsigned short height = HEIGHT * 8 - 1;
	unsigned short width = WIDTH * 8 - 1;

	unsigned short i, j;

	short pixel_mv_x = mv_x >> 3;
	short pixel_mv_y = mv_y >> 3;
    short dy = (mv_y & 0x7);
	short dx = (mv_x & 0x7);

	int A, B, C, D;

	if ( dx == 0 && dy == 0 )
	{
        for ( i = 0; i < MbPartHeight; i++ )
		{
			for ( j = 0; j < MbPartWidth; j++ )
			{
               p_u[y + i][x + j] += ref_pic[ref].U[C4(pixel_mv_y + i)][C5(pixel_mv_x + j)];
			   p_v[y + i][x + j] += ref_pic[ref].V[C4(pixel_mv_y + i)][C5(pixel_mv_x + j)];
			}

		}
	}
	else
	{
        A = (8 - dx) * (8 - dy);
		B = dx * (8 - dy);
		C = (8 - dx) * dy;
		D = dx * dy;

		for ( i = 0; i < MbPartHeight; i++ )
		{
			for ( j = 0; j < MbPartWidth; j++ )
			{
				p_u[y + i][x + j] += (
					A *	ref_pic[ref].U[C4(pixel_mv_y + i    )][C5(pixel_mv_x + j    )] + 
					B *	ref_pic[ref].U[C4(pixel_mv_y + i    )][C5(pixel_mv_x + j + 1)] +
					C *	ref_pic[ref].U[C4(pixel_mv_y + i + 1)][C5(pixel_mv_x + j    )] +
					D *	ref_pic[ref].U[C4(pixel_mv_y + i + 1)][C5(pixel_mv_x + j + 1)] + 32	) >> 6;

				p_v[y + i][x + j] += (
					A *	ref_pic[ref].V[C4(pixel_mv_y + i    )][C5(pixel_mv_x + j    )] + 
					B *	ref_pic[ref].V[C4(pixel_mv_y + i    )][C5(pixel_mv_x + j + 1)] +
					C *	ref_pic[ref].V[C4(pixel_mv_y + i + 1)][C5(pixel_mv_x + j    )] +
					D *	ref_pic[ref].V[C4(pixel_mv_y + i + 1)][C5(pixel_mv_x + j + 1)] + 32 ) >> 6;
			}
		}
	}
	for ( i = 0; i < MbPartHeight; i++ )
	{
		for ( j = 0; j < MbPartWidth; j++ )
		{
			p_u[y + i][x + j] = Clip3(0, 255, p_u[y + i][x + j]);
			p_v[y + i][x + j] = Clip3(0, 255, p_v[y + i][x + j]); 
		}
	}
	
}

void Dec_P_skip_MB(unsigned short mb_index)
{
	unsigned short x0 = mb_index % WIDTH;
	unsigned short y0 = mb_index / WIDTH;

	unsigned short x = x0 * 4;
	unsigned short y = y0 * 4;

	short mv_x, mv_y;

	unsigned short i, j;
	short ref = 0;
	short mvp[2];
    for ( i = 0; i < 2; i++ )
	{
		for ( j = 0; j < 2; j++ )
		{
			RefIdx[y / 2 + j][x / 2 + i] = ref;
		}
	}

	if ( x == 0 || y == 0 )
	{
		mvp[0] = mvp[1] = 0;
	}
	else if ( slice_mb_index == 0 || slice_mb_index < WIDTH){
		mvp[0] = mvp[1] = 0;
	}
	else if ( RefIdx[y / 2][x / 2 - 1] == 0 && MV[0][y][x - 1] == 0 && MV[1][y][x - 1] == 0 )
	{
        mvp[0] = mvp[1] = 0;
	}
	else if ( RefIdx[y / 2 - 1][x / 2] == 0 && MV[0][y - 1][x] == 0 && MV[1][y - 1][x] == 0 )
	{
		mvp[0] = mvp[1] = 0;
	}
	else
	{
		get_mvp(x, y, 4, 4, mb_index, 0, mvp);
	}

    for ( i = 0; i < 4; i++ )
	{
		for ( j = 0; j < 4; j++ )
		{
			MV[0][y + j][x + i] = mvp[0];
			MV[1][y + j][x + i] = mvp[1];
		}
	}

	mv_x = x0 * 64 + mvp[0];
	mv_y = y0 * 64 + mvp[1];
	if (c_mv_out){
		fprintf(c_mv_out,"pic_num:%5d mb_index_out:%5d\n",pic_num,mb_index);
		for (j=0;j<4;j++)
				fprintf(c_mv_out,"mvx_l0_curr_mb_out:%5d%5d%5d%5d\n",(unsigned short)MV[0][y+j][x],(unsigned short)MV[0][y+j][x+1],(unsigned short)MV[0][y+j][x+2],(unsigned short)MV[0][y+j][x+3]);
		for (j=0;j<4;j++)
				fprintf(c_mv_out,"mvy_l0_curr_mb_out:%5d%5d%5d%5d\n",(unsigned short)MV[1][y+j][x],(unsigned short)MV[1][y+j][x+1],(unsigned short)MV[1][y+j][x+2],(unsigned short)MV[1][y+j][x+3]);
		fprintf(c_mv_out,"\n");
	}
	int block_idx = 0;
	int k;
	for ( k = 0; k < 16; k++ )
	{
		switch (k)
		{
			case 0 : j = 0; i = 0; break;
			case 1 : j = 0; i = 1; break;
			case 2 : j = 1; i = 0; break;
			case 3 : j = 1; i = 1; break;
			case 4 : j = 0; i = 2; break;
			case 5 : j = 0; i = 3; break;
			case 6 : j = 1; i = 2; break;
			case 7 : j = 1; i = 3; break;
			case 8 : j = 2; i = 0; break;
			case 9 : j = 2; i = 1; break;
			case 10: j = 3; i = 0; break;
			case 11: j = 3; i = 1; break;
			case 12: j = 2; i = 2; break;
			case 13: j = 2; i = 3; break;
			case 14: j = 3; i = 2; break;
			case 15: j = 3; i = 3; break;
		}
		x = x0 * 16 + i * 4;
		y = y0 * 16 + j * 4;
		mv_x = (x << 2) + MV[0][(y + j) / 4][(x + i) / 4];
		mv_y = (y << 2) + MV[1][(y + j) / 4][(x + i) / 4];
		ref = RefIdx[y / 8 ][x / 8];
		get_block_subpixel(current_pic.Y, mv_x, mv_y, 4, 4, x, y, ref);
	}
	for ( j = 0; j < 2; j++ )
	{
		for (i = 0; i < 2; i++)
		{
			x = x0 * 16 + i * 8;
			y = y0 * 16 + j * 8;
			mv_x = (x << 2) + MV[0][(y + j) / 4][(x + i) / 4];
			mv_y = (y << 2) + MV[1][(y + j) / 4][(x + i) / 4];
			ref = RefIdx[y / 8 ][x / 8];
			get_block_subpixel_c(current_pic.U, current_pic.V, mv_x, mv_y, 4, 4, x / 2, y / 2, ref);
		}
	}
	ref_all_same++;
	
	int xx,yy;
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
					fprintf(c_sum_out_hex, "%02x   ", current_pic.Y[y0 * 16 + i + yy][x0 * 16 + j+xx]);
					fprintf(c_sum_out, "%5d", current_pic.Y[y0 * 16 + i + yy][x0 * 16 + j+xx]);
				}
				fprintf(c_sum_out_hex, "\n");	
				fprintf(c_sum_out, "\n");
			}
			fprintf(c_sum_out_hex, "\n");	
			fprintf(c_sum_out, "\n");
		}
	}
	if (c_sum_out && c_sum_out_hex){
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
					fprintf(c_sum_out_hex, "%02x   ", current_pic.U[y0 * 8 + i + yy][x0 * 8 + j+xx]);
					fprintf(c_sum_out, "%5d", current_pic.U[y0*8 + i + yy][x0*8 + j+xx]);
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
					fprintf(c_sum_out_hex, "%02x   ", current_pic.V[y0 * 8 + i + yy][x0 * 8 + j+xx]);
					fprintf(c_sum_out, "%5d", current_pic.V[y0*8 + i + yy][x0*8 + j+xx]);
				}
				fprintf(c_sum_out_hex, "\n");	
				fprintf(c_sum_out, "\n");
			}
			fprintf(c_sum_out_hex, "\n");	
			fprintf(c_sum_out, "\n");
		}
	}
}


