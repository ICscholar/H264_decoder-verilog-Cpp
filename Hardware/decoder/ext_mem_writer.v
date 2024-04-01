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

module ext_mem_writer(
	//global signals
	input clk,
	input rst_n,

	//misc control and data signals
	input start,
	input start_of_frame,
	input end_of_MB,
	input last_mb_write_start,
	input [`mb_x_bits + `mb_y_bits - 1:0] mb_index,
	input [`mb_x_bits + `mb_y_bits :0] total_mbs_one_frame,
	input [4:0] blk4x4_counter,
	input [2:0] pic_num_2to0,
	input [`mb_x_bits - 1:0] mb_x_in,
	input [`mb_y_bits - 1:0] mb_y_in,
	input [`mb_x_bits :0] pic_width_in_mbs,
	input [`mb_y_bits :0] pic_height_in_map_units,

	//interface to sum
	input [7:0] sum_0,
	input [7:0] sum_1,
	input [7:0] sum_2,
	input [7:0] sum_3,
	input [7:0] sum_4,
	input [7:0] sum_5,
	input [7:0] sum_6,
	input [7:0] sum_7,
	input [7:0] sum_8,
	input [7:0] sum_9,
	input [7:0] sum_10,
	input [7:0] sum_11,
	input [7:0] sum_12,
	input [7:0] sum_13,
	input [7:0] sum_14,
	input [7:0] sum_15,           
	output      idle,

	//interface to ext_mem_hub
	input  									 ext_mem_writer_ready,
	output reg  							 ext_mem_writer_burst,
	output reg [7:0] 						 ext_mem_writer_burst_len_minus1,
	output reg [`ext_buf_mem_addr_width-1:0] ext_mem_writer_addr,
	output reg[`ext_buf_mem_data_width-1:0]	 ext_mem_writer_data,
	output reg      						 ext_mem_writer_valid
);
parameter MBsCacheWidth = 4; //cache 4 MBs for writing
parameter Log2MBsCacheWidth = 2; //cache 4 MBs for writing
parameter TotalWriteCount = (4*16 + 2*2*8)*MBsCacheWidth;
parameter CbStartCount = (4*16)*MBsCacheWidth;
parameter CrStartCount = (4*16 + 2*8)*MBsCacheWidth;

///////////////////////////////////
wire [31:0] blk_data_row0;
wire [31:0] blk_data_row1;
wire [31:0] blk_data_row2;
wire [31:0] blk_data_row3;
wire luma_wr;
wire [4+Log2MBsCacheWidth:0] luma_wr_addr;
wire chroma_wr;
wire [3+Log2MBsCacheWidth:0] chroma_wr_addr;

wire [31:0] luma_row0_data_out;
wire [31:0] luma_row1_data_out;
wire [31:0] luma_row2_data_out;
wire [31:0] luma_row3_data_out;
wire [31:0] chroma_row0_data_out;
wire [31:0] chroma_row1_data_out;
wire [31:0] chroma_row2_data_out;
wire [31:0] chroma_row3_data_out;
wire [4+Log2MBsCacheWidth:0] luma_rd_addr_row0;
wire [4+Log2MBsCacheWidth:0] luma_rd_addr_row1;
wire [4+Log2MBsCacheWidth:0] luma_rd_addr_row2;
wire [4+Log2MBsCacheWidth:0] luma_rd_addr_row3;
wire [3+Log2MBsCacheWidth:0] chroma_rd_addr_row0;
wire [3+Log2MBsCacheWidth:0] chroma_rd_addr_row1;
wire [3+Log2MBsCacheWidth:0] chroma_rd_addr_row2;
wire [3+Log2MBsCacheWidth:0] chroma_rd_addr_row3;
wire rd_ena;
reg [3:0] state;
reg [6+Log2MBsCacheWidth:0] counter;
reg [6+Log2MBsCacheWidth:0] counter_reg;
reg data_valid;

