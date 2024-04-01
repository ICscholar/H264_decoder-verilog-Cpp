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
//2011-8-16 initiial revision
module transform_inverse_quant(
	input clk,
	input rst_n,
	input ena,
	input [5:0] QP,
	input [3:0] residual_state,

	input signed [15:0]	curr_DC,
	input signed [11:0]	p_in_0,
	input signed [11:0]	p_in_1,
	input signed [11:0]	p_in_2,
	input signed [11:0]	p_in_3,
	input signed [11:0]	p_in_4,
	input signed [11:0]	p_in_5,
	input signed [11:0]	p_in_6,
	input signed [11:0]	p_in_7,
	input signed [11:0]	p_in_8,
	input signed [11:0]	p_in_9,
	input signed [11:0]	p_in_10,
	input signed [11:0]	p_in_11,
	input signed [11:0]	p_in_12,
	input signed [11:0]	p_in_13,
	input signed [11:0]	p_in_14,
	input signed [11:0]	p_in_15,

	output reg [15:0] p_out_0,
	output reg [15:0] p_out_1,
	output reg [15:0] p_out_2,
	output reg [15:0] p_out_3,
	output reg [15:0] p_out_4,
	output reg [15:0] p_out_5,
	output reg [15:0] p_out_6,
	output reg [15:0] p_out_7,
	output reg [15:0] p_out_8,
	output reg [15:0] p_out_9,
	output reg [15:0] p_out_10,
	output reg [15:0] p_out_11,
	output reg [15:0] p_out_12,
	output reg [15:0] p_out_13,
	output reg [15:0] p_out_14,
	output reg [15:0] p_out_15
);	


reg [5:0] dequant_ram_wr_addr;
reg [5:0] dequant_ram_rd_addr;
reg dequant_ram_wr;
reg [38:0] dequant_ram_data_in;
wire[38:0] dequant_ram_data_out;
reg dequant_ram_init_started;
reg dequant_ram_init_done;
reg [3:0] dequant_ram_div6;
reg [2:0] dequant_ram_rem6;

reg signed [13:0] dequant_coeff0;
reg signed [13:0] dequant_coeff1;
reg signed [13:0] dequant_coeff2;
reg signed [13:0] dequant_coeff3;
reg signed [13:0] dequant_coeff4;
reg signed [13:0] dequant_coeff5;
reg signed [13:0] dequant_coeff6;
reg signed [13:0] dequant_coeff7;
reg signed [13:0] dequant_coeff8;
reg signed [13:0] dequant_coeff9;
reg signed [13:0] dequant_coeff10;
reg signed [13:0] dequant_coeff11;
reg signed [13:0] dequant_coeff12;
reg signed [13:0] dequant_coeff13;
reg signed [13:0] dequant_coeff14;
reg signed [13:0] dequant_coeff15;

dequant_coeff_ram dequant_coeff_ram_inst(
	.clk(clk),
	.wr(dequant_ram_wr),
	.wr_addr(dequant_ram_wr_addr),
	.rd_addr(dequant_ram_rd_addr),
    .data_in(dequant_ram_data_in),
    .data_out(dequant_ram_data_out)
);

always @(posedge clk or negedge rst_n)
if (~rst_n) begin
	dequant_coeff0 <= 0;
	dequant_coeff1 <= 0;
	dequant_coeff2 <= 0; 
	dequant_coeff3 <= 0; 
	dequant_coeff4 <= 0; 
	dequant_coeff5 <= 0; 
	dequant_coeff6 <= 0; 
	dequant_coeff7 <= 0; 
	dequant_coeff8 <= 0; 
	dequant_coeff9 <= 0; 
	dequant_coeff10 <= 0;
	dequant_coeff11 <= 0;	
	dequant_coeff12 <= 0;
	dequant_coeff13 <= 0;
	dequant_coeff14 <= 0;
	dequant_coeff15 <= 0;
