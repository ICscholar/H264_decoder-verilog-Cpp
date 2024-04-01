//--------------------------------------------------------------------------------------------------
// Copyright (C) 2013-2017 qiu bin 
// All rights reserved   
// Design    : bitstream_p
// Author(s) : qiu bin
// Email     : chat1@126.com
// Phone 15957074161
// QQ:1517642772             
//-------------------------------------------------------------------------------------------------

#ifndef __transform_h__
#define __transform_h__

void inverse_zigzag(short p[]);

// block type 1 : Intra16x16LumaDC
//            2 : Intra16x16LumaAC
//            3 : Luma4x4
//            5 : ChromaDC
//            6 : ChromaAC
void inverse_quant(unsigned short QP, unsigned short block_type, short p[], int p_int[]);

void DHT2(short p[]);

void DHT(short p[]);

void IDCT(short p[], int type);

#endif
