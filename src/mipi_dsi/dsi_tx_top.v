
module dsi_tx_top #(
parameter	HACT		    = 12'd1920,
parameter	VACT			= 12'd1080,
parameter	HSP				= 8'd2,
parameter	HBP				= 8'd88,
parameter	HFP				= 8'd120,
parameter	VSP				= 8'd2,
parameter	VBP				= 8'd20,
parameter	VFP				= 8'd20
)
(
                          input  rst_n ,
   input i_mipi_clk,
   input i_mipi_tx_pclk,
   input i_sysclk,
   input i_sysclk_div_2,

   input pixel_vs_i,
   input pixel_hs_i,
   input pixel_de_i,
   input [63:0] pixel_data_i,
   output pixel_data_en,

   input        mipi_dp_data0_LP_N_IN,
   input        mipi_dp_data0_LP_P_IN,
   output LCD_POWER,
   output LCD_RST_P,
   output       mipi_dp_clk_HS_OE,
   output [7:0] mipi_dp_clk_HS_OUT,
   output       mipi_dp_clk_LP_N_OE,
   output       mipi_dp_clk_LP_N_OUT,
   output       mipi_dp_clk_LP_P_OE,
   output       mipi_dp_clk_LP_P_OUT,
   output       mipi_dp_clk_RST,
   output       mipi_dp_data0_HS_OE,
   output [7:0] mipi_dp_data0_HS_OUT,
   output       mipi_dp_data0_LP_N_OE,
   output       mipi_dp_data0_LP_N_OUT,
   output       mipi_dp_data0_LP_P_OE,
   output       mipi_dp_data0_LP_P_OUT,
   output       mipi_dp_data0_RST,
   output       mipi_dp_data1_HS_OE,
   output [7:0] mipi_dp_data1_HS_OUT,
   output       mipi_dp_data1_LP_N_OE,
   output       mipi_dp_data1_LP_N_OUT,
   output       mipi_dp_data1_LP_P_OE,
   output       mipi_dp_data1_LP_P_OUT,
   output       mipi_dp_data1_RST,
   output       mipi_dp_data2_HS_OE,
   output [7:0] mipi_dp_data2_HS_OUT,
   output       mipi_dp_data2_LP_N_OE,
   output       mipi_dp_data2_LP_N_OUT,
   output       mipi_dp_data2_LP_P_OE,
   output       mipi_dp_data2_LP_P_OUT,
   output       mipi_dp_data2_RST,
   output       mipi_dp_data3_HS_OE,
   output [7:0] mipi_dp_data3_HS_OUT,
   output       mipi_dp_data3_LP_N_OE,
   output       mipi_dp_data3_LP_N_OUT,
   output       mipi_dp_data3_LP_P_OE,
   output       mipi_dp_data3_LP_P_OUT,
   output       mipi_dp_data3_RST
);





////////////////////////////////////////////////////////////////
// signal 

reg 	r_rstn_video;
reg		[25:0]	r_rst_cnt;

////////////////////////////////////////////////////////////////
// DSI Tx AXI
wire	[31:0]	w_axi_rdata;
wire			w_axi_awready;
wire			w_axi_wready;
wire			w_axi_arready;
wire			w_axi_rvalid;
wire			w_axi_bvalid;

wire	[6:0]	w_axi_awaddr;
wire			w_axi_awvalid;
wire	[31:0]	w_axi_wdata;
wire			w_axi_wvalid;
wire			w_axi_bready;
wire	[6:0]	w_axi_araddr;
wire			w_axi_arvalid;
wire			w_axi_rready;

wire			w_confdone;

////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////




assign	mipi_dp_clk_RST		= ~rst_n;//i_arstn;
assign	mipi_dp_data0_RST	= ~rst_n;//i_arstn;
assign	mipi_dp_data1_RST	= ~rst_n;//i_arstn;
assign	mipi_dp_data2_RST	= ~rst_n;//i_arstn;
assign	mipi_dp_data3_RST	= ~rst_n;//i_arstn;
assign  LCD_POWER 			= 1'b1;//i_arstn;


