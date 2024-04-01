`timescale 1 ns / 10 ps
module sync_ram_display(
	aclr,
	data,
	rdclk,
	rdreq,
	wrclk,
	wrreq,
	q,
	rdusedw,
	wrusedw);
parameter data_bits = 41;
parameter addr_bits = 4;
input	  aclr;
	input	[data_bits-1:0]  data;
	input	  rdclk;
	input	  rdreq;
	input	  wrclk;
	input	  wrreq;
	output	 [data_bits-1:0]  q;
	output	[3:0]  rdusedw;
	output	[3:0]  wrusedw;

wire [addr_bits-1:0] wraddress;
wire [addr_bits-1:0] rdaddress;

assign wraddress = 0;	
assign rdaddress = 0;

dp_ram_display #(.DATA_WIDTH(data_bits), .ADDR_WIDTH(addr_bits)) dp_ram
(
	.data(data),
	.rdaddress(rdaddress), 
	.wraddress(wraddress),
	.wren(1'b1),
	.rdclock(rdclk), 
	.wrclock(wrclk),
	.q(q)
);

endmodule
