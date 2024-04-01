//--------------------------------------------------------------------------------------------------
// Copyright (C) 2013-2017 qiu bin 
// All rights reserved   
// Design    : bitstream_p
// Author(s) : qiu bin
// Email     : chat1@126.com
// Phone 15957074161
// QQ:1517642772             
//-------------------------------------------------------------------------------------------------


`include "defines.v"

module transform_fsm(
	input clk,
	input rst_n,
	input ena,
	input start,

	input [4:0] TotalCoeff,
	input [3:0] residual_state,	
	input [3:0] luma4x4BlkIdx_residual,
	input [1:0] chroma4x4BlkIdx_residual,
	
	output reg [3:0] DC_rd_idx,
	output reg regs_out_sel,
	output reg itrans_col_mode,
	output reg regs_col_mode,
	output reg DHT_sel,
	output reg DHT_wr,
	output reg IQ_wr,
	output reg IDCT_wr,
	output reg DC_regs_wr,
	output reg AC_all_0_wr,
	output reg valid
);

reg [4:0] total_counter;
reg is_AC_all_0;

always @(*)
if (residual_state == `Intra16x16ACLevel_s ||
	residual_state == `LumaLevel_s ||
	residual_state == `ChromaACLevel_Cb_s ||
	residual_state == `ChromaACLevel_Cr_s) begin
	if (TotalCoeff == 0)
		is_AC_all_0 <= 1'b1;
	else
		is_AC_all_0 <= 1'b0;
end
else if (residual_state != `Intra16x16DCLevel_s &&
		 residual_state != `ChromaDCLevel_Cb_s &&
		 residual_state != `ChromaDCLevel_Cr_s) begin
	is_AC_all_0 <= 1'b1;
end
else begin
	is_AC_all_0 <= 1'b0;
end

parameter
DHTClocks  = 6,
DHT2Clocks = 2,
IQClocks   = 3,
IQ2Clocks  = 3,
IDCTClocks = 6;

//route1
//LumaDC
//clock 0 -- DHTClocks-1:DHT,
//clock DHTClocks -- DHTClocks+IQClocks-1:IQ

//route2
//ChromaDC
//clock 0 -- DHT2Clocks-1:DHT2,
//clock DHT2Clocks -- DHT2Clocks+IQClocks-1:IQ

//route3
//AC,Luma4x4
//clock 0 -- IQClocks-1:IQ,
//clock IQClocks -- IQClocks+IDCTClocks-1:IDCT

//route4
//all0 block
//clock 0 i

always @(posedge clk or negedge rst_n)
if (~rst_n) begin
	total_counter <= 0;
	valid <= 0;
end
else if (ena) begin
	if (start) begin
		total_counter <= 1;
		valid <= 0;
	end
	else if (is_AC_all_0 && total_counter > 0) begin
		valid <= 1'b1;
		total_counter <= 0;
	end
	else if (total_counter > 0)begin
		if (residual_state == `Intra16x16DCLevel_s &&
		   	total_counter < DHTClocks + IQClocks - 1)
			total_counter <= total_counter + 1'b1;
		else if ((residual_state == `ChromaDCLevel_Cb_s || 
			residual_state == `ChromaDCLevel_Cr_s) && 
		   	total_counter < DHT2Clocks + IQ2Clocks -1)
			total_counter <= total_counter + 1'b1;
		else if ((residual_state == `Intra16x16ACLevel_s ||
		          residual_state == `LumaLevel_s ||
			      residual_state == `ChromaACLevel_Cb_s ||
			      residual_state == `ChromaACLevel_Cr_s) &&
		          total_counter < IQClocks + IDCTClocks - 1)
			total_counter <= total_counter + 1'b1;
		else begin
			valid <= 1'b1;
			total_counter <= 0;
		end
	end
end

always @(posedge clk or negedge rst_n)
if (~rst_n)
	AC_all_0_wr <= 0;
else if (ena) begin
	AC_all_0_wr <= start && total_counter == 0 && is_AC_all_0;
end

always @(posedge clk or negedge rst_n)
if (~rst_n)
	regs_out_sel <= 0;
else if (residual_state == `Intra16x16DCLevel_s) begin
	case (total_counter)
	2,5:regs_out_sel <= 1;
	default:regs_out_sel <= 0;
	endcase
end
else if (residual_state == `ChromaDCLevel_Cb_s ||
         residual_state == `ChromaDCLevel_Cr_s) begin
	case (total_counter)
	2:regs_out_sel <= 1;
	default:regs_out_sel <= 0;
	endcase
end
else if (residual_state == `Intra16x16ACLevel_s ||
         residual_state == `LumaLevel_s ||
	     residual_state == `ChromaACLevel_Cb_s ||
	     residual_state == `ChromaACLevel_Cr_s) begin
	case (total_counter)
	2,5:regs_out_sel <= 1;
	default:regs_out_sel <= 0;
	endcase
