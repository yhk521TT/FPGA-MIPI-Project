


`timescale 1ns/1ns
module uvc_top #(
parameter	MAX_HRES		    = 12'd1920,
parameter	MAX_VRES		    = 12'd1080,
parameter	HSP					= 8'd8,
parameter	HBP					= 8'd88,
parameter	HFP					= 8'd120,
parameter	VSP					= 8'd2,
parameter	VBP					= 8'd20,
parameter	VFP					= 8'd20
)
(
  input clk,
  input i_hs,
  input i_vs,
  input i_de,
  input [23:0] i_data,
  output [15:0] fx3_dq,
  output uvc_clk_HI,
  output uvc_clk_LO,
//   output [12:0] ucv_ctl
  output fx3_ctl_11,
  output fx3_ctl_12
);

// parameter	MAX_HRES		= 12'd1920;
// parameter	MAX_VRES		= 12'd1080;
// parameter	HSP				= 8'd8;
// parameter	HBP				= 8'd46;
// parameter	HFP				= 8'd46;
// parameter	VSP				= 8'd8;
// parameter	VBP				= 8'd2;
// parameter	VFP				= 8'd2;



wire [7:0] r_data;
wire [7:0] g_data;
wire [7:0] b_data;
wire hs;
wire vs;
wire de;
wire [7:0] y_444		;
wire [7:0] cb_444		;
wire [7:0] cr_444		;
wire 		 h_sync_444	;
wire 		 v_sync_444	;
wire 		 de_444		;

wire [7:0] y_422		;
wire [7:0] c_422		;
wire 	   hs_sync_422	;
wire 	   vs_sync_422	;
wire 	   de_422		;

assign uvc_clk_HI = 1'b0;
assign uvc_clk_LO = 1'b1;
assign fx3_dq = {c_422,y_422};//{fx3_dat[7:0],fx3_dat[15:8]};//{8'd0,r_data};
// assign ucv_ctl[11] = de_422;//de;//fx3_LV ;//lv;//gpio28
// assign ucv_ctl[12] = vs_sync_422;//vs;//fx3_FV;//fv ;     //gpio29
 assign fx3_ctl_11 = de_422;//de;//fx3_LV ;//lv;//gpio28
assign fx3_ctl_12 = vs_sync_422;//vs;//fx3_FV;//fv ;     //gpio29  
//----------------------------

wire i_stable;
vid_info_det vid_info_det_inst (
    .clk(clk),
    .rst_n(1'b1),
    .i_vs(i_vs),
    .i_hs(i_hs),
    .i_de(i_de),
    .frame_cnt_o(),
    .frame_stable(i_stable),
    .neg_vs_sync(),
    .neg_hs_sync(),
    .o_h_act(),
    .h_active_error(),
    .o_v_act(),
    .o_v_total(),
    .v_total_error(),
    .o_h_total(),
    .h_total_error(),
    .h_sync_error()
  );

	color_bar_rgb # (
    .DYN_EN(1'b0),
    .HS_POLORY(1'b0),
    .VS_POLORY(1'b0),
    .SYMBOL_WIDTH(8),
    .SYMBOL_NUM(3),
    .PAR_PIXEL_NUM(1),
    .HFP(HFP),
    .HST(HSP),
    .HACT(MAX_HRES),
    .HBP(HBP),
    .VFP(VFP),
    .VST(VSP),
    .VACT(MAX_VRES),
    .VBP(VBP),
    .TEST_MODE(2'd1)
  )
  color_bar_rgb_inst (
    .clk(clk),
    .rst_n(1'b1),
    .i_cfg_vid(i_cfg_vid),
    .h_cnt(h_cnt),
    .v_cnt(v_cnt),
    .hs(hs),
    .vs(vs),
    .de(de),
    .o_vid_data({r_data,g_data,b_data})
  );
	

	rgb_to_ycbcr u_rgb_to_ycbcr(
		/*i*/.clk				(clk),
		/*i*/.i_r_8b			(i_stable ? i_data[23:16]	: r_data),//(r_data),//
		/*i*/.i_g_8b			(i_stable ? i_data[15:8]	: g_data),//(g_data),//
		/*i*/.i_b_8b			(i_stable ? i_data[7:0]		: b_data),//(b_data),//
		/*i*/.i_h_sync			(i_stable ? ~i_hs			: hs),
		/*i*/.i_v_sync			(i_stable ? ~i_vs			: vs),
		/*i*/.i_data_en			(i_stable ? i_de	 		: de),
		
		/*o*/.o_y_8b			(y_444		),
		/*o*/.o_cb_8b			(cb_444		),
		/*o*/.o_cr_8b			(cr_444		),
		/*o*/.o_h_sync			(h_sync_444	),
		/*o*/.o_v_sync			(v_sync_444	),                                                                                                  
		/*o*/.o_data_en         (de_444		)                                                                                       
		);
	
	 yuv444_yuv422(
		/*i*/.sys_clk	(clk),
		/*i*/.i_hs		(h_sync_444),
		/*i*/.line_end	(),
		/*i*/.i_vs		(v_sync_444),
		/*i*/.i_de		(de_444),
		/*i*/.i_y		(y_444),
		/*i*/.i_cb		(cb_444),
		/*i*/.i_cr		(cr_444),
		/*o*/.o_hs		(hs_sync_422),
		/*o*/.o_vs		(vs_sync_422),
		/*o*/.o_de		(de_422      ),
		/*o*/.o_y		(y_422       ),
		/*o*/.o_c		(c_422       )	
	);
	





// 	img	img_u0(	

// 			.clk			(clk),//clk_25M
// 			.rst_n			(1'b1),	
// 			.rdata			(8'hF0)			,
// 			.a				(32'h50_5a_50_ef)		,
// 			.vga_rgb		(fx3_dat)	,   
// 			.vga_hsy		(fx3_LV) 	,
// 			.vga_vsy		(fx3_FV)
// );

//


endmodule


