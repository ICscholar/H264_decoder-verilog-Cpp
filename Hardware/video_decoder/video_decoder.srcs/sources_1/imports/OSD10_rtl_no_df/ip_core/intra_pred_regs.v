// 用于视频编码领域中的帧内预测（Intra Prediction）的寄存器处理

// 与预测模式和块计数有关的多个信号，如mb_pred_mode（宏块预测模式）、I16_pred_mode（16x16帧内预测模式）、I4_pred_mode（4x4帧内预测模式）等。
// 来自其他模块的数据输入，如line_ram_luma_data（亮度数据）、line_ram_cb_data和line_ram_cr_data（色度数据）等

// 主要逻辑
// 预加载和写入操作：根据输入的控制信号和数据，模块在每个时钟周期更新内部的寄存器值。这包括处理来自邻近块的数据（如上方块、左方块等），并根据帧内预测的不同模式计算预测值。

// DC和平面预测模式的计算：模块根据帧内预测的模式执行不同的计算，如DC预测模式下的累加和舍入操作，以及平面预测模式下的H和V值的计算，这些值反映了像素值沿水平和垂直方向的变化趋势。

// 种子值的计算：用于平面预测模式中，根据预先计算的a、b、c值生成种子值，这些种子值后续用于生成预测像素值。

`include "defines.v"

module intra_pred_regs(
	input clk,
	input rst_n,
	input ena,
	
	//plane
	input precalc_ena,
	input abc_latch,
	input seed_latch,
	input seed_wr,
	input [3:0] precalc_counter,
	input [13:0] sum0_reg,
	input [13:0] sum3_reg,

	input [4:0] blk4x4_counter,
	input [3:0] mb_pred_mode,
	input [1:0] I16_pred_mode,
	input [3:0] I4_pred_mode,
	input [1:0] intra_pred_mode_chroma,
	
	input [31:0] line_ram_luma_data,
	input [31:0] line_ram_cb_data,
	input [31:0] line_ram_cr_data,
	input [31:0] sum_right_colum,
	input [31:0] sum_bottom_row,
	
	
	input [2:0] preload_counter,
	input up_left_wr,
	input left_mb_luma_wr,
	input up_mb_luma_wr,
	input up_left_cb_wr,
	input up_left_cr_wr,
	input left_mb_cb_wr,
	input left_mb_cr_wr,
	
	input top_left_blk_avail,
	input top_blk_avail,
	input top_right_blk_avail,
	input left_blk_avail,
	
	output reg [7:0] left_mb_muxout_0,
	output reg [7:0] left_mb_muxout_1,
	output reg [7:0] left_mb_muxout_2,
	output reg [7:0] left_mb_muxout_3,
	
	output reg [7:0] up_mb_muxout_0,
	output reg [7:0] up_mb_muxout_1,
	output reg [7:0] up_mb_muxout_2,
	output reg [7:0] up_mb_muxout_3,
	
	output reg [7:0] up_left_muxout,
	
	output reg [7:0] up_right_muxout_0,
	output reg [7:0] up_right_muxout_1,
	output reg [7:0] up_right_muxout_2,                     
	output reg [7:0] up_right_muxout_3,                     
	
	output reg [11:0] DC_sum_up,
	output reg [11:0] DC_sum_left,
	output reg [4:0]  DC_sum_round_value,

	output reg signed [12:0] b,
	output reg signed [12:0] c,
	
	output reg [14:0] seed
); 

//FFs                
reg [7:0] up_mb_luma_0;     
reg [7:0] up_mb_luma_1;     
reg [7:0] up_mb_luma_2;     
reg [7:0] up_mb_luma_3;     
reg [7:0] up_mb_luma_4;     
reg [7:0] up_mb_luma_5;     
reg [7:0] up_mb_luma_6;     
reg [7:0] up_mb_luma_7;     
reg [7:0] up_mb_luma_8;     
reg [7:0] up_mb_luma_9;     
reg [7:0] up_mb_luma_10;    
reg [7:0] up_mb_luma_11;    
reg [7:0] up_mb_luma_12;    
reg [7:0] up_mb_luma_13;
reg [7:0] up_mb_luma_14;
reg [7:0] up_mb_luma_15;

reg [7:0] left_mb_luma_0;  
reg [7:0] left_mb_luma_1;  
reg [7:0] left_mb_luma_2;  
reg [7:0] left_mb_luma_3;  
reg [7:0] left_mb_luma_4;  
reg [7:0] left_mb_luma_5;  
reg [7:0] left_mb_luma_6;  
reg [7:0] left_mb_luma_7;  
reg [7:0] left_mb_luma_8;  
reg [7:0] left_mb_luma_9;  
reg [7:0] left_mb_luma_10; 
reg [7:0] left_mb_luma_11; 
reg [7:0] left_mb_luma_12; 
reg [7:0] left_mb_luma_13; 
reg [7:0] left_mb_luma_14; 
reg [7:0] left_mb_luma_15; 
     

reg [7:0] up_mb_cb_0;
reg [7:0] up_mb_cb_1;
reg [7:0] up_mb_cb_2;
reg [7:0] up_mb_cb_3;
reg [7:0] up_mb_cb_4;
reg [7:0] up_mb_cb_5;
reg [7:0] up_mb_cb_6;
reg [7:0] up_mb_cb_7;

reg [7:0] left_mb_cb_0;
reg [7:0] left_mb_cb_1;
reg [7:0] left_mb_cb_2;
reg [7:0] left_mb_cb_3;
reg [7:0] left_mb_cb_4;
reg [7:0] left_mb_cb_5;
reg [7:0] left_mb_cb_6;
reg [7:0] left_mb_cb_7;

reg [7:0] up_mb_cr_0;
reg [7:0] up_mb_cr_1;
reg [7:0] up_mb_cr_2;
reg [7:0] up_mb_cr_3;
reg [7:0] up_mb_cr_4;
reg [7:0] up_mb_cr_5;
reg [7:0] up_mb_cr_6;
reg [7:0] up_mb_cr_7;
                       
reg [7:0] left_mb_cr_0;
reg [7:0] left_mb_cr_1;
reg [7:0] left_mb_cr_2;
reg [7:0] left_mb_cr_3;
reg [7:0] left_mb_cr_4;
reg [7:0] left_mb_cr_5;
reg [7:0] left_mb_cr_6;
reg [7:0] left_mb_cr_7;

reg [7:0] up_left_0;
reg [7:0] up_left_1;
reg [7:0] up_left_2;
reg [7:0] up_left_3;
reg [7:0] up_left_4;
reg [7:0] up_left_5;
reg [7:0] up_left_up_left_mb;
reg [7:0] up_left_cb;
reg [7:0] up_left_cr;

reg [9:0] up_mb_luma_sum_0;
reg [9:0] up_mb_luma_sum_1;
reg [9:0] up_mb_luma_sum_2;
reg [9:0] up_mb_luma_sum_3;

reg [9:0] left_mb_luma_sum_0;
reg [9:0] left_mb_luma_sum_1;
reg [9:0] left_mb_luma_sum_2;
reg [9:0] left_mb_luma_sum_3;

wire is_I4_luma_DC;
wire is_I16_luma_DC;
wire is_chroma_DC;

assign is_I4_luma_DC = mb_pred_mode == `mb_pred_mode_I4MB && I4_pred_mode == `Intra4x4_DC && ~blk4x4_counter[4];
assign is_I16_luma_DC = mb_pred_mode == `mb_pred_mode_I16MB && I16_pred_mode == `Intra16x16_DC && ~blk4x4_counter[4];
assign is_chroma_DC = intra_pred_mode_chroma == `Intra_chroma_DC && blk4x4_counter[4];

