// Accumulates residual and prediction pixels for each 4x4 block
// Implements sum pixel adder to add signed residual and prediction
// Outputs sum values for 4x4 blocks in a macroblock
// Generates right column and bottom row sums
// State machine controls pipeline stages

`include "defines.v"

module sum
(
	clk,
	rst_n,
	ena,
	blk4x4_counter,
	mb_index,
	total_mbs_one_frame,
	mb_pred_mode,
	mb_pred_inter_sel,
	is_residual_not_dc,
	
    residual_0,
    residual_1, 
    residual_2, 
    residual_3, 
    residual_4, 
    residual_5, 
    residual_6, 
    residual_7, 
    residual_8, 
    residual_9, 
    residual_10,
    residual_11,
    residual_12,
    residual_13,
    residual_14,	
    residual_15,
	residual_out_ram_wr_addr,
	residual_out_ram_rd,
	residual_valid,
	
	intra_pred_0,
	intra_pred_1,
	intra_pred_2,
	intra_pred_3,
	intra_pred_4,
	intra_pred_5,
	intra_pred_6,
	intra_pred_7,
	intra_pred_8,
	intra_pred_9, 
	intra_pred_10,
	intra_pred_11,
	intra_pred_12,
	intra_pred_13,
	intra_pred_14,
	intra_pred_15,
	intra_pred_valid,
	
	inter_pred_0,
	inter_pred_1,
	inter_pred_2,
	inter_pred_3,
	inter_pred_4,
	inter_pred_5,
	inter_pred_6,
	inter_pred_7,
	inter_pred_8,
	inter_pred_9, 
	inter_pred_10,
	inter_pred_11,
	inter_pred_12,
	inter_pred_13,
	inter_pred_14,
	inter_pred_15,
	inter_pred_out_ram_wr_addr,
	inter_pred_out_ram_rd,
	
	sum_0,
	sum_1,
	sum_2,
	sum_3,
	sum_4,
	sum_5,
	sum_6,
	sum_7,
	sum_8,
	sum_9,
	sum_10,
	sum_11,
	sum_12,
	sum_13,
	sum_14,
	sum_15,	
	sum_right_colum,
	sum_bottom_row,
	write_to_ram_start,             //write current blk4x4 to fpga ram
	write_to_ext_ram_last_mb_start,		//write last mb pixels to external ram
	write_to_ram_idle,
	valid
);
parameter MBsCacheWidth = 4; //cache 4 MBs for writing
parameter Log2MBsCacheWidth = 2; //cache 4 MBs for writing

input clk;
input rst_n;
input ena;

input [4:0] blk4x4_counter;
input [`mb_x_bits+`mb_y_bits-1:0] mb_index;
input [`mb_x_bits+`mb_y_bits:0] total_mbs_one_frame;
input [3:0] mb_pred_mode;
input mb_pred_inter_sel;
input is_residual_not_dc;

input [8:0] residual_0;
input [8:0] residual_1;
input [8:0] residual_2;
input [8:0] residual_3;
input [8:0] residual_4;
input [8:0] residual_5;
input [8:0] residual_6;
input [8:0] residual_7;
input [8:0] residual_8;
input [8:0] residual_9;
input [8:0] residual_10;
input [8:0] residual_11;
input [8:0] residual_12;
input [8:0] residual_13;
input [8:0] residual_14;
input [8:0] residual_15;
input [4:0] residual_out_ram_wr_addr;
output reg residual_out_ram_rd;
input residual_valid;

input [7:0] intra_pred_0; 
input [7:0] intra_pred_1; 
input [7:0] intra_pred_2; 
input [7:0] intra_pred_3; 
input [7:0] intra_pred_4; 
input [7:0] intra_pred_5; 
input [7:0] intra_pred_6; 
input [7:0] intra_pred_7; 
input [7:0] intra_pred_8; 
input [7:0] intra_pred_9; 
input [7:0] intra_pred_10;
input [7:0] intra_pred_11;
input [7:0] intra_pred_12;
input [7:0] intra_pred_13;
input [7:0] intra_pred_14;
input [7:0] intra_pred_15;
input intra_pred_valid;

input [7:0] inter_pred_0; 
input [7:0] inter_pred_1; 
input [7:0] inter_pred_2; 
input [7:0] inter_pred_3; 
input [7:0] inter_pred_4; 
input [7:0] inter_pred_5; 
input [7:0] inter_pred_6; 
input [7:0] inter_pred_7; 
input [7:0] inter_pred_8; 
input [7:0] inter_pred_9; 
input [7:0] inter_pred_10;
input [7:0] inter_pred_11;
input [7:0] inter_pred_12;
input [7:0] inter_pred_13;
input [7:0] inter_pred_14;
input [7:0] inter_pred_15;
input [4:0] inter_pred_out_ram_wr_addr;
output reg inter_pred_out_ram_rd;

output [7:0] sum_0;
output [7:0] sum_1;
output [7:0] sum_2;
output [7:0] sum_3;
output [7:0] sum_4;
output [7:0] sum_5;
output [7:0] sum_6;
output [7:0] sum_7;
output [7:0] sum_8;
output [7:0] sum_9;
output [7:0] sum_10;
output [7:0] sum_11;
output [7:0] sum_12;
output [7:0] sum_13;
output [7:0] sum_14;
output [7:0] sum_15;

output [31:0] sum_right_colum;
output [31:0] sum_bottom_row;

input  write_to_ram_idle;
output write_to_ram_start;
output write_to_ext_ram_last_mb_start;
output reg valid;
//FFs
parameter
Idle  = 0,
WaitIntraBlk4x4 = 1,
CalcSum = 6,
Write = 7;

reg [2:0] state;
reg write_to_ram_start;
reg valid_flag;

reg [7:0] sum_0;
reg [7:0] sum_1;
reg [7:0] sum_2;
reg [7:0] sum_3;
reg [7:0] sum_4;
reg [7:0] sum_5;
reg [7:0] sum_6;
reg [7:0] sum_7;
reg [7:0] sum_8;
reg [7:0] sum_9;
reg [7:0] sum_10;
reg [7:0] sum_11;
reg [7:0] sum_12;
reg [7:0] sum_13;
reg [7:0] sum_14;
reg [7:0] sum_15;

reg [31:0] sum_right_colum;
reg [31:0] sum_bottom_row;

reg [8:0] sum_pixel_0_a;
reg [8:0] sum_pixel_1_a;
reg [8:0] sum_pixel_2_a;
reg [8:0] sum_pixel_3_a;
reg [8:0] sum_pixel_4_a;
reg [8:0] sum_pixel_5_a;
reg [8:0] sum_pixel_6_a;
reg [8:0] sum_pixel_7_a;
reg [8:0] sum_pixel_8_a;
reg [8:0] sum_pixel_9_a;
reg [8:0] sum_pixel_10_a;
reg [8:0] sum_pixel_11_a;
reg [8:0] sum_pixel_12_a;
reg [8:0] sum_pixel_13_a;
reg [8:0] sum_pixel_14_a;
reg [8:0] sum_pixel_15_a;

reg [7:0] sum_pixel_0_b;
reg [7:0] sum_pixel_1_b;
reg [7:0] sum_pixel_2_b;
reg [7:0] sum_pixel_3_b;
reg [7:0] sum_pixel_4_b;
reg [7:0] sum_pixel_5_b;
reg [7:0] sum_pixel_6_b;
reg [7:0] sum_pixel_7_b;
reg [7:0] sum_pixel_8_b;
reg [7:0] sum_pixel_9_b;
reg [7:0] sum_pixel_10_b;
reg [7:0] sum_pixel_11_b;
reg [7:0] sum_pixel_12_b;
reg [7:0] sum_pixel_13_b;
reg [7:0] sum_pixel_14_b;
reg [7:0] sum_pixel_15_b;

wire [7:0] sum_pixel_0;
wire [7:0] sum_pixel_1;
wire [7:0] sum_pixel_2;
wire [7:0] sum_pixel_3;
wire [7:0] sum_pixel_4;
wire [7:0] sum_pixel_5;
wire [7:0] sum_pixel_6;
wire [7:0] sum_pixel_7;
wire [7:0] sum_pixel_8;
wire [7:0] sum_pixel_9;
wire [7:0] sum_pixel_10;
wire [7:0] sum_pixel_11;
wire [7:0] sum_pixel_12;
wire [7:0] sum_pixel_13;
wire [7:0] sum_pixel_14;
wire [7:0] sum_pixel_15;

sum_pixel sum_pixel_inst_0(
	.a(sum_pixel_0_a),
	.b(sum_pixel_0_b),
	.sum(sum_pixel_0)
);
sum_pixel sum_pixel_inst_1(
	.a(sum_pixel_1_a),
	.b(sum_pixel_1_b),
	.sum(sum_pixel_1)
);
sum_pixel sum_pixel_inst_2(
	.a(sum_pixel_2_a),
	.b(sum_pixel_2_b),
	.sum(sum_pixel_2)
);
sum_pixel sum_pixel_inst_3(
	.a(sum_pixel_3_a),
	.b(sum_pixel_3_b),
	.sum(sum_pixel_3)
);
sum_pixel sum_pixel_inst_4(
	.a(sum_pixel_4_a),
	.b(sum_pixel_4_b),
	.sum(sum_pixel_4)
);
sum_pixel sum_pixel_inst_5(
	.a(sum_pixel_5_a),
	.b(sum_pixel_5_b),
	.sum(sum_pixel_5)
);
sum_pixel sum_pixel_inst_6(
	.a(sum_pixel_6_a),
	.b(sum_pixel_6_b),
	.sum(sum_pixel_6)
);
sum_pixel sum_pixel_inst_7(
	.a(sum_pixel_7_a),
	.b(sum_pixel_7_b),
	.sum(sum_pixel_7)
);
sum_pixel sum_pixel_inst_8(
	.a(sum_pixel_8_a),
	.b(sum_pixel_8_b),
	.sum(sum_pixel_8)
);
sum_pixel sum_pixel_inst_9(
	.a(sum_pixel_9_a),
	.b(sum_pixel_9_b),
	.sum(sum_pixel_9)
);
sum_pixel sum_pixel_inst_10(
	.a(sum_pixel_10_a),
	.b(sum_pixel_10_b),
	.sum(sum_pixel_10)
);
sum_pixel sum_pixel_inst_11(
	.a(sum_pixel_11_a),
	.b(sum_pixel_11_b),
	.sum(sum_pixel_11)
);
sum_pixel sum_pixel_inst_12(
	.a(sum_pixel_12_a),
	.b(sum_pixel_12_b),
	.sum(sum_pixel_12)
);
sum_pixel sum_pixel_inst_13(
	.a(sum_pixel_13_a),
	.b(sum_pixel_13_b),
	.sum(sum_pixel_13)
);
sum_pixel sum_pixel_inst_14(
	.a(sum_pixel_14_a),
	.b(sum_pixel_14_b),
	.sum(sum_pixel_14)
);
sum_pixel sum_pixel_inst_15(
	.a(sum_pixel_15_a),
	.b(sum_pixel_15_b),
	.sum(sum_pixel_15)
);

reg start;
reg prev_intra_residual_valid;

always @(posedge clk)
	prev_intra_residual_valid <= residual_valid && intra_pred_valid;

reg last_blk4x4_started;
always @(posedge clk)
if (blk4x4_counter == 23 && start)
	last_blk4x4_started <= 1'b1;
else if (blk4x4_counter == 0)
	last_blk4x4_started <= 1'b0;

always @(*) begin
	start <= 0;
	residual_out_ram_rd <= 0;
	inter_pred_out_ram_rd <= 0;
	if (state == Idle && ~last_blk4x4_started) begin
		if ( ~mb_pred_inter_sel && is_residual_not_dc &&
			residual_valid && intra_pred_valid && ~prev_intra_residual_valid) begin
			start <= 1;
		end
		else if ( mb_pred_mode == `mb_pred_mode_P_SKIP &&
				inter_pred_out_ram_wr_addr > blk4x4_counter) begin
			start <= 1;
			inter_pred_out_ram_rd <= 1'b1;
		end
		else if (mb_pred_inter_sel && 
			residual_out_ram_wr_addr > blk4x4_counter &&
			inter_pred_out_ram_wr_addr > blk4x4_counter)begin
			start <= 1;
			residual_out_ram_rd <= 1'b1;
			inter_pred_out_ram_rd <= 1'b1;
		end
	end
