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
#include "macroblock.h"
#include "cavlc.h"
#include "transform.h"
#include "intrapred.h"
#include "interpred.h"
#include "macroblock.h"
#include "bitstream_header.h"
#include <assert.h>
#include <stdio.h>
#include <string.h>

extern unsigned short WIDTH, HEIGHT;
extern unsigned short **intra_pred_mode;
extern unsigned short **intra_mode;
extern unsigned short **qp_z;
extern unsigned short **qp_z_c;
extern unsigned short **nnz;
extern unsigned short ***nnz_chroma;
extern Picture_t current_pic;
extern short** RefIdx;
extern short ***MV;
extern unsigned short slice_mb_index;
extern int debug_flag;
macroblock_t cur_mb;

extern unsigned short slice_num;
extern unsigned short mb_index;
extern unsigned short cur_mb_index;
unsigned short first_mb_index_in_slice;
extern unsigned short pic_num;
#define TRACE_MB_PRED_INDEX 315
#define TRACE_MB_PRED_SLICE 92

unsigned short qp_z_a;
unsigned short qp_z_c_a;

short chroma_qp_table[52] = {
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9,10,11,
   12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,
   28,29,29,30,31,32,32,33,34,34,35,35,36,36,37,37,
   37,38,38,38,39,39,39,39
};

short get_qp_z_c(int qp_z, int chroma_qp_offset){
	return chroma_qp_table[Clip3(0, 51,qp_z+chroma_qp_offset)];
}

// the main decoder function Inter也放这里了
void Intra_Dec_One_Macroblock( 
							  unsigned char rbsp[], 
							  unsigned int& bytes_offset, 
							  unsigned short& bits_offset,
							  unsigned short mb_index,
							  int is_first_mb_in_slice,
							  SliceType st, 
							  const SliceHeader_t& slice_header,
							  const PPS_t& pps,
							  const SPS_t& sps)
{
	unsigned short len = 0;
	PredMode pred_mode;
	unsigned short I16_Pred_Mode; // DC, Vertical, Horizontal, Plain
	unsigned short CBPChroma;
	unsigned short CBPLuma;
	unsigned short intra_pre_mode_chroma;
	unsigned short CodedBlockPattern;
	short qp_delta;
	unsigned short i = mb_index / WIDTH;
	unsigned short j = mb_index % WIDTH;
	unsigned short block_idx;

	unsigned short _i;
	short qp_tmp;
	static unsigned short qp_y_prev;

	unsigned short mb_type = read_ue_v(rbsp, bytes_offset, bits_offset, len);
	GotoNextNBits(len);

	if ( st == I )
	{
		if (mb_type == 0)
		{
			//Log("============MB Index : %d, Predmode : I4MB=========================\n", mb_index);
			pred_mode = I4MB;
		}
		else if (mb_type == 25)
		{
			pred_mode = IPCM;
		}
		else
		{
			//Log("============MB Index : %d, Predmode : I16MB, MB Type : %d==========\n", mb_index, mb_type);
			pred_mode = I16MB;
			mb_type--;
		}

	}
	else if ( st == P )
	{
        //Log("============MB Index : %d ", mb_index);
		assert( mb_type >= 0 && mb_type <= 30 );
		switch ( mb_type )
		{
		case 0:
		case 1:
		case 2:
		case 3:
			pred_mode = PRED_L0;
			//Log("PredMode : PRED_L0 ==============\n");
			break;
		case 4:
			pred_mode = P_REF0;
			//Log("PredMode : P_REF0 ===============\n");
			break;
			//Spec 2005.3 p106: The macroblock types for P and SP slices are specified in Table 7 13 and Table 7 11. 
			//mb_type values 0 to 4 are specified in Table 7 13 and mb_type values 5 to 30 are specified in Table 7 11, 
			//indexed by subtracting 5 from the value of mb_type.
		case 5:
			pred_mode = I4MB;
			//Log("PredMode : I4MB =================\n");
			break;
		case 30:
			pred_mode = I16MB;
			//Log("PredMode : IPCM ================\n");
			break;
		default:
			pred_mode = I16MB;
			//Log("PredMode : I16MB ================\n");
			mb_type -= 6;
		}
	}
	else if ( st == B )
	{
		assert( mb_type >= 0 && mb_type <= 48 );

	}

	if ( pred_mode == I16MB )
	{
		I16_Pred_Mode = mb_type & 0x03;
		CBPLuma = (mb_type >= 12 ? 15 : 0);
		CBPChroma = (mb_type % 12) / 4;

		// 把CBPLuma和CBPChroma合起来, 高四个字节CBPChroma,低四个字节CBPLuma
		// CBPChroma为0x0010或0x0011, 0x0010只传色度的DC分量,0x0011传色度AC和DC
		// 0001 1111 => 31
		CodedBlockPattern = (0x30 & (CBPChroma  << 4)) | CBPLuma; 
	}

	if (pred_mode == IPCM)
	{
		Dec_IPCM_Macroblock();
		return;
	}

	Read_MB_Pred( 
		rbsp, 
		bytes_offset, 
		bits_offset,
		mb_index,
		slice_header, 
		sps, 
		pps, 
		pred_mode, 
		mb_type,
		intra_pre_mode_chroma);
	if (pred_mode != I16MB)
	{
		if ( pred_mode == I4MB )
		{
            CodedBlockPattern = read_me_v(rbsp, bytes_offset, bits_offset, 1, len);
		}
		else
		{
            CodedBlockPattern = read_me_v(rbsp, bytes_offset, bits_offset, 0, len);
		}
		GotoNextNBits(len);
	}

	// 协议中 : CBPLuma > 0 || CBPChroma > 0 || pred_mode == I16MB

	if (is_first_mb_in_slice)
	{
		qp_z[i][j] = pps.pic_init_qp_minus26 + 26 + slice_header.slice_qp_delta ;
		qp_z_c[i][j] = Clip3(0, 51, qp_z[i][j] + pps.chroma_qp_index_offset);
		qp_y_prev = qp_z[i][j];
	}
	if ( CodedBlockPattern || pred_mode == I16MB )
	{
		qp_delta = read_se_v(rbsp, bytes_offset, bits_offset, len);
		GotoNextNBits(len);
		qp_tmp =  (short)(qp_y_prev) + qp_delta;//binq
		qp_z[i][j] = qp_y_prev + qp_delta;

		if (qp_tmp < 0)
			qp_z[i][j] = qp_tmp + 52;
		else if ( qp_tmp > 51)
			qp_z[i][j] = qp_tmp - 52;
		else
			qp_z[i][j] = qp_tmp;
		qp_y_prev = qp_z[i][j];
	}
	else
	{
		qp_z[i][j] = qp_y_prev;
	}

	qp_z_c[i][j] = get_qp_z_c(qp_z[i][j], pps.chroma_qp_index_offset);
	
	qp_z_a = qp_z[i][j];
	qp_z_c_a = qp_z_c[i][j];
	residual(rbsp, bytes_offset, bits_offset, mb_index, pred_mode, qp_z[i][j], qp_z_c[i][j], CodedBlockPattern);
	

	pred_avail_check(mb_index, pps);
	if (pred_mode == I16MB)
	{
		IntraPred16(mb_index, I16_Pred_Mode, pps);
		IntraPredChroma(mb_index, intra_pre_mode_chroma, pps);
	}
	else if (pred_mode == I4MB)
	{
		for (block_idx = 0; block_idx < 16; block_idx++)
		{
			IntraPred4(mb_index, block_idx, pps);
		}
		IntraPredChroma(mb_index, intra_pre_mode_chroma, pps);
	}
	else
	{
		InterPred(mb_index);
	}	
}