////////////////////////////////////////////////////////////////

always@(posedge i_mipi_clk or  negedge rst_n)
begin
	if ( !rst_n ) begin
		r_rst_cnt	<= 'd0;
	end else if(~r_rst_cnt[25]) begin		
		r_rst_cnt	<= r_rst_cnt + 1'b1;
			
	end
end
assign	LCD_RST_P	= ~rst_n;//~r_rst_cnt[25];//
wire axi_rst_n = r_rst_cnt[25];

reg [26:0] dly_cnt = 'd0;

wire vid_rst_n;
always @( posedge i_sysclk_div_2 or negedge rst_n )
begin
	if( !rst_n )
		dly_cnt <= 'd0;
	else if( w_confdone )
		dly_cnt <= dly_cnt[26] ? dly_cnt :(dly_cnt + 1'b1);
	else 
		dly_cnt <= 'd0;
end 

assign vid_rst_n = dly_cnt[26];//sys_rst_n
assign pixel_data_en        =  vid_rst_n;
// Panel driver initialization
panel_config
#(
	.INITIAL_CODE	("./src/mipi_dsi/Panel_1080p_reg.mem"),
	.REG_DEPTH		(9'd150)
)
inst_panel_config
(
	.i_axi_clk		(i_mipi_clk		),
	.i_restn		(axi_rst_n),//(LCD_RST_P	),
	
	.i_axi_awready	(w_axi_awready	),
	.i_axi_wready	(w_axi_wready	),
	.i_axi_bvalid	(w_axi_bvalid	),
	.o_axi_awaddr	(w_axi_awaddr	),
	.o_axi_awvalid	(w_axi_awvalid	),
	.o_axi_wdata	(w_axi_wdata	),
	.o_axi_wvalid	(w_axi_wvalid	),
	.o_axi_bready	(w_axi_bready	),
	
	.i_axi_arready	(w_axi_arready	),
	.i_axi_rdata	(w_axi_rdata	),
	.i_axi_rvalid	(w_axi_rvalid	),
	.o_axi_araddr	(w_axi_araddr	),
	.o_axi_arvalid	(w_axi_arvalid	),
	.o_axi_rready	(w_axi_rready	),
	
	.o_addr_cnt		(			),
	.o_state		(			),
	.o_confdone		(w_confdone	),
	
	.i_dbg_we		(0	),
	.i_dbg_din		(0	),
	.i_dbg_addr		(0	),
	.o_dbg_dout		(	),
	.i_dbg_reconfig	(0	)
);


// wire [47:0] dout;
// wire o_de;
// wire o_vs;
// wire o_hs;
	

// color_bar_rgb # (
//     .DYN_EN(1'b1),
//     .HS_POLORY(1'b1),
//     .VS_POLORY(1'b1),
//     .SYMBOL_WIDTH(8),
//     .SYMBOL_NUM(3),
//     .PAR_PIXEL_NUM(2),
//     .HFP(HFP),
//     .HST(HSP),
//     .HACT(HACT),
//     .HBP(HBP),
//     .VFP(VFP),
//     .VST(VSP),
//     .VACT(VACT),
//     .VBP(VBP),
//     .TEST_MODE(2'd1)
//   )
//   color_bar_rgb_inst (
//     .clk(i_sysclk_div_2),
//     .rst_n(vid_rst_n),
//     .hs(o_hs),
//     .vs(o_vs),
//     .de(o_de),
//     .o_vid_data(dout)
//   );
	


// MIPI DSI TX Channel
dsi_tx
#(
)
inst_efx_dsi_tx
(
	.reset_n			(rst_n	),//(LCD_RST_P),//
	.clk				(i_mipi_clk		),	// 100
	.reset_byte_HS_n	(rst_n	),//(LCD_RST_P),//
	.clk_byte_HS		(i_mipi_tx_pclk	),	// 1000/8=125
	.reset_pixel_n		(rst_n	),//(vid_rst_n	)(LCD_RST_P),//
	.clk_pixel			(i_sysclk_div_2	),  // 1000/16=62.5
	// LVDS clock lane   
	.Tx_LP_CLK_P		(mipi_dp_clk_LP_P_OUT),
	.Tx_LP_CLK_P_OE     (mipi_dp_clk_LP_P_OE),
	.Tx_LP_CLK_N		(mipi_dp_clk_LP_N_OUT),
	.Tx_LP_CLK_N_OE     (mipi_dp_clk_LP_N_OE),
	.Tx_HS_C            (mipi_dp_clk_HS_OUT),
	.Tx_HS_enable_C		(mipi_dp_clk_HS_OE),
	
	// ----- DLane -----------
	// LVDS data lane
	.Tx_LP_D_P			({mipi_dp_data3_LP_P_OUT, mipi_dp_data2_LP_P_OUT, mipi_dp_data1_LP_P_OUT, mipi_dp_data0_LP_P_OUT}),
	.Tx_LP_D_P_OE       ({mipi_dp_data3_LP_P_OE, mipi_dp_data2_LP_P_OE, mipi_dp_data1_LP_P_OE, mipi_dp_data0_LP_P_OE}),
	.Tx_LP_D_N			({mipi_dp_data3_LP_N_OUT, mipi_dp_data2_LP_N_OUT, mipi_dp_data1_LP_N_OUT, mipi_dp_data0_LP_N_OUT}),
	.Tx_LP_D_N_OE       ({mipi_dp_data3_LP_N_OE, mipi_dp_data2_LP_N_OE, mipi_dp_data1_LP_N_OE, mipi_dp_data0_LP_N_OE}),
	.Tx_HS_D_0			(mipi_dp_data0_HS_OUT),
	.Tx_HS_D_1			(mipi_dp_data1_HS_OUT),
	.Tx_HS_D_2			(mipi_dp_data2_HS_OUT),
	.Tx_HS_D_3			(mipi_dp_data3_HS_OUT),
	// control signal to LVDS IO
	.Tx_HS_enable_D		({mipi_dp_data3_HS_OE, mipi_dp_data2_HS_OE, mipi_dp_data1_HS_OE, mipi_dp_data0_HS_OE}),
	.Rx_LP_D_P			(mipi_dp_data0_LP_P_IN),
	.Rx_LP_D_N			(mipi_dp_data0_LP_N_IN),
	
	//AXI4-Lite Interface
	.axi_clk		(i_mipi_clk		), 
	.axi_reset_n	(axi_rst_n),//(LCD_RST_P			),//
	.axi_awaddr		(w_axi_awaddr	),//Write Address. byte address.
	.axi_awvalid	(w_axi_awvalid	),//Write address valid.
	.axi_awready	(w_axi_awready	),//Write address ready.
	.axi_wdata		(w_axi_wdata	),//Write data bus.
	.axi_wvalid		(w_axi_wvalid	),//Write valid.
	.axi_wready		(w_axi_wready	),//Write ready.
						  
	.axi_bvalid		(w_axi_bvalid	),//Write response valid.
	.axi_bready		(w_axi_bready	),//Response ready.      
	.axi_araddr		(w_axi_araddr	),//Read address. byte address.
	.axi_arvalid	(w_axi_arvalid	),//Read address valid.
	.axi_arready	(w_axi_arready	),//Read address ready.
	.axi_rdata		(w_axi_rdata	),//Read data.
	.axi_rvalid		(w_axi_rvalid	),//Read valid.
	.axi_rready		(w_axi_rready	),//Read ready.

    .hsync				(pixel_hs_i),//(o_hs),//(~w_pack_hs),
    .vsync				(pixel_vs_i),//(o_vs),//(~w_pack_vs),
	.vc					(2'b0					),
	.datatype			(6'h3E					),
    .pixel_data			(pixel_data_i),//dout}			),//({16'b0, w_pack_data}),
    .pixel_data_valid	(pixel_de_i),//(o_de),//(w_pack_valid),
	.haddr				(HACT				),
	.TurnRequest_dbg    (1'b0					),
	.TurnRequest_done	(),
	.irq				()
);



endmodule
