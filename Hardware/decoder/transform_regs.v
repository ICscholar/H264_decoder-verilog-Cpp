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

module transform_DC_regs
(
	input clk,
	input rst_n,
	input ena,
	input clr,
	input [3:0] residual_state,
	input wr,
	input [3:0] rd_idx,
	input [15:0] data_in_0,
	input [15:0] data_in_1, 
	input [15:0] data_in_2, 
	input [15:0] data_in_3, 
	input [15:0] data_in_4, 
	input [15:0] data_in_5, 
	input [15:0] data_in_6, 
	input [15:0] data_in_7, 
	input [15:0] data_in_8, 
	input [15:0] data_in_9, 
	input [15:0] data_in_10,
	input [15:0] data_in_11,
	input [15:0] data_in_12,
	input [15:0] data_in_13,
	input [15:0] data_in_14,
	input [15:0] data_in_15,

	output reg [15:0] data_out
);
//------------------
// FFs
//-----------------
reg [15:0] reg_0;
reg [15:0] reg_1;  
reg [15:0] reg_2;  
reg [15:0] reg_3;  
reg [15:0] reg_4;  
reg [15:0] reg_5;  
reg [15:0] reg_6;  
reg [15:0] reg_7;  
reg [15:0] reg_8;  
reg [15:0] reg_9;  
reg [15:0] reg_10;
reg [15:0] reg_11;
reg [15:0] reg_12;
reg [15:0] reg_13;
reg [15:0] reg_14;
reg [15:0] reg_15;

reg [15:0] Cb_reg_0;
reg [15:0] Cb_reg_1;
reg [15:0] Cb_reg_2;  
reg [15:0] Cb_reg_3; 
 
reg [15:0] Cr_reg_0;  
reg [15:0] Cr_reg_1;  
reg [15:0] Cr_reg_2;  
reg [15:0] Cr_reg_3;  
always @(posedge clk or negedge rst_n)
if (!rst_n)
begin
	reg_0  <= 0;
	reg_1  <= 0;
	reg_2  <= 0;
	reg_3  <= 0;
	reg_4  <= 0;
	reg_5  <= 0;
	reg_6  <= 0;
	reg_7  <= 0;
	reg_8  <= 0;
	reg_9  <= 0;
	reg_10 <= 0;
	reg_11 <= 0;
	reg_12 <= 0;
	reg_13 <= 0;
	reg_14 <= 0;
	reg_15 <= 0;
	Cb_reg_0 <= 0;
	Cb_reg_1 <= 0;
	Cb_reg_2 <= 0;
	Cb_reg_3 <= 0;
	Cr_reg_0 <= 0;   
	Cr_reg_1 <= 0;   
	Cr_reg_2 <= 0;   
	Cr_reg_3 <= 0;
end
else if (ena && clr)
begin
	reg_0  <= 0;
	reg_1  <= 0;
	reg_2  <= 0;
	reg_3  <= 0;
	reg_4  <= 0;
	reg_5  <= 0;
	reg_6  <= 0;
	reg_7  <= 0;
	reg_8  <= 0;
	reg_9  <= 0;
	reg_10 <= 0;
	reg_11 <= 0;
	reg_12 <= 0;
	reg_13 <= 0;
	reg_14 <= 0;
	reg_15 <= 0;
	Cb_reg_0 <= 0;
	Cb_reg_1 <= 0;
	Cb_reg_2 <= 0;
	Cb_reg_3 <= 0;
	Cr_reg_0 <= 0;   
	Cr_reg_1 <= 0;   
	Cr_reg_2 <= 0;   
	Cr_reg_3 <= 0;
