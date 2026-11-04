
`define NUM_CAM 1


module dsi_top #(
    parameter NUM_DATA_LANE = 4
)(

//`default_nettype none
    ////////////////////////    CLOCK & PLL     ////////////////////////
    
    input       i_fb_clk,
    input       i_sysclk_div2,
    input       dphy_byte_clk, //312.5MHz

    // input       pll_mipi_locked,
    // input       pll_byteclk_locked,  
    input  rst_n,
    ////////////////////////    USER CONTROL    ///////////////////
    output      o_lcd_rstp,
    output      lcd_power_en,
    input              w_vs,
    input              w_hs,
    input              w_valid,
    input [63:0]       w_data,

    output             wire       w_confdone,
    ///---- MIPI blocks related clocks   ----///
    input  logic         mipi_dphy_tx_pclk,      //MIPI HS byte clock from MIPI block 
    input  logic         RxClkEsc,   
    input  logic         esc_clk,   //20Mhz
    
    ///---- MIPI blocks control signals   ----///
    input   logic        mipi_dphy_tx_inst1_PLL_UNLOCK,
    output  logic        mipi_dphy_tx_inst1_RESET_N,
    output  logic        mipi_dphy_tx_inst1_PLL_SSC_EN, 

    ///---- Clock Lane   ----///
    input   logic        mipi_dphy_tx_inst1_STOPSTATE_CLK,
    output  logic        mipi_dphy_tx_inst1_TX_REQUEST_HS,
    output  logic        mipi_dphy_tx_inst1_TX_ULPS_CLK,
    output  logic        mipi_dphy_tx_inst1_TX_ULPS_EXIT,
    input   logic        mipi_dphy_tx_inst1_TX_ULPS_ACTIVE_CLK_NOT,

    ///---- Data Lane ULPS ----///
    output  logic        mipi_dphy_tx_inst1_TX_ULPS_ESC_LAN0,
    output  logic        mipi_dphy_tx_inst1_TX_ULPS_ESC_LAN1,
    output  logic        mipi_dphy_tx_inst1_TX_ULPS_ESC_LAN2,
    output  logic        mipi_dphy_tx_inst1_TX_ULPS_ESC_LAN3,
    output  logic        mipi_dphy_tx_inst1_TX_ULPS_EXIT_LAN0,
    output  logic        mipi_dphy_tx_inst1_TX_ULPS_EXIT_LAN1,
    output  logic        mipi_dphy_tx_inst1_TX_ULPS_EXIT_LAN2,
    output  logic        mipi_dphy_tx_inst1_TX_ULPS_EXIT_LAN3,
    input   logic        mipi_dphy_tx_inst1_TX_ULPS_ACTIVE_NOT_LAN0,
    input   logic        mipi_dphy_tx_inst1_TX_ULPS_ACTIVE_NOT_LAN1,
    input   logic        mipi_dphy_tx_inst1_TX_ULPS_ACTIVE_NOT_LAN2,
    input   logic        mipi_dphy_tx_inst1_TX_ULPS_ACTIVE_NOT_LAN3,

    ///---- Data Lane LP mode   ----///
    output  logic        mipi_dphy_tx_inst1_TX_REQUEST_ESC_LAN0,
    output  logic        mipi_dphy_tx_inst1_TX_REQUEST_ESC_LAN1,
    output  logic        mipi_dphy_tx_inst1_TX_REQUEST_ESC_LAN2,
    output  logic        mipi_dphy_tx_inst1_TX_REQUEST_ESC_LAN3,
    input   logic        mipi_dphy_tx_inst1_STOPSTATE_LAN0,
    input   logic        mipi_dphy_tx_inst1_STOPSTATE_LAN1,
    input   logic        mipi_dphy_tx_inst1_STOPSTATE_LAN2,
    input   logic        mipi_dphy_tx_inst1_STOPSTATE_LAN3,

    ///---- Data Lane HS mode   ----///
    output  logic        mipi_dphy_tx_inst1_TX_SKEW_CAL_HS_LAN0,
    output  logic        mipi_dphy_tx_inst1_TX_SKEW_CAL_HS_LAN1,
    output  logic        mipi_dphy_tx_inst1_TX_SKEW_CAL_HS_LAN2,
    output  logic        mipi_dphy_tx_inst1_TX_SKEW_CAL_HS_LAN3,
    input   logic        mipi_dphy_tx_inst1_TX_READY_HS_LAN0,
    input   logic        mipi_dphy_tx_inst1_TX_READY_HS_LAN1,
    input   logic        mipi_dphy_tx_inst1_TX_READY_HS_LAN2,
    input   logic        mipi_dphy_tx_inst1_TX_READY_HS_LAN3,
    output  logic        mipi_dphy_tx_inst1_TX_REQUEST_HS_LAN0,
    output  logic        mipi_dphy_tx_inst1_TX_REQUEST_HS_LAN1,
    output  logic        mipi_dphy_tx_inst1_TX_REQUEST_HS_LAN2,
    output  logic        mipi_dphy_tx_inst1_TX_REQUEST_HS_LAN3,
    output  logic [15:0] mipi_dphy_tx_inst1_TX_DATA_HS_LAN0,
    output  logic [15:0] mipi_dphy_tx_inst1_TX_DATA_HS_LAN1,
    output  logic [15:0] mipi_dphy_tx_inst1_TX_DATA_HS_LAN2,
    output  logic [15:0] mipi_dphy_tx_inst1_TX_DATA_HS_LAN3,
    output  logic        mipi_dphy_tx_inst1_TX_WORD_VALID_HS_LAN0,
    output  logic        mipi_dphy_tx_inst1_TX_WORD_VALID_HS_LAN1,
    output  logic        mipi_dphy_tx_inst1_TX_WORD_VALID_HS_LAN2,
    output  logic        mipi_dphy_tx_inst1_TX_WORD_VALID_HS_LAN3,

    ///---- Data Lane 0 Escape mode LPDT   ----///
    output logic         mipi_dphy_tx_inst1_TX_VALID_ESC, 
    output logic [7:0]   mipi_dphy_tx_inst1_TX_DATA_ESC,
    output logic         mipi_dphy_tx_inst1_TX_LPDT_ESC,
    input  logic         mipi_dphy_tx_inst1_TX_READY_ESC,
    
    ///---- Data Lane 0 Escape mode Trigger and Turnaround   ----///
    output logic         mipi_dphy_tx_inst1_TURN_REQUEST,
    output logic [3:0]   mipi_dphy_tx_inst1_TX_TRIGGER_ESC,
    output logic         mipi_dphy_tx_inst1_FORCE_RX_MODE,
    input  logic         mipi_dphy_tx_inst1_DIRECTION,
    input  logic [3:0]   mipi_dphy_tx_inst1_RX_TRIGGER_ESC,
    input  logic         mipi_dphy_tx_inst1_RX_LPDT_ESC,
    input  logic         mipi_dphy_tx_inst1_RX_VALID_ESC,
    input  logic [7:0]   mipi_dphy_tx_inst1_RX_DATA_ESC,
    input  logic         mipi_dphy_tx_inst1_RX_ULPS_ESC,
    input  logic         mipi_dphy_tx_inst1_ERR_CONTROL,
    input  logic         mipi_dphy_tx_inst1_ERR_ESC,
    input  logic         mipi_dphy_tx_inst1_ERR_CONTENTION_LP0,
    input  logic         mipi_dphy_tx_inst1_ERR_CONTENTION_LP1,
    input  logic         mipi_dphy_tx_inst1_ERR_SYNC_ESC//,
    
);

