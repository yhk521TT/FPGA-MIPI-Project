/*  对比度与亮度简化算法公式，参考photoshop-matlab算法
对比度上调
    R = Average_R + 100*(R-Average_R)/(100-Contrast) + Bright;
    G = Average_G + 100*(G-Average_G)/(100-Contrast) + Bright;
    B = Average_B + 100*(B-Average_B)/(100-Contrast) + Bright;
 对比度下调   
    R= Average_R + (R - Average_R) * (100 - Contrast)/100 + Bright;
    G= Average_G + (G - Average_G) * (100 - Contrast)/100 + Bright;
    B= Average_B + (B - Average_B) * (100 - Contrast)/100 + Bright;
    
    1、由于倒数为小数，因此这里涉及到了定点数的计算。所谓定点数就是将小数位数固定，这样就会产生误差，因此我们需要选择合适的小数位数来保证误差足够小。
       以本设计为例，定点数为32位，1位整数位，31位小数位。
    2、针对不同的分辨率，需要提前配置好分辨率的倒数参数：
       parameter IamgeSize = 32'h00001945; //(1/IamgeSize)*(2^31) = 32'h00001945，1位整数位，31位小数位,IamgeSize=720*461
*/
module Contrast_Adj #(
	parameter COLOR_PLANE_WIDTH = 8, 
	parameter COLOR_PLANE_NUM = 3,  
  parameter	PIXCEL_NUM = 2        
)(
input wire 				vid_clk,          
input wire 				rst_n,           
input wire [1:0]  vid_h_sync_i,         
input wire [1:0]	vid_v_sync_i,         
input wire [1:0]  vid_de_i,            
input wire[COLOR_PLANE_WIDTH*COLOR_PLANE_NUM*PIXCEL_NUM-1:0] 	vid_data_i,     
input wire 				CONTRAST_SIG,  
input wire[7:0] 	CONTRAST,
input	wire[31:0]  invert_frame_size,

input	wire [7:0]	lumi_r,
input	wire [7:0]	lumi_g,
input	wire [7:0]	lumi_b,   
output wire [1:0]	vid_h_sync_o,       
output wire [1:0] vid_v_sync_o,       
output wire [1:0]	vid_de_o,          
output wire [COLOR_PLANE_WIDTH*COLOR_PLANE_NUM*PIXCEL_NUM-1:0]	vid_data_o
);         

wire neg_v_sync ;

reg	[31:0] r_sum = 32'd0;
reg [31:0] g_sum = 32'd0;
reg [31:0] b_sum = 32'd0; 
reg	[31:0] r_sum_r = 32'd0;
reg [31:0] g_sum_r = 32'd0;
reg [31:0] b_sum_r = 32'd0;
wire[63:0]  average_r_temp;
wire[63:0]  average_g_temp;
wire[63:0]  average_b_temp; 
reg			neg_v_sync_d1 = 1'b0;
reg			neg_v_sync_d2 = 1'b0;


reg			v_sync_r = 1'b0;
//reg	[31:0] image_size = 32'd0;
//reg	[31:0] image_size_r = 32'd0;
wire	[31:0] invert_imagesize;
//sign the frame start
always @( posedge vid_clk or negedge rst_n )
begin
		if( !rst_n ) begin
				v_sync_r <= 1'b0;
		end else begin
				v_sync_r <= vid_v_sync_i[0];
		end
end

//calculate the average data of the RGB for one frame
assign neg_v_sync = {v_sync_r,vid_v_sync_i} == 2'b10;
always @( posedge vid_clk or negedge rst_n )
begin
		if( !rst_n ) begin
				neg_v_sync_d1 <= 1'b0;
				neg_v_sync_d2 <= 1'b0;

		end else begin
				neg_v_sync_d1 <= neg_v_sync;
				neg_v_sync_d2 <= neg_v_sync_d1;

		end
end

wire [47:0]	vid_data_w ;
assign	vid_data_w[23:0] = vid_de_i[0] ? vid_data_i[23:0] : 24'd0;
assign	vid_data_w[47:24] = vid_de_i[1] ? vid_data_i[47:24] : 24'd0;

