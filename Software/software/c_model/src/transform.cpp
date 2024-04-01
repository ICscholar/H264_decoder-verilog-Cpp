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
#include "transform.h"
#include <assert.h>
#include "bitstream_header.h"

void inverse_zigzag(short p[])
{
	/*  
	0   1   4   8       0   1   2   3
	5   2   3   6       4   5   6   7
	9   12  13  10   -> 8   9   10  11 
	7   11  14  15      12  13  14  15
	*/
	short tp;
	tp = p[2];
	p[2] = p[5];
	p[5] = p[4];
	p[4] = tp;

	tp = p[3];
	p[3] = p[6];
	p[6] = p[7];
	p[7] = p[12];
	p[12] = p[9];
	p[9] = p[8];
	p[8] = tp;

	tp = p[13];
	p[13] = p[10];
	p[10] = p[11];
	p[11] = tp;
}

//block_type =	1:  Intra16x16LumaDC
//				2:	Intra16x16LumaAC
//				3:  Luma4x4
//				4:  ChromaDC(inter)
//				5:  ChromaDC(intra)
//				6:  ChromaAC
//				
/*
void inverse_quant(unsigned short QP, unsigned short block_type, short p[])
{
	if (block_type <= 3)
	{
		assert(QP >= 0 && QP <= 51);
	}
	else 
	{
  		assert(QP >= 0 && QP <= 39);
	}

	static unsigned short dequant_coef[6][16] = 
	{
		{10, 13, 10, 13,
		 13, 16, 13, 16,
		 10, 13, 10, 13,
		 13, 16, 13, 16},

		{11, 14, 11, 14,
		 14, 18, 14, 18,
		 11, 14, 11, 14,
		 14, 18, 14, 18},

		{13, 16, 13, 16,
		 16, 20, 16, 20,
		 13, 16, 13, 16, 
		 16, 20, 16, 20},

		{14, 18, 14, 18,
		 18, 23, 18, 23,
		 14, 18, 14, 18,
		 18, 23, 18, 23},

		{16, 20, 16, 20, 
		 20, 25, 20, 25,
		 16, 20, 16, 20,
		 20, 25, 20, 25},

		{18, 23, 18, 23,
		 23, 29, 23, 29,
		 18, 23, 18, 23, 
		 23, 29, 23, 29}
	};

	unsigned short qp = QP % 6;
	unsigned short qbits = QP / 6;
	assert(qbits <= 8);
	unsigned short i;
	switch (block_type)
	{
	case 1://Intra16x16LumaDC
		if (qbits > 2)
		{
			for (i = 0; i < 16; i++)
			{
				p[i] = (p[i]*dequant_coef[qp][0]) << (qbits-2);
			}
		}
		else
		{
			for (i = 0; i < 16; i++)
			{
				//p[i] = ( p[i]*dequant_coef[qp][0] >> (2-qbits)); 
				p[i] = ( p[i]*dequant_coef[qp][0]+(1<<(1-qbits)) ) >> (2-qbits);
			}
		}
		break;
	case 2://Intra16x16LumaAC
	case 6://ChromaAC
		for (i = 1; i < 16; i++)
		{
			p[i] = (p[i]*dequant_coef[qp][i]) << qbits;
		}
		break;

	case 3://Luma4x4
		for (i = 0; i < 16; i++)
		{
			p[i] = (p[i]*dequant_coef[qp][i]) << qbits;
		}
		break;
	case 5://ChromaDC
		if (qbits >= 1)
		{
			for (i = 0; i < 4; i++)
			{
				p[i] = (p[i]*dequant_coef[qp][0]) << (qbits - 1);
			}
		}
		else
		{
			for (i = 0; i < 4; i++)
			{
				p[i] = (p[i]*dequant_coef[qp][0]) >> 1;
			}
		}
		break;
	default:
		assert(0);
	}
}
*/
void inverse_quant(unsigned short QP, unsigned short block_type, short p[],int p_int[])
{
	static int first_time_n = 0;
	int q;


	if (block_type <= 3)
	{
		assert(QP >= 0 && QP <= 51);
	}
	else 
	{
  		assert(QP >= 0 && QP <= 39);
	}

	static unsigned short dequant_coef[6/*QP*/][3] = 
	{
		{10, 13, 16},

		{11, 14, 18},

		{13, 16,20},

		{14, 18, 23},

		{16, 20, 25},

		{18, 23, 29}
	};

	unsigned short i;
	static unsigned int dequant4_coeff[52][16];
	if (first_time_n==0){
		first_time_n = 1;
		for(q=0; q<52; q++){
            int shift = q/6;
            int idx = q%6;
			printf("---------------%d-----------------\n",q);
            for(i=0; i<3; i++){
                dequant4_coeff[q][i] = (unsigned int)(dequant_coef[idx][i] << shift);
				printf("%05x ",  dequant4_coeff[q][i]);
				if ((i+1)%3 == 0)
					printf("\n");
			}
		}
	}

	for (i = 0; i < 16; i++){
		p_int[i] = *(p+i);
	}
	switch (block_type)
	{
	case 1://Intra16x16LumaDC
		for (i = 0; i < 16; i++)
		{
			p_int[i] = p[i]*dequant4_coeff[QP][0];
		}
		break;
	case 2://Intra16x16LumaAC
	case 6://ChromaAC
		for (i = 1; i < 16; i++)
		{
			p_int[i] = p[i]*dequant4_coeff[QP][(i&1) + ((i>>2)&1)];
		}
		break;

	case 3://Luma4x4
		for (i = 0; i < 16; i++)
		{
			p_int[i] = p[i]*dequant4_coeff[QP][(i&1) + ((i>>2)&1)];
		}
		break;
	case 5://ChromaDC
		for (i = 0; i < 4; i++)
		{
			p_int[i] = p[i]*dequant4_coeff[QP][0];
		}
		break;
	default:
		assert(0);
	}
}