localparam	MAX_HRES		= 12'd1920;
localparam	MAX_VRES		= 12'd1080;
localparam	HSP				= 8'd2;
localparam	HBP				= 8'd88;
localparam	HFP				= 8'd120;
localparam	VSP				= 6'd2;
localparam	VBP				= 6'd20;
localparam	VFP				= 6'd20;




////---- unused signals  ----////
assign mipi_dphy_tx_inst1_PLL_SSC_EN = 0;



// Mapping to DPHY TX
logic                       TxUlpsClk;
logic                       TxUlpsExitClk;
logic [NUM_DATA_LANE-1:0]   TxUlpsEsc;
logic [NUM_DATA_LANE-1:0]   TxUlpsExit;
logic [NUM_DATA_LANE-1:0]   TxRequestEsc;
logic [NUM_DATA_LANE-1:0]   TxSkewCalHS;
logic [NUM_DATA_LANE-1:0]   TxRequestHS;
logic                       TxRequestHSc;
logic [15:0]                TxDataHS0;
logic [15:0]                TxDataHS1;
logic [15:0]                TxDataHS2;
logic [15:0]                TxDataHS3;
logic [1:0]                 TxReqValidHS0;
logic [1:0]                 TxReqValidHS1;
logic [1:0]                 TxReqValidHS2;
logic [1:0]                 TxReqValidHS3;
logic                       TxUlpsActiveClkNot;
logic [NUM_DATA_LANE-1:0]   TxStopStateD;
logic                       TxStopStateC;
logic [NUM_DATA_LANE-1:0]   TxUlpsActiveNot;
logic [NUM_DATA_LANE-1:0]   TxReadyHS;
logic                       TurnRequest;
logic                       TxValidEsc;
logic                       TxLpdtEsc;
logic                       TxReadyEsc;
logic [3:0]                 TxTriggerEsc;
logic                       RxLPDTEsc;
logic                       RxValidEsc;
logic [7:0]                 RxDataEsc;
logic [7:0]                 TxDataEsc_0;

