////////////////////////////////////////////////////////////////////////////////
//
//       This confidential and proprietary software may be used only
//     as authorized by a licensing agreement from Synopsys Inc.
//     In the event of publication, the following notice is applicable:
//
//                    (C) COPYRIGHT 1995 - 2014 SYNOPSYS INC.
//                           ALL RIGHTS RESERVED
//
//       The entire notice above must be reproduced on all authorized
//     copies.
//
// AUTHOR:    KB                 Dec. 14, 1995
//
// VERSION:   Simulation Architecture
//
// DesignWare_version: e4cb3ea1
// DesignWare_release: I-2013.12-DWBB_201312.5
//
////////////////////////////////////////////////////////////////////////////////
//-----------------------------------------------------------------------------------
//
// ABSTRACT:  Three-Stage Pipelined Multiplier
//           A_width-Bits * B_width-Bits => A_width+B_width Bits
//           Operands A and B can be either both signed (two's complement) or 
//	     both unsigned numbers. TC determines the coding of the input operands.
//           ie. TC = '1' => signed multiplication
//	         TC = '0' => unsigned multiplication
//
//
//MODIFIED : GN  Jan. 25, 1996
//            Move component from DW03 to DW02
//	Jay Zhu, Nov 29, 1999: remove unit delay and simplify procedures
//---------------------------------------------------------------------------------
// 
//      WSFDB revision control info 
//		@(#)DW02_mult_3_stage.v	1.1
//
//---------------------------------------------------------------------------------
module DW02_mult_3_stage(A,B,TC,CLK,PRODUCT);
parameter	A_width = 8;
parameter	B_width = 8;
input	[A_width-1:0]	A;
input	[B_width-1:0]	B;
input			TC,CLK;
output	[A_width+B_width-1:0]	PRODUCT;

reg	[A_width+B_width-1:0]	PRODUCT,product_piped1;
wire	[A_width+B_width-1:0]	pre_product;

wire	[A_width-1:0]	temp_a;
wire	[B_width-1:0]	temp_b;
wire	[A_width+B_width-2:0]	long_temp1,long_temp2;

assign	temp_a = (A[A_width-1])? (~A + 1'b1) : A;
assign	temp_b = (B[B_width-1])? (~B + 1'b1) : B;

assign	long_temp1 = temp_a * temp_b;
assign	long_temp2 = ~(long_temp1 - 1'b1);

assign	pre_product = (TC)? (((A[A_width-1] ^ B[B_width-1]) && (|long_temp1))?
				{1'b1,long_temp2} : {1'b0,long_temp1})
			: A * B;

always @ (posedge CLK)
begin
	product_piped1 <= pre_product;
	PRODUCT <= product_piped1;
end

endmodule

