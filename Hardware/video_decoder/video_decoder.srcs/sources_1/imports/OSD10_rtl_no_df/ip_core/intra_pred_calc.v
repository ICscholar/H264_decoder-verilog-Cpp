// 根据不同预测模式,从周边像素获取参考样本值
// 计算预测平面,采样周边像素实现预测
// 计算方向预测,实现边缘延伸估计预计值
// 计算预测模样Sum值,支持DC预测
// 根据4x4块循环实现整个MB预测
// 输出16个预计值送往IDCT重建 residual

// mb represents a macroblock, 基本编码单元，代表视频帧中的一个子区域
`include "defines.v"

//proceed 1 colum at a time

module intra_pred_calc(
	input clk,
	input rst_n,
	input start,
	input [5:0] calc_ena,
	
	input [4:0] blk4x4_counter,
	input [3:0] mb_pred_mode,
	input [1:0] I16_pred_mode,
	input [3:0] I4_pred_mode,
	input [1:0] intra_pred_mode_chroma,
	
	input [12:0] b,
	input [12:0] c,
	input [14:0] seed,
	
	input [7:0] up_mb_muxout_0,
	input [7:0] up_mb_muxout_1,
	input [7:0] up_mb_muxout_2,
	input [7:0] up_mb_muxout_3,
	
	input [7:0] left_mb_muxout_0,
	input [7:0] left_mb_muxout_1,
	input [7:0] left_mb_muxout_2,
	input [7:0] left_mb_muxout_3,
	
	input [7:0] up_left_muxout,
	
	input [7:0] up_right_muxout_0,
	input [7:0] up_right_muxout_1,
	input [7:0] up_right_muxout_2,
	input [7:0] up_right_muxout_3,
	
	input [11:0] DC_sum_up,
	input [11:0] DC_sum_left,
	input [4:0] DC_sum_round_value,

	output [13:0] plane_sum_0_out,
	output [13:0] plane_sum_3_out,
	
	output reg [7:0] intra_pred_0,
	output reg [7:0] intra_pred_1,
	output reg [7:0] intra_pred_2,
	output reg [7:0] intra_pred_3,
	output reg [7:0] intra_pred_4,
	output reg [7:0] intra_pred_5,
	output reg [7:0] intra_pred_6,
	output reg [7:0] intra_pred_7,
	output reg [7:0] intra_pred_8,
	output reg [7:0] intra_pred_9,
	output reg [7:0] intra_pred_10,
	output reg [7:0] intra_pred_11,
	output reg [7:0] intra_pred_12,
	output reg [7:0] intra_pred_13,
	output reg [7:0] intra_pred_14,
	output reg [7:0] intra_pred_15
);

wire [12:0] DC_sum;//ff*16+ff*16+16=1FE0
wire [10:0] DC_sum_shift_2;
wire [9:0] DC_sum_shift_3;
wire [8:0] DC_sum_shift_4;
wire [7:0] DC_sum_shift_5;

//plane
wire signed [15:0] b_ext;
wire signed [15:0] c_ext;

assign b_ext = {b[12],b[12],b[12],b};
assign c_ext = {c[12],c[12],c[12],c};

//DC
assign DC_sum = DC_sum_up + DC_sum_left + DC_sum_round_value;
assign DC_sum_shift_2 = DC_sum >> 2;
assign DC_sum_shift_3 = DC_sum >> 3;
assign DC_sum_shift_4 = DC_sum >> 4;
assign DC_sum_shift_5 = DC_sum >> 5;

reg [7:0] multi_add0_adder0;
reg [7:0] multi_add0_adder1;
reg [7:0] multi_add0_adder2;
reg [1:0] multi_add0_round_value;
reg [9:0] multi_add0_sum;

reg [7:0] multi_add1_adder0;
reg [7:0] multi_add1_adder1;
reg [7:0] multi_add1_adder2;
reg [1:0] multi_add1_round_value;
reg [9:0] multi_add1_sum;

reg [7:0] multi_add2_adder0;
reg [7:0] multi_add2_adder1;
reg [7:0] multi_add2_adder2;
reg [1:0] multi_add2_round_value;
reg [9:0] multi_add2_sum;

reg [7:0] multi_add3_adder0;
reg [7:0] multi_add3_adder1;
reg [7:0] multi_add3_adder2;
reg [1:0] multi_add3_round_value;
reg [9:0] multi_add3_sum;

reg [7:0] multi_add4_adder0;
reg [7:0] multi_add4_adder1;
reg [7:0] multi_add4_adder2;
reg [1:0] multi_add4_round_value;
reg [9:0] multi_add4_sum;

reg [7:0] multi_add5_adder0;
reg [7:0] multi_add5_adder1;
reg [7:0] multi_add5_adder2;
reg [1:0] multi_add5_round_value;
reg [9:0] multi_add5_sum;

reg [7:0] multi_add6_adder0;
reg [7:0] multi_add6_adder1;
reg [7:0] multi_add6_adder2;
reg [1:0] multi_add6_round_value;
reg [9:0] multi_add6_sum;

reg [7:0] multi_add7_adder0;
reg [7:0] multi_add7_adder1;
reg [7:0] multi_add7_adder2;
reg [1:0] multi_add7_round_value;
reg [9:0] multi_add7_sum;

reg [7:0] multi_add8_adder0;
reg [7:0] multi_add8_adder1;
reg [7:0] multi_add8_adder2;
reg [1:0] multi_add8_round_value;
reg [9:0] multi_add8_sum;

reg [7:0] multi_add9_adder0;
reg [7:0] multi_add9_adder1;
reg [7:0] multi_add9_adder2;
reg [1:0] multi_add9_round_value;
reg [9:0] multi_add9_sum;

reg is_pred_mode_vertical;
reg is_pred_mode_horizontal;
reg is_pred_mode_DC;
reg is_pred_mode_plane;  
reg is_pred_mode_diag_down_left;
reg is_pred_mode_diag_down_right;
reg is_pred_mode_vertical_right;
reg is_pred_mode_horizontal_down;
reg is_pred_mode_vertical_left;
reg is_pred_mode_horizontal_up;

always @(*)
begin
	is_pred_mode_vertical <= ~blk4x4_counter[4] && 
								mb_pred_mode == `mb_pred_mode_I16MB && 
								I16_pred_mode == `Intra16x16_Vertical ||
				 				~blk4x4_counter[4] && 
								mb_pred_mode == `mb_pred_mode_I4MB &&
								I4_pred_mode == `Intra4x4_Vertical ||
								intra_pred_mode_chroma == `Intra_chroma_Vertical &&
								blk4x4_counter[4];

 is_pred_mode_horizontal <= ~blk4x4_counter[4] && 
								mb_pred_mode == `mb_pred_mode_I16MB && 
								I16_pred_mode == `Intra16x16_Horizontal ||
				 				~blk4x4_counter[4] && 
								mb_pred_mode == `mb_pred_mode_I4MB &&
								I4_pred_mode == `Intra4x4_Horizontal ||
								intra_pred_mode_chroma == `Intra_chroma_Horizontal &&
								blk4x4_counter[4];

 is_pred_mode_DC <= mb_pred_mode == `mb_pred_mode_I4MB && 
								I4_pred_mode == `Intra4x4_DC && 
								~blk4x4_counter[4] || 
								mb_pred_mode == `mb_pred_mode_I16MB && 
								I16_pred_mode == `Intra16x16_DC && 
								~blk4x4_counter[4] ||
								intra_pred_mode_chroma == `Intra_chroma_DC && 
								blk4x4_counter[4];


 is_pred_mode_plane <= mb_pred_mode == `mb_pred_mode_I16MB && 
								I16_pred_mode == `Intra16x16_Plane && 
								~blk4x4_counter[4] ||
								intra_pred_mode_chroma == `Intra_chroma_Plane && 
								blk4x4_counter[4];

 is_pred_mode_diag_down_left <= I4_pred_mode == `Intra4x4_Diagonal_Down_Left && 
									~blk4x4_counter[4]; 

 is_pred_mode_diag_down_right <= I4_pred_mode == `Intra4x4_Diagonal_Down_Right && 
									~blk4x4_counter[4]; 

 is_pred_mode_vertical_right <= I4_pred_mode == `Intra4x4_Vertical_Right && 
									~blk4x4_counter[4]; 

 is_pred_mode_horizontal_down <= I4_pred_mode == `Intra4x4_Horizontal_Down && 
									~blk4x4_counter[4];

 is_pred_mode_vertical_left <= I4_pred_mode == `Intra4x4_Vertical_Left && 
									~blk4x4_counter[4];

 is_pred_mode_horizontal_up <= I4_pred_mode == `Intra4x4_Horizontal_Up && 
									~blk4x4_counter[4];
end


always @(*) begin
	multi_add0_sum = multi_add0_adder0 + multi_add0_adder1 + {multi_add0_adder2, 1'b0} + multi_add0_round_value;
	multi_add1_sum = multi_add1_adder0 + multi_add1_adder1 + {multi_add1_adder2, 1'b0} + multi_add1_round_value;
	multi_add2_sum = multi_add2_adder0 + multi_add2_adder1 + {multi_add2_adder2, 1'b0} + multi_add2_round_value;
	multi_add3_sum = multi_add3_adder0 + multi_add3_adder1 + {multi_add3_adder2, 1'b0} + multi_add3_round_value;
	multi_add4_sum = multi_add4_adder0 + multi_add4_adder1 + {multi_add4_adder2, 1'b0} + multi_add4_round_value;
	multi_add5_sum = multi_add5_adder0 + multi_add5_adder1 + {multi_add5_adder2, 1'b0} + multi_add5_round_value;
	multi_add6_sum = multi_add6_adder0 + multi_add6_adder1 + {multi_add6_adder2, 1'b0} + multi_add6_round_value;
	multi_add7_sum = multi_add7_adder0 + multi_add7_adder1 + {multi_add7_adder2, 1'b0} + multi_add7_round_value;
	multi_add8_sum = multi_add8_adder0 + multi_add8_adder1 + {multi_add8_adder2, 1'b0} + multi_add8_round_value;
	multi_add9_sum = multi_add9_adder0 + multi_add9_adder1 + {multi_add9_adder2, 1'b0} + multi_add9_round_value;
end

always @(posedge clk) begin
	multi_add0_adder0 <= 0; 
	multi_add0_adder1 <= 0;
	multi_add0_adder2 <= 0; 
	multi_add1_adder0 <= 0;
	multi_add1_adder1 <= 0; 
	multi_add1_adder2 <= 0;
	multi_add2_adder0 <= 0; 
	multi_add2_adder1 <= 0;
	multi_add2_adder2 <= 0; 
	multi_add3_adder0 <= 0;
	multi_add3_adder1 <= 0; 
	multi_add3_adder2 <= 0;
	multi_add4_adder0 <= 0; 
	multi_add4_adder1 <= 0;
	multi_add4_adder2 <= 0; 
	multi_add5_adder0 <= 0; 
	multi_add5_adder1 <= 0;
	multi_add5_adder2 <= 0; 
	multi_add6_adder0 <= 0;
	multi_add6_adder1 <= 0; 
	multi_add6_adder2 <= 0;
	multi_add7_adder0 <= 0; 
	multi_add7_adder1 <= 0;
	multi_add7_adder2 <= 0;
	multi_add8_adder0 <= 0; 
	multi_add8_adder1 <= 0;
	multi_add8_adder2 <= 0;
	multi_add9_adder0 <= 0; 
	multi_add9_adder1 <= 0;
	multi_add9_adder2 <= 0;
	multi_add0_round_value <= 1;
	multi_add1_round_value <= 1;
	multi_add2_round_value <= 1;
	multi_add3_round_value <= 1;
	multi_add4_round_value <= 1;
	multi_add5_round_value <= 1;
	multi_add6_round_value <= 1;
	multi_add7_round_value <= 1;
	multi_add8_round_value <= 1;
	multi_add9_round_value <= 1;
	if (is_pred_mode_diag_down_left)begin
		multi_add0_adder0 <= up_mb_muxout_0; 
		multi_add0_adder1 <= up_mb_muxout_2;
		multi_add0_adder2 <= up_mb_muxout_1; 
		multi_add1_adder0 <= up_mb_muxout_1;
		multi_add1_adder1 <= up_mb_muxout_3; 
		multi_add1_adder2 <= up_mb_muxout_2;
		multi_add2_adder0 <= up_mb_muxout_2; 
		multi_add2_adder1 <= up_right_muxout_0;
		multi_add2_adder2 <= up_mb_muxout_3; 
		multi_add3_adder0 <= up_mb_muxout_3;
		multi_add3_adder1 <= up_right_muxout_1; 
		multi_add3_adder2 <= up_right_muxout_0;
		multi_add0_round_value <= 2;
		multi_add1_round_value <= 2;
		multi_add2_round_value <= 2;
		multi_add3_round_value <= 2;				
		multi_add4_adder0 <= up_right_muxout_0;
		multi_add4_adder1 <= up_right_muxout_2; 
		multi_add4_adder2 <= up_right_muxout_1;
		multi_add5_adder0 <= up_right_muxout_1; 
		multi_add5_adder1 <= up_right_muxout_3;
		multi_add5_adder2 <= up_right_muxout_2; 
		multi_add6_adder0 <= up_right_muxout_2;
		multi_add6_adder1 <= up_right_muxout_3;
		multi_add6_adder2 <= up_right_muxout_3;		
		multi_add4_round_value <= 2;
		multi_add5_round_value <= 2;
		multi_add6_round_value <= 2;				
	end
	else if (is_pred_mode_diag_down_right)begin
		multi_add0_adder0 <= left_mb_muxout_0; 
		multi_add0_adder1 <= up_mb_muxout_0;
		multi_add0_adder2 <= up_left_muxout; 
		multi_add1_adder0 <= up_mb_muxout_1; 
		multi_add1_adder1 <= up_left_muxout;
		multi_add1_adder2 <= up_mb_muxout_0; 
		multi_add2_adder0 <= up_mb_muxout_0;
		multi_add2_adder1 <= up_mb_muxout_2; 
		multi_add2_adder2 <= up_mb_muxout_1;
		multi_add3_adder0 <= up_mb_muxout_1; 
		multi_add3_adder1 <= up_mb_muxout_3;
		multi_add3_adder2 <= up_mb_muxout_2;
		multi_add0_round_value <= 2;
		multi_add1_round_value <= 2;
		multi_add2_round_value <= 2;
		multi_add3_round_value <= 2;
		multi_add4_adder0 <= left_mb_muxout_1; 
		multi_add4_adder1 <= up_left_muxout;
		multi_add4_adder2 <= left_mb_muxout_0; 
		multi_add5_adder0 <= left_mb_muxout_0;
		multi_add5_adder1 <= left_mb_muxout_2; 
		multi_add5_adder2 <= left_mb_muxout_1;
		multi_add6_adder0 <= left_mb_muxout_1; 
		multi_add6_adder1 <= left_mb_muxout_3;
		multi_add6_adder2 <= left_mb_muxout_2;
		multi_add4_round_value <= 2;
		multi_add5_round_value <= 2;
		multi_add6_round_value <= 2;		
	end
	else if (is_pred_mode_vertical_right) begin
		multi_add0_adder0 <= up_left_muxout; 
		multi_add0_adder1 <= up_mb_muxout_0;
		multi_add0_adder2 <= 0; 
		multi_add1_adder0 <= up_mb_muxout_0;
		multi_add1_adder1 <= up_mb_muxout_1; 
		multi_add1_adder2 <= 0;
		multi_add2_adder0 <= up_mb_muxout_1; 
		multi_add2_adder1 <= up_mb_muxout_2;
		multi_add2_adder2 <= 0; 
		multi_add3_adder0 <= up_mb_muxout_2;
		multi_add3_adder1 <= up_mb_muxout_3; 
		multi_add3_adder2 <= 0;
		multi_add4_adder0 <= left_mb_muxout_0; 
		multi_add4_adder1 <= up_mb_muxout_0;
		multi_add4_adder2 <= up_left_muxout; 
		multi_add5_adder0 <= up_mb_muxout_1; 
		multi_add5_adder1 <= up_left_muxout;
		multi_add5_adder2 <= up_mb_muxout_0; 
		multi_add6_adder0 <= up_mb_muxout_0;
		multi_add6_adder1 <= up_mb_muxout_2; 
		multi_add6_adder2 <= up_mb_muxout_1;
		multi_add7_adder0 <= up_mb_muxout_1; 
		multi_add7_adder1 <= up_mb_muxout_3;
		multi_add7_adder2 <= up_mb_muxout_2;		
		multi_add4_round_value <= 2;
		multi_add5_round_value <= 2;
		multi_add6_round_value <= 2;
		multi_add7_round_value <= 2;
		multi_add8_adder0 <= up_left_muxout;
		multi_add8_adder1 <= left_mb_muxout_1; 
		multi_add8_adder2 <= left_mb_muxout_0;
		multi_add9_adder0 <= left_mb_muxout_0; 
		multi_add9_adder1 <= left_mb_muxout_2;
		multi_add9_adder2 <= left_mb_muxout_1; 
		multi_add8_round_value <= 2;
		multi_add9_round_value <= 2;
	end
	else if (is_pred_mode_horizontal_down) begin
		multi_add0_adder0 <= up_left_muxout; 
		multi_add0_adder1 <= left_mb_muxout_0;
		multi_add0_adder2 <= 0; 
		multi_add1_adder0 <= left_mb_muxout_0;
		multi_add1_adder1 <= left_mb_muxout_1; 
		multi_add1_adder2 <= 0;
		multi_add2_adder0 <= left_mb_muxout_1; 
		multi_add2_adder1 <= left_mb_muxout_2;
		multi_add2_adder2 <= 0; 
		multi_add3_adder0 <= left_mb_muxout_2;
		multi_add3_adder1 <= left_mb_muxout_3; 
		multi_add3_adder2 <= 0;
		multi_add4_adder0 <= left_mb_muxout_0; 
		multi_add4_adder1 <= up_mb_muxout_0;
		multi_add4_adder2 <= up_left_muxout; 
		multi_add5_adder0 <= left_mb_muxout_1; 
		multi_add5_adder1 <= up_left_muxout;
		multi_add5_adder2 <= left_mb_muxout_0; 
		multi_add6_adder0 <= left_mb_muxout_0;
		multi_add6_adder1 <= left_mb_muxout_2; 
		multi_add6_adder2 <= left_mb_muxout_1;
		multi_add7_adder0 <= left_mb_muxout_1; 
		multi_add7_adder1 <= left_mb_muxout_3;
		multi_add7_adder2 <= left_mb_muxout_2;		
		multi_add4_round_value <= 2;
		multi_add5_round_value <= 2;
		multi_add6_round_value <= 2;
		multi_add7_round_value <= 2;
		multi_add8_adder0 <= up_left_muxout;
		multi_add8_adder1 <= up_mb_muxout_1; 
		multi_add8_adder2 <= up_mb_muxout_0; 
		multi_add9_adder0 <= up_mb_muxout_0;
		multi_add9_adder1 <= up_mb_muxout_2; 
		multi_add9_adder2 <= up_mb_muxout_1; 
		multi_add8_round_value <= 2;
		multi_add9_round_value <= 2;
	end
	else if (is_pred_mode_vertical_left) begin
		multi_add0_adder0 <= up_mb_muxout_0; 
		multi_add0_adder1 <= up_mb_muxout_1;
		multi_add0_adder2 <= 0; 
		multi_add1_adder0 <= up_mb_muxout_1;
		multi_add1_adder1 <= up_mb_muxout_2; 
		multi_add1_adder2 <= 0;
		multi_add2_adder0 <= up_mb_muxout_2; 
		multi_add2_adder1 <= up_mb_muxout_3;
		multi_add2_adder2 <= 0; 
		multi_add3_adder0 <= up_mb_muxout_3;
		multi_add3_adder1 <= up_right_muxout_0; 
		multi_add3_adder2 <= 0;
		multi_add4_adder0 <= up_mb_muxout_0; 
		multi_add4_adder1 <= up_mb_muxout_2;
		multi_add4_adder2 <= up_mb_muxout_1; 
		multi_add5_adder0 <= up_mb_muxout_1; 
		multi_add5_adder1 <= up_mb_muxout_3;
		multi_add5_adder2 <= up_mb_muxout_2; 
		multi_add6_adder0 <= up_right_muxout_0;
		multi_add6_adder1 <= up_mb_muxout_2; 
		multi_add6_adder2 <= up_mb_muxout_3;
		multi_add7_adder0 <= up_mb_muxout_3; 
		multi_add7_adder1 <= up_right_muxout_1;
		multi_add7_adder2 <= up_right_muxout_0;		
		multi_add4_round_value <= 2;
		multi_add5_round_value <= 2;
		multi_add6_round_value <= 2;
		multi_add7_round_value <= 2;
		multi_add8_adder0 <= up_right_muxout_0;
		multi_add8_adder1 <= up_right_muxout_1; 
		multi_add8_adder2 <= 0;
		multi_add9_adder0 <= up_right_muxout_0; 
		multi_add9_adder1 <= up_right_muxout_2;
		multi_add9_adder2 <= up_right_muxout_1; 		
		multi_add9_round_value <= 2;
	end
	else begin
		multi_add0_adder0 <= left_mb_muxout_0; 
		multi_add0_adder1 <= left_mb_muxout_1;
		multi_add0_adder2 <= 0; 
		multi_add1_adder0 <= left_mb_muxout_1;
		multi_add1_adder1 <= left_mb_muxout_2; 
		multi_add1_adder2 <= 0;
		multi_add2_adder0 <= left_mb_muxout_2; 
		multi_add2_adder1 <= left_mb_muxout_3;
		multi_add2_adder2 <= 0; 
		multi_add3_adder0 <= left_mb_muxout_3;
		multi_add3_adder1 <= left_mb_muxout_3; 
		multi_add3_adder2 <= 0;
		multi_add4_adder0 <= left_mb_muxout_0; 
		multi_add4_adder1 <= left_mb_muxout_2;
		multi_add4_adder2 <= left_mb_muxout_1; 
		multi_add5_adder0 <= left_mb_muxout_1; 
		multi_add5_adder1 <= left_mb_muxout_3;
		multi_add5_adder2 <= left_mb_muxout_2; 
		multi_add6_adder0 <= left_mb_muxout_2;
		multi_add6_adder1 <= left_mb_muxout_3; 
		multi_add6_adder2 <= left_mb_muxout_3;
		multi_add7_adder0 <= left_mb_muxout_3; 
		multi_add7_adder1 <= 0;
		multi_add7_adder2 <= 0;		
		multi_add4_round_value <= 2;
		multi_add5_round_value <= 2;
		multi_add6_round_value <= 2;
		multi_add7_round_value <= 0;		
	end
end

//plane
reg signed [15:0] plane_sum_0; 
reg signed [15:0] plane_sum_1; 
reg signed [15:0] plane_sum_2; 
reg signed [15:0] plane_sum_3; 

reg [7:0] plane_out_0; 
reg [7:0] plane_out_1; 
reg [7:0] plane_out_2; 
reg [7:0] plane_out_3; 

reg signed [10:0] plane_out_0_shift; 
reg signed [10:0] plane_out_1_shift; 
reg signed [10:0] plane_out_2_shift; 
reg signed [10:0] plane_out_3_shift;

assign plane_sum_0_out = plane_sum_0;
assign plane_sum_3_out = plane_sum_3;
wire signed [15:0] seed_signed;
assign seed_signed = {1'b0,seed};
always @(posedge clk or negedge rst_n)
if (~rst_n) begin
	plane_sum_0 <= 0;
	plane_sum_1 <= 0;
	plane_sum_2 <= 0;
	plane_sum_3 <= 0;
end
else if (calc_ena[1] && ~blk4x4_counter[0])begin
	plane_sum_0 <= seed_signed;
	plane_sum_1 <= seed_signed + c_ext;
	plane_sum_2 <= seed_signed + (c_ext <<< 1);
	plane_sum_3 <= seed_signed + (c_ext <<< 1) + c_ext;
end
else if (|calc_ena[4:1])begin
	plane_sum_0 <= plane_sum_0 + b_ext;
	plane_sum_1 <= plane_sum_1 + b_ext;
	plane_sum_2 <= plane_sum_2 + b_ext;
	plane_sum_3 <= plane_sum_3 + b_ext;
end

always @(*) begin
	plane_out_0_shift = (plane_sum_0 + 16) >>> 5;
	plane_out_1_shift = (plane_sum_1 + 16) >>> 5;
	plane_out_2_shift = (plane_sum_2 + 16) >>> 5;
	plane_out_3_shift = (plane_sum_3 + 16) >>> 5;
end


always @(*) begin
	plane_out_0 = plane_out_0_shift < 0 ? 0 : (plane_out_0_shift > 255 ? 255 : plane_out_0_shift);
	plane_out_1 = plane_out_1_shift < 0 ? 0 : (plane_out_1_shift > 255 ? 255 : plane_out_1_shift);
	plane_out_2 = plane_out_2_shift < 0 ? 0 : (plane_out_2_shift > 255 ? 255 : plane_out_2_shift);
	plane_out_3 = plane_out_3_shift < 0 ? 0 : (plane_out_3_shift > 255 ? 255 : plane_out_3_shift);
end

always @(posedge clk or negedge rst_n)
if (~rst_n) begin
	intra_pred_0 <= 0;
	intra_pred_1 <= 0;
	intra_pred_2 <= 0;
	intra_pred_3 <= 0;
	intra_pred_4 <= 0;
	intra_pred_5 <= 0;
	intra_pred_6 <= 0;
	intra_pred_7 <= 0;
	intra_pred_8 <= 0;
	intra_pred_9 <= 0;
	intra_pred_10 <= 0;
	intra_pred_11 <= 0;
	intra_pred_12 <= 0;
	intra_pred_13 <= 0;
	intra_pred_14 <= 0;
	intra_pred_15 <= 0;
end
else if (calc_ena[0]) begin
	if (is_pred_mode_vertical) begin
		intra_pred_0 <= up_mb_muxout_0;
		intra_pred_1 <= up_mb_muxout_1;
		intra_pred_2 <= up_mb_muxout_2;
		intra_pred_3 <= up_mb_muxout_3;
		intra_pred_4 <= up_mb_muxout_0;
		intra_pred_5 <= up_mb_muxout_1;
		intra_pred_6 <= up_mb_muxout_2;
		intra_pred_7 <= up_mb_muxout_3;
		intra_pred_8 <= up_mb_muxout_0;
		intra_pred_9 <= up_mb_muxout_1;
		intra_pred_10 <= up_mb_muxout_2;
		intra_pred_11 <= up_mb_muxout_3;
		intra_pred_12 <= up_mb_muxout_0;
		intra_pred_13 <= up_mb_muxout_1;
		intra_pred_14 <= up_mb_muxout_2;
		intra_pred_15 <= up_mb_muxout_3;
	end
	else if (is_pred_mode_horizontal)begin
		intra_pred_0 <= left_mb_muxout_0;
		intra_pred_1 <= left_mb_muxout_0;
		intra_pred_2 <= left_mb_muxout_0;
		intra_pred_3 <= left_mb_muxout_0;
		intra_pred_4 <= left_mb_muxout_1;
		intra_pred_5 <= left_mb_muxout_1;
		intra_pred_6 <= left_mb_muxout_1;
		intra_pred_7 <= left_mb_muxout_1;
		intra_pred_8 <= left_mb_muxout_2;
		intra_pred_9 <= left_mb_muxout_2;
		intra_pred_10 <= left_mb_muxout_2;
		intra_pred_11 <= left_mb_muxout_2;
		intra_pred_12 <= left_mb_muxout_3;
		intra_pred_13 <= left_mb_muxout_3;
		intra_pred_14 <= left_mb_muxout_3;
		intra_pred_15 <= left_mb_muxout_3;
	end
	else if (is_pred_mode_DC)begin
		if (DC_sum_round_value[1])begin//number is 4
			intra_pred_0 <= DC_sum_shift_2;
			intra_pred_1 <= DC_sum_shift_2;
			intra_pred_2 <= DC_sum_shift_2;
			intra_pred_3 <= DC_sum_shift_2;
			intra_pred_4 <= DC_sum_shift_2;
			intra_pred_5 <= DC_sum_shift_2;
			intra_pred_6 <= DC_sum_shift_2;
			intra_pred_7 <= DC_sum_shift_2;
			intra_pred_8 <= DC_sum_shift_2;
			intra_pred_9 <= DC_sum_shift_2;
			intra_pred_10 <= DC_sum_shift_2;
			intra_pred_11 <= DC_sum_shift_2;
			intra_pred_12 <= DC_sum_shift_2;
			intra_pred_13 <= DC_sum_shift_2;
			intra_pred_14 <= DC_sum_shift_2;
			intra_pred_15 <= DC_sum_shift_2;
		end
		else if (DC_sum_round_value[2])begin//number is 8
			intra_pred_0 <= DC_sum_shift_3;
			intra_pred_1 <= DC_sum_shift_3;
			intra_pred_2 <= DC_sum_shift_3;
			intra_pred_3 <= DC_sum_shift_3;
			intra_pred_4 <= DC_sum_shift_3;
			intra_pred_5 <= DC_sum_shift_3;
			intra_pred_6 <= DC_sum_shift_3;
			intra_pred_7 <= DC_sum_shift_3;
			intra_pred_8 <= DC_sum_shift_3;
			intra_pred_9 <= DC_sum_shift_3;
			intra_pred_10 <= DC_sum_shift_3;
			intra_pred_11 <= DC_sum_shift_3;
			intra_pred_12 <= DC_sum_shift_3;
			intra_pred_13 <= DC_sum_shift_3;
			intra_pred_14 <= DC_sum_shift_3;
			intra_pred_15 <= DC_sum_shift_3;
		end
		else if (DC_sum_round_value[3])begin//number is 16
			intra_pred_0 <= DC_sum_shift_4;
			intra_pred_1 <= DC_sum_shift_4;
			intra_pred_2 <= DC_sum_shift_4;
			intra_pred_3 <= DC_sum_shift_4;
			intra_pred_4 <= DC_sum_shift_4;
			intra_pred_5 <= DC_sum_shift_4;
			intra_pred_6 <= DC_sum_shift_4;
			intra_pred_7 <= DC_sum_shift_4;
			intra_pred_8 <= DC_sum_shift_4;
			intra_pred_9 <= DC_sum_shift_4;
			intra_pred_10 <= DC_sum_shift_4;
			intra_pred_11 <= DC_sum_shift_4;
			intra_pred_12 <= DC_sum_shift_4;
			intra_pred_13 <= DC_sum_shift_4;
			intra_pred_14 <= DC_sum_shift_4;
			intra_pred_15 <= DC_sum_shift_4;
		end
		else if (DC_sum_round_value[4])begin//number is 32
			intra_pred_0 <= DC_sum_shift_5;
			intra_pred_1 <= DC_sum_shift_5;
			intra_pred_2 <= DC_sum_shift_5;
			intra_pred_3 <= DC_sum_shift_5;
			intra_pred_4 <= DC_sum_shift_5;
			intra_pred_5 <= DC_sum_shift_5;
			intra_pred_6 <= DC_sum_shift_5;
			intra_pred_7 <= DC_sum_shift_5;
			intra_pred_8 <= DC_sum_shift_5;
			intra_pred_9 <= DC_sum_shift_5;
			intra_pred_10 <= DC_sum_shift_5;
			intra_pred_11 <= DC_sum_shift_5;
			intra_pred_12 <= DC_sum_shift_5;
			intra_pred_13 <= DC_sum_shift_5;
			intra_pred_14 <= DC_sum_shift_5;
			intra_pred_15 <= DC_sum_shift_5;
		end
		else begin //number is 0
			intra_pred_0 <= 128;
			intra_pred_1 <= 128;
			intra_pred_2 <= 128;
			intra_pred_3 <= 128;
			intra_pred_4 <= 128;
			intra_pred_5 <= 128;
			intra_pred_6 <= 128;
			intra_pred_7 <= 128;
			intra_pred_8 <= 128;
			intra_pred_9 <= 128;
			intra_pred_10 <= 128;
			intra_pred_11 <= 128;
			intra_pred_12 <= 128;
			intra_pred_13 <= 128;
			intra_pred_14 <= 128;
			intra_pred_15 <= 128;
		end
	end
	else if (is_pred_mode_diag_down_left)begin
		intra_pred_0 <= multi_add0_sum >> 2;
		intra_pred_1 <= multi_add1_sum >> 2;
		intra_pred_4 <= multi_add1_sum >> 2;
		intra_pred_2 <= multi_add2_sum >> 2;
		intra_pred_5 <= multi_add2_sum >> 2;
		intra_pred_8 <= multi_add2_sum >> 2;
		intra_pred_3 <= multi_add3_sum >> 2;
		intra_pred_6 <= multi_add3_sum >> 2;
		intra_pred_9 <= multi_add3_sum >> 2;
		intra_pred_12 <= multi_add3_sum >> 2;
		intra_pred_7 <= multi_add4_sum >> 2;
		intra_pred_10 <= multi_add4_sum >> 2;
		intra_pred_13 <= multi_add4_sum >> 2;
		intra_pred_11 <= multi_add5_sum >> 2;
		intra_pred_14 <= multi_add5_sum >> 2;
		intra_pred_15 <= multi_add6_sum >> 2;
	end
	else if (is_pred_mode_diag_down_right)begin
		intra_pred_0 <= multi_add0_sum >> 2;
		intra_pred_5 <= multi_add0_sum >> 2;
		intra_pred_10 <= multi_add0_sum >> 2;
		intra_pred_15 <= multi_add0_sum >> 2;
		intra_pred_1 <= multi_add1_sum >> 2;
		intra_pred_6 <= multi_add1_sum >> 2;
		intra_pred_11 <= multi_add1_sum >> 2;
		intra_pred_2 <= multi_add2_sum >> 2;
		intra_pred_7 <= multi_add2_sum >> 2;
		intra_pred_3 <= multi_add3_sum >> 2;
		intra_pred_4 <= multi_add4_sum >> 2;
		intra_pred_9 <= multi_add4_sum >> 2;
		intra_pred_14 <= multi_add4_sum >> 2;
		intra_pred_8 <= multi_add5_sum >> 2;
		intra_pred_13 <= multi_add5_sum >> 2;
		intra_pred_12 <= multi_add6_sum >> 2;
	end
	else if (is_pred_mode_vertical_right)begin
		intra_pred_0 <= multi_add0_sum >> 1;
		intra_pred_1 <= multi_add1_sum >> 1;
		intra_pred_2 <= multi_add2_sum >> 1;
		intra_pred_3 <= multi_add3_sum >> 1;
		intra_pred_4 <= multi_add4_sum >> 2;
		intra_pred_5 <= multi_add5_sum >> 2;
		intra_pred_6 <= multi_add6_sum >> 2;
		intra_pred_7 <= multi_add7_sum >> 2;
		intra_pred_8 <= multi_add8_sum >> 2;
		intra_pred_9 <= multi_add0_sum >> 1;
		intra_pred_10 <= multi_add1_sum >> 1;
		intra_pred_11 <= multi_add2_sum >> 1;
		intra_pred_12 <= multi_add9_sum >> 2;
		intra_pred_13 <= multi_add4_sum >> 2;
		intra_pred_14 <= multi_add5_sum >> 2;
		intra_pred_15 <= multi_add6_sum >> 2;
	end
	else if (is_pred_mode_horizontal_down)begin
		intra_pred_0 <= multi_add0_sum >> 1;
		intra_pred_1 <= multi_add4_sum >> 2;
		intra_pred_4 <= multi_add1_sum >> 1;
		intra_pred_5 <= multi_add5_sum >> 2;
		intra_pred_8 <= multi_add2_sum >> 1;
		intra_pred_9 <= multi_add6_sum >> 2;
		intra_pred_12 <= multi_add3_sum >> 1;
		intra_pred_13 <= multi_add7_sum >> 2;
		intra_pred_2 <= multi_add8_sum >> 2;
		intra_pred_3 <= multi_add9_sum >> 2;
		intra_pred_6 <= multi_add0_sum >> 1;
		intra_pred_7 <= multi_add4_sum >> 2;
		intra_pred_10 <= multi_add1_sum >> 1;
		intra_pred_11 <= multi_add5_sum >> 2;
		intra_pred_14 <= multi_add2_sum >> 1;
		intra_pred_15 <= multi_add6_sum >> 2;
	end
	else if (is_pred_mode_vertical_left)begin
		intra_pred_0 <= multi_add0_sum >> 1;
		intra_pred_1 <= multi_add1_sum >> 1;
		intra_pred_2 <= multi_add2_sum >> 1;
		intra_pred_3 <= multi_add3_sum >> 1;
		intra_pred_4 <= multi_add4_sum >> 2;
		intra_pred_5 <= multi_add5_sum >> 2;
		intra_pred_6 <= multi_add6_sum >> 2;
		intra_pred_7 <= multi_add7_sum >> 2;
		intra_pred_8 <= multi_add1_sum >> 1;
		intra_pred_9 <= multi_add2_sum >> 1;
		intra_pred_10 <= multi_add3_sum >> 1;
		intra_pred_11 <= multi_add8_sum >> 1;
		intra_pred_12 <= multi_add5_sum >> 2;
		intra_pred_13 <= multi_add6_sum >> 2;
		intra_pred_14 <= multi_add7_sum >> 2;
		intra_pred_15 <= multi_add9_sum >> 2;
	end
	else if (is_pred_mode_horizontal_up)begin
		intra_pred_0 <= multi_add0_sum >> 1;
		intra_pred_1 <= multi_add4_sum >> 2;
		intra_pred_2 <= multi_add1_sum >> 1;
		intra_pred_3 <= multi_add5_sum >> 2;
		intra_pred_4 <= multi_add1_sum >> 1;
		intra_pred_5 <= multi_add5_sum >> 2;
		intra_pred_6 <= multi_add2_sum >> 1;
		intra_pred_7 <= multi_add6_sum >> 2;
		intra_pred_8 <= multi_add2_sum >> 1;
		intra_pred_9 <= multi_add6_sum >> 2;
		intra_pred_10 <= multi_add3_sum >> 1;
		intra_pred_11 <= multi_add3_sum >> 1;
		intra_pred_12 <= multi_add3_sum >> 1;
		intra_pred_13 <= multi_add3_sum >> 1;
		intra_pred_14 <= multi_add3_sum >> 1;
		intra_pred_15 <= multi_add3_sum >> 1;
	end
	else begin
		intra_pred_0 <= 0;
		intra_pred_1 <= 0;
		intra_pred_2 <= 0;
		intra_pred_3 <= 0;
		intra_pred_4 <= 0;
		intra_pred_5 <= 0;
		intra_pred_6 <= 0;
		intra_pred_7 <= 0;
		intra_pred_8 <= 0;
		intra_pred_9 <= 0;
		intra_pred_10 <= 0;
		intra_pred_11 <= 0;
		intra_pred_12 <= 0;
		intra_pred_13 <= 0;
		intra_pred_14 <= 0;
		intra_pred_15 <= 0;       
	end
end 
else if (calc_ena) begin
	if (calc_ena[2])begin
		intra_pred_0 <= plane_out_0;
		intra_pred_4 <= plane_out_1;
		intra_pred_8 <= plane_out_2;
		intra_pred_12 <= plane_out_3;
	end
	else if (calc_ena[3])begin
		intra_pred_1 <= plane_out_0;
		intra_pred_5 <= plane_out_1;
		intra_pred_9 <= plane_out_2;
		intra_pred_13 <= plane_out_3;
	end
	else if (calc_ena[4])begin
		intra_pred_2 <= plane_out_0;
		intra_pred_6 <= plane_out_1;
		intra_pred_10 <= plane_out_2;
		intra_pred_14 <= plane_out_3;
	end 
	else if (calc_ena[5])begin
		intra_pred_3 <= plane_out_0;
		intra_pred_7 <= plane_out_1;
		intra_pred_11 <= plane_out_2;
		intra_pred_15 <= plane_out_3;
	end 
end
endmodule
