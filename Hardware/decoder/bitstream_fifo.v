//--------------------------------------------------------------------------------------------------
// Copyright (C) 2013-2017 qiu bin 
// All rights reserved   
// Design    : bitstream_p
// Author(s) : qiu bin
// Email     : chat1@126.com
// Phone 15957074161
// QQ:1517642772             
//-------------------------------------------------------------------------------------------------


//`define BS_TYPE_TS
`ifdef BS_TYPE_TS

module bitstream_fifo 
(
	read_clk,
	rst_n,
	read,
	stream_out,
	stream_out_valid,
	stream_over,
	
    write_clk,
    write_data,
    write_valid,
    write_ready
);
input			write_clk;
input       read_clk;
input 			rst_n;
input [7:0] write_data;
input write_valid;
output write_ready;
(* KEEP = "TRUE" *)(*mark_debug = "true"*)input			read;
(* KEEP = "TRUE" *)(*mark_debug = "true"*)output	[7:0]	stream_out;
(* KEEP = "TRUE" *)(*mark_debug = "true"*)output			stream_out_valid;
(* KEEP = "TRUE" *)(*mark_debug = "true"*)output          stream_over;

wire [10:0] usedw;
wire full;

wire empty;
assign stream_out_valid = ~empty;
wire [7:0] nal_data;

stream_fifo stream_fifo_inst(
	.rst(~rst_n),
	.din(nal_data),
	.rd_clk(read_clk),
	.rd_en(read),
	.wr_clk(write_clk),
	.wr_en(nal_data_valid && nal_data_ready),
	.dout(stream_out),
	.empty(empty),
	.full(full),
	.wr_data_count());

assign nal_data_ready = ~full;

reg ts_data_in_valid;
wire ts_data_out_ready;
wire [7:0] ts_data_out;
wire ts_data_out_valid;
wire ts_data_out_sync;

ts_adapter ts_adapter_inst(
	.clk(write_clk),
	.reset(~rst_n),
	.i_tdata(write_data),
	.i_tvalid(write_valid),
	.i_tready(write_ready),
	.o_tdata(ts_data_out),
	.o_tvalid(ts_data_out_valid),
	.o_tready(ts_data_out_ready),
	.sync(ts_data_out_sync)
);

ts_checker ts_checker_inst(
	.clk(write_clk), 
	.reset(~rst_n),
	.i_ts_sync(ts_data_out_sync),
	.i_tdata(ts_data_out),
	.i_tvalid(ts_data_out_valid),
	.i_tready(ts_data_out_ready),
	.o_tdata(nal_data),
	.o_tvalid(nal_data_valid), 
	.o_tready(nal_data_ready)
);

/*
stream_fifo stream_fifo (
	.aclr(!rst_n),
	.clock(clk),
	.data(file_data),
	.rdreq(read),
	.wrreq(),
	.empty(empty),
	.full(full),
	.q(),
	.usedw(usedw)
);
*/

endmodule
`else
module bitstream_fifo 
(
	read_clk,
	rst_n,
	read,
	stream_out,
	stream_out_valid,
	stream_over,
	
    write_clk,
    write_data,
    write_valid,
    write_ready
);
input			write_clk;
input       read_clk;
input 			rst_n;
input [7:0] write_data;
input write_valid;
output write_ready;
(* KEEP = "TRUE" *)(*mark_debug = "true"*)input			read;
(* KEEP = "TRUE" *)(*mark_debug = "true"*)output	[7:0]	stream_out;
(* KEEP = "TRUE" *)(*mark_debug = "true"*)output			stream_out_valid;
(* KEEP = "TRUE" *)(*mark_debug = "true"*)output          stream_over;

wire [10:0] usedw;
wire full;

wire empty;
assign stream_out_valid = ~empty;
/*
stream_fifo stream_fifo_inst(
	.rst(~rst_n),
	.din(write_data),
	.rd_clk(read_clk),
	.rd_en(read),
	.wr_clk(write_clk),
	.wr_en(write_valid),
	.dout(stream_out),
	.empty(empty),
	.full(full),
	.wr_data_count(usedw));
*/
dc_fifo #(.data_bits(8), .addr_bits(9)) stream_fifo_inst(
	.aclr(~rst_n),
	.wr_clk(write_clk),
	.wr(write_valid && write_ready),
	.wr_data(write_data),
	.wr_full(full),
	.wr_words_avail(),
	.rd_clk(read_clk),
	.rd(read),
	.rd_data(stream_out),
	.rd_words_avail(),
	.rd_empty(empty)
);

assign write_ready = ~full;
/*
stream_fifo stream_fifo (
	.aclr(!rst_n),
	.clock(clk),
	.data(file_data),
	.rdreq(read),
	.wrreq(),
	.empty(empty),
	.full(full),
	.q(),
	.usedw(usedw)
);
*/

endmodule
`endif
