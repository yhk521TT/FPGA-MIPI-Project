//=================================================================
//
//  Copyright (C) 2022 Persion All rights reserved.
//  文件名称：top.v
//  创 建 者：Ramsey Wang
//  创建日期：2022.04.01
//  描    述：hdmi_top
//
//=================================================================


module hdmi_top
(


    ////////////////////////    CLOCK & PLL     ////////////////////////
	input hdmi_tx_locked,
    input hdmi_tx_slow_clk,
  input 		i_hs,
  input 		i_vs,
  input 		i_de,
  input [7:0] i_rdata,
  input [7:0] i_gdata,
  input [7:0] i_bdata,

    output [9:0]tmds_data0_o ,
    output [9:0]tmds_data1_o ,
    output [9:0]tmds_data2_o ,
    output [9:0]tmds_clk_o   ,

    output tmds_data0_TX_OE,
    output tmds_data1_TX_OE,
    output tmds_data2_TX_OE,
    output tmds_clk_TX_OE,
	output tmds_data0_TX_RST,
	output tmds_data1_TX_RST,
	output tmds_data2_TX_RST,
	output tmds_clk_TX_RST

);

//=====================================================================================
//localpram
//=====================================================================================
	parameter	MAX_HRES		= 12'd1920;
	parameter	MAX_VRES		= 12'd1536;
	parameter	HSP				= 8'd2;
	parameter	HBP				= 8'd88;
	parameter	HFP				= 8'd120;
	parameter	VSP				= 8'd2;
	parameter	VBP				= 8'd20;
	parameter	VFP				= 8'd20;


  
//=====================================================================================
//hdmi demo
//=====================================================================================
wire                            video_hs;
wire                            video_vs;
wire                            video_de;
wire[7:0]                       video_r;
wire[7:0]                       video_g;
wire[7:0]                       video_b;
wire   							sys_rst_n;
//=====================================================================================
//rest-n
//=====================================================================================

 reset
	#(
		.IN_RST_ACTIVE	("LOW"),
		.OUT_RST_ACTIVE	("LOW"),
		.CYCLE			(3)
	)
	inst_rx_byteclk_rst
	(
		.i_arst	(hdmi_tx_locked),
		.i_clk	(hdmi_tx_slow_clk),
		.o_srst	(sys_rst_n)
	);

//=====================================================================================
//hdmi demo
//=====================================================================================
wire [9:0] tmds_data0;
wire [9:0] tmds_data1;
wire [9:0] tmds_data2;
wire [9:0] tmds_clk ;


assign tmds_data0_TX_OE = 1'b1;
assign tmds_data1_TX_OE = 1'b1;
assign tmds_data2_TX_OE = 1'b1;
assign tmds_clk_TX_OE   = 1'b1;

assign tmds_data0_TX_RST = 1'b0;
assign tmds_data1_TX_RST = 1'b0;
assign tmds_data2_TX_RST = 1'b0;
assign tmds_clk_TX_RST   = 1'b0;

wire i_stable;
vid_info_det vid_info_det_inst (
    .clk(hdmi_tx_slow_clk),
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
    .HS_POLORY(1'b1),
    .VS_POLORY(1'b1),
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
    .clk(hdmi_tx_slow_clk),
    .rst_n(1'b1),
    .i_cfg_vid(i_cfg_vid),
    .h_cnt(h_cnt),
    .v_cnt(v_cnt),
    .hs(video_hs),
    .vs(video_vs),
    .de(video_de),
    .o_vid_data({video_r,video_g,video_b})
  );

dvi_encoder dvi_encoder_m0
(
	.pixelclk      (hdmi_tx_slow_clk        ),// system clock
	.rstin         (~sys_rst_n         ),// reset
	//hdmi tx
	.blue_din      (i_stable ? i_bdata:video_b	 ),//(video_b	),    //  
	.green_din     (i_stable ? i_gdata:video_g	 ),//(video_g	),    //  
	.red_din       (i_stable ? i_rdata:video_r	 ),//(video_r	),    //  
	.hsync         (i_stable ? i_hs   :video_hs  ),// (video_hs ),    //  
	.vsync         (i_stable ? i_vs   :video_vs  ),// (video_vs ),    //  
	.de            (i_stable ? i_de   :video_de  ),// (video_de ),    //
	
    .tmds_data0    (tmds_data0),
    .tmds_data1    (tmds_data1),
    .tmds_data2    (tmds_data2),
    .tmds_clk      (tmds_clk  )
);
   
assign tmds_clk_o =  tmds_clk;
assign tmds_data0_o = tmds_data0;
assign tmds_data1_o = tmds_data1;
assign tmds_data2_o = tmds_data2;


  
 
endmodule
