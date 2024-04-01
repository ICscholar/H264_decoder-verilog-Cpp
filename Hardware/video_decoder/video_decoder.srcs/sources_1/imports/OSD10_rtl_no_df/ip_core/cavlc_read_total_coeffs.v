// 实现了从H.264标准定义的变元系数提取码流格式,通过串行逻辑统一读取其中编码的信息:
// 主要功能包括:
// 1.根据变元块中非零系数个数nC的值,选择对应的变元系数提取方式。
// 2.根据nC不同范围,将输入码流分配到不同寄存器rbsp_1/2/3/4/5中。
// 3.对不同nC范围,利用不同算法从码流中提取尾零计数和总系数个数。
// 4.根据nC值选择对应输出。

// 具体实现:
// 定义了输出和暂存寄存器保存结果
// 根据nC将码流分配
// 对不同nC范围,通过串行逻辑统一从码流中读取尾零计数和总系数个数
// 输出结果通过组合逻辑输出
// 同步存储输出结果
// 其中,对不同nC范围都采用了类似串连加权决策树的方式,通过轮流判断码流比特位,逐步推导出尾零计数和总系数个数

//推导出尾零计数和总系数个数在视频编码标准如H.264中的重要意义:
// 帮助解码器高效还原变元系数序列。只需按尾零计数插入0,然后填充总个数即可
// 作为失真累计的参考,有助于控制失真水平不超标

//尾零计数 tail zeros
//在计算机科学中，尾零指的是数字表示中从右边数最后一个非零位之后连续出现的零的个数。 例如，二进制数字10100的尾零为2，因为它从右侧第三位开始有两个连续的零。
// 尾零计数在编码过程中可以起到进一步压缩信息量的作用:
// 如果尾零计数很长(比如全0系数),可以用更短的码表示
// 尾零计数越长,表示变元序列特征越稳定,可以利用这个统计信息进一步提升压缩率
// 在解码时,尾零计数可以帮助快速还原变元系数序列。它提供了变元高频部分的重要前缀信息。
`include "defines.v"

module cavlc_read_total_coeffs
(
    clk,
    rst_n,
    ena,
    start,
    sel,
    rbsp, nC,
    TrailingOnes,
    TotalCoeff,
    TrailingOnes_comb,
    TotalCoeff_comb,
    len_comb
);
//------------------------
//ports
//------------------------
input   clk;
input   rst_n;
input   ena;
input   start;
input   sel;

input   [0:15]   rbsp;
input   signed   [5:0]   nC;

output  [4:0]  TotalCoeff;        //range from 0 to 16
output  [1:0]  TrailingOnes;      //range from 0 to 3   ,变元块的尾零计数值。
output  [4:0]  TotalCoeff_comb;   //unsaved result of TotalCoeff_comb
output  [1:0]  TrailingOnes_comb; //unsaved result of TrailingOnes_comb
output  [4:0]  len_comb;          //indicate how many rbsp bit consumed, range from 0 to 16


//------------------------
//regs
//------------------------
reg     [4:0]   TotalCoeff_comb;
reg     [1:0]   TrailingOnes_comb;
reg     [4:0]   len_comb;

//for nC >= 0 && nC < 2
reg     [4:0]   TotalCoeff_1;
reg     [1:0]   TrailingOnes_1;
reg     [4:0]   len_1;

//for nC >= 2 && nC < 4
reg     [4:0]   TotalCoeff_2;
reg     [1:0]   TrailingOnes_2;
reg     [4:0]   len_2;

//for nC >= 4 && nC < 8
reg     [4:0]   TotalCoeff_3;
reg     [1:0]   TrailingOnes_3;
reg     [4:0]   len_3;

//for nC >= 8
reg     [4:0]   TotalCoeff_4;
reg     [1:0]   TrailingOnes_4;
reg     [4:0]   len_4;

//for nC == -1
reg     [4:0]   TotalCoeff_5;
reg     [1:0]   TrailingOnes_5;
reg     [4:0]   len_5;


//------------------------
//FFs
//------------------------
//len is not necessary to be saved
//TotalCoeff & TrailingOnes should be valid when cavlc_state == `cavlc_read_total_coeffs_s
//to do that,combinational result "TotalCoeff_comb & TrailingOnes_comb" are outputed
reg     [0:15]  rbsp_1;         
reg     [0:13]  rbsp_2;
reg     [0:9]   rbsp_3;
reg     [0:5]   rbsp_4;
reg     [0:7]   rbsp_5;

reg     [4:0]   TotalCoeff;
reg     [1:0]   TrailingOnes;

//------------------------
//input mux
//------------------------
always @(posedge clk or negedge rst_n)
if (!rst_n)
begin
        rbsp_1 <=  0;
        rbsp_2 <=  0;
        rbsp_3 <=  0;
        rbsp_4 <=  0;
        rbsp_5 <=  0;

