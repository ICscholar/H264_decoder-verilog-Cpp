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

module transform_top(
	input	clk,
	input	rst_n,
	input	ena,
	input   start,
	input	[5:0] curr_QP,
	input   [3:0] residual_state,
	input   [3:0] luma4x4BlkIdx_residual,
	input   [1:0] chroma4x4BlkIdx_residual,
	input	start_of_MB,
	input   [11:0]	coeff_0, 
	input	[11:0]	coeff_1, 
	input	[11:0]	coeff_2, 
	input	[11:0]	coeff_3, 
	input	[11:0]	coeff_4,
	input	[11:0]	coeff_5, 
	input	[11:0]	coeff_6, 
	input	[11:0]	coeff_7, 
	input	[11:0]	coeff_8, 
	input	[11:0]	coeff_9, 
	input	[11:0]	coeff_10,
	input	[11:0]	coeff_11,
	input	[11:0]	coeff_12,
	input	[11:0]	coeff_13,
	input	[11:0]	coeff_14,
	input	[11:0]	coeff_15,
	input   [4:0]   TotalCoeff,

	output  [8:0]	residual_out_0, 
	output	[8:0]	residual_out_1, 
	output	[8:0]	residual_out_2, 
	output	[8:0]	residual_out_3, 
	output	[8:0]	residual_out_4, 
	output	[8:0]	residual_out_5, 
	output	[8:0]	residual_out_6, 
	output	[8:0]	residual_out_7, 
	output	[8:0]	residual_out_8, 
	output	[8:0]	residual_out_9, 
	output	[8:0]	residual_out_10,
	output	[8:0]	residual_out_11,
	output	[8:0]	residual_out_12,
	output	[8:0]	residual_out_13,
	output	[8:0]	residual_out_14,
	output	[8:0]	residual_out_15,
	output valid
);
//-----------------------
//inverse_zigzag
//-----------------------
wire [15:0] curr_DC;
wire regs_out_sel;
wire itrans_col_mode;
wire regs_col_mode;
wire DC_regs_wr;
wire [3:0] DC_rd_idx;
wire AC_all_0_wr;
wire DHT_wr;
wire DHT_sel;
wire IQ_wr;
wire IDCT_wr;

wire [15:0] inverse_zigzag_out_0;
wire [15:0] inverse_zigzag_out_1;
wire [15:0] inverse_zigzag_out_2;
wire [15:0] inverse_zigzag_out_3;
wire [15:0] inverse_zigzag_out_4;
wire [15:0] inverse_zigzag_out_5;
wire [15:0] inverse_zigzag_out_6;
wire [15:0] inverse_zigzag_out_7;
wire [15:0] inverse_zigzag_out_8;
wire [15:0] inverse_zigzag_out_9;
wire [15:0] inverse_zigzag_out_10;
wire [15:0] inverse_zigzag_out_11;
wire [15:0] inverse_zigzag_out_12;
wire [15:0] inverse_zigzag_out_13;
wire [15:0] inverse_zigzag_out_14;
wire [15:0] inverse_zigzag_out_15;

wire [15:0] regs_out_0;
wire [15:0] regs_out_1;
wire [15:0] regs_out_2;
wire [15:0] regs_out_3;
wire [15:0] regs_out_4;
wire [15:0] regs_out_5;
wire [15:0] regs_out_6;
wire [15:0] regs_out_7;
wire [15:0] regs_out_8;
wire [15:0] regs_out_9;
wire [15:0] regs_out_10;
wire [15:0] regs_out_11;
wire [15:0] regs_out_12;
wire [15:0] regs_out_13;
wire [15:0] regs_out_14;
wire [15:0] regs_out_15;

wire [15:0] itrans_in_0;
wire [15:0] itrans_in_1;
wire [15:0] itrans_in_2;
wire [15:0] itrans_in_3;
wire [15:0] itrans_in_4;
wire [15:0] itrans_in_5;
wire [15:0] itrans_in_6;
wire [15:0] itrans_in_7;
wire [15:0] itrans_in_8;
wire [15:0] itrans_in_9;
wire [15:0] itrans_in_10;
wire [15:0] itrans_in_11;
wire [15:0] itrans_in_12;
wire [15:0] itrans_in_13;
wire [15:0] itrans_in_14;
wire [15:0] itrans_in_15;

