// （NALU）的读取和解析，这是视频编码标准（如H.264/AVC或H.265/HEVC）中用于封装视频数据的一种格式。
// ⼀个NALU = ⼀组对应于视频编码的NALU头部信息 + ⼀个原始字节序列负荷(RBSP,Raw Byte Sequence Payload).
// 模块的功能包括检测NALU起始字节、提取NALU头信息、读取视频流数据，并将编码视频比特流（EBSP）转换为原始字节序列负载（RBSP）

// 主要功能
// NALU起始字节检测: 通过比较连续的字节值是否等于NALU起始码0x000001，来检测NALU的开始。

// NALU头信息提取: 在检测到NALU起始字节后，下一个字节被解析为NALU头，包括类型（nal_unit_type）、引用指标（nal_ref_idc）和禁止位（forbidden_zero_bit）。

// 视频流地址管理: 根据模块的使能信号和读请求信号，递增视频流内存地址以便连续读取数据。

// EBSP到RBSP的转换: 过滤掉EBSP中的防伪造三字节（0x000003），并将处理后的数据作为RBSP输出。
// 这是因为在NALU数据中，序列0x000003是为了防止在数据中出现与NALU起始码相似的模式而插入的，需要在解码时去除。

// 读请求管理: 控制模块何时向视频流发出读请求，依赖于SPS（序列参数集）的发现和其他条件。
module read_nalu
(
 clk,
 rst_n,
 ena,
 rd_req_by_rbsp_buffer_in,
 mem_data_in,

 nal_unit_type,
 nal_ref_idc,
 forbidden_zero_bit,

 stream_mem_addr, 
 mem_rd_req_out,
 rbsp_data_out,
 rbsp_valid_out
);
input clk,rst_n;	   //global clock and reset					   
input rd_req_by_rbsp_buffer_in;		   //enable this module
input ena;
input 	[7:0]	mem_data_in;	  //data from stream
output	[31:0]	stream_mem_addr;
output  		mem_rd_req_out;		  //read request from stream

output[4:0] nal_unit_type;	   //nalu head output
output[1:0] nal_ref_idc;
output      forbidden_zero_bit; 

output[8:0] rbsp_data_out;	  //data to rbsp buffer
output      rbsp_valid_out;	  	 //write to rbsp buffer

//nslu
parameter
NaluStartBytes = 24'h000001;

reg[7:0] nalu_head;
reg       nalu_valid;

reg[7:0] last_byte3;
reg[7:0] last_byte2;
reg[7:0] last_byte1;
reg[7:0] current_byte;
reg[7:0] next_byte1;
reg[7:0] next_byte2;
reg[7:0] next_byte3;
reg[7:0] next_byte4;

reg  start_bytes_detect;//current nalu start bytes
reg sps_found;
wire next_start_bytes_detect; //next nalu start bytes

reg [31:0] stream_mem_addr;
always @(posedge clk or negedge rst_n)
if (!rst_n)
   stream_mem_addr  <=  0;
else if (ena && mem_rd_req_out == 1'b1)
   stream_mem_addr  <= stream_mem_addr + 1;


always @(posedge clk or negedge rst_n)
if (!rst_n)
begin
   last_byte1   <= 8'b0;
   last_byte2   <= 8'b0;
   last_byte3   <= 8'b0;
   current_byte <= 8'b0;
   next_byte1   <= 8'b0;
   next_byte2   <= 8'b0;
   next_byte3   <= 8'b0;
   next_byte4   <= 8'b0;
end
else if (ena && mem_rd_req_out)
begin
   next_byte4   <= mem_data_in;
   next_byte3   <= next_byte4;
   next_byte2   <= next_byte3;
   next_byte1   <= next_byte2;
   current_byte <= next_byte1;
   last_byte1   <= current_byte;
   last_byte2   <= last_byte1;
   last_byte3   <= last_byte2; 
end
    
//detect nalu start bytes     
always @(posedge clk or negedge rst_n)
if (~rst_n)
    start_bytes_detect <= 1'b0;
else if(ena) begin
	if (rd_req_by_rbsp_buffer_in && {last_byte2,last_byte1,current_byte} 
			 == NaluStartBytes)
		start_bytes_detect <= 1'b1;
	else if (rd_req_by_rbsp_buffer_in)
		start_bytes_detect <= 1'b0;    
end
//nalu head

always @(posedge clk or negedge rst_n)
if (~rst_n) begin
   nalu_head <= 'b0;
   sps_found <= 'b0;
end
else if (ena && start_bytes_detect)begin
	nalu_head <= current_byte;
	if (current_byte[4:0] == 7)
		sps_found <= 1'b1;
end


always @(posedge clk or negedge rst_n)
if (~rst_n)
   nalu_valid <= 1'b0;
else if (ena) begin
	if(rd_req_by_rbsp_buffer_in && next_start_bytes_detect)
	   nalu_valid <= 1'b0;
	else if (rd_req_by_rbsp_buffer_in && start_bytes_detect)
	   nalu_valid <= 1'b1;
end
//current nalu end , next nalu start       
assign next_start_bytes_detect =  {next_byte1,next_byte2,next_byte3} == NaluStartBytes ||
{next_byte1,next_byte2,next_byte3,next_byte4} == {8'h00,NaluStartBytes} ;

//nalu head struct
assign nal_unit_type = nalu_head[4:0];
assign nal_ref_idc = nalu_head[6:5];
assign forbidden_zero_bit = nalu_head[7]; 

//ebsp to rbsp
parameter
emulation_prevention_three_byte = 24'h000003;

reg competition_bytes_detect;

always @(posedge clk or negedge rst_n)
if (~rst_n)
    competition_bytes_detect <= 1'b0;
else if (ena)begin
	if (rd_req_by_rbsp_buffer_in && {last_byte1,current_byte,next_byte1}
			  == emulation_prevention_three_byte)
		competition_bytes_detect <= 1'b1;
	else if (rd_req_by_rbsp_buffer_in)
		competition_bytes_detect <= 1'b0;
end
     
assign rbsp_data_out = {next_start_bytes_detect, current_byte};
assign rbsp_valid_out = nalu_valid && !competition_bytes_detect && sps_found && (
   						nal_unit_type == 7 || nal_unit_type == 8 || nal_unit_type == 1 || nal_unit_type == 5) ;

//mem read
assign mem_rd_req_out = sps_found ? (rd_req_by_rbsp_buffer_in && ena):ena;
        
endmodule
