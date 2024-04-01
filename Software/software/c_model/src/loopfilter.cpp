#include "bitstream_header.h"
#include "loopfilter.h"
#include "macroblock.h"
#include <math.h>
#include <assert.h>
#include <memory.h>
#include <stdlib.h>

extern unsigned short WIDTH, HEIGHT;
extern unsigned short **intra_pred_mode;
extern unsigned short **intra_mode;
extern unsigned short **qp_z;
extern unsigned short **qp_z_c;
extern unsigned short **nnz;
extern unsigned short ***nnz_chroma;
extern short **RefIdx;
extern short ***MV;
extern char slice_table[40000];

extern Picture_t current_pic;
extern Picture_t ref_pic[5];

extern unsigned short slice_num;
extern unsigned short pic_num;

//这个函数求bs
void strength(unsigned short verticalFlag, unsigned short x, unsigned short y, unsigned short bs[4][4])
{
	//输入x, y以像素为单位
    unsigned short x0 = x / 16;
	unsigned short y0 = y / 16;
	unsigned short xx = x / 4;
	unsigned short yy = y / 4;

    //过滤垂直线时的p,q分布
	//            |
	//            |<--分界线
	// ------------------------
	//|p3|p2|p1|p0|q0|q1|q2|q3|   
	// ------------------------

    unsigned short intra_p, intra_q;
	unsigned short i, j;
	short a, b;
	bool flag, flag1;
	unsigned short d;
	intra_q = intra_mode[y0][x0];
	if ( verticalFlag )
	{
		if ( intra_q )
		{
            for ( i = 0; i < 4; i++ )
			{
				bs[i][0] = 4;
				bs[i][1] = bs[i][2] = bs[i][3] = 3;
			}
			return;	//case0 end
		}
		
		if ( x0 == 0 )
		{
			intra_p = 1;
		}
		else
		{
            intra_p = intra_mode[y0][x0 - 1];
		}
		d = 0;

		if ( intra_p )
		{
			bs[0][0] = bs[1][0] = bs[2][0] = bs[3][0] = 4;
			d = 1;
		}
		for ( i  = 0; i < 4; i++ )
		{
			for ( j = d; j < 4; j++ )
			{
                if ( nnz[yy + i][xx + j - 1] || nnz[yy + i][xx + j] )
				{
					bs[i][j] = 2;
					continue;
				}
				flag = RefIdx[(yy + i) / 2][(xx + j) / 2] != RefIdx[(yy + i) / 2][(xx + j - 1) / 2];
				a = MV[0][yy + i][xx + j] - MV[0][yy + i][xx + j - 1];
				b = MV[1][yy + i][xx + j] - MV[1][yy + i][xx + j - 1]; // fix MV[0][yy + i][xx + j - 1] -> MV[1][yy + i][xx + j - 1]
				flag1 = (abs(a) >= 4 || abs(b) >= 4);
				if ( flag || flag1 )
				{
					bs[i][j] = 1;
					continue;
				}
                bs[i][j] = 0;
			}
		}

	}
	else
	{
		if ( y0 == 0 )
		{
		    intra_p = 1;
		}
		else
		{
            intra_p = intra_mode[y0 - 1][x0];
		}
        
		d = 0;
		if ( intra_q )
		{
			for ( i = 0; i < 4; i++ )
			{
				bs[0][i] = 4;
				bs[1][i] = bs[2][i] = bs[3][i] = 3;
			}
			return;
		}
		if ( intra_p )
		{
			bs[0][0] = bs[0][1] = bs[0][2] = bs[0][3] = 4;
			d = 1;
		}
		for ( i = d; i < 4; i++ )
		{
			for ( j = 0; j < 4; j++ )
			{
				if ( nnz[yy + i - 1][xx + j] || nnz[yy + i][xx + j] )
				{
					bs[i][j] = 2;
					continue;
				}
				flag = RefIdx[(yy + i) / 2][(xx + j) / 2] != RefIdx[(yy + i - 1) / 2][(xx + j) / 2];//bug fix, binqiu xx + i -> xx + j
				a = MV[0][yy + i][xx + j] - MV[0][yy + i - 1][xx + j];
				b = MV[1][yy + i][xx + j] - MV[1][yy + i - 1][xx + j];
				flag1 = (abs(a) >= 4  || abs(b) >= 4);
				if ( flag || flag1 )
				{
					bs[i][j] = 1;
					continue;
				}
				bs[i][j] = 0;
			}
		}
	}

}

