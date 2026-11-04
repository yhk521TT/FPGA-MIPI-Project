// *********************************************************************************/
// Project Name :
// Author       : lifeng
// Email        : 103447209@qq.com
// Creat Time   : 2021/2/24 10:39:16
// File Name    : .v
// Module Name  : 
// Called By    :
// Abstract     :
//
// *********************************************************************************/
// Modification History:
// 1. initial
// *********************************************************************************/
// *************************
// MODULE DEFINITION
// *************************
`timescale 1 ns / 1 ns
module tb_top(
);
// Parameter Define
parameter   AXI_DW = 32;//Data Width
parameter   AXI_AW = 16;//Address Width
parameter   AXI_LEN = 8;//minimum=1; maximum=256;

localparam  AXI_CNT = 3;
localparam  AXI_SW = AXI_DW/8;//Write Strobes Width

// Register Define 
reg                             aresetn;
reg                             aclk=0;

// Wire Define
//--AXI4 Interface
wire    [AXI_CNT*8-1:0]         axi_awid;
wire    [AXI_CNT*AXI_AW-1:0]    axi_awaddr;
wire    [AXI_CNT*8-1:0]         axi_awlen;
wire    [AXI_CNT*3-1:0]         axi_awsize;
wire    [AXI_CNT*2-1:0]         axi_awburst;
wire    [AXI_CNT-1:0]           axi_awlock;
wire    [AXI_CNT*4-1:0]         axi_awcache;
wire    [AXI_CNT*3-1:0]         axi_awprot;
wire    [AXI_CNT-1:0]           axi_awvalid;
wire    [AXI_CNT-1:0]           axi_awready;
wire    [AXI_CNT*AXI_DW-1:0]    axi_wdata;
wire    [AXI_CNT*AXI_SW-1:0]    axi_wstrb;
wire    [AXI_CNT-1:0]           axi_wlast;
wire    [AXI_CNT-1:0]           axi_wvalid;
wire    [AXI_CNT-1:0]           axi_wready;
wire    [AXI_CNT*8-1:0]         axi_bid;
wire    [AXI_CNT*2-1:0]         axi_bresp;
wire    [AXI_CNT-1:0]           axi_bvalid;
wire    [AXI_CNT-1:0]           axi_bready;
wire    [AXI_CNT*8-1:0]         axi_arid;
wire    [AXI_CNT*AXI_AW-1:0]    axi_araddr;
wire    [AXI_CNT*8-1:0]         axi_arlen;
wire    [AXI_CNT*3-1:0]         axi_arsize;
wire    [AXI_CNT*2-1:0]         axi_arburst;
wire    [AXI_CNT-1:0]           axi_arlock;
wire    [AXI_CNT*4-1:0]         axi_arcache;
wire    [AXI_CNT*3-1:0]         axi_arprot;
wire    [AXI_CNT-1:0]           axi_arvalid;
wire    [AXI_CNT-1:0]           axi_arready;
wire    [AXI_CNT*8-1:0]         axi_rid;
wire    [AXI_CNT*AXI_DW-1:0]    axi_rdata;
wire    [AXI_CNT*2-1:0]         axi_rresp;
wire    [AXI_CNT-1:0]           axi_rlast;
wire    [AXI_CNT-1:0]           axi_rvalid;
wire    [AXI_CNT-1:0]           axi_rready;

//-----------------------------------------------------------------------------------//
//                                  THE Sim Behavior
//-----------------------------------------------------------------------------------//
initial
    begin
        aresetn <= 1;
        #11;
        aresetn <= 0;
        repeat (10) @(posedge aclk);
        aresetn <= 1;            
    end

//-----------------------------------------------------------------------------------//
//                                  THE Clock Generate
//-----------------------------------------------------------------------------------//
always aclk = #(5) ~aclk;

//-----------------------------------------------------------------------------------//
//                                  THE DUT
//-----------------------------------------------------------------------------------//
axi_interconnect #
(
    .S_COUNT                            (2                                  ),
    .M_COUNT                            (1                                  ),
    .DATA_WIDTH                         (AXI_DW                             ),
    .ADDR_WIDTH                         (AXI_AW                             ),
    .ID_WIDTH                           (8                                  )
)
u_axi_interconnect
(
    .clk                                (aclk                               ),
    .rst                                (!aresetn                           ),
//AXI slave interfaces
    .s_axi_awid                         (axi_awid   [0*8      +: 2*8]       ),
    .s_axi_awaddr                       (axi_awaddr [0*AXI_AW +: 2*AXI_AW]  ), 
    .s_axi_awlen                        (axi_awlen  [0*8      +: 2*8]       ), 
    .s_axi_awsize                       (axi_awsize [0*3      +: 2*3]       ), 
    .s_axi_awburst                      (axi_awburst[0*2      +: 2*2]       ), 
    .s_axi_awlock                       (axi_awlock [0*1      +: 2*1]       ), 
    .s_axi_awcache                      (axi_awcache[0*4      +: 2*4]       ), 
    .s_axi_awprot                       (axi_awprot [0*3      +: 2*3]       ), 
    .s_axi_awvalid                      (axi_awvalid[0*1      +: 2*1]       ), 
    .s_axi_awready                      (axi_awready[0*1      +: 2*1]       ), 
    .s_axi_wdata                        (axi_wdata  [0*AXI_DW +: 2*AXI_DW]  ), 
    .s_axi_wstrb                        (axi_wstrb  [0*AXI_SW +: 2*AXI_SW]  ), 
    .s_axi_wlast                        (axi_wlast  [0*1      +: 2*1]       ), 
    .s_axi_wvalid                       (axi_wvalid [0*1      +: 2*1]       ), 
    .s_axi_wready                       (axi_wready [0*1      +: 2*1]       ),
    .s_axi_bid                          (axi_bid    [0*8      +: 2*8]       ),
    .s_axi_bresp                        (axi_bresp  [0*2      +: 2*2]       ), 
    .s_axi_bvalid                       (axi_bvalid [0*1      +: 2*1]       ), 
    .s_axi_bready                       (axi_bready [0*1      +: 2*1]       ),
    .s_axi_arid                         (axi_arid   [0*8      +: 2*8]       ),
    .s_axi_araddr                       (axi_araddr [0*AXI_AW +: 2*AXI_AW]  ), 
    .s_axi_arlen                        (axi_arlen  [0*8      +: 2*8]       ), 
    .s_axi_arsize                       (axi_arsize [0*3      +: 2*3]       ), 
    .s_axi_arburst                      (axi_arburst[0*2      +: 2*2]       ), 
    .s_axi_arlock                       (axi_arlock [0*1      +: 2*1]       ), 
    .s_axi_arcache                      (axi_arcache[0*4      +: 2*4]       ), 
    .s_axi_arprot                       (axi_arprot [0*3      +: 2*3]       ), 
    .s_axi_arvalid                      (axi_arvalid[0*1      +: 2*1]       ), 
    .s_axi_arready                      (axi_arready[0*1      +: 2*1]       ),
    .s_axi_rid                          (axi_rid    [0*8      +: 2*8]       ),
    .s_axi_rdata                        (axi_rdata  [0*AXI_DW +: 2*AXI_DW]  ), 
    .s_axi_rresp                        (axi_rresp  [0*2      +: 2*2]       ), 
    .s_axi_rlast                        (axi_rlast  [0*1      +: 2*1]       ), 
    .s_axi_rvalid                       (axi_rvalid [0*1      +: 2*1]       ), 
    .s_axi_rready                       (axi_rready [0*1      +: 2*1]       ),
//AXI master interfaces
    .m_axi_awid                         (axi_awid   [2*8      +: 1*8]       ),
    .m_axi_awaddr                       (axi_awaddr [2*AXI_AW +: 1*AXI_AW]  ), 
    .m_axi_awlen                        (axi_awlen  [2*8      +: 1*8]       ), 
    .m_axi_awsize                       (axi_awsize [2*3      +: 1*3]       ), 
    .m_axi_awburst                      (axi_awburst[2*2      +: 1*2]       ), 
    .m_axi_awlock                       (axi_awlock [2*1      +: 1*1]       ), 
    .m_axi_awcache                      (axi_awcache[2*4      +: 1*4]       ), 
    .m_axi_awprot                       (axi_awprot [2*3      +: 1*3]       ), 
    .m_axi_awvalid                      (axi_awvalid[2*1      +: 1*1]       ), 
    .m_axi_awready                      (axi_awready[2*1      +: 1*1]       ), 
    .m_axi_wdata                        (axi_wdata  [2*AXI_DW +: 1*AXI_DW]  ), 
    .m_axi_wstrb                        (axi_wstrb  [2*AXI_SW +: 1*AXI_SW]  ), 
    .m_axi_wlast                        (axi_wlast  [2*1      +: 1*1]       ), 
    .m_axi_wvalid                       (axi_wvalid [2*1      +: 1*1]       ), 
    .m_axi_wready                       (axi_wready [2*1      +: 1*1]       ),
    .m_axi_bid                          (axi_bid    [2*8      +: 1*8]       ),
    .m_axi_bresp                        (axi_bresp  [2*2      +: 1*2]       ), 
    .m_axi_bvalid                       (axi_bvalid [2*1      +: 1*1]       ), 
    .m_axi_bready                       (axi_bready [2*1      +: 1*1]       ),
    .m_axi_arid                         (axi_arid   [2*8      +: 1*8]       ),
    .m_axi_araddr                       (axi_araddr [2*AXI_AW +: 1*AXI_AW]  ), 
    .m_axi_arlen                        (axi_arlen  [2*8      +: 1*8]       ), 
    .m_axi_arsize                       (axi_arsize [2*3      +: 1*3]       ), 
    .m_axi_arburst                      (axi_arburst[2*2      +: 1*2]       ), 
    .m_axi_arlock                       (axi_arlock [2*1      +: 1*1]       ), 
    .m_axi_arcache                      (axi_arcache[2*4      +: 1*4]       ), 
    .m_axi_arprot                       (axi_arprot [2*3      +: 1*3]       ), 
    .m_axi_arvalid                      (axi_arvalid[2*1      +: 1*1]       ), 
    .m_axi_arready                      (axi_arready[2*1      +: 1*1]       ),
    .m_axi_rid                          (axi_rid    [2*8      +: 1*8]       ),
    .m_axi_rdata                        (axi_rdata  [2*AXI_DW +: 1*AXI_DW]  ), 
    .m_axi_rresp                        (axi_rresp  [2*2      +: 1*2]       ), 
    .m_axi_rlast                        (axi_rlast  [2*1      +: 1*1]       ), 
    .m_axi_rvalid                       (axi_rvalid [2*1      +: 1*1]       ), 
    .m_axi_rready                       (axi_rready [2*1      +: 1*1]       )
);



//-----------------------------------------------------------------------------------//
//                                  THE Sim Model
//-----------------------------------------------------------------------------------//
genvar i;
generate
for(i=0; i<2; i=i+1)
begin : multiple

axi_master_gen#(
    .AXI_DW                             (AXI_DW                             ),
    .AXI_AW                             (AXI_AW                             ),
    .AXI_LEN                            (AXI_LEN                            )
)
u_axi_master_gen
(
    .rstn                               (aresetn                            ),
    .clk                                (aclk                               ),
    .m_axi_awid                         (axi_awid   [i*8      +: 1*8     ]  ),
    .m_axi_awaddr                       (axi_awaddr [i*AXI_AW +: 1*AXI_AW]  ),
    .m_axi_awlen                        (axi_awlen  [i*8      +: 1*8     ]  ),
    .m_axi_awsize                       (axi_awsize [i*3      +: 1*3     ]  ),
    .m_axi_awburst                      (axi_awburst[i*2      +: 1*2     ]  ),
    .m_axi_awlock                       (axi_awlock [i*1      +: 1*1     ]  ),
    .m_axi_awcache                      (axi_awcache[i*4      +: 1*4     ]  ),
    .m_axi_awprot                       (axi_awprot [i*3      +: 1*3     ]  ),
    .m_axi_awvalid                      (axi_awvalid[i*1      +: 1*1     ]  ),
    .m_axi_awready                      (axi_awready[i*1      +: 1*1     ]  ),
    .m_axi_wdata                        (axi_wdata  [i*AXI_DW +: 1*AXI_DW]  ),
    .m_axi_wstrb                        (axi_wstrb  [i*AXI_SW +: 1*AXI_SW]  ),
    .m_axi_wlast                        (axi_wlast  [i*1      +: 1*1     ]  ),
    .m_axi_wvalid                       (axi_wvalid [i*1      +: 1*1     ]  ),
    .m_axi_wready                       (axi_wready [i*1      +: 1*1     ]  ),
    .m_axi_bid                          (axi_bid    [i*8      +: 1*8     ]  ),
    .m_axi_bresp                        (axi_bresp  [i*2      +: 1*2     ]  ),
    .m_axi_bvalid                       (axi_bvalid [i*1      +: 1*1     ]  ),
    .m_axi_bready                       (axi_bready [i*1      +: 1*1     ]  ),
    .m_axi_arid                         (axi_arid   [i*8      +: 1*8     ]  ),
    .m_axi_araddr                       (axi_araddr [i*AXI_AW +: 1*AXI_AW]  ),
    .m_axi_arlen                        (axi_arlen  [i*8      +: 1*8     ]  ),
    .m_axi_arsize                       (axi_arsize [i*3      +: 1*3     ]  ),
    .m_axi_arburst                      (axi_arburst[i*2      +: 1*2     ]  ),
    .m_axi_arlock                       (axi_arlock [i*1      +: 1*1     ]  ),
    .m_axi_arcache                      (axi_arcache[i*4      +: 1*4     ]  ),
    .m_axi_arprot                       (axi_arprot [i*3      +: 1*3     ]  ),
    .m_axi_arvalid                      (axi_arvalid[i*1      +: 1*1     ]  ),
    .m_axi_arready                      (axi_arready[i*1      +: 1*1     ]  ),
    .m_axi_rid                          (axi_rid    [i*8      +: 1*8     ]  ),
    .m_axi_rdata                        (axi_rdata  [i*AXI_DW +: 1*AXI_DW]  ),
    .m_axi_rresp                        (axi_rresp  [i*2      +: 1*2     ]  ),
    .m_axi_rlast                        (axi_rlast  [i*1      +: 1*1     ]  ),
    .m_axi_rvalid                       (axi_rvalid [i*1      +: 1*1     ]  ),
    .m_axi_rready                       (axi_rready [i*1      +: 1*1     ]  )
);

end
endgenerate

axi_ram #
(
    .DATA_WIDTH                         (AXI_DW                             ),
    .ADDR_WIDTH                         (AXI_AW                             ),
    .ID_WIDTH                           (8                                  ),
    .PIPELINE_OUTPUT                    (0                                  )
)
u_axi_ram
(
    .clk                                (aclk                               ),
    .rst                                (!aresetn                           ),
    .s_axi_awid                         (axi_awid   [2*8      +: 1*8     ]  ),
    .s_axi_awaddr                       (axi_awaddr [2*AXI_AW +: 1*AXI_AW]  ), 
    .s_axi_awlen                        (axi_awlen  [2*8      +: 1*8     ]  ), 
    .s_axi_awsize                       (axi_awsize [2*3      +: 1*3     ]  ), 
    .s_axi_awburst                      (axi_awburst[2*2      +: 1*2     ]  ), 
    .s_axi_awlock                       (axi_awlock [2*1      +: 1*1     ]  ), 
    .s_axi_awcache                      (axi_awcache[2*4      +: 1*4     ]  ), 
    .s_axi_awprot                       (axi_awprot [2*3      +: 1*3     ]  ), 
    .s_axi_awvalid                      (axi_awvalid[2*1      +: 1*1     ]  ), 
    .s_axi_awready                      (axi_awready[2*1      +: 1*1     ]  ), 
    .s_axi_wdata                        (axi_wdata  [2*AXI_DW +: 1*AXI_DW]  ), 
    .s_axi_wstrb                        (axi_wstrb  [2*AXI_SW +: 1*AXI_SW]  ), 
    .s_axi_wlast                        (axi_wlast  [2*1      +: 1*1     ]  ), 
    .s_axi_wvalid                       (axi_wvalid [2*1      +: 1*1     ]  ), 
    .s_axi_wready                       (axi_wready [2*1      +: 1*1     ]  ), 
    .s_axi_bid                          (axi_bid    [2*8      +: 1*8     ]  ),
    .s_axi_bresp                        (axi_bresp  [2*2      +: 1*2     ]  ), 
    .s_axi_bvalid                       (axi_bvalid [2*1      +: 1*1     ]  ), 
    .s_axi_bready                       (axi_bready [2*1      +: 1*1     ]  ),
    .s_axi_arid                         (axi_arid   [2*8      +: 1*8     ]  ),
    .s_axi_araddr                       (axi_araddr [2*AXI_AW +: 1*AXI_AW]  ), 
    .s_axi_arlen                        (axi_arlen  [2*8      +: 1*8     ]  ), 
    .s_axi_arsize                       (axi_arsize [2*3      +: 1*3     ]  ), 
    .s_axi_arburst                      (axi_arburst[2*2      +: 1*2     ]  ), 
    .s_axi_arlock                       (axi_arlock [2*1      +: 1*1     ]  ), 
    .s_axi_arcache                      (axi_arcache[2*4      +: 1*4     ]  ), 
    .s_axi_arprot                       (axi_arprot [2*3      +: 1*3     ]  ), 
    .s_axi_arvalid                      (axi_arvalid[2*1      +: 1*1     ]  ), 
    .s_axi_arready                      (axi_arready[2*1      +: 1*1     ]  ),
    .s_axi_rid                          (axi_rid    [2*8      +: 1*8     ]  ),
    .s_axi_rdata                        (axi_rdata  [2*AXI_DW +: 1*AXI_DW]  ), 
    .s_axi_rresp                        (axi_rresp  [2*2      +: 1*2     ]  ), 
    .s_axi_rlast                        (axi_rlast  [2*1      +: 1*1     ]  ), 
    .s_axi_rvalid                       (axi_rvalid [2*1      +: 1*1     ]  ), 
    .s_axi_rready                       (axi_rready [2*1      +: 1*1     ]  )
);

endmodule