end
else if (ena)begin
	if (residual_state == `Intra16x16DCLevel_s || 
		residual_state == `ChromaDCLevel_Cb_s  ||
		residual_state == `ChromaDCLevel_Cr_s) begin
		dequant_coeff0 <= {1'b0,dequant_ram_data_out[12:0]};
		dequant_coeff1 <= {1'b0,dequant_ram_data_out[12:0]};
		dequant_coeff2 <= {1'b0,dequant_ram_data_out[12:0]};
		dequant_coeff3 <= {1'b0,dequant_ram_data_out[12:0]};
		dequant_coeff4 <= {1'b0,dequant_ram_data_out[12:0]};
		dequant_coeff5 <= {1'b0,dequant_ram_data_out[12:0]};
		dequant_coeff6 <= {1'b0,dequant_ram_data_out[12:0]};
		dequant_coeff7 <= {1'b0,dequant_ram_data_out[12:0]};
		dequant_coeff8 <= {1'b0,dequant_ram_data_out[12:0]};
		dequant_coeff9 <= {1'b0,dequant_ram_data_out[12:0]};
		dequant_coeff10 <= {1'b0,dequant_ram_data_out[12:0]};
		dequant_coeff11 <= {1'b0,dequant_ram_data_out[12:0]};	
		dequant_coeff12 <= {1'b0,dequant_ram_data_out[12:0]};
		dequant_coeff13 <= {1'b0,dequant_ram_data_out[12:0]};
		dequant_coeff14 <= {1'b0,dequant_ram_data_out[12:0]};
		dequant_coeff15 <= {1'b0,dequant_ram_data_out[12:0]};
	end
	else begin
		dequant_coeff0 <= {1'b0,dequant_ram_data_out[12:0]};
		dequant_coeff1 <= {1'b0,dequant_ram_data_out[25:13]};
		dequant_coeff2 <= {1'b0,dequant_ram_data_out[12:0]};
		dequant_coeff3 <= {1'b0,dequant_ram_data_out[25:13]};
		dequant_coeff4 <= {1'b0,dequant_ram_data_out[25:13]};
		dequant_coeff5 <= {1'b0,dequant_ram_data_out[38:26]};
		dequant_coeff6 <= {1'b0,dequant_ram_data_out[25:13]};
		dequant_coeff7 <= {1'b0,dequant_ram_data_out[38:26]};
		dequant_coeff8 <= {1'b0,dequant_ram_data_out[12:0]};
		dequant_coeff9 <= {1'b0,dequant_ram_data_out[25:13]};
		dequant_coeff10 <= {1'b0,dequant_ram_data_out[12:0]};
		dequant_coeff11 <= {1'b0,dequant_ram_data_out[25:13]};	
		dequant_coeff12 <= {1'b0,dequant_ram_data_out[25:13]};
		dequant_coeff13 <= {1'b0,dequant_ram_data_out[38:26]};
		dequant_coeff14 <= {1'b0,dequant_ram_data_out[25:13]};
		dequant_coeff15 <= {1'b0,dequant_ram_data_out[38:26]};	
	end
end

always @(*)
	dequant_ram_rd_addr <= QP;

always @(posedge clk or negedge rst_n)
if(~rst_n) begin
	dequant_ram_wr_addr <= 0;
	dequant_ram_wr <= 0;
	dequant_ram_data_in <= 0;
	dequant_ram_init_started <= 0;
	dequant_ram_init_done <= 0;
	dequant_ram_div6 <= 0;
	dequant_ram_rem6 <= 0;
end
else if (~dequant_ram_init_done && ~dequant_ram_init_started)begin
	dequant_ram_init_started <= 1;
	dequant_ram_div6 <= 0;
	dequant_ram_rem6 <= 0;
end
else if (dequant_ram_init_started) begin
	if (dequant_ram_wr) begin
		dequant_ram_wr_addr <= dequant_ram_wr_addr + 1'b1;
	end
	if (dequant_ram_rem6 < 5) begin
		dequant_ram_rem6 <= dequant_ram_rem6 + 1'b1;
	end
	else begin
		dequant_ram_rem6 <= 0;
		dequant_ram_div6 <= dequant_ram_div6 + 1'b1;
	end
	dequant_ram_wr <= 1'b1;
	if (dequant_ram_wr_addr == 51) begin
		dequant_ram_init_done <= 1'b1;
		dequant_ram_init_started <= 1'b0;
		dequant_ram_wr <= 1'b0;
	end
	case (dequant_ram_rem6)
	0: begin
		dequant_ram_data_in[12:0] <= 5'd10 << dequant_ram_div6;
		dequant_ram_data_in[25:13] <= 5'd13 << dequant_ram_div6;
		dequant_ram_data_in[38:26] <= 5'd16 << dequant_ram_div6;
	end
	1: begin
		dequant_ram_data_in[12:0] <= 5'd11 << dequant_ram_div6;
		dequant_ram_data_in[25:13] <= 5'd14 << dequant_ram_div6;
		dequant_ram_data_in[38:26] <= 5'd18 << dequant_ram_div6;
	end
	2: begin
		dequant_ram_data_in[12:0] <= 5'd13 << dequant_ram_div6;
		dequant_ram_data_in[25:13] <= 5'd16 << dequant_ram_div6;
		dequant_ram_data_in[38:26] <= 5'd20 << dequant_ram_div6;
	end
	3: begin
		dequant_ram_data_in[12:0] <= 5'd14 << dequant_ram_div6;
		dequant_ram_data_in[25:13] <= 5'd18 << dequant_ram_div6;
		dequant_ram_data_in[38:26] <= 5'd23 << dequant_ram_div6;
	end
	4: begin
		dequant_ram_data_in[12:0] <= 5'd16 << dequant_ram_div6;
		dequant_ram_data_in[25:13] <= 5'd20 << dequant_ram_div6;
		dequant_ram_data_in[38:26] <= 5'd25 << dequant_ram_div6;
	end
	default: begin //5
		dequant_ram_data_in[12:0] <= 5'd18 << dequant_ram_div6;
		dequant_ram_data_in[25:13] <= 5'd23 << dequant_ram_div6;
		dequant_ram_data_in[38:26] <= 5'd29 << dequant_ram_div6;
	end
	endcase
end

// cavlc_coeff:12 bits signed, dequant_coeff 13 bits signed 
parameter 
MultResultBits = 11+12+1;
reg signed [MultResultBits - 1:0] mult_result0;
reg signed [MultResultBits - 1:0] mult_result1;
reg signed [MultResultBits - 1:0] mult_result2;
reg signed [MultResultBits - 1:0] mult_result3;
reg signed [MultResultBits - 1:0] mult_result4;
reg signed [MultResultBits - 1:0] mult_result5;
reg signed [MultResultBits - 1:0] mult_result6;
reg signed [MultResultBits - 1:0] mult_result7;
reg signed [MultResultBits - 1:0] mult_result8;
reg signed [MultResultBits - 1:0] mult_result9;
reg signed [MultResultBits - 1:0] mult_result10;
reg signed [MultResultBits - 1:0] mult_result11;
reg signed [MultResultBits - 1:0] mult_result12;
reg signed [MultResultBits - 1:0] mult_result13;
reg signed [MultResultBits - 1:0] mult_result14;
reg signed [MultResultBits - 1:0] mult_result15;

always @(posedge clk ) 
begin
	mult_result0 <= p_in_0 * dequant_coeff0;
	mult_result1 <= p_in_1 * dequant_coeff1;
	mult_result2 <= p_in_2 * dequant_coeff2;
	mult_result3 <= p_in_3 * dequant_coeff3;
	mult_result4 <= p_in_4 * dequant_coeff4;
	mult_result5 <= p_in_5 * dequant_coeff5;
	mult_result6 <= p_in_6 * dequant_coeff6;
	mult_result7 <= p_in_7 * dequant_coeff7;
	mult_result8 <= p_in_8 * dequant_coeff8;
	mult_result9 <= p_in_9 * dequant_coeff9;
	mult_result10 <= p_in_10 * dequant_coeff10;
	mult_result11 <= p_in_11 * dequant_coeff11;
	mult_result12 <= p_in_12 * dequant_coeff12;
	mult_result13 <= p_in_13 * dequant_coeff13;
	mult_result14 <= p_in_14 * dequant_coeff14;
	mult_result15 <= p_in_15 * dequant_coeff15;
end

always @(*)
if (residual_state == `Intra16x16DCLevel_s) begin
	p_out_0  = (mult_result0  + 2) >>> 2;
	p_out_1  = (mult_result1  + 2) >>> 2;
	p_out_2  = (mult_result2  + 2) >>> 2;
	p_out_3  = (mult_result3  + 2) >>> 2;
	p_out_4  = (mult_result4  + 2) >>> 2;
	p_out_5  = (mult_result5  + 2) >>> 2;
	p_out_6  = (mult_result6  + 2) >>> 2;
	p_out_7  = (mult_result7  + 2) >>> 2;
	p_out_8  = (mult_result8  + 2) >>> 2;
	p_out_9  = (mult_result9  + 2) >>> 2;
	p_out_10 = (mult_result10 + 2) >>> 2;
	p_out_11 = (mult_result11 + 2) >>> 2;
	p_out_12 = (mult_result12 + 2) >>> 2;
	p_out_13 = (mult_result13 + 2) >>> 2;
	p_out_14 = (mult_result14 + 2) >>> 2;
	p_out_15 = (mult_result15 + 2) >>> 2;