end


reg cur_mb_write_to_ram_done;
reg write_to_ram_idle_p;
reg [2:0] step;
assign write_to_ext_ram_last_mb_start = step[1];
always @(posedge clk) begin
	write_to_ram_idle_p <= write_to_ram_idle;
end

always @(posedge clk or negedge rst_n)
if (~rst_n) begin
	cur_mb_write_to_ram_done <= 0;
	step <= 0;
end
else if (start && blk4x4_counter == 23 && mb_index + 1 == total_mbs_one_frame) begin
	cur_mb_write_to_ram_done <= 0;
	step <= 1;
end
else if (step == 1 && write_to_ram_idle)begin
	step <= 2;
end
else if (step == 2) begin
	step <= 4;
end
else if (step == 4 && ~write_to_ram_idle_p && write_to_ram_idle)begin
	cur_mb_write_to_ram_done <= 1'b1;
	step <= 0;
end
wire [Log2MBsCacheWidth-1:0] mb_index_lower_bits_p1;
assign mb_index_lower_bits_p1 = mb_index[Log2MBsCacheWidth-1:0] + 1'b1;

always @(posedge clk or negedge rst_n)
if (~rst_n)
begin
	state <= 0;
	write_to_ram_start <= 0;
	valid_flag <= 0;
	valid <= 0;
