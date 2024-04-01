// H.264码流的比特流控制器模块：
// 根据NALU类型选择解析SPS、PPS或Slice信息。

// 根据不同语法单元的状态控制对应的模块使能信号。

// 管理比特流的前沿处理,实现码流转发到下一个NALU或下一个帧

`include "defines.v"

module bitstream_controller
(
 clk,
 rst_n,
 ena,
 ext_mem_init_done,
 cycle_counter_ena,
 num_cycles_1_frame,
 sps_state,
 pps_state,
 slice_header_state,
 slice_data_state,
 first_mb_in_slice,
 mb_index,
 write_to_ram_idle,
 num_ref_idx_active_override_flag,
 num_ref_idx_l0_active_minus1_slice_header,
 num_ref_idx_l0_active_minus1_pps,
 forward_len_pps,
 forward_len_sps,
 forward_len_slice_header,
 forward_len_slice_data,
 end_of_stream,
 nal_unit_type,
 
 sps_enable,
 pps_enable,
 slice_header_enable,
 slice_data_enable, 
 num_ref_idx_l0_active_minus1,
 forward_len,
 start_of_frame,
 end_of_frame,
 start_of_slice,
 pic_num,
 pic_num_a,
 bitstream_forwarded_rbsp,
 is_last_bit_of_rbsp,
 bitstream_forwarded_rbsp_clear,
 forward_to_next_nalu_out,
 bitstream_state
);

input clk;
input rst_n;
input ena;
input ext_mem_init_done;
input cycle_counter_ena;
input[23:0] num_cycles_1_frame;
input[4:0] sps_state;
input[3:0] pps_state;
input[4:0] slice_header_state; // fix, input[3:0], Port width mismatch, so slice_header_state = `slice_header_end  5'b10000 is impossible
input[4:0] slice_data_state;
input [`mb_x_bits + `mb_y_bits - 1:0] first_mb_in_slice;
input [`mb_x_bits + `mb_y_bits - 1:0] mb_index;
input write_to_ram_idle;
input num_ref_idx_active_override_flag;
input[2:0] num_ref_idx_l0_active_minus1_slice_header;
input[2:0] num_ref_idx_l0_active_minus1_pps;
input[4:0] forward_len_pps;
input[4:0] forward_len_sps;
input[4:0] forward_len_slice_header;
input[4:0] forward_len_slice_data;
input end_of_stream;
input[4:0] nal_unit_type;

output sps_enable;
output pps_enable;
output slice_header_enable;
output slice_data_enable;
output[2:0] num_ref_idx_l0_active_minus1;
output[4:0] forward_len;
output reg start_of_frame;
input end_of_frame;
output reg start_of_slice;
output reg [63:0] pic_num;
output reg [15:0] pic_num_a;
input is_last_bit_of_rbsp;
input bitstream_forwarded_rbsp;
output reg bitstream_forwarded_rbsp_clear;
output forward_to_next_nalu_out;
output reg[2:0] bitstream_state;
//wire[9:0] num_mb_in_slice;

reg forward_to_next_nalu;
reg forward_to_next_frame;

wire end_of_stream;
reg[23:0] frame_cycle_counter;

reg sps_enable;
reg pps_enable;
reg slice_header_enable;
reg slice_data_enable;

//reg[2:0] num_ref_idx_l0_active_minus1;
assign forward_to_next_nalu_out = forward_to_next_nalu && ~bitstream_forwarded_rbsp;
always @(posedge clk)
if (ena) begin
	if (bitstream_state== `bitstream_slice_header && slice_header_state == `slice_header_end1 && first_mb_in_slice == 0)
		start_of_frame <= 1;
	else
		start_of_frame <= 0;
end
		
always @(posedge clk)
if (ena) begin
	if (bitstream_state== `bitstream_slice_header && slice_header_state == `slice_header_end1 && 
			~forward_to_next_frame)
		start_of_slice <= 1;
	else
		start_of_slice <= 0;
end

always @(posedge clk)
if (~rst_n) begin
    pic_num <= 0;
    pic_num_a <= 0;
end
else if (ena && end_of_frame) begin
	pic_num <= pic_num + 1'b1;
	pic_num_a <= pic_num_a + 1'b1;
