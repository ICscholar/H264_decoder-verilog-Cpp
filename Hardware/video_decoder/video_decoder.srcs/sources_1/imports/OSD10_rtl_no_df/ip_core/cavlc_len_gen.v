// 后缀为_comb的变量为组合逻辑变量，不会在时钟上升沿下降沿更新
// 记录Context-Based Adaptive Binary Arithmetic Coding(CAVLC)解码器在每个状态下解码的码流位数
// 主要功能:

// 根据CAVLC当前状态指示,选择不同模块输出的码流长度。

// CAVLC主要状态包括:

//     读取变元总个数和尾零个数
//     读取系数级值前缀和后缀
//     读取零元计数
//     读取运行长度
//     计算级值
//     空闲

// "读取系数级值前缀和后缀"在H.264视频编码标准中具有以下重要作用:

// 用于熵编码系数级值。前缀和后缀可以很好地描述级值分布,设计出高效的熵编码方案。

// 前缀表示级值的阶段范围,后缀进一步缩小到具体值。通过这种粗细编码,实现更高压缩率。

// 前缀后缀结合可以还原出原始级值。这在解码时免除了单独编码每个级值
`include "defines.v"

module cavlc_len_gen
(
    cavlc_state,
    len_read_total_coeffs_comb,
    len_read_levels_comb,
    len_read_total_zeros_comb,
    len_read_run_befores_comb,
    len_comb
);
//------------------------
// ports
//------------------------
input  [7:0] cavlc_state;
input  [4:0] len_read_total_coeffs_comb;
input  [4:0] len_read_levels_comb;
input  [3:0] len_read_total_zeros_comb;
input  [3:0] len_read_run_befores_comb;

output [4:0] len_comb;

//------------------------
// regs
//------------------------
reg [4:0] len_comb;         //number of bits comsumed by cavlc in a cycle

//------------------------
// len_comb
//------------------------
always @ (*)
case (1'b1) //synthesis parallel_case
    cavlc_state[`cavlc_read_total_coeffs_bit]  : len_comb <= len_read_total_coeffs_comb;
    cavlc_state[`cavlc_read_t1s_flags_bit],  
    cavlc_state[`cavlc_read_level_prefix_bit],
    cavlc_state[`cavlc_read_level_suffix_bit]  : len_comb <= len_read_levels_comb;       
    cavlc_state[`cavlc_read_total_zeros_bit]   : len_comb <= len_read_total_zeros_comb;
    cavlc_state[`cavlc_read_run_befores_bit]   : len_comb <= len_read_run_befores_comb;
    cavlc_state[`cavlc_calc_level_bit],
    cavlc_state[`cavlc_idle_bit]               : len_comb <= 0;
    default                                    : len_comb <= 'b1;
endcase

endmodule

