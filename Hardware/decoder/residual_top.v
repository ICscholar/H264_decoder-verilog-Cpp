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


module residual_top (
	input   clk, rst_n,
	input   ena,
	input   residual_start,
	input   mb_pred_inter_sel,
	input   is_residual_not_dc,
	input   [0:15]  rbsp,
	input   [3:0]  num_zero_bits,

	input   signed [5:0]    nC,
	input   [4:0]   max_coeff_num,
	input   [3:0]   luma4x4BlkIdx_residual,
	input   [1:0]   chroma4x4BlkIdx_residual,
	input 	start_of_MB,
	
	input   [3:0]   residual_state,
	input   [5:0]   qp,
	input   [5:0]   qp_c,
	
	output [8:0] residual_0,
	output [8:0] residual_1,
	output [8:0] residual_2,
	output [8:0] residual_3,
	output [8:0] residual_4,
	output [8:0] residual_5,
	output [8:0] residual_6,
	output [8:0] residual_7,
	output [8:0] residual_8,
	output [8:0] residual_9,
	output [8:0] residual_10,
	output [8:0] residual_11,
	output [8:0] residual_12,
	output [8:0] residual_13,
	output [8:0] residual_14,
	output [8:0] residual_15,            
	
	output  [4:0]   TotalCoeff,
	output  [4:0]   len_comb,
	output  cavlc_idle,
	output  residual_valid,
	output  [4:0] out_ram_wr_addr_reg,
	input   out_ram_rd
);
wire [8:0] residual_i_0;
wire [8:0] residual_i_1;
wire [8:0] residual_i_2;
wire [8:0] residual_i_3;
wire [8:0] residual_i_4;
wire [8:0] residual_i_5;
wire [8:0] residual_i_6;
wire [8:0] residual_i_7;
wire [8:0] residual_i_8;
wire [8:0] residual_i_9;
wire [8:0] residual_i_10;
wire [8:0] residual_i_11;
wire [8:0] residual_i_12;
wire [8:0] residual_i_13;
wire [8:0] residual_i_14;
wire [8:0] residual_i_15;            
wire [8:0] residual_o_0;
wire [8:0] residual_o_1;
wire [8:0] residual_o_2;
wire [8:0] residual_o_3;
wire [8:0] residual_o_4;
wire [8:0] residual_o_5;
wire [8:0] residual_o_6;
wire [8:0] residual_o_7;
wire [8:0] residual_o_8;
wire [8:0] residual_o_9;
wire [8:0] residual_o_10;
wire [8:0] residual_o_11;
wire [8:0] residual_o_12;
wire [8:0] residual_o_13;
wire [8:0] residual_o_14;
wire [8:0] residual_o_15;            

wire [4:0] out_ram_rd_addr;
wire [4:0] out_ram_wr_addr;

dp_ram #(9*16, 5) residual_out_ram_0(
	.aclr(~rst_n),
	.data({residual_i_0,residual_i_1,residual_i_2,residual_i_3,
			  residual_i_4,residual_i_5,residual_i_6,residual_i_7,
			  residual_i_8,residual_i_9,residual_i_10,residual_i_11,
			  residual_i_12,residual_i_13,residual_i_14,residual_i_15}),
	.rdaddress(out_ram_rd_addr),	
	.wraddress(out_ram_wr_addr),
	.wren(out_ram_wr),
	.rdclock(clk),
	.wrclock(clk),
	.q({residual_o_0,residual_o_1,residual_o_2,residual_o_3,
			  residual_o_4,residual_o_5,residual_o_6,residual_o_7,
			  residual_o_8,residual_o_9,residual_o_10,residual_o_11,
			  residual_o_12,residual_o_13,residual_o_14,residual_o_15})
);
assign residual_0 = mb_pred_inter_sel ? residual_o_0 : residual_i_0;
assign residual_1 = mb_pred_inter_sel ? residual_o_1 : residual_i_1;
assign residual_2 = mb_pred_inter_sel ? residual_o_2 : residual_i_2;
assign residual_3 = mb_pred_inter_sel ? residual_o_3 : residual_i_3;
assign residual_4 = mb_pred_inter_sel ? residual_o_4 : residual_i_4;
assign residual_5 = mb_pred_inter_sel ? residual_o_5 : residual_i_5;
assign residual_6 = mb_pred_inter_sel ? residual_o_6 : residual_i_6;
assign residual_7 = mb_pred_inter_sel ? residual_o_7 : residual_i_7;
assign residual_8 = mb_pred_inter_sel ? residual_o_8 : residual_i_8;
assign residual_9 = mb_pred_inter_sel ? residual_o_9 : residual_i_9;
assign residual_10= mb_pred_inter_sel ? residual_o_10: residual_i_10;
assign residual_11= mb_pred_inter_sel ? residual_o_11: residual_i_11;
assign residual_12= mb_pred_inter_sel ? residual_o_12: residual_i_12;
assign residual_13= mb_pred_inter_sel ? residual_o_13: residual_i_13;
assign residual_14= mb_pred_inter_sel ? residual_o_14: residual_i_14;
assign residual_15= mb_pred_inter_sel ? residual_o_15: residual_i_15;