void DHT(short p[])
{
	//  1  1  1  1         1  1  1  1
	//  1  1 -1 -1         1  1 -1 -1
	//  1 -1 -1  1 * [W] * 1 -1 -1  1
	//  1 -1  1 -1         1 -1  1 -1
	short temp[4] = { 0 };
	int i;

	for (i = 0; i < 4; i++)
	{
		temp[0] = p[i*4+0] + p[i*4+2];
		temp[1] = p[i*4+0] - p[i*4+2];
		temp[2] = p[i*4+1] - p[i*4+3];
		temp[3] = p[i*4+3] + p[i*4+1];

		p[4*i+0] = (temp[0] + temp[3]);
		p[4*i+1] = (temp[1] + temp[2]);
		p[4*i+2] = (temp[1] - temp[2]);	
		p[4*i+3] = (temp[0] - temp[3]);		
	}

	for (i = 0; i < 4; i++)
	{
		temp[0] = p[i] + p[8+i];
		temp[1] = p[i] - p[8+i];
		temp[2] = p[4+i] - p[12+i];
		temp[3] = p[12+i] + p[4+i];

		p[i+4*0] = temp[0] + temp[3];
		p[i+4*1] = temp[1] + temp[2];
		p[i+4*2] = temp[1] - temp[2];	
		p[i+4*3] = temp[0] - temp[3];
	}
}


void DHT2(short p[])
{
	static short temp[4]={ 0 };
	// 1  1       1 1
	//      Zrd 
	// 1 -1       1 -1
	
	temp[0] = p[0] + p[2];
	temp[1] = p[0] - p[2];
	temp[2] = p[1] - p[3];
	temp[3] = p[1] + p[3];
	p[0]  = (temp[0] + temp[3]);
	p[2]  = (temp[1] + temp[2]);
	p[3]  = (temp[1] - temp[2]);
	p[1]  = (temp[0] - temp[3]);
}

// 1   1   1  1/2      x00  x01  x02  x03      X00  X01  X02  X03
// 1   1/2 -1  -1      x10  x11  x12  x13      X10  X11  X12  X13
// 1  -1/2 -1  1   *   x20  x21  x22  x23  =   X20  X21  X22  X23
// 1  -1   1 -1/2      x30  x31  x32  x33      X30  X31  X32  X33

// X00 = x00 + x10 + x20 + x30/2
// X10 = x00 + x10/2 -x20 -x30
// X20 = x00 - x10/2 - x20 + x30
// X30 = x00 -x10   + x20  -x30/2
// temp0 = x00 + x20
// temp1 = x10 + x30/2
// temp2 = x00 - x20
// temp3 = x10/2 - x30
// X00 = temp0 + temp1
// X10 = temp2 + temp3
// X20 = temp2 - temp3
// X30 = temp0 - temp1

void IDCT(short p[],int type)
{
	short temp[4] = { 0 };
	// 1    1     1   1/2            1    1    1    1
	// 1   1/2   -1   -1             1   1/2  -1/2  -1
	// 1  -1/2   -1   1     * [W] *  1   -1   -1  -1
	// 1   -1     1  -1/2            1/2  -1  1    -1/2

	int i;
	for (i = 0; i < 4; i++) 
	{ 
		temp[0] =  p[0 + i*4]      +  p[2 + i*4];
		temp[1] =  p[0 + i*4]      -  p[2 + i*4];
		temp[2] = (p[1 + i*4]>>1)  -  p[3 + i*4];
		temp[3] =  p[1 + i*4]      + (p[3 + i*4]>>1);

		p[0 + i*4] = (temp[0]  +  temp[3]);
		p[1 + i*4] = (temp[1]  +  temp[2]);
		p[2 + i*4] = (temp[1]  -  temp[2]);	
		p[3 + i*4] = (temp[0]  -  temp[3]);		
	}

	for (i = 0; i < 4; i++)
	{
		temp[0] = p[i]        +  p[i+8];
		temp[1] = p[i]        -  p[i+8];
		temp[2] = (p[i+4]>>1) -  p[i+12];
		temp[3] =  p[i+4]     +  (p[i+12]>>1) ;

		p[i +  0]  = (temp[0] + temp[3] + 32) >> 6;
		p[i +  4]  = (temp[1] + temp[2] + 32) >> 6;
		p[i +  8]  = (temp[1] - temp[2] + 32) >> 6;	
		p[i + 12]  = (temp[0] - temp[3] + 32) >> 6;
	}
}