assign mipi_dphy_tx_inst1_RESET_N = rst_n;//i_arstn;
assign mipi_dphy_tx_inst1_TX_ULPS_CLK = TxUlpsClk;
assign mipi_dphy_tx_inst1_TX_ULPS_EXIT = TxUlpsExitClk;
assign TxUlpsActiveClkNot = mipi_dphy_tx_inst1_TX_ULPS_ACTIVE_CLK_NOT;
assign mipi_dphy_tx_inst1_TX_ULPS_ESC_LAN0 = TxUlpsEsc[0];
assign mipi_dphy_tx_inst1_TX_ULPS_ESC_LAN1 = TxUlpsEsc[1];
assign mipi_dphy_tx_inst1_TX_ULPS_ESC_LAN2 = TxUlpsEsc[2];
assign mipi_dphy_tx_inst1_TX_ULPS_ESC_LAN3 = TxUlpsEsc[3];
assign mipi_dphy_tx_inst1_TX_ULPS_EXIT_LAN0 = TxUlpsExit[0];
assign mipi_dphy_tx_inst1_TX_ULPS_EXIT_LAN1 = TxUlpsExit[1];
assign mipi_dphy_tx_inst1_TX_ULPS_EXIT_LAN2 = TxUlpsExit[2];
assign mipi_dphy_tx_inst1_TX_ULPS_EXIT_LAN3 = TxUlpsExit[3];
assign mipi_dphy_tx_inst1_TX_REQUEST_ESC_LAN0 = TxRequestEsc[0];
assign mipi_dphy_tx_inst1_TX_REQUEST_ESC_LAN1 = TxRequestEsc[1];
assign mipi_dphy_tx_inst1_TX_REQUEST_ESC_LAN2 = TxRequestEsc[2];
assign mipi_dphy_tx_inst1_TX_REQUEST_ESC_LAN3 = TxRequestEsc[3];
assign mipi_dphy_tx_inst1_TX_SKEW_CAL_HS_LAN0 = TxSkewCalHS[0];
assign mipi_dphy_tx_inst1_TX_SKEW_CAL_HS_LAN1 = TxSkewCalHS[1];
assign mipi_dphy_tx_inst1_TX_SKEW_CAL_HS_LAN2 = TxSkewCalHS[2];
assign mipi_dphy_tx_inst1_TX_SKEW_CAL_HS_LAN3 = TxSkewCalHS[3];
assign TxStopStateD[0] = mipi_dphy_tx_inst1_STOPSTATE_LAN0;
assign TxStopStateD[1] = mipi_dphy_tx_inst1_STOPSTATE_LAN1;
assign TxStopStateD[2] = mipi_dphy_tx_inst1_STOPSTATE_LAN2;
assign TxStopStateD[3] = mipi_dphy_tx_inst1_STOPSTATE_LAN3;
assign TxStopStateC = mipi_dphy_tx_inst1_STOPSTATE_CLK;
assign TxUlpsActiveNot[0] = mipi_dphy_tx_inst1_TX_ULPS_ACTIVE_NOT_LAN0;
assign TxUlpsActiveNot[1] = mipi_dphy_tx_inst1_TX_ULPS_ACTIVE_NOT_LAN1;
assign TxUlpsActiveNot[2] = mipi_dphy_tx_inst1_TX_ULPS_ACTIVE_NOT_LAN2;
assign TxUlpsActiveNot[3] = mipi_dphy_tx_inst1_TX_ULPS_ACTIVE_NOT_LAN3;
assign TxReadyHS[0] = mipi_dphy_tx_inst1_TX_READY_HS_LAN0;
assign TxReadyHS[1] = mipi_dphy_tx_inst1_TX_READY_HS_LAN1;
assign TxReadyHS[2] = mipi_dphy_tx_inst1_TX_READY_HS_LAN2;
assign TxReadyHS[3] = mipi_dphy_tx_inst1_TX_READY_HS_LAN3;
assign mipi_dphy_tx_inst1_TX_REQUEST_HS = TxRequestHSc;
assign mipi_dphy_tx_inst1_TX_DATA_HS_LAN0 = TxDataHS0;
assign mipi_dphy_tx_inst1_TX_DATA_HS_LAN1 = TxDataHS1;
assign mipi_dphy_tx_inst1_TX_DATA_HS_LAN2 = TxDataHS2;
assign mipi_dphy_tx_inst1_TX_DATA_HS_LAN3 = TxDataHS3;
assign mipi_dphy_tx_inst1_TX_REQUEST_HS_LAN0 = TxRequestHS[0];
assign mipi_dphy_tx_inst1_TX_REQUEST_HS_LAN1 = TxRequestHS[1];
assign mipi_dphy_tx_inst1_TX_REQUEST_HS_LAN2 = TxRequestHS[2];
assign mipi_dphy_tx_inst1_TX_REQUEST_HS_LAN3 = TxRequestHS[3];
assign mipi_dphy_tx_inst1_TX_WORD_VALID_HS_LAN0 = TxReqValidHS0[1];
assign mipi_dphy_tx_inst1_TX_WORD_VALID_HS_LAN1 = TxReqValidHS1[1];
assign mipi_dphy_tx_inst1_TX_WORD_VALID_HS_LAN2 = TxReqValidHS2[1];
assign mipi_dphy_tx_inst1_TX_WORD_VALID_HS_LAN3 = TxReqValidHS3[1];

