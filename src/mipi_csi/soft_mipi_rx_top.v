
module soft_mipi_rx_top #(
  parameter PACK_BIT          = 40
) (
   input mipi_clk,
   input CLK_5M,
   input i_sysclk_div2,
   input arst_n,
   input mipi_rx_ck0_CLKOUT,

   input  io_cam_scl_IN,
   input  io_cam_sda_IN,
   output io_cam_scl_OUT,
   output io_cam_scl_OE,
   output io_cam_sda_OUT,
   output io_cam_sda_OE,
   output o_cam_rst_p,

  //mipi rx
   output mipi_rx_ck0_HS_ENA,
   output mipi_rx_dp00_HS_ENA,
   output mipi_rx_dp01_HS_ENA,
   output mipi_rx_dp02_HS_ENA,
   output mipi_rx_dp03_HS_ENA,

   output mipi_rx_ck0_HS_TERM,
   output mipi_rx_dp00_HS_TERM,
   output mipi_rx_dp01_HS_TERM,
   output mipi_rx_dp02_HS_TERM,
   output mipi_rx_dp03_HS_TERM,
  
  
   output mipi_rx_dp00_RST,
   output mipi_rx_dp01_RST,
   output mipi_rx_dp02_RST,
   output mipi_rx_dp03_RST,


   input       mipi_rx_ck0_LP_N_IN,
   input       mipi_rx_ck0_LP_P_IN,
   input       mipi_rx_dp00_LP_N_IN,
   input       mipi_rx_dp00_LP_P_IN,
   input       mipi_rx_dp01_LP_N_IN,
   input       mipi_rx_dp01_LP_P_IN,
   input       mipi_rx_dp02_LP_N_IN,
   input       mipi_rx_dp02_LP_P_IN,
   input       mipi_rx_dp03_LP_N_IN,
   input       mipi_rx_dp03_LP_P_IN,

   input [7:0] mipi_rx_dp00_HS_IN,
   input [7:0] mipi_rx_dp01_HS_IN,
   input [7:0] mipi_rx_dp02_HS_IN,
   input [7:0] mipi_rx_dp03_HS_IN,

   output      mipi_rx_dp00_FIFO_RD,
   output      mipi_rx_dp01_FIFO_RD,
   output      mipi_rx_dp02_FIFO_RD,
   output      mipi_rx_dp03_FIFO_RD,
   input       mipi_rx_dp00_FIFO_EMPTY,
   input       mipi_rx_dp01_FIFO_EMPTY,
   input       mipi_rx_dp02_FIFO_EMPTY,
   input       mipi_rx_dp03_FIFO_EMPTY,

   output      rx_out_de,
   output      rx_out_hs,
   output      rx_out_vs,
   output      [PACK_BIT-1:0] rx_out_data




);



//========================================================================== 
// csi 
//========================================================================== 
wire mipi_dphy_rx_reset_byte_HS_n;
wire reset_pixel_n;
    
reset
#(
	.IN_RST_ACTIVE	("LOW"),
	.OUT_RST_ACTIVE	("LOW"),
	.CYCLE			(3)
)
inst_rx_byteclk_rst
(
	.i_arst	(arst_n),
	.i_clk	(mipi_rx_ck0_CLKOUT),
	.o_srst	(mipi_dphy_rx_reset_byte_HS_n)
);

reset
#(
	.IN_RST_ACTIVE	("LOW"),
	.OUT_RST_ACTIVE	("LOW"),
	.CYCLE			(3)
)
inst_pixel_clk_rst
(
	.i_arst	(arst_n),
	.i_clk	(i_sysclk_div2),//pixel_clk
	.o_srst	(reset_pixel_n)
);
    



reg		[5:0]	r_rx_axi_araddr_1P;
reg				r_rx_axi_arvalid_1P;
wire			w_rx_axi_arready;
wire	[31:0]	w_rx_axi_rdata;
wire			w_rx_axi_rvalid;
reg				r_rx_axi_rready_1P;

  assign mipi_rx_dp00_RST = 1'b0; 
  assign mipi_rx_dp01_RST = 1'b0; 
  assign mipi_rx_dp02_RST = 1'b0; 
  assign mipi_rx_dp03_RST = 1'b0; 