wire [15:0] butterfly_out_0;
wire [15:0] butterfly_out_1;
wire [15:0] butterfly_out_2;
wire [15:0] butterfly_out_3;
wire [15:0] butterfly_out_4;
wire [15:0] butterfly_out_5;
wire [15:0] butterfly_out_6;
wire [15:0] butterfly_out_7;
wire [15:0] butterfly_out_8;
wire [15:0] butterfly_out_9;
wire [15:0] butterfly_out_10;
wire [15:0] butterfly_out_11;
wire [15:0] butterfly_out_12;
wire [15:0] butterfly_out_13;
wire [15:0] butterfly_out_14;
wire [15:0] butterfly_out_15;

wire [15:0] IQ_out_0;
wire [15:0] IQ_out_1;
wire [15:0] IQ_out_2;
wire [15:0] IQ_out_3;
wire [15:0] IQ_out_4;
wire [15:0] IQ_out_5;
wire [15:0] IQ_out_6;
wire [15:0] IQ_out_7;
wire [15:0] IQ_out_8;
wire [15:0] IQ_out_9;
wire [15:0] IQ_out_10;
wire [15:0] IQ_out_11;
wire [15:0] IQ_out_12;
wire [15:0] IQ_out_13;
wire [15:0] IQ_out_14;
wire [15:0] IQ_out_15;

assign residual_out_0 = regs_out_0[8:0];
assign residual_out_1 = regs_out_1[8:0];
assign residual_out_2 = regs_out_2[8:0];
assign residual_out_3 = regs_out_3[8:0];
assign residual_out_4 = regs_out_4[8:0];
assign residual_out_5 = regs_out_5[8:0];
assign residual_out_6 = regs_out_6[8:0];
assign residual_out_7 = regs_out_7[8:0];
assign residual_out_8 = regs_out_8[8:0];
assign residual_out_9 = regs_out_9[8:0];
assign residual_out_10= regs_out_10[8:0];
assign residual_out_11= regs_out_11[8:0];
assign residual_out_12= regs_out_12[8:0];
assign residual_out_13= regs_out_13[8:0];
assign residual_out_14= regs_out_14[8:0];
assign residual_out_15= regs_out_15[8:0];
		
transform_inverse_zigzag transform_inverse_zigzag(
	.clk(clk),
	.rst_n(rst_n),
	.ena(ena),

	.residual_state(residual_state),
	.coeff_0(coeff_0),
	.coeff_1(coeff_1),
	.coeff_2(coeff_2),
	.coeff_3(coeff_3),
	.coeff_4(coeff_4),
	.coeff_5(coeff_5),
	.coeff_6(coeff_6),
	.coeff_7(coeff_7),
	.coeff_8(coeff_8),
	.coeff_9(coeff_9),
	.coeff_10(coeff_10),
	.coeff_11(coeff_11),
	.coeff_12(coeff_12),
	.coeff_13(coeff_13),
	.coeff_14(coeff_14),
	.coeff_15(coeff_15),

	.inverse_zigzag_out_0(inverse_zigzag_out_0),
	.inverse_zigzag_out_1(inverse_zigzag_out_1),
	.inverse_zigzag_out_2(inverse_zigzag_out_2),
	.inverse_zigzag_out_3(inverse_zigzag_out_3),
	.inverse_zigzag_out_4(inverse_zigzag_out_4),
	.inverse_zigzag_out_5(inverse_zigzag_out_5),
	.inverse_zigzag_out_6(inverse_zigzag_out_6),
	.inverse_zigzag_out_7(inverse_zigzag_out_7),
	.inverse_zigzag_out_8(inverse_zigzag_out_8),
	.inverse_zigzag_out_9(inverse_zigzag_out_9),
	.inverse_zigzag_out_10(inverse_zigzag_out_10),
	.inverse_zigzag_out_11(inverse_zigzag_out_11),
	.inverse_zigzag_out_12(inverse_zigzag_out_12),
	.inverse_zigzag_out_13(inverse_zigzag_out_13),
	.inverse_zigzag_out_14(inverse_zigzag_out_14),
	.inverse_zigzag_out_15(inverse_zigzag_out_15)
);