void FilterProcess_bs4_ver( short **p, 
						    unsigned short x,
							unsigned short y, 
							unsigned short chromaFlag,
							unsigned short alpha,
							unsigned short beta)
{
	unsigned short i;
	unsigned short nE = chromaFlag ? 2 : 4;
	short q0, q1, q2, q3, p0, p1, p2, p3;
	short _p1, _q1, a_p, a_q;
	bool flag1, flag2;

	for ( i = 0; i < nE; i++ )
	{
        q0 = p[y + i][x];
		q1 = p[y + i][x + 1];
		p0 = p[y + i][x - 1];
		p1 = p[y + i][x - 2];
		//filterSamplesFlag = ( bS != 0  &&  Abs( p0 – q0 ) < ?  &&  Abs( p1 – p0 ) < ?  &&  Abs( q1 – q0 ) < ? ) 四个条件都满足的情况下才滤波
		if ( abs(p0 - q0) >= alpha || abs(p1 - p0) >= beta || abs(q1 - q0) >= beta )
		{
			continue;
		}
		q2 = p[y + i][x + 2];
		q3 = p[y + i][x + 3];
		p2 = p[y + i][x - 3];
		p3 = p[y + i][x - 4];

		a_p = abs(p2 - p0);
		a_q = abs(q2 - q0);
		flag1 = !chromaFlag && a_p < beta && abs(p0 - q0) < ((alpha >> 2) + 2);
		flag2 = !chromaFlag && a_q < beta && abs(p0 - q0) < ((alpha >> 2) + 2);

		if ( flag1 )
		{
            _p1 = p2 + p1 + p0 + q0;
			p[y + i][x - 1] = ((_p1 << 1) + q1 - p2 + 4) >> 3;
			p[y + i][x - 3] = ( ((p3 + p2) << 1) + _p1 + 4) >> 3;
            p[y + i][x - 2] = (_p1 + 2) >> 2;
		}
		else
		{
            p[y + i][x - 1] = ((p1 << 1) + p0 + q1 + 2) >> 2;
		}

		if ( flag2 )
		{
            _q1 = q2 + q1 + q0 + p0;
			p[y + i][x] = ((_q1 << 1) + p1 - q2 + 4) >> 3;
			p[y + i][x + 2] = ( ((q3 + q2) << 1) + _q1 + 4) >> 3;
			p[y + i][x + 1] = (_q1 + 2) >> 2;
		}
		else
		{
            p[y + i][x] = ((q1 << 1) + q0 + p1 + 2) >> 2;
		}
	}
}

void FilterProcess_bs_lessthan4_ver( short **p, 
									 unsigned short x,
									 unsigned short y,
									 unsigned short chromaFlag,
									 unsigned short bs,
									 unsigned short alpha,
									 unsigned short beta,
									 unsigned short tc_0
									 )
{
	unsigned short i;
	unsigned short nE = chromaFlag ? 2 : 4;
	short p0, p1, p2, q0, q1, q2;
	short ap, aq, tc;
	short delta;

	// ------------------------
	//|p3|p2|p1|p0|q0|q1|q2|q3|   i = 0 y0
	// ------------------------
	// ...        |x              i = 1 y1
	// ...   4x4  |  4x4          i = 2 y2
	// ...        |               i = 3 y3

	// p[y][x]
	for ( i = 0; i < nE; i++ )
	{
        p0 = p[y + i][x - 1];
		p1 = p[y + i][x - 2];
		q0 = p[y + i][x];
		q1 = p[y + i][x + 1];

		if ( abs(p0 - q0) >= alpha || abs(p1 - p0) >= beta || abs(q1 - q0) >= beta )
		{
			continue;
		}
		p2 = p[y + i][x - 3];
		q2 = p[y + i][x + 2];

		ap = abs(p2 - p0) < beta;
		aq = abs(q2 - q0) < beta;
        //当上述条件成立时，说明边界变化强度不是很大，滤波强度的设定值相对于实际值偏大
        //才对p1 q1进行修正
        //基本思路是求出delta0,delta1, p0 = p0 + delta0, q0 = q0 - delta0
        // p1 = p1 + delta1, q1 = q1 + delta1
		tc = tc_0 + (chromaFlag ? 1 : (ap+aq));
        delta = Clip3(-tc, tc, ( (q0 - p0) * 4 + p1 - q1 + 4) >> 3 );
        p[y + i][x - 1] = Clip3(0, 255, p0 + delta);
		p[y + i][x] = Clip3(0, 255, q0 - delta);
		//bs小于四时最多改变x x+1 x-1 x-2处的值,就波及范围仅2
		//ap成立时才对p1进行修正
		if ( !chromaFlag && ap )
		{
            p[y + i][x - 2] = p1 + Clip3(-tc_0, tc_0, (p2 + ((p0 + q0 + 1) >> 1) - p1 * 2) >> 1 );
		}
		//aq 成立时才对q1进行修正
		if ( !chromaFlag && aq )
		{
            p[y + i][x + 1] = q1 + Clip3(-tc_0, tc_0, (q2 + ((p0 + q0 + 1) >> 1) - q1 * 2) >> 1 );
		}
		
	}
}