always @( posedge vid_clk or negedge rst_n )
begin
		if( !rst_n ) begin
				r_sum <= 32'd0;
				g_sum <= 32'd0;
				b_sum <= 32'd0;
				r_sum_r <= 32'd0;
				g_sum_r <= 32'd0;
				b_sum_r <= 32'd0;
		end else if( neg_v_sync ) begin
				r_sum_r <= r_sum;
				g_sum_r <= g_sum;
				b_sum_r <= b_sum;
				r_sum <= 32'd0;
				g_sum <= 32'd0;
				b_sum <= 32'd0;
		end else begin
				r_sum <= r_sum + vid_data_w[23:16] + vid_data_w[47:40];
				g_sum <= g_sum + vid_data_w[15:8] + vid_data_w[39:32];
				b_sum <= b_sum + vid_data_w[7:0] + vid_data_w[31:24]; 
		end
end     

//=======================================================
//average calculate
//=======================================================
//always @( posedge vid_clk or negedge rst_n )
//begin
//		if( !rst_n ) begin
//				image_size <= 32'd0;
//				image_size_r <= 32'd0;
//		end else if( neg_v_sync ) begin
//				image_size_r <= image_size;
//				image_size <= 32'd0;
//		end else if( vid_de_i[0] ) begin
//				image_size <= image_size + 2; 
//		end
//end 

assign average_r_temp = r_sum_r * invert_frame_size;
assign average_g_temp = g_sum_r * invert_frame_size;
assign average_b_temp = b_sum_r * invert_frame_size;
reg	[7:0] average_r = 8'd0;
reg	[7:0] average_g = 8'd0;
reg	[7:0] average_b = 8'd0;
always @( posedge vid_clk or negedge rst_n)
begin
		if( !rst_n ) begin  
				average_r <= 8'd0; 
		    average_g <= 8'd0; 
		    average_b <= 8'd0; 
		end else if( neg_v_sync_d2 ) begin
				average_r <= average_r_temp[38:31];
				average_g <= average_g_temp[38:31];
				average_b <= average_b_temp[38:31];
		end
end