wire[9:0] line_ram_luma_4pixel_sum;
assign line_ram_luma_4pixel_sum = line_ram_luma_data[7:0] + line_ram_luma_data[15:8] +
			                      line_ram_luma_data[23:16] + line_ram_luma_data[31:24];

wire[9:0] sum_bottom_row_sum;
assign  sum_bottom_row_sum = sum_bottom_row[7:0] + sum_bottom_row[15:8] +
			                 sum_bottom_row[23:16] + sum_bottom_row[31:24]; 

wire[9:0] sum_right_colum_sum;
assign  sum_right_colum_sum = sum_right_colum[7:0] + sum_right_colum[15:8] +
			                 sum_right_colum[23:16] + sum_right_colum[31:24]; 

always @(posedge clk or negedge rst_n)
if (!rst_n) begin
	up_mb_luma_0 <= 0;
	up_mb_luma_1 <= 0;
	up_mb_luma_2 <= 0;
	up_mb_luma_3 <= 0;
	up_mb_luma_4 <= 0;
	up_mb_luma_5 <= 0;
	up_mb_luma_6 <= 0;
	up_mb_luma_7 <= 0;
	up_mb_luma_8 <= 0;
	up_mb_luma_9 <= 0;
	up_mb_luma_10 <= 0;
	up_mb_luma_11 <= 0;
	up_mb_luma_12 <= 0;
	up_mb_luma_13 <= 0;
	up_mb_luma_14 <= 0;
	up_mb_luma_15 <= 0;
	up_mb_luma_sum_0 <= 0;
	up_mb_luma_sum_1 <= 0;
	up_mb_luma_sum_2 <= 0;
	up_mb_luma_sum_3 <= 0;
end
else if (ena && top_blk_avail && preload_counter > 0 && preload_counter <= 4)
	case(preload_counter)
	4: begin
		up_mb_luma_sum_0 <= line_ram_luma_4pixel_sum;
		up_mb_luma_0 <= line_ram_luma_data[7:0]; 	
		up_mb_luma_1 <= line_ram_luma_data[15:8];
		up_mb_luma_2 <= line_ram_luma_data[23:16];	
		up_mb_luma_3 <= line_ram_luma_data[31:24];
	end
	3:begin
		up_mb_luma_sum_1 <= line_ram_luma_4pixel_sum;
		up_mb_luma_4 <= line_ram_luma_data[7:0];
		up_mb_luma_5 <= line_ram_luma_data[15:8];
		up_mb_luma_6 <= line_ram_luma_data[23:16];
		up_mb_luma_7 <= line_ram_luma_data[31:24];
	end
	2:begin
		up_mb_luma_sum_2 <= line_ram_luma_4pixel_sum;
		up_mb_luma_8 <= line_ram_luma_data[7:0];
		up_mb_luma_9 <= line_ram_luma_data[15:8];
		up_mb_luma_10<= line_ram_luma_data[23:16];
		up_mb_luma_11<= line_ram_luma_data[31:24];
	end
	1:begin
		up_mb_luma_sum_3 <= line_ram_luma_4pixel_sum;
		up_mb_luma_12 <= line_ram_luma_data[7:0];
		up_mb_luma_13 <= line_ram_luma_data[15:8];
		up_mb_luma_14 <= line_ram_luma_data[23:16];
		up_mb_luma_15 <= line_ram_luma_data[31:24];
	end
	endcase
else if (ena && up_mb_luma_wr)
	case({blk4x4_counter[2], blk4x4_counter[0]})
	0:begin
		up_mb_luma_sum_0 <= sum_bottom_row_sum;
		{up_mb_luma_3,up_mb_luma_2,up_mb_luma_1,up_mb_luma_0} <= sum_bottom_row;
	end
	1:begin
		up_mb_luma_sum_1 <= sum_bottom_row_sum;
		{up_mb_luma_7,up_mb_luma_6,up_mb_luma_5,up_mb_luma_4} <= sum_bottom_row;
	end
	2:begin
		up_mb_luma_sum_2 <= sum_bottom_row_sum;
		{up_mb_luma_11,up_mb_luma_10,up_mb_luma_9,up_mb_luma_8} <= sum_bottom_row;
	end
	3:begin
		up_mb_luma_sum_3 <= sum_bottom_row_sum;
		{up_mb_luma_15,up_mb_luma_14,up_mb_luma_13,up_mb_luma_12} <= sum_bottom_row;
	end
	endcase

	
always @(posedge clk or negedge rst_n)
if (!rst_n)begin
	up_mb_cb_0 <= 0;
	up_mb_cb_1 <= 0;
	up_mb_cb_2 <= 0;
	up_mb_cb_3 <= 0;
	up_mb_cb_4 <= 0;
	up_mb_cb_5 <= 0;
	up_mb_cb_6 <= 0;
	up_mb_cb_7 <= 0;