void FilterProcess_bs_lessthan4_hor( short **p, 
									 unsigned short x,
									 unsigned short y,
									 unsigned short chromaFlag,
									 unsigned short bs,
									 unsigned short alpha,
									 unsigned short beta,
									 unsigned short tc_0 )
{
	unsigned short i;
	unsigned short nE = chromaFlag ? 2 : 4;
	short p0, p1, p2, q0, q1, q2;
    short ap, aq, delta, tc;

	for ( i = 0; i < nE; i++ )
	{
        p0 = p[y - 1][x + i];
		p1 = p[y - 2][x + i];
		q0 = p[y][x + i];
		q1 = p[y + 1][x + i];
	//	if (chromaFlag==1)
		fprintf(fp_deblock_dbg, "in:%02x %02x %02x %02x %02x %02x %02x %02x,out:",p[y - 4][x + i], p[y - 3][x + i], p[y - 2][x + i],p[y - 1][x + i],
								 p[y + 0][x + i], p[y + 1][x + i], p[y + 2][x + i],p[y + 3][x + i]);

		if ( abs(p0 - q0) >= alpha || abs(p1 - p0) >= beta || abs(q1 - q0) >= beta )
		{
			//if (chromaFlag==1)
			fprintf(fp_deblock_dbg, "%02x %02x %02x %02x %02x %02x %02x %02x\n",p[y - 4][x + i], p[y - 3][x + i], p[y - 2][x + i],p[y - 1][x + i],
								 p[y + 0][x + i], p[y + 1][x + i], p[y + 2][x + i],p[y + 3][x + i]);

			continue;
								}
		if (!chromaFlag){
			p2 = p[y - 3][x + i];
			q2 = p[y + 2][x + i];
		}
		ap = abs(p2 - p0) < beta;
		aq = abs(q2 - q0) < beta;
		
		tc = tc_0 + ( chromaFlag ? 1 : (ap+aq) );
		delta = Clip3(-tc, tc, ( ((q0 - p0) << 2) + p1 - q1 + 4) >> 3);
		p[y - 1][x + i] = Clip3(0, 255, p0 + delta);
		p[y][x + i] = Clip3(0, 255, q0 - delta);
		if ( !chromaFlag && ap )
		{
            p[y - 2][x + i] = p1 + Clip3(-tc_0, tc_0, (p2 + ((p0 + q0 + 1) >> 1) - 2 * p1) >> 1);
		}

		if ( !chromaFlag && aq )
		{
            p[y  +1][x + i] = q1 + Clip3(-tc_0, tc_0, (q2 + ((p0 + q0 + 1) >> 1) - 2 * q1) >> 1);
		}
			//		if (chromaFlag==1)
		fprintf(fp_deblock_dbg, "%02x %02x %02x %02x %02x %02x %02x %02x\n",p[y - 4][x + i], p[y - 3][x + i], p[y - 2][x + i],p[y - 1][x + i],
								 p[y + 0][x + i], p[y + 1][x + i], p[y + 2][x + i],p[y + 3][x + i]);
	}
}