//------------------------------------------
//transform_mux,select from regs and zigzag
//------------------------------------------
transform_mux transform_mux_inst(
	.clk(clk),
	.rst_n(rst_n),
	.ena(ena),

	.regs_out_sel(regs_out_sel),
	.itrans_col_mode(itrans_col_mode),
	.inverse_zigzag_out_0(inverse_zigzag_out_0),
	.inverse_zigzag_out_1(inverse_zigzag_out_1),
	.inverse_zigzag_out_2(inverse_zigzag_out_2),
	.inverse_zigzag_out_3(inverse_zigzag_out_3),
	.inverse_zigzag_out_4(inverse_zigzag_out_4),
	.inverse_zigzag_out_5(inverse_zigzag_out_5),
	.inverse_zigzag_out_6(inverse_zigzag_out_6),
	.inverse_zigzag_out_7(inverse_zigzag_out_7),
	.inverse_zigzag_out_8(inverse_zigzag_out_8),
	.inverse_zigzag_out_9(inverse_zigzag_out_9),
	.inverse_zigzag_out_10(inverse_zigzag_out_10),
	.inverse_zigzag_out_11(inverse_zigzag_out_11),
	.inverse_zigzag_out_12(inverse_zigzag_out_12),
	.inverse_zigzag_out_13(inverse_zigzag_out_13),
	.inverse_zigzag_out_14(inverse_zigzag_out_14),
	.inverse_zigzag_out_15(inverse_zigzag_out_15),

	.regs_out_0(regs_out_0),
	.regs_out_1(regs_out_1),
	.regs_out_2(regs_out_2),
	.regs_out_3(regs_out_3),
	.regs_out_4(regs_out_4),
	.regs_out_5(regs_out_5),
	.regs_out_6(regs_out_6),
	.regs_out_7(regs_out_7),
	.regs_out_8(regs_out_8),
	.regs_out_9(regs_out_9),
	.regs_out_10(regs_out_10),
	.regs_out_11(regs_out_11),
	.regs_out_12(regs_out_12),
	.regs_out_13(regs_out_13),
	.regs_out_14(regs_out_14),
    .regs_out_15(regs_out_15),
    
	.itrans_in_0(itrans_in_0),
	.itrans_in_1(itrans_in_1),
	.itrans_in_2(itrans_in_2),
	.itrans_in_3(itrans_in_3),
	.itrans_in_4(itrans_in_4),
	.itrans_in_5(itrans_in_5),
	.itrans_in_6(itrans_in_6),
	.itrans_in_7(itrans_in_7),
	.itrans_in_8(itrans_in_8),
	.itrans_in_9(itrans_in_9),
	.itrans_in_10(itrans_in_10),
	.itrans_in_11(itrans_in_11),
	.itrans_in_12(itrans_in_12),
	.itrans_in_13(itrans_in_13),
	.itrans_in_14(itrans_in_14),
	.itrans_in_15(itrans_in_15)
);


transform_butterfly transform_butterfly(
	.clk(clk),
	.rst_n(rst_n),
	.ena(ena),
	.DHT_sel(DHT_sel),

	.butterfly_in_0(itrans_in_0),
	.butterfly_in_1(itrans_in_1),
	.butterfly_in_2(itrans_in_2),
	.butterfly_in_3(itrans_in_3),  
	.butterfly_in_4(itrans_in_4),
	.butterfly_in_5(itrans_in_5),
	.butterfly_in_6(itrans_in_6),
	.butterfly_in_7(itrans_in_7),
	.butterfly_in_8(itrans_in_8),
	.butterfly_in_9(itrans_in_9),
	.butterfly_in_10(itrans_in_10),
	.butterfly_in_11(itrans_in_11),
	.butterfly_in_12(itrans_in_12),
	.butterfly_in_13(itrans_in_13),
	.butterfly_in_14(itrans_in_14),
	.butterfly_in_15(itrans_in_15),

	.butterfly_out_0(butterfly_out_0),
	.butterfly_out_1(butterfly_out_1),
	.butterfly_out_2(butterfly_out_2),
	.butterfly_out_3(butterfly_out_3),  
	.butterfly_out_4(butterfly_out_4),
	.butterfly_out_5(butterfly_out_5),
	.butterfly_out_6(butterfly_out_6),
	.butterfly_out_7(butterfly_out_7),
	.butterfly_out_8(butterfly_out_8),
	.butterfly_out_9(butterfly_out_9),
	.butterfly_out_10(butterfly_out_10),
	.butterfly_out_11(butterfly_out_11),
	.butterfly_out_12(butterfly_out_12),
	.butterfly_out_13(butterfly_out_13),
	.butterfly_out_14(butterfly_out_14),
	.butterfly_out_15(butterfly_out_15)
);
 
