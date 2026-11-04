// *********************************************************************************/
// Project Name :
// Author       : lifeng
// Email        : 103447209@qq.com
// Creat Time   : 2021/2/22 12:05:21
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
module axi_master_gen#(
    parameter                       AXI_DW = 32,
    parameter                       AXI_AW = 32,
    parameter                       AXI_LEN = 32//minimum=1; maximum=256;
)
(
//Globle Signals
input                           rstn,
input                           clk,
//Master AXI4 Write Bus Interface
output  wire    [7:0]           m_axi_awid,
output  reg     [AXI_AW-1:0]    m_axi_awaddr,
output  reg     [7:0]           m_axi_awlen,
output  wire    [2:0]           m_axi_awsize,
output  wire    [1:0]           m_axi_awburst,
output  wire                    m_axi_awlock,
output  wire    [3:0]           m_axi_awcache,
output  wire    [2:0]           m_axi_awprot,
output  reg                     m_axi_awvalid,
input                           m_axi_awready,
output  reg     [AXI_DW-1:0]    m_axi_wdata,
output  wire    [AXI_DW/8-1:0]  m_axi_wstrb,
output  reg                     m_axi_wlast,
output  reg                     m_axi_wvalid,
input                           m_axi_wready,
input           [7:0]           m_axi_bid,
input           [1:0]           m_axi_bresp,
input                           m_axi_bvalid,
output  reg                     m_axi_bready,
//Master AXI4 Read Bus Interface
output  wire    [7:0]           m_axi_arid,
output  reg     [AXI_AW-1:0]    m_axi_araddr,
output  reg     [7:0]           m_axi_arlen,
output  wire    [2:0]           m_axi_arsize,
output  wire    [1:0]           m_axi_arburst,
output  wire                    m_axi_arlock,
output  wire    [3:0]           m_axi_arcache,
output  wire    [2:0]           m_axi_arprot,
output  reg                     m_axi_arvalid,
input                           m_axi_arready,
input           [7:0]           m_axi_rid,
input           [AXI_DW-1:0]    m_axi_rdata,
input           [1:0]           m_axi_rresp,
input                           m_axi_rlast,
input                           m_axi_rvalid,
output  wire                    m_axi_rready
);
// Parameter Define 
parameter State_idle  = 3'd0;
parameter State_waddr = 3'd1;
parameter State_wdata = 3'd2;
parameter State_wait  = 3'd3;
parameter State_raddr = 3'd4;

parameter MODE = 2'b00;//00b:Normal; 01b:Write Only; 10b:Read Only;
parameter WAIT_TIME = 8'd0;
parameter AXSIZE = AXI_DW/8;
parameter AXSIZE_WTH = clogb2(AXSIZE);

// Register Define
reg     [2:0]                   cur_state;
reg     [2:0]                   next_state;
reg     [7:0]                   burst_cnt;
reg     [7:0]                   wait_cnt;
reg     [AXI_DW-1:0]            rdata;
reg                             rd_err;

// Wire Define

/*----------------------------------------------------------------------------------*\
                                 The main code
\*----------------------------------------------------------------------------------*/