csi_rx_controller inst_efx_csi2_rx
(
    .reset_n			(arst_n),
    .clk				(mipi_clk),
    .reset_byte_HS_n	(mipi_dphy_rx_reset_byte_HS_n),
    .clk_byte_HS		(mipi_rx_ck0_CLKOUT),
    .reset_pixel_n		(reset_pixel_n),
    .clk_pixel			(i_sysclk_div2),  
    // LVDS clock lane   
	.Rx_LP_CLK_P		(mipi_rx_ck0_LP_P_IN),
	.Rx_LP_CLK_N		(mipi_rx_ck0_LP_N_IN),
	.Rx_HS_enable_C		(mipi_rx_ck0_HS_ENA),
	.LVDS_termen_C		(mipi_rx_ck0_HS_TERM),
	
	// ----- DLane 0 -----------
    // LVDS data lane
    .Rx_LP_D_P			  ({mipi_rx_dp03_LP_P_IN, mipi_rx_dp02_LP_P_IN, mipi_rx_dp01_LP_P_IN, mipi_rx_dp00_LP_P_IN}),
	.Rx_LP_D_N			    ({mipi_rx_dp03_LP_N_IN, mipi_rx_dp02_LP_N_IN, mipi_rx_dp01_LP_N_IN, mipi_rx_dp00_LP_N_IN}),
	.Rx_HS_D_0			    (mipi_rx_dp00_HS_IN),
	.Rx_HS_D_1			    (mipi_rx_dp01_HS_IN),	
	.Rx_HS_D_2			    (mipi_rx_dp02_HS_IN),
	.Rx_HS_D_3			    (mipi_rx_dp03_HS_IN),
	.Rx_HS_enable_D		  ({mipi_rx_dp03_HS_ENA    , mipi_rx_dp02_HS_ENA    , mipi_rx_dp01_HS_ENA    , mipi_rx_dp00_HS_ENA    }),
	.LVDS_termen_D		  ({mipi_rx_dp03_HS_TERM   , mipi_rx_dp02_HS_TERM   , mipi_rx_dp01_HS_TERM   , mipi_rx_dp00_HS_TERM   }),
	.fifo_rd_enable     ({mipi_rx_dp03_FIFO_RD   , mipi_rx_dp02_FIFO_RD   , mipi_rx_dp01_FIFO_RD   , mipi_rx_dp00_FIFO_RD   }),
	.fifo_rd_empty      ({mipi_rx_dp03_FIFO_EMPTY, mipi_rx_dp02_FIFO_EMPTY, mipi_rx_dp01_FIFO_EMPTY, mipi_rx_dp00_FIFO_EMPTY}),
	
	.DLY_enable_D       (),
	.DLY_inc_D          (),
	.u_dly_enable_D     (),
	.u_dly_inc_D        (),
	
    //AXI4-Lite Interface
    .axi_clk		(mipi_clk), 
    .axi_reset_n	(arst_n),
    .axi_awaddr		(6'b0),//Write Address. byte address.
    .axi_awvalid	(1'b0),//Write address valid.
    .axi_awready	(),//Write address ready.
    .axi_wdata		(32'b0),//Write data bus.
    .axi_wvalid		(1'b0),//Write valid.
    .axi_wready		(),//Write ready.           
    .axi_bvalid		(),//Write response valid.
    .axi_bready		(1'b0),//Response ready.      
    .axi_araddr		(r_rx_axi_araddr_1P),//Read address. byte address.
    .axi_arvalid	(r_rx_axi_arvalid_1P),//Read address valid.
    .axi_arready	(w_rx_axi_arready),//Read address ready.
    .axi_rdata		(w_rx_axi_rdata),//Read data.
    .axi_rvalid		(w_rx_axi_rvalid),//Read valid.
//    .axi_rready		(r_rx_axi_rready_1P),//Read ready.
    .axi_rready		(1'b1),//Read ready.
	
    .hsync_vc0			(rx_out_hs),
    .hsync_vc1			(),
    .hsync_vc2			(),
    .hsync_vc3			(),
    .vsync_vc0			(rx_out_vs),
    .vsync_vc1			(),
    .vsync_vc2			(),
    .vsync_vc3			(),
    .vc					(),
	.word_count			(word_count),
	.shortpkt_data_field(),
	.datatype			(datatype),        //DATATYPE RAW8
    .pixel_per_clk		(),
	.pixel_data			(rx_out_data),
    .pixel_data_valid	(rx_out_de),
    .irq				(),
     .mipi_debug_in(),
    .mipi_debug_out()

);

wire scl_padoen_o;
wire sda_padoen_o;


reg [12:0] i2c_rst_cnt = 'd0;

always @( posedge CLK_5M or negedge reset_pixel_n )
begin
    if( !reset_pixel_n )
       i2c_rst_cnt <= 'd0;
    else 
       i2c_rst_cnt <= i2c_rst_cnt[12] ? i2c_rst_cnt : i2c_rst_cnt + 1'b1;
end
wire i2c_rst_n = i2c_rst_cnt[12];

i2c_master_ctrl_top u2_i2c_master_ctrl_top(
  /*i*/.clk			(CLK_5M		),
  /*i*/.rst_n			(i2c_rst_n		),
  /*i*/.scl_pad_i     (io_cam_scl_IN),//(1'b1),
  /*o*/.scl_pad_o     (io_cam_scl_OUT),
  /*o*/.scl_padoen_o  (scl_padoen_o),
  /*i*/.sda_pad_i     (io_cam_sda_IN),
  /*o*/.sda_pad_o     (io_cam_sda_OUT),
  /*o*/.sda_padoen_o  (sda_padoen_o)
  
  );
assign o_cam_rst_p = ~arst_n;
assign io_cam_scl_OE = ~scl_padoen_o;
assign io_cam_sda_OE = ~sda_padoen_o;


vid_info_det # (
    .CLK_FREQ(32'd70_000_000)
  )
  vid_info_det_inst (
    .clk(i_sysclk_div2),
    .rst_n(pixel_data_en),
    .i_vs(rx_out_vs),
    .i_hs(rx_out_hs),
    .i_de(rx_out_de),
    .frame_cnt_o(),
    .frame_stable(),
    .neg_vs_sync(),
    .neg_hs_sync(),
    .o_h_act(),
    .h_active_error(),
    .o_v_act(),
    .v_active_error(),
    .o_v_total(),
    .v_total_error(),
    .o_h_total(),
    .h_total_error(),
    .h_sync_error()
  );



endmodule