end
else if (ena) begin
	case(state)
	Idle: begin
		valid <= 1'b0;
		valid_flag <= 1'b0;
		if (start) begin
			state <= Write;
			write_to_ram_start <= 1;
			if (blk4x4_counter < 23)begin
				valid <= 1'b1;
				valid_flag <= 1'b1;
			end
			else if (write_to_ram_idle && mb_index + 1 < total_mbs_one_frame) begin
				valid <= 1'b1;
				valid_flag <= 1'b1;
			end
		end
	end
	Write: begin
		write_to_ram_start <= 0;
		valid <= 1'b0;
		if (mb_index + 1 < total_mbs_one_frame && (
				mb_index_lower_bits_p1 != 0 ||
				mb_index_lower_bits_p1 == 0 && blk4x4_counter < 23 ||
				mb_index_lower_bits_p1 == 0 && blk4x4_counter == 23 && write_to_ram_idle) || 
			(mb_index + 1 == total_mbs_one_frame && ( 
				blk4x4_counter < 23 || 
				cur_mb_write_to_ram_done))
		) begin
			state <= Idle;
			if (~valid_flag)
				valid <= 1'b1;
		end
	end
	endcase
end


always @(posedge clk or negedge rst_n)
if (!rst_n) begin
	sum_0 <= 0;
	sum_1 <= 0;
	sum_2 <= 0;
	sum_3 <= 0;
	sum_4 <= 0;
	sum_5 <= 0;
	sum_6 <= 0;
	sum_7 <= 0;
	sum_8 <= 0;
	sum_9 <= 0;
	sum_10 <= 0;
	sum_11 <= 0;
	sum_12 <= 0;
	sum_13 <= 0;
	sum_14 <= 0;
	sum_15 <= 0;
