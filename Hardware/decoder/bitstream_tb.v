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
//-cond "/u_decode_stream/slice_data_inst/mb_index_out==4 && "
//-cond "/u_decode_stream/bc_inst/pic_num==1"
module bitstream_tb;
reg rst_n;
reg clk;
reg clk150;
reg ext_mem_reader_clk;
wire video_clk;
wire dec_clk;

assign dec_clk = clk;
assign video_clk = clk150;
reg		[7:0] stream_mem [0:32*1024*1024];

wire [7:0]  stream_data;
reg [31:0]	stream_mem_addr;
wire 		stream_mem_rd;

wire									ext_mem_writer_burst; 
wire [7:0]								ext_mem_writer_burst_len_minus1;
reg 									ext_mem_writer_ready;
reg [`ext_buf_mem_addr_width-1:0]		ext_mem_writer_addr;
wire [`ext_buf_mem_addr_width-1:0]		ext_mem_writer_addr_wire;
wire [`ext_buf_mem_data_width-1:0]		ext_mem_writer_data;
wire									ext_mem_writer_valid;

wire [71:0] ext_mem_reader_cmd_data;
wire ext_mem_reader_cmd_valid;
wire ext_mem_reader_cmd_ready;
wire [4:0] ext_mem_reader_burst_len_minus1;
wire [`ext_buf_mem_addr_width-1:0] ext_mem_reader_burst_addr;
wire [31:0] ext_mem_reader_addr;
wire [63:0] ext_mem_reader_data;
wire ext_mem_reader_ready;
wire ext_mem_reader_valid;

assign ext_mem_reader_cmd_data[63:32] = ext_mem_reader_burst_addr;
assign ext_mem_reader_cmd_data[22:0] = (ext_mem_reader_burst_len_minus1 + 1'b1) << 3;

ext_mem_reader_cmd_translate #(64) ext_mem_reader_cmd_translate(
	.clk(ext_mem_reader_clk),
	.rst_n(rst_n),
	.ext_mem_reader_cmd_ready(ext_mem_reader_cmd_ready),
	.ext_mem_reader_cmd_data(ext_mem_reader_cmd_data),
	.ext_mem_reader_cmd_valid(ext_mem_reader_cmd_valid),

	.ext_mem_reader_addr(ext_mem_reader_addr),
	.ext_mem_reader_valid(ext_mem_reader_valid),
	.ext_mem_reader_ready(ext_mem_reader_ready)
);

wire ext_mem_reader_cmd_ready_display;
wire [71:0] ext_mem_reader_cmd_data_display;
wire ext_mem_reader_cmd_valid_display;
wire [31:0] ext_mem_reader_addr_display;
wire ext_mem_reader_ready_display;
wire ext_mem_reader_valid_display;
wire [63:0] ext_mem_reader_data_display;

ext_mem_reader_cmd_translate #(64) ext_mem_reader_cmd_translate_display(
	.clk(video_clk),
	.rst_n(rst_n),
	.ext_mem_reader_cmd_ready(ext_mem_reader_cmd_ready_display),
	.ext_mem_reader_cmd_data(ext_mem_reader_cmd_data_display),
	.ext_mem_reader_cmd_valid(ext_mem_reader_cmd_valid_display),

	.ext_mem_reader_addr(ext_mem_reader_addr_display),
	.ext_mem_reader_valid(ext_mem_reader_valid_display),
	.ext_mem_reader_ready(ext_mem_reader_ready_display)
);


always @(posedge clk or negedge rst_n)
if (~rst_n)
	ext_mem_writer_addr <= 0;
else if (ext_mem_writer_burst && ext_mem_writer_ready)
	ext_mem_writer_addr <= ext_mem_writer_addr_wire;
else if (ext_mem_writer_valid && ext_mem_writer_ready)
	ext_mem_writer_addr <= ext_mem_writer_addr + 4;
//////////////////////////////////////////////////////
//decoder
wire [`mb_x_bits:0] pic_width_in_mbs;
wire [`mb_y_bits:0] pic_height_in_map_units;
wire [`mb_x_bits+`mb_y_bits:0] total_mbs_one_frame;
wire start_of_frame;
wire end_of_frame;
wire [63:0] pic_num;
wire [`mb_x_bits+`mb_y_bits-1:0] mb_index;


