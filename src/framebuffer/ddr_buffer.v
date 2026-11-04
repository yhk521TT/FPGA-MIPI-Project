

`timescale 1ps/1ps
module ddr_buffer #(
parameter AXI_DATA_WIDTH = 512, //!AXI接口位宽
parameter AXI_ADDR_WIDTH = 32,  //!AXI地址位宽
parameter WR_FIFO_DEPTH	= 1024, //!Write fifo depth   
parameter RD_FIFO_DEPTH = 1024, //!read fifo depth
parameter I_VID_WIDTH   = 16,
parameter START_ADDR		=	33'h000201900,
parameter MAX_VID_WIDTH		=	1920 ,//video width 
parameter MAX_VID_HIGHT		=	1080 ,//wideo height
parameter AXI_STRB_WIDTH = AXI_DATA_WIDTH/8,//!总共的字节数量，= AXI_DATA_WIDTH/8
parameter AXI_BURST_WIDTH = $clog2(AXI_DATA_WIDTH/8),
parameter AXSIZE_WTH = $clog2(AXI_DATA_WIDTH/8),//!内部数据
parameter WR_USEDW_WITH = $clog2(WR_FIFO_DEPTH), //!内部数据
parameter BURST_LEN  = 'd7,
parameter FB_NUM			= 	3//2 buffer ,3 buffer   





) (

input 											axi_clk,
input 											axi_rst_n,
input 											rd_start,
input											  wr_start, // pulse signal 

input 		[31:0] 								wr_busrt_len,
input 		[31:0] 								rd_burst_len,

input                               wr_fifo_rst_p,
input											          wr_fifo_wrclk,
input											          wr_fifo_wren,
output											        wr_fifo_wrfull,
input	 [AXI_DATA_WIDTH-1:0]					wr_fifo_wrdata, 
output [ WR_USEDW_WITH:0]						wr_fifo_wrusedw, 

output                                 ddr_rd_valid,
output  [AXI_DATA_WIDTH-1:0] 					ddr_rd_data,
input 										            rd_fifo_wr_full,

output 	[5:0] 									    awid,
output  [AXI_ADDR_WIDTH-1:0] 					awaddr,
output  [AXI_BURST_WIDTH-1:0] 					awlen,
output  [2:0] 									    awsize,
output  [1:0] 									    awburst,
output  [3:0] 									    awcache,
output  										        awlock,
output  										        awvalid,
output  										        awcobuf,
output  										        awapcmd,
output  										        awallstrb,
output  										        awqos,
input 											        awready,

output [5:0] 									arid,
output  [AXI_ADDR_WIDTH-1:0] 					araddr,
output  [AXI_BURST_WIDTH-1:0] 					arlen,
output  [2:0] 									arsize,
output  [1:0] 									arburst,
output  										arlock,
output  										arvalid,
output  										arapcmd,
output 											arqos,
input 											arready,
output  [AXI_DATA_WIDTH-1:0] 					wdata,  
output	[31:0]									test_wdata,
output	[31:0]									test_rdata,
output  [AXI_STRB_WIDTH-1:0] 					wstrb,
output  										wlast,
output  										wvalid,
input 											wready,

input [5:0] 									rid,
input [AXI_DATA_WIDTH-1:0] 						rdata,
input 											rlast,
input 											rvalid,
output  										rready,
input [1:0] 									rresp,
input [5:0] 									bid,
input 											bvalid,
output  										bready

);

//=============================================================
//reg define 
//=============================================================   


//=============================================================
//wire define 
//============================================================= 

wire		                        wr_sw_ack           ;
wire		                        wr_sw 		          ;
wire		                        rd_sw			          ;
wire		                        rd_sw_ack           ;
wire		[AXI_ADDR_WIDTH-1:0]		wr_start_addr       ;
wire		[AXI_ADDR_WIDTH-1:0]    rd_start_addr       ; 
wire                            rd_end_flag         ;
wire                            wr_end_flag         ;
//=============================================================  
//RTL                                                     
//=============================================================  


ddr_wr_buffer # (
    .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
    .WR_FIFO_DEPTH(WR_FIFO_DEPTH),
    .AXI_STRB_WIDTH(AXI_STRB_WIDTH),
    .AXSIZE_WTH(AXSIZE_WTH),
    .WR_USEDW_WITH(WR_USEDW_WITH),
    .BURST_LEN   ( BURST_LEN )
  )
  ddr_wr_buffer_inst (
    .axi_clk(axi_clk),
    .rst_n(axi_rst_n),
    .wr_start(wr_start),
    .start_addr(wr_start_addr),
    .burst_len(wr_busrt_len),
    .wr_end_flag(wr_end_flag),
    .wr_fifo_rst_p(wr_fifo_rst_p),
    .wr_fifo_wrclk(wr_fifo_wrclk),
    .wr_fifo_wren(wr_fifo_wren),
    .wr_fifo_wrfull(wr_fifo_wrfull),
    .wr_fifo_wrdata(wr_fifo_wrdata),
    .wr_fifo_wrusedw(wr_fifo_wrusedw),
    .awid(awid),
    .awaddr(awaddr),
    .awlen(awlen),
    .awsize(awsize),
    .awburst(awburst),
    .awcache(awcache),
    .awlock(awlock),
    .awvalid(awvalid),
    .awcobuf(awcobuf),
    .awapcmd(awapcmd),
    .awallstrb(awallstrb),
    .awqos(awqos),
    .awready(awready),
    .wdata(wdata),
    .wstrb(wstrb),
    .wlast(wlast),
    .wvalid(wvalid),
    .wready(wready),
	  .bid	( bid			),
    .bvalid	( bvalid		),
    .bready	( bready		)
  );


assign test_wdata = wdata[32:0];
assign test_rdata = rdata[32:0];
//=============================================================================================
// FIFO RD_PROCESSING
//=============================================================================================
ddr_rd_buffer # (
    .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
    .AXI_STRB_WIDTH(AXI_STRB_WIDTH),
    .AXI_BURST_WIDTH(AXI_BURST_WIDTH),
    .AXSIZE_WTH(AXSIZE_WTH),
    .BURST_LEN   ( BURST_LEN )
  )
  ddr_rd_buffer_inst (
    .axi_clk(axi_clk),
    .rst_n(axi_rst_n),
    .start(rd_start),
    .start_addr(rd_start_addr),
    .burst_len(rd_burst_len),

    .ddr_rd_valid(ddr_rd_valid),
    .ddr_rd_data(ddr_rd_data),
    .rd_fifo_wr_full(rd_fifo_wr_full),
    .rd_end_flag(rd_end_flag),
    .arid(arid),
    .araddr(araddr),
    .arlen(arlen),
    .arsize(arsize),
    .arburst(arburst),
    .arlock(arlock),
    .arvalid(arvalid),
    .arapcmd(arapcmd),
    .arqos(arqos),
    .arready(arready),
    .rid(rid),
    .rdata(rdata),
    .rlast(rlast),
    .rvalid(rvalid),
    .rready(rready),
    .rresp(rresp)
  );

/*----------------------------------------------------------------------------------*\
                                 The function code
\*----------------------------------------------------------------------------------*/


bank_switch #(
    .ADDR_WIDTH     (AXI_ADDR_WIDTH),
		.FB_NUM					( FB_NUM),
		.MAX_VID_WIDTH 	( MAX_VID_WIDTH),
		.MAX_VID_HIGHT 	( MAX_VID_HIGHT),
		.START_ADDR			(	START_ADDR 	),
		.VID_DATA_WIDTH	(I_VID_WIDTH	),
		.AXI_DATA_WIDTH (AXI_DATA_WIDTH )
)
  u_bank_sw
(
/*i*/.ddr_clk		(axi_clk	),
/*i*/.rst_n			(axi_rst_n),
              	
/*i*/.wr_sw			(wr_end_flag),
/*i*/.rd_sw			(rd_end_flag ),
                
/*o*/.wr_bank		(wr_bank	),
/*o*/.rd_bank		(rd_bank	),
/*o*/.rd_sw_ack	(rd_sw_ack),
/*o*/.wr_sw_ack (wr_sw_ack),
/*o*/.rd_start_addr(rd_start_addr),
/*o*/.wr_start_addr(wr_start_addr)
);


endmodule