assign blk_data_row0 = {sum_3,sum_2,sum_1,sum_0};
assign blk_data_row1 = {sum_7,sum_6,sum_5,sum_4};
assign blk_data_row2 = {sum_11,sum_10,sum_9,sum_8};
assign blk_data_row3 = {sum_15,sum_14,sum_13,sum_12};
assign rd_ena = ext_mem_writer_ready;
assign ena = ext_mem_writer_ready;
//store 2 mb, one for write,the other for read
mb_ram #(5+Log2MBsCacheWidth, 32) luma_row0(
 .clk(clk),
 .wr(luma_wr),
 .rd_ena(rd_ena), 
 .wr_addr(luma_wr_addr), 
 .rd_addr(luma_rd_addr_row0),
 .data_in(blk_data_row0), 
 .data_out(luma_row0_data_out)
);

mb_ram #(5+Log2MBsCacheWidth, 32) luma_row1(
 .clk(clk),
 .wr(luma_wr), 
 .rd_ena(rd_ena), 
 .wr_addr(luma_wr_addr), 
 .rd_addr(luma_rd_addr_row1), 
 .data_in(blk_data_row1), 
 .data_out(luma_row1_data_out)
);

mb_ram #(5+Log2MBsCacheWidth, 32) luma_row2(
 .clk(clk),
 .wr(luma_wr), 
 .rd_ena(rd_ena), 
 .wr_addr(luma_wr_addr), 
 .rd_addr(luma_rd_addr_row2),
 .data_in(blk_data_row2), 
 .data_out(luma_row2_data_out)
);

mb_ram #(5+Log2MBsCacheWidth, 32) luma_row3(
 .clk(clk),
 .wr(luma_wr), 
 .rd_ena(rd_ena), 
 .wr_addr(luma_wr_addr), 
 .rd_addr(luma_rd_addr_row3), 
 .data_in(blk_data_row3), 
 .data_out(luma_row3_data_out)
);

mb_ram #(4+Log2MBsCacheWidth, 32) chroma_row0(
 .clk(clk),
 .wr(chroma_wr), 
 .rd_ena(rd_ena), 
 .wr_addr(chroma_wr_addr), 
 .rd_addr(chroma_rd_addr_row0),
 .data_in(blk_data_row0), 
 .data_out(chroma_row0_data_out)
);

mb_ram #(4+Log2MBsCacheWidth, 32) chroma_row1(
 .clk(clk),
 .wr(chroma_wr), 
 .rd_ena(rd_ena), 
 .wr_addr(chroma_wr_addr), 
 .rd_addr(chroma_rd_addr_row1), 
 .data_in(blk_data_row1), 
 .data_out(chroma_row1_data_out)
);

mb_ram #(4+Log2MBsCacheWidth, 32) chroma_row2(
 .clk(clk),
 .wr(chroma_wr), 
 .rd_ena(rd_ena), 
 .wr_addr(chroma_wr_addr), 
 .rd_addr(chroma_rd_addr_row2),
 .data_in(blk_data_row2), 
 .data_out(chroma_row2_data_out)
);

mb_ram #(4+Log2MBsCacheWidth, 32) chroma_row3(
 .clk(clk),
 .wr(chroma_wr), 
 .rd_ena(rd_ena), 
 .wr_addr(chroma_wr_addr), 
 .rd_addr(chroma_rd_addr_row3), 
 .data_in(blk_data_row3), 
 .data_out(chroma_row3_data_out)
);

reg [`mb_x_bits - 1:0] mb_x_writing;
reg [`mb_y_bits - 1:0] mb_y_writing;
reg write_to_ram_start_p;
reg write_to_ram_start;
wire [Log2MBsCacheWidth-1:0] mb_index_lower_bits_p1;
assign mb_index_lower_bits_p1 = mb_index[Log2MBsCacheWidth-1:0] + 1;

reg is_luma;
reg is_cb;
reg is_cr;

always @(*)
if (counter < 4*16*MBsCacheWidth) begin
	is_luma <= 1'b1;
	is_cb <= 1'b0;
	is_cr <= 1'b0;
end
else if (counter < 4*16*MBsCacheWidth + 2*8*MBsCacheWidth) begin
	is_luma <= 1'b0;
	is_cb <= 1'b1;
	is_cr <= 1'b0;
end
else begin
	is_luma <= 1'b0;
	is_cb <= 1'b0;
	is_cr <= 1'b1;
end

