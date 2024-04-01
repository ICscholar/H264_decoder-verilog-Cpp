//--------------------------------------------------------------------------------------------------
// Copyright (C) 2013-2017 qiu bin 
// All rights reserved   
// Design    : bitstream_p
// Author(s) : qiu bin
// Email     : chat1@126.com
// Phone 15957074161
// QQ:1517642772             
//-------------------------------------------------------------------------------------------------

`define _SIM
`ifdef _SIM

// 条件为真时,定义一个可仿真的dc_fifo模块

// 条件为假时,定义一个直接使用IP的dc_fifo模块
module dc_fifo
(
	aclr,

	wr_clk,
	wr,
	wr_data,
	wr_full,
	wr_words_avail,
		
	rd_clk,
	rd,
	rd_data,
	rd_words_avail,
	rd_empty
);
parameter data_bits = 16;
parameter addr_bits = 7;
input  aclr;
input  wr_clk;
input  wr;
input  [data_bits-1:0] wr_data;
output reg wr_full;

input  rd_clk;
input  rd;
output [data_bits-1:0] rd_data;
output [addr_bits-1:0] rd_words_avail;
output [addr_bits-1:0] wr_words_avail;
output reg rd_empty;

reg [data_bits-1:0] rd_data;

reg [addr_bits-1:0] wr_addr;
reg [data_bits-1:0] mem[0: (1 << addr_bits) - 1];

reg [addr_bits-1:0] rd_addr;
wire [addr_bits-1:0] wr_addr_sync_in;
wire [addr_bits-1:0] rd_addr_sync_in;
wire [addr_bits-1:0] wr_addr_synced;
wire [addr_bits-1:0] rd_addr_synced;

assign wr_addr_sync_in = wr ? wr_addr + 1'b1 : wr_addr;
assign rd_addr_sync_in = rd ? rd_addr + 1'b1 : rd_addr;

sync_ram #(addr_bits) sync_ram_inst0(
	.aclr(aclr),
	.data(wr_addr_sync_in),
	.rdclk(rd_clk),
	.wrclk(wr_clk),
	.q(wr_addr_synced)
);


sync_ram #(addr_bits) sync_ram_inst1(
	.aclr(aclr),
	.data(rd_addr_sync_in),
	.rdclk(wr_clk),
	.wrclk(rd_clk),
	.q(rd_addr_synced)
);
	
always @(posedge wr_clk or posedge aclr)
if (aclr) 
	wr_addr <= 0;
else if (wr) begin
	wr_addr <= wr_addr + 1;
	mem[wr_addr] <= wr_data;
end



assign	wr_words_avail = rd_addr_synced <= wr_addr ? wr_addr - rd_addr_synced : wr_addr + (1 << addr_bits) - rd_addr_synced ;

always @(*)
	wr_full <= wr_words_avail > (1 << addr_bits) - 3;
	
always @(posedge rd_clk or posedge aclr)
if (aclr) begin
	rd_data <= 0;
	rd_addr <= 0;
end
else if (rd) begin
	rd_addr <= rd_addr + 1'b1;
	rd_data <= mem[rd_addr];
end

assign	rd_words_avail = rd_addr <= wr_addr_synced ? wr_addr_synced - rd_addr : wr_addr_synced + (1 << addr_bits) - rd_addr;

	
always @(*)
if (wr_addr_synced == rd_addr)
	rd_empty <= 1;
else
	rd_empty <= 0;


//synopsys translate_off
always @(posedge wr_clk)
if (wr && (wr_addr == rd_addr - 1))
	$display("%t : %m, write while fifo is full", $time);

always @(posedge rd_clk)
if (rd && wr_addr_synced == rd_addr)
	$display("%t : %m, read while fifo is empty", $time);
//synopsys translate_on

endmodule

`else
module dc_fifo
(
	aclr,

	wr_clk,
	wr,
	wr_data,
	wr_full,
		
	rd_clk,
	rd,
	rd_data,
	rd_words_avail,
	rd_empty
);
parameter addr_bits = 7;
parameter data_bits = 16;
input  aclr;
input  wr_clk;
input  wr;
input  [71:0] wr_data;
output wr_full;

input  rd_clk;
input  rd;
output [71:0] rd_data;
output rd_words_avail;
output rd_empty;

inter_ref_p_fifo p_fifo(
    .rst(aclr),
    .wr_clk(wr_clk),
    .rd_clk(rd_clk),
    .din(wr_data),
    .wr_en(wr),
    .rd_en(rd),
    .dout(rd_data),
    .full(wr_full),
    .empty(rd_empty)
  );
 endmodule
  
`endif