transform_inverse_quant transform_inverse_quant_inst(
	.clk(clk),
	.rst_n(rst_n),
	.ena(ena),
	.QP(curr_QP),
	.residual_state(residual_state),

	.curr_DC(curr_DC),
	.p_in_0(itrans_in_0[11:0]),
	.p_in_1(itrans_in_1[11:0]),
	.p_in_2(itrans_in_2[11:0]),
	.p_in_3(itrans_in_3[11:0]),
	.p_in_4(itrans_in_4[11:0]),
	.p_in_5(itrans_in_5[11:0]),
	.p_in_6(itrans_in_6[11:0]),
	.p_in_7(itrans_in_7[11:0]),
	.p_in_8(itrans_in_8[11:0]),
	.p_in_9(itrans_in_9[11:0]),
	.p_in_10(itrans_in_10[11:0]),
	.p_in_11(itrans_in_11[11:0]),
	.p_in_12(itrans_in_12[11:0]),
	.p_in_13(itrans_in_13[11:0]),
	.p_in_14(itrans_in_14[11:0]),
	.p_in_15(itrans_in_15[11:0]),

	.p_out_0(IQ_out_0),
	.p_out_1(IQ_out_1),
	.p_out_2(IQ_out_2),
	.p_out_3(IQ_out_3),
	.p_out_4(IQ_out_4),
	.p_out_5(IQ_out_5),
	.p_out_6(IQ_out_6),
	.p_out_7(IQ_out_7),
	.p_out_8(IQ_out_8),
	.p_out_9(IQ_out_9),
	.p_out_10(IQ_out_10),
	.p_out_11(IQ_out_11),
	.p_out_12(IQ_out_12),
	.p_out_13(IQ_out_13),
	.p_out_14(IQ_out_14),
	.p_out_15(IQ_out_15)
);	

transform_DC_regs transform_DC_regs_inst(
	.clk(clk),
	.rst_n(rst_n),
	.ena(ena),
	.clr(start_of_MB),

	.residual_state(residual_state),
	.wr(DC_regs_wr),
	.rd_idx(DC_rd_idx),

	.data_in_0(IQ_out_0),
	.data_in_1(IQ_out_1), 
	.data_in_2(IQ_out_2), 
	.data_in_3(IQ_out_3), 
	.data_in_4(IQ_out_4), 
	.data_in_5(IQ_out_5), 
	.data_in_6(IQ_out_6), 
	.data_in_7(IQ_out_7), 
	.data_in_8(IQ_out_8), 
	.data_in_9(IQ_out_9), 
	.data_in_10(IQ_out_10),
	.data_in_11(IQ_out_11),
	.data_in_12(IQ_out_12),
	.data_in_13(IQ_out_13),
	.data_in_14(IQ_out_14),
	.data_in_15(IQ_out_15),

	.data_out(curr_DC)
);