reg [7:0] contrast_sel;
wire[31:0] Contrast_Recip;   
always @( posedge vid_clk or negedge rst_n )
begin
		if( !rst_n ) begin
				contrast_sel <= 8'd127;
		end else begin
				contrast_sel <= (CONTRAST_SIG==1)? (8'd127-CONTRAST):8'd127;
		end
end

Reciprocal Reciprocal(
	 .clk(vid_clk),
    .Divisor_Sel(contrast_sel),
    .Recip(Contrast_Recip)
    );
    

reg [7:0] mult_data = 8'd127;

always @( posedge vid_clk or negedge rst_n )
begin
		if( !rst_n ) begin
				mult_data <= 8'd127;
		end else if( CONTRAST_SIG ) begin
				mult_data <= 8'd127 ;
		end else begin
				mult_data <= 8'd127-CONTRAST;
		end
end

reg	[47:0] contrast_temp = 48'd0;

reg	sign_r_h = 1'b0;
reg	sign_g_h = 1'b0;
reg	sign_b_h = 1'b0;
reg	sign_r_l = 1'b0;
reg	sign_g_l = 1'b0;
reg	sign_b_l = 1'b0;
//===================================================================================
//de_i_r1 sign_b_l
//===================================================================================
always @(posedge vid_clk or negedge rst_n)
begin
		if( !rst_n ) begin
				contrast_temp[23:0] <= 24'd0; 
				sign_r_l <= 1'b0;
				sign_g_l <= 1'b0;
				sign_b_l <= 1'b0;
		end else begin
				if( vid_de_i[0] ) begin
						if( vid_data_i[7:0] > average_b ) begin
								contrast_temp[7:0] <= (vid_data_i[7:0] - average_b );
								sign_b_l <= 1'b1;
						end else begin
								contrast_temp[7:0] <= (average_b - vid_data_i[7:0] );
								sign_b_l <= 1'b0;
						end
						
						if( vid_data_i[15:8] > average_g ) begin
								contrast_temp[15:8] <= (vid_data_i[15:8] - average_g );
								sign_g_l <= 1'b1;
						end else begin
								contrast_temp[15:8] <= (average_g - vid_data_i[15:8] );
								sign_g_l <= 1'b0;
						end
						
						if( vid_data_i[23:16] > average_r ) begin
								contrast_temp[23:16] <= (vid_data_i[23:16] - average_r );
								sign_r_l <= 1'b1;
						end else begin
								contrast_temp[23:16] <= (average_r - vid_data_i[23:16] );
								sign_r_l <= 1'b0;
						end
				end 
		end
end   


always @(posedge vid_clk or negedge rst_n)
begin
		if( !rst_n ) begin
				contrast_temp[47:24] <= 24'd0; 
				sign_b_h <= 1'b0;
				sign_r_h <= 1'b0;
				sign_g_h <= 1'b0;
		end else begin
				if( vid_de_i[1] ) begin
						if( vid_data_i[31:24] > average_b ) begin
								contrast_temp[31:24] <= vid_data_i[31:24] - average_b ;
								sign_b_h <= 1'b1;
						end else begin
								contrast_temp[31:24] <= average_b - vid_data_i[31:24] ;
								sign_b_h <= 1'b0;
						end
						
						if( vid_data_i[39:32] > average_g ) begin
								contrast_temp[39:32] <= vid_data_i[39:32] - average_g ;
								sign_g_h <= 1'b1;
						end else begin
								contrast_temp[39:32] <= average_g - vid_data_i[39:32] ;
								sign_g_h <= 1'b0;
						end
						
						if( vid_data_i[47:40] > average_r ) begin
								contrast_temp[47:40] <= vid_data_i[47:40] - average_r ;
								sign_r_h <= 1'b1;
						end else begin
								contrast_temp[47:40] <= average_r - vid_data_i[47:40] ;
								sign_r_h <= 1'b0;
						end
				end 
		end
end 

//===================================================================================
//de_i_d2 sign_b_l_d1
//===================================================================================

reg	sign_r_h_d1 = 1'b0;
reg	sign_g_h_d1 = 1'b0;
reg	sign_b_h_d1 = 1'b0;
reg	sign_r_l_d1 = 1'b0;
reg	sign_g_l_d1 = 1'b0;
reg	sign_b_l_d1 = 1'b0;  
reg	sign_r_h_d1_temp = 1'b0; 
reg	sign_g_h_d1_temp = 1'b0; 
reg	sign_b_h_d1_temp = 1'b0; 
reg	sign_r_l_d1_temp = 1'b0; 
reg	sign_g_l_d1_temp = 1'b0; 
reg	sign_b_l_d1_temp = 1'b0; 

reg	[47:0] contrast_temp07_00 = 48'd0;
reg	[47:0] contrast_temp15_08 = 48'd0;
reg	[47:0] contrast_temp23_16 = 48'd0;
reg	[47:0] contrast_temp31_24 = 48'd0;
reg	[47:0] contrast_temp39_32 = 48'd0;
reg	[47:0] contrast_temp47_40 = 48'd0;  
reg [15:0] mult_temp07_00 = 16'd0;
reg [15:0] mult_temp15_08 = 16'd0;
reg [15:0] mult_temp23_16 = 16'd0;
reg [15:0] mult_temp31_24 = 16'd0;
reg [15:0] mult_temp39_32 = 16'd0;
reg [15:0] mult_temp47_40 = 16'd0;
always @( posedge vid_clk or negedge rst_n )
begin
		if( !rst_n ) begin
				mult_temp07_00 <= 16'd0;
				mult_temp15_08 <= 16'd0;
				mult_temp23_16 <= 16'd0;
				mult_temp31_24 <= 16'd0;
				mult_temp39_32 <= 16'd0;
				mult_temp47_40 <= 16'd0;
				sign_r_l_d1_temp <= 1'b0;
				sign_g_l_d1_temp <= 1'b0;
				sign_b_l_d1_temp <= 1'b0;
				sign_r_h_d1_temp <= 1'b0;
				sign_g_h_d1_temp <= 1'b0;
				sign_b_h_d1_temp <= 1'b0;
		end else begin
				mult_temp07_00 <= contrast_temp[ 7: 0] * mult_data;
				mult_temp15_08 <= contrast_temp[15: 8] * mult_data;
				mult_temp23_16 <= contrast_temp[23:16] * mult_data;
				mult_temp31_24 <= contrast_temp[31:24] * mult_data;
				mult_temp39_32 <= contrast_temp[39:32] * mult_data;
				mult_temp47_40 <= contrast_temp[47:40] * mult_data;
				
				sign_r_l_d1_temp <= sign_r_l;
				sign_g_l_d1_temp <= sign_g_l;
				sign_b_l_d1_temp <= sign_b_l;
				
				sign_r_h_d1_temp <= sign_r_h;
				sign_g_h_d1_temp <= sign_g_h;
				sign_b_h_d1_temp <= sign_b_h;
		end
end 
always @( posedge vid_clk or negedge rst_n )
begin
		if( !rst_n ) begin
				contrast_temp07_00 <= 48'd0;
				contrast_temp15_08 <= 48'd0;
				contrast_temp23_16 <= 48'd0;
				contrast_temp31_24 <= 48'd0;
				contrast_temp39_32 <= 48'd0;
				contrast_temp47_40 <= 48'd0;
				sign_r_l_d1 <= 1'b0;
				sign_g_l_d1 <= 1'b0;
				sign_b_l_d1 <= 1'b0;
				sign_r_h_d1 <= 1'b0;
				sign_g_h_d1 <= 1'b0;
				sign_b_h_d1 <= 1'b0;
		end else begin
				contrast_temp07_00 <= mult_temp07_00 * Contrast_Recip;
				contrast_temp15_08 <= mult_temp15_08 * Contrast_Recip;
				contrast_temp23_16 <= mult_temp23_16 * Contrast_Recip;
				contrast_temp31_24 <= mult_temp31_24 * Contrast_Recip;
				contrast_temp39_32 <= mult_temp39_32 * Contrast_Recip;
				contrast_temp47_40 <= mult_temp47_40 * Contrast_Recip;
				
				sign_r_l_d1 <= sign_r_l_d1_temp;
				sign_g_l_d1 <= sign_g_l_d1_temp;
				sign_b_l_d1 <= sign_b_l_d1_temp;
				
				sign_r_h_d1 <= sign_r_h_d1_temp;
				sign_g_h_d1 <= sign_g_h_d1_temp;
				sign_b_h_d1 <= sign_b_h_d1_temp;
		end
end 


//===================================================================================
//de_i_d3 sign_b_l_d2
//===================================================================================
wire [8:0] contrast_tmp07_00;
wire [8:0] contrast_tmp15_08;
wire [8:0] contrast_tmp23_16;
wire [8:0] contrast_tmp31_24;
wire [8:0] contrast_tmp39_32;
wire [8:0] contrast_tmp47_40;



reg [8:0] contrast_add07_00 = 8'd0;
reg [8:0] contrast_sub07_00 = 8'd0;
reg [8:0] contrast_add15_08 = 8'd0;
reg [8:0] contrast_sub15_08 = 8'd0;
reg [8:0] contrast_add23_16 = 8'd0;
reg [8:0] contrast_sub23_16 = 8'd0;
reg [8:0] contrast_add31_24 = 8'd0;
reg [8:0] contrast_sub31_24 = 8'd0;
reg [8:0] contrast_add39_32 = 8'd0;
reg [8:0] contrast_sub39_32 = 8'd0;
reg [8:0] contrast_add47_40 = 8'd0;
reg [8:0] contrast_sub47_40 = 8'd0;
reg sign_r_l_d2 = 1'b0;
reg sign_g_l_d2 = 1'b0;
reg sign_b_l_d2 = 1'b0;
reg sign_r_h_d2 = 1'b0;
reg sign_g_h_d2 = 1'b0;
reg sign_b_h_d2 = 1'b0;
always @( posedge vid_clk or negedge rst_n )
begin
		if( !rst_n ) begin
				sign_r_l_d2 <= 1'b0;
				sign_g_l_d2 <= 1'b0;
				sign_b_l_d2 <= 1'b0;
				sign_r_h_d2 <= 1'b0;
				sign_g_h_d2 <= 1'b0;
				sign_b_h_d2 <= 1'b0;
		end else begin
				sign_r_l_d2 <= sign_r_l_d1;
				sign_g_l_d2 <= sign_g_l_d1;
				sign_b_l_d2 <= sign_b_l_d1;
				sign_r_h_d2 <= sign_r_h_d1;
				sign_g_h_d2 <= sign_g_h_d1;
				sign_b_h_d2 <= sign_b_h_d1;
		end
end 

always @( posedge vid_clk or negedge rst_n )
begin
		if( !rst_n ) begin
			  contrast_add07_00[8:0] <= 9'd0;
			  contrast_sub07_00[8:0] <= 9'd0;
			  contrast_add15_08[8:0] <= 9'd0;
			  contrast_sub15_08[8:0] <= 9'd0;
			  contrast_add23_16[8:0] <= 9'd0;
			  contrast_sub23_16[8:0] <= 9'd0;
			  contrast_add31_24[8:0] <= 9'd0;
			  contrast_sub31_24[8:0] <= 9'd0;
			  contrast_add39_32[8:0] <= 9'd0;
			  contrast_sub39_32[8:0] <= 9'd0;
			  contrast_add47_40[8:0] <= 9'd0;
			  contrast_sub47_40[8:0] <= 9'd0;
			  
		end else  begin
				contrast_add07_00[8:0] <= {1'b0,average_b} + contrast_tmp07_00 ;
				contrast_sub07_00[8:0] <= {1'b0,average_b} - contrast_tmp07_00 ;
				contrast_add15_08[8:0] <= {1'b0,average_g} + contrast_tmp15_08 ;
				contrast_sub15_08[8:0] <= {1'b0,average_g} - contrast_tmp15_08 ;
				contrast_add23_16[8:0] <= {1'b0,average_r} + contrast_tmp23_16 ;
				contrast_sub23_16[8:0] <= {1'b0,average_r} - contrast_tmp23_16 ;
				contrast_add31_24[8:0] <= {1'b0,average_b} + contrast_tmp31_24 ;
				contrast_sub31_24[8:0] <= {1'b0,average_b} - contrast_tmp31_24 ;
				contrast_add39_32[8:0] <= {1'b0,average_g} + contrast_tmp39_32 ;
				contrast_sub39_32[8:0] <= {1'b0,average_g} - contrast_tmp39_32 ;
				contrast_add47_40[8:0] <= {1'b0,average_r} + contrast_tmp47_40 ;
				contrast_sub47_40[8:0] <= {1'b0,average_r} - contrast_tmp47_40 ;
				
		end
end     
assign contrast_tmp07_00 = (|contrast_temp07_00[47:39]) ? 9'h0ff : {1'b0,contrast_temp07_00[38:31]} + contrast_temp07_00[30];
assign contrast_tmp15_08 = (|contrast_temp15_08[47:39]) ? 9'h0ff : {1'b0,contrast_temp15_08[38:31]} + contrast_temp15_08[30];
assign contrast_tmp23_16 = (|contrast_temp23_16[47:39]) ? 9'h0ff : {1'b0,contrast_temp23_16[38:31]} + contrast_temp23_16[30];
assign contrast_tmp31_24 = (|contrast_temp31_24[47:39]) ? 9'h0ff : {1'b0,contrast_temp31_24[38:31]} + contrast_temp31_24[30];
assign contrast_tmp39_32 = (|contrast_temp39_32[47:39]) ? 9'h0ff : {1'b0,contrast_temp39_32[38:31]} + contrast_temp39_32[30];
assign contrast_tmp47_40 = (|contrast_temp47_40[47:39]) ? 9'h0ff : {1'b0,contrast_temp47_40[38:31]} + contrast_temp47_40[30];


//===================================================================================
//de_i_d3 sign_b_l_d3
//===================================================================================
reg [1:0] vid_de_d1 		= 2'd0;
reg [1:0] vid_h_sync_d1 = 2'd0;
reg [1:0] vid_v_sync_d1 = 2'd0;
                  
reg [1:0] vid_de_d2 		= 2'd0;
reg [1:0] vid_h_sync_d2 = 2'd0;
reg [1:0] vid_v_sync_d2 = 2'd0;
                  
reg [1:0] vid_de_d3 		= 2'd0;
reg [1:0] vid_h_sync_d3 = 2'd0;
reg [1:0] vid_v_sync_d3 = 2'd0;   

reg [1:0] vid_de_d4 		= 2'd0;
reg [1:0] vid_h_sync_d4 = 2'd0;
reg [1:0] vid_v_sync_d4 = 2'd0;

reg [1:0] vid_de_d5 		= 2'd0;
reg [1:0] vid_h_sync_d5 = 2'd0;
reg [1:0] vid_v_sync_d5 = 2'd0;    

reg [1:0] vid_de_d6 		= 2'd0;
reg [1:0] vid_h_sync_d6 = 2'd0;
reg [1:0] vid_v_sync_d6 = 2'd0;    

reg [1:0] vid_de_d7 		= 2'd0; 
reg [1:0] vid_h_sync_d7 = 2'd0; 
reg [1:0] vid_v_sync_d7 = 2'd0; 
always @( posedge vid_clk or negedge rst_n ) 
begin
		if( !rst_n ) begin
				vid_de_d1 <= 2'd0;
				vid_h_sync_d1 <= 2'd0;
				vid_v_sync_d1 <= 2'd0;
				vid_de_d2 <= 2'd0;
				vid_h_sync_d2 <= 2'd0;
				vid_v_sync_d2 <= 2'd0;
				vid_de_d3 <= 2'd0;
				vid_h_sync_d3 <= 2'd0;
				vid_v_sync_d3 <= 2'd0;
				
				vid_de_d4 <= 2'd0;
				vid_h_sync_d4 <= 2'd0;
				vid_v_sync_d4 <= 2'd0;
				
				vid_de_d5 <= 2'd0;
				vid_h_sync_d5 <= 2'd0;
				vid_v_sync_d5 <= 2'd0; 
				
				vid_de_d6 <= 2'd0;    
				vid_h_sync_d6 <= 2'd0;
				vid_v_sync_d6 <= 2'd0;   
				
				vid_de_d7 <= 2'd0;    
				vid_h_sync_d7 <= 2'd0;
				vid_v_sync_d7 <= 2'd0;
		end else begin
				vid_de_d1 		<= vid_de_i;
				vid_h_sync_d1 <= vid_h_sync_i;
				vid_v_sync_d1 <= vid_v_sync_i;
				
				vid_de_d2 		<= vid_de_d1;
				vid_h_sync_d2 <= vid_h_sync_d1;
				vid_v_sync_d2 <= vid_v_sync_d1;
				
				vid_de_d3 		<= vid_de_d2;
				vid_h_sync_d3 <= vid_h_sync_d2;
				vid_v_sync_d3 <= vid_v_sync_d2;
				
				vid_de_d4 		<= vid_de_d3;    
				vid_h_sync_d4 <= vid_h_sync_d3;
				vid_v_sync_d4 <= vid_v_sync_d3;
				
				vid_de_d5 		<= vid_de_d4;    
				vid_h_sync_d5 <= vid_h_sync_d4;
				vid_v_sync_d5 <= vid_v_sync_d4;  
				
				vid_de_d6 		<= vid_de_d5;    
				vid_h_sync_d6 <= vid_h_sync_d5;
				vid_v_sync_d6 <= vid_v_sync_d5; 
				
				vid_de_d7 		<= vid_de_d6;     
				vid_h_sync_d7 <= vid_h_sync_d6; 
				vid_v_sync_d7 <= vid_v_sync_d6; 
		end
end
reg [7:0] rgb_data07_00 = 8'h40;
reg [7:0] rgb_data15_08 = 8'h40;
reg [7:0] rgb_data23_16 = 8'h40; 
reg [7:0] rgb_data31_24 = 8'h40;
reg [7:0] rgb_data39_32 = 8'h40;
reg [7:0] rgb_data47_40 = 8'h40;
always @( posedge vid_clk or negedge rst_n )
begin
		if( !rst_n ) begin
				rgb_data07_00 <= 8'h40;
				rgb_data15_08 <= 8'h40;
				rgb_data23_16 <= 8'h40; 
		end else if( vid_de_d3[0] ) begin
				if( sign_b_l_d2 ) begin
						if(  contrast_add07_00[8] ) begin
							  rgb_data07_00 <= 8'hff;
						end else begin
								rgb_data07_00 <= contrast_add07_00[7:0]; 
						end
				end else begin
				    if( contrast_sub07_00[8] ) begin
				    		rgb_data07_00 <= 8'h00; 
				    end else begin
				        rgb_data07_00 <= contrast_sub07_00[7:0];
				    end
				end 
				if( sign_g_l_d2 ) begin
						if(  contrast_add15_08[8] ) begin
							  rgb_data15_08 <= 8'hff;
						end else begin
								rgb_data15_08 <= contrast_add15_08[7:0]; 
						end
				end else begin
				    if( contrast_sub15_08[8] ) begin
				    		rgb_data15_08 <= 8'h00; 
				    end else begin
				        rgb_data15_08 <= contrast_sub15_08[7:0];
				    end
				end 
				if( sign_r_l_d2 ) begin
						if(  contrast_add23_16[8] ) begin
							  rgb_data23_16 <= 8'hff;
						end else begin
								rgb_data23_16 <= contrast_add23_16[7:0]; 
						end
				end else begin
				    if( contrast_sub23_16[8] ) begin
				    		rgb_data23_16 <= 8'h00; 
				    end else begin
				        rgb_data23_16 <= contrast_sub23_16[7:0];
				    end
				end 
		end 
end
always @( posedge vid_clk or negedge rst_n )
begin
		if( !rst_n ) begin
				rgb_data31_24 <= 8'h40;             
				rgb_data39_32 <= 8'h40;             
				rgb_data47_40 <= 8'h40;             
		end else if( vid_de_d3[1] ) begin               
				if( sign_b_h_d2 ) begin
						if(  contrast_add31_24[8] ) begin
							  rgb_data31_24 <= 8'hff;
						end else begin
								rgb_data31_24 <= contrast_add31_24[7:0]; 
						end
				end else begin
				    if( contrast_sub31_24[8] ) begin
				    		rgb_data31_24 <= 8'h00; 
				    end else begin
				        rgb_data31_24 <= contrast_sub31_24[7:0];
				    end
				end 
				if( sign_g_h_d2 ) begin
						if(  contrast_add39_32[8] ) begin
							  rgb_data39_32 <= 8'hff;
						end else begin
								rgb_data39_32 <= contrast_add39_32[7:0]; 
						end
				end else begin
				    if( contrast_sub39_32[8] ) begin
				    		rgb_data39_32 <= 8'h00; 
				    end else begin
				        rgb_data39_32 <= contrast_sub39_32[7:0];
				    end
				end 
				if( sign_r_h_d2 ) begin
						if(  contrast_add47_40[8] ) begin
							  rgb_data47_40 <= 8'hff;
						end else begin
								rgb_data47_40 <= contrast_add47_40[7:0]; 
						end
				end else begin
				    if( contrast_sub47_40[8] ) begin
				    		rgb_data47_40 <= 8'h00; 
				    end else begin
				        rgb_data47_40 <= contrast_sub47_40[7:0];
				    end
				end 
		end 
end
//===========================================================================
//
//===========================================================================  
reg [15:0] bright_temp07_00 ;
reg [15:0] bright_temp15_08 ;
reg [15:0] bright_temp23_16 ;
reg [15:0] bright_temp31_24 ;
reg [15:0] bright_temp39_32 ;
reg [15:0] bright_temp47_40 ;  

//wire [15:0] bright_temp_w07_00 ;
//wire [15:0] bright_temp_w15_08 ;
//wire [15:0] bright_temp_w23_16 ;
//wire [15:0] bright_temp_w31_24 ;
//wire [15:0] bright_temp_w39_32 ;
//wire [15:0] bright_temp_w47_40 ;

reg [7:0] rgb_out07_00 ;
reg [7:0] rgb_out15_08 ;
reg [7:0] rgb_out23_16 ;
reg [7:0] rgb_out31_24 ;
reg [7:0] rgb_out39_32 ;
reg [7:0] rgb_out47_40 ;

always @( posedge vid_clk )
begin
	bright_temp07_00 <=	rgb_data07_00 * lumi_b;
	bright_temp15_08 <=	rgb_data15_08 * lumi_g;
	bright_temp23_16 <=	rgb_data23_16 * lumi_r;
	bright_temp31_24 <=	rgb_data31_24 * lumi_b;
	bright_temp39_32 <=	rgb_data39_32 * lumi_g;
	bright_temp47_40 <=	rgb_data47_40 * lumi_r;
end


//assign bright_temp07_00 = rgb_data07_00 * lumi_b;  
//assign bright_temp15_08 = rgb_data15_08 * lumi_g;
//assign bright_temp23_16 = rgb_data23_16 * lumi_r;
//assign bright_temp31_24 = rgb_data31_24 * lumi_b;
//assign bright_temp39_32 = rgb_data39_32 * lumi_g;
//assign bright_temp47_40 = rgb_data47_40 * lumi_r;

always @( posedge vid_clk )
begin//protect the bright_temp[14:7] == 255 and the bright_temp[6] == 1 
		if( bright_temp07_00[15] || (&bright_temp07_00[14:7]) ) begin
		    rgb_out07_00 <= 8'hff; 
		end else begin 
				rgb_out07_00 <= bright_temp07_00[14:7] + bright_temp07_00[6];
		end
		
		if( bright_temp15_08[15] || (&bright_temp15_08[14:7]) ) begin
		    rgb_out15_08 <= 8'hff; 
		end else begin 
				rgb_out15_08 <= bright_temp15_08[14:7] + bright_temp15_08[6];
		end
		
		if( bright_temp23_16[15] || (&bright_temp23_16[14:7]) ) begin
		    rgb_out23_16 <= 8'hff; 
		end else begin 
				rgb_out23_16 <= bright_temp23_16[14:7] + bright_temp23_16[6];
		end
		
		if( bright_temp31_24[15] || (&bright_temp31_24[14:7]) ) begin
		    rgb_out31_24 <= 8'hff; 
		end else begin 
				rgb_out31_24 <= bright_temp31_24[14:7] + bright_temp31_24[6];
		end
		
		if( bright_temp39_32[15] || (&bright_temp39_32[14:7]) ) begin
		    rgb_out39_32 <= 8'hff; 
		end else begin 
				rgb_out39_32 <= bright_temp39_32[14:7] + bright_temp39_32[6];
		end
		
		if( bright_temp47_40[15] || (&bright_temp47_40[14:7]) ) begin
		    rgb_out47_40 <= 8'hff; 
		end else begin 
				rgb_out47_40 <= bright_temp47_40[14:7] + bright_temp47_40[6];
		end
end


assign vid_data_o = {rgb_out47_40,rgb_out39_32,rgb_out31_24,rgb_out23_16,rgb_out15_08,rgb_out07_00};
assign vid_de_o = vid_de_d7 ;
assign vid_h_sync_o = vid_h_sync_d7;
assign vid_v_sync_o = vid_v_sync_d7;


endmodule