void Dec_IPCM_Macroblock()
{

}

// 把帧内4x4亮度块预测模式读到全局变量intra_pred_mode中,色度块的预测模式通过intra_pre_mode_chroma返回,
// 16x16块只读取了一个intra_pred_mode_chroma信息
void Read_MB_Pred( unsigned char rbsp[], 
				  unsigned int& bytes_offset, 
				  unsigned short& bits_offset,
				  unsigned short mb_index,
				  const SliceHeader_t& slice_header,
				  const SPS_t& sps,
				  const PPS_t& pps, 
				  PredMode pred_mode,
				  unsigned short mb_type,
				  unsigned short& intra_pre_mode_chroma )
{
	unsigned short y0 = mb_index / WIDTH;
	unsigned short x0 = mb_index % WIDTH;
	unsigned short y = y0 * 4;
	unsigned short x = x0 * 4;
	unsigned short I4MB_pred_mode;
	unsigned short blockIdx;
	unsigned short len = 0;
	unsigned short i, j;
	SliceType st = static_cast<SliceType>(slice_header.slice_type % 5);
	short ref0, ref1;
	short mvp[2];

	static const unsigned short i_blockidx[16] = {0,0,1,1,0,0,1,1,2,2,3,3,2,2,3,3};
	static const unsigned short j_blockidx[16] = {0,1,0,1,2,3,2,3,0,1,0,1,2,3,2,3};

	if (pred_mode == I4MB || pred_mode == I16MB)
	{
		if (pred_mode == I4MB)
		{
			for (blockIdx = 0; blockIdx < 16; blockIdx++)
			{
				i = (4 * y0) + i_blockidx[blockIdx];
				j = (4 * x0) + j_blockidx[blockIdx];
				unsigned short mostProbableIntraPredMode = 
					Get_MostProbableIntraPredMode(i, j);
				unsigned short prev_intra4_pred_mode_flag = 
					read_one_bit(rbsp, bytes_offset, bits_offset);
					GotoNextBit;
				// prev_intra4_pred_mode_flag = 1, 使用最有可能预测方式

				if (!prev_intra4_pred_mode_flag)
				{
					unsigned short rem_intra4_pred_mode = 
						read_bits(rbsp, bytes_offset, bits_offset, 3);
					GotoNextNBits(3);

					if (rem_intra4_pred_mode >= mostProbableIntraPredMode)
					{
						I4MB_pred_mode = rem_intra4_pred_mode + 1;
					}
					else
					{
						I4MB_pred_mode = rem_intra4_pred_mode;

					}
				}
				else
				{
					I4MB_pred_mode = mostProbableIntraPredMode;
				}
				intra_pred_mode[i][j] = I4MB_pred_mode;
			}

		}

		intra_pre_mode_chroma = read_ue_v(rbsp, bytes_offset, bits_offset, len);
		intra_mode[y0][x0] = 1;
		GotoNextNBits(len);
		
		if ( st == P )
		{
			RefIdx[y0 * 2    ][x0 * 2    ] = 
			RefIdx[y0 * 2 + 1][x0 * 2    ] = 
			RefIdx[y0 * 2    ][x0 * 2 + 1] = 
			RefIdx[y0 * 2 + 1][x0 * 2 + 1] = -1;
		}
		
		//return;
	}
	if ( pred_mode == PRED_L0 || pred_mode == P_REF0 )
	{
		switch ( mb_type )
		{
		case 0: // P_L0_16x16
			if (slice_header.num_ref_idx_active_override_flag && slice_header.num_ref_idx_l0_active_minus1 > 0) // 不是用pps.num_ref_idx_10_active_minus1
			{
				ref0 = read_te_v(rbsp, bytes_offset, bits_offset, len, slice_header.num_ref_idx_l0_active_minus1+1); 
				GotoNextNBits(len);
			}
			else if(slice_header.num_ref_idx_active_override_flag == 0 && pps.num_ref_idx_l0_active_minus1 > 0) {
				ref0 = read_te_v(rbsp, bytes_offset, bits_offset, len, pps.num_ref_idx_l0_active_minus1+1); 
				GotoNextNBits(len);
			}
			else
			{
				ref0 = 0;
			}
			// ref_idx每个8x8块一个? 最小8x8块一个?, 
			RefIdx[y0 * 2    ][x0 * 2    ] = 
			RefIdx[y0 * 2 + 1][x0 * 2    ] = 
			RefIdx[y0 * 2    ][x0 * 2 + 1] = 
			RefIdx[y0 * 2 + 1][x0 * 2 + 1] = ref0;
			
			// MV x,y轴各一个
            get_mvp(x, y, 4, 4, mb_index, ref0, mvp);
			mvp[0] += read_se_v(rbsp, bytes_offset, bits_offset, len);
			GotoNextNBits(len);
			mvp[1] += read_se_v(rbsp, bytes_offset, bits_offset, len);
			GotoNextNBits(len);
//		if (mvp[0]>64 || mvp[1]>64)
//			printf("mvp[0]=%d,mvp[1]=%d\n",mvp[0],mvp[1]);
            cur_mb.par_num = 1;
			cur_mb.mv_par[0].refidx = ref0;
			cur_mb.mv_par[0].height = cur_mb.mv_par[0].width = 16;
			cur_mb.mv_par[0].mv_x = mvp[0];
			cur_mb.mv_par[0].mv_y = mvp[1];
			cur_mb.mv_par[0].pos_x = x0 * 16;
			cur_mb.mv_par[0].pos_y = y0 * 16;


			for ( i = 0; i < 4; i++ )
			{
				for ( j = 0; j < 4; j++)
				{
					MV[0][y + j][x + i] = mvp[0];
					MV[1][y + j][x + i] = mvp[1];
				}
			}

			break;
		case 1: // P_L0_L0_16x8
			if (slice_header.num_ref_idx_active_override_flag && slice_header.num_ref_idx_l0_active_minus1 > 0) // 不是用pps.num_ref_idx_10_active_minus1
			{
				ref0 = read_te_v(rbsp, bytes_offset, bits_offset, len, slice_header.num_ref_idx_l0_active_minus1+1); 
				GotoNextNBits(len);
				ref1 = read_te_v(rbsp, bytes_offset, bits_offset, len, slice_header.num_ref_idx_l0_active_minus1+1);
				GotoNextNBits(len);
			}
			else if(slice_header.num_ref_idx_active_override_flag == 0 && pps.num_ref_idx_l0_active_minus1 > 0) {
				ref0 = read_te_v(rbsp, bytes_offset, bits_offset, len, pps.num_ref_idx_l0_active_minus1+1); 
				GotoNextNBits(len);
				ref1 = read_te_v(rbsp, bytes_offset, bits_offset, len, pps.num_ref_idx_l0_active_minus1+1);
				GotoNextNBits(len);
			}
			else
			{
				ref0 = 0; 
				ref1 = 0;
			}

			RefIdx[y / 2    ][x / 2] = RefIdx[y / 2    ][x / 2 + 1] = ref0;
			RefIdx[y / 2 + 1][x / 2] = RefIdx[y / 2 + 1][x / 2 + 1] = ref1;
			
			cur_mb.par_num = 2;
			cur_mb.mv_par[0].refidx = ref0;
			cur_mb.mv_par[1].refidx = ref1;
			cur_mb.mv_par[0].width = 16;
			cur_mb.mv_par[1].width = 16;
			cur_mb.mv_par[0].height = 8;
			cur_mb.mv_par[1].height = 8;

			get_mvp(x, y, 4, 2, mb_index, ref0, mvp);
			mvp[0] += read_se_v(rbsp, bytes_offset, bits_offset, len);
			GotoNextNBits(len);
			mvp[1] += read_se_v(rbsp, bytes_offset, bits_offset, len);
			GotoNextNBits(len);
//		if (mvp[0]>64 || mvp[1]>64)
//			printf("mvp[0]=%d,mvp[1]=%d\n",mvp[0],mvp[1]);
            cur_mb.mv_par[0].mv_x = mvp[0];
			cur_mb.mv_par[0].mv_y = mvp[1];
			cur_mb.mv_par[0].pos_x = x0 * 16;
			cur_mb.mv_par[0].pos_y = y0 * 16;

			for ( i = 0; i < 4; i++ )
			{
				for ( j = 0; j < 2; j++ )
				{
					MV[0][y + j][x + i] = mvp[0];
					MV[1][y + j][x + i] = mvp[1];
				}
			}

			get_mvp(x, y + 2, 4, 2, mb_index, ref1, mvp);
			mvp[0] += read_se_v(rbsp, bytes_offset, bits_offset, len);
			GotoNextNBits(len);
			mvp[1] += read_se_v(rbsp, bytes_offset, bits_offset, len);
			GotoNextNBits(len);
//		if (mvp[0]>=64 || mvp[1]>=64)
//			printf("mvp[0]=%d,mvp[1]=%d\n",mvp[0],mvp[1]);
            cur_mb.mv_par[1].mv_x = mvp[0];
			cur_mb.mv_par[1].mv_y = mvp[1];
			cur_mb.mv_par[1].pos_x = x0 * 16;
			cur_mb.mv_par[1].pos_y = y0 * 16 + 8;

			for ( i = 0; i < 4; i++ )
			{
				for ( j = 2; j < 4; j++ )
				{
					MV[0][y + j][x + i] = mvp[0];
					MV[1][y + j][x + i] = mvp[1];
				}
			}

			break;
		case 2: // P_L0_L0_8x16
		if (mb_index== 149){
			int abcd=1;
		}
			if (slice_header.num_ref_idx_active_override_flag && slice_header.num_ref_idx_l0_active_minus1 > 0) // 不是用pps.num_ref_idx_10_active_minus1
			{
				ref0 = read_te_v(rbsp, bytes_offset, bits_offset, len, slice_header.num_ref_idx_l0_active_minus1+1); 
				GotoNextNBits(len);
				ref1 = read_te_v(rbsp, bytes_offset, bits_offset, len, slice_header.num_ref_idx_l0_active_minus1+1);
				GotoNextNBits(len);
			}
			else if(slice_header.num_ref_idx_active_override_flag == 0 && pps.num_ref_idx_l0_active_minus1 > 0) {
				ref0 = read_te_v(rbsp, bytes_offset, bits_offset, len, pps.num_ref_idx_l0_active_minus1+1); 
				GotoNextNBits(len);
				ref1 = read_te_v(rbsp, bytes_offset, bits_offset, len, pps.num_ref_idx_l0_active_minus1+1);
				GotoNextNBits(len);
			}
			else
			{
				ref0 = 0; 
				ref1 = 0;
			}
			RefIdx[y / 2][x / 2    ] = RefIdx[y / 2 + 1][x / 2    ] = ref0;
			RefIdx[y / 2][x / 2 + 1] = RefIdx[y / 2 + 1][x / 2 + 1] = ref1;

            cur_mb.par_num = 2;
			cur_mb.mv_par[0].refidx = ref0;
			cur_mb.mv_par[1].refidx = ref1;
			cur_mb.mv_par[0].width = 8;
			cur_mb.mv_par[1].width = 8;
			cur_mb.mv_par[0].height = 16;
			cur_mb.mv_par[1].height = 16;

            get_mvp(x, y, 2, 4, mb_index, ref0, mvp);
			mvp[0] += read_se_v(rbsp, bytes_offset, bits_offset, len);
			GotoNextNBits(len);
			mvp[1] += read_se_v(rbsp, bytes_offset, bits_offset, len);
			GotoNextNBits(len);
//		if (mvp[0]>64 || mvp[1]>64)
//			printf("mvp[0]=%d,mvp[1]=%d\n",mvp[0],mvp[1]);
			cur_mb.mv_par[0].mv_x = mvp[0];
			cur_mb.mv_par[0].mv_y = mvp[1];
			cur_mb.mv_par[0].pos_x = x0 * 16;
			cur_mb.mv_par[0].pos_y = y0 * 16;

			for ( i = 0; i < 2; i++ )
			{
				for ( j = 0; j < 4; j++ )
				{
                    MV[0][y + j][x + i] = mvp[0];
					MV[1][y + j][x + i] = mvp[1];
				}
			}

			get_mvp(x + 2, y, 2, 4, mb_index, ref1, mvp);
			mvp[0] += read_se_v(rbsp, bytes_offset, bits_offset, len);
			GotoNextNBits(len);
			mvp[1] += read_se_v(rbsp, bytes_offset, bits_offset, len);
			GotoNextNBits(len);
//		if (mvp[0]>64 || mvp[1]>64)
//			printf("mvp[0]=%d,mvp[1]=%d\n",mvp[0],mvp[1]);
			cur_mb.mv_par[1].mv_x = mvp[0];
			cur_mb.mv_par[1].mv_y = mvp[1];
			cur_mb.mv_par[1].pos_x = x0 * 16 + 8;
			cur_mb.mv_par[1].pos_y = y0 * 16;

			for ( i = 2; i < 4; i++ )
			{
				for ( j = 0; j < 4; j++ )
				{
					MV[0][y + j][x + i] = mvp[0];
					MV[1][y + j][x + i] = mvp[1];
				}
			}

			break;

		case 3: // P_8x8,
		case 4: // P_8x8ref0
			Read_Sub_MB_Pred(rbsp, bytes_offset, bits_offset, mb_index, slice_header, sps, pps, pred_mode);
			break;
		default:
			assert( 0 );
		}
	}
	if (st != SI && st != I && c_mv_out)
	{
		Log_mv("pic_num:%5d mb_index_out:%5d\n",pic_num,mb_index);
		for (j=0;j<4;j++)
			fprintf(c_mv_out, "mvx_l0_curr_mb_out:%5d%5d%5d%5d\n",(unsigned short)MV[0][y+j][x],(unsigned short)MV[0][y+j][x+1],(unsigned short)MV[0][y+j][x+2],(unsigned short)MV[0][y+j][x+3]);
		for (j=0;j<4;j++)
			fprintf(c_mv_out, "mvy_l0_curr_mb_out:%5d%5d%5d%5d\n",(unsigned short)MV[1][y+j][x],(unsigned short)MV[1][y+j][x+1],(unsigned short)MV[1][y+j][x+2],(unsigned short)MV[1][y+j][x+3]);
		fprintf(c_mv_out, "\n");
	}
}