end
else if (ena && start)
begin
    if (nC[5])
        rbsp_5 <=  rbsp[0:7];
    else if ( nC[4] || nC[3])
        rbsp_4 <= rbsp[0:5];
    else if (nC[2])
        rbsp_3 <= rbsp[0:9];
    else if (nC[1])
        rbsp_2 <= rbsp[0:13];
    else
        rbsp_1 <= rbsp;
end
//------------------------
//nC >= 0 && nC < 2                 
//------------------------
always @(rbsp_1)
case (1'b1) 
rbsp_1[0] : begin
    TrailingOnes_1  <= 0;
    TotalCoeff_1    <= 0;
    len_1           <= 1;
end
rbsp_1[1] : begin
    TrailingOnes_1  <= 1;
    TotalCoeff_1    <= 1;
    len_1           <= 2;
end
rbsp_1[2] : begin
    TrailingOnes_1  <= 2;
    TotalCoeff_1    <= 2;
    len_1           <= 3;
end
rbsp_1[3] : begin
    if (rbsp_1[4] == 'b1) begin
        TrailingOnes_1  <= 3;
        TotalCoeff_1    <= 3;
        len_1           <= 5;
    end
    else if (rbsp_1[5] == 'b1) begin
        TrailingOnes_1  <= 0;
        TotalCoeff_1    <= 1;
        len_1           <= 6;
    end
    else begin
        TrailingOnes_1  <= 1;
        TotalCoeff_1    <= 2;
        len_1           <= 6;
    end
end
rbsp_1[4] : begin
    if (rbsp_1[5] == 'b1) begin
        TrailingOnes_1  <= 3;
        TotalCoeff_1    <= 4;
        len_1           <= 6;
    end
    else if (rbsp_1[6] == 'b1) begin
        TrailingOnes_1  <= 2;
        TotalCoeff_1    <= 3;
        len_1           <= 7;
    end
    else begin
        TrailingOnes_1  <= 3;
        TotalCoeff_1    <= 5;
        len_1           <= 7;
    end
end
rbsp_1[5] : begin
    len_1           <= 8;
    if (rbsp_1[6:7] == 'b11) begin
        TrailingOnes_1  <= 0;
        TotalCoeff_1    <= 2;
    end
    else if (rbsp_1[6:7] == 'b10) begin
        TrailingOnes_1  <= 1;
        TotalCoeff_1    <= 3;
    end
    else if (rbsp_1[6:7] == 'b01) begin
        TrailingOnes_1  <= 2;
        TotalCoeff_1    <= 4;
    end
    else begin
        TrailingOnes_1  <= 3;
        TotalCoeff_1    <= 6;
    end
end
rbsp_1[6] : begin
    len_1           <= 9;
    if (rbsp_1[7:8] == 2'b11) begin
        TrailingOnes_1  <= 0;
        TotalCoeff_1    <= 3;
    end
    else if (rbsp_1[7:8] == 2'b10) begin
        TrailingOnes_1  <= 1;
        TotalCoeff_1    <= 4;
    end
    else if (rbsp_1[7:8] == 2'b01) begin
        TrailingOnes_1  <= 2;
        TotalCoeff_1    <= 5;
    end
    else  begin
        TrailingOnes_1  <= 3;
        TotalCoeff_1    <= 7;
    end
end
rbsp_1[7] : begin
    len_1           <= 10;
    if (rbsp_1[8:9] == 2'b11) begin
        TrailingOnes_1  <= 0;
        TotalCoeff_1    <= 4;
    end
    else if (rbsp_1[8:9] == 2'b10) begin
        TrailingOnes_1  <= 1;
        TotalCoeff_1    <= 5;
    end
    else if (rbsp_1[8:9] == 2'b01) begin
        TrailingOnes_1  <= 2;
        TotalCoeff_1    <= 6;
    end
    else begin
        TrailingOnes_1  <= 3;
        TotalCoeff_1    <= 8;
    end
end
rbsp_1[8] : begin
    len_1           <= 11;
    if (rbsp_1[9:10] == 2'b11) begin
        TrailingOnes_1  <= 0;
        TotalCoeff_1    <= 5;
    end
    else if (rbsp_1[9:10] == 2'b10) begin
        TrailingOnes_1  <= 1;
        TotalCoeff_1    <= 6;
    end
    else if (rbsp_1[9:10] == 2'b01) begin
        TrailingOnes_1  <= 2;
        TotalCoeff_1    <= 7;
    end
    else begin
        TrailingOnes_1  <= 3;
        TotalCoeff_1    <= 9;
    end
end
rbsp_1[9] : begin
    len_1           <= 13;
    if (rbsp_1[10:12] == 3'b111) begin
        TrailingOnes_1  <= 0;
        TotalCoeff_1    <= 6;
    end
    else if (rbsp_1[10:12] == 3'b011) begin
        TrailingOnes_1  <= 0;
        TotalCoeff_1    <= 7;
    end
    else if (rbsp_1[10:12] == 3'b110) begin
        TrailingOnes_1  <= 1;
        TotalCoeff_1    <= 7;
    end
    else if (rbsp_1[10:12] == 3'b000) begin
        TrailingOnes_1  <= 0;
        TotalCoeff_1    <= 8;
    end
    else if (rbsp_1[10:12] == 3'b010) begin
        TrailingOnes_1  <= 1;
        TotalCoeff_1    <= 8;
    end
    else if (rbsp_1[10:12] == 3'b101) begin
        TrailingOnes_1  <= 2;
        TotalCoeff_1    <= 8;
    end
    else if (rbsp_1[10:12] == 3'b001) begin
        TrailingOnes_1  <= 2;
        TotalCoeff_1    <= 9;
    end
    else begin
        TrailingOnes_1  <= 3;
        TotalCoeff_1    <= 10;
    end
end
rbsp_1[10] : begin
    len_1           <= 14;
    if (rbsp_1[11:13] == 3'b111) begin
        TrailingOnes_1  <= 0;
        TotalCoeff_1    <= 9;
    end
    else if (rbsp_1[11:13] == 3'b110) begin
        TrailingOnes_1  <= 1;
        TotalCoeff_1    <= 9;
    end
    else if (rbsp_1[11:13] == 3'b011) begin
        TrailingOnes_1  <= 0;
        TotalCoeff_1    <= 10;
    end
    else if (rbsp_1[11:13] == 3'b010) begin
        TrailingOnes_1  <= 1;
        TotalCoeff_1    <= 10;
    end
    else if (rbsp_1[11:13] == 3'b101) begin
        TrailingOnes_1  <= 2;
        TotalCoeff_1    <= 10;
    end
    else if (rbsp_1[11:13] == 3'b001) begin
        TrailingOnes_1  <= 2;
        TotalCoeff_1    <= 11;
    end
    else if (rbsp_1[11:13] == 3'b100) begin
        TrailingOnes_1  <= 3;
        TotalCoeff_1    <= 11;
    end
    else begin
        TrailingOnes_1  <= 3;
        TotalCoeff_1    <= 12;
    end
end
rbsp_1[11] : begin
    len_1           <= 15;
    if (rbsp_1[12:14] == 3'b111) begin
        TrailingOnes_1  <= 0;
        TotalCoeff_1    <= 11;
    end
    else if (rbsp_1[12:14] == 3'b110) begin
        TrailingOnes_1  <= 1;
        TotalCoeff_1    <= 11;
    end
    else if (rbsp_1[12:14] == 3'b011) begin
        TrailingOnes_1  <= 0;
        TotalCoeff_1    <= 12;
    end
    else if (rbsp_1[12:14] == 3'b010) begin
        TrailingOnes_1  <= 1;
        TotalCoeff_1    <= 12;
    end
    else if (rbsp_1[12:14] == 3'b101) begin
        TrailingOnes_1  <= 2;
        TotalCoeff_1    <= 12;
    end
    else if (rbsp_1[12:14] == 3'b001) begin
        TrailingOnes_1  <= 2;
        TotalCoeff_1    <= 13;
    end
    else if (rbsp_1[12:14] == 3'b100) begin
        TrailingOnes_1  <= 3;
        TotalCoeff_1    <= 13;
    end
    else begin
        TrailingOnes_1  <= 3;
        TotalCoeff_1    <= 14;
    end
end
rbsp_1[12] : begin
    len_1           <= 16;
    if (rbsp_1[13:15] == 3'b111) begin
        TrailingOnes_1  <= 0;
        TotalCoeff_1    <= 13;
    end
    else if (rbsp_1[13:15] == 3'b011) begin
        TrailingOnes_1  <= 0;
        TotalCoeff_1    <= 14;
    end
    else if (rbsp_1[13:15] == 3'b110) begin
        TrailingOnes_1  <= 1;
        TotalCoeff_1    <= 14;
    end
    else if (rbsp_1[13:15] == 3'b101) begin
        TrailingOnes_1  <= 2;
        TotalCoeff_1    <= 14;
    end
    else if (rbsp_1[13:15] == 3'b010) begin
        TrailingOnes_1  <= 1;
        TotalCoeff_1    <= 15;
    end
    else if (rbsp_1[13:15] == 3'b001) begin
        TrailingOnes_1  <= 2;
        TotalCoeff_1    <= 15;
    end
    else if (rbsp_1[13:15] == 3'b100) begin
        TrailingOnes_1  <= 3;
        TotalCoeff_1    <= 15;
    end
    else begin
        TrailingOnes_1  <= 3;
        TotalCoeff_1    <= 16;
    end
end
rbsp_1[13] : begin
    len_1           <= 16;
    if (rbsp_1[14:15] == 2'b11) begin
        TrailingOnes_1  <= 0;
        TotalCoeff_1    <= 15;
    end
    else if (rbsp_1[14:15] == 2'b00) begin
        TrailingOnes_1  <= 0;
        TotalCoeff_1    <= 16;
    end
    else if (rbsp_1[14:15] == 2'b10) begin
        TrailingOnes_1  <= 1;
        TotalCoeff_1    <= 16;
    end
    else begin
        TrailingOnes_1  <= 2;
        TotalCoeff_1    <= 16;
    end
end
default : begin
    len_1           <= 15;
    TrailingOnes_1  <= 1;
    TotalCoeff_1    <= 13;
end
endcase

//------------------------
//nC >= 2 && nC < 4
//------------------------
always @(rbsp_2)
case (1'b1) 
rbsp_2[0] : begin
    len_2           <= 2;
    if (rbsp_2[1] == 'b1) begin
        TrailingOnes_2  <= 0;
        TotalCoeff_2    <= 0;
    end
    else begin
        TrailingOnes_2  <= 1;
        TotalCoeff_2    <= 1;
    end
end
rbsp_2[1] : begin
    if (rbsp_2[2] == 'b1) begin
        TrailingOnes_2  <= 2;
        TotalCoeff_2    <= 2;
        len_2           <= 3;
    end
    else if (rbsp_2[3] == 'b1) begin
        TrailingOnes_2  <= 3;
        TotalCoeff_2    <= 3;
        len_2           <= 4;
    end
    else begin
        TrailingOnes_2  <= 3;
        TotalCoeff_2    <= 4;
        len_2           <= 4;
    end
end
rbsp_2[2] : begin
    if (rbsp_2[3:4] == 'b11) begin
        TrailingOnes_2  <= 1;
        TotalCoeff_2    <= 2;
        len_2           <= 5;
    end
    else if (rbsp_2[3:4] == 'b10) begin
        TrailingOnes_2  <= 3;
        TotalCoeff_2    <= 5;
        len_2           <= 5;
    end
    else if (rbsp_2[4:5] == 'b11) begin
        TrailingOnes_2  <= 0;
        TotalCoeff_2    <= 1;
        len_2           <= 6;
    end
    else if (rbsp_2[4:5] == 'b10) begin
        TrailingOnes_2  <= 1;
        TotalCoeff_2    <= 3;
        len_2           <= 6;
    end
    else if (rbsp_2[4:5] == 'b01) begin
        TrailingOnes_2  <= 2;
        TotalCoeff_2    <= 3;
        len_2           <= 6;
    end
    else begin
        TrailingOnes_2  <= 3;
        TotalCoeff_2    <= 6;
        len_2           <= 6;
    end
end
rbsp_2[3] : begin
    len_2           <= 6;
    if (rbsp_2[4:5] == 'b11) begin
        TrailingOnes_2  <= 0;
        TotalCoeff_2    <= 2;
    end
    else if (rbsp_2[4:5] == 'b10) begin
        TrailingOnes_2  <= 1;
        TotalCoeff_2    <= 4;
    end
    else if (rbsp_2[4:5] == 'b01) begin
        TrailingOnes_2  <= 2;
        TotalCoeff_2    <= 4;
    end
    else begin
        TrailingOnes_2  <= 3;
        TotalCoeff_2    <= 7;
    end
end
rbsp_2[4] : begin
    len_2           <= 7;
    if (rbsp_2[5:6] == 'b11) begin
        TrailingOnes_2  <= 0;
        TotalCoeff_2    <= 3;
    end
    else if (rbsp_2[5:6] == 'b10) begin
        TrailingOnes_2  <= 1;
        TotalCoeff_2    <= 5;
    end
    else if (rbsp_2[5:6] == 'b01) begin
        TrailingOnes_2  <= 2;
        TotalCoeff_2    <= 5;
    end
    else begin
        TrailingOnes_2  <= 3;
        TotalCoeff_2    <= 8;
    end
end
rbsp_2[5] : begin
    len_2           <= 8;
    if (rbsp_2[6:7] == 'b11) begin
        TrailingOnes_2  <= 0;
        TotalCoeff_2    <= 4;
    end
    else if (rbsp_2[6:7] == 'b00) begin
        TrailingOnes_2  <= 0;
        TotalCoeff_2    <= 5;
    end
    else if (rbsp_2[6:7] == 'b10) begin
        TrailingOnes_2  <= 1;
        TotalCoeff_2    <= 6;
    end
    else begin
        TrailingOnes_2  <= 2;
        TotalCoeff_2    <= 6;
    end
end
rbsp_2[6] : begin
    len_2           <= 9;
    if (rbsp_2[7:8] == 'b11) begin
        TrailingOnes_2  <= 0;
        TotalCoeff_2    <= 6;
    end
    else if (rbsp_2[7:8] == 'b10) begin
        TrailingOnes_2  <= 1;
        TotalCoeff_2    <= 7;
    end
    else if (rbsp_2[7:8] == 'b01) begin
        TrailingOnes_2  <= 2;
        TotalCoeff_2    <= 7;
    end
    else begin
        TrailingOnes_2  <= 3;
        TotalCoeff_2    <= 9;
    end
end
rbsp_2[7] : begin
    len_2           <= 11;
    if (rbsp_2[8:10] == 'b111) begin
        TrailingOnes_2  <= 0;
        TotalCoeff_2    <= 7;
    end
    else if (rbsp_2[8:10] == 'b011) begin
        TrailingOnes_2  <= 0;
        TotalCoeff_2    <= 8;
    end
    else if (rbsp_2[8:10] == 'b110) begin
        TrailingOnes_2  <= 1;
        TotalCoeff_2    <= 8;
    end
    else if (rbsp_2[8:10] == 'b101) begin
        TrailingOnes_2  <= 2;
        TotalCoeff_2    <= 8;
    end
    else if (rbsp_2[8:10] == 'b010) begin
        TrailingOnes_2  <= 1;
        TotalCoeff_2    <= 9;
    end
    else if (rbsp_2[8:10] == 'b001) begin
        TrailingOnes_2  <= 2;
        TotalCoeff_2    <= 9;
    end
    else if (rbsp_2[8:10] == 'b100) begin
        TrailingOnes_2  <= 3;
        TotalCoeff_2    <= 10;
    end
    else begin
        TrailingOnes_2  <= 3;
        TotalCoeff_2    <= 11;
    end
end
rbsp_2[8] : begin
    len_2           <= 12;
    if (rbsp_2[9:11] == 'b111) begin
        TrailingOnes_2  <= 0;
        TotalCoeff_2    <= 9;
    end
    else if (rbsp_2[9:11] == 'b011) begin
        TrailingOnes_2  <= 0;
        TotalCoeff_2    <= 10;
    end
    else if (rbsp_2[9:11] == 'b110) begin
        TrailingOnes_2  <= 1;
        TotalCoeff_2    <= 10;
    end
    else if (rbsp_2[9:11] == 'b101) begin
        TrailingOnes_2  <= 2;
        TotalCoeff_2    <= 10;
    end
    else if (rbsp_2[9:11] == 'b000) begin
        TrailingOnes_2  <= 0;
        TotalCoeff_2    <= 11;
    end
    else if (rbsp_2[9:11] == 'b010) begin
        TrailingOnes_2  <= 1;
        TotalCoeff_2    <= 11;
    end
    else if (rbsp_2[9:11] == 'b001) begin
        TrailingOnes_2  <= 2;
        TotalCoeff_2    <= 11;
    end
    else  begin
        TrailingOnes_2  <= 3;
        TotalCoeff_2    <= 12;
    end
end
rbsp_2[9] : begin
    len_2           <= 13;
    if (rbsp_2[10:12] == 'b111) begin
        TrailingOnes_2  <= 0;
        TotalCoeff_2    <= 12;
    end
    else if (rbsp_2[10:12] == 'b110) begin
        TrailingOnes_2  <= 1;
        TotalCoeff_2    <= 12;
    end
    else if (rbsp_2[10:12] == 'b101) begin
        TrailingOnes_2  <= 2;
        TotalCoeff_2    <= 12;
    end
    else if (rbsp_2[10:12] == 'b011) begin
        TrailingOnes_2  <= 0;
        TotalCoeff_2    <= 13;
    end
    else if (rbsp_2[10:12] == 'b010) begin
        TrailingOnes_2  <= 1;
        TotalCoeff_2    <= 13;
    end
    else if (rbsp_2[10:12] == 'b001) begin
        TrailingOnes_2  <= 2;
        TotalCoeff_2    <= 13;
    end
    else if (rbsp_2[10:12] == 'b100) begin
        TrailingOnes_2  <= 3;
        TotalCoeff_2    <= 13;
    end
    else begin
        TrailingOnes_2  <= 3;
        TotalCoeff_2    <= 14;
    end
end
rbsp_2[10] : begin
    if (rbsp_2[11:12] == 'b11) begin
        TrailingOnes_2  <= 0;
        TotalCoeff_2    <= 14;
        len_2           <= 13;
    end
    else if (rbsp_2[11:12] == 'b10) begin
        TrailingOnes_2  <= 2;
        TotalCoeff_2    <= 14;
        len_2           <= 13;
    end
    else if (rbsp_2[12:13] == 'b11) begin
        TrailingOnes_2  <= 1;
        TotalCoeff_2    <= 14;
        len_2           <= 14;
    end
    else if (rbsp_2[12:13] == 'b01) begin
        TrailingOnes_2  <= 0;
        TotalCoeff_2    <= 15;
        len_2           <= 14;
    end
    else if (rbsp_2[12:13] == 'b00) begin
        TrailingOnes_2  <= 1;
        TotalCoeff_2    <= 15;
        len_2           <= 14;
    end
    else begin
        TrailingOnes_2  <= 2;
        TotalCoeff_2    <= 15;
        len_2           <= 14;
    end
end
rbsp_2[11] : begin
    len_2           <= 14;
    if (rbsp_2[12:13] == 'b11) begin
        TrailingOnes_2  <= 0;
        TotalCoeff_2    <= 16;
    end
    else if (rbsp_2[12:13] == 'b10) begin
        TrailingOnes_2  <= 1;
        TotalCoeff_2    <= 16;
    end
    else if (rbsp_2[12:13] == 'b01) begin
        TrailingOnes_2  <= 2;
        TotalCoeff_2    <= 16;
    end
    else begin
        TrailingOnes_2  <= 3;
        TotalCoeff_2    <= 16;
    end
end
default : begin
    TrailingOnes_2  <= 3;
    TotalCoeff_2    <= 15;
    len_2           <= 13;
end
endcase

//------------------------
// nC >= 4 && nC < 8
//------------------------
always @(rbsp_3)
case (1'b1) 
rbsp_3[0] : begin
    len_3           <= 4;
    case (rbsp_3[1:3])
        'b111 : begin
            TrailingOnes_3  <= 0;
            TotalCoeff_3    <= 0;
        end
        'b110 : begin
            TrailingOnes_3  <= 1;
            TotalCoeff_3    <= 1;
        end
        'b101 : begin
            TrailingOnes_3  <= 2;
            TotalCoeff_3    <= 2;
        end
        'b100 : begin
            TrailingOnes_3  <= 3;
            TotalCoeff_3    <= 3;
        end
        'b011 : begin
            TrailingOnes_3  <= 3;
            TotalCoeff_3    <= 4;
        end
        'b010 : begin
            TrailingOnes_3  <= 3;
            TotalCoeff_3    <= 5;
        end
        'b001 : begin
            TrailingOnes_3  <= 3;
            TotalCoeff_3    <= 6;
        end
        'b000 : begin
            TrailingOnes_3  <= 3;
            TotalCoeff_3    <= 7;
        end
    endcase
end
rbsp_3[1] : begin
    len_3           <= 5;
    case (rbsp_3[2:4])
        'b111 : begin
            TrailingOnes_3  <= 1;
            TotalCoeff_3    <= 2;
        end
        'b100 : begin
            TrailingOnes_3  <= 1;
            TotalCoeff_3    <= 3;
        end
        'b110 : begin
            TrailingOnes_3  <= 2;
            TotalCoeff_3    <= 3;
        end
        'b010 : begin
            TrailingOnes_3  <= 1;
            TotalCoeff_3    <= 4;
        end
        'b011 : begin
            TrailingOnes_3  <= 2;
            TotalCoeff_3    <= 4;
        end
        'b000 : begin
            TrailingOnes_3  <= 1;
            TotalCoeff_3    <= 5;
        end
        'b001 : begin
            TrailingOnes_3  <= 2;
            TotalCoeff_3    <= 5;
        end
        'b101 : begin
            TrailingOnes_3  <= 3;
            TotalCoeff_3    <= 8;
        end
    endcase
end
rbsp_3[2] : begin
    len_3           <= 6;
    case (rbsp_3[3:5])
        3'b111 : begin
            TrailingOnes_3  <= 0;
            TotalCoeff_3    <= 1;
        end
        3'b011 : begin
            TrailingOnes_3  <= 0;
            TotalCoeff_3    <= 2;
        end
        3'b000 : begin
            TrailingOnes_3  <= 0;
            TotalCoeff_3    <= 3;
        end
        3'b110 : begin
            TrailingOnes_3  <= 1;
            TotalCoeff_3    <= 6;
        end
        3'b101 : begin
            TrailingOnes_3  <= 2;
            TotalCoeff_3    <= 6;
        end
        3'b010 : begin
            TrailingOnes_3  <= 1;
            TotalCoeff_3    <= 7;
        end
        3'b001 : begin
            TrailingOnes_3  <= 2;
            TotalCoeff_3    <= 7;
        end
        3'b100 : begin
            TrailingOnes_3  <= 3;
            TotalCoeff_3    <= 9;
        end
    endcase
end
rbsp_3[3] : begin
    len_3           <= 7;
    case (rbsp_3[4:6])
        'b111 : begin
            TrailingOnes_3  <= 0;
            TotalCoeff_3    <= 4;
        end
        'b011 : begin
            TrailingOnes_3  <= 0;
            TotalCoeff_3    <= 5;
        end
        'b001 : begin
            TrailingOnes_3  <= 0;
            TotalCoeff_3    <= 6;
        end
        'b000 : begin
            TrailingOnes_3  <= 0;
            TotalCoeff_3    <= 7;
        end
        'b110 : begin
            TrailingOnes_3  <= 1;
            TotalCoeff_3    <= 8;
        end
        'b101 : begin
            TrailingOnes_3  <= 2;
            TotalCoeff_3    <= 8;
        end

        'b010 : begin
            TrailingOnes_3  <= 2;
            TotalCoeff_3    <= 9;
        end
        'b100 : begin
            TrailingOnes_3  <= 3;
            TotalCoeff_3    <= 10;
        end
    endcase
end
rbsp_3[4] : begin
    len_3           <= 8;
    case (rbsp_3[5:7])
        'b111 : begin
            TrailingOnes_3  <= 0;
            TotalCoeff_3    <= 8;
        end
        'b011 : begin
            TrailingOnes_3  <= 0;
            TotalCoeff_3    <= 9;
        end
        'b110 : begin
            TrailingOnes_3  <= 1;
            TotalCoeff_3    <= 9;
        end
        'b010 : begin
            TrailingOnes_3  <= 1;
            TotalCoeff_3    <= 10;
        end
        'b101 : begin
            TrailingOnes_3  <= 2;
            TotalCoeff_3    <= 10;
        end
        'b001 : begin
            TrailingOnes_3  <= 2;
            TotalCoeff_3    <= 11;
        end
        'b100 : begin
            TrailingOnes_3  <= 3;
            TotalCoeff_3    <= 11;
        end
        'b000 : begin
            TrailingOnes_3  <= 3;
            TotalCoeff_3    <= 12;
        end
    endcase
end
rbsp_3[5] : begin
    len_3           <= 9;
    case (rbsp_3[6:8])
        'b111 : begin
            TrailingOnes_3  <= 0;
            TotalCoeff_3    <= 10;
        end
        'b011 : begin
            TrailingOnes_3  <= 0;
            TotalCoeff_3    <= 11;
        end
        'b110 : begin
            TrailingOnes_3  <= 1;
            TotalCoeff_3    <= 11;
        end
        'b000 : begin
            TrailingOnes_3  <= 0;
            TotalCoeff_3    <= 12;
        end
        'b010 : begin
            TrailingOnes_3  <= 1;
            TotalCoeff_3    <= 12;
        end
        'b101 : begin
            TrailingOnes_3  <= 2;
            TotalCoeff_3    <= 12;
        end
        'b001 : begin
            TrailingOnes_3  <= 2;
            TotalCoeff_3    <= 13;
        end
        'b100 : begin
            TrailingOnes_3  <= 3;
            TotalCoeff_3    <= 13;
        end
    endcase
end
rbsp_3[6] : begin
    if (rbsp_3[7:8] == 'b11)begin
        TrailingOnes_3  <= 1;
        TotalCoeff_3    <= 13;
        len_3           <= 9;
    end
    else if (rbsp_3[7:9] == 'b101)begin
        TrailingOnes_3  <= 0;
        TotalCoeff_3    <= 13;
        len_3           <= 10;
    end
    else if (rbsp_3[7:9] == 'b001)begin
        TrailingOnes_3  <= 0;
        TotalCoeff_3    <= 14;
        len_3           <= 10;
    end
    else if (rbsp_3[7:9] == 'b100)begin
        TrailingOnes_3  <= 1;
        TotalCoeff_3    <= 14;
        len_3           <= 10;
    end
    else if (rbsp_3[7:9] == 'b011)begin
        TrailingOnes_3  <= 2;
        TotalCoeff_3    <= 14;
        len_3           <= 10;
    end
    else if (rbsp_3[7:9] == 'b010)begin
        TrailingOnes_3  <= 3;
        TotalCoeff_3    <= 14;
        len_3           <= 10;
    end
    else begin
        TrailingOnes_3  <= 1;
        TotalCoeff_3    <= 15;
        len_3           <= 10;
    end
end
rbsp_3[7] : begin
    len_3           <= 10;
    case (rbsp_3[8:9])
        'b01 : begin
            TrailingOnes_3  <= 0;
            TotalCoeff_3    <= 15;
        end
        'b11 : begin
            TrailingOnes_3  <= 2;
            TotalCoeff_3    <= 15;
        end
        'b10 : begin
            TrailingOnes_3  <= 3;
            TotalCoeff_3    <= 15;
        end
        'b00 : begin
            TrailingOnes_3  <= 1;
            TotalCoeff_3    <= 16;
        end
    endcase
end
rbsp_3[8] : begin
    len_3           <= 10;
    if (rbsp_3[9] == 'b1)begin
        TrailingOnes_3  <= 2;
        TotalCoeff_3    <= 16;
    end
    else begin
        TrailingOnes_3  <= 3;
        TotalCoeff_3    <= 16;
    end
end
default : begin
    len_3           <= 10;
    TrailingOnes_3  <= 0;
    TotalCoeff_3    <= 16;
end
endcase

//------------------------
// nC > 8
//------------------------
always @(rbsp_4)
begin
    len_4 <= 6;
    if (rbsp_4[0:4] == 5'b00001) begin
        TrailingOnes_4  <= 0;
        TotalCoeff_4    <= 0;
    end
    else begin
        TrailingOnes_4  <= rbsp_4[4:5];
        TotalCoeff_4    <= rbsp_4[0:3] + 1'b1;
    end
end

//------------------------
// nC == -1
//------------------------
always @(rbsp_5)
case (1'b1)
rbsp_5[0] : begin
    TrailingOnes_5  <= 1;
    TotalCoeff_5    <= 1;
    len_5           <= 1;
end
rbsp_5[1] : begin
    TrailingOnes_5  <= 0;
    TotalCoeff_5    <= 0;
    len_5           <= 2;
end
rbsp_5[2] : begin
    TrailingOnes_5  <= 2;
    TotalCoeff_5    <= 2;
    len_5           <= 3;
end
rbsp_5[3] : begin
    len_5           <= 6;
    if (rbsp_5[4:5] == 'b11) begin
        TrailingOnes_5  <= 0;
        TotalCoeff_5    <= 1;
    end
    else if (rbsp_5[4:5] == 'b00) begin
        TrailingOnes_5  <= 0;
        TotalCoeff_5    <= 2;
    end
    else if (rbsp_5[4:5] == 'b10) begin
        TrailingOnes_5  <= 1;
        TotalCoeff_5    <= 2;
    end
    else begin
        TrailingOnes_5  <= 3;
        TotalCoeff_5    <= 3;
    end
end
rbsp_5[4] : begin
    len_5           <= 6;
    if (rbsp_5[5] == 'b1) begin
        TrailingOnes_5  <= 0;
        TotalCoeff_5    <= 3;
    end
    else begin
        TrailingOnes_5  <= 0;
        TotalCoeff_5    <= 4;
    end
end
rbsp_5[5] : begin
    len_5           <= 7;
    if (rbsp_5[6] == 'b1) begin
        TrailingOnes_5  <= 1;
        TotalCoeff_5    <= 3;
    end
    else begin
        TrailingOnes_5  <= 2;
        TotalCoeff_5    <= 3;
    end
end
rbsp_5[6] : begin
    len_5           <= 8;
    if (rbsp_5[7] == 'b1) begin
        TrailingOnes_5  <= 1;
        TotalCoeff_5    <= 4;
    end
    else begin
        TrailingOnes_5  <= 2;
        TotalCoeff_5    <= 4;
    end
end
default : begin
    len_5           <= 7;
    TrailingOnes_5  <= 3;
    TotalCoeff_5    <= 4;
end
endcase

//------------------------
//output mux
//------------------------
//startect a colum according to nC
always @(*)
begin
    if (nC == -1) begin
        TrailingOnes_comb   <= TrailingOnes_5;
        TotalCoeff_comb     <= TotalCoeff_5;
        len_comb            <= len_5;
    end
    else if (nC[4] | nC[3]) begin
        TrailingOnes_comb   <= TrailingOnes_4;
        TotalCoeff_comb     <= TotalCoeff_4;
        len_comb            <= len_4;
    end
    else if (nC[2]) begin
        TrailingOnes_comb   <= TrailingOnes_3;
        TotalCoeff_comb     <= TotalCoeff_3;
        len_comb            <= len_3;
    end
    else if (nC[1]) begin
        TrailingOnes_comb   <= TrailingOnes_2;
        TotalCoeff_comb     <= TotalCoeff_2;
        len_comb            <= len_2;
    end
    else begin
        TrailingOnes_comb   <= TrailingOnes_1;
        TotalCoeff_comb     <= TotalCoeff_1;
        len_comb            <= len_1;
    end
end

//------------------------
//TrailingOnes & TotalCoeff
//------------------------
always @(posedge clk or negedge rst_n)
if (!rst_n) begin
    TrailingOnes    <= 0;
    TotalCoeff      <= 0;
end
else if (ena && sel) begin
    TrailingOnes    <= TrailingOnes_comb;
    TotalCoeff      <= TotalCoeff_comb;
end

endmodule

