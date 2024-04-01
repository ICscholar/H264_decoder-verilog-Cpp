//--------------------------------------------------------------------------------------------------
// Copyright (C) 2013-2017 qiu bin 
// All rights reserved   
// Design    : bitstream_p
// Author(s) : qiu bin
// Email     : chat1@126.com
// Phone 15957074161
// QQ:1517642772             
//-------------------------------------------------------------------------------------------------

module dp_ram
#(parameter DATA_WIDTH=8, parameter ADDR_WIDTH=6)
(
	input [(DATA_WIDTH-1):0] data,
	input [(ADDR_WIDTH-1):0] rdaddress, wraddress,
	input wren, rdclock, wrclock,
	output reg [DATA_WIDTH-1:0] q,
	input aclr
);
	
	reg [DATA_WIDTH-1:0] ram[2**ADDR_WIDTH-1:0];
	
	always @ (posedge wrclock)
	begin
		// Write
		if (wren)
			ram[wraddress] <= data;
	end
	
	always @ (posedge rdclock or posedge aclr)
	if (aclr)
		q <= 0;
	else
	begin
		// Read 
		q <= ram[rdaddress];
	end
	
endmodule

