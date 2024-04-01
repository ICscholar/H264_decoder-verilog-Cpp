//--------------------------------------------------------------------------------------------------
// Design    : bitstream_p
// Author(s) : qiu bin, shi tian qi
// Email     : chat1@126.com, tishi1@126.com
// Copyright (C) 2013 qiu bin 
// All rights reserved                
//-------------------------------------------------------------------------------------------------
//`define RES_1080p

module video_ctrl(
	input        rst_n,
	input        clk,
	output reg   hsync_n,
	output reg   vsync_n,
	output reg   de,
	output reg   is_next_pixel_active,
	output reg   y_valid,
	output reg [12:0] next_x,
	output reg [12:0] next_y,
	output reg [12:0] hcnt,
	output reg [12:0] vcnt,

	output [15:0] pixel_clock_div_10000,
	output [15:0] v_freq,
	output [15:0] num_pixels_per_line,
	output [15:0] num_lines
);
`ifdef RES_1080p
//Horizontal timing constants
parameter H_FRONT		= 'd148;
parameter H_SYNC        = 'd44;
parameter H_BACK        = 'd88;
parameter H_ACT         = 'd1920;
parameter H_BLANK_END   =  H_FRONT+H_SYNC+H_BACK;
parameter H_PERIOD      =  H_FRONT+H_SYNC+H_BACK+H_ACT;
//Vertical timing constants
parameter V_FRONT       =  'd15;//'d36; 
parameter V_SYNC        =  'd5;
parameter V_BACK        = 'd2; //'d4
parameter V_ACT         = 'd1080;
parameter V_BLANK_END   =  V_FRONT+V_SYNC+V_BACK;
parameter V_PERIOD      =  V_FRONT+V_SYNC+V_BACK+V_ACT;
//parameter PIXEL_CLOCK   = 74250000;
assign pixel_clock_div_10000 = v_freq * num_pixels_per_line * num_lines / 10000;
assign v_freq = 60;
assign num_pixels_per_line = H_PERIOD;
assign num_lines = V_PERIOD;

`else
//Horizontal timing constants
parameter H_FRONT		= 'd220;
parameter H_SYNC        = 'd40;
parameter H_BACK        = 'd110;
parameter H_ACT         = 'd1280;
parameter H_BLANK_END   =  H_FRONT+H_SYNC+H_BACK;
parameter H_PERIOD      =  H_FRONT+H_SYNC+H_BACK+H_ACT;
//Vertical timing constants
parameter V_FRONT       = 'd20;
parameter V_SYNC        = 'd5;
parameter V_BACK        = 'd5;
parameter V_ACT         = 'd720;
parameter V_BLANK_END   =  V_FRONT+V_SYNC+V_BACK;
parameter V_PERIOD      =  V_FRONT+V_SYNC+V_BACK+V_ACT;
//parameter PIXEL_CLOCK   = 74250000;
assign pixel_clock_div_10000 = v_freq * num_pixels_per_line * num_lines / 10000;
assign v_freq = 60;
assign num_pixels_per_line = H_PERIOD;
assign num_lines = V_PERIOD;
`endif



//hsync_n
always @ (posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		hcnt <= 0;
		hsync_n <= 1;
	end
	else
	begin
		if(hcnt<H_PERIOD-1)
			hcnt <= hcnt + 1;  
		else 
			hcnt <= 0;
		if (hcnt == H_FRONT-1)
			hsync_n <= 1'b0;
		else if (hcnt == H_FRONT+H_SYNC-1)
			hsync_n <= 1'b1;
	end
end
  
 
//vsync_n
always @ (posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		vcnt <=  0;
		vsync_n <= 1;
	end
	else
	begin 
		if (hcnt == H_PERIOD-1)
		begin
			if(vcnt<V_PERIOD-1)
				vcnt <= vcnt + 1;  
			else 
				vcnt <= 0;
			if (vcnt == V_FRONT-1)
				vsync_n <= 1'b0;
			else if (vcnt == V_FRONT+V_SYNC-1)
				vsync_n <= 1'b1;
		end
	end
end
    
//valid h blank end = 10
//cnt 0 1 2 3 4 5 6 7 8 9, 0-8 is_next_pixel_active=0, 9 is_next_pixel_active
//=1
always @ (posedge clk or negedge rst_n)
if (!rst_n) begin
	is_next_pixel_active <= 0;
	de <= 0;
	y_valid <= 0;
end 
else begin
	if (vcnt >= V_BLANK_END) begin
		if (hcnt == H_BLANK_END - 2)
			is_next_pixel_active <= 1'b1;
		else if (hcnt == H_PERIOD - 2)
			is_next_pixel_active <= 1'b0;
	end
	y_valid <= vcnt >= V_BLANK_END;
	de <= is_next_pixel_active;
end
	
//x & y
always @ (posedge clk or negedge rst_n)
if (!rst_n) begin
	next_x <= 0;
	next_y <= 0;
end
else begin
	if (hcnt < H_BLANK_END - 1)
		next_x <= 0;
	else
		next_x <= next_x + 1'b1;
	
	if (vcnt < V_BLANK_END)
		next_y <= 0;
	else if (hcnt == H_PERIOD-1)
		next_y <= next_y + 1'b1;
end

endmodule
   
     
    