unsigned short Get_MostProbableIntraPredMode(unsigned short i, unsigned short j)
{
	short min_val, left, top, pos_x, pos_y, blk_x, blk_y;
	pos_x = j >> 2;
	pos_y = i >> 2;
	blk_x = j&3;
	blk_y = i&3;
	if (i > 0 && !(blk_y == 0 && slice_mb_index < WIDTH)){
		top = intra_pred_mode[i - 1][j];
	}
	else {
		top = -1;
	}
	if (j > 0 && !(blk_x == 0 && slice_mb_index == 0 )){
		left = intra_pred_mode[i][j - 1];
	}
	else {
		left = -1;
	}
	min_val = min(left, top);
		return min_val >= 0 ? min_val : 2;
}

void residual(unsigned char rbsp[], 
			  unsigned int& bytes_offset, 
			  unsigned short& bits_offset, 
			  unsigned short mb_index,
			  PredMode pred_mode,
			  unsigned short QP,
			  unsigned short QP_C,
			  unsigned short CBP)
{
	short luma[16][16] = { 0 };
	short chroma[2][4][16] = { 0 };
	short p[16] = { 0 };

	unsigned short len = 0;
	
	unsigned short pos_x = mb_index % WIDTH;
	unsigned short pos_y = mb_index / WIDTH;

	unsigned short i, j, k;
	unsigned short nC;

	static const unsigned short idx_scan[16] = 
	{0,1,4,5,2,3,6,7,8,9,12,13,10,11,14,15};

	//static const unsigned short qp_chroma[52] = {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,
	//	23,24,26,26,27,28,29,29,30,31,32,32,33,34,34,35,35,36,36,37,37,37,38,38,38,39,39,39,39};

//	static const unsigned short qp_chroma[52] = {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,
//		23,24,25,26,27,28,29,29,30,31,32,32,33,34,34,35,35,36,36,37,37,37,38,38,38,39,39,39,39}; // 标准2005年3月
                          // 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51

	static const unsigned short i_blockidx[16] = {0,0,1,1,0,0,1,1,2,2,3,3,2,2,3,3};
	static const unsigned short j_blockidx[16] = {0,1,0,1,2,3,2,3,0,1,0,1,2,3,2,3};

	unsigned short idx;
	unsigned short i8x8, i4x4;
	unsigned short iCbCr;
	int is_left_mb_in_same_slice;
	int is_up_mb_in_same_slice;
	int left_avail;
	int up_avail;
	int is_in_mb_left;
	int is_in_mb_top;
	int nA,nB;
	int p_int[16];


	  
	is_left_mb_in_same_slice = slice_mb_index > 0;
	is_up_mb_in_same_slice = slice_mb_index >= WIDTH;
	
	if (mb_index == 1858 && pic_num == 197){ 
		int abc=1;
	} 
	if (pred_mode == I16MB)
	{
		i = pos_y * 4;
		j = pos_x * 4;
		// nnz[Height*4][Width*4]的每个位置上未必都有值，有的4x4块都不需要进行cavlc变换，直接用0填充???
		// 直流系数的nnz当作第一个交流系数4x4块的nnz
		        if (i == 0 && j == 0)
				{
					nC = 0;
				}
				else if (i == 0 && j != 0)
				{
					if (!is_left_mb_in_same_slice)
						nC = 0;
					else
						nC = nnz[0][j -1];
				}
				else if (i != 0 && j == 0)
				{
					if (!is_up_mb_in_same_slice)
						nC = 0;
					else
						nC = nnz[i - 1][0];
				}
				else if (i != 0 && j != 0)
				{
					nA = 0;
					nB = 0;
					up_avail = 0;
					left_avail = 0;
					if (is_left_mb_in_same_slice) {
						left_avail = 1;
						nA = nnz[i][j-1];
					}
					if (is_up_mb_in_same_slice){
						up_avail = 1;
						nB = nnz[i-1][j];
					}
					nC = (left_avail && up_avail) ? (nA+nB+1)/2 : nA + nB;
				}
		// output p
		cavlc(rbsp, bytes_offset, bits_offset, nC, 16, p, 16);
		inverse_zigzag(p);
		DHT(p);
		inverse_quant(QP, 1, p, p_int);

		for (idx = 0; idx < 16; idx++)
		{
			luma[idx_scan[idx]][0] = (p_int[idx] + 2) >> 2;
		}
	}
	
	idx = 0;
	for (i8x8 = 0; i8x8 < 4; i8x8++)
	{
		for (i4x4 = 0; i4x4 < 4; i4x4++, idx++)
		{
			// 由idx 0,1,4,5...转换成正常x,y位置
			i = pos_y * 4;
			j = pos_x * 4;
			i += i_blockidx[idx];
			j += j_blockidx[idx];
			nnz[i][j] = 0;

			// CodedBlockPattern的用法，低四位亮度，高2位色度，低4位每一个表示第i个8x8块的直流+交流是否编码，
			// 低2位表示CbCr的直流/交流是否编码，11时直流才编码，CbCr的2x4个直流系数单独拎出来做DHT变换，
			// 亮度的话16x16直流系数拎出来，4x4不拎
			if (CBP & (1 << i8x8)) 
			{
				is_in_mb_left = i8x8 == 0 && i4x4 == 0 || i8x8 == 0 && i4x4 == 2 || i8x8 == 2 && i4x4 == 0 || i8x8 == 2 && i4x4 == 2;
				is_in_mb_top = i8x8 == 0 && i4x4 == 0 || i8x8 == 0 && i4x4 == 1 || i8x8 == 1 && i4x4 == 0 || i8x8 == 1 && i4x4 == 1;
				if (i == 0 && j == 0)
				{
					nC = 0;
				}
				else if (i == 0 && j != 0)
				{
					if (!is_left_mb_in_same_slice && is_in_mb_left)
						nC = 0;
					else
						nC = nnz[0][j -1];
				}
				else if (i != 0 && j == 0)
				{
					if (!is_up_mb_in_same_slice && is_in_mb_top)
						nC = 0;
					else
						nC = nnz[i - 1][0];
				}
				else if (i != 0 && j != 0)
				{
					nA = 0;
					nB = 0;
					up_avail = 0;
					left_avail = 0;
					if (is_left_mb_in_same_slice || !is_in_mb_left) {
						left_avail = 1;
						nA = nnz[i][j-1];
					}
					if (is_up_mb_in_same_slice || !is_in_mb_top){
						up_avail = 1;
						nB = nnz[i-1][j];
					}
					nC = (left_avail && up_avail) ? (nA+nB+1)/2 : nA + nB;
				}
				
				if (pred_mode == I16MB)
				{
					// i, j已经由i8x8,i4x4转换成正常位置了
					nnz[i][j] = cavlc(rbsp, bytes_offset, bits_offset, nC, 15, &luma[idx][1], 15);
					if (nnz[i][j])
					{
						inverse_zigzag(&luma[idx][0]);
						inverse_quant(QP, 2, &luma[idx][0], p_int);
						for (int ii = 1; ii < 16; ii++)
						{
							luma[idx][ii] = p_int[ii];
						}
						IDCT(luma[idx], 32);
					}
					else
					{
						luma[idx][0] = (luma[idx][0] + 32) >> 6;
						for (k = 1; k < 16; k++)
						{
							luma[idx][k] = luma[idx][0];
						}
					}
				}
				else
				{
					nnz[i][j] = cavlc(rbsp, bytes_offset, bits_offset, nC, 16, &luma[idx][0], 16);
					if (nnz[i][j])
					{
						inverse_zigzag(&luma[idx][0]);
						inverse_quant(QP, 3, &luma[idx][0], p_int);
						for (int ii = 0; ii < 16; ii++)
						{
							luma[idx][ii] = p_int[ii];
						}
						IDCT(luma[idx], 0);
					}
					else				// luma[16][16] is default initialized zero
					{
						for (k = 0; k < 16; k++)
						{
							luma[idx][k] = 0;
						}
					}
				}
				
			}
			else
			{
				if (luma[idx][0])
				{
					luma[idx][0] = (luma[idx][0] + 32) >> 6;
					for (k = 1; k < 16; k++)
					{
						luma[idx][k] = luma[idx][0];
					}
				}
			}
			//if (debug_flag){
			if (c_residual_out){
				fprintf(c_residual_out, "pic_num:%5d mb_index_out:%5d blk:%5d\n",pic_num, mb_index,  idx);		
				fprintf(c_residual_out, "%5d%5d%5d%5d\n", luma[idx][0], luma[idx][1], luma[idx][2], luma[idx][3]);
				fprintf(c_residual_out, "%5d%5d%5d%5d\n", luma[idx][4], luma[idx][5], luma[idx][6], luma[idx][7]);
				fprintf(c_residual_out, "%5d%5d%5d%5d\n", luma[idx][8], luma[idx][9], luma[idx][10], luma[idx][11]);
				fprintf(c_residual_out, "%5d%5d%5d%5d\n\n", luma[idx][12], luma[idx][13], luma[idx][14], luma[idx][15]);
				fflush(c_residual_out);
			}
			//}
		}
		
	}

	// copy luma[16][16] to current_pic.luma
	// luma[i]还是0145 2367的位置
	for (i = 0; i < 16; i++)
	{
		for (j = 0; j < 16; j++)
		{
			current_pic.Y[pos_y * 16 + idx_scan[i] / 4 * 4 + j / 4][pos_x * 16 + idx_scan[i] % 4 * 4 + j % 4] = luma[i][j];
		}
	}


	if (slice_num == 5 && mb_index == 9)
		{
			int a;
			a = 1;
		}

	// 码流中存放顺序,Cb直流,Cr直流,四对Cb,Cr交流
	if (CBP & 0x30) // chroma DC residual present 0x1F 11,01,10
	{
		for (iCbCr = 0; iCbCr < 2; iCbCr++)
		{
			// nC = -1
			// p以前被用过了,所以要重新初始化
			memset(p, 0, 16 * sizeof(short));
			cavlc(rbsp, bytes_offset, bits_offset, -1, 4, p, 4);
			DHT2(p);
			inverse_quant(QP_C, 5, p, p_int);
			// 分成4个4x4的块
			for (idx = 0; idx < 4; idx++)
			{
				chroma[iCbCr][idx][0] = (p_int[idx])>> 1;
			}
		}
	}

	if (CBP & 0x20) // chroma AC residual present 11 10
	{
		for (iCbCr = 0; iCbCr < 2;iCbCr++)
		{
			for (i4x4 = 0; i4x4 < 4; i4x4++)
			{
				i = (mb_index / WIDTH) * 2;
				j = (mb_index % WIDTH) * 2;
				if( i4x4 & 0x2 )
				{
					i += 1;
				}
				if( i4x4 & 0x1 ) 
				{
					j += 1;
				}
				
				is_in_mb_left = i4x4 == 0 || i4x4 == 2;
				is_in_mb_top = i4x4 == 0 || i4x4 == 1;
				if (i == 0 && j == 0)
				{
					nC = 0;
				}
				else if (i == 0 && j != 0)
				{
					if (!is_left_mb_in_same_slice && is_in_mb_left)
						nC = 0;
					else
						nC = nnz_chroma[iCbCr][0][j - 1];
				}
				else if (i != 0 && j == 0)
				{
					if (!is_up_mb_in_same_slice && is_in_mb_top)
						nC = 0;
					else
						nC = nnz_chroma[iCbCr][i - 1][0];
				}
				else if (i != 0 && j != 0)
				{
					nA = 0;
					nB = 0;
					up_avail = 0;
					left_avail = 0;
					if (is_left_mb_in_same_slice || !is_in_mb_left) {
						left_avail = 1;
						nA = nnz_chroma[iCbCr][i][j - 1];
					}
					if (is_up_mb_in_same_slice || !is_in_mb_top){
						up_avail = 1;
						nB = nnz_chroma[iCbCr][i - 1][j];
					}
					nC = (left_avail && up_avail) ? (nA+nB+1)/2 : nA + nB;
				}


				nnz_chroma[iCbCr][i][j] = cavlc(rbsp, bytes_offset, bits_offset, nC, 15, &chroma[iCbCr][i4x4][1], 15);
				if (nnz_chroma[iCbCr][i][j])
				{
					inverse_zigzag(&chroma[iCbCr][i4x4][0]);
					inverse_quant(QP_C, 6, &chroma[iCbCr][i4x4][0],p_int);
					for (int ii = 1; ii < 16; ii++)
					{
						chroma[iCbCr][i4x4][ii] = p_int[ii];
						//fprintf(c_sum_out, "mb:%d,[%d][%d][%d]", mb_index, iCbCr,i4x4,ii, chroma[iCbCr][i4x4][ii]);
					}
					//chroma[iCbCr][i4x4][0] += 32;
					IDCT(chroma[iCbCr][i4x4],0); // chroma[iCbCr][i4x4]相当于&chroma[iCbCr][i4x4][0]
				}
				else
				{
					if (chroma[iCbCr][i4x4][0])
					{
						chroma[iCbCr][i4x4][0] = (chroma[iCbCr][i4x4][0] + 32)>> 6;
						for (k = 1; k < 16; k++)
						{
							chroma[iCbCr][i4x4][k] = chroma[iCbCr][i4x4][0];
						}
					}
				}
				if (c_residual_out){
					fprintf(c_residual_out, "pic_num:%5d mb_index_out:%5d blk:%5d\n",pic_num, mb_index, 16+iCbCr*4+i4x4);
					fprintf(c_residual_out, "%5d%5d%5d%5d\n", chroma[iCbCr][i4x4][0], chroma[iCbCr][i4x4][1], chroma[iCbCr][i4x4][2], chroma[iCbCr][i4x4][3]);
					fprintf(c_residual_out, "%5d%5d%5d%5d\n", chroma[iCbCr][i4x4][4], chroma[iCbCr][i4x4][5], chroma[iCbCr][i4x4][6], chroma[iCbCr][i4x4][7]);
					fprintf(c_residual_out, "%5d%5d%5d%5d\n", chroma[iCbCr][i4x4][8], chroma[iCbCr][i4x4][9], chroma[iCbCr][i4x4][10], chroma[iCbCr][i4x4][11]);
					fprintf(c_residual_out, "%5d%5d%5d%5d\n\n", chroma[iCbCr][i4x4][12], chroma[iCbCr][i4x4][13], chroma[iCbCr][i4x4][14], chroma[iCbCr][i4x4][15]);
				}
			}  /*End of for*/
		} /*End of for*/
	} /* End of if*/
	else
	{
		for (iCbCr = 0; iCbCr < 2; iCbCr++)
		{
			for (i4x4 = 0; i4x4 < 4; i4x4++)
			{
				if (chroma[iCbCr][i4x4][0])
				{
					chroma[iCbCr][i4x4][0] = (chroma[iCbCr][i4x4][0] + 32)>> 6;
					for (k = 1; k < 16; k++)
					{
						chroma[iCbCr][i4x4][k] = chroma[iCbCr][i4x4][0];
					}
				} 
				if (c_residual_out) {
					fprintf(c_residual_out, "pic_num:%5d mb_index_out:%5d blk:%5d\n",pic_num, mb_index, 16+iCbCr*4+i4x4);
					fprintf(c_residual_out, "%5d%5d%5d%5d\n", chroma[iCbCr][i4x4][0], chroma[iCbCr][i4x4][1], chroma[iCbCr][i4x4][2], chroma[iCbCr][i4x4][3]);
					fprintf(c_residual_out, "%5d%5d%5d%5d\n", chroma[iCbCr][i4x4][4], chroma[iCbCr][i4x4][5], chroma[iCbCr][i4x4][6], chroma[iCbCr][i4x4][7]);
					fprintf(c_residual_out, "%5d%5d%5d%5d\n", chroma[iCbCr][i4x4][8], chroma[iCbCr][i4x4][9], chroma[iCbCr][i4x4][10], chroma[iCbCr][i4x4][11]);
					fprintf(c_residual_out, "%5d%5d%5d%5d\n\n", chroma[iCbCr][i4x4][12], chroma[iCbCr][i4x4][13], chroma[iCbCr][i4x4][14], chroma[iCbCr][i4x4][15]);
				}
			}
		}
	}

	for (i = 0; i < 4; i++)
	{
		for (j = 0; j < 16; j++)
		{
			current_pic.U[pos_y * 8 + i / 2 * 4 + j / 4][pos_x * 8 + i % 2 * 4 + j % 4] = chroma[0][i][j];
		}
	}
	
	for (i = 0; i < 4; i++)
	{
		for (j = 0; j < 16; j++)
		{
			current_pic.V[pos_y * 8 + i / 2 * 4 + j / 4][pos_x * 8 + i % 2 * 4 + j % 4] = chroma[1][i][j];
		}
	}


}