end
else if(ena && wr && residual_state == `Intra16x16DCLevel_s)begin
	reg_0 <= data_in_0; 
	reg_1 <= data_in_1;
	reg_4 <= data_in_2; 
	reg_5 <= data_in_3;
	reg_2 <= data_in_4; 
	reg_3 <= data_in_5;			
	reg_6 <= data_in_6; 
	reg_7 <= data_in_7;			
	reg_8 <= data_in_8; 
	reg_9 <= data_in_9;
	reg_12 <= data_in_10; 
	reg_13 <= data_in_11;
	reg_10 <= data_in_12; 
	reg_11 <= data_in_13;			
	reg_14 <= data_in_14; 
	reg_15 <= data_in_15;			
end
else  if(ena && wr && residual_state == `ChromaDCLevel_Cb_s)
	begin 
		Cb_reg_0 <= data_in_0; Cb_reg_2 <= data_in_1;
		Cb_reg_3 <= data_in_2; Cb_reg_1 <= data_in_3;			
	end
else if (ena && wr && residual_state == `ChromaDCLevel_Cr_s)
	begin 
		Cr_reg_0 <= data_in_0; Cr_reg_2 <= data_in_1;   
		Cr_reg_3 <= data_in_2; Cr_reg_1 <= data_in_3;	
	end
	
always @(posedge clk or negedge rst_n)
if (!rst_n)
	data_out <= 0;
else  if(ena && (residual_state ==`Intra16x16ACLevel_s ||
   	     residual_state == `Intra16x16ACLevel_0_s))//lumaAC
	case (rd_idx)
	0:data_out <= reg_0;
	1:data_out <= reg_1;
	2:data_out <= reg_2;
	3:data_out <= reg_3;
	4:data_out <= reg_4;
	5:data_out <= reg_5;
	6:data_out <= reg_6;
	7:data_out <= reg_7;
	8:data_out <= reg_8;
	9:data_out <= reg_9;
	10:data_out <= reg_10;
	11:data_out <= reg_11;
	12:data_out <= reg_12;
	13:data_out <= reg_13;
	14:data_out <= reg_14;
	default:data_out <= reg_15;
	endcase
else  if(ena)
	case (rd_idx)
	0:data_out <= Cb_reg_0;
	1:data_out <= Cb_reg_1;
	2:data_out <= Cb_reg_2;
	3:data_out <= Cb_reg_3;
	4:data_out <= Cr_reg_0;
	5:data_out <= Cr_reg_1;
	6:data_out <= Cr_reg_2;
	default:data_out <= Cr_reg_3;
	endcase

endmodule


module transform_regs(
	input clk,
	input rst_n,
	input ena,
	input col_mode,
	input [3:0] residual_state,
   	
	input AC_all_0_wr,
	input IQ_wr,
	input DHT_wr,
	input IDCT_wr,

	input signed [15:0] curr_DC, 

	input [15:0] IQ_out_0,
	input [15:0] IQ_out_1,
	input [15:0] IQ_out_2,
	input [15:0] IQ_out_3,
	input [15:0] IQ_out_4,
	input [15:0] IQ_out_5,
	input [15:0] IQ_out_6,
	input [15:0] IQ_out_7,
	input [15:0] IQ_out_8,
	input [15:0] IQ_out_9,
	input [15:0] IQ_out_10,
	input [15:0] IQ_out_11,
	input [15:0] IQ_out_12,
	input [15:0] IQ_out_13,
	input [15:0] IQ_out_14,
	input [15:0] IQ_out_15,	

	input signed [15:0] butterfly_out_0,
	input signed [15:0] butterfly_out_1,
	input signed [15:0] butterfly_out_2,
	input signed [15:0] butterfly_out_3,
	input signed [15:0] butterfly_out_4,
	input signed [15:0] butterfly_out_5,
	input signed [15:0] butterfly_out_6,
	input signed [15:0] butterfly_out_7,
	input signed [15:0] butterfly_out_8,
	input signed [15:0] butterfly_out_9,
	input signed [15:0] butterfly_out_10,
	input signed [15:0] butterfly_out_11,
	input signed [15:0] butterfly_out_12,
	input signed [15:0] butterfly_out_13,
	input signed [15:0] butterfly_out_14,
	input signed [15:0] butterfly_out_15,	
		
	output [15:0]	regs_out_0,
	output [15:0]	regs_out_1,
	output [15:0]	regs_out_2,
	output [15:0]	regs_out_3,
	output [15:0]	regs_out_4,
	output [15:0]	regs_out_5,
	output [15:0]	regs_out_6,
	output [15:0]	regs_out_7,
	output [15:0]	regs_out_8,
	output [15:0]	regs_out_9,
	output [15:0]	regs_out_10,
	output [15:0]	regs_out_11,
	output [15:0]	regs_out_12,
	output [15:0]	regs_out_13,
	output [15:0]	regs_out_14,
	output [15:0]	regs_out_15	
);
//------------------
// FFs
//-----------------
reg signed [15:0] reg_0;
reg signed [15:0] reg_1;  
reg signed [15:0] reg_2;  
reg signed [15:0] reg_3;  
reg signed [15:0] reg_4;  
reg signed [15:0] reg_5;  
reg signed [15:0] reg_6;  
reg signed [15:0] reg_7;  
reg signed [15:0] reg_8;  
reg signed [15:0] reg_9;  
reg signed [15:0] reg_10;
reg signed [15:0] reg_11;
reg signed [15:0] reg_12;
reg signed [15:0] reg_13;
reg signed [15:0] reg_14;
reg signed [15:0] reg_15;

reg signed [8:0] rounding_0;
reg signed [8:0] rounding_1; 
reg signed [8:0] rounding_2; 
reg signed [8:0] rounding_3; 
reg signed [8:0] rounding_4; 
reg signed [8:0] rounding_5; 
reg signed [8:0] rounding_6; 
reg signed [8:0] rounding_7; 
reg signed [8:0] rounding_8; 
reg signed [8:0] rounding_9; 
reg signed [8:0] rounding_10;
reg signed [8:0] rounding_11;
reg signed [8:0] rounding_12;
reg signed [8:0] rounding_13;
reg signed [8:0] rounding_14;
reg signed [8:0] rounding_15;


always @(*) begin
	rounding_0 = (butterfly_out_0+32) >>> 6;
	rounding_1 = (butterfly_out_1+32) >>> 6;
	rounding_2 = (butterfly_out_2+32) >>> 6;								
	rounding_3 = (butterfly_out_3+32) >>> 6;
	rounding_4 = (butterfly_out_4+32) >>> 6;
	rounding_5 = (butterfly_out_5+32) >>> 6;
	rounding_6 = (butterfly_out_6+32) >>> 6;								
	rounding_7 = (butterfly_out_7+32) >>> 6;
	rounding_8 = (butterfly_out_8+32) >>> 6;
	rounding_9 = (butterfly_out_9+32) >>> 6;
	rounding_10 = (butterfly_out_10+32) >>> 6;								
	rounding_11 = (butterfly_out_11+32) >>> 6;
	rounding_12 = (butterfly_out_12+32) >>> 6;
	rounding_13 = (butterfly_out_13+32) >>> 6;
	rounding_14 = (butterfly_out_14+32) >>> 6;								
	rounding_15 = (butterfly_out_15+32) >>> 6;
end
	
assign regs_out_0 = reg_0[15:0];
assign regs_out_1 = reg_1[15:0];	
assign regs_out_2 = reg_2[15:0];
assign regs_out_3 = reg_3[15:0];
assign regs_out_4 = reg_4[15:0];
assign regs_out_5 = reg_5[15:0];
assign regs_out_6 = reg_6[15:0];
assign regs_out_7 = reg_7[15:0];
assign regs_out_8 = reg_8[15:0];
assign regs_out_9 = reg_9[15:0];
assign regs_out_10 = reg_10[15:0];
assign regs_out_11 = reg_11[15:0];
assign regs_out_12 = reg_12[15:0];
assign regs_out_13 = reg_13[15:0];
assign regs_out_14 = reg_14[15:0];
assign regs_out_15 = reg_15[15:0];

wire signed [8:0] curr_DC_rounded;
assign curr_DC_rounded = (curr_DC + 32) >>> 6;

always @(posedge clk or negedge rst_n)
if (!rst_n) begin
	reg_0  <= 0;
	reg_1  <= 0;
	reg_2  <= 0;
	reg_3  <= 0;
	reg_4  <= 0;
	reg_5  <= 0;
	reg_6  <= 0;
	reg_7  <= 0;
	reg_8  <= 0;
	reg_9  <= 0;
	reg_10 <= 0;
	reg_11 <= 0;
	reg_12 <= 0;
	reg_13 <= 0;
	reg_14 <= 0;
	reg_15 <= 0;
end
else  if(ena && AC_all_0_wr) begin
	reg_0  <= curr_DC_rounded;
	reg_1  <= curr_DC_rounded;
	reg_2  <= curr_DC_rounded;
	reg_3  <= curr_DC_rounded;
	reg_4  <= curr_DC_rounded;
	reg_5  <= curr_DC_rounded;
	reg_6  <= curr_DC_rounded;
	reg_7  <= curr_DC_rounded;
	reg_8  <= curr_DC_rounded;
	reg_9  <= curr_DC_rounded;
	reg_10 <= curr_DC_rounded;
	reg_11 <= curr_DC_rounded; 
	reg_12 <= curr_DC_rounded;
	reg_13 <= curr_DC_rounded;
	reg_14 <= curr_DC_rounded;
	reg_15 <= curr_DC_rounded; 
end
else if (ena && IQ_wr) begin
	reg_0 <= IQ_out_0;
	reg_1 <= IQ_out_1; 
	reg_2 <= IQ_out_2;  
	reg_3 <= IQ_out_3; 
   	reg_4 <= IQ_out_4;
	reg_5 <= IQ_out_5;
	reg_6 <= IQ_out_6;
	reg_7 <= IQ_out_7;
	reg_8 <= IQ_out_8; 
	reg_9 <= IQ_out_9; 
	reg_10 <= IQ_out_10;
	reg_11 <= IQ_out_11;
	reg_12 <= IQ_out_12;
	reg_13 <= IQ_out_13;
	reg_14 <= IQ_out_14;
	reg_15 <= IQ_out_15;
end
else if(ena && col_mode && IDCT_wr) begin
	reg_0 <= rounding_0; 
	reg_1 <= rounding_4; 
	reg_2 <= rounding_8; 
	reg_3 <= rounding_12; 
	reg_4 <= rounding_1; 
	reg_5 <= rounding_5; 
	reg_6 <= rounding_9; 
	reg_7 <= rounding_13; 
	reg_8 <= rounding_2; 
	reg_9 <= rounding_6; 
	reg_10 <= rounding_10; 
	reg_11 <= rounding_14;
	reg_12 <= rounding_3;
	reg_13 <= rounding_7;
	reg_14 <= rounding_11;
	reg_15 <= rounding_15;
end
else if (ena && col_mode && DHT_wr ) begin
	reg_0 <= butterfly_out_0;
	reg_1 <= butterfly_out_4; 
	reg_2 <= butterfly_out_8; 
	reg_3 <= butterfly_out_12;  
	reg_4 <= butterfly_out_1;
	reg_5 <= butterfly_out_5;
	reg_6 <= butterfly_out_9;
	reg_7 <= butterfly_out_13;
	reg_8 <= butterfly_out_2; 
	reg_9 <= butterfly_out_6; 
	reg_10 <= butterfly_out_10;
	reg_11 <= butterfly_out_14;
	reg_12 <= butterfly_out_3;  
	reg_13 <= butterfly_out_7; 
	reg_14 <= butterfly_out_11;
	reg_15 <= butterfly_out_15;
end
else if (ena && (IDCT_wr || DHT_wr)) begin
	reg_0 <= butterfly_out_0;
	reg_1 <= butterfly_out_1; 
	reg_2 <= butterfly_out_2; 
	reg_3 <= butterfly_out_3; 
	reg_4 <= butterfly_out_4;
	reg_5 <= butterfly_out_5;
	reg_6 <= butterfly_out_6;
	reg_7 <= butterfly_out_7;
	reg_8 <= butterfly_out_8; 
	reg_9 <= butterfly_out_9; 
	reg_10 <= butterfly_out_10;
	reg_11 <= butterfly_out_11;
	reg_12 <= butterfly_out_12; 
	reg_13 <= butterfly_out_13; 
	reg_14 <= butterfly_out_14;
	reg_15 <= butterfly_out_15;
end
endmodule

