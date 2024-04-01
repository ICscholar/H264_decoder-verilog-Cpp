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

// used for storing intra4x4_pred_mode, ref_idx, mvp etc
// 
module ext_ram_32
(
	wr_clk,
	rd_clk,
	rd_clk_display,
	wr, 
	wr_addr, 
	rd_addr, 
	rd_addr_display,
	rd_addr_check,
	data_in, 
	data_out,
	data_out_display,
	data_out_check,
	start_of_frame,
	end_of_frame,
	pic_num
);
parameter
BinMode = 0;

input wr_clk;
input rd_clk;
input rd_clk_display;
input wr;
input[25:0] wr_addr;
input[25:0] rd_addr;
input[31:0] rd_addr_display;
input[25:0] rd_addr_check;
input[31:0] data_in;
output reg [63:0] data_out;
output reg [63:0] data_out_display;
output reg [63:0] data_out_check;
input start_of_frame;
input end_of_frame;
input [63:0] pic_num;
reg [2:0] pic_num_d;
reg[31:0] ram[0:8000000];

//read
always @ (posedge rd_clk)
if (rd_addr % 4 == 0)begin
  	data_out[63:32] <= ram[rd_addr/4+1];
  	data_out[31:0] <= ram[rd_addr/4];
end
else if (rd_addr % 4 == 1) begin
	data_out[63:56] <= ram[rd_addr/4+2][7:0];
	data_out[55:24] <= ram[rd_addr/4+1];
	data_out[23:00] <= ram[rd_addr/4][31:8];
end
else if (rd_addr % 4 == 2) begin
	data_out[63:48] <= ram[rd_addr/4+2][15:0];
	data_out[47:16] <= ram[rd_addr/4+1];
	data_out[15:00] <= ram[rd_addr/4][31:16];
end
else begin// if (rd_addr % 4 == 3) begin
	data_out[63:40] <= ram[rd_addr/4+2][23:0];
	data_out[39:08] <= ram[rd_addr/4+1];
	data_out[07:00] <= ram[rd_addr/4][31:24];
end

//read
always @ (posedge rd_clk_display)
if (rd_addr_display % 4 == 0)begin
  	data_out_display <= {ram[(rd_addr_display-32'h10000000)/4+1],ram[(rd_addr_display-32'h10000000)/4]};
end
else begin
	$display("rd_addr_display not 4 bytes aligned");
end

//read check
always @ (*)
if (rd_addr_display % 4 == 0)begin
  	data_out_check <= {ram[rd_addr_check/4+1],ram[rd_addr_check/4]};
end
else begin
	$display("rd_addr_display not 4 bytes aligned");
end


//write
always @ (posedge wr_clk)
    if (wr)
        ram[wr_addr/4] <= data_in;

wire write_to_file_start;
reg is_after_end_of_frame;

always@(posedge wr_clk)begin
	if (start_of_frame)
		is_after_end_of_frame <= 1'b0;
	else if (end_of_frame) begin
		is_after_end_of_frame <= 1'b1;
		pic_num_d <= pic_num[2:0];
	end
end

assign write_to_file_start = is_after_end_of_frame && u_decode_stream.write_to_ram_idle;

integer fp_w;
reg [7:0] data;
integer j,idx;
integer frame_size;
initial
	begin
		if (BinMode)
			$fputc(0,0);
		else
			fp_w = $fopen("out.yuv");
		while(1) begin
			@ (posedge write_to_file_start);
			frame_size = (u_decode_stream.pic_width_in_mbs_minus1 + 1)*(u_decode_stream.pic_height_in_map_units_minus1+1)*16*24;
			for (j= 0; j < frame_size; j= j + 1) begin
	        	idx = frame_size*pic_num_d[2:0] + j;
				if (idx[1:0] == 0)
					data = ram[idx/4][7:0];
				else if (idx[1:0] == 1)
					data = ram[idx/4][15:8];
				else if (idx[1:0] == 2)
					data = ram[idx/4][23:16];
				else
					data = ram[idx/4][31:24];

				if (BinMode)
					$fputc(data,1);
				else
					$fwrite(fp_w,"%02x",data);
				
	        	//$fdisplay(fp_display, "%h", ram[idx]);
	        end        
			if (BinMode)
				$fputc(0,2);
			else
				$fflush(fp_w);
			$display("frame write done\n");
		end
	end
	
endmodule