end
else if (ena && top_blk_avail && (preload_counter == 1 || preload_counter == 2))begin
	case(preload_counter)
	2:begin
		up_mb_cb_0 <= line_ram_cb_data[7:0];
		up_mb_cb_1 <= line_ram_cb_data[15:8];
		up_mb_cb_2 <= line_ram_cb_data[23:16];
		up_mb_cb_3 <= line_ram_cb_data[31:24];
	end
	1:begin
		up_mb_cb_4 <= line_ram_cb_data[7:0];
		up_mb_cb_5 <= line_ram_cb_data[15:8];
		up_mb_cb_6 <= line_ram_cb_data[23:16];
		up_mb_cb_7 <= line_ram_cb_data[31:24];
	end
	endcase
end

always @(posedge clk or negedge rst_n)
if (!rst_n)begin
	up_mb_cr_0 <= 0;
	up_mb_cr_1 <= 0;
	up_mb_cr_2 <= 0;
	up_mb_cr_3 <= 0;
	up_mb_cr_4 <= 0;
	up_mb_cr_5 <= 0;
	up_mb_cr_6 <= 0;
	up_mb_cr_7 <= 0;
end
else if (ena && top_blk_avail && (preload_counter == 1 || preload_counter == 2))begin
	case(preload_counter)
	2:begin
		up_mb_cr_0 <= line_ram_cr_data[7:0];
		up_mb_cr_1 <= line_ram_cr_data[15:8];
		up_mb_cr_2 <= line_ram_cr_data[23:16];
		up_mb_cr_3 <= line_ram_cr_data[31:24];
	end
	1:begin
		up_mb_cr_4 <= line_ram_cr_data[7:0];
		up_mb_cr_5 <= line_ram_cr_data[15:8];
		up_mb_cr_6 <= line_ram_cr_data[23:16];
		up_mb_cr_7 <= line_ram_cr_data[31:24];
	end
	endcase
end


always @(posedge clk)
if (ena) begin
	case ({blk4x4_counter[4], blk4x4_counter[2], blk4x4_counter[0]})
	3'b000:begin
		up_mb_muxout_0 <= up_mb_luma_0;
		up_mb_muxout_1 <= up_mb_luma_1;
		up_mb_muxout_2 <= up_mb_luma_2;
		up_mb_muxout_3 <= up_mb_luma_3;
	end
	3'b001:begin
		up_mb_muxout_0 <= up_mb_luma_4;
		up_mb_muxout_1 <= up_mb_luma_5;
		up_mb_muxout_2 <= up_mb_luma_6;
		up_mb_muxout_3 <= up_mb_luma_7;
	end
	3'b010:begin
		up_mb_muxout_0 <= up_mb_luma_8;
		up_mb_muxout_1 <= up_mb_luma_9;  
		up_mb_muxout_2 <= up_mb_luma_10;  
		up_mb_muxout_3 <= up_mb_luma_11;  
	end
	3'b011:begin
		up_mb_muxout_0 <= up_mb_luma_12;  
		up_mb_muxout_1 <= up_mb_luma_13;  
		up_mb_muxout_2 <= up_mb_luma_14;  
		up_mb_muxout_3 <= up_mb_luma_15;  
	end   
	3'b100:begin
		up_mb_muxout_0 <= up_mb_cb_0;
		up_mb_muxout_1 <= up_mb_cb_1;
		up_mb_muxout_2 <= up_mb_cb_2;
		up_mb_muxout_3 <= up_mb_cb_3;
	end
	3'b101:begin
		up_mb_muxout_0 <= up_mb_cb_4;
		up_mb_muxout_1 <= up_mb_cb_5;
		up_mb_muxout_2 <= up_mb_cb_6;
		up_mb_muxout_3 <= up_mb_cb_7;
	end
	3'b110:begin
		up_mb_muxout_0 <= up_mb_cr_0;
		up_mb_muxout_1 <= up_mb_cr_1;
		up_mb_muxout_2 <= up_mb_cr_2;
		up_mb_muxout_3 <= up_mb_cr_3;
	end
	default:begin
		up_mb_muxout_0 <= up_mb_cr_4;
		up_mb_muxout_1 <= up_mb_cr_5;
		up_mb_muxout_2 <= up_mb_cr_6;
		up_mb_muxout_3 <= up_mb_cr_7;
	end
	endcase
end

always @(posedge clk or negedge rst_n)
if (!rst_n) begin
	left_mb_luma_0 <= 0;
	left_mb_luma_1 <= 0;
	left_mb_luma_2 <= 0;
	left_mb_luma_3 <= 0;
	left_mb_luma_4 <= 0;
	left_mb_luma_5 <= 0;
	left_mb_luma_6 <= 0;
	left_mb_luma_7 <= 0;
	left_mb_luma_8 <= 0;
	left_mb_luma_9 <= 0;
	left_mb_luma_10 <= 0;
	left_mb_luma_11 <= 0;
	left_mb_luma_12 <= 0;
	left_mb_luma_13 <= 0;
	left_mb_luma_14 <= 0;
	left_mb_luma_15 <= 0;
end
else if (ena && left_mb_luma_wr)begin
	case({blk4x4_counter[3], blk4x4_counter[1]})
	0: begin
		left_mb_luma_sum_0 <= sum_right_colum_sum;
		left_mb_luma_0 <= sum_right_colum[7:0];
		left_mb_luma_1 <= sum_right_colum[15:8];
		left_mb_luma_2 <= sum_right_colum[23:16];
		left_mb_luma_3 <= sum_right_colum[31:24];
	end
	1:begin
		left_mb_luma_sum_1 <= sum_right_colum_sum;
		left_mb_luma_4 <= sum_right_colum[7:0]; 
		left_mb_luma_5 <= sum_right_colum[15:8];
		left_mb_luma_6 <= sum_right_colum[23:16];
		left_mb_luma_7 <= sum_right_colum[31:24];
	end
	2:begin
		left_mb_luma_sum_2 <= sum_right_colum_sum;
		left_mb_luma_8 <= sum_right_colum[7:0]; 
		left_mb_luma_9 <= sum_right_colum[15:8];
		left_mb_luma_10<= sum_right_colum[23:16];
		left_mb_luma_11<= sum_right_colum[31:24];
	end
	3:begin
		left_mb_luma_sum_3 <= sum_right_colum_sum;
		left_mb_luma_12 <= sum_right_colum[7:0];
		left_mb_luma_13 <= sum_right_colum[15:8];
		left_mb_luma_14 <= sum_right_colum[23:16];
		left_mb_luma_15 <= sum_right_colum[31:24];
	end
	endcase