end		
else if (bitstream_forwarded_rbsp)
	pic_num_a <= 0;

always @(posedge clk or negedge rst_n)
    if (rst_n == 0)
        begin
            sps_enable <= 0;
            pps_enable <= 0;
            slice_header_enable <= 0;
            slice_data_enable <= 0;
            bitstream_state <= `rst_bitstream;
			forward_to_next_nalu <= 1'b0;
			forward_to_next_frame <= 1'b0;
			bitstream_forwarded_rbsp_clear <= 1'b0;
        end
	else if (ena) begin
		bitstream_forwarded_rbsp_clear <= 1'b0;
	    case (bitstream_state )
            `rst_bitstream:
                if (nal_unit_type == `nalu_type_sps && ext_mem_init_done)
                    begin
                        sps_enable <= 1;
                        bitstream_state <= `bitstream_sps;
                    end
			`bitstream_forward_to_next_nalu:begin
				forward_to_next_nalu <= 1'b1;
				if (bitstream_forwarded_rbsp)begin
					forward_to_next_nalu <= 1'b0;
					bitstream_forwarded_rbsp_clear <= 1'b1;
					bitstream_state <= `bitstream_next_nalu;
				end
			end
			`bitstream_next_nalu: begin
				if (nal_unit_type == `nalu_type_sps)
					begin
					   sps_enable <= 1;
					   bitstream_state <= `bitstream_sps;
					end
				else if (nal_unit_type == `nalu_type_pps)
					begin
					   pps_enable <= 1;
					   bitstream_state <= `bitstream_pps;
					end                            
				 else 
					 begin
						 bitstream_state <= `bitstream_slice_header;
						 slice_header_enable <= 1;
					 end  
			 end
            `bitstream_sps:
                if (sps_state == `sps_end)
                    begin
                        sps_enable <= 0;
                        bitstream_state <= `bitstream_forward_to_next_nalu;
					end

            `bitstream_pps:
                if (pps_state == `pps_end)
                    begin
                        pps_enable <= 0;
                        bitstream_state <= `bitstream_forward_to_next_nalu;
                    end            
            `bitstream_slice_header:
                if (slice_header_state == `slice_header_end1 )
                    begin
						slice_header_enable <= 0;
						if (forward_to_next_frame && first_mb_in_slice != 0) begin
							bitstream_state <= `bitstream_forward_to_next_nalu;
						end
						else begin
							forward_to_next_frame <= 0;
							slice_data_enable <= 1;
							bitstream_state <= `bitstream_slice_data;
						end
                    end

            `bitstream_slice_data:
                if (slice_data_state == `rbsp_trailing_bits_slice_data)
                    begin
                        slice_data_enable <= 0;
						bitstream_state <= `bitstream_forward_to_next_nalu;
					end
				else if (slice_data_state == `sd_forward_to_next_frame)
					begin
                        slice_data_enable <= 0;
						forward_to_next_frame <= 1'b1;
						bitstream_state <= `bitstream_forward_to_next_nalu;
					end
			
            
        endcase
	end

/*assign num_mb_in_slice = (pic_width_in_mbs_minus1+1)*(pic_height_in_map_units_minus1+1);
always @(posedge clk or negedge rst_n)
    if (rst_n == 0)
        begin
            num_ref_idx_l0_active_minus1 <= 0;
        end
    else if (ena && (
    		slice_header_state == `slice_header_end || slice_header_state == `pps_end)
		begin
			num_ref_idx_l0_active_minus1 <= num_ref_idx_active_override_flag ? 
            num_ref_idx_l0_active_minus1_slice_header : num_ref_idx_l0_active_minus1_pps;
		end
*/

assign num_ref_idx_l0_active_minus1 = num_ref_idx_active_override_flag ? 
                                      num_ref_idx_l0_active_minus1_slice_header : num_ref_idx_l0_active_minus1_pps;
  
assign forward_len = pps_enable ? forward_len_pps : (
                     sps_enable ? forward_len_sps : (
                     slice_header_enable ? forward_len_slice_header : (
                     slice_data_enable ? forward_len_slice_data : (
					 forward_to_next_nalu_out ? 8:0))));
    
            
endmodule
