//--------------------------------------------------------------------------------------------------
// Copyright (C) 2013-2017 qiu bin 
// All rights reserved   
// Design    : bitstream_p
// Author(s) : qiu bin
// Email     : chat1@126.com
// Phone 15957074161
// QQ:1517642772             
//-------------------------------------------------------------------------------------------------

module ext_mem_reader_cmd_translate(
	input clk,
	input rst_n,
	output reg ext_mem_reader_cmd_ready,
	input [71:0] ext_mem_reader_cmd_data,
	input ext_mem_reader_cmd_valid,

	output reg [31:0] ext_mem_reader_addr,
	output ext_mem_reader_valid,
	input ext_mem_reader_ready

);
parameter DataWidth = 32;

wire [71:0] axis_cmd_data;
wire [22:0] axis_cmd_BTT = axis_cmd_data[22:0];
wire [31:0] axis_cmd_SADDR = axis_cmd_data[63:32];
wire wr_full;
reg rd;
wire rd_empty;
reg [2:0] state;
reg [9:0] addr_offset;
reg ext_mem_reader_valid_reg;
reg ext_mem_reader_valid_and_reg;
assign ext_mem_reader_valid = ext_mem_reader_valid_and_reg & ext_mem_reader_valid_reg;
always @(*)
	ext_mem_reader_cmd_ready <= ~wr_full;	

always @(posedge clk)
	ext_mem_reader_valid_and_reg <= 1'b1;//$random() % 2;	

dc_fifo #(72,3) dc_fifo(
	.aclr(~rst_n),

	.wr_clk(clk),
	.wr(ext_mem_reader_cmd_valid && ext_mem_reader_cmd_ready),
	.wr_data(ext_mem_reader_cmd_data),
	.wr_full(wr_full),
	.wr_words_avail(),
		
	.rd_clk(clk),
	.rd(rd),
	.rd_data(axis_cmd_data),
	.rd_words_avail(),
	.rd_empty(rd_empty)
);
parameter
Idle = 3'd0,
FetchCmd = 3'd1,
SetAddr = 3'd2,
IncAddr = 3'd3;

always @(posedge clk or negedge rst_n)
if (~rst_n) begin
	state <= Idle;
	rd <= 0;
	addr_offset <= 0;
	ext_mem_reader_addr <= 0;
	ext_mem_reader_valid_reg <= 0;
end
else if (ext_mem_reader_ready) begin
	rd <= 1'b0;
	case (state)
	Idle:begin
		ext_mem_reader_valid_reg <= 1'b0;
		if (~rd_empty) begin
			state <= FetchCmd;
			rd <= 1'b1;
		end
	end
	FetchCmd:begin
		state <= SetAddr;
		rd <= 1'b0;
	end
	SetAddr:begin
		state <= IncAddr;
		addr_offset <= 0;
		ext_mem_reader_addr <= axis_cmd_SADDR;
		
	end
	IncAddr:begin
		ext_mem_reader_valid_reg <= 1'b1;
		if (ext_mem_reader_valid_and_reg && addr_offset + DataWidth/8 < axis_cmd_BTT) begin
			addr_offset <= addr_offset + DataWidth / 8;
			ext_mem_reader_addr <= ext_mem_reader_addr + DataWidth / 8;			
		end
		else if (ext_mem_reader_valid_and_reg )begin
			state <= Idle;
		end
	end
	endcase
end

endmodule

