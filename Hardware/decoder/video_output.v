//--------------------------------------------------------------------------------------------------
// Design    : bitstream_p
// Author(s) : qiu bin, shi tian qi
// Email     : chat1@126.com, tishi1@126.com
// Copyright (C) 2013 qiu bin 
// All rights reserved                
//-------------------------------------------------------------------------------------------------
//`define YUV422_Output

`ifdef YUV422_Output
module video_output (
	input clk,
  	input video_de_i,
	input video_hs_n_i,
	input video_vs_n_i,
	input[10:0] video_next_x_i,
	input[63:0] y_data,
	input[63:0] u_data,
	input[63:0] v_data,
	output reg video_de,
	output reg video_hs_n,
	output reg video_vs_n,
	output reg [7:0] video_y,
	output reg [7:0] video_u,
	output reg [7:0] video_v
);


always @(posedge clk) begin
	video_y = y_data[7+video_next_x_i[2:0]*8-:8];
	video_u = u_data[7+video_next_x_i[3:1]*8-:8];
	video_v = v_data[7+video_next_x_i[3:1]*8-:8];
	video_de <= video_de_i;
	video_hs_n <= video_hs_n_i;
	video_vs_n <= video_vs_n_i;
end

endmodule

`else
module video_output (
	input clk,
  	input video_de_i,
	input video_hs_n_i,
	input video_vs_n_i,
	input[10:0] video_next_x_i,
	input[63:0] y_data,
	input[63:0] u_data,
	input[63:0] v_data,
	output reg video_de,
	output reg video_hs_n,
	output reg video_vs_n,
	output [15:0] video_data
);


reg [7:0]	y;
reg	[7:0]	u;
reg	[7:0]	v;
reg video_de_d;
reg video_hs_n_d;
reg video_vs_n_d;
reg video_de_dd;
reg video_hs_n_dd;
reg video_vs_n_dd;

always @(posedge clk) begin
	video_de_d <= video_de_i;
    video_hs_n_d <= video_hs_n_i;
    video_vs_n_d <= video_vs_n_i;
    video_de_dd <= video_de_d;
    video_hs_n_dd <= video_hs_n_d;
    video_vs_n_dd <= video_vs_n_d;
	y = y_data[7+video_next_x_i[2:0]*8-:8];
	u = u_data[7+video_next_x_i[3:1]*8-:8];
	v = v_data[7+video_next_x_i[3:1]*8-:8];
	video_de <= video_de_dd;
	video_hs_n <= video_hs_n_dd;
	video_vs_n <= video_vs_n_dd;
end
//
//regs
//
reg  [7:0]  video_r,video_g,video_b;
reg  [9:0] r_tmp;
reg  [9:0] g_tmp;
reg  [9:0] b_tmp;

assign video_data = {video_r[7:3], video_g[7:2],video_b[7:3]};

always@(posedge clk) begin
    if (r_tmp[9])
      video_r <= 0;
    else if (r_tmp[8:0] > 255)
      video_r <= 255;
    else
      video_r <= r_tmp[7:0];

    if (g_tmp[9])
      video_g <= 0;
    else if (g_tmp[8:0] > 255)
      video_g <= 255;
    else
      video_g <= g_tmp[7:0];
      
    if (b_tmp[9])
      video_b <= 0;
    else if (b_tmp[8:0] > 255)
      video_b <= 255;
    else
      video_b <= b_tmp[7:0];
end

/*
R = 1.164(Y-16) + 1.596(Cr-128)
G = 1.164(Y-16) - 0.391(Cb-128) - 0.813(Cr-128)
B = 1.164(Y-16) + 2.018(Cb-128)

R << 9 = 596Y  + 817Cr          - 114131
G << 9 = 596Y  - 416Cr - 200Cb  + 69370
B << 9 = 596Y          + 1033Cb - 141787
*/
reg [17:0] a0;
reg [17:0] a1;
reg [17:0] a2;
reg [17:0] a3;
reg [17:0] a4;

always@(posedge clk) begin
    a0<= y*596;
    a1 <=v*817;
    a2 <=u*200;
    a3 <=v*416;
    a4 <= u*1033;
end
/*
always@(posedge clk) begin
    r_tmp <= ( y*596 + v*817 - 114131 ) >>9;
    g_tmp <= ( y*596 - u*200 - v*416 + 69370) >>9;
    b_tmp <= ( y*596 + u*1033 - 141787 ) >>9;
end
*/
always@(posedge clk) begin
    r_tmp <= ( a0[17:2] + a1[17:2] - 114131/4 ) >>7;
    g_tmp <= ( a0[17:2] - a2[17:2] - a3[17:2] + 69370/4) >>7;
    b_tmp <= ( a0[17:2] + a4[17:2] - 141787/4 ) >>7;
end

endmodule
`endif