end

always @(posedge clk or negedge rst_n)
if (~rst_n)
	itrans_col_mode <= 0;
else if (residual_state == `Intra16x16DCLevel_s) begin
	case (total_counter)
	2:itrans_col_mode <= 1;
	default:itrans_col_mode <= 0;
	endcase
end
else if (residual_state == `Intra16x16ACLevel_s ||
         residual_state == `LumaLevel_s ||
	     residual_state == `ChromaACLevel_Cb_s ||
	     residual_state == `ChromaACLevel_Cr_s) begin
	case (total_counter)
	5:itrans_col_mode <= 1;
	default:itrans_col_mode <= 0;
	endcase
end

always @(posedge clk or negedge rst_n)
if (~rst_n)
	regs_col_mode <= 0;
else if (residual_state == `Intra16x16DCLevel_s) begin
	case (total_counter)
	4:regs_col_mode <= 1;
	default:regs_col_mode <= 0;
	endcase
end
else if (residual_state == `Intra16x16ACLevel_s ||
         residual_state == `LumaLevel_s ||
	     residual_state == `ChromaACLevel_Cb_s ||
	     residual_state == `ChromaACLevel_Cr_s) begin
	case (total_counter)
	7:regs_col_mode <= 1;
	default:regs_col_mode <= 0;
	endcase
end

always @(posedge clk or negedge rst_n)
if (~rst_n)begin
	DHT_wr <= 0;
end
else if (residual_state == `Intra16x16DCLevel_s) begin
	case (total_counter)
	1,4:DHT_wr <= 1;
	default:DHT_wr <= 0;
	endcase
end
else if (residual_state == `ChromaDCLevel_Cb_s ||
         residual_state == `ChromaDCLevel_Cr_s) begin
	case (total_counter)
	1:DHT_wr <= 1;
	default:DHT_wr <= 0;
	endcase
end

always @(posedge clk or negedge rst_n)
if (~rst_n)begin
	IQ_wr <= 0;
end
else if ((residual_state == `Intra16x16ACLevel_s ||
         residual_state == `LumaLevel_s ||
	     residual_state == `ChromaACLevel_Cb_s ||
	     residual_state == `ChromaACLevel_Cr_s) && TotalCoeff != 0) begin
	case (total_counter)
	1:IQ_wr <= 1;
	default:IQ_wr <= 0;
	endcase
end

always @(posedge clk or negedge rst_n)
if (~rst_n)begin
	IDCT_wr <= 0;
end
else if ((residual_state == `Intra16x16ACLevel_s ||
         residual_state == `LumaLevel_s ||
	     residual_state == `ChromaACLevel_Cb_s ||
	     residual_state == `ChromaACLevel_Cr_s) && TotalCoeff != 0) begin
	case (total_counter)
	4,7:IDCT_wr <= 1;
	default:IDCT_wr <= 0;
	endcase
end

always @(posedge clk or negedge rst_n)
if (~rst_n)begin
	DHT_sel <= 0;
end
else if (residual_state == `Intra16x16DCLevel_s ||
         residual_state == `ChromaDCLevel_Cb_s ||
	     residual_state == `ChromaDCLevel_Cr_s) begin
	DHT_sel <= 1;
end
else begin
	DHT_sel <= 0;
end

always @(posedge clk or negedge rst_n)
if (~rst_n)begin
	DC_regs_wr <= 0;
end
else if (residual_state == `Intra16x16DCLevel_s) begin
	case (total_counter)
	7:DC_regs_wr <= 1;
	default:DC_regs_wr <= 0;
	endcase
end
else if (residual_state == `ChromaDCLevel_Cb_s ||
	     residual_state == `ChromaDCLevel_Cr_s) begin
	case (total_counter)
	4:DC_regs_wr <= 1;
	default:DC_regs_wr <= 0;
	endcase
end
//-----------------
//DC_rd_idx      
//-----------------  
always @(posedge clk or negedge rst_n)
if (~rst_n) begin
	DC_rd_idx <= 0;
end
else if (ena) begin
	if(residual_state == `Intra16x16ACLevel_s || residual_state == `Intra16x16ACLevel_0_s)
		DC_rd_idx <= luma4x4BlkIdx_residual;
	else if (residual_state == `ChromaACLevel_Cb_s || residual_state == `ChromaACLevel_Cb_0_s )
		DC_rd_idx <= {2'b00,chroma4x4BlkIdx_residual};
	else if (residual_state == `ChromaACLevel_Cr_s || residual_state == `ChromaACLevel_Cr_0_s)
		DC_rd_idx <= {2'b01,chroma4x4BlkIdx_residual};
	else
        DC_rd_idx <= 0;
end

endmodule