// x, y, MbPartWidth, MbPartHeight以4x4块为单位
void get_mvp(unsigned short x, 
			 unsigned short y, 
			 unsigned short MbPartWidth, 
			 unsigned short MbPartHeight, 
			 unsigned short mb_index,
			 short ref_idx, 
			 short* mvp)
{
	if(mb_index==269 && pic_num==2){
		int abc=1;
	}
    //           --------         ------------------
	//          |        |       |                  |
	//          |  up    |       |    up_right      |
	//          |        |       |                  |
	//  -------- ---------------- ------------------
	// |        |                |
	// |   left |                |
	// |        |                |
	//  --------|                |
	//          |                |
	//           ----------------

    
	short ref_left, ref_up, ref_up_right, ref_up_left;
	short mv_left_x, mv_left_y;
	short mv_up_x, mv_up_y;
	short mv_up_left_x, mv_up_left_y;
	short mv_up_right_x, mv_up_right_y;
	bool up_left_avial,up_avail, up_right_avail, left_avail;

	up_left_avial = test_block_available( x, y, MbPartWidth,MbPartHeight,0);
	up_avail = test_block_available( x, y, MbPartWidth,MbPartHeight,1);
    up_right_avail = test_block_available( x, y, MbPartWidth,MbPartHeight,2);		
	left_avail = test_block_available( x, y, MbPartWidth,MbPartHeight,3);

	if ( up_left_avial )
	{
		ref_up_left = RefIdx[(y - 1) / 2][(x - 1) / 2];
	}
	else
	{
		ref_up_left = -1;
	}

	if ( left_avail )
	{
		ref_left = RefIdx[y / 2][(x - 1) / 2];
	}
	else
	{
		ref_left = -1;
	}

	if ( up_avail )
	{
		ref_up = RefIdx[(y - 1) / 2][x / 2];
	}
	else
	{
		ref_up = -1;
	}

	if ( up_right_avail )
	{
		ref_up_right = RefIdx[(y - 1) / 2][(x + MbPartWidth) / 2];
	}
	else
	{
		ref_up_right = -1;
	}

    if ( ref_left == -1 )
	{
	    mv_left_x = 0;
		mv_left_y = 0;
	}
	else
	{
		mv_left_x = MV[0][y][x - 1];
		mv_left_y = MV[1][y][x - 1];
	}

	if ( ref_up == -1 )
	{
	    mv_up_x = 0;
		mv_up_y = 0;
	}
	else
	{
	    mv_up_x = MV[0][y - 1][x];
		mv_up_y = MV[1][y - 1][x];
	}

	if ( ref_up_left == -1 )
	{
	    mv_up_left_x = 0;
		mv_up_left_y = 0;
	}
	else
	{
	    mv_up_left_x = MV[0][y - 1][x - 1];
		mv_up_left_y = MV[1][y - 1][x - 1];
	}

	//右上角的块不可用时，以左上角的块代替？
	if ( up_right_avail == false )
	{
		ref_up_right = ref_up_left;
		mv_up_right_x = mv_up_left_x;
		mv_up_right_y = mv_up_left_y;
	}
	else
	{
		mv_up_right_x = (ref_up_right == -1) ? 0 : MV[0][y - 1][x + MbPartWidth];
		mv_up_right_y = (ref_up_right == -1) ? 0 : MV[1][y - 1][x + MbPartWidth];
	}

	// 三个参考块和当前块的参考帧可能不同
	if ( ref_left == ref_idx && ref_up != ref_idx && ref_up_right != ref_idx )
	{
        mvp[0] = mv_left_x;
		mvp[1] = mv_left_y;
		return;
	}
	else if ( ref_left != ref_idx && ref_up == ref_idx && ref_up_right != ref_idx )
	{
		mvp[0] = mv_up_x;
		mvp[1] = mv_up_y;
		return;
	}
	else if ( ref_left != ref_idx && ref_up != ref_idx && ref_up_right == ref_idx )
	{
		mvp[0] = mv_up_right_x;
		mvp[1] = mv_up_right_y;
		return;
	}

	// 对于16x8块，上面部分mvp由up块预测，下面部分mvp由left块预测
	// 对于8x16块，左面部分mvp由left块预测，右边部分mvp由up_right块预测
	if ( MbPartWidth == 4 && MbPartHeight == 2 ) // 16x8 
	{
        if ( (y & 0x2) == 0 && ref_up == ref_idx ) //上面 &的优先级比==低
		{
			mvp[0] = mv_up_x;
			mvp[1] = mv_up_y;
			return;
		}
		if ( (y & 0x2) == 0x2 && ref_left == ref_idx ) //下面
		{
            mvp[0] = mv_left_x;
			mvp[1] = mv_left_y;
			return;
		}
	}
	else if ( MbPartWidth == 2 && MbPartHeight == 4 ) // 8x16
	{
		if ( (x & 0x2) == 0 && ref_left == ref_idx ) //左边
		{
			mvp[0] = mv_left_x;
			mvp[1] = mv_left_y;
			return;
		}
		if ( (x & 0x2) == 0x2 && ref_up_right == ref_idx )//右边
		{
            mvp[0] = mv_up_right_x;
			mvp[1] = mv_up_right_y;
			return;
		}
	}

	if ( up_avail == false && up_right_avail == false )
	{
		mvp[0] = mv_left_x;
		mvp[1] = mv_left_y;
	}
	else
	{
		mvp[0] = Median(mv_left_x, mv_up_x, mv_up_right_x);
		mvp[1] = Median(mv_left_y, mv_up_y, mv_up_right_y);
	}
}


