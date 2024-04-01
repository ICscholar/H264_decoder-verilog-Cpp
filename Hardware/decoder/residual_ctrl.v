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

module residual_ctrl
(
	input  clk,
	input  rst_n,
	input  ena,
	input  start_of_MB,
	input  mb_pred_inter_sel,
	input  is_residual_not_dc,
	input  [3:0] residual_state,
	input  residual_start,
	output residual_valid,
	output reg[4:0] out_ram_wr_addr,
	output reg[4:0] out_ram_wr_addr_reg,
	output reg[4:0] out_ram_rd_addr,
	input out_ram_rd,
	output out_ram_wr,
	output cavlc_start,
	input  cavlc_valid,
	output transform_start,
	input  transform_valid,
	input [5:0] qp,
	input [5:0] qp_c,
	output reg [5:0] curr_QP	
);


//FFs
reg cavlc_valid_s;
reg transform_valid_s;
reg transform_finished;

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n) begin
		cavlc_valid_s     <= 0;
		transform_valid_s <= 0;
	end
	else if (ena) begin
		cavlc_valid_s     <= cavlc_valid;
		transform_valid_s <= transform_valid;
	end
end


wire all0_blk;
wire cavlc_finish;
wire transform_finish;

assign all0_blk = (residual_state == `Intra16x16ACLevel_0_s ||
				   residual_state == `LumaLevel_0_s ||
				   residual_state == `ChromaACLevel_Cb_0_s ||
				   residual_state == `ChromaACLevel_Cr_0_s );
				   
assign cavlc_start = residual_start && !all0_blk;
assign cavlc_finish = cavlc_valid && !cavlc_valid_s;
assign transform_start = residual_start && all0_blk || cavlc_finish;
assign transform_finish = transform_valid && !transform_valid_s;
always @(posedge clk or negedge rst_n)
begin
	if (!rst_n) 
		transform_finished <= 0;
	else if (ena) begin
		if (residual_start || start_of_MB)
			transform_finished <= 0;
		else if (transform_finish)
			transform_finished <= 1;
	end
end
assign residual_valid = transform_finish || transform_finished;
assign out_ram_wr = transform_finish && mb_pred_inter_sel && is_residual_not_dc;

always @(posedge clk or negedge rst_n)
if (~rst_n)
	out_ram_wr_addr <= 0;
else if (out_ram_wr)
	out_ram_wr_addr <= out_ram_wr_addr + 1;
else if (start_of_MB)
	out_ram_wr_addr <= 0;

always @(posedge clk or negedge rst_n)
if (~rst_n)
	out_ram_wr_addr_reg <= 0;
else 
	out_ram_wr_addr_reg <= out_ram_wr_addr;


always @(posedge clk or negedge rst_n)
if (~rst_n)
	out_ram_rd_addr <= 0;
else if (out_ram_rd)
	out_ram_rd_addr <= out_ram_rd_addr + 1;
else if (start_of_MB)
	out_ram_rd_addr <= 0;
/*
always @(posedge clk or negedge rst_n)
if (~rst_n)
	out_ram_wr_addr_reg <= 0;
else 
	out_ram_wr_addr_reg <= out_ram_wr_addr;

always @(*)
if (out_ram_wr)
	out_ram_wr_addr <= out_ram_wr_addr_reg + 1;
else if (start_of_MB)
	out_ram_wr_addr <= 0;
else
	out_ram_wr_addr <= out_ram_wr_addr_reg;
*/
//----------------------
// curr_QP
//----------------------
always @(posedge clk or negedge rst_n)
if (!rst_n)
	curr_QP <= 0;
else if(ena)begin
	if (residual_state == `Intra16x16DCLevel_s || 
		residual_state == `Intra16x16ACLevel_s || 
		residual_state == `LumaLevel_s)
		curr_QP <= qp;
	else
		curr_QP <= qp_c;
end

endmodule
