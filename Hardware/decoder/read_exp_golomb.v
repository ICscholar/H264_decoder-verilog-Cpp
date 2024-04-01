//--------------------------------------------------------------------------------------------------
// Copyright (C) 2013-2017 qiu bin 
// All rights reserved   
// Design    : bitstream_p
// Author(s) : qiu bin
// Email     : chat1@126.com
// Phone 15957074161
// QQ:1517642772             
//-------------------------------------------------------------------------------------------------

`include "defines.v"

module read_exp_golomb
(
 data_in,
 num_zero_bits,
 max_minus1_in,
 read_te_sel,
 intra4x4_in,
 
 ue_out, 
 se_out,
 te_out,
 
 CBP_luma_out, 
 CBP_chroma_out,
 
 length_out
);

input [30:0] data_in;
input [3:0] num_zero_bits;
input [2:0] max_minus1_in;
input   read_te_sel;
input   intra4x4_in;

output  [15:0] ue_out;
output  [15:0] se_out;
output  [9:0] te_out;       //mb_skip_run > 255 appears
output  [1:0] CBP_chroma_out;
output  [3:0] CBP_luma_out;
output  [4:0] length_out;

reg [15:0] ue_out;
reg [15:0] se_out;
reg [9:0] te_out;
reg [4:0] length_out;
reg[1:0] CBP_chroma_out;
reg[3:0] CBP_luma_out;

always @(*)
	if (read_te_sel && (max_minus1_in == 0))
		length_out  <= 0;
	else if (read_te_sel && max_minus1_in == 1)
		length_out <= 1;
    else
        length_out <= (num_zero_bits << 1) + 1'b1;

//------------------------
// read_ue
//------------------------
always @( num_zero_bits or data_in)
        case ( num_zero_bits )
        0 : ue_out <= 0;
        1 : ue_out <= data_in[29:28] - 1;
        2 : ue_out <= data_in[28:26] - 1;
        3 : ue_out <= data_in[27:24] - 1;
        4 : ue_out <= data_in[26:22] - 1;
        5 : ue_out <= data_in[25:20] - 1;
        6 : ue_out <= data_in[24:18] - 1;
        7 : ue_out <= data_in[23:16] - 1;
        8 : ue_out <= data_in[22:14] - 1;
        9 : ue_out <= data_in[21:12] - 1;
        10: ue_out <= data_in[20:10] - 1;
		11: ue_out <= data_in[19:8]  - 1;
        12: ue_out <= data_in[18:6]  - 1;
        13: ue_out <= data_in[17:4]  - 1;
        14: ue_out <= data_in[16:2]  - 1;
        default : ue_out <= data_in[15:0] - 1;
        endcase
 
//~(1-1)/2+1 = 0
//~(2-1)/2+1 = 0
//~(3-1)/2+1 = -1
//~(4-1)/2+1 = -1
//~(5-1)/2+1 = -2
//~(6-1)/2+1 = -2
//~(9-1)/2+1 = -4
//------------------------
// read_se
//------------------------
//reg [15:0] se_out;
always @(*)
        case ( num_zero_bits )
        0 : se_out <= 0;
        1 : se_out <= data_in[28] ? -(data_in[29:28]-1)/2 : data_in[29:29] ;
        2 : se_out <= data_in[26] ? -(data_in[28:26]-1)/2 : data_in[28:27];
        3 : se_out <= data_in[24] ? -(data_in[27:24]-1)/2 : data_in[27:25];
        4 : se_out <= data_in[22] ? -(data_in[26:22]-1)/2 : data_in[26:23];
        5 : se_out <= data_in[20] ? -(data_in[25:20]-1)/2 : data_in[25:21];
        6 : se_out <= data_in[18] ? -(data_in[24:18]-1)/2 : data_in[24:19];
        7 : se_out <= data_in[16] ? -(data_in[23:16]-1)/2 : data_in[23:17];
        8 : se_out <= data_in[14] ? -(data_in[22:14]-1)/2 : data_in[22:15];
        9 : se_out <= data_in[12] ? -(data_in[21:12]-1)/2 : data_in[21:13];
        10: se_out <= data_in[10] ? -(data_in[20:10]-1)/2 : data_in[20:11];
		11: se_out <= data_in[8] ? -(data_in[19:8]-1)/2 : data_in[19:9];
        12: se_out <= data_in[6] ? -(data_in[18:6]-1)/2 : data_in[18:7];
        13: se_out <= data_in[4] ? -(data_in[17:4]-1)/2 : data_in[17:5];
        14: se_out <= data_in[2] ? -(data_in[16:2]-1)/2 : data_in[16:3];
        default : se_out <= data_in[0] ? -(data_in[15:0]-1)/2 : data_in[15:1];
        endcase

//------------------------
// read_se
//------------------------
/*
always @(ue_out)
    case (ue_out[0])
    1:se_out <= (ue_out + 1) >> 1;
    0:se_out <= ~ue_out[15:1] + 1;
    endcase
*/

//------------------------
// read_te
//------------------------
always @(ue_out or max_minus1_in or data_in)
    if(max_minus1_in == 0)
        te_out <= 0;
    else if (max_minus1_in == 1)
        te_out <= data_in[30] == 1? 8'b0:8'b1;
	else
		te_out <= ue_out;
    
//------------------------
// read_me
//------------------------
always @(ue_out or intra4x4_in)
    if (intra4x4_in)
        case(ue_out[5:0])
            2, 3, 8, 9,10,11,17,18,19,20,29,30,31,32,37,38 : CBP_chroma_out <= 0;
            1, 4, 5, 6, 7,16,21,22,23,24,33,34,35,36,39,40 : CBP_chroma_out <= 1;
            0,12,13,14,15,25,26,27,28,41,42,43,44,45,46,47 : CBP_chroma_out <= 2;
            default: CBP_chroma_out <= 0;
        endcase
    else
        case(ue_out[5:0])
            0, 2, 3, 4, 5, 7, 8, 9,10,11,13,14,15,16,17,18 : CBP_chroma_out <= 0;
            1,19,32,33,34,35,36,37,38,39,40,41,42,43,44,45 : CBP_chroma_out <= 1;   
            6,12,20,21,22,23,24,25,26,27,28,29,30,31,46,47 : CBP_chroma_out <= 2; 
            default: CBP_chroma_out <= 0;
        endcase

always @(ue_out or intra4x4_in)
    if (intra4x4_in)
        case(ue_out[5:0])
            3,16,41:  CBP_luma_out <= 0;
            29,33,42: CBP_luma_out <= 1;
            30,34,43: CBP_luma_out <= 2;
            17,21,25: CBP_luma_out <= 3;
            31,35,44: CBP_luma_out <= 4;
            18,22,26: CBP_luma_out <= 5;
            37,39,46: CBP_luma_out <= 6;
            4,8,12:   CBP_luma_out <= 7;
            32,36,45: CBP_luma_out <= 8;
            38,40,47: CBP_luma_out <= 9;
            19,23,27: CBP_luma_out <= 10;
            5,9,13:   CBP_luma_out <= 11;
            20,24,28: CBP_luma_out <= 12;
            6,10,14:  CBP_luma_out <= 13;
            7,11,15:  CBP_luma_out <= 14;
            0,1,2:    CBP_luma_out <= 15;
            default: CBP_luma_out <= 0;
        endcase
    else
        case(ue_out[5:0])
            0,1,6:    CBP_luma_out <= 0;
            2,24,32:  CBP_luma_out <= 1;
            3,25,33:  CBP_luma_out <= 2;
            7,20,36:  CBP_luma_out <= 3;
            4,26,34:  CBP_luma_out <= 4;
            8,21,37:  CBP_luma_out <= 5;
            17,44,46: CBP_luma_out <= 6;
            13,28,40: CBP_luma_out <= 7;
            5,27,35:  CBP_luma_out <= 8;
            18,45,47: CBP_luma_out <= 9;
            9,22,38:  CBP_luma_out <= 10;
            14,29,41: CBP_luma_out <= 11;
            10,23,39: CBP_luma_out <= 12;
            15,30,42: CBP_luma_out <= 13;
            16,31,43: CBP_luma_out <= 14;
            11,12,19: CBP_luma_out <= 15;
            default: CBP_luma_out <= 0;
        endcase
        
endmodule