end
	
always @(posedge clk or negedge rst_n)
if (!rst_n)begin
	left_mb_cb_0 <= 0;
	left_mb_cb_1 <= 0;
	left_mb_cb_2 <= 0;
	left_mb_cb_3 <= 0;
	left_mb_cb_4 <= 0;
	left_mb_cb_5 <= 0;
	left_mb_cb_6 <= 0;
	left_mb_cb_7 <= 0;
end
else if (ena && left_mb_cb_wr)begin
	case(blk4x4_counter[1])
	0:begin
		left_mb_cb_0 <= sum_right_colum[7:0];
		left_mb_cb_1 <= sum_right_colum[15:8];
		left_mb_cb_2 <= sum_right_colum[23:16];
		left_mb_cb_3 <= sum_right_colum[31:24];
	end
	1:begin
		left_mb_cb_4 <= sum_right_colum[7:0];
		left_mb_cb_5 <= sum_right_colum[15:8];
		left_mb_cb_6 <= sum_right_colum[23:16];
		left_mb_cb_7 <= sum_right_colum[31:24];
	end
	endcase
end

always @(posedge clk or negedge rst_n)
if (!rst_n)begin
	left_mb_cr_0 <= 0;
	left_mb_cr_1 <= 0;
	left_mb_cr_2 <= 0;
	left_mb_cr_3 <= 0;
	left_mb_cr_4 <= 0;
	left_mb_cr_5 <= 0;
	left_mb_cr_6 <= 0;
	left_mb_cr_7 <= 0;
end
else if (ena && left_mb_cr_wr)begin
	case(blk4x4_counter[1])
	0:begin
		left_mb_cr_0 <= sum_right_colum[7:0];
		left_mb_cr_1 <= sum_right_colum[15:8];
		left_mb_cr_2 <= sum_right_colum[23:16];
		left_mb_cr_3 <= sum_right_colum[31:24];
	end
	1:begin
		left_mb_cr_4 <= sum_right_colum[7:0];
		left_mb_cr_5 <= sum_right_colum[15:8];
		left_mb_cr_6 <= sum_right_colum[23:16];
		left_mb_cr_7 <= sum_right_colum[31:24];
	end
	endcase
end

always @(posedge clk)
if (ena) begin
	casex ({blk4x4_counter[4], blk4x4_counter[2], blk4x4_counter[3],  blk4x4_counter[1]})
	'b0x00:begin
		left_mb_muxout_0 <= left_mb_luma_0;
		left_mb_muxout_1 <= left_mb_luma_1;
		left_mb_muxout_2 <= left_mb_luma_2;
		left_mb_muxout_3 <= left_mb_luma_3;
	end
	'b0x01:begin
		left_mb_muxout_0 <= left_mb_luma_4;
		left_mb_muxout_1 <= left_mb_luma_5;
		left_mb_muxout_2 <= left_mb_luma_6;
		left_mb_muxout_3 <= left_mb_luma_7;
	end
	'b0x10:begin
		left_mb_muxout_0 <= left_mb_luma_8;
		left_mb_muxout_1 <= left_mb_luma_9;
		left_mb_muxout_2 <= left_mb_luma_10;
		left_mb_muxout_3 <= left_mb_luma_11;
	end
	'b0x11:begin
		left_mb_muxout_0 <= left_mb_luma_12;
		left_mb_muxout_1 <= left_mb_luma_13;
		left_mb_muxout_2 <= left_mb_luma_14;
		left_mb_muxout_3 <= left_mb_luma_15;
	end
	'b1000:begin
		left_mb_muxout_0 <= left_mb_cb_0;
		left_mb_muxout_1 <= left_mb_cb_1;
		left_mb_muxout_2 <= left_mb_cb_2;
		left_mb_muxout_3 <= left_mb_cb_3;
	end
	'b1001:begin
		left_mb_muxout_0 <= left_mb_cb_4;
		left_mb_muxout_1 <= left_mb_cb_5;
		left_mb_muxout_2 <= left_mb_cb_6;
		left_mb_muxout_3 <= left_mb_cb_7;
	end
	'b1100:begin
		left_mb_muxout_0 <= left_mb_cr_0;
		left_mb_muxout_1 <= left_mb_cr_1;
		left_mb_muxout_2 <= left_mb_cr_2;
		left_mb_muxout_3 <= left_mb_cr_3;
	end
	default:begin
		left_mb_muxout_0 <= left_mb_cr_4;
		left_mb_muxout_1 <= left_mb_cr_5;
		left_mb_muxout_2 <= left_mb_cr_6;
		left_mb_muxout_3 <= left_mb_cr_7;
	end
	endcase
end

//
//up left
//
always @(posedge clk or negedge rst_n)
if (!rst_n) begin
	up_left_0 <= 0;
	up_left_1 <= 0;
	up_left_2 <= 0;
	up_left_3 <= 0;
	up_left_4 <= 0;
	up_left_5 <= 0;
	up_left_up_left_mb <= 0;
end
else if (ena && preload_counter >0)
	case(preload_counter)
		4:up_left_0 <= line_ram_luma_data[31:24]; //for blk1
		3:up_left_1 <= line_ram_luma_data[31:24]; //for blk4
		2:up_left_2 <= line_ram_luma_data[31:24]; //for blk5
	endcase
else if (ena && up_left_wr) begin
	case(blk4x4_counter[3:0])
		0:begin
			up_left_3 <= left_mb_luma_3;	//for blk2
			up_left_4 <= sum_bottom_row[31:24]; //for blk3
		end
		1:up_left_0 <= sum_bottom_row[31:24];	//for blk6
		2: begin
			up_left_3 <= left_mb_luma_7;       //for blk8
			up_left_5 <= sum_bottom_row[31:24]; //for blk9
		end
		3:up_left_4 <= sum_bottom_row[31:24]; // for blk12
		4:up_left_1 <= sum_bottom_row[31:24];  // for blk7
		6:up_left_0 <= sum_bottom_row[31:24];	//for blk13
		8:begin
			up_left_1 <= left_mb_luma_11;       //for blk 10
			up_left_2 <= sum_bottom_row[31:24]; //for blk11
		end
		9:up_left_5 <= sum_bottom_row[31:24]; //for blk14
		12:up_left_4 <= sum_bottom_row[31:24]; //for blk15
		15:up_left_up_left_mb <= line_ram_luma_data[31:24];	//15 for next mb blk0
	endcase