reg is_reg_luma;
reg is_reg_cb;
reg is_reg_cr;

always @(*)
if (counter_reg < 4*16*MBsCacheWidth) begin
	is_reg_luma <= 1'b1;
	is_reg_cb <= 1'b0;
	is_reg_cr <= 1'b0;
end
else if (counter_reg < 4*16*MBsCacheWidth + 2*8*MBsCacheWidth) begin
	is_reg_luma <= 1'b0;
	is_reg_cb <= 1'b1;
	is_reg_cr <= 1'b0;
end
else begin
	is_reg_luma <= 1'b0;
	is_reg_cb <= 1'b0;
	is_reg_cr <= 1'b1;
end

always @(posedge clk or negedge rst_n)
if (!rst_n) begin
	mb_x_writing <= 0;
	mb_y_writing <= 0;
	write_to_ram_start_p <= 0;
	write_to_ram_start <= 0;
end
else if (end_of_MB && mb_index_lower_bits_p1 == 0 && mb_index != total_mbs_one_frame-1 || last_mb_write_start) begin
	mb_x_writing <= mb_x_in - MBsCacheWidth + 1;
	mb_y_writing <= mb_y_in;
	write_to_ram_start_p <= 1'b1;
	write_to_ram_start <= 1'b0;
end
else begin
	write_to_ram_start_p <= 1'b0;
	write_to_ram_start <= write_to_ram_start_p;
end

//ram write
assign luma_wr_addr = { mb_index[Log2MBsCacheWidth],
					   blk4x4_counter[3], blk4x4_counter[1], 
					    mb_index[Log2MBsCacheWidth-1:0], blk4x4_counter[2], blk4x4_counter[0]};
assign chroma_wr_addr = { mb_index[Log2MBsCacheWidth],
   						blk4x4_counter[2],
						blk4x4_counter[1],
					   	mb_index[Log2MBsCacheWidth-1:0], blk4x4_counter[0]};

assign luma_wr = ~blk4x4_counter[4] && start;
assign chroma_wr = blk4x4_counter[4] && start;
wire [4+Log2MBsCacheWidth:0] luma_rd_addr;
wire [3+Log2MBsCacheWidth:0] chroma_rd_addr;

assign luma_rd_addr = {mb_x_writing[Log2MBsCacheWidth], counter[5+Log2MBsCacheWidth-:2], counter[1+Log2MBsCacheWidth:0]};
assign chroma_rd_addr = {mb_x_writing[Log2MBsCacheWidth], counter[4+Log2MBsCacheWidth-:2], counter[Log2MBsCacheWidth:0]};
//ram read
assign luma_rd_addr_row0 = is_luma && counter[3+Log2MBsCacheWidth:2+Log2MBsCacheWidth] == 0 ? luma_rd_addr : 0;
assign luma_rd_addr_row1 = is_luma && counter[3+Log2MBsCacheWidth:2+Log2MBsCacheWidth] == 1 ? luma_rd_addr : 0;
assign luma_rd_addr_row2 = is_luma && counter[3+Log2MBsCacheWidth:2+Log2MBsCacheWidth] == 2 ? luma_rd_addr : 0;
assign luma_rd_addr_row3 = is_luma && counter[3+Log2MBsCacheWidth:2+Log2MBsCacheWidth] == 3 ? luma_rd_addr : 0;


assign chroma_rd_addr_row0 = ~is_luma && counter[2+Log2MBsCacheWidth:1+Log2MBsCacheWidth] == 0 ? chroma_rd_addr : 0;
assign chroma_rd_addr_row1 = ~is_luma && counter[2+Log2MBsCacheWidth:1+Log2MBsCacheWidth] == 1 ? chroma_rd_addr : 0;
assign chroma_rd_addr_row2 = ~is_luma && counter[2+Log2MBsCacheWidth:1+Log2MBsCacheWidth] == 2 ? chroma_rd_addr : 0;
assign chroma_rd_addr_row3 = ~is_luma && counter[2+Log2MBsCacheWidth:1+Log2MBsCacheWidth] == 3 ? chroma_rd_addr : 0;

assign idle = state == 0;
always @(posedge clk or negedge rst_n)
if (!rst_n) begin
    state <= 0;
	counter <= 0;
	counter_reg <= 0;
	data_valid <= 0;
	ext_mem_writer_valid <= 0;
