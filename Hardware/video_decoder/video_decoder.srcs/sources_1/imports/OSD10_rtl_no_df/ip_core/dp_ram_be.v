//--------------------------------------------------------------------------------------------------
// Copyright (C) 2013-2017 qiu bin 
// All rights reserved   
// Design    : bitstream_p
// Author(s) : qiu bin
// Email     : chat1@126.com
// Phone 15957074161
// QQ:1517642772             
//-------------------------------------------------------------------------------------------------

module dp_ram_be
#(parameter DATA_WIDTH=3, parameter ADDR_WIDTH=5)
(
	input [7:0] data,
	input [(ADDR_WIDTH-1):0] rdaddress, wraddress,
	input wren, rdclock, wrclock,
	output reg [DATA_WIDTH*8-1:0] q,
	input [DATA_WIDTH-1:0] be
);


reg [DATA_WIDTH*8-1:0] ram0[(1<<ADDR_WIDTH)-1:0];

integer i;
	always @ (posedge wrclock)
	for(i = 0; i < DATA_WIDTH; i = i + 1) begin
		if (wren && be[i])
			ram0[wraddress][7+i*8-:8] <= data;
	end
				

always @ (posedge rdclock)
	q <= ram0[rdaddress];
	
endmodule