wire signed [11:0]    coeff_0; 
wire signed [11:0]    coeff_1; 
wire signed [11:0]    coeff_2; 
wire signed [11:0]    coeff_3; 
wire signed [11:0]    coeff_4; 
wire signed [11:0]    coeff_5; 
wire signed [11:0]    coeff_6; 
wire signed [11:0]    coeff_7; 
wire signed [11:0]    coeff_8; 
wire signed [11:0]    coeff_9; 
wire signed [11:0]    coeff_10;
wire signed [11:0]    coeff_11;
wire signed [11:0]    coeff_12;
wire signed [11:0]    coeff_13;
wire signed [11:0]    coeff_14;
wire signed [11:0]    coeff_15;
wire cavlc_valid;

cavlc_top cavlc_inst(
    .clk(clk),
    .rst_n(rst_n),
    .ena(ena),
    .start(cavlc_start),
    .rbsp(rbsp),
	.num_zero_bits(num_zero_bits),

    .nC(nC),
    .max_coeff_num(max_coeff_num),

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
    .TotalCoeff(TotalCoeff),
    .len_comb(len_comb),
    .idle(cavlc_idle),
    .valid(cavlc_valid)
);

wire transform_start;
wire transform_valid;
wire [5:0] curr_QP;

transform_top transform_inst(
    .clk(clk),
    .rst_n(rst_n),
    .ena(ena),
    .start(transform_start),
	.curr_QP(curr_QP),
    .residual_state(residual_state),
    .luma4x4BlkIdx_residual(luma4x4BlkIdx_residual),
    .chroma4x4BlkIdx_residual(chroma4x4BlkIdx_residual),
    .start_of_MB(start_of_MB),
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
   .TotalCoeff(TotalCoeff),
     
    .residual_out_0(residual_i_0),
	.residual_out_1(residual_i_1),
	.residual_out_2(residual_i_2),
	.residual_out_3(residual_i_3),
	.residual_out_4(residual_i_4),
	.residual_out_5(residual_i_5),
	.residual_out_6(residual_i_6),
	.residual_out_7(residual_i_7),
	.residual_out_8(residual_i_8),
	.residual_out_9(residual_i_9),
	.residual_out_10(residual_i_10),
	.residual_out_11(residual_i_11),
	.residual_out_12(residual_i_12),
	.residual_out_13(residual_i_13),
	.residual_out_14(residual_i_14),
	.residual_out_15(residual_i_15),
    .valid(transform_valid)
);

residual_ctrl residual_ctrl_inst(
	.clk(clk),
	.rst_n(rst_n),
	.ena(ena),
	.start_of_MB(start_of_MB),
	.mb_pred_inter_sel(mb_pred_inter_sel),
	.is_residual_not_dc(is_residual_not_dc),
	.residual_state(residual_state),
	.residual_start(residual_start),
	.residual_valid(residual_valid),
	.out_ram_wr(out_ram_wr),
	.out_ram_rd(out_ram_rd),
	.out_ram_wr_addr(out_ram_wr_addr),
	.out_ram_wr_addr_reg(out_ram_wr_addr_reg),
	.out_ram_rd_addr(out_ram_rd_addr),
	.cavlc_start(cavlc_start),
	.cavlc_valid(cavlc_valid),
	.transform_start(transform_start),
	.transform_valid(transform_valid),
	.qp(qp),
	.qp_c(qp_c),
	.curr_QP(curr_QP)
);
 //  initial $fsdbInteractive;
/*initial 
begin 
    $fsdbDumpfile("residual.fsdb"); 
    $fsdbDumpvars; 
end
*/ 
endmodule