transform_regs transform_regs(
	.clk(clk),
	.rst_n(rst_n),
	.ena(ena),
	.col_mode(regs_col_mode),

	.AC_all_0_wr(AC_all_0_wr),
	.IQ_wr(IQ_wr),
	.DHT_wr(DHT_wr),
	.IDCT_wr(IDCT_wr),

	.curr_DC(curr_DC),
	.residual_state(residual_state),

	.IQ_out_0(IQ_out_0),
	.IQ_out_1(IQ_out_1),
	.IQ_out_2(IQ_out_2),
	.IQ_out_3(IQ_out_3),	
	.IQ_out_4(IQ_out_4),
	.IQ_out_5(IQ_out_5),
	.IQ_out_6(IQ_out_6),
	.IQ_out_7(IQ_out_7),
	.IQ_out_8(IQ_out_8),
	.IQ_out_9(IQ_out_9),
	.IQ_out_10(IQ_out_10),
	.IQ_out_11(IQ_out_11),
	.IQ_out_12(IQ_out_12),
	.IQ_out_13(IQ_out_13),
	.IQ_out_14(IQ_out_14),
	.IQ_out_15(IQ_out_15),

	.butterfly_out_0(butterfly_out_0),
	.butterfly_out_1(butterfly_out_1),
	.butterfly_out_2(butterfly_out_2),
	.butterfly_out_3(butterfly_out_3),	
	.butterfly_out_4(butterfly_out_4),
	.butterfly_out_5(butterfly_out_5),
	.butterfly_out_6(butterfly_out_6),
	.butterfly_out_7(butterfly_out_7),
	.butterfly_out_8(butterfly_out_8),
	.butterfly_out_9(butterfly_out_9),
	.butterfly_out_10(butterfly_out_10),
	.butterfly_out_11(butterfly_out_11),
	.butterfly_out_12(butterfly_out_12),
	.butterfly_out_13(butterfly_out_13),
	.butterfly_out_14(butterfly_out_14),
	.butterfly_out_15(butterfly_out_15),

	.regs_out_0(regs_out_0),
	.regs_out_1(regs_out_1),
	.regs_out_2(regs_out_2),
	.regs_out_3(regs_out_3),
	.regs_out_4(regs_out_4),
	.regs_out_5(regs_out_5),
	.regs_out_6(regs_out_6),
	.regs_out_7(regs_out_7),
	.regs_out_8(regs_out_8),
	.regs_out_9(regs_out_9),
	.regs_out_10(regs_out_10),
	.regs_out_11(regs_out_11),
	.regs_out_12(regs_out_12),
	.regs_out_13(regs_out_13),
	.regs_out_14(regs_out_14),
    .regs_out_15(regs_out_15)	
);

//-----------------------
// transform_fsm
//-----------------------
transform_fsm transform_fsm(
	.clk(clk),
	.rst_n(rst_n),
	.ena(ena),
	.start(start),
	.TotalCoeff(TotalCoeff),
	.residual_state(residual_state),
	.luma4x4BlkIdx_residual(luma4x4BlkIdx_residual),
	.chroma4x4BlkIdx_residual(chroma4x4BlkIdx_residual),

	.AC_all_0_wr(AC_all_0_wr),
	.regs_out_sel(regs_out_sel),
	.itrans_col_mode(itrans_col_mode),
	.regs_col_mode(regs_col_mode),
	.DHT_sel(DHT_sel),
	.DHT_wr(DHT_wr),
	.IQ_wr(IQ_wr),
	.IDCT_wr(IDCT_wr),
	.DC_regs_wr(DC_regs_wr),
	.DC_rd_idx(DC_rd_idx),
    .valid(valid)
);
endmodule

module transform_mux(
	input clk,
	input rst_n,
	input ena,
	input regs_out_sel,
	input itrans_col_mode,

	input [15:0] inverse_zigzag_out_0,
	input [15:0] inverse_zigzag_out_1,
	input [15:0] inverse_zigzag_out_2,
	input [15:0] inverse_zigzag_out_3,
	input [15:0] inverse_zigzag_out_4,
	input [15:0] inverse_zigzag_out_5,
	input [15:0] inverse_zigzag_out_6,
	input [15:0] inverse_zigzag_out_7,
	input [15:0] inverse_zigzag_out_8,
	input [15:0] inverse_zigzag_out_9,
	input [15:0] inverse_zigzag_out_10,
	input [15:0] inverse_zigzag_out_11,
	input [15:0] inverse_zigzag_out_12,
	input [15:0] inverse_zigzag_out_13,
	input [15:0] inverse_zigzag_out_14,
	input [15:0] inverse_zigzag_out_15,
		
	input [15:0] regs_out_0,
	input [15:0] regs_out_1,
	input [15:0] regs_out_2,
	input [15:0] regs_out_3,
	input [15:0] regs_out_4,
	input [15:0] regs_out_5,
	input [15:0] regs_out_6,
	input [15:0] regs_out_7,
	input [15:0] regs_out_8,
	input [15:0] regs_out_9,
	input [15:0] regs_out_10,
	input [15:0] regs_out_11,
	input [15:0] regs_out_12,
	input [15:0] regs_out_13,
	input [15:0] regs_out_14,
	input [15:0] regs_out_15,

	output reg [15:0] itrans_in_0,  
	output reg [15:0] itrans_in_1,
	output reg [15:0] itrans_in_2,
	output reg [15:0] itrans_in_3,
	output reg [15:0] itrans_in_4,  
	output reg [15:0] itrans_in_5,
	output reg [15:0] itrans_in_6,
	output reg [15:0] itrans_in_7,
	output reg [15:0] itrans_in_8,  
	output reg [15:0] itrans_in_9,
	output reg [15:0] itrans_in_10,
	output reg [15:0] itrans_in_11,
	output reg [15:0] itrans_in_12, 
	output reg [15:0] itrans_in_13,
	output reg [15:0] itrans_in_14,
	output reg [15:0] itrans_in_15
);

