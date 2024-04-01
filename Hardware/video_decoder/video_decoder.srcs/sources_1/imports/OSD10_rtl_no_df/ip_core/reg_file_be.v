//--------------------------------------------------------------------------------------------------
// Copyright (C) 2013-2017 qiu bin 
// All rights reserved   
// Design    : bitstream_p
// Author(s) : qiu bin
// Email     : chat1@126.com
// Phone 15957074161
// QQ:1517642772             
//-------------------------------------------------------------------------------------------------

module reg_file_be
#(parameter DATA_WIDTH=13, ADDR_WIDTH=5)
(
	input clk,
	input [7:0] data,
	input [ADDR_WIDTH-1:0] wr_addr,
	input wren,
	output [DATA_WIDTH*8-1:0] q
);


genvar i;
generate
for(i = 0; i <  DATA_WIDTH; i = i + 1) begin
	reg [7:0] reg_file_i;

	always @ (posedge clk)
		if (wren && i == wr_addr)
			 reg_file_i <= data;
			 
	assign q[7+i*8-:8] = reg_file_i;
end

endgenerate
			


	
endmodule