void FilterProcess_bs4_hor( short **p, 
						    unsigned short x,
							unsigned short y,
							unsigned short chromaFlag,
							unsigned short alpha,
							unsigned short beta )
{
	unsigned short i = 0;
	unsigned short nE = chromaFlag ? 2 : 4;
	short q0, q1, q2, q3, p0, p1, p2, p3;
	short _p1, _q1, a_p, a_q;
	bool flag1, flag2;

	for ( i = 0; i < nE; i++ )
	{
        q0 = p[y][x + i];
		q1 = p[y + 1][x + i];
		p0 = p[y - 1][x + i];
		p1 = p[y - 2][x + i];
	//	if (chromaFlag==1)
fprintf(fp_deblock_dbg, "in:%02x %02x %02x %02x %02x %02x %02x %02x,out:",p[y - 4][x + i], p[y - 3][x + i], p[y - 2][x + i],p[y - 1][x + i],
								 p[y + 0][x + i], p[y + 1][x + i], p[y + 2][x + i],p[y + 3][x + i]);
		if ( abs(p0 - q0) >= alpha || abs(p1 - p0) >= beta || abs(q1 - q0) >= beta )
		{
		//	if (chromaFlag==1)
			fprintf(fp_deblock_dbg, "%02x %02x %02x %02x %02x %02x %02x %02x\n",p[y - 4][x + i], p[y - 3][x + i], p[y - 2][x + i],p[y - 1][x + i],
								 p[y + 0][x + i], p[y + 1][x + i], p[y + 2][x + i],p[y + 3][x + i]);

			continue;
		}
		q2 = p[y + 2][x + i];
		q3 = p[y + 3][x + i];
		p2 = p[y - 3][x + i];
		p3 = p[y - 4][x + i];

		a_p = abs(p2 - p0);
		a_q = abs(q2 - q0);

		flag1 = !chromaFlag && a_p < beta && abs(p0 - q0) < ((alpha >> 2) + 2);
		flag2 = !chromaFlag && a_q < beta && abs(p0 - q0) < ((alpha >> 2) + 2);

		if ( flag1 )
		{
		    //修正p0 p1 p2
            _p1 = p2 + p1 + p0 + q0;
			p[y - 1][x + i] = ((_p1 << 1) + q1 - p2 + 4) >> 3;
			p[y - 3][x + i] = ( ((p3 + p2) << 1) + _p1 + 4) >> 3;
			p[y - 2][x + i] = (_p1 + 2) >> 2;
		}
		else
		{
		    //只修正p0
			p[y - 1][x + i] = ((p1 << 1) + p0 + q1 + 2) >> 2;
		}

		if ( flag2 )
		{
            _q1 = q2 + q1 + q0 + p0;
			p[y][x + i] = ((_q1 << 1) + p1 - q2 + 4) >> 3;
			p[y + 2][x + i] = ( ((q3 + q2) << 1) + _q1 + 4) >> 3;
			p[y + 1][x + i] = (_q1 + 2) >> 2;
		}
		else
		{
            p[y][x + i] = ((q1 << 1) + q0 + p1 + 2) >> 2;
		}
				//	if (chromaFlag==1)
		fprintf(fp_deblock_dbg, "%02x %02x %02x %02x %02x %02x %02x %02x\n",p[y - 4][x + i], p[y - 3][x + i], p[y - 2][x + i],p[y - 1][x + i],
								 p[y + 0][x + i], p[y + 1][x + i], p[y + 2][x + i],p[y + 3][x + i]);
	}
}

void FilterEdge( unsigned short x,
				 unsigned short y,
				 unsigned short chromaFlag,
				 unsigned short verticalFlag,
				 short **p,
				 unsigned short edgeFlag,
				 unsigned short bs,
				 unsigned short index_A, 
				 unsigned short alpha,
				 unsigned short beta )
{
	//tc0:滤波限幅变量
	static const unsigned short tc0[3][52] = {
		{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,
			1,1,1,1,1,1,1,2,2,2,2,3,3,3,4,4,4,5,6,6,7,8,9,10,11,13},
		{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,
		1,1,1,1,1,2,2,2,2,3,3,3,4,4,5,5,6,7,8,8,10,11,12,13,15,17},
		{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,
		1,2,2,2,2,3,3,3,4,4,4,5,6,6,7,8,9,10,11,13,14,16,18,20,23,25}
	};
    
	unsigned short tc_0 = tc0[bs - 1][index_A]; // bs=4时tc_0无效
	if ( verticalFlag )
	{
		if ( bs < 4 )
		{
			FilterProcess_bs_lessthan4_ver( p, x, y, chromaFlag, bs, alpha, beta, tc_0 );
		}
		else
		{
			FilterProcess_bs4_ver(p, x, y, chromaFlag, alpha, beta);
		}
	}
	else
	{
		if ( bs < 4 )
		{
			FilterProcess_bs_lessthan4_hor(p, x, y, chromaFlag, bs, alpha, beta, tc_0);
		}
		else
		{
            FilterProcess_bs4_hor(p, x, y, chromaFlag, alpha, beta);
		}
	}

}