always @(posedge clk or negedge rst_n)
if (~rst_n) begin
    itrans_in_0 <= 0;
    itrans_in_1 <= 0;
    itrans_in_2 <= 0;
    itrans_in_3 <= 0;
	itrans_in_4 <= 0;
    itrans_in_5 <= 0;
    itrans_in_6 <= 0;
    itrans_in_7 <= 0;
    itrans_in_8 <= 0;
    itrans_in_9 <= 0;
    itrans_in_10 <= 0;
    itrans_in_11 <= 0;
    itrans_in_12 <= 0;
    itrans_in_13 <= 0;
    itrans_in_14 <= 0;
    itrans_in_15 <= 0;
end
else if (ena && regs_out_sel && itrans_col_mode) begin
    itrans_in_0 <= regs_out_0;
    itrans_in_1 <= regs_out_4;
    itrans_in_2 <= regs_out_8;
    itrans_in_3 <= regs_out_12;
	itrans_in_4 <= regs_out_1;
    itrans_in_5 <= regs_out_5;
    itrans_in_6 <= regs_out_9;
    itrans_in_7 <= regs_out_13;
    itrans_in_8 <= regs_out_2;
    itrans_in_9 <= regs_out_6;
    itrans_in_10 <= regs_out_10;
    itrans_in_11 <= regs_out_14;
    itrans_in_12 <= regs_out_3;
    itrans_in_13 <= regs_out_7;
    itrans_in_14 <= regs_out_11;
    itrans_in_15 <= regs_out_15;
end
else if (ena && regs_out_sel) begin
    itrans_in_0 <= regs_out_0;
    itrans_in_1 <= regs_out_1;
    itrans_in_2 <= regs_out_2;
    itrans_in_3 <= regs_out_3;
	itrans_in_4 <= regs_out_4;
    itrans_in_5 <= regs_out_5;
    itrans_in_6 <= regs_out_6;
    itrans_in_7 <= regs_out_7;
    itrans_in_8 <= regs_out_8;
    itrans_in_9 <= regs_out_9;
    itrans_in_10 <= regs_out_10;
    itrans_in_11 <= regs_out_11;
    itrans_in_12 <= regs_out_12;
    itrans_in_13 <= regs_out_13;
    itrans_in_14 <= regs_out_14;
    itrans_in_15 <= regs_out_15;
end
else if(ena)begin
	itrans_in_0 <= inverse_zigzag_out_0;
    itrans_in_1 <= inverse_zigzag_out_1;
    itrans_in_2 <= inverse_zigzag_out_2;
    itrans_in_3 <= inverse_zigzag_out_3;
	itrans_in_4 <= inverse_zigzag_out_4;
    itrans_in_5 <= inverse_zigzag_out_5;
    itrans_in_6 <= inverse_zigzag_out_6;
    itrans_in_7 <= inverse_zigzag_out_7;
    itrans_in_8 <= inverse_zigzag_out_8;
    itrans_in_9 <= inverse_zigzag_out_9;
    itrans_in_10 <= inverse_zigzag_out_10;
    itrans_in_11 <= inverse_zigzag_out_11;
    itrans_in_12 <= inverse_zigzag_out_12;
    itrans_in_13 <= inverse_zigzag_out_13;
    itrans_in_14 <= inverse_zigzag_out_14;
    itrans_in_15 <= inverse_zigzag_out_15;
end

endmodule