end
else begin
	if (state == 0) begin
	   if (write_to_ram_start) begin
			state <= 1'b1;
			counter <= 0;
			counter_reg <= 0;
			data_valid <= 0;
			ext_mem_writer_valid <= 0;
		end
	end
	else if (ena && state <= 4) begin//state == 1
		ext_mem_writer_valid <= data_valid;
		if (counter < TotalWriteCount - 1) begin 
			counter <= counter + 1'b1;
			data_valid <= 1'b1;
		end
		else begin
			state <= 8;
		end

		if (counter == CbStartCount-1)
			state <= 2;
		else if (counter == CrStartCount-1)
			state <= 4;

		counter_reg <= counter;
	end 
	else if (ena && state == 8) begin // because of the ext_mem_writer_data is valid after 2 clocks the addr is given, so need to add external 2 clocks to transfer data 
		state <= 9;
	end
	else if (ena && state == 9) begin
		state <= 0;
		ext_mem_writer_valid <= 0;
	end
end

///////////////////////////
//ready         1   1   0   1   0   0   1   0   0   0   1   1   0   1
//counter       0   1   2   2   3   3   3   4   4   4   4   5   6   6
//counter_reg   X   0   1   1   2   2   2   3   3   3   3   4   5   0
// data         X   X   0   0   1   1   1   2   2   2   2   3   4   4
////////////////////////////////
reg [`ext_buf_mem_addr_width-1:0] luma_addr_base;
reg [`ext_buf_mem_addr_width-1:0] cb_addr_base;
reg [`ext_buf_mem_addr_width-1:0] cr_addr_base;
reg [`ext_buf_mem_addr_width-1:0] luma_addr_offset;
reg [`ext_buf_mem_addr_width-1:0] chroma_cb_addr_offset;
reg [`ext_buf_mem_addr_width-1:0] chroma_cr_addr_offset;

reg [`mb_x_bits + `mb_y_bits :0] total_mbs_above_line;
reg [2:0] addr_base_add_counter;

//cb_addr_base & cr_addr_base
always @(posedge clk) begin
	total_mbs_above_line <= pic_width_in_mbs * mb_y_writing;
end

always @(posedge clk or negedge rst_n)
if (!rst_n) begin
	luma_addr_base <= 0;
    cb_addr_base <= 0;
    cr_addr_base <= 0;
