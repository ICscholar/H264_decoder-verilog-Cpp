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

module get_mvp
(
 clk,
 rst_n,
 mv_calc_ready,
 mv_calc_valid,
 mb_index_in,
 luma4x4BlkIdx_in,
 mb_x,
 mb_y,
 first_mb_index_in_slice,
 MbPartWidth_in,
 MbPartHeight_in,
 ref_idx_l0_in,
 pic_width_in_mbs,
 ref_idx_l0_left_mb_in,
 ref_idx_l0_curr_mb_in,
 ref_idx_l0_up_left_mb_in,
 ref_idx_l0_up_mb_in,
 ref_idx_l0_up_right_mb_in,
 mvx_l0_left_mb_in,
 mvx_l0_curr_mb_in,
 mvx_l0_up_left_mb_in,
 mvx_l0_up_mb_in,
 mvx_l0_up_right_mb_in,
 mvy_l0_left_mb_in,
 mvy_l0_curr_mb_in,
 mvy_l0_up_left_mb_in,
 mvy_l0_up_mb_in,
 mvy_l0_up_right_mb_in,
 mvpx_l0_out,
 mvpy_l0_out
);

input clk;
input rst_n;
input mv_calc_ready;
output reg mv_calc_valid;
input[`mb_x_bits + `mb_y_bits - 1:0]  mb_index_in;
input[3:0]   luma4x4BlkIdx_in;
input[`mb_y_bits - 1:0]  mb_y;
input[`mb_x_bits - 1:0]  mb_x;
input [`mb_x_bits + `mb_y_bits - 1:0]  first_mb_index_in_slice;
input[4:0]   MbPartWidth_in;
input[4:0]   MbPartHeight_in;
input[2:0]   ref_idx_l0_in;
input[`mb_x_bits :0]   pic_width_in_mbs;

input[5:0] ref_idx_l0_left_mb_in;
input[11:0] ref_idx_l0_curr_mb_in;
input[5:0]  ref_idx_l0_up_left_mb_in;
input[5:0]  ref_idx_l0_up_mb_in;
input[5:0]  ref_idx_l0_up_right_mb_in;

input[63:0] mvx_l0_left_mb_in;
input[255:0] mvx_l0_curr_mb_in;
input[15:0] mvx_l0_up_left_mb_in; // only right most 4x4 blk is used
input[63:0] mvx_l0_up_mb_in;
input[15:0] mvx_l0_up_right_mb_in; // only left most 4x4 blk is used

input[63:0] mvy_l0_left_mb_in;
input[255:0] mvy_l0_curr_mb_in;
input[15:0] mvy_l0_up_left_mb_in;
input[63:0] mvy_l0_up_mb_in;
input[15:0] mvy_l0_up_right_mb_in;

output[15:0] mvpx_l0_out;
output[15:0] mvpy_l0_out;


reg[`mb_y_bits + 3:0]  pixel_y;
reg[`mb_x_bits + 3:0]  pixel_x;

reg[3:0] luma4x4BlkIdx_uprightmost;

reg signed[2:0] ref_idx_l0_up_left;
reg signed[2:0] ref_idx_l0_up;
reg signed[2:0] ref_idx_l0_left;
reg signed[2:0] ref_idx_l0_up_right_mid;
reg signed[2:0] ref_idx_l0_up_right;

reg signed[15:0] mvx_l0_up_left;
reg signed[15:0] mvx_l0_up;
reg signed[15:0] mvx_l0_up_right;
reg signed[15:0] mvx_l0_left;

reg signed[15:0] mvy_l0_up_left;
reg signed[15:0] mvy_l0_up;
reg signed[15:0] mvy_l0_up_right;
reg signed[15:0] mvy_l0_left;

reg signed[15:0] mvpx_l0_out;
reg signed[15:0] mvpy_l0_out;

reg[2:0] ref_idx_l0; // ref_idx_l0_in, depricated


reg [`mb_x_bits + `mb_y_bits - 1:0] avail_cur_mb_index;
reg [3:0] avail_cur_blk_index;
reg [`mb_x_bits+1:0] avial_cur_blk4x4_x;
reg [`mb_y_bits+1:0] avial_cur_blk4x4_y;

reg up_left_avail;
reg [`mb_x_bits + `mb_y_bits - 1:0] up_left_avail_dst_mb_index;
reg [3:0] up_left_avail_dst_blk_index;
reg signed [`mb_x_bits+2:0] up_left_blk4x4_x;
reg signed [`mb_y_bits+2:0] up_left_blk4x4_y;

reg up_avail;
reg [`mb_x_bits + `mb_y_bits - 1:0] up_avail_dst_mb_index;
reg [3:0] up_avail_dst_blk_index;
reg signed [`mb_x_bits+2:0] up_blk4x4_x;
reg signed [`mb_y_bits+2:0] up_blk4x4_y;

reg up_right_avail;
reg [`mb_x_bits + `mb_y_bits - 1:0] up_right_avail_dst_mb_index;
reg [3:0] up_right_avail_dst_blk_index;
reg signed [`mb_x_bits+2:0] up_right_blk4x4_x;
reg signed [`mb_y_bits+2:0] up_right_blk4x4_y;

reg left_avail;
reg [`mb_x_bits + `mb_y_bits - 1:0] left_avail_dst_mb_index;
reg [3:0] left_avail_dst_blk_index;
reg signed [`mb_x_bits+2:0] left_blk4x4_x;
reg signed [`mb_y_bits+2:0] left_blk4x4_y;

reg mv_calc_ready_d;
always @(posedge clk or negedge rst_n)
if (~rst_n) begin
	mv_calc_ready_d <= 0;
	mv_calc_valid <= 0;
end
else begin
	mv_calc_ready_d <= mv_calc_ready;
	if (mv_calc_ready_d && ~mv_calc_ready)
		mv_calc_valid <= 0;
	else
		mv_calc_valid <= mv_calc_ready_d;
end

always @(*) begin
	pixel_x = {mb_x, luma4x4BlkIdx_in[2], luma4x4BlkIdx_in[0], 2'b0};
	pixel_y = {mb_y, luma4x4BlkIdx_in[3], luma4x4BlkIdx_in[1], 2'b0};
end

always @(posedge clk) begin
	avail_cur_mb_index <= mb_index_in;
	avail_cur_blk_index <= {avial_cur_blk4x4_y[1],avial_cur_blk4x4_x[1],avial_cur_blk4x4_y[0],avial_cur_blk4x4_x[0]};

	up_left_avail_dst_mb_index <= up_left_blk4x4_y[`mb_y_bits+1:2] * pic_width_in_mbs + up_left_blk4x4_x[`mb_x_bits+1:2];
	up_left_avail_dst_blk_index <= {up_left_blk4x4_y[1],up_left_blk4x4_x[1],up_left_blk4x4_y[0],up_left_blk4x4_x[0]};

	up_avail_dst_mb_index = up_blk4x4_y[`mb_y_bits+1:2] * pic_width_in_mbs + up_blk4x4_x[`mb_x_bits+1:2];
	up_avail_dst_blk_index = {up_blk4x4_y[1],up_blk4x4_x[1],up_blk4x4_y[0],up_blk4x4_x[0]};

	up_right_avail_dst_mb_index <= up_right_blk4x4_y[`mb_y_bits+1:2] * pic_width_in_mbs + up_right_blk4x4_x[`mb_x_bits+1:2];
	up_right_avail_dst_blk_index <= {up_right_blk4x4_y[1],up_right_blk4x4_x[1],up_right_blk4x4_y[0],up_right_blk4x4_x[0]};

	left_avail_dst_mb_index <= left_blk4x4_y[`mb_y_bits+1:2] * pic_width_in_mbs + left_blk4x4_x[`mb_x_bits+1:2];
	left_avail_dst_blk_index <= {left_blk4x4_y[1],left_blk4x4_x[1],left_blk4x4_y[0],left_blk4x4_x[0]};
/*
	up_left_avail = ~(up_left_blk4x4_x < 0 || up_left_blk4x4_y < 0 || 
					up_left_blk4x4_x > pic_width_in_mbs * 4 || 
					up_left_avail_dst_mb_index < first_mb_index_in_slice || up_left_avail_dst_mb_index > avail_cur_mb_index ||
					up_left_avail_dst_mb_index == avail_cur_mb_index && up_left_avail_dst_blk_index > avail_cur_blk_index);
*/	
end

always @(*) begin
	avial_cur_blk4x4_x = pixel_x[`mb_x_bits+3:2];
	avial_cur_blk4x4_y = pixel_y[`mb_y_bits+3:2];
	up_left_blk4x4_x = pixel_x[`mb_x_bits+3:2]-1;
	up_left_blk4x4_y = pixel_y[`mb_y_bits+3:2]-1;
	up_blk4x4_x = pixel_x[`mb_x_bits+3:2];
	up_blk4x4_y = pixel_y[`mb_y_bits+3:2]-1;
	up_right_blk4x4_x = pixel_x[`mb_x_bits+3:2]+(MbPartWidth_in>>2);
	up_right_blk4x4_y = pixel_y[`mb_y_bits+3:2]-1;
	left_blk4x4_x = pixel_x[`mb_x_bits+3:2]-1;
	left_blk4x4_y = pixel_y[`mb_y_bits+3:2];
	up_left_avail = ~(up_left_blk4x4_x < 0 || up_left_blk4x4_y < 0 || 
					up_left_avail_dst_mb_index < first_mb_index_in_slice);

	up_avail = ~(up_blk4x4_y < 0 || 
					up_avail_dst_mb_index < first_mb_index_in_slice);

	up_right_avail = ~(up_right_blk4x4_y < 0 || 
					up_right_blk4x4_x >= pic_width_in_mbs * 4 || 
					up_right_avail_dst_mb_index < first_mb_index_in_slice ||
					up_right_avail_dst_mb_index > avail_cur_mb_index ||
					up_right_avail_dst_mb_index == avail_cur_mb_index && up_right_avail_dst_blk_index > avail_cur_blk_index);

	left_avail = ~(left_blk4x4_x < 0 || 
				   left_avail_dst_mb_index < first_mb_index_in_slice );	
end

always @(posedge clk)
    case (luma4x4BlkIdx_in)
        0,1,2,3:     ref_idx_l0 <= ref_idx_l0_curr_mb_in[2:0];
        4,5,6,7:     ref_idx_l0 <= ref_idx_l0_curr_mb_in[5:3];
        8,9,10,11:   ref_idx_l0 <= ref_idx_l0_curr_mb_in[8:6];
        12,13,14,15: ref_idx_l0 <= ref_idx_l0_curr_mb_in[11:9];        
    endcase

always @(*)
    begin   
        if(up_avail )
            begin
                case(luma4x4BlkIdx_in)
                    0,1:                 ref_idx_l0_up = ref_idx_l0_up_mb_in[2:0];
                    4,5:                 ref_idx_l0_up = ref_idx_l0_up_mb_in[5:3];
                    2,3,6,7,10,11,14,15: ref_idx_l0_up = ref_idx_l0;
                    8,9:                 ref_idx_l0_up = ref_idx_l0_curr_mb_in[2:0];
                    12,13:               ref_idx_l0_up = ref_idx_l0_curr_mb_in[5:3];
                endcase
            end
        else
            begin
                ref_idx_l0_up = -1;                
            end
            
        if (up_left_avail)
            begin
                case(luma4x4BlkIdx_in)
                    0:         ref_idx_l0_up_left = ref_idx_l0_up_left_mb_in[5:3];
                    1,4:       ref_idx_l0_up_left = ref_idx_l0_up_mb_in[2:0];
                    5:         ref_idx_l0_up_left = ref_idx_l0_up_mb_in[5:3];
                    2,8:       ref_idx_l0_up_left = ref_idx_l0_left_mb_in[2:0];
                    10:        ref_idx_l0_up_left = ref_idx_l0_left_mb_in[5:3];
                    3,7,11,15: ref_idx_l0_up_left = ref_idx_l0;
                    6,9,12:    ref_idx_l0_up_left = ref_idx_l0_curr_mb_in[2:0];
                    13:        ref_idx_l0_up_left = ref_idx_l0_curr_mb_in[5:3];
                    14:        ref_idx_l0_up_left = ref_idx_l0_curr_mb_in[8:6];
                endcase                
            end
        else
            begin
                ref_idx_l0_up_left = -1;
            end
            
        if (left_avail )
            begin
                case(luma4x4BlkIdx_in)
                    0,2:                ref_idx_l0_left = ref_idx_l0_left_mb_in[2:0];
                    8,10:               ref_idx_l0_left = ref_idx_l0_left_mb_in[5:3];
                    1,3,9,11,5,7,13,15: ref_idx_l0_left = ref_idx_l0;
                    4,6:                ref_idx_l0_left = ref_idx_l0_curr_mb_in[2:0];
                    12,14:              ref_idx_l0_left = ref_idx_l0_curr_mb_in[8:6];
                endcase
            end
        else
            begin
                ref_idx_l0_left = -1;
            end
    end

always @(*)
	if (up_right_avail)
		ref_idx_l0_up_right <= ref_idx_l0_up_right_mid;
    else
		ref_idx_l0_up_right <= ref_idx_l0_up_left;

	//0  1  4   5 
    //2  3  6   7
    //8  9  12  13
    //10 11  14  15
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
	// 6's up right is not 5?
	// RefIdx[(y - 1) / 2][(x + MbPartWidth) / 2] 

always @(posedge clk)
    if(pixel_y > 0 && (pixel_x + MbPartWidth_in) < (pic_width_in_mbs)<<4  )
        case(luma4x4BlkIdx_uprightmost)
            0:  ref_idx_l0_up_right_mid <= ref_idx_l0_up_mb_in[2:0];
            1,4:  ref_idx_l0_up_right_mid <= ref_idx_l0_up_mb_in[5:3];
            2,8:  ref_idx_l0_up_right_mid <= ref_idx_l0_curr_mb_in[2:0];
            3,6,9,12:  ref_idx_l0_up_right_mid <= ref_idx_l0_curr_mb_in[5:3];
            5:  ref_idx_l0_up_right_mid <= ref_idx_l0_up_right_mb_in[2:0];
            10: ref_idx_l0_up_right_mid <= ref_idx_l0_curr_mb_in[8:6];
            11,14: ref_idx_l0_up_right_mid <= ref_idx_l0_curr_mb_in[11:9];
            default : ref_idx_l0_up_right_mid <= -1;
        endcase
    else
        begin
            ref_idx_l0_up_right_mid <= -1; 
        end

always @ (ref_idx_l0_up_left or mvx_l0_up_left_mb_in or mvx_l0_up_mb_in or mvx_l0_curr_mb_in 
            or mvy_l0_left_mb_in or mvy_l0_up_mb_in or mvy_l0_curr_mb_in or mvy_l0_up_left_mb_in
            or luma4x4BlkIdx_in or mvx_l0_left_mb_in)  
   if (ref_idx_l0_up_left == -1)
       begin
           mvx_l0_up_left <= 0;
           mvy_l0_up_left <= 0;
       end 
   else
       case(luma4x4BlkIdx_in)
           0:  begin mvx_l0_up_left <= mvx_l0_up_left_mb_in; mvy_l0_up_left <= mvy_l0_up_left_mb_in; end
           1:  begin mvx_l0_up_left <= mvx_l0_up_mb_in[15:0];        mvy_l0_up_left <= mvy_l0_up_mb_in[15:0];        end
           2:  begin mvx_l0_up_left <= mvx_l0_left_mb_in[15:0];      mvy_l0_up_left <= mvy_l0_left_mb_in[15:0];      end
           3:  begin mvx_l0_up_left <= mvx_l0_curr_mb_in[15:0];      mvy_l0_up_left <= mvy_l0_curr_mb_in[15:0];      end
           4:  begin mvx_l0_up_left <= mvx_l0_up_mb_in[31:16];       mvy_l0_up_left <= mvy_l0_up_mb_in[31:16];      end
           5:  begin mvx_l0_up_left <= mvx_l0_up_mb_in[47:32];      mvy_l0_up_left <= mvy_l0_up_mb_in[47:32];      end
           6:  begin mvx_l0_up_left <= mvx_l0_curr_mb_in[31:16];     mvy_l0_up_left <= mvy_l0_curr_mb_in[31:16];    end
           7:  begin mvx_l0_up_left <= mvx_l0_curr_mb_in[79:64];    mvy_l0_up_left <= mvy_l0_curr_mb_in[79:64];    end
           8:  begin mvx_l0_up_left <= mvx_l0_left_mb_in[31:16];     mvy_l0_up_left <= mvy_l0_left_mb_in[31:16];    end
           9:  begin mvx_l0_up_left <= mvx_l0_curr_mb_in[47:32];     mvy_l0_up_left <= mvy_l0_curr_mb_in[47:32];    end
           10: begin mvx_l0_up_left <= mvx_l0_left_mb_in[47:32];    mvy_l0_up_left <= mvy_l0_left_mb_in[47:32];    end
           11: begin mvx_l0_up_left <= mvx_l0_curr_mb_in[143:128];    mvy_l0_up_left <= mvy_l0_curr_mb_in[143:128];    end
           12: begin mvx_l0_up_left <= mvx_l0_curr_mb_in[63:48];    mvy_l0_up_left <= mvy_l0_curr_mb_in[63:48];    end
           13: begin mvx_l0_up_left <= mvx_l0_curr_mb_in[111:96];    mvy_l0_up_left <= mvy_l0_curr_mb_in[111:96];    end
           14: begin mvx_l0_up_left <= mvx_l0_curr_mb_in[159:144];    mvy_l0_up_left <= mvy_l0_curr_mb_in[159:144];    end
           15: begin mvx_l0_up_left <= mvx_l0_curr_mb_in[207:192];    mvy_l0_up_left <= mvy_l0_curr_mb_in[207:192];  end
       endcase

always @ (posedge clk)
    if (ref_idx_l0_up == -1)
        begin
            mvx_l0_up <= 0;
            mvy_l0_up <= 0;
        end
    else
        case(luma4x4BlkIdx_in)
           0:  begin mvx_l0_up <= mvx_l0_up_mb_in[15:0];        mvy_l0_up <= mvy_l0_up_mb_in[15:0];          end
           1:  begin mvx_l0_up <= mvx_l0_up_mb_in[31:16];       mvy_l0_up <= mvy_l0_up_mb_in[31:16];        end
           2:  begin mvx_l0_up <= mvx_l0_curr_mb_in[15:0];      mvy_l0_up <= mvy_l0_curr_mb_in[15:0];        end
           3:  begin mvx_l0_up <= mvx_l0_curr_mb_in[31:16];     mvy_l0_up <= mvy_l0_curr_mb_in[31:16];      end
           4:  begin mvx_l0_up <= mvx_l0_up_mb_in[47:32];      mvy_l0_up <= mvy_l0_up_mb_in[47:32];        end
           5:  begin mvx_l0_up <= mvx_l0_up_mb_in[63:48];      mvy_l0_up <= mvy_l0_up_mb_in[63:48];        end
           6:  begin mvx_l0_up <= mvx_l0_curr_mb_in[79:64];    mvy_l0_up <= mvy_l0_curr_mb_in[79:64];      end
           7:  begin mvx_l0_up <= mvx_l0_curr_mb_in[95:80];    mvy_l0_up <= mvy_l0_curr_mb_in[95:80];      end
           8:  begin mvx_l0_up <= mvx_l0_curr_mb_in[47:32];     mvy_l0_up <= mvy_l0_curr_mb_in[47:32];      end
           9:  begin mvx_l0_up <= mvx_l0_curr_mb_in[63:48];    mvy_l0_up <= mvy_l0_curr_mb_in[63:48];      end
           10: begin mvx_l0_up <= mvx_l0_curr_mb_in[143:128];    mvy_l0_up <= mvy_l0_curr_mb_in[143:128];      end
           11: begin mvx_l0_up <= mvx_l0_curr_mb_in[159:144];    mvy_l0_up <= mvy_l0_curr_mb_in[159:144];      end
           12: begin mvx_l0_up <= mvx_l0_curr_mb_in[111:96];    mvy_l0_up <= mvy_l0_curr_mb_in[111:96];      end
           13: begin mvx_l0_up <= mvx_l0_curr_mb_in[127:112];    mvy_l0_up <= mvy_l0_curr_mb_in[127:112];      end
           14: begin mvx_l0_up <= mvx_l0_curr_mb_in[207:192];    mvy_l0_up <= mvy_l0_curr_mb_in[207:192];    end
           15: begin mvx_l0_up <= mvx_l0_curr_mb_in[223:208];   mvy_l0_up <= mvy_l0_curr_mb_in[223:208];    end            
        endcase

always @ (posedge clk) 
    if (ref_idx_l0_left == -1) // fix: ref_idx_l0_left should be declared as signed, otherwise it never equals -1
        begin
            mvx_l0_left <= 0;
            mvy_l0_left <= 0;
        end
    else
        case(luma4x4BlkIdx_in)
            0:  begin mvx_l0_left <= mvx_l0_left_mb_in[15:0];      mvy_l0_left <= mvy_l0_left_mb_in[15:0];      end
            1:  begin mvx_l0_left <= mvx_l0_curr_mb_in[15:0];      mvy_l0_left <= mvy_l0_curr_mb_in[15:0];      end
            2:  begin mvx_l0_left <= mvx_l0_left_mb_in[31:16];    mvy_l0_left <= mvy_l0_left_mb_in[31:16];    end
            3:  begin mvx_l0_left <= mvx_l0_curr_mb_in[47:32];    mvy_l0_left <= mvy_l0_curr_mb_in[47:32];    end
            4:  begin mvx_l0_left <= mvx_l0_curr_mb_in[31:16];    mvy_l0_left <= mvy_l0_curr_mb_in[31:16];    end
            5:  begin mvx_l0_left <= mvx_l0_curr_mb_in[79:64];    mvy_l0_left <= mvy_l0_curr_mb_in[79:64];    end
            6:  begin mvx_l0_left <= mvx_l0_curr_mb_in[63:48];    mvy_l0_left <= mvy_l0_curr_mb_in[63:48];    end
            7:  begin mvx_l0_left <= mvx_l0_curr_mb_in[111:96];    mvy_l0_left <= mvy_l0_curr_mb_in[111:96];    end
            8:  begin mvx_l0_left <= mvx_l0_left_mb_in[47:32];    mvy_l0_left <= mvy_l0_left_mb_in[47:32];    end
            9:  begin mvx_l0_left <= mvx_l0_curr_mb_in[143:128];    mvy_l0_left <= mvy_l0_curr_mb_in[143:128];    end
            10: begin mvx_l0_left <= mvx_l0_left_mb_in[63:48];    mvy_l0_left <= mvy_l0_left_mb_in[63:48];    end
            11: begin mvx_l0_left <= mvx_l0_curr_mb_in[175:160];    mvy_l0_left <= mvy_l0_curr_mb_in[175:160];    end
            12: begin mvx_l0_left <= mvx_l0_curr_mb_in[159:144];    mvy_l0_left <= mvy_l0_curr_mb_in[159:144];    end
            13: begin mvx_l0_left <= mvx_l0_curr_mb_in[207:192];  mvy_l0_left <= mvy_l0_curr_mb_in[207:192];  end
            14: begin mvx_l0_left <= mvx_l0_curr_mb_in[191:176];  mvy_l0_left <= mvy_l0_curr_mb_in[191:176];  end
            15: begin mvx_l0_left <= mvx_l0_curr_mb_in[239:224];  mvy_l0_left <= mvy_l0_curr_mb_in[239:224];  end     
        endcase      

always @(luma4x4BlkIdx_in or MbPartWidth_in)
    case(luma4x4BlkIdx_in)
        0:
            if(MbPartWidth_in == 4)
                luma4x4BlkIdx_uprightmost <= 0;
            else if(MbPartWidth_in == 8)
                luma4x4BlkIdx_uprightmost <= 1;
            else // MbPartWidth = 16
                luma4x4BlkIdx_uprightmost <= 5;
        2:
            if(MbPartWidth_in == 4)
                luma4x4BlkIdx_uprightmost <= 2;
            else if(MbPartWidth_in == 8)
                luma4x4BlkIdx_uprightmost <= 3;
            else // MbPartWidth = 16
                luma4x4BlkIdx_uprightmost <= 7;        

        4:
            if(MbPartWidth_in == 4)
                luma4x4BlkIdx_uprightmost <= 4;
            else // MbPartWidth = 8
                luma4x4BlkIdx_uprightmost <= 5;
        6:
            if(MbPartWidth_in == 4)
                luma4x4BlkIdx_uprightmost <= 6;
            else // MbPartWidth = 8
                luma4x4BlkIdx_uprightmost <= 7;        
        8:
            if(MbPartWidth_in == 4)
                luma4x4BlkIdx_uprightmost <= 8;
            else if(MbPartWidth_in == 8)
                luma4x4BlkIdx_uprightmost <= 9;
            else // MbPartWidth = 16
                luma4x4BlkIdx_uprightmost <= 13;        

        10:
            if(MbPartWidth_in == 4)
                luma4x4BlkIdx_uprightmost <= 10;
            else if(MbPartWidth_in == 8)
                luma4x4BlkIdx_uprightmost <= 11;
            else // MbPartWidth = 16
                luma4x4BlkIdx_uprightmost <= 15;        

        12:
            if(MbPartWidth_in == 4)
                luma4x4BlkIdx_uprightmost <= 12;
            else // MbPartWidth = 8
                luma4x4BlkIdx_uprightmost <= 13;        
        14:
            if(MbPartWidth_in == 4)
                luma4x4BlkIdx_uprightmost <= 14;
            else // MbPartWidth = 8
                luma4x4BlkIdx_uprightmost <= 15;        
        default:
            luma4x4BlkIdx_uprightmost <= luma4x4BlkIdx_in;
    endcase    
        


always @ (posedge clk)
    if ( up_right_avail )
        case(luma4x4BlkIdx_uprightmost)
            0:  
                begin
                mvx_l0_up_right <= mvx_l0_up_mb_in[31:16];
                mvy_l0_up_right <= mvy_l0_up_mb_in[31:16];
                end
            1:  
                begin 
                mvx_l0_up_right <= mvx_l0_up_mb_in[47:32];      
                mvy_l0_up_right <= mvy_l0_up_mb_in[47:32];      
                end
            2:  
                begin 
                mvx_l0_up_right <= mvx_l0_curr_mb_in[31:16];    
                mvy_l0_up_right <= mvy_l0_curr_mb_in[31:16];    
                end
            4:  
                begin
                mvx_l0_up_right <= mvx_l0_up_mb_in[63:48];      
                mvy_l0_up_right <= mvy_l0_up_mb_in[63:48];                      
                end
            5:  
                begin 
                mvx_l0_up_right <= mvx_l0_up_right_mb_in[15:0];      
                mvy_l0_up_right <= mvy_l0_up_right_mb_in[15:0];
                end
            6:  
                begin 
                mvx_l0_up_right <= mvx_l0_curr_mb_in[95:80];    
                mvy_l0_up_right <= mvy_l0_curr_mb_in[95:80];    
                end
            8:  
                begin 
                mvx_l0_up_right <= mvx_l0_curr_mb_in[63:48];    
                mvy_l0_up_right <= mvy_l0_curr_mb_in[63:48];    
                end
            9:  
                begin 
                mvx_l0_up_right <= mvx_l0_curr_mb_in[111:96];    
                mvy_l0_up_right <= mvy_l0_curr_mb_in[111:96];    
                end
            10: 
                begin 
                mvx_l0_up_right <= mvx_l0_curr_mb_in[159:144];    
                mvy_l0_up_right <= mvy_l0_curr_mb_in[159:144];    
                end
            12: 
                begin 
                mvx_l0_up_right <= mvx_l0_curr_mb_in[127:112];    
                mvy_l0_up_right <= mvy_l0_curr_mb_in[127:112];    
                end
            14: 
                begin 
                mvx_l0_up_right <= mvx_l0_curr_mb_in[223:208];  
                mvy_l0_up_right <= mvy_l0_curr_mb_in[223:208];  
                end 
            //default : begin mvx_l0_up_right <= -1; mvy_l0_up_right <= -1; end
            default : begin mvx_l0_up_right <= mvx_l0_up_left; mvy_l0_up_right <= mvy_l0_up_left; end        
        endcase
    else
        begin
            mvx_l0_up_right <= mvx_l0_up_left;
            mvy_l0_up_right <= mvy_l0_up_left;
        end

always @(posedge clk)
    if ( ref_idx_l0_left == ref_idx_l0 && 
         ref_idx_l0_up != ref_idx_l0 &&
         ref_idx_l0_up_right != ref_idx_l0 )
        begin
            mvpx_l0_out <= mvx_l0_left;
            mvpy_l0_out <= mvy_l0_left;
        end
    else if (ref_idx_l0_left != ref_idx_l0 && 
         ref_idx_l0_up == ref_idx_l0 &&
         ref_idx_l0_up_right != ref_idx_l0 )
        begin
            mvpx_l0_out <= mvx_l0_up;
            mvpy_l0_out <= mvy_l0_up;        
        end
    else if (ref_idx_l0_left != ref_idx_l0 && 
         ref_idx_l0_up != ref_idx_l0 &&
         ref_idx_l0_up_right == ref_idx_l0) 
        begin
            mvpx_l0_out <= mvx_l0_up_right;
            mvpy_l0_out <= mvy_l0_up_right;        
        end
    else if (MbPartWidth_in == 16 && MbPartHeight_in == 8 && pixel_y[3:2] < 2 && ref_idx_l0 == ref_idx_l0_up )
        begin // 16x8's up
            mvpx_l0_out <= mvx_l0_up;
            mvpy_l0_out <= mvy_l0_up;
        end 
    else if (MbPartWidth_in == 16 && MbPartHeight_in == 8 && pixel_y[3:2] >= 2 && ref_idx_l0 == ref_idx_l0_left )
        begin // 16x8's down
            mvpx_l0_out <= mvx_l0_left;
            mvpy_l0_out <= mvy_l0_left;
        end
    else if (MbPartWidth_in == 8 && MbPartHeight_in == 16 && pixel_x[3:2] < 2 && ref_idx_l0 == ref_idx_l0_left)
        begin // 8x16's left
            mvpx_l0_out <= mvx_l0_left;
            mvpy_l0_out <= mvy_l0_left;
        end
    else if (MbPartWidth_in == 8 && MbPartHeight_in == 16 && pixel_x[3:2] >= 2 && ref_idx_l0 == ref_idx_l0_up_right)
        begin
            mvpx_l0_out <= mvx_l0_up_right;
            mvpy_l0_out <= mvy_l0_up_right;
        end    
    else if (up_avail == 0 && up_right_avail == 0)
        begin
            mvpx_l0_out <= mvx_l0_left;
            mvpy_l0_out <= mvy_l0_left;
        end
    else
        begin // Median(a,b,c)
            mvpx_l0_out <= mvx_l0_left > mvx_l0_up ? 
                          (mvx_l0_left > mvx_l0_up_right ? 
                              (mvx_l0_up > mvx_l0_up_right ? mvx_l0_up : mvx_l0_up_right): mvx_l0_left)
                          :(mvx_l0_left > mvx_l0_up_right ?
                              mvx_l0_left : (mvx_l0_up < mvx_l0_up_right ?mvx_l0_up:mvx_l0_up_right));
            mvpy_l0_out <= mvy_l0_left > mvy_l0_up ? 
                          (mvy_l0_left > mvy_l0_up_right ? 
                              (mvy_l0_up > mvy_l0_up_right ? mvy_l0_up : mvy_l0_up_right): mvy_l0_left)
                          :(mvy_l0_left > mvy_l0_up_right ?
                              mvy_l0_left : (mvy_l0_up < mvy_l0_up_right ? mvy_l0_up : mvy_l0_up_right));
        end                   

    
endmodule
