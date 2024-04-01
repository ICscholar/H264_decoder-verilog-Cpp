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

module intra_pred_fsm
(
    input clk,
    input rst_n,
    input ena,
    input start,
	input start_of_MB,

	input [`mb_x_bits - 1:0] mb_x,
	input [3:0] mb_pred_mode,
	input mb_pred_inter_sel,
	input [3:0] I4_pred_mode,
	input [1:0] I16_pred_mode,
	input [1:0] intra_pred_mode_chroma,
	input [4:0] blk4x4_counter,
	input [7:0] is_mb_intra,
	input constrained_intra_pred_flag,
	input sum_valid,

	output reg top_left_blk_avail,
	output reg top_blk_avail,
	output reg top_right_blk_avail,
	output reg left_blk_avail,

	output reg [2:0] preload_counter,
	output reg [2:0] up_left_addr,
	output reg left_mb_luma_wr,
	output reg up_mb_luma_wr,
	output reg up_left_wr,
	output reg up_left_cb_wr,
	output reg up_left_cr_wr,
	output reg left_mb_cb_wr,
	output reg left_mb_cr_wr,
	output reg line_ram_luma_wr_n,
	output reg line_ram_cb_wr_n,
	output reg line_ram_cr_wr_n,
	output reg [`mb_x_bits+1:0] line_ram_luma_addr,
	output reg [`mb_x_bits:0] line_ram_chroma_addr,
	
	output reg [5:0] calc_ena,
	output reg precalc_ena,
	output reg [3:0] precalc_counter,
	output abc_latch,
	output seed_latch,
	output seed_wr,
	output reg valid
); 


//FFs
reg sum_valid_s;
reg [2:0] state;

assign abc_latch = (state == `intra_pred_precalc_s && precalc_counter == 'b1111);
assign seed_latch = (state == `intra_pred_seedcalc_s);
assign seed_wr = ((   mb_pred_mode == `mb_pred_mode_I16MB && 
						I16_pred_mode == `Intra16x16_Plane && (

                       ((blk4x4_counter == 0 || blk4x4_counter == 2 || 
                        blk4x4_counter == 8) && calc_ena[2])||                            

                       ((blk4x4_counter == 1 || blk4x4_counter == 3 ||
                          blk4x4_counter == 9 || blk4x4_counter == 11) 
                        && !sum_valid_s && sum_valid))) ||

                   (intra_pred_mode_chroma == `Intra_chroma_Plane && 
                    (((blk4x4_counter == 16 || blk4x4_counter == 20) && calc_ena[2]) )));
reg [5:0] calc_ena_init;
always @(*)
if (blk4x4_counter[4] && intra_pred_mode_chroma == `Intra_chroma_Plane || 
	~blk4x4_counter[4] && mb_pred_mode == `mb_pred_mode_I16MB &&
   	I16_pred_mode == `Intra16x16_Plane)
	calc_ena_init <= 'b000010;
else 
	calc_ena_init <= 'b000001;
              
always @(posedge clk or negedge rst_n)
if (!rst_n) begin
    state <= `intra_pred_idle_s;
    valid <= 0;
    precalc_counter <= 0;
	calc_ena <= 0;
	precalc_ena <= 0;
end
else if (ena) begin
    case (state)
    `intra_pred_idle_s: begin
        if (start)begin
            if (blk4x4_counter == 0)begin   //load all up mb information at blk 0
                state <= `intra_pred_preload_s;                 
                valid <= 0;
            end
            else if (intra_pred_mode_chroma == `Intra_chroma_Plane &&
                  (blk4x4_counter == 16 || blk4x4_counter == 20))begin
                state <= `intra_pred_precalc_s;                 
				precalc_ena <= 1'b1;
                precalc_counter <= 4;                                            
                valid <= 0;               
            end   
            else begin
                state <= `intra_pred_calc_s;
				calc_ena <= calc_ena_init;
                valid <= 0;     
            end
        end
    end
    `intra_pred_preload_s: begin
        if (preload_counter == 1)begin
            if (mb_pred_mode == `mb_pred_mode_I16MB && I16_pred_mode == `Intra16x16_Plane)begin
                state <= `intra_pred_precalc_s;
                precalc_counter <= 8;                                            
				precalc_ena <= 1'b1;
            end
            else begin
                state <= `intra_pred_calc_s;
				calc_ena <= calc_ena_init;
            end
        end
    end
    `intra_pred_precalc_s:
        if (precalc_counter == 'b1111) begin
            state <= `intra_pred_seedcalc_s;
			precalc_ena <= 1'b0;
        end
        else begin
            precalc_counter <= precalc_counter - 1;
        end
    `intra_pred_seedcalc_s:
        begin
            state <= `intra_pred_calc_s;
			calc_ena <= calc_ena_init;
        end
    `intra_pred_calc_s: begin
		calc_ena <= calc_ena << 1;
		if (calc_ena[0]|| calc_ena[5])begin
			calc_ena <= 0;
			valid <= 1;
			state <= `intra_pred_idle_s;
		end
	end
    endcase
	if (start_of_MB) begin
		state <= `intra_pred_idle_s;
		valid <= 1'b0;
		precalc_counter <= 0;
		calc_ena <= 0;
		precalc_ena <= 0;
	end
end

always @(posedge clk or negedge rst_n)
if (!rst_n)
	sum_valid_s <= 0;
else if (ena)
	sum_valid_s <= sum_valid;

always @(posedge clk or negedge rst_n)
if (!rst_n)
    preload_counter <= 0;
else if (ena) begin
    if (start && state == `intra_pred_idle_s && blk4x4_counter == 0)
        preload_counter <= 6;                                            
    else if (preload_counter > 0)    
        preload_counter <= preload_counter - 1;
end
    
//intra_pred_regs control
//wr and addr        
    
always @(*)   
    if (!sum_valid_s  &&  sum_valid &&(
         (mb_pred_mode == `mb_pred_mode_I4MB && blk4x4_counter < 16 ) || 
         (mb_pred_mode == `mb_pred_mode_I16MB || mb_pred_inter_sel) &&
         (blk4x4_counter == 5 || blk4x4_counter == 7||
         blk4x4_counter == 13 || blk4x4_counter == 15)))
                                       
        left_mb_luma_wr <= 1;
    else
        left_mb_luma_wr <= 0;
        
always @(*)
    if (!sum_valid_s  &&  sum_valid &&(
         (mb_pred_mode == `mb_pred_mode_I4MB  && blk4x4_counter < 16) || 
         (mb_pred_mode == `mb_pred_mode_I16MB || mb_pred_inter_sel) &&
         (blk4x4_counter == 10 || blk4x4_counter == 11||
         blk4x4_counter == 14 || blk4x4_counter == 15)
         ))
        up_mb_luma_wr <= 1;
    else
        up_mb_luma_wr <= 0;
        

always @(*)
    if (!sum_valid_s  &&  sum_valid && (
		mb_pred_mode == `mb_pred_mode_I4MB &&  (
		{blk4x4_counter[2],blk4x4_counter[0]} != 2'b11 &&	 //not right colum
   		{blk4x4_counter[3],blk4x4_counter[1]} != 2'b11 ||   //not bottom row
		blk4x4_counter == 15) ||
	   	(mb_pred_mode == `mb_pred_mode_I16MB || mb_pred_inter_sel) &&  blk4x4_counter == 15
		)) //for next mb blk 0
        up_left_wr <= 1;
    else
        up_left_wr <= 0;

always @(*)
    if (!sum_valid_s && sum_valid && blk4x4_counter == 19 )                
        up_left_cb_wr <= 1;
    else
        up_left_cb_wr <= 0;

always @(*)
    if (!sum_valid_s && sum_valid && blk4x4_counter == 23 )                
        up_left_cr_wr <= 1;
    else
        up_left_cr_wr <= 0;

        
always @(*)
    case(blk4x4_counter)
        0, 6    :up_left_addr <= 0;
        1, 8    :up_left_addr <= 1;
        2, 9    :up_left_addr <= 2;
        3, 12   :up_left_addr <= 3; 
        4       :up_left_addr <= 4;
        default:up_left_addr <= 0;
    endcase
   
always @(*)
    if  (!sum_valid_s  &&  sum_valid &&
         (blk4x4_counter == 17 || blk4x4_counter == 19))    
        left_mb_cb_wr <= 1;
    else
        left_mb_cb_wr <= 0;

    
always @(*)
    if  (!sum_valid_s  &&  sum_valid &&
         (blk4x4_counter == 21 || blk4x4_counter == 23))    
        left_mb_cr_wr <= 1;
    else
        left_mb_cr_wr <= 0;

always @(*)
    if (!sum_valid_s  && sum_valid && 
        (blk4x4_counter == 10 || blk4x4_counter == 11 ||
        blk4x4_counter == 14 || blk4x4_counter == 15))
        line_ram_luma_wr_n <= 0;
    else
        line_ram_luma_wr_n <= 1;
        
always @(*)
    if (!sum_valid_s  && sum_valid &&
     (blk4x4_counter == 18 || blk4x4_counter == 19 ))
        line_ram_cb_wr_n <= 0;
    else
        line_ram_cb_wr_n <= 1;
    
always @(*)
    if (!sum_valid_s  && sum_valid && 
    (blk4x4_counter == 22 || blk4x4_counter == 23 ))
        line_ram_cr_wr_n <= 0;
    else
        line_ram_cr_wr_n <= 1;  


always @(*)
if(!sum_valid_s && sum_valid)
    case(blk4x4_counter)	//write
        10:line_ram_luma_addr <= (mb_x<<2) + 0;
        11:line_ram_luma_addr <= (mb_x<<2) + 1;
        14:line_ram_luma_addr <= (mb_x<<2) + 2;
        15:line_ram_luma_addr <= (mb_x<<2) + 3;
        default:line_ram_luma_addr <= (mb_x<<2) + 3;
    endcase
else begin  //there is 1 cycle latency to read, because it's sync read
    case(preload_counter)
    6:line_ram_luma_addr <= (mb_x<<2) + 4;
    5:line_ram_luma_addr <= (mb_x<<2) + 0;
    4:line_ram_luma_addr <= (mb_x<<2) + 1;
    3:line_ram_luma_addr <= (mb_x<<2) + 2;
    2:line_ram_luma_addr <= (mb_x<<2) + 3;
    default :line_ram_luma_addr <= (mb_x<<2) + 3;
    endcase
end

always @(*)
if(!sum_valid_s && sum_valid)
    case(blk4x4_counter)
        18,22:line_ram_chroma_addr <= (mb_x << 1) + 0;
        19,23:line_ram_chroma_addr <= (mb_x << 1) + 1;
        default : line_ram_chroma_addr <= (mb_x << 1) + 1;
    endcase
else begin
    case(preload_counter)
    3:line_ram_chroma_addr <= (mb_x<<1) + 0;
    2:line_ram_chroma_addr <= (mb_x<<1) + 1;
    default : line_ram_chroma_addr <= (mb_x<<1) + 1;
    endcase
end


wire is_up_left_mb_not_avail;
wire is_up_mb_not_avail;
wire is_up_right_mb_not_avail;
wire is_left_mb_not_avail;
assign is_up_left_mb_not_avail = is_mb_intra[1:0] != 1 &&
							(is_mb_intra[1:0] == 0 || constrained_intra_pred_flag);
assign is_up_mb_not_avail = is_mb_intra[3:2] != 1 &&
							(is_mb_intra[3:2] == 0 || constrained_intra_pred_flag);
assign is_up_right_mb_not_avail = is_mb_intra[5:4] != 1 &&
							(is_mb_intra[5:4] == 0 || constrained_intra_pred_flag);
assign is_left_mb_not_avail = is_mb_intra[7:6] != 1 &&
							(is_mb_intra[7:6] == 0 || constrained_intra_pred_flag);

always @(*) begin
	if (mb_pred_mode == `mb_pred_mode_I16MB) begin
		top_left_blk_avail <= ~is_up_left_mb_not_avail;
		top_blk_avail <= ~is_up_mb_not_avail;
		top_right_blk_avail <= ~is_up_mb_not_avail;
		left_blk_avail <= ~is_left_mb_not_avail;
	end
	else
	case(blk4x4_counter)
	1:begin
		top_left_blk_avail <= ~is_up_mb_not_avail;
		top_blk_avail <= ~is_up_mb_not_avail;
		top_right_blk_avail <= ~is_up_mb_not_avail;
		left_blk_avail <= 1;
	end
	2:begin
		top_left_blk_avail <= ~is_left_mb_not_avail;
		top_blk_avail <= 1;
		top_right_blk_avail <= 1;
		left_blk_avail <= ~is_left_mb_not_avail;
	end
	3:begin
		top_left_blk_avail <= 1;
		top_blk_avail <= 1;
		top_right_blk_avail <= 0;
		left_blk_avail <= 1;
	end
	4:begin
		top_left_blk_avail <= ~is_up_mb_not_avail;
		top_blk_avail <= ~is_up_mb_not_avail;
		top_right_blk_avail <= ~is_up_mb_not_avail;
		left_blk_avail <= 1;
	end
	5:begin
		top_left_blk_avail <= ~is_up_mb_not_avail;
		top_blk_avail <= ~is_up_mb_not_avail;
		top_right_blk_avail <= ~is_up_right_mb_not_avail;
		left_blk_avail <= 1;
	end
	6:begin
		top_left_blk_avail <= 1;
		top_blk_avail <= 1;
		top_right_blk_avail <= 1;
		left_blk_avail <= 1;
	end
	7:begin
		top_left_blk_avail <= 1;
		top_blk_avail <= 1;
		top_right_blk_avail <= 0;
		left_blk_avail <= 1;
	end
	8:begin
		top_left_blk_avail <= ~is_left_mb_not_avail;
		top_blk_avail <= 1;
		top_right_blk_avail <= 1;
		left_blk_avail <= ~is_left_mb_not_avail;
	end
	9:begin
		top_left_blk_avail <= 1;
		top_blk_avail <= 1;
		top_right_blk_avail <= 1;
		left_blk_avail <= 1;
	end
	10:begin
		top_left_blk_avail <= ~is_left_mb_not_avail;
		top_blk_avail <= 1;
		top_right_blk_avail <= 1;
		left_blk_avail <= ~is_left_mb_not_avail;
	end
	11:begin
		top_left_blk_avail <= 1;
		top_blk_avail <= 1;
		top_right_blk_avail <= 0;
		left_blk_avail <= 1;
	end
	12:begin
		top_left_blk_avail <= 1;
		top_blk_avail <= 1;
		top_right_blk_avail <= 1;
		left_blk_avail <= 1;
	end
	13:begin
		top_left_blk_avail <= 1;
		top_blk_avail <= 1;
		top_right_blk_avail <= 0;
		left_blk_avail <= 1;
	end
	14:begin
		top_left_blk_avail <= 1;
		top_blk_avail <= 1;
		top_right_blk_avail <= 1;
		left_blk_avail <= 1;
	end
	15:begin
		top_left_blk_avail <= 1;
		top_blk_avail <= 1;
		top_right_blk_avail <= 0;
		left_blk_avail <= 1;
	end
	default:begin
		top_left_blk_avail <= ~is_up_left_mb_not_avail;
		top_blk_avail <= ~is_up_mb_not_avail;
		top_right_blk_avail <= ~is_up_mb_not_avail;
		left_blk_avail <= ~is_left_mb_not_avail;
	end
	endcase
end

		
endmodule
