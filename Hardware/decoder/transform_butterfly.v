//--------------------------------------------------------------------------------------------------
// Copyright (C) 2013-2017 qiu bin 
// All rights reserved   
// Design    : bitstream_p
// Author(s) : qiu bin
// Email     : chat1@126.com
// Phone 15957074161
// QQ:1517642772             
//-------------------------------------------------------------------------------------------------


module transform_butterfly
(
	input clk,
	input rst_n,
	input ena,
	input DHT_sel,
	input signed [15:0] butterfly_in_0,
	input signed [15:0] butterfly_in_1,
	input signed [15:0] butterfly_in_2,
	input signed [15:0] butterfly_in_3,
	input signed [15:0] butterfly_in_4,
	input signed [15:0] butterfly_in_5,
	input signed [15:0] butterfly_in_6,
	input signed [15:0] butterfly_in_7,
	input signed [15:0] butterfly_in_8,
	input signed [15:0] butterfly_in_9,
	input signed [15:0] butterfly_in_10,
	input signed [15:0] butterfly_in_11,
	input signed [15:0] butterfly_in_12,
	input signed [15:0] butterfly_in_13,
	input signed [15:0] butterfly_in_14,
	input signed [15:0] butterfly_in_15,

	output signed [15:0] butterfly_out_0,
	output signed [15:0] butterfly_out_1,
	output signed [15:0] butterfly_out_2,
	output signed [15:0] butterfly_out_3,
	output signed [15:0] butterfly_out_4,
	output signed [15:0] butterfly_out_5,
	output signed [15:0] butterfly_out_6,
	output signed [15:0] butterfly_out_7,
	output signed [15:0] butterfly_out_8,
	output signed [15:0] butterfly_out_9,
	output signed [15:0] butterfly_out_10,
	output signed [15:0] butterfly_out_11,
	output signed [15:0] butterfly_out_12,
	output signed [15:0] butterfly_out_13,
	output signed [15:0] butterfly_out_14,
	output signed [15:0] butterfly_out_15
);


reg signed [15:0] temp_0;
reg signed [15:0] temp_1;
reg signed [15:0] temp_2;
reg signed [15:0] temp_3;
reg signed [15:0] temp_4;
reg signed [15:0] temp_5;
reg signed [15:0] temp_6;
reg signed [15:0] temp_7;
reg signed [15:0] temp_8;
reg signed [15:0] temp_9;
reg signed [15:0] temp_10;
reg signed [15:0] temp_11;
reg signed [15:0] temp_12;
reg signed [15:0] temp_13;
reg signed [15:0] temp_14;
reg signed [15:0] temp_15;

wire signed [15:0] butterfly_tmp_1;
wire signed [15:0] butterfly_tmp_3;
wire signed [15:0] butterfly_tmp_5;
wire signed [15:0] butterfly_tmp_7;
wire signed [15:0] butterfly_tmp_9;
wire signed [15:0] butterfly_tmp_11;
wire signed [15:0] butterfly_tmp_13;
wire signed [15:0] butterfly_tmp_15;

assign butterfly_tmp_1 = DHT_sel?butterfly_in_1:butterfly_in_1>>>1;
assign butterfly_tmp_3 = DHT_sel?butterfly_in_3:butterfly_in_3>>>1;
assign butterfly_tmp_5 = DHT_sel?butterfly_in_5:butterfly_in_5>>>1;
assign butterfly_tmp_7 = DHT_sel?butterfly_in_7:butterfly_in_7>>>1;
assign butterfly_tmp_9 = DHT_sel?butterfly_in_9:butterfly_in_9>>>1;
assign butterfly_tmp_11 = DHT_sel?butterfly_in_11:butterfly_in_11>>>1;
assign butterfly_tmp_13 = DHT_sel?butterfly_in_13:butterfly_in_13>>>1;
assign butterfly_tmp_15 = DHT_sel?butterfly_in_15:butterfly_in_15>>>1;

always @(posedge clk or negedge rst_n)
if (~rst_n)begin
	temp_0 <= 0;
	temp_1 <= 0;	
	temp_2 <= 0;
	temp_3 <= 0;
	temp_4 <= 0;
	temp_5 <= 0;	
	temp_6 <= 0;
	temp_7 <= 0;
	temp_8 <= 0;
	temp_9 <= 0;	
	temp_10 <= 0;
	temp_11 <= 0;
	temp_12 <= 0;
	temp_13 <= 0;	
	temp_14 <= 0;
	temp_15 <= 0;
end
else if(ena)begin
	temp_0 <= butterfly_in_0 + butterfly_in_2;
	temp_1 <= butterfly_in_0 - butterfly_in_2;	
	temp_2 <= butterfly_tmp_1 - butterfly_in_3;
	temp_3 <= butterfly_tmp_3 + butterfly_in_1;

	temp_4 <= butterfly_in_4 + butterfly_in_6;
	temp_5 <= butterfly_in_4 - butterfly_in_6;	
	temp_6 <= butterfly_tmp_5 - butterfly_in_7;
	temp_7 <= butterfly_tmp_7 + butterfly_in_5;

	temp_8 <= butterfly_in_8 + butterfly_in_10;
	temp_9 <= butterfly_in_8 - butterfly_in_10;	
	temp_10 <= butterfly_tmp_9 - butterfly_in_11;
	temp_11 <= butterfly_tmp_11 + butterfly_in_9;

	temp_12 <= butterfly_in_12 + butterfly_in_14;
	temp_13 <= butterfly_in_12 - butterfly_in_14;	
	temp_14 <= butterfly_tmp_13 - butterfly_in_15;
	temp_15 <= butterfly_tmp_15 + butterfly_in_13;
end

assign	butterfly_out_0 = temp_0 + temp_3;
assign	butterfly_out_1 = temp_1 + temp_2;
assign	butterfly_out_2 = temp_1 - temp_2;
assign	butterfly_out_3 = temp_0 - temp_3;

assign	butterfly_out_4 = temp_4 + temp_7;
assign	butterfly_out_5 = temp_5 + temp_6;
assign	butterfly_out_6 = temp_5 - temp_6;
assign	butterfly_out_7 = temp_4 - temp_7;

assign	butterfly_out_8 = temp_8 + temp_11;
assign	butterfly_out_9 = temp_9 + temp_10;
assign	butterfly_out_10 = temp_9 - temp_10;
assign	butterfly_out_11 = temp_8 - temp_11;

assign	butterfly_out_12 = temp_12 + temp_15;
assign	butterfly_out_13 = temp_13 + temp_14;
assign	butterfly_out_14 = temp_13 - temp_14;
assign	butterfly_out_15 = temp_12 - temp_15;

endmodule