/*----------------------- FSM Region ----------------------------*/
always @(posedge clk or negedge rstn)
begin
    if(rstn == 1'b0)
        cur_state <= State_idle;
    else
		cur_state <= next_state;
end

always @(*)
begin
	case(cur_state)
    State_idle :
        if(MODE == 2'b10)
            next_state = State_raddr;
        else
            next_state = State_waddr;

    State_waddr :
        if((m_axi_awvalid == 1'b1) && (m_axi_awready == 1'b1))
            next_state = State_wdata;
        else
            next_state = State_waddr;

    State_wdata :
        if((m_axi_bvalid == 1'b1) && (m_axi_bready == 1'b1))
            next_state = State_wait;
        else
            next_state = State_wdata;

    State_wait :
        if((MODE == 2'b01) && (wait_cnt == WAIT_TIME))
            next_state = State_waddr;
        else if(wait_cnt == WAIT_TIME)
            next_state = State_raddr;
        else
            next_state = State_wait;
    
    State_raddr :
        if((MODE == 2'b10) && (m_axi_arvalid == 1'b1) && (m_axi_arready == 1'b1))
            next_state = State_wait;
        else if((m_axi_arvalid == 1'b1) && (m_axi_arready == 1'b1))
            next_state = State_waddr;
        else
            next_state = State_raddr;

    default :
        next_state = State_idle;
    endcase
end

/*----------------------- Fixed Singals Region ----------------------------*/
assign m_axi_awid = 8'h0;
assign m_axi_awsize = AXSIZE_WTH;
assign m_axi_awburst = 2'b01;
assign m_axi_awprot = 3'b010;
assign m_axi_awlock = 1'b0;
assign m_axi_awcache = 4'b0011;
assign m_axi_wstrb = {AXI_DW/8{1'b1}};

assign m_axi_arid = 8'h0;
assign m_axi_arsize = AXSIZE_WTH;
assign m_axi_arburst = 2'b01;
assign m_axi_arprot = 3'b010;
assign m_axi_arlock = 1'b0;
assign m_axi_arcache = 4'b0011;

/*----------------------- Common Region ----------------------------*/
always @(posedge clk or negedge rstn)
begin
    if(rstn == 1'b0)
        burst_cnt <= 8'h0;
    else if((m_axi_wvalid == 1'b1) && (m_axi_wready == 1'b1) && (burst_cnt == m_axi_awlen))
		burst_cnt <= 8'h0;
    else if((m_axi_wvalid == 1'b1) && (m_axi_wready == 1'b1))
        burst_cnt <= burst_cnt + 1;
end

always @(posedge clk or negedge rstn)
begin
    if(rstn == 1'b0)
        wait_cnt <= 8'h0;
    else if(cur_state == State_wait)
		wait_cnt <= wait_cnt + 1;
    else
        wait_cnt <= 8'h0;
end

/*----------------------- Master AXI4 Write Bus Region ----------------------------*/
always @(posedge clk or negedge rstn)
begin
    if(rstn == 1'b0)
        m_axi_awvalid <= 1'b0;
    else if((m_axi_awvalid == 1'b1) && (m_axi_awready == 1'b1))
        m_axi_awvalid <= 1'b0;
    else if(cur_state == State_waddr)
        m_axi_awvalid <= 1'b1;	
end

always @(posedge clk or negedge rstn)
begin
    if(rstn == 1'b0)
        m_axi_awaddr <= {AXI_AW{1'h0}};
    else if((m_axi_bvalid == 1'b1) && (m_axi_bready == 1'b1))
        m_axi_awaddr <= m_axi_awaddr + AXI_LEN*AXSIZE;
end

always @(posedge clk or negedge rstn)
begin
    if(rstn == 1'b0)
        m_axi_awlen <= 8'h0;
    else
        m_axi_awlen <= AXI_LEN - 1;
end

always @(posedge clk or negedge rstn)
begin
    if(rstn == 1'b0)
        m_axi_wvalid <= 1'b0;
    else if((m_axi_awvalid == 1'b1) && (m_axi_awready == 1'b1))
				m_axi_wvalid <= 1'b1;//burst 
    else if((m_axi_wlast == 1'b1) && (m_axi_wready == 1'b1))
        m_axi_wvalid <= 1'b0;
end

always @(posedge clk or negedge rstn)
begin
    if(rstn == 1'b0)
        m_axi_wdata <= {AXI_DW{1'b0}};
    else if((m_axi_wvalid == 1'b1) && (m_axi_wready == 1'b1))
		m_axi_wdata <= m_axi_wdata + 1'b1;
end

always @(posedge clk or negedge rstn)
begin
    if(rstn == 1'b0)
        m_axi_wlast <= 1'b0;
    else if(((m_axi_awvalid == 1'b1) && (m_axi_awready == 1'b1) && (m_axi_awlen == 8'h0)) ||
            ((m_axi_wvalid == 1'b1) && (m_axi_wready == 1'b1) && (burst_cnt == m_axi_awlen-1) && (m_axi_awlen != 8'h0)))
				m_axi_wlast <= 1'b1;
    else if(m_axi_wready == 1'b1)
        m_axi_wlast <= 1'b0;
end

always @(posedge clk or negedge rstn)
begin
    if(rstn == 1'b0)
        m_axi_bready <= 1'b0;
    else if((m_axi_awvalid == 1'b1) && (m_axi_awready == 1'b1))
				m_axi_bready <= 1'b1;
    else if(m_axi_bvalid == 1'b1)
        m_axi_bready <= 1'b0;
end

/*----------------------- Master AXI4 Read Bus Region ----------------------------*/
always @(posedge clk or negedge rstn)
begin
    if(rstn == 1'b0)
        m_axi_arvalid <= 1'b0;
    else if((m_axi_arvalid == 1'b1) && (m_axi_arready == 1'b1))
        m_axi_arvalid <= 1'b0;
    else if(cur_state == State_raddr)
        m_axi_arvalid <= 1'b1;
end

always @(posedge clk or negedge rstn)
begin
    if(rstn == 1'b0)
        m_axi_araddr <= {AXI_AW{1'h0}};
    else if((m_axi_arvalid == 1'b1) && (m_axi_arready == 1'b1))
        m_axi_araddr <= m_axi_araddr + AXI_LEN*(AXI_DW/8);
end

always @(posedge clk or negedge rstn)
begin
    if(rstn == 1'b0)
        m_axi_arlen <= 8'h0;
    else
        m_axi_arlen <= AXI_LEN - 1;
end

assign m_axi_rready = 1'b1;

always @(posedge clk or negedge rstn)
begin
    if(rstn == 1'b0)
        rdata <= {AXI_DW{1'b0}};
    else if((m_axi_rvalid == 1'b1) && (m_axi_rready == 1'b1))
        rdata <= rdata + 1;
end

always @(posedge clk or negedge rstn)
begin
    if(rstn == 1'b0)
        rd_err <= 1'b0;
    else if((MODE == 2'b00) && (m_axi_rvalid == 1'b1) && (m_axi_rready == 1'b1) && (rdata != m_axi_rdata))
        rd_err <= 1'b1;
    else    
        rd_err <= 1'b0;
end

/*----------------------------------------------------------------------------------*\
                                 The function code
\*----------------------------------------------------------------------------------*/
function integer clogb2;
input [31:0] value;
begin
value = value - 1;
for (clogb2 = 0; value > 0; clogb2 = clogb2 + 1)
value = value >> 1;
end
endfunction

endmodule