end
else if (start_of_frame) begin
	addr_base_add_counter <= pic_num_2to0;
	luma_addr_base <= 0;
	cb_addr_base <= {total_mbs_one_frame, 8'b0};
	cr_addr_base <= {total_mbs_one_frame, 8'b0} + {total_mbs_one_frame, 6'b0};
end
else if (addr_base_add_counter > 0) begin
	addr_base_add_counter <= addr_base_add_counter - 1'b1;
	luma_addr_base <= luma_addr_base + {total_mbs_one_frame, 8'b0} +
									   {total_mbs_one_frame, 7'b0};
    cb_addr_base <= cb_addr_base + {total_mbs_one_frame, 8'b0} +
								   {total_mbs_one_frame, 7'b0};
    cr_addr_base <= cr_addr_base + {total_mbs_one_frame, 8'b0} +
								   {total_mbs_one_frame, 7'b0};
end

wire[Log2MBsCacheWidth+2-1:0] counter_lower_bits_p1;
assign counter_lower_bits_p1 = counter[Log2MBsCacheWidth+2-1:0]+1'b1;
//luma_addr_offset
always @(posedge clk or negedge rst_n)
if (!rst_n)
    luma_addr_offset <= 0;
else if (write_to_ram_start)
	luma_addr_offset <= (total_mbs_above_line*256)+mb_x_writing*16;
else if(ena)begin
	if (state[0] && counter_lower_bits_p1 == 0)
		luma_addr_offset <= luma_addr_offset + (pic_width_in_mbs)*16 + 3'd4 - (5'd16 << Log2MBsCacheWidth);
	else if (state[0])
		luma_addr_offset <= luma_addr_offset + 3'd4;
end

//chroma_addr_offset
always @(posedge clk or negedge rst_n)
if (!rst_n)
    chroma_cb_addr_offset <= 0;
else if (write_to_ram_start)
	chroma_cb_addr_offset <= (total_mbs_above_line*64)+(mb_x_writing*8);
else if(ena)begin
	if (state[1] && counter_lower_bits_p1[Log2MBsCacheWidth:0] == 0)
		chroma_cb_addr_offset <= chroma_cb_addr_offset + (pic_width_in_mbs*8) + 3'd4 - (4'd8 << Log2MBsCacheWidth);
	else if (state[1])
		chroma_cb_addr_offset <= chroma_cb_addr_offset + 3'd4;
end


always @(posedge clk or negedge rst_n)
if (!rst_n)
    chroma_cr_addr_offset <= 0;
else if (write_to_ram_start)
	chroma_cr_addr_offset <= (total_mbs_above_line*64)+(mb_x_writing*8);
else if(ena)begin
	if (state[2] && counter_lower_bits_p1[Log2MBsCacheWidth:0] == 0)
		chroma_cr_addr_offset <= chroma_cr_addr_offset + (pic_width_in_mbs*8) + 3'd4 - (4'd8 << Log2MBsCacheWidth);
	else if (state[2])
		chroma_cr_addr_offset <= chroma_cr_addr_offset + 3'd4;
end

always @(posedge clk)
if (ena) begin
	if (is_luma)
    	ext_mem_writer_addr <= luma_addr_base + luma_addr_offset;
	else if (is_cb)
    	ext_mem_writer_addr <= cb_addr_base + chroma_cb_addr_offset;
	else 
    	ext_mem_writer_addr <= cr_addr_base + chroma_cr_addr_offset;
end

always @(posedge clk)
if (ena) begin
	if (is_reg_luma)//luma
		case(counter_reg[3+Log2MBsCacheWidth:2+Log2MBsCacheWidth])
		0:ext_mem_writer_data <= luma_row0_data_out;
		1:ext_mem_writer_data <= luma_row1_data_out;
		2:ext_mem_writer_data <= luma_row2_data_out;
		default:ext_mem_writer_data <= luma_row3_data_out;
		endcase
	else//chroma
		case(counter_reg[2+Log2MBsCacheWidth:1+Log2MBsCacheWidth])
		0:ext_mem_writer_data <= chroma_row0_data_out;
		1:ext_mem_writer_data <= chroma_row1_data_out;
		2:ext_mem_writer_data <= chroma_row2_data_out;
		default:ext_mem_writer_data <= chroma_row3_data_out;
		endcase
end

always @(posedge clk or negedge rst_n)
if (~rst_n) begin
	ext_mem_writer_burst <= 0;
	ext_mem_writer_burst_len_minus1 = 0;
end
else if (ena) begin
	if (state && is_luma && counter[Log2MBsCacheWidth+1:0] == 0) begin
		ext_mem_writer_burst <= 1;
		ext_mem_writer_burst_len_minus1 = 4*MBsCacheWidth-1;
	end
	else if (state && ~is_luma && counter[Log2MBsCacheWidth:0] == 0) begin
		ext_mem_writer_burst <= 1;
		ext_mem_writer_burst_len_minus1 = 2*MBsCacheWidth-1;
	end
	else
		ext_mem_writer_burst <= 0;
end

endmodule


// used for storing sum data
module mb_ram
(
	clk,
	wr,
	rd_ena,
	wr_addr,
	rd_addr,
    data_in,
    data_out
);
parameter addr_bits = 8;
parameter data_bits = 16;
input     clk;
input     wr;
input     rd_ena;
input     [addr_bits-1:0]  wr_addr;
input     [addr_bits-1:0]  rd_addr;
input     [data_bits-1:0]  data_in;
output    [data_bits-1:0]  data_out;
	
reg       [data_bits-1:0]  ram[0:(1 << addr_bits) -1];
reg       [data_bits-1:0]  data_out;

//read
always @ ( posedge clk )
begin
	if (rd_ena)
	    data_out <= ram[rd_addr];
end 

//write
always @ (posedge clk)
begin
    if (wr)
        ram[wr_addr] <= data_in;
end

endmodule