assign mipi_dphy_tx_inst1_TURN_REQUEST = TurnRequest;
assign RxLPDTEsc = mipi_dphy_tx_inst1_RX_LPDT_ESC;
assign RxValidEsc = mipi_dphy_tx_inst1_RX_VALID_ESC;
assign RxDataEsc = mipi_dphy_tx_inst1_RX_DATA_ESC;
assign mipi_dphy_tx_inst1_TX_TRIGGER_ESC = TxTriggerEsc;
assign mipi_dphy_tx_inst1_TX_VALID_ESC = TxValidEsc;
assign mipi_dphy_tx_inst1_TX_DATA_ESC = TxDataEsc_0;
assign mipi_dphy_tx_inst1_TX_LPDT_ESC = TxLpdtEsc;
assign TxReadyEsc = mipi_dphy_tx_inst1_TX_READY_ESC;

wire       w_fb_clk_arstn;
wire       w_dphy_byte_clk_arstn;

wire       i_fb_clk_rst_n;
//===================================================================
//reset_ctrl
//===================================================================


localparam RESET_COUNT          = 22;
localparam RESET_LCD            = 22'd100;
localparam RELEASE_RESET_LCD    = 22'd1000;
reg         r_lcd_rstn = 1;
reg  [RESET_COUNT-1:0] r_rst_cnt = 0;

