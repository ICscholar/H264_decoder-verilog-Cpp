
module dp_ram_display
#(parameter DATA_WIDTH=8, parameter ADDR_WIDTH=6)
(
	input [(DATA_WIDTH-1):0] data,
	input [(ADDR_WIDTH-1):0] rdaddress, wraddress,
	input wren, rdclock, wrclock,
	output reg [DATA_WIDTH-1:0] q
);
	
	reg [DATA_WIDTH-1:0] ram[2**ADDR_WIDTH-1:0];
	
	always @ (posedge wrclock)
	begin
		// Write
		if (wren)
			ram[wraddress] <= data;
	end
	
	always @ (posedge rdclock)
	begin
		// Read 
		q <= ram[rdaddress];
	end
	
endmodule


