//--------------------------------------------------------------------------------------------------
// Copyright (C) 2013-2017 qiu bin 
// All rights reserved   
// Design    : bitstream_p
// Author(s) : qiu bin
// Email     : chat1@126.com
// Phone 15957074161
// QQ:1517642772             
//-------------------------------------------------------------------------------------------------

`timescale 1 ns / 10 ps
module sync_ram(
	aclr,
	data,
	rdclk,
	wrclk,
	q);
parameter data_bits = 32;
	input aclr;
	input	[data_bits-1:0]  data;
	input	  rdclk;
	input	  wrclk;
	output	 [data_bits-1:0]  q;

wire [2:0] wraddress;
wire [2:0] rdaddress;

assign wraddress = 0;	
assign rdaddress = 0;

dp_ram #(.DATA_WIDTH(data_bits), .ADDR_WIDTH(3)) dp_ram
(
	.aclr(aclr),
	.data(data),
	.rdaddress(rdaddress), 
	.wraddress(wraddress),
	.wren(1'b1),
	.rdclock(rdclk), 
	.wrclock(wrclk),
	.q(q)
);

endmodule