decode_stream u_decode_stream
(
 .clk(clk),
 .rst_n(rst_n),
 .ena(1'b1),
 
 .num_cycles_1_frame(24'd1),
  
 //interface to stream memory or fifo
 .stream_mem_valid(stream_valid),
 .stream_mem_data_in(stream_data),
 .stream_mem_addr_out(),
 .stream_mem_rd(stream_rd),
 .stream_mem_end(1'b0),
 
 //interface to external buffer memory
 .ext_mem_init_done(1'b1),
 .ext_mem_writer_burst(ext_mem_writer_burst),
 .ext_mem_writer_burst_len_minus1(ext_mem_writer_burst_len_minus1),
 .ext_mem_writer_ready(ext_mem_writer_ready),
 .ext_mem_writer_addr(ext_mem_writer_addr_wire),
 .ext_mem_writer_data(ext_mem_writer_data),
 .ext_mem_writer_valid(ext_mem_writer_valid),

 .ext_mem_reader_clk(ext_mem_reader_clk),
 .ext_mem_reader_rst_n(rst_n),
 .ext_mem_reader_burst_ready(ext_mem_reader_cmd_ready),
 .ext_mem_reader_burst(ext_mem_reader_cmd_valid),
 .ext_mem_reader_burst_len_minus1(ext_mem_reader_burst_len_minus1),
 .ext_mem_reader_burst_addr(ext_mem_reader_burst_addr),
 .ext_mem_reader_valid(ext_mem_reader_valid),
 .ext_mem_reader_ready(ext_mem_reader_ready),
 .ext_mem_reader_data(ext_mem_reader_data),
 
 //video information
 .pic_width_in_mbs(pic_width_in_mbs),
 .pic_height_in_map_units(pic_height_in_map_units),
 .total_mbs_one_frame(total_mbs_one_frame),
 .start_of_frame(start_of_frame),
 .end_of_frame(end_of_frame),
 .pic_num(pic_num),
 .run_counter(),
 .mb_index(mb_index)
);


////////////////////////////////////
//display

wire [63:0] y_data;
wire [63:0] u_data;
wire [63:0] v_data;

wire video_de_i;
wire video_is_next_pixel_active_i;
wire video_y_valid_i;
wire video_hs_n_i;
wire video_vs_n_i;
wire [12:0] video_next_x_i;
wire [12:0] video_next_y_i;
wire [7:0] video_r;
wire [7:0] video_g;
wire [7:0] video_b;
reg [25:0] rd_addr_check;
reg [25:0] rd_addr_check_u;
reg [25:0] rd_addr_check_v;
wire [63:0] data_out_check;
reg [63:0] data_out_check_u;
reg [63:0] data_out_check_v;

display_mem_reader display_mem_reader_inst(
    .rst_n(rst_n),

	.decoder_clk(dec_clk),
	.mem_reader_clk(video_clk),
	.video_clk(video_clk),
    
	.ext_mem_reader_cmd_ready(ext_mem_reader_cmd_ready_display),
	.ext_mem_reader_cmd_valid(ext_mem_reader_cmd_valid_display),
	.ext_mem_reader_cmd_data(ext_mem_reader_cmd_data_display),

	.ext_mem_reader_data_valid(ext_mem_reader_valid_display),
	.ext_mem_reader_data_ready(ext_mem_reader_ready_display),
	.ext_mem_reader_data(ext_mem_reader_data_display),

	.pic_width_in_mbs(pic_width_in_mbs),
	.pic_height_in_map_units(pic_height_in_map_units),
	.total_mbs_one_frame(total_mbs_one_frame),
	.start_of_frame(start_of_frame),
	.pic_num(pic_num),
	.mb_index(mb_index),
	
	.video_valid(video_de_i),
	.video_y_valid(video_y_valid_i),
	.video_is_next_pixel_active(video_is_next_pixel_active_i),
	.video_y(video_next_y_i),
	.video_next_x(video_next_x_i),
	.video_hs_n(video_hs_n_i),

	.y_data(y_data),
	.u_data(u_data),
	.v_data(v_data)
);


video_ctrl video_ctrl(
	.rst_n(rst_n),
	.clk(video_clk),
	
	.hsync_n(video_hs_n_i),
	.vsync_n(video_vs_n_i),
	.de(video_de_i),
	.is_next_pixel_active(video_is_next_pixel_active_i),
	.y_valid(video_y_valid_i),

	.next_x(video_next_x_i),
	.next_y(video_next_y_i),
	.hcnt(),
	.vcnt(),

	.pixel_clock_div_10000(),
	.v_freq(),
	.num_pixels_per_line(),
	.num_lines()
);

wire [23:0] pic_size = (pic_width_in_mbs * pic_height_in_map_units)*384;
wire [25:0] pic_offset = display_mem_reader_inst.display_pic_num * pic_size;

always @(*) begin
	rd_addr_check = video_next_x_i[10:3]*8  + video_next_y_i * 1280 + pic_offset;
end

always @(*) begin
	rd_addr_check_u = video_next_x_i[10:4]*8  + video_next_y_i/2 * 640 + pic_offset + pic_size * 4 / 6;
end

always @(*) begin
	data_out_check_u = {ext_ram_32.ram[rd_addr_check_u/4+1],ext_ram_32.ram[rd_addr_check_u/4]};
end

always @(posedge video_clk)
if (video_de_i && display_mem_reader_inst.read_ena && y_data != data_out_check) begin
		$display( "%t : wrong display y_data, x=%d, y=%d expect %016x, got %016x",$time,video_next_x_i, video_next_y_i,data_out_check, y_data);
		$stop();
end

always @(posedge video_clk)
if (video_de_i && display_mem_reader_inst.read_ena && u_data != data_out_check_u) begin
	$display( "%t : wrong display u_data, x=%d, y=%d expect %016x, got %016x",$time,video_next_x_i, video_next_y_i,data_out_check_u, u_data);
	$display( "%t : wrong display u_data, rd_addr_check_u=%08x",$time,rd_addr_check_u);
	$stop();
end

//*/
wire ext_mem_writer_burst_and_ready = ext_mem_writer_burst & ext_mem_writer_ready;
reg [7:0] burst_len_counter;
reg ext_mem_writer_last;
always @(posedge clk or negedge rst_n)
if (~rst_n) begin
	burst_len_counter <= 0;
	ext_mem_writer_last <= 1'b0;
end
else if (ext_mem_writer_burst_and_ready) begin
	burst_len_counter <= ext_mem_writer_burst_len_minus1;
	ext_mem_writer_last <= 1'b0;
end
else if (ext_mem_writer_valid && ext_mem_writer_ready && ext_mem_writer_last == 1'b0) begin
	burst_len_counter <= burst_len_counter - 1'b1;
	if (burst_len_counter == 1)
		ext_mem_writer_last <= 1'b1;
end

wire [22:0] axis_wr_cmd_BTT = ext_mem_writer_burst_len_minus1;
wire axis_wr_cmd_Type = 1; //auto inc
wire[5:0] axis_wr_cmd_DSA = 0;
wire axis_wr_EOF = 1;
wire axis_wr_DRR = 0;
wire [31:0] axis_wr_SADDR = ext_mem_writer_addr;
wire [71:0] axis_mem_wr_cmd_data = {axis_wr_SADDR,axis_wr_DRR,axis_wr_EOF,axis_wr_cmd_DSA,axis_wr_cmd_Type,axis_wr_cmd_BTT};
wire [31:0] axis_mem_wr_data = ext_mem_writer_data;
wire axis_mem_wr_cmd_valid = ext_mem_writer_burst_and_ready;
wire axis_mem_wr_valid = ext_mem_writer_valid;
wire axis_mem_wr_last = ext_mem_writer_last;
//assign ext_mem_writer_ready = axis_mem_wr_ready && axis_mem_wr_cmd_ready;


wire [31:0] mem_wr_data;
wire mem_wr_last;
wire mem_wr_ready;
wire mem_wr_valid;
wire[71:0] mem_wr_cmd_data;
wire mem_wr_cmd_ready;
wire mem_wr_cmd_valid;

// clock and reset
always
begin
   #3.34 ext_mem_reader_clk = 0;
   #3.34 ext_mem_reader_clk = 1;
end

always
begin
   #6.67 clk = 0;
   #6.67 clk = 1;
end

always
begin
   #3.33 clk150 = 0;
   #3.33 clk150 = 1;
end

initial
begin
   clk = 1'b1;
   ext_mem_reader_clk =1'b1;
   rst_n = 1'b0;
   repeat (5) @(posedge clk);
   rst_n = 1'b1;
end

always @(posedge clk)
	ext_mem_writer_ready <= $random() % 2;	

wire bus_clk;
wire [7:0] main_tdata;
reg main_tvalid;
wire main_tready;
assign bus_clk = clk150;

bitstream_fifo bitstream_fifo (
	.write_clk(bus_clk),
	.write_data(main_tdata),
	.write_valid(main_tvalid),
	.write_ready(main_tready),
	
	.read_clk(dec_clk),
	.rst_n(rst_n),
	.read(stream_rd),
	.stream_out(stream_data),
	.stream_out_valid(stream_valid),
	.stream_over()
);

always @(posedge clk)
	main_tvalid <= $random() % 2;	

assign main_tdata = stream_mem[stream_mem_addr];	//async read
always @(posedge bus_clk or negedge rst_n)
if (~rst_n)
	stream_mem_addr <= 0;
else if (main_tvalid && main_tready)
	stream_mem_addr <= stream_mem_addr + 1'b1;

// read stream file
integer ch,fp_264,addr_264;
initial
begin
	addr_264 = 0;
	fp_264 = $fopen("dance1080p.264", "rb");
	while(1) begin
		ch = $fgetc(fp_264);
		if (ch >= 0 && ch <256) begin
			stream_mem[addr_264] = ch;
			addr_264 = addr_264 + 1;
		end
		else begin
			forever
				@(pic_num);
		end
	end
	$readmemh( "out.mem", stream_mem );
end


ext_ram_32 #(.BinMode(1)) ext_ram_32 
(
	.wr_clk(dec_clk),
	.rd_clk(ext_mem_reader_clk),
	.rd_clk_display(video_clk),
	.wr(ext_mem_writer_ready && ext_mem_writer_valid),
	.wr_addr(ext_mem_writer_addr), 
	.rd_addr(ext_mem_reader_addr[`ext_buf_mem_addr_width-1:0]), 
	.rd_addr_display(ext_mem_reader_addr_display), 
	.rd_addr_check(rd_addr_check),
	.data_in(ext_mem_writer_data), 
	.data_out(ext_mem_reader_data),
	.data_out_display(ext_mem_reader_data_display),
	.data_out_check(data_out_check),
	.start_of_frame(start_of_frame),
	.end_of_frame(end_of_frame),
	.pic_num(pic_num)
);



integer blk_num, residual_blk_num, fp_w, fp_w_cavlc,fp_w_residual;

initial
begin
    while(1)
	begin	    
		@(u_decode_stream.slice_data_inst.slice_data_state);
		if (u_decode_stream.slice_data_inst.slice_data_state == `mb_num_update)
        begin
			//if (u_decode_stream.slice_data_inst.mb_index_out[3:0] == 4'b1111)
            $display( "pic_num:%d mb_index_out:%d", u_decode_stream.bc_inst.pic_num, u_decode_stream.slice_data_inst.mb_index_out);	    	
		end
	end
end

/*
fprintf(fp_deblock_dbg, "pic_num=%04d, mb_index=%04d\n", pic_num, mb_index);
	for (i = 0; i < 4; i++){
		fprintf(fp_deblock_dbg, "ver bs=%1d %1d %1d %1d\n", bs[i][0],bs[i][1],bs[i][2],bs[i][3]);
	}
*/
/*
integer fp_w_bs;
initial
begin
	fp_w_bs = $fopen("trace_bs.txt", "w");
    while(1)
	begin	    
		@(u_decode_stream.slice_data_inst.slice_data_state);
		if (u_decode_stream.slice_data_inst.slice_data_state == `mb_num_update)
        begin
            $fdisplay( fp_w_bs, "pic_num=%04d, mb_index=%04d", u_decode_stream.bc_inst.pic_num, u_decode_stream.slice_data_inst.mb_index_out);
	  		if (u_decode_stream.slice_data_inst.df_qp_le_than_thresh == 0)
				$fdisplay( fp_w_bs, "qp0=%02d,qp1=%02d,qp2=%02d,qp3=%02d,qp4=%02d,qp5=%02d", 
					u_decode_stream.slice_data_inst.df_qp0, u_decode_stream.slice_data_inst.df_qp1,
					u_decode_stream.slice_data_inst.df_qp2, u_decode_stream.slice_data_inst.df_qp3,
					u_decode_stream.slice_data_inst.df_qp4, u_decode_stream.slice_data_inst.df_qp5);
		end
	end
end

initial
begin
	fp_w_bs = $fopen("trace_bs.txt", "w");
    while(1)
	begin	    
		@(u_decode_stream.df_top_inst.df_data_path_and_ctrl_inst.state_h);
		# 1;
		if (u_decode_stream.df_top_inst.df_data_path_and_ctrl_inst.state_h >= 0 && u_decode_stream.df_top_inst.df_data_path_and_ctrl_inst.state_h <= 63
			&& u_decode_stream.df_top_inst.df_data_path_and_ctrl_inst.bs_h_out > 0)
        begin
			$fdisplay( fp_w_bs, "in:%02x %02x %02x %02x %02x %02x %02x %02x,out:%02x %02x %02x %02x %02x %02x %02x %02x",// u_decode_stream.df_top_inst.df_data_path_and_ctrl_inst.state_h,
				u_decode_stream.df_top_inst.h_filter0_inst.reg_p3_in,u_decode_stream.df_top_inst.h_filter0_inst.reg_p2_in,
				u_decode_stream.df_top_inst.h_filter0_inst.reg_p1_in,u_decode_stream.df_top_inst.h_filter0_inst.reg_p0_in,
				u_decode_stream.df_top_inst.h_filter0_inst.reg_q0_in,u_decode_stream.df_top_inst.h_filter0_inst.reg_q1_in,
				u_decode_stream.df_top_inst.h_filter0_inst.reg_q2_in,u_decode_stream.df_top_inst.h_filter0_inst.reg_q3_in,
				u_decode_stream.df_top_inst.df_data_path_and_ctrl_inst.h_filter0_p3_out,u_decode_stream.df_top_inst.df_data_path_and_ctrl_inst.h_filter0_p2_out,
				u_decode_stream.df_top_inst.df_data_path_and_ctrl_inst.h_filter0_p1_out,u_decode_stream.df_top_inst.df_data_path_and_ctrl_inst.h_filter0_p0_out,
				u_decode_stream.df_top_inst.df_data_path_and_ctrl_inst.h_filter0_q0_out,u_decode_stream.df_top_inst.df_data_path_and_ctrl_inst.h_filter0_q1_out,
				u_decode_stream.df_top_inst.df_data_path_and_ctrl_inst.h_filter0_q2_out,u_decode_stream.df_top_inst.df_data_path_and_ctrl_inst.h_filter0_q3_out);
			$fdisplay( fp_w_bs, "in:%02x %02x %02x %02x %02x %02x %02x %02x,out:%02x %02x %02x %02x %02x %02x %02x %02x",// u_decode_stream.df_top_inst.df_data_path_and_ctrl_inst.state_h,
				u_decode_stream.df_top_inst.h_filter1_inst.reg_p3_in,u_decode_stream.df_top_inst.h_filter1_inst.reg_p2_in,
				u_decode_stream.df_top_inst.h_filter1_inst.reg_p1_in,u_decode_stream.df_top_inst.h_filter1_inst.reg_p0_in,
				u_decode_stream.df_top_inst.h_filter1_inst.reg_q0_in,u_decode_stream.df_top_inst.h_filter1_inst.reg_q1_in,
				u_decode_stream.df_top_inst.h_filter1_inst.reg_q2_in,u_decode_stream.df_top_inst.h_filter1_inst.reg_q3_in,
				u_decode_stream.df_top_inst.df_data_path_and_ctrl_inst.h_filter1_p3_out,u_decode_stream.df_top_inst.df_data_path_and_ctrl_inst.h_filter1_p2_out,
				u_decode_stream.df_top_inst.df_data_path_and_ctrl_inst.h_filter1_p1_out,u_decode_stream.df_top_inst.df_data_path_and_ctrl_inst.h_filter1_p0_out,
				u_decode_stream.df_top_inst.df_data_path_and_ctrl_inst.h_filter1_q0_out,u_decode_stream.df_top_inst.df_data_path_and_ctrl_inst.h_filter1_q1_out,
				u_decode_stream.df_top_inst.df_data_path_and_ctrl_inst.h_filter1_q2_out,u_decode_stream.df_top_inst.df_data_path_and_ctrl_inst.h_filter1_q3_out);
    		$fflush(fp_w_bs);
		end
	end
end
*/
`ifdef _DUMP_DBG_DATA
initial
begin
	fp_w_cavlc = $fopen("trace_cavlc.log", "w");
	blk_num = 0;
	while(1)
	begin
		@(posedge u_decode_stream.residual_inst.cavlc_valid);
		@(posedge clk);
		blk_num = blk_num + 1;
		
	   // $fdisplay( fp_w_cavlc, "mb_index_out:%-d luma4x4BlkIdx: %-d  chroma4x4BlkIdx :%-d", u_decode_stream.slice_data_inst.mb_index_out,  u_decode_stream.slice_data_inst.luma4x4BlkIdx_out, u_decode_stream.slice_data_inst.chroma4x4BlkIdx_out);		
		$fdisplay( fp_w_cavlc,"mb_index:%-5dnC:%-5dTotalCoeff:%-5d", u_decode_stream.slice_data_inst.mb_index_out, u_decode_stream.residual_inst.nC, u_decode_stream.residual_inst.TotalCoeff);
		$fdisplay( fp_w_cavlc,"%5d%5d%5d%5d", u_decode_stream.residual_inst.coeff_0, u_decode_stream.residual_inst.coeff_1, u_decode_stream.residual_inst.coeff_2, u_decode_stream.residual_inst.coeff_3);
		$fdisplay( fp_w_cavlc,"%5d%5d%5d%5d", u_decode_stream.residual_inst.coeff_4, u_decode_stream.residual_inst.coeff_5, u_decode_stream.residual_inst.coeff_6, u_decode_stream.residual_inst.coeff_7);
		$fdisplay( fp_w_cavlc,"%5d%5d%5d%5d", u_decode_stream.residual_inst.coeff_8, u_decode_stream.residual_inst.coeff_9, u_decode_stream.residual_inst.coeff_10, u_decode_stream.residual_inst.coeff_11);
		$fdisplay( fp_w_cavlc,"%5d%5d%5d%5d\n",u_decode_stream.residual_inst.coeff_12, u_decode_stream.residual_inst.coeff_13, u_decode_stream.residual_inst.coeff_14, u_decode_stream.residual_inst.coeff_15);
	end
end

integer fp_w_bs;
initial
begin
	fp_w_bs = $fopen("trace_bs.txt", "w");
    while(1)
	begin	    
		@(u_decode_stream.slice_data_inst.slice_data_state);
		if (u_decode_stream.slice_data_inst.slice_data_state == `mb_num_update)
        begin
            $fdisplay( fp_w_bs, "pic_num=%04d, mb_index=%04d", u_decode_stream.bc_inst.pic_num, u_decode_stream.slice_data_inst.mb_index_out);
	  		if (u_decode_stream.slice_data_inst.df_qp_le_than_thresh == 0)
				$fdisplay( fp_w_bs, "qp0=%02d,qp1=%02d,qp2=%02d,qp3=%02d,qp4=%02d,qp5=%02d", 
					u_decode_stream.slice_data_inst.df_qp0, u_decode_stream.slice_data_inst.df_qp1,
					u_decode_stream.slice_data_inst.df_qp2, u_decode_stream.slice_data_inst.df_qp3,
					u_decode_stream.slice_data_inst.df_qp4, u_decode_stream.slice_data_inst.df_qp5);
			
    		$fdisplay( fp_w_bs, "ver bs=%1d %1d %1d %1d", u_decode_stream.slice_data_inst.bs_vertical[2:0], u_decode_stream.slice_data_inst.bs_vertical[14:12],
												   u_decode_stream.slice_data_inst.bs_vertical[26:24],u_decode_stream.slice_data_inst.bs_vertical[38:36]);
    		$fdisplay( fp_w_bs, "ver bs=%1d %1d %1d %1d", u_decode_stream.slice_data_inst.bs_vertical[5:3],u_decode_stream.slice_data_inst.bs_vertical[17:15],
												   u_decode_stream.slice_data_inst.bs_vertical[29:27],u_decode_stream.slice_data_inst.bs_vertical[41:39]);
    		$fdisplay( fp_w_bs, "ver bs=%1d %1d %1d %1d", u_decode_stream.slice_data_inst.bs_vertical[8:6],u_decode_stream.slice_data_inst.bs_vertical[20:18],
												   u_decode_stream.slice_data_inst.bs_vertical[32:30],u_decode_stream.slice_data_inst.bs_vertical[44:42]);
    		$fdisplay( fp_w_bs, "ver bs=%1d %1d %1d %1d", u_decode_stream.slice_data_inst.bs_vertical[11:9],u_decode_stream.slice_data_inst.bs_vertical[23:21],
												   u_decode_stream.slice_data_inst.bs_vertical[35:33],u_decode_stream.slice_data_inst.bs_vertical[47:45]);
			$fdisplay( fp_w_bs, "hor bs=%1d %1d %1d %1d", u_decode_stream.slice_data_inst.bs_horizontal[2:0], u_decode_stream.slice_data_inst.bs_horizontal[5:3],
												   u_decode_stream.slice_data_inst.bs_horizontal[8:6],u_decode_stream.slice_data_inst.bs_horizontal[11:9]);
    		$fdisplay( fp_w_bs, "hor bs=%1d %1d %1d %1d", u_decode_stream.slice_data_inst.bs_horizontal[14:12],u_decode_stream.slice_data_inst.bs_horizontal[17:15],
												   u_decode_stream.slice_data_inst.bs_horizontal[20:18],u_decode_stream.slice_data_inst.bs_horizontal[23:21]);
    		$fdisplay( fp_w_bs, "hor bs=%1d %1d %1d %1d", u_decode_stream.slice_data_inst.bs_horizontal[26:24],u_decode_stream.slice_data_inst.bs_horizontal[29:27],
												   u_decode_stream.slice_data_inst.bs_horizontal[32:30],u_decode_stream.slice_data_inst.bs_horizontal[35:33]);
    		$fdisplay( fp_w_bs, "hor bs=%1d %1d %1d %1d", u_decode_stream.slice_data_inst.bs_horizontal[38:36],u_decode_stream.slice_data_inst.bs_horizontal[41:39],
												   u_decode_stream.slice_data_inst.bs_horizontal[44:42],u_decode_stream.slice_data_inst.bs_horizontal[47:45]);
											   
    		$fflush(fp_w_bs);
		end
	end
end

initial
begin
	residual_blk_num = 0;
	fp_w_residual = $fopen("trace_residual.log", "w");
	while(1)
	begin
		@(posedge u_decode_stream.residual_inst.transform_valid);
		if (u_decode_stream.residual_inst.transform_inst.residual_state != `Intra16x16DCLevel_s &&
			u_decode_stream.residual_inst.transform_inst.residual_state != `ChromaDCLevel_Cb_s &&
			u_decode_stream.residual_inst.transform_inst.residual_state != `ChromaDCLevel_Cr_s)begin
			@(posedge clk);
			residual_blk_num = residual_blk_num + 1;
		    $fdisplay( fp_w_residual, "pic_num:%5d mb_index_out:%5d blk:%5d", u_decode_stream.pic_num, u_decode_stream.slice_data_inst.mb_index_out,  u_decode_stream.blk4x4_counter);		
			$fdisplay( fp_w_residual,"%5d%5d%5d%5d", u_decode_stream.residual_inst.residual_0, u_decode_stream.residual_inst.residual_1, u_decode_stream.residual_inst.residual_2, u_decode_stream.residual_inst.residual_3);
			$fdisplay( fp_w_residual,"%5d%5d%5d%5d", u_decode_stream.residual_inst.residual_4, u_decode_stream.residual_inst.residual_5, u_decode_stream.residual_inst.residual_6, u_decode_stream.residual_inst.residual_7);
			$fdisplay( fp_w_residual,"%5d%5d%5d%5d", u_decode_stream.residual_inst.residual_8, u_decode_stream.residual_inst.residual_9, u_decode_stream.residual_inst.residual_10, u_decode_stream.residual_inst.residual_11);
			$fdisplay( fp_w_residual,"%5d%5d%5d%5d\n",u_decode_stream.residual_inst.residual_12, u_decode_stream.residual_inst.residual_13, u_decode_stream.residual_inst.residual_14, u_decode_stream.residual_inst.residual_15);
		end
	end
end

integer fp_w_intra4x4;
initial
begin
	fp_w_intra4x4 = $fopen("trace_intra4x4.log", "w");
	while(1)
	begin
		@(negedge (u_decode_stream.intra_pred_top.intra_pred_fsm_inst.state == `intra_pred_calc_s ));
		begin
			$fdisplay( fp_w_intra4x4,"mb_index:%5d blk:%5d", u_decode_stream.slice_data_inst.mb_index_out, u_decode_stream.blk4x4_counter);
			$fdisplay( fp_w_intra4x4,"%02x   %02x   %02x   %02x   ", u_decode_stream.intra_pred_top.intra_pred_0, u_decode_stream.intra_pred_top.intra_pred_1,  u_decode_stream.intra_pred_top.intra_pred_2, u_decode_stream.intra_pred_top.intra_pred_3);
			$fdisplay( fp_w_intra4x4,"%02x   %02x   %02x   %02x   ", u_decode_stream.intra_pred_top.intra_pred_4, u_decode_stream.intra_pred_top.intra_pred_5,  u_decode_stream.intra_pred_top.intra_pred_6, u_decode_stream.intra_pred_top.intra_pred_7);
			$fdisplay( fp_w_intra4x4,"%02x   %02x   %02x   %02x   ", u_decode_stream.intra_pred_top.intra_pred_8, u_decode_stream.intra_pred_top.intra_pred_9,  u_decode_stream.intra_pred_top.intra_pred_10, u_decode_stream.intra_pred_top.intra_pred_11);
			$fdisplay( fp_w_intra4x4,"%02x   %02x   %02x   %02x   \n",u_decode_stream.intra_pred_top.intra_pred_12, u_decode_stream.intra_pred_top.intra_pred_13,  u_decode_stream.intra_pred_top.intra_pred_14, u_decode_stream.intra_pred_top.intra_pred_15);
		end
	end
end

integer fp_w_sum_hex;
initial
begin
	fp_w_sum_hex = $fopen("trace_sum_hex.log", "w");
	while(1)
	begin
		@(posedge u_decode_stream.sum.valid);
		begin
			$fdisplay( fp_w_sum_hex,"pic_num:%5d mb_index:%5d blk:%5d", u_decode_stream.pic_num, u_decode_stream.slice_data_inst.mb_index_out, u_decode_stream.blk4x4_counter);
			$fdisplay( fp_w_sum_hex,"%02x   %02x   %02x   %02x   ", u_decode_stream.sum.sum_0,  u_decode_stream.sum.sum_1,  u_decode_stream.sum.sum_2, u_decode_stream.sum.sum_3);
			$fdisplay( fp_w_sum_hex,"%02x   %02x   %02x   %02x   ", u_decode_stream.sum.sum_4,  u_decode_stream.sum.sum_5,  u_decode_stream.sum.sum_6, u_decode_stream.sum.sum_7);
			$fdisplay( fp_w_sum_hex,"%02x   %02x   %02x   %02x   ", u_decode_stream.sum.sum_8,  u_decode_stream.sum.sum_9,  u_decode_stream.sum.sum_10, u_decode_stream.sum.sum_11);
			$fdisplay( fp_w_sum_hex,"%02x   %02x   %02x   %02x   \n",u_decode_stream.sum.sum_12,  u_decode_stream.sum.sum_13,  u_decode_stream.sum.sum_14, u_decode_stream.sum.sum_15);
		end
	end
end

integer fp_w_sum;
initial
begin
	fp_w_sum = $fopen("trace_sum.log", "w");
	while(1)
	begin
		@(posedge u_decode_stream.sum.valid);
		begin
			$fdisplay( fp_w_sum,"pic_num:%5d mb_index:%5d blk:%5d", u_decode_stream.pic_num, u_decode_stream.slice_data_inst.mb_index_out, u_decode_stream.blk4x4_counter);
			$fdisplay( fp_w_sum,"%5d%5d%5d%5d", u_decode_stream.sum.sum_0,  u_decode_stream.sum.sum_1,  u_decode_stream.sum.sum_2, u_decode_stream.sum.sum_3);
			$fdisplay( fp_w_sum,"%5d%5d%5d%5d", u_decode_stream.sum.sum_4,  u_decode_stream.sum.sum_5,  u_decode_stream.sum.sum_6, u_decode_stream.sum.sum_7);
			$fdisplay( fp_w_sum,"%5d%5d%5d%5d", u_decode_stream.sum.sum_8,  u_decode_stream.sum.sum_9,  u_decode_stream.sum.sum_10, u_decode_stream.sum.sum_11);
			$fdisplay( fp_w_sum,"%5d%5d%5d%5d\n",u_decode_stream.sum.sum_12,  u_decode_stream.sum.sum_13,  u_decode_stream.sum.sum_14, u_decode_stream.sum.sum_15);
		end
	end
end

integer fp_w_mv;
initial
begin
	fp_w_mv = $fopen("trace_mv.log", "w");
    while(1)
	begin	    
		@(u_decode_stream.slice_data_inst.slice_data_state);
		if ( u_decode_stream.slice_data_inst.slice_type_mod5_in != `slice_type_I &&
             u_decode_stream.slice_data_inst.slice_type_mod5_in != `slice_type_SI && 
				u_decode_stream.slice_data_inst.slice_data_state == `mb_num_update)
        begin
            $fdisplay( fp_w_mv, "pic_num:%5d mb_index_out:%5d", u_decode_stream.bc_inst.pic_num, u_decode_stream.slice_data_inst.mb_index_out);	    	    		
    		$fdisplay( fp_w_mv, "mvx_l0_curr_mb_out:%5d%5d%5d%5d", u_decode_stream.slice_data_inst.mvx_l0_curr_mb_out[15:0],
    		                                                    u_decode_stream.slice_data_inst.mvx_l0_curr_mb_out[31:16],
    		                                                    u_decode_stream.slice_data_inst.mvx_l0_curr_mb_out[79:64],
    		                                                    u_decode_stream.slice_data_inst.mvx_l0_curr_mb_out[95:80]
    		                                                    );
    		                                                    
    		$fdisplay( fp_w_mv, "mvx_l0_curr_mb_out:%5d%5d%5d%5d", u_decode_stream.slice_data_inst.mvx_l0_curr_mb_out[47:32],
    		                                                    u_decode_stream.slice_data_inst.mvx_l0_curr_mb_out[63:48],
    		                                                    u_decode_stream.slice_data_inst.mvx_l0_curr_mb_out[111:96],
    		                                                    u_decode_stream.slice_data_inst.mvx_l0_curr_mb_out[127:112]
    		                                                    );
    		$fdisplay( fp_w_mv, "mvx_l0_curr_mb_out:%5d%5d%5d%5d", u_decode_stream.slice_data_inst.mvx_l0_curr_mb_out[143:128],
    		                                                    u_decode_stream.slice_data_inst.mvx_l0_curr_mb_out[159:144],
    		                                                    u_decode_stream.slice_data_inst.mvx_l0_curr_mb_out[207:192],
    		                                                    u_decode_stream.slice_data_inst.mvx_l0_curr_mb_out[223:208]
    		                                                    );
    		$fdisplay( fp_w_mv, "mvx_l0_curr_mb_out:%5d%5d%5d%5d", u_decode_stream.slice_data_inst.mvx_l0_curr_mb_out[175:160],
    		                                                    u_decode_stream.slice_data_inst.mvx_l0_curr_mb_out[191:176],
    		                                                    u_decode_stream.slice_data_inst.mvx_l0_curr_mb_out[239:224],
    		                                                    u_decode_stream.slice_data_inst.mvx_l0_curr_mb_out[255:240]
    		                                                    );
    		$fdisplay( fp_w_mv, "mvy_l0_curr_mb_out:%5d%5d%5d%5d", u_decode_stream.slice_data_inst.mvy_l0_curr_mb_out[15:0],
    		                                                    u_decode_stream.slice_data_inst.mvy_l0_curr_mb_out[31:16],
    		                                                    u_decode_stream.slice_data_inst.mvy_l0_curr_mb_out[79:64],
    		                                                    u_decode_stream.slice_data_inst.mvy_l0_curr_mb_out[95:80]
    		                                                    
    		                                                    );
    		$fdisplay( fp_w_mv, "mvy_l0_curr_mb_out:%5d%5d%5d%5d", u_decode_stream.slice_data_inst.mvy_l0_curr_mb_out[47:32],
    		                                                    u_decode_stream.slice_data_inst.mvy_l0_curr_mb_out[63:48]
    		                                                    ,
    		                                                    u_decode_stream.slice_data_inst.mvy_l0_curr_mb_out[111:96],
    		                                                    u_decode_stream.slice_data_inst.mvy_l0_curr_mb_out[127:112]
    		                                                    );
    		$fdisplay( fp_w_mv, "mvy_l0_curr_mb_out:%5d%5d%5d%5d", u_decode_stream.slice_data_inst.mvy_l0_curr_mb_out[143:128],
    		                                                    u_decode_stream.slice_data_inst.mvy_l0_curr_mb_out[159:144],
    		                                                    u_decode_stream.slice_data_inst.mvy_l0_curr_mb_out[207:192],
    		                                                    u_decode_stream.slice_data_inst.mvy_l0_curr_mb_out[223:208]
    		                                                    );
    		$fdisplay( fp_w_mv, "mvy_l0_curr_mb_out:%5d%5d%5d%5d", u_decode_stream.slice_data_inst.mvy_l0_curr_mb_out[175:160],
    		                                                    u_decode_stream.slice_data_inst.mvy_l0_curr_mb_out[191:176]
    		                                                    ,
    		                                                    u_decode_stream.slice_data_inst.mvy_l0_curr_mb_out[239:224],
    		                                                    u_decode_stream.slice_data_inst.mvy_l0_curr_mb_out[255:240]); 
    		$fdisplay( fp_w_mv,"");  
		end
	end
end

initial
begin
	fp_w = $fopen("trace.log", "w");
    while(1)
	begin	    
		@(u_decode_stream.slice_data_inst.slice_data_state);
		if (u_decode_stream.slice_data_inst.slice_data_state == `mb_num_update)
        begin
            $display( "pic_num:%d mb_index_out:%d", u_decode_stream.bc_inst.pic_num, u_decode_stream.slice_data_inst.mb_index_out);	    	
		    $fdisplay( fp_w, "pic_num:%d mb_index_out:%d", u_decode_stream.bc_inst.pic_num, u_decode_stream.slice_data_inst.mb_index_out);	    	
    		
    		$fdisplay( fp_w, "mb_type:%-50d", u_decode_stream.slice_data_inst.mb_type);
    		$fdisplay( fp_w, "ref_idx_l0_curr_mb_out:%5d%5d%5d%5d", 
    		           u_decode_stream.slice_data_inst.ref_idx_l0_curr_mb_out[2:0],
    		           u_decode_stream.slice_data_inst.ref_idx_l0_curr_mb_out[5:3],
    		           u_decode_stream.slice_data_inst.ref_idx_l0_curr_mb_out[8:6],
    		           u_decode_stream.slice_data_inst.ref_idx_l0_curr_mb_out[11:9]);
    		$fdisplay( fp_w, "intra4x4_pred_mode_curr_mb_out:%-50x", u_decode_stream.slice_data_inst.intra4x4_pred_mode_curr_mb_out);
    		$fdisplay( fp_w, "nC_curr_mb_out:%-50x", u_decode_stream.slice_data_inst.nC_curr_mb_out);
    		$fdisplay( fp_w, "nC_cb_curr_mb_out:%-032x", u_decode_stream.slice_data_inst.nC_cb_curr_mb_out);
    		$fdisplay( fp_w, "nC_cr_curr_mb_out:%-032x", u_decode_stream.slice_data_inst.nC_cr_curr_mb_out);
    		$fdisplay( fp_w, "qp:%-50d", u_decode_stream.slice_data_inst.qp);
    		$fdisplay( fp_w, "qp_c:%-50d", u_decode_stream.slice_data_inst.qp_c);
/*
    		$fdisplay( fp_w, "mvx_l0_curr_mb_out:%5d%5d%5d%5d", u_decode_stream.slice_data_inst.mvx_l0_curr_mb_out[15:0],
    		                                                    u_decode_stream.slice_data_inst.mvx_l0_curr_mb_out[31:16],
    		                                                    u_decode_stream.slice_data_inst.mvx_l0_curr_mb_out[79:64],
    		                                                    u_decode_stream.slice_data_inst.mvx_l0_curr_mb_out[95:80]
    		                                                    );
    		$fdisplay( fp_w, "mvx_l0_curr_mb_out:%5d%5d%5d%5d", u_decode_stream.slice_data_inst.mvx_l0_curr_mb_out[47:32],
    		                                                    u_decode_stream.slice_data_inst.mvx_l0_curr_mb_out[63:48]
    		                                                    ,
    		                                                    u_decode_stream.slice_data_inst.mvx_l0_curr_mb_out[111:96],
    		                                                    u_decode_stream.slice_data_inst.mvx_l0_curr_mb_out[127:112]);
    		$fdisplay( fp_w, "mvx_l0_curr_mb_out:%5d%5d%5d%5d", u_decode_stream.slice_data_inst.mvx_l0_curr_mb_out[143:128],
    		                                                    u_decode_stream.slice_data_inst.mvx_l0_curr_mb_out[159:144],
    		                                                    u_decode_stream.slice_data_inst.mvx_l0_curr_mb_out[207:192],
    		                                                    u_decode_stream.slice_data_inst.mvx_l0_curr_mb_out[223:208]
    		                                                    
    		                                                    );
    		$fdisplay( fp_w, "mvx_l0_curr_mb_out:%5d%5d%5d%5d", u_decode_stream.slice_data_inst.mvx_l0_curr_mb_out[175:160],
    		                                                    u_decode_stream.slice_data_inst.mvx_l0_curr_mb_out[191:176],
    		                                                    u_decode_stream.slice_data_inst.mvx_l0_curr_mb_out[239:224],
    		                                                    u_decode_stream.slice_data_inst.mvx_l0_curr_mb_out[255:240]
    		                                                    );
    		$fdisplay( fp_w, "mvy_l0_curr_mb_out:%5d%5d%5d%5d", u_decode_stream.slice_data_inst.mvy_l0_curr_mb_out[15:0],
    		                                                    u_decode_stream.slice_data_inst.mvy_l0_curr_mb_out[31:16],
    		                                                    u_decode_stream.slice_data_inst.mvy_l0_curr_mb_out[79:64],
    		                                                    u_decode_stream.slice_data_inst.mvy_l0_curr_mb_out[95:80]
    		                                                    
    		                                                    );
    		$fdisplay( fp_w, "mvy_l0_curr_mb_out:%5d%5d%5d%5d", u_decode_stream.slice_data_inst.mvy_l0_curr_mb_out[47:32],
    		                                                    u_decode_stream.slice_data_inst.mvy_l0_curr_mb_out[63:48]
    		                                                    ,
    		                                                    u_decode_stream.slice_data_inst.mvy_l0_curr_mb_out[111:96],
    		                                                    u_decode_stream.slice_data_inst.mvy_l0_curr_mb_out[127:112]
    		                                                    );
    		$fdisplay( fp_w, "mvy_l0_curr_mb_out:%5d%5d%5d%5d", u_decode_stream.slice_data_inst.mvy_l0_curr_mb_out[143:128],
    		                                                    u_decode_stream.slice_data_inst.mvy_l0_curr_mb_out[159:144],
    		                                                    u_decode_stream.slice_data_inst.mvy_l0_curr_mb_out[207:192],
    		                                                    u_decode_stream.slice_data_inst.mvy_l0_curr_mb_out[223:208]
    		                                                    );
    		$fdisplay( fp_w, "mvy_l0_curr_mb_out:%5d%5d%5d%5d", u_decode_stream.slice_data_inst.mvy_l0_curr_mb_out[175:160],
    		                                                    u_decode_stream.slice_data_inst.mvy_l0_curr_mb_out[191:176]
    		                                                    ,
    		                                                    u_decode_stream.slice_data_inst.mvy_l0_curr_mb_out[239:224],
    		                                                    u_decode_stream.slice_data_inst.mvy_l0_curr_mb_out[255:240]);
*/
/*     		$fdisplay( fp_w, "ref_idx_l0_curr_mb_out:%3d%3d%3d%3d", u_decode_stream.slice_data_inst.ref_idx_l0_curr_mb_out[2:0],
    		                                                    u_decode_stream.slice_data_inst.ref_idx_l0_curr_mb_out[5:3]
    		                                                    ,
    		                                                    u_decode_stream.slice_data_inst.ref_idx_l0_curr_mb_out[8:6],
    		                                                    u_decode_stream.slice_data_inst.ref_idx_l0_curr_mb_out[11:9]);    		                                                    
    		
   	    	$fdisplay( fp_w, "CBP_luma_reg:%-50d", u_decode_stream.slice_data_inst.CBP_luma_reg);
    		$fdisplay( fp_w, "CBP_chroma_reg:%-50d", u_decode_stream.slice_data_inst.CBP_chroma_reg);
    		$fdisplay( fp_w, "mb_qp_delta:%-50d", u_decode_stream.slice_data_inst.mb_qp_delta);
    		$fdisplay( fp_w, "mb_pred_mode_out:%-50d", u_decode_stream.slice_data_inst.mb_pred_mode_out);
    		$fdisplay( fp_w, "I16_pred_mode:%-50d", u_decode_stream.slice_data_inst.I16_pred_mode);
    		$fdisplay( fp_w, "intra_pred_mode_chroma:%-50d", u_decode_stream.slice_data_inst.intra_pred_mode_chroma);
    		$fdisplay( fp_w, "intra_mode:%-50d\n\n", u_decode_stream.slice_data_inst.intra_mode);
    
    		$fdisplay( fp_w,"------------------------------------------------------------");*/	 
    		$fdisplay( fp_w,"");  
    		$fflush(fp_w);
		end
	end
end

/*
always @(u_decode_stream.slice_data_inst.mb_pred_state or u_decode_stream.slice_data_inst.rbsp_buffer_valid_in) 
if(u_decode_stream.slice_data_inst.rbsp_buffer_valid_in)
begin
    if (u_decode_stream.slice_data_inst.mb_pred_state == `prev_intra4x4_pred_mode_flag_s && u_decode_stream.slice_data_inst.rbsp_in[23] == 1)
        $fdisplay(fp_w, "luma4x4BlkIdx_out:%d  prev_intra4x4_pred_mode_flag_out:1", u_decode_stream.slice_data_inst.luma4x4BlkIdx_out);
    else if (u_decode_stream.slice_data_inst.mb_pred_state == `rem_intra4x4_pred_mode_s)
        begin
            #1;
            $fdisplay(fp_w, "luma4x4BlkIdx_out:%d  prev_intra4x4_pred_mode_flag_out:0  rem_intra4x4_pred_mode_out:%b",
            u_decode_stream.slice_data_inst.luma4x4BlkIdx_out, u_decode_stream.slice_data_inst.rbsp_in[23:21]);
        end
    else if (u_decode_stream.slice_data_inst.mb_pred_state == `mvdx_l0_s)
        begin
            #1;
            $fdisplay(fp_w, "mvdx_l0:%d mvpx_l0_in:%d mbPartIdx:%d",
            u_decode_stream.slice_data_inst.exp_golomb_decoding_output_se_in, u_decode_stream.slice_data_inst.mvpx_l0_in,
            u_decode_stream.slice_data_inst.mbPartIdx);        
        end
    else if (u_decode_stream.slice_data_inst.mb_pred_state == `mvdy_l0_s)
        begin
            #1;
            $fdisplay(fp_w, "mvdy_l0:%d mvpx_l0_in:%d mbPartIdx:%d",
            u_decode_stream.slice_data_inst.exp_golomb_decoding_output_se_in, u_decode_stream.slice_data_inst.mvpy_l0_in,
            u_decode_stream.slice_data_inst.mbPartIdx);        
        end
end

always @(u_decode_stream.slice_data_inst.sub_mb_pred_state or u_decode_stream.slice_data_inst.rbsp_buffer_valid_in)
if(u_decode_stream.slice_data_inst.rbsp_buffer_valid_in)
    if (u_decode_stream.slice_data_inst.sub_mb_pred_state == `sub_mb_type_s)
        begin
            #1;
            $fdisplay(fp_w, "sub_mb_type:%d mbPartIdx:%d ", u_decode_stream.slice_data_inst.exp_golomb_decoding_output_in,
            u_decode_stream.slice_data_inst.mbPartIdx);        
        end
    else if (u_decode_stream.slice_data_inst.sub_mb_pred_state == `sub_mvdx_l0_s)
        begin
            #1;
            $fdisplay(fp_w, "mvdx_l0:%d mvpx_l0_in:%d mbPartIdx:%d subMbPartIdx:%d",
            u_decode_stream.slice_data_inst.exp_golomb_decoding_output_se_in, u_decode_stream.slice_data_inst.mvpx_l0_in,
            u_decode_stream.slice_data_inst.mbPartIdx,
            u_decode_stream.slice_data_inst.subMbPartIdx);        
        end
    else if (u_decode_stream.slice_data_inst.sub_mb_pred_state == `sub_mvdy_l0_s)
        begin
            #1;
            $fdisplay(fp_w, "mvdy_l0:%d mvpx_l0_in:%d mbPartIdx:%d subMbPartIdx:%d",
            u_decode_stream.slice_data_inst.exp_golomb_decoding_output_se_in, u_decode_stream.slice_data_inst.mvpy_l0_in,
            u_decode_stream.slice_data_inst.mbPartIdx,
            u_decode_stream.slice_data_inst.subMbPartIdx);        
        end   
*/
initial 
begin 
    $fsdbDumpfile("top.fsdb"); 
    $fsdbDumpvars; 
end 
`endif
endmodule