bool test_block_available(unsigned short x, unsigned short y, int part_width, int part_height, int dir)
{
	static unsigned short index[16] = {0,1,4,5,2,3,6,7,8,9,12,13,10,11,14,15};
	unsigned short mb_index;
	unsigned short block_index;
	unsigned short dst_mb_index;
	unsigned short dst_block_index;
	unsigned short dst_x;
	unsigned short dst_y;
	if (dir == 0){	//up left
		dst_x = x - 1;
		dst_y = y - 1;
	}
	else if (dir == 1){	//up
		dst_x = x;
		dst_y = y - 1;
	}
	else if (dir == 2){	//up right
		dst_x = x + part_width;
		dst_y = y - 1;
	}
	else if (dir == 3){	//left
		dst_x = x - 1;
		dst_y = y;
	}
	mb_index = ( y / 4 ) * WIDTH + x / 4;
	block_index = index[(y & 0x3) << 2 | (x & 0x3)];

	dst_mb_index = ( dst_y/ 4 ) * WIDTH + dst_x / 4;
	dst_block_index = index[(dst_y & 0x3) << 2 | (dst_x & 0x3)];
	
	if ( dst_x < 0 || dst_y < 0 || dst_x >= WIDTH * 4 || dst_y >= HEIGHT * 4 )
	{
	    return false;
	}

    //0  1  4   5 
    //2  3  6   7
    //8  9  12  13
    //10 11  14  15
	if ( dst_mb_index > mb_index )
	{
		return false;
	}

	if ( dst_mb_index == mb_index && dst_block_index > block_index )
	{
		return false;
	}
	if ( dst_mb_index < first_mb_index_in_slice){
		return false;
	}
	
	return true;

}

