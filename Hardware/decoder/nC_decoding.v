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

module nC_decoding
(
 mb_x_in,
 mb_y_in,
 is_in_same_slice,
 luma4x4BlkIdx_in,
 chroma4x4BlkIdx_in,
 nC_up_mb_in,
 nC_left_mb_in,
 nC_curr_mb_in,
 nC_cb_up_mb_in,
 nC_cb_left_mb_in,
 nC_cb_curr_mb_in,
 nC_cr_up_mb_in,
 nC_cr_left_mb_in,
 nC_cr_curr_mb_in, 
 nC_out,
 nC_cb_out,
 nC_cr_out
);

input[`mb_x_bits - 1:0] mb_x_in;
input[`mb_y_bits - 1:0] mb_y_in;
input[3:0] is_in_same_slice;
input[3:0] luma4x4BlkIdx_in;
input[1:0] chroma4x4BlkIdx_in;
input[31:0] nC_up_mb_in;
input[31:0] nC_left_mb_in;
input[127:0] nC_curr_mb_in;
input[15:0] nC_cb_up_mb_in;
input[15:0] nC_cb_left_mb_in;
input[31:0] nC_cb_curr_mb_in;
input[15:0] nC_cr_up_mb_in;
input[15:0] nC_cr_left_mb_in;
input[31:0] nC_cr_curr_mb_in; 


output[4:0] nC_out;
output[4:0] nC_cb_out;
output[4:0] nC_cr_out;

reg[7:0] nA;
reg[7:0] nB;
reg[7:0] nA_cb;
reg[7:0] nB_cb;
reg[7:0] nA_cr;
reg[7:0] nB_cr;

reg[4:0] nC_out;
reg[4:0] nC_cb_out;
reg[4:0] nC_cr_out;

wire up_blk_avail_l;
wire left_blk_avail_l;
wire up_blk_avail_c;
wire left_blk_avail_c;

reg is_in_mb_left_l;
reg is_in_mb_top_l;
reg is_in_mb_left_c;
reg is_in_mb_top_c;

always @(*)
if({luma4x4BlkIdx_in[2], luma4x4BlkIdx_in[0]} == 0)
	is_in_mb_left_l <= 1;
else
    is_in_mb_left_l <= 0;
     
always @(*)
if({luma4x4BlkIdx_in[3], luma4x4BlkIdx_in[1]} == 0)
	is_in_mb_top_l <= 1;
else
    is_in_mb_top_l <= 0;

always @(*)
	is_in_mb_left_c = ~chroma4x4BlkIdx_in[0];

always @(*)
	is_in_mb_top_c = ~chroma4x4BlkIdx_in[1];


always @ (luma4x4BlkIdx_in or nC_up_mb_in or nC_curr_mb_in or nC_left_mb_in)
    begin
        case(luma4x4BlkIdx_in)
            0: begin nA <= nC_left_mb_in[7:0]; nB <= nC_up_mb_in[7:0]; end
            1: begin nA <= nC_curr_mb_in[7:0]; nB <= nC_up_mb_in[15:8]; end
            2: begin nA <= nC_left_mb_in[15:8]; nB <= nC_curr_mb_in[7:0]; end
            3: begin nA <= nC_curr_mb_in[23:16]; nB <= nC_curr_mb_in[15:8]; end
            4: begin nA <= nC_curr_mb_in[15:8]; nB <= nC_up_mb_in[23:16]; end
            5: begin nA <= nC_curr_mb_in[39:32]; nB <= nC_up_mb_in[31:24]; end
            6: begin nA <= nC_curr_mb_in[31:24]; nB <= nC_curr_mb_in[39:32]; end
            7: begin nA <= nC_curr_mb_in[55:48]; nB <= nC_curr_mb_in[47:40]; end
            8: begin nA <= nC_left_mb_in[23:16]; nB <= nC_curr_mb_in[23:16]; end
            9: begin nA <= nC_curr_mb_in[71:64]; nB <= nC_curr_mb_in[31:24]; end
            10: begin nA <= nC_left_mb_in[31:24]; nB <= nC_curr_mb_in[71:64]; end
            11: begin nA <= nC_curr_mb_in[87:80]; nB <= nC_curr_mb_in[79:72]; end
            12: begin nA <= nC_curr_mb_in[79:72]; nB <= nC_curr_mb_in[55:48]; end
            13: begin nA <= nC_curr_mb_in[103:96]; nB <= nC_curr_mb_in[63:56]; end
            14: begin nA <= nC_curr_mb_in[95:88]; nB <= nC_curr_mb_in[103:96]; end
            15: begin nA <= nC_curr_mb_in[119:112]; nB <= nC_curr_mb_in[111:104]; end
        endcase
    end