end


always @(posedge clk or negedge rst_n)		//for blk 0,2,8,10, update at blk 15,0,2,8
if (!rst_n) begin
	up_left_muxout <= 0;
end 
else if (ena)begin
	if (blk4x4_counter[4] && blk4x4_counter[2])
		up_left_muxout <= up_left_cr;
	else if (blk4x4_counter[4])
		up_left_muxout <= up_left_cb;
	else
	case(blk4x4_counter)
	0      : up_left_muxout <= up_left_up_left_mb;
	1,6,13 : up_left_muxout <= up_left_0;
	4,7,10 : up_left_muxout <= up_left_1;
	5,11   : up_left_muxout <= up_left_2;
	2,8    : up_left_muxout <= up_left_3;
	3,12,15: up_left_muxout <= up_left_4;
	default: up_left_muxout <= up_left_5;
	endcase
end

always @(posedge clk or negedge rst_n)
if (!rst_n)
	up_left_cb <= 0;
else if (ena && up_left_cb_wr)
	up_left_cb <= line_ram_cb_data[31:24];

always @(posedge clk or negedge rst_n)
if (!rst_n)
	up_left_cr <= 0;
else if (ena && up_left_cr_wr)
	up_left_cr <= line_ram_cr_data[31:24];

//
//up right
//
reg [7:0] up_right_ram_0;
reg [7:0] up_right_ram_1;
reg [7:0] up_right_ram_2;
reg [7:0] up_right_ram_3;

always @(posedge clk or negedge rst_n)
if (!rst_n) begin
	up_right_ram_0 <= 0;
	up_right_ram_1 <= 0;
	up_right_ram_2 <= 0;
	up_right_ram_3 <= 0;
end
else if (ena && preload_counter == 5)begin
	up_right_ram_0 <= line_ram_luma_data[7:0];
	up_right_ram_1 <= line_ram_luma_data[15:8];
	up_right_ram_2 <= line_ram_luma_data[23:16];
	up_right_ram_3 <= line_ram_luma_data[31:24];
end


//
//0  1  4  5   |  16 17 | 20 21
//2  3  6  7   |  18 19 | 22 23
//8  9  12 13
//10 11 14 15

always @(posedge clk or negedge rst_n)
if (!rst_n) begin
	up_right_muxout_0 <= 0;
	up_right_muxout_1 <= 0;
	up_right_muxout_2 <= 0;
	up_right_muxout_3 <= 0;
end
else if (ena)begin
	case(blk4x4_counter)
	0:begin
		up_right_muxout_0 <= up_mb_luma_4;
		up_right_muxout_1 <= up_mb_luma_5;
		up_right_muxout_2 <= up_mb_luma_6;
		up_right_muxout_3 <= up_mb_luma_7;
	end
	1:begin
		up_right_muxout_0 <= up_mb_luma_8;
		up_right_muxout_1 <= up_mb_luma_9;
		up_right_muxout_2 <= up_mb_luma_10;
		up_right_muxout_3 <= up_mb_luma_11;
	end
	2:begin
		up_right_muxout_0 <= up_mb_luma_4;
		up_right_muxout_1 <= up_mb_luma_5;
		up_right_muxout_2 <= up_mb_luma_6;
		up_right_muxout_3 <= up_mb_luma_7;		
	end
	3:begin
		up_right_muxout_0 <= up_mb_luma_7;
		up_right_muxout_1 <= up_mb_luma_7;
		up_right_muxout_2 <= up_mb_luma_7;
		up_right_muxout_3 <= up_mb_luma_7;
	end
	4:begin
		up_right_muxout_0 <= up_mb_luma_12;
		up_right_muxout_1 <= up_mb_luma_13;
		up_right_muxout_2 <= up_mb_luma_14;
		up_right_muxout_3 <= up_mb_luma_15;
	end
	5:begin
		if (top_right_blk_avail)begin
			up_right_muxout_0 <= up_right_ram_0;
			up_right_muxout_1 <= up_right_ram_1;
			up_right_muxout_2 <= up_right_ram_2;
			up_right_muxout_3 <= up_right_ram_3;
		end
		else begin
			up_right_muxout_0 <= up_mb_luma_15;
			up_right_muxout_1 <= up_mb_luma_15;
			up_right_muxout_2 <= up_mb_luma_15;
			up_right_muxout_3 <= up_mb_luma_15;
		end
	end
	6:begin
		up_right_muxout_0 <= up_mb_luma_12;
		up_right_muxout_1 <= up_mb_luma_13;
		up_right_muxout_2 <= up_mb_luma_14;
		up_right_muxout_3 <= up_mb_luma_15;		
	end
	7:begin
		up_right_muxout_0 <= up_mb_luma_15;
		up_right_muxout_1 <= up_mb_luma_15;
		up_right_muxout_2 <= up_mb_luma_15;
		up_right_muxout_3 <= up_mb_luma_15;
	end
	8:begin
		up_right_muxout_0 <= up_mb_luma_4;
		up_right_muxout_1 <= up_mb_luma_5;
		up_right_muxout_2 <= up_mb_luma_6;
		up_right_muxout_3 <= up_mb_luma_7;
	end
	9:begin
		up_right_muxout_0 <= up_mb_luma_8;
		up_right_muxout_1 <= up_mb_luma_9;
		up_right_muxout_2 <= up_mb_luma_10;
		up_right_muxout_3 <= up_mb_luma_11;
	end
	10:begin
		up_right_muxout_0 <= up_mb_luma_4;
		up_right_muxout_1 <= up_mb_luma_5;
		up_right_muxout_2 <= up_mb_luma_6;
		up_right_muxout_3 <= up_mb_luma_7;
	end
	11:begin
		up_right_muxout_0 <= up_mb_luma_7;
		up_right_muxout_1 <= up_mb_luma_7;
		up_right_muxout_2 <= up_mb_luma_7;
		up_right_muxout_3 <= up_mb_luma_7;		
	end
	12:begin
		up_right_muxout_0 <= up_mb_luma_12;
		up_right_muxout_1 <= up_mb_luma_13;
		up_right_muxout_2 <= up_mb_luma_14;
		up_right_muxout_3 <= up_mb_luma_15;
	end
	13:begin
		up_right_muxout_0 <= up_mb_luma_15;
		up_right_muxout_1 <= up_mb_luma_15;
		up_right_muxout_2 <= up_mb_luma_15;
		up_right_muxout_3 <= up_mb_luma_15;
	end
	14:begin
		up_right_muxout_0 <= up_mb_luma_12;
		up_right_muxout_1 <= up_mb_luma_13;
		up_right_muxout_2 <= up_mb_luma_14;
		up_right_muxout_3 <= up_mb_luma_15;
	end
	default:begin
		up_right_muxout_0 <= up_mb_luma_15;
		up_right_muxout_1 <= up_mb_luma_15;
		up_right_muxout_2 <= up_mb_luma_15;
		up_right_muxout_3 <= up_mb_luma_15;
	end
	endcase
