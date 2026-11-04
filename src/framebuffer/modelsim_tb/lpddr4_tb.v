`timescale 1 ns / 1 ns

module lpddr4_tb;

localparam AXI_DATA_WIDTH = 512;
localparam I_VID_WIDTH = 32;
localparam O_VID_WIDTH = 16;
localparam AXI_ADDR_WIDTH = 33;
localparam WR_FIFO_DEPTH	= 128;    
localparam RD_FIFO_DEPTH = 128;
localparam START_ADDR=33'h0000;
parameter   MAX_VID_WIDTH	=	1920 ;//video width 
parameter   MAX_VID_HIGHT	=	1080 ;//wideo height
parameter   BURST_LEN       = 63;
parameter	MAX_HRES		= 13'd1000;
parameter	MAX_VRES		= 13'd20;
parameter	HSP				= 13'd20;
parameter	HBP				= 13'd46;
parameter	HFP				= 13'd46;
parameter	VSP				= 13'd3;
parameter	VBP				= 13'd5;
parameter	VFP				= 13'd5;

parameter AXI_DW = 512;
parameter AXI_AW = 24;
reg axi0_ACLK = 'd0;           

wire  axi0_ARQOS;         
wire  axi0_AWQOS;         
wire  [5:0] axi0_AWID;    
wire  [32:0] axi0_AWADDR; 
wire  [7:0] axi0_AWLEN;   
wire  [2:0] axi0_AWSIZE;  
wire  [1:0] axi0_AWBURST; 
wire  axi0_AWVALID;       
wire  [3:0] axi0_AWCACHE; 
wire  axi0_AWCOBUF;       
wire  axi0_AWLOCK;        
wire  axi0_AWAPCMD;       
wire  axi0_AWALLSTRB;     
wire  [5:0] axi0_ARID;   
wire  [32:0] axi0_ARADDR; 
wire  [7:0] axi0_ARLEN;   
wire  [2:0] axi0_ARSIZE;  
wire  [1:0] axi0_ARBURST; 
wire  axi0_ARVALID;       
wire  axi0_ARLOCK;        
wire  axi0_ARAPCMD;       
wire  axi0_WLAST;         
wire  axi0_WVALID;        
wire  [511:0] axi0_WDATA; 
wire  [63:0] axi0_WSTRB;  
wire  axi0_BREADY;        
wire  axi0_RREADY;        
wire axi0_AWREADY;        
wire axi0_ARREADY;        
wire axi0_WREADY;         
wire [5:0] axi0_BID;      
wire [1:0] axi0_BRESP;    
wire axi0_BVALID;         
wire [5:0] axi0_RID;      
wire axi0_RLAST;          
wire axi0_RVALID;         
wire [511:0] axi0_RDATA;  
wire [1:0] axi0_RRESP;   
reg	io_asyncResetn = 1'b0;
always #10 axi0_ACLK = ~axi0_ACLK;
initial
begin
	#0
		io_asyncResetn = 0;
	#345
		io_asyncResetn = 1;



end



reg clk = 1'b0;

wire hs;
wire vs;
wire de;
wire [7:0] r_data;
wire [7:0] g_data;
wire [7:0] b_data;
always #10 clk = ~clk;
wire fb_ch0_hs;
wire fb_ch0_vs;
wire fb_ch0_de;
wire [O_VID_WIDTH-1:0] fb_ch0_dout;
       


	color_bar_rgb #(
			.HS_POLORY 		(1'b0	    ),
			.VS_POLORY 		(1'b0	    ),
		
			.TEST_MODE 		(2'b00		)
	)u_color_bar_rgb(
	/*i*/.clk	(clk),
	/*i*/.rst_n	(io_asyncResetn ),
	    .H_FRONT_PORCH 	(HFP/2	    ),
        .H_SYNC 		(HSP/2	    ),
        .H_VALID 		(MAX_HRES/2	),
        .H_BACK_PORCH 	(HBP/2	    ),
        .V_FRONT_PORCH 	(VFP		),
        .V_SYNC 		(VSP		),
        .V_VALID 		(MAX_VRES	),
        .V_BACK_PORCH 	(VBP		),
	/*o*/.hs	(hs),
	/*o*/.vs	(vs),
	/*o*/.de	(de),
	/*O*/.h_cnt (h_cnt),
	/*O*/.v_cnt (v_cnt),
	/*o*/.rgb_r	(r_data),    //像素数据、红色分量
	/*o*/.rgb_g	(g_data),    //像素数据、绿色分量
	/*o*/.rgb_b (b_data)    //像素数据、蓝色分量
	
	);

frame_buffer #(
.AXI_DATA_WIDTH ( AXI_DATA_WIDTH	),
.I_VID_WIDTH    ( I_VID_WIDTH       ),
.O_VID_WIDTH    ( O_VID_WIDTH       ),
.MAX_VID_WIDTH 	( MAX_VID_WIDTH     ),
.MAX_VID_HIGHT 	( MAX_VID_HIGHT     ),
.BURST_LEN      ( BURST_LEN         ),
.AXI_ADDR_WIDTH ( AXI_ADDR_WIDTH	),
.WR_FIFO_DEPTH	( WR_FIFO_DEPTH		),    
.RD_FIFO_DEPTH 	( RD_FIFO_DEPTH 	),
.START_ADDR     (START_ADDR)
)u_frame_buffer(
    .axi_clk(axi0_ACLK),
    .rst_n(io_asyncResetn),
    .i_clk  (clk) ,
    .i_vs   (vs) , 
    .i_de   (de) , 
    .vin    ({8'd0,r_data,g_data,b_data}) ,
    .o_clk  (clk) ,
    .o_hs   (fb_ch0_hs) ,
    .o_vs   (fb_ch0_vs) ,
    .o_de   (fb_ch0_de) ,
    .vout   (fb_ch0_dout) ,
    .H_FRONT_PORCH 	(HFP	    ),
    .H_SYNC 		(HSP	    ),	
    .H_VALID 		(MAX_HRES	),
    .H_BACK_PORCH 	(HBP	    ),
    .V_FRONT_PORCH 	(VFP		),
    .V_SYNC 		(VSP		),	
    .V_VALID 		(MAX_VRES	),
    .V_BACK_PORCH 	(VBP		),
    .awid(axi0_AWID),
    .awaddr(axi0_AWADDR),
    .awlen(axi0_AWLEN),
    .awsize(axi0_AWSIZE),
    .awburst(axi0_AWBURST),
    .awcache(axi0_AWCACHE),
    .awlock(axi0_AWLOCK),
    .awvalid(axi0_AWVALID),
    .awcobuf(axi0_AWCOBUF),
    .awapcmd(axi0_AWAPCMD),
    .awallstrb(axi0_AWALLSTRB),
    .awready(axi0_AWREADY),
    .awqos(axi0_AWQOS),
    .arid(axi0_ARID),
    .araddr(axi0_ARADDR),
    .arlen(axi0_ARLEN),
    .arsize(axi0_ARSIZE),
    .arburst(axi0_ARBURST),
    .arlock(axi0_ARLOCK),
    .arvalid(axi0_ARVALID),
    .arapcmd(axi0_ARAPCMD),
    .arready(axi0_ARREADY),
    .arqos(axi0_ARQOS),
    .wdata(axi0_WDATA),
    .wstrb(axi0_WSTRB),
    .wlast(axi0_WLAST),
    .wvalid(axi0_WVALID),
    .wready(axi0_WREADY),
    .rid(axi0_RID),
    .rdata(axi0_RDATA),
    .rlast(axi0_RLAST),
    .rvalid(axi0_RVALID),
    .rready(axi0_RREADY),
    .rresp(axi0_RRESP),
    .bid(axi0_BID),
    .bvalid(axi0_BVALID),
    .bready(axi0_BREADY)
);



axi_ram #
(
    .DATA_WIDTH            (AXI_DW       ),
    .ADDR_WIDTH            (AXI_AW       ),
    .ID_WIDTH              (6            ),
    .PIPELINE_OUTPUT       (0            )
)                                        
u_axi_ram
(
    .clk                   (axi0_ACLK     ),
    .rst                   (!io_asyncResetn     	),
    .s_axi_awid            (0     ),
    .s_axi_awaddr          (axi0_AWADDR   ), 
    .s_axi_awlen           ({2'd0,axi0_AWLEN[5:0] }   ), 
    .s_axi_awsize          (axi0_AWSIZE   ), 
    .s_axi_awburst         (axi0_AWBURST  ), 
    .s_axi_awlock          (axi0_AWLOCK   ), 
    .s_axi_awcache         (axi0_AWCACHE  ), 
    .s_axi_awprot          (axi0_AWPROT   ), 
    .s_axi_awvalid         (axi0_AWVALID  ), 
    .s_axi_awready         (axi0_AWREADY  ), 
    .s_axi_wdata           (axi0_WDATA    ), 
    .s_axi_wstrb           (axi0_WSTRB    ), 
    .s_axi_wlast           (axi0_WLAST    ), 
    .s_axi_wvalid          (axi0_WVALID   ), 
    .s_axi_wready          (axi0_WREADY   ), 
    .s_axi_bid             (axi0_BID      ),
    .s_axi_bresp           (axi0_BRESP    ), 
    .s_axi_bvalid          (axi0_BVALID   ), 
    .s_axi_bready          (axi0_BREADY   ),
    .s_axi_arid            (0     ),
    .s_axi_araddr          (axi0_ARADDR   ), 
    .s_axi_arlen           ({2'd0,axi0_ARLEN[5:0]}    ), 
    .s_axi_arsize          (axi0_ARSIZE   ), 
    .s_axi_arburst         (axi0_ARBURST  ), 
    .s_axi_arlock          (axi0_ARLOCK   ), 
    .s_axi_arcache         (axi0_ARCACHE  ), 
    .s_axi_arprot          (axi0_ARPROT   ), 
    .s_axi_arvalid         (axi0_ARVALID  ), 
    .s_axi_arready         (axi0_ARREADY  ),
    .s_axi_rid             (axi0_RID      ),
    .s_axi_rdata           (axi0_RDATA    ), 
    .s_axi_rresp           (axi0_RRESP    ), 
    .s_axi_rlast           (axi0_RLAST    ), 
    .s_axi_rvalid          (axi0_RVALID   ), 
    .s_axi_rready          (axi0_RREADY   )
);



color_bar_checker #(
    .DATA_WIDTH(O_VID_WIDTH)
) u_color_bar_checker (
    .clk(clk),
    .rst_n(arst_n),
    .i_hs(fb_ch0_hs),
    .i_vs(fb_ch0_vs),
    .i_de(fb_ch0_de),
    .vin(fb_ch0_dout),
    .check_fail(check_fail)
  );



endmodule