always @(chroma4x4BlkIdx_in or nC_cb_left_mb_in or nC_cb_up_mb_in or nC_cb_curr_mb_in)
    case(chroma4x4BlkIdx_in) // spec 9.2.1
        0: 
            begin 
                nA_cb <= nC_cb_left_mb_in[7:0]; 
                nB_cb <= nC_cb_up_mb_in[7:0];
            end
        1:
            begin
                nA_cb <= nC_cb_curr_mb_in[7:0]; 
                nB_cb <= nC_cb_up_mb_in[15:8];
            end
        2:
            begin
                nA_cb <= nC_cb_left_mb_in[15:8]; 
                nB_cb <= nC_cb_curr_mb_in[7:0];
            end        
        3:
            begin
                nA_cb <= nC_cb_curr_mb_in[23:16]; 
                nB_cb <= nC_cb_curr_mb_in[15:8];
            end      
    endcase

always @(chroma4x4BlkIdx_in or nC_cr_left_mb_in or nC_cr_up_mb_in or nC_cr_curr_mb_in)
    case(chroma4x4BlkIdx_in)
        0: 
            begin 
                nA_cr <= nC_cr_left_mb_in[7:0];
                nB_cr <= nC_cr_up_mb_in[7:0];
            end
        1:
            begin
                nA_cr <= nC_cr_curr_mb_in[7:0];
                nB_cr <= nC_cr_up_mb_in[15:8];
            end
        2:
            begin
                nA_cr <= nC_cr_left_mb_in[15:8];
                nB_cr <= nC_cr_curr_mb_in[7:0];
            end        
        3:
            begin
                nA_cr <= nC_cr_curr_mb_in[23:16];
                nB_cr <= nC_cr_curr_mb_in[15:8];
            end      
    endcase





assign up_blk_avail_l = is_in_same_slice[1] || !is_in_mb_top_l;
assign left_blk_avail_l = is_in_same_slice[3] || !is_in_mb_left_l;
assign up_blk_avail_c = is_in_same_slice[1] || !is_in_mb_top_c;
assign left_blk_avail_c = is_in_same_slice[3] || !is_in_mb_left_c;


always @(*)
    begin
        if (mb_x_in == 0 && is_in_mb_left_l == 1 && mb_y_in == 0 && is_in_mb_top_l == 1)
            begin
                nC_out <= 0;
			end
        else if (mb_x_in == 0 && is_in_mb_left_l == 1)
            begin
				if (up_blk_avail_l)
                	nC_out <= nB;
				else
					nC_out <= 0;
            end
        else if (mb_y_in == 0 && is_in_mb_top_l == 1)
            begin
				if (left_blk_avail_l)
					nC_out <= nA;
				else
                	nC_out <= 0;
            end
        else
            begin
				if (left_blk_avail_l && up_blk_avail_l) 
                	nC_out <= (nA + nB + 1) >> 1;
				else if (left_blk_avail_l)
					nC_out <= nA;
				else if (up_blk_avail_l)
					nC_out <= nB;
				else
					nC_out <= 0;
					
			end
    end

always @(*)
    begin
        if (mb_x_in == 0 && is_in_mb_left_c == 1 && mb_y_in == 0 && is_in_mb_top_c == 1)
            begin
                nC_cb_out <= 0;
            end
        else if (mb_x_in == 0 && is_in_mb_left_c == 1)
            begin
 				if (up_blk_avail_c)
                	nC_cb_out <= nB_cb;
				else
					nC_cb_out <= 0;
            end
        else if (mb_y_in == 0 && is_in_mb_top_c == 1)
            begin
              	if (left_blk_avail_c)
                	nC_cb_out <= nA_cb;
				else
					nC_cb_out <= 0;
			end
        else
            begin
				if (left_blk_avail_c && up_blk_avail_c) 
                	nC_cb_out <= (nA_cb + nB_cb + 1) >> 1;
				else if (left_blk_avail_c)
					nC_cb_out <= nA_cb;
				else if (up_blk_avail_c)
					nC_cb_out <= nB_cb;
				else
					nC_cb_out <= 0;
            end
		end

always @(*)
    begin
        if (mb_x_in == 0 && is_in_mb_left_c == 1 && mb_y_in == 0 && is_in_mb_top_c == 1)
            begin
                nC_cr_out <= 0;
            end
        else if (mb_x_in == 0 && is_in_mb_left_c == 1)
            begin
 				if (up_blk_avail_c)
                	nC_cr_out <= nB_cr;
				else
					nC_cr_out <= 0;
            end
        else if (mb_y_in == 0 && is_in_mb_top_c == 1)
            begin
              	if (left_blk_avail_c)
                	nC_cr_out <= nA_cr;
				else
					nC_cr_out <= 0;
			end
        else
            begin
				if (left_blk_avail_c && up_blk_avail_c) 
                	nC_cr_out <= (nA_cr + nB_cr + 1) >> 1;
				else if (left_blk_avail_c)
					nC_cr_out <= nA_cr;
				else if (up_blk_avail_c)
					nC_cr_out <= nB_cr;
				else
					nC_cr_out <= 0;
            end
		end
endmodule