end


wire chroma_use_up;
assign chroma_use_up = blk4x4_counter[4] && top_blk_avail && 
						intra_pred_mode_chroma == `Intra_chroma_DC && ( 
						~left_blk_avail || left_blk_avail && blk4x4_counter[1:0] != 2);

always @(posedge clk or negedge rst_n)
if (~rst_n) begin
	DC_sum_up <= 0;
end
else if (ena && top_blk_avail && is_I16_luma_DC && preload_counter == 1) begin
	DC_sum_up <= line_ram_luma_4pixel_sum + up_mb_luma_sum_0 + 
				up_mb_luma_sum_1 + up_mb_luma_sum_2;
end
else if (ena && top_blk_avail && is_I16_luma_DC) begin
	DC_sum_up <= DC_sum_up;
end
else if (ena && is_I16_luma_DC) begin
	DC_sum_up <= 0;
end
else if (ena && top_blk_avail && is_I4_luma_DC) begin
	case({blk4x4_counter[2], blk4x4_counter[0]})
	0:DC_sum_up <= up_mb_luma_sum_0;
	1:DC_sum_up <= up_mb_luma_sum_1; 
	2:DC_sum_up <= up_mb_luma_sum_2;
	3:DC_sum_up <= up_mb_luma_sum_3; 
	endcase
end
else if (ena && chroma_use_up && ~blk4x4_counter[2] && ~blk4x4_counter[0])begin
	DC_sum_up <= up_mb_cb_0 + up_mb_cb_1 + up_mb_cb_2 + up_mb_cb_3;
end
else if (ena && chroma_use_up && ~blk4x4_counter[2] && blk4x4_counter[0])begin
	DC_sum_up <= up_mb_cb_4 + up_mb_cb_5 + up_mb_cb_6 + up_mb_cb_7;
end
else if (ena && chroma_use_up && blk4x4_counter[2] && ~blk4x4_counter[0])begin
	DC_sum_up <= up_mb_cr_0 + up_mb_cr_1 + up_mb_cr_2 + up_mb_cr_3;
end
else if (ena && chroma_use_up && blk4x4_counter[2] && blk4x4_counter[0])begin
	DC_sum_up <= up_mb_cr_4 + up_mb_cr_5 + up_mb_cr_6 + up_mb_cr_7;
end
else if (ena)begin
	DC_sum_up <= 0;
end

wire chroma_use_left;
assign chroma_use_left = blk4x4_counter[4] && left_blk_avail && 
						intra_pred_mode_chroma == `Intra_chroma_DC && ( 
						~top_blk_avail || top_blk_avail && blk4x4_counter[1:0] != 1);

always @(posedge clk or negedge rst_n)
if (~rst_n)
	DC_sum_left <= 0;
else if (ena && left_blk_avail && is_I16_luma_DC && preload_counter == 1) begin
	DC_sum_left <= left_mb_luma_sum_0 + left_mb_luma_sum_1 + 
				   left_mb_luma_sum_2 + left_mb_luma_sum_3;
end
else if (ena && left_blk_avail  && is_I16_luma_DC) begin
	DC_sum_left <= DC_sum_left;
end
else if (ena && is_I16_luma_DC )begin
	DC_sum_left <= 0;
end
else if (ena && left_blk_avail && is_I4_luma_DC) begin
	case({blk4x4_counter[3], blk4x4_counter[1]})
	0:DC_sum_left <= left_mb_luma_sum_0;
	1:DC_sum_left <= left_mb_luma_sum_1; 
	2:DC_sum_left <= left_mb_luma_sum_2;
	3:DC_sum_left <= left_mb_luma_sum_3; 
	endcase
end
else if (ena && chroma_use_left && ~blk4x4_counter[2] && ~blk4x4_counter[1])begin
	DC_sum_left <= left_mb_cb_0 + left_mb_cb_1 + left_mb_cb_2 + left_mb_cb_3;
end
else if (ena && chroma_use_left && ~blk4x4_counter[2] && blk4x4_counter[1])begin
	DC_sum_left <= left_mb_cb_4 + left_mb_cb_5 + left_mb_cb_6 + left_mb_cb_7;
end
else if (ena && chroma_use_left && blk4x4_counter[2] && ~blk4x4_counter[1])begin
	DC_sum_left <= left_mb_cr_0 + left_mb_cr_1 + left_mb_cr_2 + left_mb_cr_3;
end
else if (ena && chroma_use_left && blk4x4_counter[2] && blk4x4_counter[1])begin
	DC_sum_left <= left_mb_cr_4 + left_mb_cr_5 + left_mb_cr_6 + left_mb_cr_7;
end
else if (ena) begin
	DC_sum_left <= 0;
end

always @(posedge clk)
if (ena && is_I16_luma_DC && top_blk_avail && left_blk_avail)begin
	DC_sum_round_value <= 16;
end
else if (ena && is_I16_luma_DC && (top_blk_avail || left_blk_avail))begin
	DC_sum_round_value <= 8;
end
else if (ena && ( is_chroma_DC && top_blk_avail && left_blk_avail && 
		~(^blk4x4_counter[1:0]) ||
   		is_I4_luma_DC && top_blk_avail && left_blk_avail ) )begin
	DC_sum_round_value <= 4;
