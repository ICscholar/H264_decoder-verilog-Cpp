#ifndef __intrapred_h__
#define __intrapred_h__

#include "parset.h"

void IntraPred16(unsigned short mb_index, unsigned short I16_pred_mode, const PPS_t& pps);

void IntraPred4(unsigned short mb_index, unsigned short block_idx, const PPS_t& pps);

void IntraPredChroma(unsigned short mb_index, unsigned short chroma_pred_mode, const PPS_t& pps);

void pred_avail_check(unsigned short mb_index, const PPS_t& pps);
#endif