//inital time
always @(posedge i_fb_clk or negedge rst_n )
begin
    if(!rst_n) 
        r_rst_cnt <= 'd0;
    else  if( r_rst_cnt != {RESET_COUNT{1'b1}})
        r_rst_cnt <= r_rst_cnt + 1'b1;
end
assign i_fb_clk_rst_n = r_rst_cnt[RESET_COUNT-1];


always @(posedge i_fb_clk or negedge rst_n ) 
begin
    if( !rst_n )
    // if (r_rst_cnt == RESET_LCD)
        r_lcd_rstn <= 1'b1;
    else if (r_rst_cnt >= RELEASE_RESET_LCD) 
        r_lcd_rstn <= 1'b0;

end
assign o_lcd_rstp = r_lcd_rstn;
assign lcd_power_en = rst_n;//
reset_ctrl #(
    .NUM_RST       (2),
    .CYCLE         (2),
    .IN_RST_ACTIVE (2'b00),
    .OUT_RST_ACTIVE(2'b00)
) inst_reset_ctrl (
    .i_arst({i_fb_clk_rst_n,rst_n}),
    .i_clk({i_fb_clk, dphy_byte_clk }),
    .o_srst({
        w_fb_clk_arstn,
        w_dphy_byte_clk_arstn
    })
);

//===================================================================
//color_bar
//===================================================================



	// color_bar_rgb #(
	// .HS_POLORY 		(1'b1	    ),
	// .VS_POLORY 		(1'b1	    ),
	
	// .TEST_MODE 		(2'd1       )
	// )u_color_bar_rgb(
	// /*i*/.clk	(i_sysclk_div2  ),
	// /*i*/.rst_n	(w_confdone     ),
    // .H_FRONT_PORCH 	(HFP/2	    ),
	// .H_SYNC 		(HSP/2	    ),
	// .H_VALID 		(MAX_HRES/2	),
	// .H_BACK_PORCH 	(HBP/2		),
	// .V_FRONT_PORCH 	(VFP		),
	// .V_SYNC 		(VSP		),
	// .V_VALID 		(MAX_VRES	),
	// .V_BACK_PORCH 	(VBP		),
	// /*o*/.hs	(w_hs),
	// /*o*/.vs	(w_vs),
	// /*o*/.de	(w_valid),
	// /*o*/.rgb_r	(w_r),    //像素数据、红色分量
	// /*o*/.rgb_g	(w_g),    //像素数据、绿色分量
	// /*o*/.rgb_b (w_b)    //像素数据、蓝色分量
	
	// );


//==============================================================
//panel_driver
//==============================================================
    wire [31:0] w_axi_rdata;
    wire        w_axi_awready;
    wire        w_axi_wready;
    wire        w_axi_arready;
    wire        w_axi_rvalid;
    wire        w_axi_bvalid;
    
    wire [ 6:0] w_axi_awaddr;
    wire        w_axi_awvalid;
    wire [31:0] w_axi_wdata;
    wire        w_axi_wvalid;
    wire        w_axi_bready;
    wire [ 6:0] w_axi_araddr;
    wire        w_axi_arvalid;
    wire        w_axi_rready;
// Panel driver initialization
panel_config #(
    .INITIAL_CODE("./src/mipi_dsi/IPhone_7p_1080p_reg.mem"),
    .REG_DEPTH   (9'd150)
) inst_panel_config (
    .i_axi_clk      (i_fb_clk),
    .i_restn        (w_fb_clk_arstn),

    .i_axi_awready(w_axi_awready),              
    .i_axi_wready (w_axi_wready),               
    .i_axi_bvalid (w_axi_bvalid),               
    .o_axi_awaddr (w_axi_awaddr),               
    .o_axi_awvalid(w_axi_awvalid),              
    .o_axi_wdata  (w_axi_wdata),                
    .o_axi_wvalid (w_axi_wvalid),               
    .o_axi_bready (w_axi_bready),               
                 
    .i_axi_arready(w_axi_arready),              
    .i_axi_rdata  (w_axi_rdata),                
    .i_axi_rvalid (w_axi_rvalid),               
    .o_axi_araddr (w_axi_araddr),               
    .o_axi_arvalid(w_axi_arvalid),              
    .o_axi_rready (w_axi_rready),               

    .o_addr_cnt(),
    .o_state   (),
    .o_confdone(w_confdone),

    .i_dbg_we      (0),
    .i_dbg_din     (0),
    .i_dbg_addr    (0),
    .o_dbg_dout    (),
    .i_dbg_reconfig(0)
);

//==============================================================
//
//==============================================================

efx_dsi_tx_top_5a7e90b0930911eda1eb0242ac120002 #(
    .HS_BYTECLK_MHZ(125),
    .HS_CMD_WDATAFIFO_DEPTH(512),
    .LP_CMD_WDATAFIFO_DEPTH(512),
    .LP_CMD_RDATAFIFO_DEPTH(2048),
    .HS_LANE_FIFO_DEPTH(128),
    .HS_DATA_WIDTH(16)
) inst_efx_dsi_tx_top (
    .clk_byte_HS        (dphy_byte_clk  ),
    .reset_byte_HS_n    (w_dphy_byte_clk_arstn),

    .clk_pixel          (i_sysclk_div2),
    .reset_pixel_n      (w_dphy_byte_clk_arstn),//(w_confdone),

    .phy_clk_byte_HS    (mipi_dphy_tx_pclk),
    
    .clk_esc            (esc_clk),
    .reset_esc_n        (w_dphy_byte_clk_arstn),//

    //PPI interface
    .TurnRequest        (TurnRequest),
    .TxRequestHSc       (TxRequestHSc),
    .TxUlpsClk          (TxUlpsClk),
    .TxUlpsExitClk      (TxUlpsExitClk),  
    .TxUlpsActiveClkNot (TxUlpsActiveClkNot),
    .TxStopStateC       (TxStopStateC),
    .TxRequestHS        (TxRequestHS),
    .TxDataHS_0         (TxDataHS0),
    .TxDataHS_1         (TxDataHS1),
    .TxDataHS_2         (TxDataHS2),
    .TxDataHS_3         (TxDataHS3),
    .TxReqValidHS0      (TxReqValidHS0),
    .TxReqValidHS1      (TxReqValidHS1),   
    .TxReqValidHS2      (TxReqValidHS2),
    .TxReqValidHS3      (TxReqValidHS3), 
    .TxReadyHS          (TxReadyHS),
    .TxSkewCalHS        (TxSkewCalHS),
    .TxRequestEsc       (TxRequestEsc), //
    .TxTriggerEsc       (TxTriggerEsc), //
    .TxStopStateD       (TxStopStateD),
    .TxUlpsExit         (TxUlpsExit),   //
    .TxUlpsActiveNot    (TxUlpsActiveNot),
    .TxUlpsEsc          (TxUlpsEsc),   // 
    .TxLpdtEsc          (TxLpdtEsc),
    .TxValidEsc         (TxValidEsc),
    .TxDataEsc_0        (TxDataEsc_0),
    .TxReadyEsc         (TxReadyEsc),  
    
    .RxClkEsc           (RxClkEsc),
    .RxDataEsc          (RxDataEsc),
    .RxLPDTEsc          (RxLPDTEsc),   
    .RxValidEsc         (RxValidEsc),

    //AXI4-Lite Interface
    .axi_clk    (i_fb_clk),
    .axi_reset_n(w_fb_clk_arstn),
    .axi_awaddr (w_axi_awaddr),  //Write Address. byte address.
    .axi_awvalid(w_axi_awvalid),  //Write address valid.
    .axi_awready(w_axi_awready),  //Write address ready.
    .axi_wdata  (w_axi_wdata),  //Write data bus.
    .axi_wvalid (w_axi_wvalid),  //Write valid.
    .axi_wready (w_axi_wready),  //Write ready.

    .axi_bvalid (w_axi_bvalid),  //Write response valid.
    .axi_bready (w_axi_bready),  //Response ready.      
    .axi_araddr (w_axi_araddr),  //Read address. byte address.
    .axi_arvalid(w_axi_arvalid),  //Read address valid.
    .axi_arready(w_axi_arready),  //Read address ready.
    .axi_rdata  (w_axi_rdata),  //Read data.
    .axi_rvalid (w_axi_rvalid),  //Read valid.
    .axi_rready (w_axi_rready),  //Read ready.

    .hsync(w_hs),
    .vsync(w_vs),
    .vc(2'b0),
    .datatype(6'h3E),
    .pixel_data(w_data),
    .pixel_data_valid(w_valid),
    .haddr(1920),
    .TurnRequest_dbg(1'b0),
    .TurnRequest_done(),
    .turnaround_timeout (),
    .irq()
);



endmodule