void deblocking_mb( unsigned short mb_index, int v_start, int h_start, unsigned short qp_avv[6], Index_t index, short **p_y, short **p_u, short **p_v)
{
	unsigned short i;
	unsigned short x0 = mb_index % WIDTH;
	unsigned short y0 = mb_index / WIDTH;

	unsigned short x = x0 << 4;
	unsigned short y = y0 << 4;
	unsigned short xx = x / 2;
	unsigned short yy = y / 2;

	unsigned short bs[4][4] = { 0 };
	int index_a;
	int index_a_c;
	int alpha_a;
	int alpha_a_c;
	int beta_a;
	int beta_a_c;

	strength( 1, x, y, bs ); // fix x0, y0 -> x, y

	
	if (v_start == 1){
		bs[0][0] = 0;
		bs[1][0] = 0;
		bs[2][0] = 0;
		bs[3][0] = 0;
	}

	
//	fprintf(fp_deblock_dbg, "ver bs=%1d %1d %1d %1d\n", bs[0][0],bs[1][0],bs[2][0],bs[3][0]);
//	fprintf(fp_deblock_dbg, "ver bs=%1d %1d %1d %1d\n", bs[0][1],bs[1][1],bs[2][1],bs[3][1]);
//	fprintf(fp_deblock_dbg, "ver bs=%1d %1d %1d %1d\n", bs[0][2],bs[1][2],bs[2][2],bs[3][2]);
//	fprintf(fp_deblock_dbg, "ver bs=%1d %1d %1d %1d\n", bs[0][3],bs[1][3],bs[2][3],bs[3][3]);
// 先滤波垂直边界 bs是以4x4块为单位的



	for ( i = 0; i < 4; i++ ) // 每条边界的四个部分
	{
		if (i==0){
			index_a = index.indexA[2];
			index_a_c = index.indexA[5];
			alpha_a = index.alpha[2];
			alpha_a_c = index.alpha[5];
			beta_a = index.beta[2];
			beta_a_c = index.beta[5];
		}
		else {
			index_a = index.indexA[0];
			index_a_c = index.indexA[3];
			alpha_a = index.alpha[0];
			alpha_a_c = index.alpha[3];
			beta_a = index.beta[0];
			beta_a_c = index.beta[3];			
		}
		if (bs[0][i] )
		{
			FilterEdge(x, y, 0, 1, p_y, 1, bs[0][i], index_a, alpha_a, beta_a);
			if ((i&1)==0){
				FilterEdge(xx, yy, 1, 1, p_u, 1, bs[0][i], index_a_c, alpha_a_c, beta_a_c);
				FilterEdge(xx, yy, 1, 1, p_v, 1, bs[0][i], index_a_c, alpha_a_c, beta_a_c);
			}
		}
		if ( bs[1][i] )
		{
			FilterEdge(x, y + 4, 0, 1, p_y, 0, bs[1][i], index_a, alpha_a, beta_a);
			if ((i&1)==0){
				FilterEdge(xx, yy+2, 1, 1, p_u, 1, bs[1][i], index_a_c, alpha_a_c, beta_a_c);
				FilterEdge(xx, yy+2, 1, 1, p_v, 1, bs[1][i], index_a_c, alpha_a_c, beta_a_c);
			}
		}
		if ( bs[2][i] )
		{
			FilterEdge(x, y + 8, 0, 1, p_y, 0, bs[2][i], index_a, alpha_a, beta_a);
			if ((i&1)==0){
				FilterEdge(xx, yy + 4, 1, 1, p_u, 0, bs[2][i], index_a_c, alpha_a_c, beta_a_c);
				FilterEdge(xx, yy + 4, 1, 1, p_v, 0, bs[2][i], index_a_c, alpha_a_c, beta_a_c);
			}
		}
		if ( bs[3][i] )
		{
			FilterEdge(x, y + 12, 0, 1, p_y, 0, bs[3][i], index_a, alpha_a, beta_a);
			if ((i&1)==0){
				FilterEdge(xx, yy + 6, 1, 1, p_u, 0, bs[3][i], index_a_c, alpha_a_c, beta_a_c);
				FilterEdge(xx, yy + 6, 1, 1, p_v, 0, bs[3][i], index_a_c, alpha_a_c, beta_a_c);
			}	
		}

		x += 4;
		xx += 2;

	}

// 再滤波水平边界
    x = x0 << 4;
	y = y0 << 4;
	xx = x / 2;
	yy = y / 2;
	memset(bs, 0, 32); 
    strength(0, x, y, bs);
    
   	if (h_start == 1){
		bs[0][0] = 0;
		bs[0][1] = 0;
		bs[0][2] = 0;
		bs[0][3] = 0;
	}

//	fprintf(fp_deblock_dbg, "hor bs=%1d %1d %1d %1d\n", bs[0][0],bs[0][1],bs[0][2],bs[0][3]);
//	fprintf(fp_deblock_dbg, "hor bs=%1d %1d %1d %1d\n", bs[1][0],bs[1][1],bs[1][2],bs[1][3]);
//	fprintf(fp_deblock_dbg, "hor bs=%1d %1d %1d %1d\n", bs[2][0],bs[2][1],bs[2][2],bs[2][3]);
//	fprintf(fp_deblock_dbg, "hor bs=%1d %1d %1d %1d\n", bs[3][0],bs[3][1],bs[3][2],bs[3][3]);
	
	for ( i = 0; i < 4; i++ )
	{
		if (i==0){
			index_a = index.indexA[1];
			index_a_c = index.indexA[4];
			alpha_a = index.alpha[1];
			alpha_a_c = index.alpha[4];
			beta_a = index.beta[1];
			beta_a_c = index.beta[4];
		}
		else {
			index_a = index.indexA[0];
			index_a_c = index.indexA[3];
			alpha_a = index.alpha[0];
			alpha_a_c = index.alpha[3];
			beta_a = index.beta[0];
			beta_a_c = index.beta[3];			
		}
		if (bs[i][0] ) // x, x+4, x+8, x+16四条边界
		{
            FilterEdge(x, y, 0, 0, p_y, 1, bs[i][0],  index_a, alpha_a, beta_a);
		}
		if ( bs[i][1] )
		{
			FilterEdge(x + 4, y, 0, 0, p_y, 0, bs[i][1], index_a, alpha_a, beta_a);
		}
		if ( bs[i][2] )
		{
			FilterEdge(x + 8, y, 0, 0, p_y, 0, bs[i][2], index_a, alpha_a, beta_a);
		}
		if ( bs[i][3] )
		{
			FilterEdge(x + 12, y, 0, 0, p_y, 0, bs[i][3], index_a, alpha_a, beta_a);
		}

		y += 4;
		yy += 2;
	}
	x = x0 << 4;
	y = y0 << 4;
	xx = x / 2;
	yy = y / 2;
	for ( i = 0; i < 4; i++ )
	{
		if (i==0){
			index_a = index.indexA[1];
			index_a_c = index.indexA[4];
			alpha_a = index.alpha[1];
			alpha_a_c = index.alpha[4];
			beta_a = index.beta[1];
			beta_a_c = index.beta[4];
		}
		else {
			index_a = index.indexA[0];
			index_a_c = index.indexA[3];
			alpha_a = index.alpha[0];
			alpha_a_c = index.alpha[3];
			beta_a = index.beta[0];
			beta_a_c = index.beta[3];			
		}
		if (bs[i][0] ) // x, x+4, x+8, x+16四条边界
		{
            if ((i&1)==0){
				FilterEdge(xx, yy, 1, 0, p_u, 1, bs[i][0], index_a_c, alpha_a_c, beta_a_c);
			}
		}
		if ( bs[i][1] )
		{
			if ((i&1)==0){
				FilterEdge(xx+2, yy, 1, 0, p_u, 1, bs[i][1], index_a_c, alpha_a_c, beta_a_c);
			}
		}
		if ( bs[i][2] )
		{
			if ((i&1)==0){
				FilterEdge(xx + 4, yy, 1, 0, p_u, 0, bs[i][2], index_a_c, alpha_a_c, beta_a_c);
			}
		}
		if ( bs[i][3] )
		{
			if ((i&1)==0){
				FilterEdge(xx + 6, yy, 1, 0, p_u, 0, bs[i][3], index_a_c, alpha_a_c, beta_a_c);
			}
		}

		y += 4;
		yy += 2;
	}
	
	x = x0 << 4;
	y = y0 << 4;
	xx = x / 2;
	yy = y / 2;
	for ( i = 0; i < 4; i++ )
	{
		if (i==0){
			index_a = index.indexA[1];
			index_a_c = index.indexA[4];
			alpha_a = index.alpha[1];
			alpha_a_c = index.alpha[4];
			beta_a = index.beta[1];
			beta_a_c = index.beta[4];
		}
		else {
			index_a = index.indexA[0];
			index_a_c = index.indexA[3];
			alpha_a = index.alpha[0];
			alpha_a_c = index.alpha[3];
			beta_a = index.beta[0];
			beta_a_c = index.beta[3];			
		}
		if (bs[i][0] ) // x, x+4, x+8, x+16四条边界
		{
            if ((i&1)==0){
				FilterEdge(xx, yy, 1, 0, p_v, 1, bs[i][0], index_a_c, alpha_a_c, beta_a_c);
			}
		}
		if ( bs[i][1] )
		{
			if ((i&1)==0){
				FilterEdge(xx+2, yy, 1, 0, p_v, 1, bs[i][1], index_a_c, alpha_a_c, beta_a_c);
			}
		}
		if ( bs[i][2] )
		{
			if ((i&1)==0){
				FilterEdge(xx + 4, yy, 1, 0, p_v, 0, bs[i][2], index_a_c, alpha_a_c, beta_a_c);
			}
		}
		if ( bs[i][3] )
		{
			if ((i&1)==0){
				FilterEdge(xx + 6, yy, 1, 0, p_v, 0, bs[i][3], index_a_c, alpha_a_c, beta_a_c);
			}
		}

		y += 4;
		yy += 2;
	}

}