end
else if (residual_state == `ChromaDCLevel_Cb_s ||
		 residual_state == `ChromaDCLevel_Cr_s) begin
	p_out_0  = (mult_result0 ) >>> 1;
	p_out_1  = (mult_result1 ) >>> 1;
	p_out_2  = (mult_result2 ) >>> 1;
	p_out_3  = (mult_result3 ) >>> 1;
	p_out_4 = mult_result4;
	p_out_5 = mult_result5;
	p_out_6 = mult_result6;
	p_out_7 = mult_result7;
	p_out_8 = mult_result8;
	p_out_9 = mult_result9;
	p_out_10 = mult_result10;
	p_out_11 = mult_result11;
	p_out_12 = mult_result12;
	p_out_13 = mult_result13;
	p_out_14 = mult_result14;
	p_out_15 = mult_result15;
end
else if(residual_state == `LumaLevel_s)begin
	p_out_0 = mult_result0;
	p_out_1 = mult_result1;
	p_out_2 = mult_result2;
	p_out_3 = mult_result3;
	p_out_4 = mult_result4;
	p_out_5 = mult_result5;
	p_out_6 = mult_result6;
	p_out_7 = mult_result7;
	p_out_8 = mult_result8;
	p_out_9 = mult_result9;
	p_out_10 = mult_result10;
	p_out_11 = mult_result11;
	p_out_12 = mult_result12;
	p_out_13 = mult_result13;
	p_out_14 = mult_result14;
	p_out_15 = mult_result15;
end
else begin
	p_out_0 = curr_DC;
	p_out_1 = mult_result1;
	p_out_2 = mult_result2;
	p_out_3 = mult_result3;
	p_out_4 = mult_result4;
	p_out_5 = mult_result5;
	p_out_6 = mult_result6;
	p_out_7 = mult_result7;
	p_out_8 = mult_result8;
	p_out_9 = mult_result9;
	p_out_10 = mult_result10;
	p_out_11 = mult_result11;
	p_out_12 = mult_result12;
	p_out_13 = mult_result13;
	p_out_14 = mult_result14;
	p_out_15 = mult_result15;
end
endmodule

module dequant_coeff_ram
(
	clk,
	wr,
	wr_addr,
	rd_addr,
    data_in,
    data_out
);
parameter addr_bits = 6;
parameter data_bits = 39;
input     clk;
input     wr;
input     [addr_bits-1:0]  wr_addr;
input     [addr_bits-1:0]  rd_addr;
input     [data_bits-1:0]  data_in;
output    [data_bits-1:0]  data_out;
	
reg       [data_bits-1:0]  ram[0:(1 << addr_bits) -1];
reg       [data_bits-1:0]  data_out;

//read
always @ ( posedge clk )
begin
    data_out <= ram[rd_addr];
end 

//write
always @ (posedge clk)
begin
    if (wr)
        ram[wr_addr] <= data_in;
end

endmodule