void Read_Sub_MB_Pred( unsigned char rbsp[],
					  unsigned int& bytes_offset,
					  unsigned short& bits_offset,
					  unsigned short mb_index,
					  const SliceHeader_t& slice_header,
					  const SPS_t& sps,
					  const PPS_t& pps,
					  PredMode pred_mode
					  )
{
	unsigned short y0 = mb_index / WIDTH;
	unsigned short x0 = mb_index % WIDTH;
	unsigned short x, y;

	unsigned short i, j, k;
	unsigned short len;
	unsigned short MbPartIdx;
	short mvp[2];
	short ref;
	unsigned short sub_mb_type[4];
	unsigned short num_sub_mb[4];
	PredMode sub_mb_pred = PRED_L0;
	unsigned short par_num;

	cur_mb.par_num = 0;
	par_num = 0;

	//子块为四个8x8,4x4,4x8,8x4块
	for ( MbPartIdx = 0; MbPartIdx < 4; MbPartIdx++ )
	{
        sub_mb_type[MbPartIdx] = read_ue_v(rbsp, bytes_offset, bits_offset, len);
		GotoNextNBits(len);
		if ( sub_mb_type[MbPartIdx] == 0 )
		{
			num_sub_mb[MbPartIdx] = 1;
		}
		else if ( sub_mb_type[MbPartIdx] == 1 || sub_mb_type[MbPartIdx] == 2 )
		{
			num_sub_mb[MbPartIdx] = 2;
		}
		else if ( sub_mb_type[MbPartIdx] == 3 )
		{
			num_sub_mb[MbPartIdx] = 4;
		}
	}

	//每8x8块参考同一帧
    for ( MbPartIdx = 0; MbPartIdx < 4; MbPartIdx++ )
	{
		if (slice_header.num_ref_idx_active_override_flag && slice_header.num_ref_idx_l0_active_minus1 > 0 && pred_mode != P_REF0
			&& ( sub_mb_pred == PRED_L0 || sub_mb_pred == BI_PRED )) // 不是用pps.num_ref_idx_10_active_minus1
		{
			ref = read_te_v(rbsp, bytes_offset, bits_offset, len, slice_header.num_ref_idx_l0_active_minus1+1); 
			GotoNextNBits(len);
		}
		else if(slice_header.num_ref_idx_active_override_flag == 0 && pps.num_ref_idx_l0_active_minus1 > 0 && pred_mode != P_REF0
			&& ( sub_mb_pred == PRED_L0 || sub_mb_pred == BI_PRED )) {
			ref = read_te_v(rbsp, bytes_offset, bits_offset, len, pps.num_ref_idx_l0_active_minus1+1); 
			GotoNextNBits(len);
		}
		else
		{
			ref = 0; 
		}

		if ( MbPartIdx == 0 )
		{
            RefIdx[y0 * 2][x0 * 2] = ref;
		}
		else if ( MbPartIdx == 1 )
		{
            RefIdx[y0 * 2][x0 * 2 + 1] = ref;
		}
		else if ( MbPartIdx == 2 )
		{
            RefIdx[y0 * 2 + 1][x0 * 2] = ref;
		}
		else if ( MbPartIdx == 3 )
		{
            RefIdx[y0 * 2 + 1][x0 * 2 + 1] = ref;
		}

		for ( k = 0; k < num_sub_mb[MbPartIdx]; k++, par_num++ )
		{
			cur_mb.mv_par[par_num].refidx = ref;
		}
	}    

	cur_mb.par_num = par_num;
	par_num = 0;

	for ( MbPartIdx = 0; MbPartIdx < 4; MbPartIdx++ )
	{
		if ( sub_mb_pred == PRED_L0 || sub_mb_pred == BI_PRED )
		{       
            if ( MbPartIdx == 0 )
			{
                x = x0 * 4;
				y = y0 * 4;
			}
			else if ( MbPartIdx == 1 )
			{
                x = x0 * 4 + 2;
				y = y0 * 4;
			}
			else if ( MbPartIdx == 2 )
			{
                x = x0 * 4;
				y = y0 * 4 + 2;
			}
			else if ( MbPartIdx == 3 )
			{
                x = x0 * 4 + 2;
				y = y0 * 4 + 2;
			}

			switch( sub_mb_type[MbPartIdx] )
			{
			case 0: // P_L0_8x8
                get_mvp(x, y, 2, 2, mb_index, RefIdx[y / 2][x / 2], mvp);
				mvp[0] += read_se_v(rbsp, bytes_offset, bits_offset, len);
				GotoNextNBits(len);
				mvp[1] += read_se_v(rbsp, bytes_offset, bits_offset, len);
				GotoNextNBits(len);
//		if (mvp[0]>=64 || mvp[1]>=64)
//			printf("mvp[0]=%d,mvp[1]=%d\n",mvp[0],mvp[1]);
                cur_mb.mv_par[par_num].height = 8;
				cur_mb.mv_par[par_num].width = 8;
				cur_mb.mv_par[par_num].mv_x = mvp[0];
				cur_mb.mv_par[par_num].mv_y = mvp[1];
				cur_mb.mv_par[par_num].pos_x = x * 4;
				cur_mb.mv_par[par_num].pos_y = y * 4;

				par_num++;

				for ( i = 0; i < 2; i++ )
				{
					for ( j = 0; j < 2; j++ )
					{
						MV[0][y + j][x + i] = mvp[0];
						MV[1][y + j][x + i] = mvp[1];
					}
				}
				break;
			case 1: // P_L0_8x4
				get_mvp(x, y, 2, 1, mb_index, RefIdx[y / 2][x / 2], mvp);
				mvp[0] += read_se_v(rbsp, bytes_offset, bits_offset, len);
				GotoNextNBits(len);
				mvp[1] += read_se_v(rbsp, bytes_offset, bits_offset, len);
				GotoNextNBits(len);
//		if (mvp[0]>=64 || mvp[1]>=64)
//			printf("mvp[0]=%d,mvp[1]=%d\n",mvp[0],mvp[1]);
				cur_mb.mv_par[par_num].width = 8;
				cur_mb.mv_par[par_num].height = 4;
				cur_mb.mv_par[par_num].mv_x = mvp[0];
				cur_mb.mv_par[par_num].mv_y = mvp[1];
				cur_mb.mv_par[par_num].pos_x = x * 4;
				cur_mb.mv_par[par_num].pos_y = y * 4;
				par_num++;

				for ( i = 0; i < 2; i++ )
				{
					MV[0][y][x + i] = mvp[0];
					MV[1][y][x + i] = mvp[1];
				}

				get_mvp(x, y + 1, 2, 1, mb_index, RefIdx[y / 2][x / 2], mvp);
				mvp[0] += read_se_v(rbsp, bytes_offset, bits_offset, len);
				GotoNextNBits(len);
				mvp[1] += read_se_v(rbsp, bytes_offset, bits_offset, len);
				GotoNextNBits(len);
//		if (mvp[0]>=64 || mvp[1]>=64)
//			printf("mvp[0]=%d,mvp[1]=%d\n",mvp[0],mvp[1]);
				cur_mb.mv_par[par_num].width = 8;
				cur_mb.mv_par[par_num].height = 4;
				cur_mb.mv_par[par_num].mv_x = mvp[0];
				cur_mb.mv_par[par_num].mv_y = mvp[1];
				cur_mb.mv_par[par_num].pos_x = x * 4;
				cur_mb.mv_par[par_num].pos_y = y * 4 + 4;

				par_num++;

				for ( i = 0; i < 2; i++ )
				{
					MV[0][y + 1][x + i] = mvp[0];
					MV[1][y + 1][x + i] = mvp[1];
				}

				break;
			case 2:// P_L0_4x8
				get_mvp(x, y, 1, 2, mb_index, RefIdx[y / 2][x / 2], mvp);
				mvp[0] += read_se_v(rbsp, bytes_offset, bits_offset, len);
				GotoNextNBits(len);
				mvp[1] += read_se_v(rbsp, bytes_offset, bits_offset, len);
				GotoNextNBits(len);
//		if (mvp[0]>=64 || mvp[1]>=64)
//			printf("mvp[0]=%d,mvp[1]=%d\n",mvp[0],mvp[1]);
				cur_mb.mv_par[par_num].width = 4;
				cur_mb.mv_par[par_num].height = 8;
				cur_mb.mv_par[par_num].mv_x = mvp[0];
				cur_mb.mv_par[par_num].mv_y = mvp[1];
				cur_mb.mv_par[par_num].pos_x = x * 4;
				cur_mb.mv_par[par_num].pos_y = y * 4;

				par_num++;

				for ( j = 0; j < 2; j++ )
				{
					MV[0][y + j][x] = mvp[0];
					MV[1][y + j][x] = mvp[1];
				}

				get_mvp(x + 1, y, 1, 2, mb_index, RefIdx[y / 2][x / 2], mvp);
				mvp[0] += read_se_v(rbsp, bytes_offset, bits_offset, len);
				GotoNextNBits(len);
				mvp[1] += read_se_v(rbsp, bytes_offset, bits_offset, len);
				GotoNextNBits(len);
//		if (mvp[0]>=64 || mvp[1]>=64)
//			printf("mvp[0]=%d,mvp[1]=%d\n",mvp[0],mvp[1]);
				cur_mb.mv_par[par_num].width = 4;
				cur_mb.mv_par[par_num].height = 8;
				cur_mb.mv_par[par_num].mv_x = mvp[0];
				cur_mb.mv_par[par_num].mv_y = mvp[1];
				cur_mb.mv_par[par_num].pos_x = x * 4 + 4;
				cur_mb.mv_par[par_num].pos_y = y * 4;

				par_num++;

				for ( j = 0; j < 2; j++ )
				{
					MV[0][y + j][x + 1] = mvp[0];
					MV[1][y + j][x + 1] = mvp[1];
				}

				break;
			case 3: // P_L0_4x4
				get_mvp(x, y, 1, 1, mb_index, RefIdx[y / 2][x / 2], mvp);
				MV[0][y][x] = mvp[0] + read_se_v(rbsp, bytes_offset, bits_offset, len);
				GotoNextNBits(len);
				MV[1][y][x] = mvp[1] + read_se_v(rbsp, bytes_offset, bits_offset, len);
				GotoNextNBits(len);

				cur_mb.mv_par[par_num].width = 4;
				cur_mb.mv_par[par_num].height = 4;
				cur_mb.mv_par[par_num].mv_x = MV[0][y][x];
				cur_mb.mv_par[par_num].mv_y = MV[1][y][x];
				cur_mb.mv_par[par_num].pos_x = x * 4;
				cur_mb.mv_par[par_num].pos_y = y * 4;

				par_num++;

				get_mvp(x + 1, y, 1, 1, mb_index, RefIdx[y / 2][x / 2], mvp);
				MV[0][y][x + 1] = mvp[0] + read_se_v(rbsp, bytes_offset, bits_offset, len);
				GotoNextNBits(len);
				MV[1][y][x + 1] = mvp[1] + read_se_v(rbsp, bytes_offset, bits_offset, len);
				GotoNextNBits(len);
//		if (mvp[0]>=64 || mvp[1]>=64)
//			printf("mvp[0]=%d,mvp[1]=%d\n",mvp[0],mvp[1]);
				cur_mb.mv_par[par_num].width = 4;
				cur_mb.mv_par[par_num].height = 4;
				cur_mb.mv_par[par_num].mv_x = MV[0][y][x + 1];
				cur_mb.mv_par[par_num].mv_y = MV[1][y][x + 1];
				cur_mb.mv_par[par_num].pos_x = x * 4 + 4;
				cur_mb.mv_par[par_num].pos_y = y * 4;

				par_num++;

				get_mvp(x, y + 1, 1, 1, mb_index, RefIdx[y / 2][x / 2], mvp);
				MV[0][y + 1][x] = mvp[0] + read_se_v(rbsp, bytes_offset, bits_offset, len);
				GotoNextNBits(len);
				MV[1][y + 1][x] = mvp[1] + read_se_v(rbsp, bytes_offset, bits_offset, len);
				GotoNextNBits(len);
//		if (mvp[0]>=64 || mvp[1]>=64)
//			printf("mvp[0]=%d,mvp[1]=%d\n",mvp[0],mvp[1]);
				cur_mb.mv_par[par_num].width = 4;
				cur_mb.mv_par[par_num].height = 4;
				cur_mb.mv_par[par_num].mv_x = MV[0][y + 1][x];
				cur_mb.mv_par[par_num].mv_y = MV[1][y + 1][x];
				cur_mb.mv_par[par_num].pos_x = x * 4;
				cur_mb.mv_par[par_num].pos_y = y * 4 + 4;

				par_num++;

				get_mvp(x + 1, y + 1, 1, 1, mb_index, RefIdx[y / 2][x / 2], mvp);
				MV[0][y + 1][x + 1] = mvp[0] + read_se_v(rbsp, bytes_offset, bits_offset, len);
				GotoNextNBits(len);
				MV[1][y + 1][x + 1] = mvp[1] + read_se_v(rbsp, bytes_offset, bits_offset, len);
				GotoNextNBits(len);
//		if (mvp[0]>=64 || mvp[1]>=64)
//			printf("mvp[0]=%d,mvp[1]=%d\n",mvp[0],mvp[1]);
				cur_mb.mv_par[par_num].width = 4;
				cur_mb.mv_par[par_num].height = 4;
				cur_mb.mv_par[par_num].mv_x = MV[0][y + 1][x + 1];
				cur_mb.mv_par[par_num].mv_y = MV[1][y + 1][x + 1];
				cur_mb.mv_par[par_num].pos_x = x * 4 + 4;
				cur_mb.mv_par[par_num].pos_y = y * 4 + 4;

				par_num++;

				break;
			default:
				assert(0);

			} // END OF SWITCH

		} // END OF IF
	} // END OF FOR
		


}
