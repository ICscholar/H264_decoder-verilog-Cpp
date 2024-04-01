// 主要用于处理网络抽象层单元（NALU）的原始字节序列负载（RBSP）数据流。
// 在视频编码标准如H.264/AVC或H.265/HEVC中，NALU是编码视频数据的基本单位，而RBSP是NALU负载的一种格式，用于传输编码视频数据。
// 这个模块的功能是从输入的NALU数据中提取RBSP数据，并进行一定的处理和转换，以便进一步的视频解码处理


`include "defines.v"

module rbsp_buffer
(
	input clk, //global clock and reset
	input rst_n,
	input ena,
	input valid_data_of_nalu_in, //enable this module, valid data of nalu 
								 //valid data is the data except for start_code, nalu_head, competition_prevent_code
	input [8:0] rbsp_in, //data from read nalu
	input [4:0] nal_unit_type_nalu,
	output [4:0] nal_unit_type,
	input [4:0] forward_len_in, //length of bits to forward 
	input [3:0] read_bits_len,
	output reg [7:0] read_bits_out,

	output rd_req_to_nalu_out,		 //read one byte request to read nalu 
	output reg [31:0] rbsp_out,	         //bits output		     
	output reg is_last_bit_of_rbsp,
	output reg [3:0] num_zero_bits,
	output buffer_valid_out,
	//debug
	output reg [31:0] rbsp_bit_counter,
	output reg bitstream_forwarded_rbsp,
	input bitstream_forwarded_rbsp_clear,
	input forward_to_next_nalu
);

reg [39:0] buffer; // store 4 bytes, if 
reg [4:0]  is_last_byte_of_rbsp;

//next_bits_offset
reg [5:0] next_bits_offset;
reg [2:0] bits_offset;
reg [4:0] nal_unit_type_nalu_d1;
reg [4:0] nal_unit_type_nalu_d2;
reg [4:0] nal_unit_type_nalu_d3;
reg [4:0] nal_unit_type_nalu_d4;
reg [4:0] nal_unit_type_nalu_d5;
wire next_is_bitstream_forwarded_rbsp;

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
	begin
		nal_unit_type_nalu_d1 <= 0;
		nal_unit_type_nalu_d2 <= 0;
		nal_unit_type_nalu_d3 <= 0;
		nal_unit_type_nalu_d4 <= 0;
		nal_unit_type_nalu_d5 <= 0;
	end
	else if (valid_data_of_nalu_in && rd_req_to_nalu_out && ena)
	begin
		nal_unit_type_nalu_d1 <= nal_unit_type_nalu;
		nal_unit_type_nalu_d2 <= nal_unit_type_nalu_d1;
		nal_unit_type_nalu_d3 <= nal_unit_type_nalu_d2;
		nal_unit_type_nalu_d4 <= nal_unit_type_nalu_d3;
		nal_unit_type_nalu_d5 <= nal_unit_type_nalu_d4;
	end
end

assign nal_unit_type = nal_unit_type_nalu_d5;
always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
	begin
		rbsp_bit_counter <= 0;
	end
	else if (buffer_valid_out && forward_len_in != 'h1f )
	begin
		rbsp_bit_counter <= rbsp_bit_counter + forward_len_in;
	end
end
reg bitstream_forwarded_rbsp_reg;

always @(*)
if (~buffer_valid_out)
	next_bits_offset <= bits_offset;
else begin
	if(bitstream_forwarded_rbsp_clear)
		next_bits_offset <= 0;
    else if ( forward_len_in == 'h1f ) // forward_len_in 5'b11111 used to clear rbsp_trailing_bits
        next_bits_offset <= 8;       
	else if(forward_to_next_nalu)
		next_bits_offset <= 8;
    else
        next_bits_offset <= bits_offset + forward_len_in; 
end
 

always @(posedge clk or negedge rst_n)
if (!rst_n) begin
	bitstream_forwarded_rbsp_reg <= 1'b0;
end
else begin
	bitstream_forwarded_rbsp_reg <= bitstream_forwarded_rbsp;
end

//bits_offset	 
always @(posedge clk or negedge rst_n)
if (!rst_n) begin
	bits_offset <= 3'b0;
end
else if ( buffer_valid_out ) begin
	bits_offset <= next_bits_offset[2:0];
end
		
reg [2:0] num_of_byte_to_fill;
reg buffer_valid_out_int;
//num_of_byte_to_fill
always @ (posedge clk or negedge rst_n)
if (!rst_n)begin
	num_of_byte_to_fill <= 5;
	buffer_valid_out_int <= 0;
end
else begin
	if ( num_of_byte_to_fill == 0 && buffer_valid_out )
        begin
    	    num_of_byte_to_fill <= next_bits_offset[5:3];
    	    buffer_valid_out_int <= (next_bits_offset[5:3] == 0);
    	end
    else if ( ena && valid_data_of_nalu_in  && rd_req_to_nalu_out)
        begin
    	    num_of_byte_to_fill <= num_of_byte_to_fill - 1'b1;
    	    buffer_valid_out_int <= (num_of_byte_to_fill == 1);
        end
	if (next_is_bitstream_forwarded_rbsp) begin
		num_of_byte_to_fill <= 0;
		buffer_valid_out_int <= 1'b1;
	end
end

assign buffer_valid_out = buffer_valid_out_int;
//equest data from nalu
assign rd_req_to_nalu_out = valid_data_of_nalu_in? (num_of_byte_to_fill > 0) : 1'b1; 
// if nalu output is invalid, request data from nalu again

//buffer

wire [39:0] next_buffer;
wire [4:0] next_is_last_byte_of_rbsp;
wire buffer_refresh_wire;
assign buffer_refresh_wire = ena && valid_data_of_nalu_in  && rd_req_to_nalu_out;
assign next_buffer = buffer_refresh_wire ? {buffer[31:0], rbsp_in[7:0]} : buffer;

reg forward_to_next_nalu_reg;
always @(posedge clk or negedge rst_n)
if (~rst_n)begin
	bitstream_forwarded_rbsp <= 0;
end
else begin
	if (bitstream_forwarded_rbsp_clear) begin
		bitstream_forwarded_rbsp <= 1'b0;
	end
	else if (is_last_byte_of_rbsp[4] && buffer_refresh_wire)begin
		bitstream_forwarded_rbsp <= 1'b1;
	end
end
assign next_is_bitstream_forwarded_rbsp = is_last_byte_of_rbsp[4] && buffer_refresh_wire;

always @ (posedge clk or negedge rst_n) 
if (!rst_n)begin
	buffer <= 32'b0;
	is_last_byte_of_rbsp <= 6'b0;
end
else if(buffer_refresh_wire)begin		   
    buffer[39:0] <= next_buffer;
	is_last_byte_of_rbsp[4:0] <= {is_last_byte_of_rbsp[3:0], rbsp_in[8]};

end


reg [31:0] next_rbsp_out;
always@(*)
	case (next_bits_offset[2:0])
	0  :next_rbsp_out <= next_buffer[39:8];
	1  :next_rbsp_out <= next_buffer[38:7];
	2  :next_rbsp_out <= next_buffer[37:6];
	3  :next_rbsp_out <= next_buffer[36:5];
	4  :next_rbsp_out <= next_buffer[35:4];
	5  :next_rbsp_out <= next_buffer[34:3];
	6  :next_rbsp_out <= next_buffer[33:2];
	default  :next_rbsp_out <= next_buffer[32:1];
	endcase

always@(posedge clk)
	rbsp_out <= next_rbsp_out;

always @(*)
	case ( 1'b1 )   
	rbsp_out[31] : num_zero_bits <= 0;
	rbsp_out[30] : num_zero_bits <= 1;
	rbsp_out[29] : num_zero_bits <= 2;
	rbsp_out[28] : num_zero_bits <= 3;
	rbsp_out[27] : num_zero_bits <= 4;
	rbsp_out[26] : num_zero_bits <= 5;
	rbsp_out[25] : num_zero_bits <= 6;
	rbsp_out[24] : num_zero_bits <= 7;
	rbsp_out[23] : num_zero_bits <= 8;
	rbsp_out[22] : num_zero_bits <= 9;
	rbsp_out[21] : num_zero_bits <= 10;
	rbsp_out[20] : num_zero_bits <= 11;
	rbsp_out[19] : num_zero_bits <= 12;
	rbsp_out[18] : num_zero_bits <= 13;
	rbsp_out[17] : num_zero_bits <= 14;   
	default     : num_zero_bits <= 15;       
	endcase



always @(*) begin
	is_last_bit_of_rbsp = 0;	
	if( is_last_byte_of_rbsp[4]) begin
		if (bits_offset == 0 && rbsp_out[31:24] == 8'h80 || 
		    bits_offset == 1 && rbsp_out[31:25] == 7'h40 ||
			bits_offset == 2 && rbsp_out[31:26] == 6'h20 ||
			bits_offset == 3 && rbsp_out[31:27] == 5'h10 ||
			bits_offset == 4 && rbsp_out[31:28] == 4'h8 ||
			bits_offset == 5 && rbsp_out[31:29] == 3'h4 ||
			bits_offset == 6 && rbsp_out[31:30] == 2'h2 ||
			bits_offset == 7)
			is_last_bit_of_rbsp = 1;
	end
end


always @(*)
case ( read_bits_len )
1 : read_bits_out <= rbsp_out[31:31];
2 : read_bits_out <= rbsp_out[31:30];
3 : read_bits_out <= rbsp_out[31:29];
4 : read_bits_out <= rbsp_out[31:28];
5 : read_bits_out <= rbsp_out[31:27];
6 : read_bits_out <= rbsp_out[31:26];
7 : read_bits_out <= rbsp_out[31:25];
8 : read_bits_out <= rbsp_out[31:24];
default: read_bits_out <= 0;
endcase

endmodule
