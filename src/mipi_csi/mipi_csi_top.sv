
module mipi_csi_top #(
    parameter NUM_DATA_LANE = 4
) (

//`default_nettype none
    ////////////////////////    CLOCK & PLL     ////////////////////////
    
    input       clk_pixel,


    input       rst_n,
    ////////////////////////    USER CONTROL    ///////////////////
    input       CLK_5M,


    output rx_out_hs,
    output rx_out_vs,
    output rx_out_valid,
    output [63:0]rx_out_data,

    
    //mipi rx
    input mipi_dphy_rx_inst2_byte_clk,
    input mipi_dphy_rx_inst2_ERR_CONTENTION_LP0,
    input mipi_dphy_rx_inst2_ERR_CONTENTION_LP1,
    input mipi_dphy_rx_inst2_ERR_CONTROL_LAN0,
    input mipi_dphy_rx_inst2_ERR_CONTROL_LAN1,
    input mipi_dphy_rx_inst2_ERR_CONTROL_LAN2,
    input mipi_dphy_rx_inst2_ERR_CONTROL_LAN3,
    input mipi_dphy_rx_inst2_ERR_ESC_LAN0,
    input mipi_dphy_rx_inst2_ERR_ESC_LAN1,
    input mipi_dphy_rx_inst2_ERR_ESC_LAN2,
    input mipi_dphy_rx_inst2_ERR_ESC_LAN3,
    input mipi_dphy_rx_inst2_ERR_SOT_HS_LAN0,
    input mipi_dphy_rx_inst2_ERR_SOT_HS_LAN1,
    input mipi_dphy_rx_inst2_ERR_SOT_HS_LAN2,
    input mipi_dphy_rx_inst2_ERR_SOT_HS_LAN3,
    input mipi_dphy_rx_inst2_ERR_SOT_SYNC_HS_LAN0,
    input mipi_dphy_rx_inst2_ERR_SOT_SYNC_HS_LAN1,
    input mipi_dphy_rx_inst2_ERR_SOT_SYNC_HS_LAN2,
    input mipi_dphy_rx_inst2_ERR_SOT_SYNC_HS_LAN3,
    input mipi_dphy_rx_inst2_LP_CLK,
    input mipi_dphy_rx_inst2_RX_ACTIVE_HS_LAN0,
    input mipi_dphy_rx_inst2_RX_ACTIVE_HS_LAN1,
    input mipi_dphy_rx_inst2_RX_ACTIVE_HS_LAN2,
    input mipi_dphy_rx_inst2_RX_ACTIVE_HS_LAN3,
    input mipi_dphy_rx_inst2_RX_CLK_ACTIVE_HS,
    input [15:0] mipi_dphy_rx_inst2_RX_DATA_ESC,
    input [15:0] mipi_dphy_rx_inst2_RX_DATA_HS_LAN0,
    input [15:0] mipi_dphy_rx_inst2_RX_DATA_HS_LAN1,
    input [15:0] mipi_dphy_rx_inst2_RX_DATA_HS_LAN2,
    input [15:0] mipi_dphy_rx_inst2_RX_DATA_HS_LAN3,
    input mipi_dphy_rx_inst2_RX_LPDT_ESC,
    input mipi_dphy_rx_inst2_RX_SKEW_CAL_HS_LAN0,
    input mipi_dphy_rx_inst2_RX_SKEW_CAL_HS_LAN1,
    input mipi_dphy_rx_inst2_RX_SKEW_CAL_HS_LAN2,
    input mipi_dphy_rx_inst2_RX_SKEW_CAL_HS_LAN3,
    input mipi_dphy_rx_inst2_RX_SYNC_HS_LAN0,
    input mipi_dphy_rx_inst2_RX_SYNC_HS_LAN1,
    input mipi_dphy_rx_inst2_RX_SYNC_HS_LAN2,
    input mipi_dphy_rx_inst2_RX_SYNC_HS_LAN3,
    input [3:0] mipi_dphy_rx_inst2_RX_TRIGGER_ESC,
    input mipi_dphy_rx_inst2_RX_ULPS_ACTIVE_CLK_NOT,

    
    input   logic		mipi_dphy_rx_inst2_ESC_LAN0_CLK,
    input   logic		mipi_dphy_rx_inst2_ESC_LAN1_CLK,
    input   logic		mipi_dphy_rx_inst2_ESC_LAN2_CLK,
    input   logic		mipi_dphy_rx_inst2_ESC_LAN3_CLK,

    input mipi_dphy_rx_inst2_RX_ULPS_ACTIVE_NOT_LAN0,
    input mipi_dphy_rx_inst2_RX_ULPS_ACTIVE_NOT_LAN1,
    input mipi_dphy_rx_inst2_RX_ULPS_ACTIVE_NOT_LAN2,
    input mipi_dphy_rx_inst2_RX_ULPS_ACTIVE_NOT_LAN3,
    input mipi_dphy_rx_inst2_RX_ULPS_CLK_NOT,
    input mipi_dphy_rx_inst2_RX_ULPS_ESC_LAN0,
    input mipi_dphy_rx_inst2_RX_ULPS_ESC_LAN1,
    input mipi_dphy_rx_inst2_RX_ULPS_ESC_LAN2,
    input mipi_dphy_rx_inst2_RX_ULPS_ESC_LAN3,
    input mipi_dphy_rx_inst2_RX_VALID_ESC,
    input mipi_dphy_rx_inst2_RX_VALID_HS_LAN0,
    input mipi_dphy_rx_inst2_RX_VALID_HS_LAN1,
    input mipi_dphy_rx_inst2_RX_VALID_HS_LAN2,
    input mipi_dphy_rx_inst2_RX_VALID_HS_LAN3,
    input mipi_dphy_rx_inst2_STOPSTATE_CLK,
    input mipi_dphy_rx_inst2_STOPSTATE_LAN0,
    input mipi_dphy_rx_inst2_STOPSTATE_LAN1,
    input mipi_dphy_rx_inst2_STOPSTATE_LAN2,
    input mipi_dphy_rx_inst2_STOPSTATE_LAN3,
    output mipi_dphy_rx_inst2_FORCE_RX_MODE,
    output mipi_dphy_rx_inst2_RESET_N,
    output mipi_dphy_rx_inst2_RST0_N,
    input mipi_rx_cfg_clk,
    output  io_cam_scl_OUT,
    output  io_cam_scl_OE,
    output  io_cam_sda_OUT,
    output  io_cam_sda_OE,
    input   io_cam_scl_IN,
    input   io_cam_sda_IN,
    output o_cam_rst_p
);








