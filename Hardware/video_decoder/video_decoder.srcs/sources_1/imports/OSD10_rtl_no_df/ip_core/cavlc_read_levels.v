//CAVLC的全称是Context-Adaptive Varialbe-Length Coding，即基于上下文的自适应变长编码。
// CAVLC的本质是变长编码，它的特性主要体现在自适应能力上，CAVLC可以根据已编码句法元素的情况动态的选择编码中使用的码表，并且随时更新拖尾系数后缀的长度，从而获得极高的压缩比

// H.264/AVC视频编码标准中变元系数level值的解码过程:
// 根据尾零计数和变元总个数,初始化level寄存器数组。
// 根据码流流入,逐个解码level值,并写入对应寄存器。
// 解码level值时,会先解码level前缀,后缀值。
// 根据前缀后缀信息解码出实际的整数level值。
// 将解码出的level值绝对值保存,作为输出。

// 具体步骤:
// 识别码流中表示前缀和后缀的位数
// 读码流中对应位,拼接成前缀和后缀数字
// 根据前缀后缀值计算level实际整数值
// 根据指数信息还原为绝对值level
// 将解码出的level值先写入寄存器,再输出

// 解码出level序列,可以准确重建图像变元系数,进而还原图像像素,是实现视频解码的关键一步。
`include "defines.v"

module cavlc_read_levels (
  	input   clk,
	input   rst_n,
	
	input   ena,
	input   t1s_sel,
	input   prefix_sel,
	input   suffix_sel,
	input	calc_sel,
	
	input   [1:0]   TrailingOnes,
	input   [4:0]   TotalCoeff,
	input   [0:11]  rbsp,
	input   [3:0]   num_zero_bits,
	input   [3:0]   i,
	
	output reg [11:0]   level_0,
	output reg [11:0]   level_1,
	output reg [11:0]   level_2,
	output reg [11:0]   level_3,
	output reg [11:0]   level_4,
	output reg [11:0]   level_5,
	output reg [11:0]   level_6,
	output reg [11:0]   level_7,
	output reg [11:0]   level_8,
	output reg [11:0]   level_9,
	output reg [11:0]   level_10,
	output reg [11:0]   level_11,
	output reg [11:0]   level_12,
	output reg [11:0]   level_13,
	output reg [11:0]   level_14,
	output reg [11:0]   level_15,
	
	output reg [4:0]   len_comb
);

//------------------------
//  regs
//------------------------
reg     [3:0]   level_prefix_comb;
reg     [11:0]  level_suffix;

//------------------------
// FFs
//------------------------
reg     [3:0]    level_prefix;
reg     [2:0]    suffixLength;   // range from 0 to 6
reg     [11:0]   level;
reg     [11:0]   level_abs;
reg     [11:0]   level_code_tmp;

//------------------------
// level_prefix_comb
//------------------------
always @(*)
	level_prefix_comb <= num_zero_bits;

//------------------------
// level_prefix
//------------------------
always @(posedge clk or negedge rst_n)
if (!rst_n)
    level_prefix <= 0;
else if (prefix_sel && ena)
    level_prefix <= level_prefix_comb;

//------------------------
// suffixLength
//------------------------
wire first_level;
assign first_level = (i == TotalCoeff - TrailingOnes - 1);
reg [7:0] mult;

always @(*)
if (suffixLength == 0)
	mult = 1;
else if (suffixLength == 1)
	mult = 2;
else if (suffixLength == 2)
	mult = 4;
else if (suffixLength == 3)
	mult = 8;
else if (suffixLength == 4)
	mult = 16;
else if (suffixLength == 5)
	mult = 32;
else if (suffixLength == 6)
	mult = 64;
else //suffixLength == 7
	mult = 128;



always @(posedge clk or negedge rst_n)
if (!rst_n)
    suffixLength <= 0;
else if (prefix_sel && ena) begin
    if (TotalCoeff > 10 && TrailingOnes < 3 && first_level )  //initialize suffixLength before proceeding first level_suffix
        suffixLength <= 1;
    else if (first_level)
        suffixLength <= 0;
    else if (suffixLength == 0 && level_abs > 2'd3)
        suffixLength <= 2;
    else if (suffixLength == 0)
        suffixLength <= 1;
    else if (  level_abs > 3*mult/2 && suffixLength < 6)
        suffixLength <= suffixLength + 1'b1;
end


//------------------------
// level_suffix
//------------------------
wire level_suffix_refresh;
assign level_suffix_refresh = suffix_sel && ena;
reg[5:0] read_bits_out;
always @(*)
case ( suffixLength )
1 : read_bits_out <= rbsp[0:0];
2 : read_bits_out <= rbsp[0:1];
3 : read_bits_out <= rbsp[0:2];
4 : read_bits_out <= rbsp[0:3];
5 : read_bits_out <= rbsp[0:4];
6 : read_bits_out <= rbsp[0:5];
default: read_bits_out <= 0;
endcase


always @(*)
if (level_suffix_refresh) begin
	if (suffixLength > 0 && level_prefix <= 14) begin
		level_suffix <= read_bits_out;
	end
	else if (level_prefix == 14) begin	//level_prefix == 14 && suffixLength == 0
		level_suffix <= rbsp[0:3];
	end
	else if (level_prefix == 15) begin
		level_suffix <= rbsp[0:11];	    
	end
	else begin
		level_suffix <= 0;	    
	end		
end     
else begin
	level_suffix <= 0;	    
end

//------------------------
// level_code_tmp
//------------------------
always @(posedge clk or negedge rst_n)
if (~rst_n) begin
	level_code_tmp <=  0;
end
else if (level_suffix_refresh) begin
    level_code_tmp <= (level_prefix * mult) + level_suffix + 
    ((suffixLength == 0 && level_prefix == 15) ? 4'd15 : 0);
end


//------------------------
// level
//------------------------
wire    [1:0]   tmp1;

assign tmp1 = (first_level && TrailingOnes < 3)? 2'd2 : 2'd0;

always @(*)
begin
    if (level_code_tmp % 2 == 0) begin
        level <= ( level_code_tmp + tmp1 + 2 ) >> 1;
    end
    else begin
        level <= (-level_code_tmp - tmp1 - 1 ) >> 1;
    end
end

//------------------------
// level_abs
//------------------------
wire level_abs_refresh;
assign level_abs_refresh = calc_sel && ena;

always @(posedge clk or negedge rst_n)
if (!rst_n) begin
    level_abs <= 0;
end
else if (level_abs_refresh) begin
    level_abs <= level[11] ? -level : level;
end

//------------------------
// level regfile
//------------------------
always @ (posedge clk or negedge rst_n)
if (!rst_n) begin
    level_0 <= 0;   level_1 <= 0;   level_2 <= 0;   level_3 <= 0;
    level_4 <= 0;   level_5 <= 0;   level_6 <= 0;   level_7 <= 0;
    level_8 <= 0;   level_9 <= 0;   level_10<= 0;   level_11<= 0;
    level_12<= 0;   level_13<= 0;   level_14<= 0;   level_15<= 0;
end
else if (t1s_sel && ena)
    case (i)
    0 : level_0 <= rbsp[0]? -1 : 1;
    1 : begin
            level_1 <= rbsp[0]? -1 : 1;
            if (TrailingOnes[1])
                level_0 <= rbsp[1]? -1 : 1;
        end
    2 : begin
            level_2 <= rbsp[0]? -1 : 1;
            if (TrailingOnes[1])
                level_1 <= rbsp[1]? -1 : 1;
            if (TrailingOnes == 3)
                level_0 <= rbsp[2]? -1 : 1;
        end         
    3 : begin
            level_3 <= rbsp[0]? -1 : 1;
            if (TrailingOnes[1])
                level_2 <= rbsp[1]? -1 : 1;
            if (TrailingOnes == 3)
                level_1 <= rbsp[2]? -1 : 1;
        end 
    4 : begin
            level_4 <= rbsp[0]? -1 : 1;
            if (TrailingOnes[1])
                level_3 <= rbsp[1]? -1 : 1;
            if (TrailingOnes == 3)
                level_2 <= rbsp[2]? -1 : 1;
        end 
    5 : begin
            level_5 <= rbsp[0]? -1 : 1;
            if (TrailingOnes[1])
                level_4 <= rbsp[1]? -1 : 1;
            if (TrailingOnes == 3)
                level_3 <= rbsp[2]? -1 : 1;
        end 
    6 : begin
            level_6 <= rbsp[0]? -1 : 1;
            if (TrailingOnes[1])
                level_5 <= rbsp[1]? -1 : 1;
            if (TrailingOnes == 3)
                level_4 <= rbsp[2]? -1 : 1;
        end 
    7 : begin
            level_7 <= rbsp[0]? -1 : 1;
            if (TrailingOnes[1])
                level_6 <= rbsp[1]? -1 : 1;
            if (TrailingOnes == 3)
                level_5 <= rbsp[2]? -1 : 1;
        end 
    8 : begin
            level_8 <= rbsp[0]? -1 : 1;
            if (TrailingOnes[1])
                level_7 <= rbsp[1]? -1 : 1;
            if (TrailingOnes == 3)
                level_6 <= rbsp[2]? -1 : 1;
        end 
    9 : begin
            level_9 <= rbsp[0]? -1 : 1;
            if (TrailingOnes[1])
                level_8 <= rbsp[1]? -1 : 1;
            if (TrailingOnes == 3)
                level_7 <= rbsp[2]? -1 : 1;
        end 
    10: begin
            level_10 <= rbsp[0]? -1 : 1;
            if (TrailingOnes[1])
                level_9 <= rbsp[1]? -1 : 1;
            if (TrailingOnes == 3)
                level_8 <= rbsp[2]? -1 : 1;
        end 
    11: begin
            level_11 <= rbsp[0]? -1 : 1;
            if (TrailingOnes[1])
                level_10 <= rbsp[1]? -1 : 1;
            if (TrailingOnes == 3)
                level_9 <= rbsp[2]? -1 : 1;
        end 
    12: begin
            level_12 <= rbsp[0]? -1 : 1;
            if (TrailingOnes[1])
                level_11 <= rbsp[1]? -1 : 1;
            if (TrailingOnes == 3)
                level_10 <= rbsp[2]? -1 : 1;
        end 
    13: begin
            level_13 <= rbsp[0]? -1 : 1;
            if (TrailingOnes[1])
                level_12 <= rbsp[1]? -1 : 1;
            if (TrailingOnes == 3)
                level_11 <= rbsp[2]? -1 : 1;
        end 
    14: begin
            level_14 <= rbsp[0]? -1 : 1;
            if (TrailingOnes[1])
                level_13 <= rbsp[1]? -1 : 1;
            if (TrailingOnes == 3)
                level_12 <= rbsp[2]? -1 : 1;
        end 
    15: begin
            level_15 <= rbsp[0]? -1 : 1;
            if (TrailingOnes[1])
                level_14 <= rbsp[1]? -1 : 1;
            if (TrailingOnes == 3)
                level_13 <= rbsp[2]? -1 : 1;
        end 
endcase
else if (calc_sel && ena)
case (i)
    0 :level_0 <= level;
    1 :level_1 <= level;
    2 :level_2 <= level;
    3 :level_3 <= level;
    4 :level_4 <= level;
    5 :level_5 <= level;
    6 :level_6 <= level;
    7 :level_7 <= level;
    8 :level_8 <= level;
    9 :level_9 <= level;
    10:level_10<= level;
    11:level_11<= level;
    12:level_12<= level;
    13:level_13<= level;
    14:level_14<= level;
    15:level_15<= level;
endcase

always @(*)
if(t1s_sel)
    len_comb <= TrailingOnes;
else if(prefix_sel)
    len_comb <= level_prefix_comb + 1;
else if(suffix_sel && suffixLength > 0 && level_prefix <= 14)
    len_comb <= suffixLength;  
else if(suffix_sel && level_prefix == 14)
    len_comb <= 4;
else if(suffix_sel && level_prefix == 15)
    len_comb <= 12;
else
    len_comb <= 0;        

endmodule
