//--------------------------------------------------------------------------------------------------
// Design    : bitstream_p
// Author(s) : qiu bin, shi tian qi
// Email     : chat1@126.com, tishi1@126.com
// Copyright (C) 2013 qiu bin 
// All rights reserved                
//-------------------------------------------------------------------------------------------------


// `include "defines.v"
`include "defines.v"

module display_mem_reader
(
    input rst_n,
	input decoder_clk,
	input mem_reader_clk,
	input video_clk,
    
	input ext_mem_reader_cmd_ready,
	output reg ext_mem_reader_cmd_valid,
	output reg [71:0] ext_mem_reader_cmd_data,

	input ext_mem_reader_data_valid,
	output ext_mem_reader_data_ready,
	input [63:0] ext_mem_reader_data,

	//video parameters from decoder
	input	[`mb_x_bits : 0]				pic_width_in_mbs,
	input	[`mb_y_bits : 0]				pic_height_in_map_units,
	input   [`mb_x_bits + `mb_y_bits:0]	    total_mbs_one_frame,
	input         							start_of_frame,
	input	[63:0]							pic_num,
	input  [`mb_x_bits + `mb_y_bits-1:0]	mb_index,

	//video signals from video_ctrl
	input video_valid,
	input video_y_valid,
	input video_is_next_pixel_active,
	input[12:0] video_y,
	input[12:0] video_next_x,
	input video_hs_n,

	output [63:0] y_data,
	output [63:0] u_data,
	output [63:0] v_data
);
parameter
DisplayPercent = 70,
DisplayRes = 1920*1088;
parameter
YBurstCount = 16,
Log2_YBurstCount = 4;
logic [3:0]  pic_num_s;
logic  [`mb_x_bits + `mb_y_bits-1:0]	mb_index_s;
logic [`mb_x_bits + `mb_y_bits:0]	    total_mbs_one_frame_s;
logic [`mb_x_bits:0]	    pic_width_in_mbs_s;
logic [`mb_y_bits :0]	    pic_height_in_map_units_s;
reg video_y_valid_d;
reg display_start_load_d;
reg y_rd;
reg uv_rd;
/////////////////////////////////////////////

sync_ram_display sync_ram_display_0(
	.aclr(~rst_n),
	.data({pic_width_in_mbs,mb_index,pic_num[3:0],total_mbs_one_frame}),
	.rdclk(mem_reader_clk),
	.rdreq(),
	.wrclk(decoder_clk),
	.wrreq(),
	.q({pic_width_in_mbs_s,mb_index_s,pic_num_s[3:0],total_mbs_one_frame_s}),
	.rdusedw(),
	.wrusedw()
);

/*
always @(posedge mem_reader_clk)
if (start_of_frame)begin
    pic_num_s[3:0] <= pic_num[3:0];
    total_mbs_one_frame_s <= total_mbs_one_frame;
    pic_width_in_mbs_s <= pic_width_in_mbs;
    mb_index_s <= mb_index;
end
*/

always @(posedge video_clk) begin
    y_rd <= video_is_next_pixel_active && video_next_x[2:0] == 5 && 
		video_next_x < (pic_width_in_mbs << 4) && video_y < (pic_height_in_map_units <<4);
    uv_rd <= video_is_next_pixel_active && video_next_x[3:0] == 13 && 
		video_next_x < (pic_width_in_mbs << 4) && video_y < (pic_height_in_map_units <<4);
end
	
reg video_hs_n_d;
reg display_start_load;
reg display_started;
always @(posedge mem_reader_clk or negedge rst_n)
if (~rst_n) begin
	display_start_load <= 1'b0;
end
else begin
	video_hs_n_d <= video_hs_n;
	if (~video_hs_n && video_hs_n_d && display_started && video_y_valid)
		display_start_load <= 1'b1;
	else
		display_start_load <= 1'b0;
end


//////////////////////////////////////////////
reg [`ext_buf_mem_addr_width-1:0] y_addr_reg;
reg [`ext_buf_mem_addr_width-1:0] u_addr_reg;
reg [`ext_buf_mem_addr_width-1:0] v_addr_reg;
reg [`ext_buf_mem_addr_width-1:0] y_addr_base;
reg [`ext_buf_mem_addr_width-1:0] u_addr_base;
reg [`ext_buf_mem_addr_width-1:0] v_addr_base;
reg read_ena;
reg video_valid_d;

reg [Log2_YBurstCount:0] ext_mem_reader_data_counter;
always @(posedge mem_reader_clk or negedge rst_n)
if (~rst_n)begin
	ext_mem_reader_data_counter <= 0;
end
else if (display_start_load)begin
	ext_mem_reader_data_counter <= 0;
end
else if (ext_mem_reader_data_valid) begin
	ext_mem_reader_data_counter <= ext_mem_reader_data_counter + 1'b1;
end

wire ram_wr;
wire is_data_y;
wire is_data_u;
wire is_data_v;

assign ext_mem_reader_data_ready = 1'b1;
assign ram_wr = ext_mem_reader_data_valid && ext_mem_reader_data_ready;
assign is_data_u = video_y[0] ? 1'b0 : ext_mem_reader_data_counter <  YBurstCount/2;
assign is_data_v = video_y[0] ? 1'b0 : ext_mem_reader_data_counter >= YBurstCount/2 && ext_mem_reader_data_counter < YBurstCount;
assign is_data_y = video_y[0] ? 1'b1 : ext_mem_reader_data_counter >= YBurstCount;

reg [7:0] y_ram_wr_addr;
reg [7:0] y_ram_rd_addr;
reg [7:0] u_ram_wr_addr;
reg [7:0] u_ram_rd_addr;
reg [7:0] v_ram_wr_addr;
reg [7:0] v_ram_rd_addr;

always @(posedge video_clk or negedge rst_n)
if (~rst_n)
	y_ram_rd_addr <= 0;
else if (display_start_load)
	y_ram_rd_addr <= 0;
else if (y_rd)
	y_ram_rd_addr <= y_ram_rd_addr + 1'd1;

always @(posedge mem_reader_clk or negedge rst_n)
if (~rst_n)
	y_ram_wr_addr <= 0;
else if (display_start_load)
	y_ram_wr_addr <= 0;
else if (ram_wr && is_data_y)
	y_ram_wr_addr <= y_ram_wr_addr + 1'd1;

always @(posedge video_clk or negedge rst_n)
if (~rst_n)
	u_ram_rd_addr <= 0;
else if (display_start_load)
	u_ram_rd_addr <= 0;
else if (uv_rd)
	u_ram_rd_addr <= u_ram_rd_addr + 1'd1;

always @(posedge mem_reader_clk or negedge rst_n)
if (~rst_n)
	u_ram_wr_addr <= 0;
else if (display_start_load)
	u_ram_wr_addr <= 0;
else if (ram_wr && is_data_u)
	u_ram_wr_addr <= u_ram_wr_addr + 1'd1;


always @(posedge video_clk or negedge rst_n)
if (~rst_n)
	v_ram_rd_addr <= 0;
else if (display_start_load)
	v_ram_rd_addr <= 0;
else if (uv_rd)
	v_ram_rd_addr <= v_ram_rd_addr + 1'd1;

always @(posedge mem_reader_clk or negedge rst_n)
if (~rst_n)
	v_ram_wr_addr <= 0;
else if (display_start_load)
	v_ram_wr_addr <= 0;
else if (ram_wr && is_data_v)
	v_ram_wr_addr <= v_ram_wr_addr + 1'd1;

dp_ram_display #(64, 8) y_ram(
	.data(ext_mem_reader_data),
	.wraddress(y_ram_wr_addr),
	.rdaddress(y_ram_rd_addr),
	.wren(ram_wr && is_data_y),
	.rdclock(video_clk),
	.wrclock(mem_reader_clk),
	.q(y_data)
);

dp_ram_display #(64, 8) u_ram(
	.data(ext_mem_reader_data),
	.wraddress(u_ram_wr_addr),
	.rdaddress(u_ram_rd_addr),
	.wren(ram_wr && is_data_u),
	.rdclock(video_clk),
	.wrclock(mem_reader_clk),
	.q(u_data)
);

dp_ram_display #(64, 8) v_ram(
	.data(ext_mem_reader_data),
	.wraddress(v_ram_wr_addr),
	.rdaddress(v_ram_rd_addr),
	.wren(ram_wr && is_data_v),
	.rdclock(video_clk),
	.wrclock(mem_reader_clk),
	.q(v_data)
);

always @(posedge mem_reader_clk or negedge rst_n)
if (!rst_n) begin
	read_ena <= 0;
	video_valid_d <= 0;
end
else begin
	video_valid_d <= video_valid;
	if (display_start_load_d && display_started)
		read_ena <= 1;
	else if (video_valid_d && !video_valid)
	   read_ena <= 0; 
end

reg [2:0] load_state;
reg [2:0] next_load_state;
parameter
LoadIdle = 3'd0,
LoadSendCmdY = 3'd1,
LoadSendCmdU = 3'd2,
LoadSendCmdV = 3'd3,
LoadDone = 3'd4;

wire [22:0] rd_cmd_BTT;
wire rd_cmd_Type = 1; //auto inc
wire[5:0] rd_cmd_DSA = 0;
wire rd_EOF = 0;
wire rd_DRR = 0;
reg [31:0] rd_SADDR;
assign rd_cmd_BTT = next_load_state == LoadSendCmdY ? YBurstCount*8 : YBurstCount*4;

always @(*)
if (next_load_state == LoadSendCmdY)
	rd_SADDR = y_addr_reg | 32'h10000000;
else if (next_load_state == LoadSendCmdU)
	rd_SADDR = u_addr_reg | 32'h10000000;
else if (next_load_state == LoadSendCmdV)
	rd_SADDR = v_addr_reg | 32'h10000000;
else
	rd_SADDR = 32'h10000000;



reg [10:0] y_line_offset;

always @(*)begin
	next_load_state <= load_state;
	casex({ext_mem_reader_cmd_ready,load_state})
	{1'bx,LoadIdle}:begin
		if (read_ena && y_line_offset < (pic_width_in_mbs_s<<4) && video_y[0] == 0)begin
			next_load_state <= LoadSendCmdU;
		end
		else if (read_ena && y_line_offset < (pic_width_in_mbs_s<<4))begin
			next_load_state <= LoadSendCmdY;
		end
	end
	{1'b1,LoadSendCmdU}:begin
		next_load_state <= LoadSendCmdV;
	end
	{1'b1,LoadSendCmdV}:begin
		next_load_state <= LoadSendCmdY;
	end
	{1'b1,LoadSendCmdY}:begin
		next_load_state <= LoadDone;
	end
	{1'bx,LoadDone}:begin
		next_load_state <= LoadIdle;
	end
	endcase
end

always @(posedge mem_reader_clk or negedge rst_n)
if (~rst_n)
	ext_mem_reader_cmd_valid <= 1'b0;
else if (next_load_state == LoadSendCmdY || next_load_state == LoadSendCmdU)
	ext_mem_reader_cmd_valid <= 1'b1;
else if (next_load_state == LoadDone)
	ext_mem_reader_cmd_valid <= 1'b0;

always @(posedge mem_reader_clk or negedge rst_n)
if (~rst_n)
	ext_mem_reader_cmd_data <= 72'b0;
else if (next_load_state == LoadSendCmdY 
		|| next_load_state == LoadSendCmdU
		|| next_load_state == LoadSendCmdV)
	ext_mem_reader_cmd_data <= { rd_SADDR,8'b0,rd_cmd_Type,rd_cmd_BTT};


always @(posedge mem_reader_clk or negedge rst_n)
if (~rst_n)
	load_state <= LoadIdle;
else
	load_state <= next_load_state;

//cb_addr_base & cr_addr_base
reg [2:0] display_pic_num;

wire [`mb_x_bits + `mb_y_bits+9:0] pic_size;
assign pic_size = (total_mbs_one_frame_s << 8) + (total_mbs_one_frame_s << 7);

reg  [`mb_x_bits + `mb_y_bits:0] prev_total_mbs_one_frame;
reg [3:0] addr_base_precalc_counter;
reg  [0:7][`ext_buf_mem_addr_width-1:0]  luma_addr_base_precalc;
reg  [0:7][`ext_buf_mem_addr_width-1:0]  cb_addr_base_precalc;
reg  [0:7][`ext_buf_mem_addr_width-1:0]  cr_addr_base_precalc;
reg  [`ext_buf_mem_addr_width-1:0]  luma_addr_base_prev;
reg  [`ext_buf_mem_addr_width-1:0]  cb_addr_base_prev;
reg  [`ext_buf_mem_addr_width-1:0]  cr_addr_base_prev;


always @(posedge mem_reader_clk or negedge rst_n)
if (!rst_n) begin
    prev_total_mbs_one_frame <= 0;
    addr_base_precalc_counter <= 0;
    luma_addr_base_precalc <= '0;
    cb_addr_base_precalc <= '0;
    cr_addr_base_precalc <= '0;
    luma_addr_base_prev <= '0;
    cb_addr_base_prev <= '0;
    cr_addr_base_prev <= '0;
end
else begin
	prev_total_mbs_one_frame <= total_mbs_one_frame_s;
	if (prev_total_mbs_one_frame != total_mbs_one_frame_s) begin
		addr_base_precalc_counter <= 1;
    	luma_addr_base_precalc[0] <= 0;
	    cb_addr_base_precalc[0] <= total_mbs_one_frame_s * 256;
	    cr_addr_base_precalc[0] <= total_mbs_one_frame_s * 256 + total_mbs_one_frame_s * 64;
    	luma_addr_base_prev <= 0;
	    cb_addr_base_prev <= (total_mbs_one_frame_s <<8) ;
	    cr_addr_base_prev <= (total_mbs_one_frame_s <<8) + (total_mbs_one_frame_s<<6) ;	    
	end
	if (addr_base_precalc_counter > 0 && addr_base_precalc_counter < 8)
		addr_base_precalc_counter <= addr_base_precalc_counter + 1'b1;
	if (addr_base_precalc_counter > 0 && addr_base_precalc_counter < 8) begin
   		luma_addr_base_precalc[addr_base_precalc_counter[2:0]] <= luma_addr_base_prev + pic_size;
	    cb_addr_base_precalc[addr_base_precalc_counter[2:0]] <= cb_addr_base_prev + pic_size;
	    cr_addr_base_precalc[addr_base_precalc_counter[2:0]] <= cr_addr_base_prev + pic_size;
	    luma_addr_base_prev <= luma_addr_base_prev + pic_size;
	    cb_addr_base_prev <= cb_addr_base_prev + pic_size;
	    cr_addr_base_prev <= cr_addr_base_prev + pic_size;
	end
end

always @(posedge mem_reader_clk or negedge rst_n)
if (~rst_n) begin
	display_started <= 0;
	display_pic_num <= 0;
end
else begin
    video_y_valid_d <= video_y_valid;
	if (pic_num_s > 0 && video_y == 0)
		display_started <= 1'b1;
    if (~video_y_valid_d && video_y_valid && display_started && mb_index_s < (DisplayRes/256)*DisplayPercent/128)
	   display_pic_num <= pic_num_s[2:0] - 1'b1;
	 else if (~video_y_valid_d && video_y_valid)
       display_pic_num <= pic_num_s[2:0];
end

wire [`mb_x_bits+3:0] pic_width = pic_width_in_mbs_s << 4;
always @(posedge mem_reader_clk or negedge rst_n)
if (!rst_n) begin
	y_addr_reg <= 0;
	u_addr_reg <= 0;
	v_addr_reg <= 0;
	y_line_offset <= 0;
                  
	display_start_load_d <= 0;
end
else begin
    display_start_load_d <= display_start_load;
	if(display_start_load) begin
		y_line_offset <= 0;
		if (video_y == 0) begin
            y_addr_base	<= luma_addr_base_precalc[display_pic_num];
            u_addr_base	<= cb_addr_base_precalc[display_pic_num];
            v_addr_base	<= cr_addr_base_precalc[display_pic_num];
		end
		else begin
		      y_addr_base	<= y_addr_base+pic_width;
		      if (video_y[0] == 0) begin
                u_addr_base    <= u_addr_base+ (pic_width>>1);
                v_addr_base    <= v_addr_base+ (pic_width>>1);
              end
		end
	end
	else if(display_start_load_d) begin
        y_addr_reg	<=	y_addr_base;
        u_addr_reg    <=    u_addr_base;
        v_addr_reg    <=    v_addr_base;
	end
	else if(load_state == LoadDone) begin
		y_line_offset <= y_line_offset + YBurstCount*8;
		y_addr_reg	<=	y_addr_reg + YBurstCount*8;
		u_addr_reg	<=	u_addr_reg + YBurstCount*4;
		v_addr_reg	<=	v_addr_reg + YBurstCount*4;
	end
end

endmodule