end
else if (ena && start) begin
	sum_0 <= sum_pixel_0;
	sum_1 <= sum_pixel_1;
	sum_2 <= sum_pixel_2;
	sum_3 <= sum_pixel_3;
	sum_4 <= sum_pixel_4;
	sum_5 <= sum_pixel_5;
	sum_6 <= sum_pixel_6;
	sum_7 <= sum_pixel_7;
	sum_8 <= sum_pixel_8;
	sum_9 <= sum_pixel_9;
	sum_10 <= sum_pixel_10;
	sum_11 <= sum_pixel_11;		
	sum_12 <= sum_pixel_12;
	sum_13 <= sum_pixel_13;
	sum_14 <= sum_pixel_14;
	sum_15 <= sum_pixel_15;
end

always @(*)
if (mb_pred_mode == `mb_pred_mode_P_SKIP) begin
	sum_pixel_0_a <= 0;
	sum_pixel_1_a <= 0;
	sum_pixel_2_a <= 0;
	sum_pixel_3_a <= 0;
	sum_pixel_4_a <= 0;
	sum_pixel_5_a <= 0;
	sum_pixel_6_a <= 0;
	sum_pixel_7_a <= 0;	
	sum_pixel_8_a <= 0;
	sum_pixel_9_a <= 0;
	sum_pixel_10_a <= 0;
	sum_pixel_11_a <= 0;	
	sum_pixel_12_a <= 0;
	sum_pixel_13_a <= 0;
	sum_pixel_14_a <= 0;
	sum_pixel_15_a <= 0;
end
else begin
	sum_pixel_0_a  <= residual_0;
	sum_pixel_1_a  <= residual_1;
	sum_pixel_2_a  <= residual_2;
	sum_pixel_3_a  <= residual_3;
	sum_pixel_4_a  <= residual_4;
	sum_pixel_5_a  <= residual_5;
	sum_pixel_6_a  <= residual_6;
	sum_pixel_7_a  <= residual_7;	
	sum_pixel_8_a  <= residual_8;
	sum_pixel_9_a  <= residual_9;
	sum_pixel_10_a <= residual_10;
	sum_pixel_11_a <= residual_11;	
	sum_pixel_12_a <= residual_12;
	sum_pixel_13_a <= residual_13;
	sum_pixel_14_a <= residual_14;
	sum_pixel_15_a <= residual_15;
end

always @(*)
if (mb_pred_mode == `mb_pred_mode_PRED_L0 ||
    mb_pred_mode == `mb_pred_mode_P_REF0 ||
	mb_pred_mode == `mb_pred_mode_P_SKIP) begin
	sum_pixel_0_b <= inter_pred_0;
	sum_pixel_1_b <= inter_pred_1;
	sum_pixel_2_b <= inter_pred_2;
	sum_pixel_3_b <= inter_pred_3;
	sum_pixel_4_b <= inter_pred_4;
	sum_pixel_5_b <= inter_pred_5;
	sum_pixel_6_b <= inter_pred_6;
	sum_pixel_7_b <= inter_pred_7;	
	sum_pixel_8_b <= inter_pred_8;
	sum_pixel_9_b <= inter_pred_9;
	sum_pixel_10_b <= inter_pred_10;
	sum_pixel_11_b <= inter_pred_11;	
	sum_pixel_12_b <= inter_pred_12;
	sum_pixel_13_b <= inter_pred_13;
	sum_pixel_14_b <= inter_pred_14;
	sum_pixel_15_b <= inter_pred_15;