wire        pll_locked;
wire       clk_5m_rst_n;
//===================================================================
//reset_ctrl
//===================================================================

reset_ctrl #(
    .NUM_RST       (1),
    .CYCLE         (2),
    .IN_RST_ACTIVE (1'b0),
    .OUT_RST_ACTIVE(1'b0)
) inst_reset_ctrl (
    .i_arst(rst_n),
    .i_clk(CLK_5M),
    .o_srst({clk_5m_rst_n
    })
);

//===================================================================
//i2c_controller
//===================================================================

wire scl_padoen_o;
wire sda_padoen_o;
reg [15:0] i2c_rst_cnt = '0;

always @( posedge CLK_5M or negedge clk_5m_rst_n )
begin
    if( !clk_5m_rst_n )
       i2c_rst_cnt <= 'd0;
    else 
       i2c_rst_cnt <= i2c_rst_cnt[15] ? i2c_rst_cnt : i2c_rst_cnt + 1'b1;
end
wire i2c_rst_n = i2c_rst_cnt[15] ;

i2c_master_ctrl_top u2_i2c_master_ctrl_top(
  /*i*/.clk			  (CLK_5M		),
  /*i*/.rst_n		  (i2c_rst_n		),
  /*i*/.scl_pad_i     (io_cam_scl_IN),//(1'b1),
  /*o*/.scl_pad_o     (io_cam_scl_OUT),
  /*o*/.scl_padoen_o  (scl_padoen_o),
  /*i*/.sda_pad_i     (io_cam_sda_IN),
  /*o*/.sda_pad_o     (io_cam_sda_OUT),
  /*o*/.sda_padoen_o  (sda_padoen_o)
  
  );
assign o_cam_rst_p = ~clk_5m_rst_n;
assign io_cam_scl_OE = ~scl_padoen_o;
assign io_cam_sda_OE = ~sda_padoen_o;
//===================================================================
//mipi rx
//===================================================================

// Mapping to DPHY RX IF
logic RxUlpsClkNot;
logic [NUM_DATA_LANE-1:0]	RxErrEsc;
logic [NUM_DATA_LANE-1:0] 	RxErrControl;
logic [NUM_DATA_LANE-1:0] 	RxErrSotSyncHS;
logic [NUM_DATA_LANE-1:0]	RXRxClkEsc;
logic [NUM_DATA_LANE-1:0]	RxUlpsEsc;
logic [NUM_DATA_LANE-1:0]	RxUlpsActiveNot;
logic [NUM_DATA_LANE-1:0]	RxSkewCalHS;
logic [NUM_DATA_LANE-1:0]	RxStopState;
logic [NUM_DATA_LANE-1:0] 	RxValidHS;
logic [NUM_DATA_LANE-1:0]  	RxSyncHS;
logic [NUM_DATA_LANE-1:0][15:0]	RxDataHS;



assign RxUlpsClkNot = mipi_dphy_rx_inst2_RX_ULPS_CLK_NOT;
assign RxUlpsActiveClkNot = mipi_dphy_rx_inst2_RX_ULPS_ACTIVE_CLK_NOT;

assign RxErrEsc[0] = mipi_dphy_rx_inst2_ERR_ESC_LAN0;
assign RxErrEsc[1] = mipi_dphy_rx_inst2_ERR_ESC_LAN1;
assign RxErrEsc[2] = mipi_dphy_rx_inst2_ERR_ESC_LAN2;
assign RxErrEsc[3] = mipi_dphy_rx_inst2_ERR_ESC_LAN3;

assign RxErrControl[0] = mipi_dphy_rx_inst2_ERR_CONTROL_LAN0;
assign RxErrControl[1] = mipi_dphy_rx_inst2_ERR_CONTROL_LAN1;
assign RxErrControl[2] = mipi_dphy_rx_inst2_ERR_CONTROL_LAN2;
assign RxErrControl[3] = mipi_dphy_rx_inst2_ERR_CONTROL_LAN3;

assign RxErrSotSyncHS[0] = mipi_dphy_rx_inst2_ERR_SOT_SYNC_HS_LAN0;
assign RxErrSotSyncHS[1] = mipi_dphy_rx_inst2_ERR_SOT_SYNC_HS_LAN1;
assign RxErrSotSyncHS[2] = mipi_dphy_rx_inst2_ERR_SOT_SYNC_HS_LAN2;
assign RxErrSotSyncHS[3] = mipi_dphy_rx_inst2_ERR_SOT_SYNC_HS_LAN3;

assign RxUlpsEsc[0] = mipi_dphy_rx_inst2_RX_ULPS_ESC_LAN0;
assign RxUlpsEsc[1] = mipi_dphy_rx_inst2_RX_ULPS_ESC_LAN1;
assign RxUlpsEsc[2] = mipi_dphy_rx_inst2_RX_ULPS_ESC_LAN2;
assign RxUlpsEsc[3] = mipi_dphy_rx_inst2_RX_ULPS_ESC_LAN3;

assign RXRxClkEsc[0] = mipi_dphy_rx_inst2_ESC_LAN0_CLK;
assign RXRxClkEsc[1] = mipi_dphy_rx_inst2_ESC_LAN1_CLK;
assign RXRxClkEsc[2] = mipi_dphy_rx_inst2_ESC_LAN2_CLK;
assign RXRxClkEsc[3] = mipi_dphy_rx_inst2_ESC_LAN3_CLK;

assign RxUlpsActiveNot[0] = mipi_dphy_rx_inst2_RX_ULPS_ACTIVE_NOT_LAN0;
assign RxUlpsActiveNot[1] = mipi_dphy_rx_inst2_RX_ULPS_ACTIVE_NOT_LAN1;
assign RxUlpsActiveNot[2] = mipi_dphy_rx_inst2_RX_ULPS_ACTIVE_NOT_LAN2;
assign RxUlpsActiveNot[3] = mipi_dphy_rx_inst2_RX_ULPS_ACTIVE_NOT_LAN3;

assign RxSkewCalHS[0] = mipi_dphy_rx_inst2_RX_SKEW_CAL_HS_LAN0;
assign RxSkewCalHS[1] = mipi_dphy_rx_inst2_RX_SKEW_CAL_HS_LAN1;
assign RxSkewCalHS[2] = mipi_dphy_rx_inst2_RX_SKEW_CAL_HS_LAN2;
assign RxSkewCalHS[3] = mipi_dphy_rx_inst2_RX_SKEW_CAL_HS_LAN3;

assign RxStopState[0] = mipi_dphy_rx_inst2_STOPSTATE_LAN0;
assign RxStopState[1] = mipi_dphy_rx_inst2_STOPSTATE_LAN1;
assign RxStopState[2] = mipi_dphy_rx_inst2_STOPSTATE_LAN2;
assign RxStopState[3] = mipi_dphy_rx_inst2_STOPSTATE_LAN3;

assign RxValidHS[0] = mipi_dphy_rx_inst2_RX_VALID_HS_LAN0;
assign RxValidHS[1] = mipi_dphy_rx_inst2_RX_VALID_HS_LAN1;
assign RxValidHS[2] = mipi_dphy_rx_inst2_RX_VALID_HS_LAN2;
assign RxValidHS[3] = mipi_dphy_rx_inst2_RX_VALID_HS_LAN3;

assign RxSyncHS[0] = mipi_dphy_rx_inst2_RX_SYNC_HS_LAN0;
assign RxSyncHS[1] = mipi_dphy_rx_inst2_RX_SYNC_HS_LAN1;
assign RxSyncHS[2] = mipi_dphy_rx_inst2_RX_SYNC_HS_LAN2;
assign RxSyncHS[3] = mipi_dphy_rx_inst2_RX_SYNC_HS_LAN3;
//rd data
assign RxDataHS[0] = mipi_dphy_rx_inst2_RX_DATA_HS_LAN0;
assign RxDataHS[1] = mipi_dphy_rx_inst2_RX_DATA_HS_LAN1;
assign RxDataHS[2] = mipi_dphy_rx_inst2_RX_DATA_HS_LAN2;
assign RxDataHS[3] = mipi_dphy_rx_inst2_RX_DATA_HS_LAN3;


assign mipi_dphy_rx_inst2_FORCE_RX_MODE = 1'b1;
assign mipi_dphy_rx_inst2_RESET_N = rst_n;
assign mipi_dphy_rx_inst2_RST0_N = i2c_rst_n;//rst_n;
wire mipi_rx_cfg_clk_rst_n ;
wire reset_byte_HS_n;
wire reset_pixel_n;
rst_n_piple # (.DLY(3))
  rst_n_mipi_rx_cfg_clk (
    .clk(mipi_rx_cfg_clk),
    .rst_n_i(rst_n),
    .rst_n_o(mipi_rx_cfg_clk_rst_n)
  );

  rst_n_piple # (.DLY(3))
  rst_n_byte_clk (
    .clk(mipi_dphy_rx_inst2_byte_clk),
    .rst_n_i(rst_n),
    .rst_n_o(reset_byte_HS_n)
  );
  rst_n_piple # (.DLY(3))
  u_rst_pixel_n (
    .clk(clk_pixel),
    .rst_n_i(i2c_rst_n),
    .rst_n_o(reset_pixel_n)
  );
reg data_en = 'd0;
  always @( posedge mipi_dphy_rx_inst2_byte_clk or negedge reset_byte_HS_n)
  begin
    if( ! reset_byte_HS_n )
        data_en <= 1'b0;
    else if (&RxStopState)
        data_en <= 1'b1;
  end 

yls_csi2_rx  u_yls_csi2_rx(
.reset_n ( mipi_rx_cfg_clk_rst_n ),
.clk ( mipi_rx_cfg_clk ),
.reset_byte_HS_n ( reset_byte_HS_n ),
.clk_byte_HS ( mipi_dphy_rx_inst2_byte_clk ),
.reset_pixel_n ( reset_pixel_n ),
.clk_pixel ( clk_pixel  ),
.irq ( irq ),
.shortpkt_data_field ( shortpkt_data_field ),
.word_count ( word_count ),
.vcx ( vcx ),
.vc ( vc ),
.RxUlpsClkNot ( RxUlpsClkNot ),
.RxUlpsActiveClkNot ( RxUlpsActiveClkNot ),
.RxClkEsc ( RXRxClkEsc ),
.RxErrEsc ( RxErrEsc ),
.RxErrControl ( RxErrControl ),
.RxErrSotSyncHS ( RxErrSotSyncHS ),
.RxUlpsEsc ( RxUlpsEsc ),
.RxUlpsActiveNot ( RxUlpsActiveNot ),
.RxSkewCalHS ( RxSkewCalHS ),
.RxStopState ( RxStopState ),

.axi_clk        ( mipi_rx_cfg_clk  ),
.axi_reset_n    ( mipi_rx_cfg_clk_rst_n ),
.axi_awready    ( axi_awready ),
.axi_awaddr     ( axi_awaddr ),
.axi_awvalid    ( axi_awvalid ),
.axi_rready     ( axi_rready ),
.axi_rvalid     ( axi_rvalid ),
.axi_rdata      ( axi_rdata ),
.axi_arready    ( axi_arready ),
.axi_arvalid    ( axi_arvalid ),
.axi_araddr     ( axi_araddr ),
.axi_bready     ( axi_bready ),
.axi_bvalid     ( axi_bvalid ),
.axi_wready     ( axi_wready ),
.axi_wvalid     ( axi_wvalid ),
.axi_wdata      ( axi_wdata ),

.pixel_per_clk (  ),

.datatype ( datatype ),
.RxSyncHS ( RxSyncHS ),
.RxDataHS0 (data_en ?RxDataHS[0]:1'b0 ),
.RxDataHS1 (data_en ?RxDataHS[1]:1'b0 ),
.RxDataHS2 (data_en ?RxDataHS[2]:1'b0 ),
.RxDataHS3 (data_en ?RxDataHS[3]:1'b0 ),
.vsync_vc0 ( rx_out_vs ),
.hsync_vc0 ( rx_out_hs ),
.pixel_data_valid ( rx_out_valid ),
.pixel_data ( rx_out_data ),

.RxValidHS0 ({RxValidHS[0], RxValidHS[0]}  ),
.RxValidHS1 ({RxValidHS[1], RxValidHS[1]}  ),
.RxValidHS2 ({RxValidHS[2], RxValidHS[2]}  ),
.RxValidHS3 ({RxValidHS[3], RxValidHS[3]}  ),
.RxValidHS4 (  ),
.RxValidHS5 (  ),
.RxValidHS6 (  ),
.RxValidHS7 (  )
);


vid_info_det vid_info_det_inst (
    .clk(clk_pixel),
    .rst_n(rst_n),
    .i_vs(rx_out_vs),
    .i_hs(rx_out_hs),
    .i_de(rx_out_valid),
    .frame_cnt_o(),
    .frame_stable(),
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


endmodule
