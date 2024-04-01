//--------------------------------------------------------------------------------------------------
// Copyright (C) 2013-2017 qiu bin 
// All rights reserved   
// Design    : bitstream_p
// Author(s) : qiu bin
// Email     : chat1@126.com
// Phone 15957074161
// QQ:1517642772             
//-------------------------------------------------------------------------------------------------

module debug_stuff(
	input clk,
	input rst_n,
	input rbsp_buffer_valid,
	input residual_start,
	input intra_pred_start,
	input sum_start,
	input residual_valid,
	input intra_pred_valid,
	input sum_valid,

	output reg [63:0] counter,
	output reg [63:0] buffer_invalid_counter,
	output reg [63:0] residual_counter,
	output reg [63:0] intra_pred_counter,
	output reg [63:0] sum_pred_counter
);

reg decode_started;
reg residual_started;
reg intra_pred_started;
reg sum_started;

always @(posedge clk or negedge rst_n)
if (~rst_n)
	decode_started <= 0;
else if (residual_start)
	decode_started <= 1'b1;

always @(posedge clk or negedge rst_n)
if (~rst_n)
	buffer_invalid_counter <= 64'd0;
else if (decode_started && ~rbsp_buffer_valid)
	buffer_invalid_counter <= buffer_invalid_counter + 1'b1;


always @(posedge clk or negedge rst_n)
if (~rst_n)
	residual_started <= 0;
else if (residual_start)
	residual_started <= 1'b1;
else if (residual_valid)
	residual_started <= 1'b0;

always @(posedge clk or negedge rst_n)
if (~rst_n)
	intra_pred_started <= 0;
else if (intra_pred_start)
	intra_pred_started <= 1'b1;
else if (intra_pred_valid)
	intra_pred_started <= 1'b0;

always @(posedge clk or negedge rst_n)
if (~rst_n)
	sum_started <= 0;
else if (sum_start)
	sum_started <= 1'b1;
else if (sum_valid)
	sum_started <= 1'b0;

always @(posedge clk or negedge rst_n)
if (~rst_n)
	counter <= 0;
else if (decode_started)
	counter <= counter + 1'b1;

always @(posedge clk or negedge rst_n)
if (~rst_n)
	residual_counter <= 0;
else if (decode_started && residual_started)
	residual_counter <= residual_counter + 1'b1;
	
always @(posedge clk or negedge rst_n)
if (~rst_n)
	intra_pred_counter <= 0;
else if (decode_started && intra_pred_started)
	intra_pred_counter <= intra_pred_counter + 1'b1;
	
always @(posedge clk or negedge rst_n)
if (~rst_n)
	sum_pred_counter <= 0;
else if (decode_started && sum_started)
	sum_pred_counter <= sum_pred_counter + 1'b1;
	
endmodule
	