end
else begin
	sum_pixel_0_b  <= intra_pred_0;
	sum_pixel_1_b  <= intra_pred_1;
	sum_pixel_2_b  <= intra_pred_2;
	sum_pixel_3_b  <= intra_pred_3;
	sum_pixel_4_b  <= intra_pred_4;
	sum_pixel_5_b  <= intra_pred_5;
	sum_pixel_6_b  <= intra_pred_6;
	sum_pixel_7_b  <= intra_pred_7;	
	sum_pixel_8_b  <= intra_pred_8;
	sum_pixel_9_b  <= intra_pred_9;
	sum_pixel_10_b <= intra_pred_10;
	sum_pixel_11_b <= intra_pred_11;	
	sum_pixel_12_b <= intra_pred_12;
	sum_pixel_13_b <= intra_pred_13;
	sum_pixel_14_b <= intra_pred_14;
	sum_pixel_15_b <= intra_pred_15;
end


always @(*) begin
	sum_right_colum[7:0]  <= sum_3;
	sum_right_colum[15:8] <= sum_7;
	sum_right_colum[23:16] <= sum_11;
	sum_right_colum[31:24] <= sum_15;
end

always @(*) begin
	sum_bottom_row[7:0]  <= sum_12;
	sum_bottom_row[15:8] <= sum_13;
	sum_bottom_row[23:16] <= sum_14;
	sum_bottom_row[31:24] <= sum_15;
end

endmodule

module sum_pixel
(
	a,
	b,
	sum
);
input signed [8:0] a;
input [7:0] b;
output [7:0] sum;
reg [7:0] sum;

wire signed [9:0] c;
wire signed [8:0] b_signed;
 
assign b_signed = {1'b0,b};
assign c = a + b_signed;

always @(*)
	if (c[9:8] == 2'b00)
		sum = c[7:0];
	else if (c[9:8] == 2'b01)
		sum = 255;
	else
		sum = 0;
endmodule