end
else if (ena && ( (is_chroma_DC && (top_blk_avail || left_blk_avail)) ||
		(is_I4_luma_DC && top_blk_avail || left_blk_avail) ))begin
	DC_sum_round_value <= 2;
end
else if (ena) begin
	DC_sum_round_value <= 0;
end


/////////////////////////
//plane
reg signed [11:0] H;
reg signed [11:0] V;

reg [7:0] H_a;
reg [7:0] H_b;
reg [7:0] V_a;
reg [7:0] V_b;


//FFs
reg signed [13:0] H_sum;
reg signed [13:0] V_sum;
reg [8:0] a;
reg signed [14:0] seed_0;
reg signed [14:0] seed_1;
reg signed [14:0] seed_2;

always @(posedge clk or negedge rst_n)
if (!rst_n)begin
    H_sum <= 0;
    V_sum <= 0;
end
else if (precalc_ena)begin
	if (~(|blk4x4_counter) && precalc_counter == 7 || 
		|blk4x4_counter && precalc_counter == 3)begin
	    H_sum <= H;
	    V_sum <= V;
	end
	else begin
	    H_sum <= H_sum + H; //8* 9bit signed = 12 bit signed
	    V_sum <= V_sum + V;
	end
end

wire is_chroma_cb;
assign is_chroma_cb = blk4x4_counter == 16;
always @(*)
if(blk4x4_counter == 0) begin
	case (precalc_counter)
	8:begin
	    H_a <= up_mb_luma_15;    H_b <= up_left_up_left_mb;
	    V_a <= left_mb_luma_15;  V_b <= up_left_up_left_mb;
	end
	7:begin
	    H_a <= up_mb_luma_14;    H_b <= up_mb_luma_0;
	    V_a <= left_mb_luma_14;  V_b <= left_mb_luma_0;
	end
	6:begin
	    H_a <= up_mb_luma_13;    H_b <= up_mb_luma_1;
	    V_a <= left_mb_luma_13;  V_b <= left_mb_luma_1;
	end
	5:begin
	    H_a <= up_mb_luma_12;    H_b <= up_mb_luma_2;
	    V_a <= left_mb_luma_12;  V_b <= left_mb_luma_2;
	end
	4:begin
	    H_a <= up_mb_luma_11;    H_b <= up_mb_luma_3;
	    V_a <= left_mb_luma_11;  V_b <= left_mb_luma_3;
	end
	3:begin
	    H_a <= up_mb_luma_10;    H_b <= up_mb_luma_4;
	    V_a <= left_mb_luma_10;  V_b <= left_mb_luma_4;
	end
	2:begin
	    H_a <= up_mb_luma_9;     H_b <= up_mb_luma_5;
	    V_a <= left_mb_luma_9;   V_b <= left_mb_luma_5;
	end
	1:begin
	    H_a <= up_mb_luma_8;     H_b <= up_mb_luma_6;
	    V_a <= left_mb_luma_8;   V_b <= left_mb_luma_6;
	end
	default:begin
	    H_a <= 0;   H_b <= 0;
	    V_a <= 0;   V_b <= 0;
	end
	endcase
end
else begin
	case (precalc_counter)
	4:begin
	    H_a <= is_chroma_cb ? up_mb_cb_7 : up_mb_cr_7;
	   	V_a <= is_chroma_cb ? left_mb_cb_7 : left_mb_cr_7; 	
	 	H_b <= is_chroma_cb ? up_left_cb:up_left_cr;
		V_b <= is_chroma_cb ? up_left_cb:up_left_cr;
	end
	3:begin
	    H_a <= is_chroma_cb ? up_mb_cb_6 : up_mb_cr_6;    
	    V_a <= is_chroma_cb ? left_mb_cb_6 : left_mb_cr_6; 
		H_b <= is_chroma_cb ? up_mb_cb_0 : up_mb_cr_0; 
		V_b <= is_chroma_cb ? left_mb_cb_0 : left_mb_cr_0;
	end
	2:begin
	    H_a <= is_chroma_cb ? up_mb_cb_5 : up_mb_cr_5;    
	    V_a <= is_chroma_cb ? left_mb_cb_5 : left_mb_cr_5; 
		H_b <= is_chroma_cb ? up_mb_cb_1 : up_mb_cr_1; 
		V_b <= is_chroma_cb ? left_mb_cb_1 : left_mb_cr_1;
	end
	1:begin
	   	H_a <= is_chroma_cb ? up_mb_cb_4 : up_mb_cr_4;    
	    V_a <= is_chroma_cb ? left_mb_cb_4 : left_mb_cr_4; 
		H_b <= is_chroma_cb ? up_mb_cb_2 : up_mb_cr_2; 
		V_b <= is_chroma_cb ? left_mb_cb_2 : left_mb_cr_2;
	end
	default:begin
	    H_a <= 0;   H_b <= 0;
	    V_a <= 0;   V_b <= 0;
	end
	endcase
end

always @(posedge clk) begin
    H <= precalc_counter*(H_a - H_b); //max 9 bits signed
    V <= precalc_counter*(V_a - V_b);
end

always @(posedge clk or negedge rst_n)
if (!rst_n)begin
	a <= 0;
	b <= 0;
	c <= 0;
end
else if (precalc_ena && abc_latch)begin
	if (blk4x4_counter == 0) begin
		a <= (up_mb_luma_15 + left_mb_luma_15);
	    b <= ((H_sum <<< 2) + H_sum + 32)>>>6; //12 bit signed <<< 2 + 12 bit signed  + 32 = 15bit signed ,after >>> 6 ,is 9 bit signed
	    c <= ((V_sum <<< 2) + V_sum + 32)>>>6;
	end
	else begin
		a <= is_chroma_cb ? (up_mb_cb_7 + left_mb_cb_7) : (up_mb_cr_7 + left_mb_cr_7);
	    b <= ((H_sum <<< 4) + H_sum + 16)>>>5;
	    c <= ((V_sum <<< 4) + V_sum + 16)>>>5;	
	end
end