void deblocking_filter( const SliceHeader_t &slice_header, const PPS_t& pps )
{
	unsigned short i,j,k,t;
	static const int alpha_indexA[52] = {
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,4,4,5,6,7,8,9,10,12,13,15,17,20,22,25,28,
			32,36,40,45,50,56,63,71,80,90,101,113,127,144,162,182,203,226,255,255
	};
	static const int beta_indexB[52] = {
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,3,3,3,3,4,4,4,6,6,7,7,8,8,
			9,9,10,10,11,11,12,12,13,13,14,14,15,15,16,16,17,17,18,18
	};

	unsigned short filter_offsetA = slice_header.slice_alpha_c0_offset_div2 << 1;
	unsigned short filter_offsetB = slice_header.slice_beta_offset_div2 << 1;
    unsigned short num_mb_in_slice = WIDTH * HEIGHT;
	unsigned short qp_avv[6];
	Index_t index;
	int v_start;
	int h_start;
	int qp_thresh;

	if ( slice_header.disable_deblocking_filter_idc != 1 )
	{
//		assert(slice_header.disable_deblocking_filter_idc == 0);


		for ( k = 0; k < WIDTH * HEIGHT; k++ )
		{
			int j = k % WIDTH;
			int i = k / WIDTH;
			unsigned short filterLeftMbEdgeFlag = (j > 0) ? 1 : 0;
			unsigned short filterTopMbEdgeFlag = (i > 0) ? 1 : 0;
			if (k ==3593&& pic_num == 3){
				int abcd=1;
			}
			qp_thresh = 15 - filter_offsetA - (pps.chroma_qp_index_offset > 0 ? pps.chroma_qp_index_offset : 0);
			fprintf(fp_deblock_dbg, "pic_num=%04d, mb_index=%04d\n", pic_num, k);

			if (qp_z[i][j] <= qp_thresh 
				&& (j == 0 || ((qp_z[i][j] + qp_z[i][j-1] + 1) >> 1) <= qp_thresh) 
				&& (i == 0 || ((qp_z[i][j] + qp_z[i-1][j] + 1) >> 1) <= qp_thresh) ){
/*				fprintf(fp_deblock_dbg, "ver bs=%1d %1d %1d %1d\n", 0,0,0,0);
				fprintf(fp_deblock_dbg, "ver bs=%1d %1d %1d %1d\n", 0,0,0,0);
				fprintf(fp_deblock_dbg, "ver bs=%1d %1d %1d %1d\n", 0,0,0,0);
				fprintf(fp_deblock_dbg, "ver bs=%1d %1d %1d %1d\n", 0,0,0,0);
				fprintf(fp_deblock_dbg, "hor bs=%1d %1d %1d %1d\n", 0,0,0,0);
				fprintf(fp_deblock_dbg, "hor bs=%1d %1d %1d %1d\n", 0,0,0,0);
				fprintf(fp_deblock_dbg, "hor bs=%1d %1d %1d %1d\n", 0,0,0,0);
				fprintf(fp_deblock_dbg, "hor bs=%1d %1d %1d %1d\n", 0,0,0,0);
*/				continue;
			}
			
			v_start = 0;
			h_start = 0;
			if (filterLeftMbEdgeFlag == 0){
				v_start = 1;
			}
			else if (slice_header.disable_deblocking_filter_idc == 2 && slice_table[k] != slice_table[k-1]){
				v_start = 1;
			}
	
		   	if (filterTopMbEdgeFlag == 0){
				h_start = 1;
			}
			else if (slice_header.disable_deblocking_filter_idc == 2 && slice_table[k] != slice_table[k-WIDTH]){
				h_start = 1;
			}
			
			

			qp_avv[0] = qp_z[i][j];
			
			if (v_start == 1)
				qp_avv[2] = (qp_z[i][j] + qp_z[i][j] + 1) >> 1;
			else
				qp_avv[2] = (qp_z[i][j-1] + qp_z[i][j] + 1) >> 1;
				
			if (h_start == 1)
				qp_avv[1] = (qp_z[i][j] + qp_z[i][j] + 1) >> 1;
			else
				qp_avv[1] = (qp_z[i-1][j] + qp_z[i][j] + 1) >> 1;
				
				
			qp_avv[3] = qp_z_c[i][j];
			
			if (v_start == 1)
				qp_avv[5] = (qp_z_c[i][j] + qp_z_c[i][j] + 1) >> 1;
			else
				qp_avv[5] = (qp_z_c[i][j-1] + qp_z_c[i][j] + 1) >> 1;
				
			if (h_start == 1)
				qp_avv[4] = (qp_z_c[i][j] + qp_z_c[i][j] + 1) >> 1;
			else
				qp_avv[4] = (qp_z_c[i-1][j] + qp_z_c[i][j] + 1) >> 1;
			
			fprintf(fp_deblock_dbg, "qp0=%02d,qp1=%02d,qp2=%02d,qp3=%02d,qp4=%02d,qp5=%02d\n", 
					qp_avv[0], qp_avv[1],qp_avv[2],qp_avv[3],qp_avv[4],qp_avv[5]);

			//qp_avv[0] = qp_avv[1] = qp_avv[2] = qp_z[0][0];
			//qp_avv[3] = qp_avv[4] = qp_avv[5] = qp_z_c[0][0];
	// qPav = ( qPp + qPq + 1 ) >> 1, an average quantisation parameter, Average QP of the two blocks
	// 亮度边界情况下 qPp,qPq采用亮度的qp
	// 亮度+色度边界的情况下，
	//	If chromaEdgeFlag is equal to 0, the following applies.
	//	If the macroblock containing the sample z0 is an I_PCM macroblock, qPz is set to 0.
	//	Otherwise (the macroblock containing the sample z0 is not an I_PCM macroblock), qPz is set to the value of QPY of the macroblock containing the sample z0.
	//	Otherwise (chromaEdgeFlag is equal to 1), the following applies.
	//	If the macroblock containing the sample z0 is an I_PCM macroblock, qPz is set to the value of QPC that corresponds to a value of 0 for QPY as specified in subclause 8.5.7.
	//	Otherwise (the macroblock containing the sample z0 is not an I_PCM macroblock), 
	//  qPz is set to the value of QPC that corresponds to the value QPY of the macroblock containing the sample z0 as specified in subclause 8.5.7.
	
	//QP  = yuv ? (QP_SCALE_CR[CQPOF(MbP->qp,uv)] + QP_SCALE_CR[CQPOF(MbQ->qp,uv)] + 1) >> 1 : (MbP->qp + MbQ->qp + 1) >> 1;
	
			for ( t = 0; t < 6; t++ )
			{
				index.indexA[t] = Clip3(0, 51, qp_avv[t] + filter_offsetA);
				index.indexB[t] = Clip3(0, 51, qp_avv[t] + filter_offsetB);
				index.alpha[t] = alpha_indexA[index.indexA[t]];
				index.beta[t] = beta_indexB[index.indexB[t]];
			}
			//if ( i == 116 && slice_num == 3 )
			//{
			//	__asm int 3
			//}
			if (k==149){
				int abcd = 1;
			}
			deblocking_mb(k,v_start,h_start,qp_avv, index, current_pic.Y, current_pic.U, current_pic.V);
			//if ( current_pic.Y[17][13] == 236 )
			//{
			 //   __asm int 3
			//}
		}
	}
}



































