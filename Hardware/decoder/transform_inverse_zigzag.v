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

module transform_inverse_zigzag(
	input clk,
	input rst_n,
	input ena,

	input [3:0]	residual_state,

	input [11:0] coeff_0,
	input [11:0] coeff_1,
	input [11:0] coeff_2,
	input [11:0] coeff_3,
	input [11:0] coeff_4,
	input [11:0] coeff_5,
	input [11:0] coeff_6,
	input [11:0] coeff_7,
	input [11:0] coeff_8,
	input [11:0] coeff_9,
	input [11:0] coeff_10,
	input [11:0] coeff_11,
	input [11:0] coeff_12,
	input [11:0] coeff_13,
	input [11:0] coeff_14,
	input [11:0] coeff_15,

	output [15:0] inverse_zigzag_out_0,
	output [15:0] inverse_zigzag_out_1,
	output [15:0] inverse_zigzag_out_2,
	output [15:0] inverse_zigzag_out_3,
	output [15:0] inverse_zigzag_out_4,
	output [15:0] inverse_zigzag_out_5,
	output [15:0] inverse_zigzag_out_6,
	output [15:0] inverse_zigzag_out_7,
	output [15:0] inverse_zigzag_out_8,
	output [15:0] inverse_zigzag_out_9,
	output [15:0] inverse_zigzag_out_10,
	output [15:0] inverse_zigzag_out_11,
	output [15:0] inverse_zigzag_out_12,
	output [15:0] inverse_zigzag_out_13,
	output [15:0] inverse_zigzag_out_14,
	output [15:0] inverse_zigzag_out_15
);
reg [11:0] inverse_zigzag_reg_0;
reg [11:0] inverse_zigzag_reg_1;
reg [11:0] inverse_zigzag_reg_2;
reg [11:0] inverse_zigzag_reg_3;
reg [11:0] inverse_zigzag_reg_4;
reg [11:0] inverse_zigzag_reg_5;
reg [11:0] inverse_zigzag_reg_6;
reg [11:0] inverse_zigzag_reg_7;
reg [11:0] inverse_zigzag_reg_8;
reg [11:0] inverse_zigzag_reg_9;
reg [11:0] inverse_zigzag_reg_10;
reg [11:0] inverse_zigzag_reg_11;
reg [11:0] inverse_zigzag_reg_12;
reg [11:0] inverse_zigzag_reg_13;
reg [11:0] inverse_zigzag_reg_14;
reg [11:0] inverse_zigzag_reg_15;

assign inverse_zigzag_out_0 = {{4{inverse_zigzag_reg_0[11]}},inverse_zigzag_reg_0}; 
assign inverse_zigzag_out_1 = {{4{inverse_zigzag_reg_1[11]}},inverse_zigzag_reg_1}; 
assign inverse_zigzag_out_2 = {{4{inverse_zigzag_reg_2[11]}},inverse_zigzag_reg_2}; 
assign inverse_zigzag_out_3 = {{4{inverse_zigzag_reg_3[11]}},inverse_zigzag_reg_3}; 
assign inverse_zigzag_out_4 = {{4{inverse_zigzag_reg_4[11]}},inverse_zigzag_reg_4}; 
assign inverse_zigzag_out_5 = {{4{inverse_zigzag_reg_5[11]}},inverse_zigzag_reg_5}; 
assign inverse_zigzag_out_6 = {{4{inverse_zigzag_reg_6[11]}},inverse_zigzag_reg_6}; 
assign inverse_zigzag_out_7 = {{4{inverse_zigzag_reg_7[11]}},inverse_zigzag_reg_7}; 
assign inverse_zigzag_out_8 = {{4{inverse_zigzag_reg_8[11]}},inverse_zigzag_reg_8}; 
assign inverse_zigzag_out_9 = {{4{inverse_zigzag_reg_9[11]}},inverse_zigzag_reg_9}; 
assign inverse_zigzag_out_10 = {{4{inverse_zigzag_reg_10[11]}},inverse_zigzag_reg_10}; 
assign inverse_zigzag_out_11 = {{4{inverse_zigzag_reg_11[11]}},inverse_zigzag_reg_11}; 
assign inverse_zigzag_out_12 = {{4{inverse_zigzag_reg_12[11]}},inverse_zigzag_reg_12}; 
assign inverse_zigzag_out_13 = {{4{inverse_zigzag_reg_13[11]}},inverse_zigzag_reg_13}; 
assign inverse_zigzag_out_14 = {{4{inverse_zigzag_reg_14[11]}},inverse_zigzag_reg_14}; 
assign inverse_zigzag_out_15 = {{4{inverse_zigzag_reg_15[11]}},inverse_zigzag_reg_15}; 