//seed for blk 0, 2, 4, 6, 8, 10, 12 ,14, 16, 18, 20, 22 is needed by intra_pred_PE
//|seed      |seed+1*b         |seed+2*b        |seed+3*b|seed+4*b |seed+5*b|seed+6*b|seed+7*b        
//|seed+1*c  |seed+1*b+1*c     |seed+2*b+1*c    |        |         |        |        |         
//|seed+2*c  |seed+1*b+2*c     |seed+2*b+2*c    |        |         |        |        |         
//|seed+3*c  |seed+1*b+3*c     |seed+2*b+3*c    |        |         |        |        | 
//
//0  1  4  5   |  16 17 | 20 21
//2  3  6  7   |  18 19 | 22 23
//8  9  12 13
//10 11 14 15

always @ (posedge clk or negedge rst_n)
if (!rst_n)begin
	seed_0 <= 0;
	seed_1 <= 0;
	seed_2 <= 0;
end
else if (ena) begin
	if(seed_latch && blk4x4_counter == 0)//generate seed for blk 0
		seed_0 <= {1'b0,a,4'b0} - {b,3'b0} - {c,3'b0} + {{3{b[10]}},b} + {{3{c[10]}},c};  //16 * a - 7 * b - 7 * c  16*9bit unsiged = 13 bit unsigned = 14bit signed , 7*b = 14 bit signed, result 15:bit signed
	else if(seed_latch) //generate seed for blk 16, 20
		seed_0 <= {1'b0,a,4'b0} - {b[10],b,2'b0} - {c[10],c,2'b0} + {{3{b[10]}},b} + {{3{c[10]}},c}; //16 * a - 3 * b - 3 * c
	else if (seed_wr)
		case (blk4x4_counter)
			0,2,8,16,20	:seed_0 <= sum3_reg+{{3{c[10]}},c};	//generate seed for blk 2, 8, 10, 18, 22 
			1,9			:seed_1 <= sum0_reg+{{3{b[10]}},b};  //generate seed for blk 4, 12
			3,11		:seed_2 <= sum0_reg+{{3{b[10]}},b};  //generate seed for blk 6, 14
		endcase
end

always @ (*) begin
	case (blk4x4_counter)
	4,12	:seed <= seed_1;
	6,14	:seed <= seed_2;
	default :seed <= seed_0;
	endcase
end

endmodule

/*
up_left related
>> (3-0)+(2-0)+(1-1)+(2-1)+(1-1)+(1-1)+(0-1)+(1-1)+(0-1)+(2-1)+(1-1)+(0-1)+(0-1)+(1-1)+(0-1)+(0-1)+(0-1)

ans = blk15 store:0:null 1:null 2:null 3:null 4:15 5:null out 4:15 new null 

     0

>> (3-0)+(2-0)+(1-1)+(2-1)+(1-1)+(1-1)+(0-1)+(1-1)+(0-1)+(2-1)+(1-1)+(0-1)+(0-1)+(1-1)+(0-1)+(0-1)

ans = blk14 store:0:null 1:null 2:null 3:null 4:15 5:14 out 0:14 new null 

     1

>> (3-0)+(2-0)+(1-1)+(2-1)+(1-1)+(1-1)+(0-1)+(1-1)+(0-1)+(2-1)+(1-1)+(0-1)+(0-1)+(1-1)+(0-1)
 
ans = blk13 store:0:13 1:null 2:null 3:null 4:15 5:14 out 0:13 new null 

     2

>> (3-0)+(2-0)+(1-1)+(2-1)+(1-1)+(1-1)+(0-1)+(1-1)+(0-1)+(2-1)+(1-1)+(0-1)+(0-1)+(1-1)

ans = blk12 store:0:13 1:null 2:null 3:null 4:12 5:14 out 4:12 new 15

     3

>> (3-0)+(2-0)+(1-1)+(2-1)+(1-1)+(1-1)+(0-1)+(1-1)+(0-1)+(2-1)+(1-1)+(0-1)+(0-1)

ans = blk11 store:0:13 1:null 2:11 3:null 4:12 5:14 out 2:11 new null

     3

>> (3-0)+(2-0)+(1-1)+(2-1)+(1-1)+(1-1)+(0-1)+(1-1)+(0-1)+(2-1)+(1-1)+(0-1)

ans = blk10 store:0:13 1:10 2:11 3:null 4:12 5:14 out 1:10 new null

     4

>> (3-0)+(2-0)+(1-1)+(2-1)+(1-1)+(1-1)+(0-1)+(1-1)+(0-1)+(2-1)+(1-1)

ans = blk9 store:0:13 1:10 2:11 3:null 4:12 5:9 out 5:9 new 14

     5

>> (3-0)+(2-0)+(1-1)+(2-1)+(1-1)+(1-1)+(0-1)+(1-1)+(0-1)+(2-1)

ans = blk8 store:0:13 1:null 2:null 3:8 4:12 5:9 out 3:8 new 10 11

     5

>> (3-0)+(2-0)+(1-1)+(2-1)+(1-1)+(1-1)+(0-1)+(1-1)+(0-1)

ans = blk7 store:0:13 1:7 2:null 3:8 4:12 5:9 out 1:7 new null

     4

>> (3-0)+(2-0)+(1-1)+(2-1)+(1-1)+(1-1)+(0-1)+(1-1)

ans = blk6 store:0:6 1:7 2:null 3:8 4:12 5:9 out 0:6 new 13

     5

>> (3-0)+(2-0)+(1-1)+(2-1)+(1-1)+(1-1)+(0-1)

ans = blk5 store:0:6 1:7 2:5 3:8 4:12 5:9 out 2:5 new null

     5

>> (3-0)+(2-0)+(1-1)+(2-1)+(1-1)+(1-1)

ans = blk4 store:0:6 1:4 2:5 3:8 4:12 5:9 out 1:4 new 7

     6

>> (3-0)+(2-0)+(1-1)+(2-1)+(1-1)

ans = blk3 store:0:6 1:4 2:5 3:8 4:3 5:9 out 4:3 new 12

     6

>> (3-0)+(2-0)+(1-1)+(2-1)

ans = blk2 store:0:6 1:4 2:5 3:2 4:3 out 3:2 new 8 9

     6

>> (3-0)+(2-0)+(1-1)

ans = blk1 store:0:1 1:4 2:5 3:2 4:3 out 0:1 new:6

     5

>> (3-0)+(2-0)

ans = blk0 store:0:1 1:4 2:5 out top_left new 2 3

     5

>> (3-0)

ans =  0 blk-1 sotre:   out :none new 1 4 5

     3

*/