always @(*)
if (residual_state == `Intra16x16ACLevel_s || 
	residual_state == `ChromaACLevel_Cb_s ||
	residual_state == `ChromaACLevel_Cr_s) begin //AC
	inverse_zigzag_reg_0 = 0;
	inverse_zigzag_reg_1 = coeff_0;
	inverse_zigzag_reg_2 = coeff_4;
	inverse_zigzag_reg_3 = coeff_5;
	inverse_zigzag_reg_4 = coeff_1;
	inverse_zigzag_reg_5 = coeff_3;
	inverse_zigzag_reg_6 = coeff_6;
	inverse_zigzag_reg_7 = coeff_11;
	inverse_zigzag_reg_8 = coeff_2;
	inverse_zigzag_reg_9 = coeff_7;
	inverse_zigzag_reg_10 = coeff_10;
	inverse_zigzag_reg_11 = coeff_12;
	inverse_zigzag_reg_12 = coeff_8;
	inverse_zigzag_reg_13 = coeff_9;
	inverse_zigzag_reg_14 = coeff_13;
	inverse_zigzag_reg_15 = coeff_14;
end
else if (residual_state == `ChromaDCLevel_Cb_s || 
		 residual_state == `ChromaDCLevel_Cr_s ) begin
	inverse_zigzag_reg_0 = coeff_0;
	inverse_zigzag_reg_1 = coeff_1;
	inverse_zigzag_reg_2 = coeff_2;
	inverse_zigzag_reg_3 = coeff_3;
	inverse_zigzag_reg_4 = coeff_2;
	inverse_zigzag_reg_5 = coeff_4;
	inverse_zigzag_reg_6 = coeff_7;
	inverse_zigzag_reg_7 = coeff_12;
	inverse_zigzag_reg_8 = coeff_3;
	inverse_zigzag_reg_9 = coeff_8;
	inverse_zigzag_reg_10 = coeff_11;
	inverse_zigzag_reg_11 = coeff_13;
	inverse_zigzag_reg_12 = coeff_9;
	inverse_zigzag_reg_13 = coeff_10;
	inverse_zigzag_reg_14 = coeff_14;
	inverse_zigzag_reg_15 = coeff_15;
end
else begin	//Luma4x4 or LumaDC
	inverse_zigzag_reg_0 = coeff_0;
	inverse_zigzag_reg_1 = coeff_1;
	inverse_zigzag_reg_2 = coeff_5;
	inverse_zigzag_reg_3 = coeff_6;
	inverse_zigzag_reg_4 = coeff_2;
	inverse_zigzag_reg_5 = coeff_4;
	inverse_zigzag_reg_6 = coeff_7;
	inverse_zigzag_reg_7 = coeff_12;
	inverse_zigzag_reg_8 = coeff_3;
	inverse_zigzag_reg_9 = coeff_8;
	inverse_zigzag_reg_10 = coeff_11;
	inverse_zigzag_reg_11 = coeff_13;
	inverse_zigzag_reg_12 = coeff_9;
	inverse_zigzag_reg_13 = coeff_10;
	inverse_zigzag_reg_14 = coeff_14;
	inverse_zigzag_reg_15 = coeff_15;
end
endmodule

