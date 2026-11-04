
`timescale 1ps/1ps
module ddr_rd_buffer #(
parameter AXI_DATA_WIDTH = 512, //!AXI接口位宽
parameter AXI_ADDR_WIDTH = 33,  //!AXI地址位宽
parameter BURST_LEN = 'd7,
parameter AXI_STRB_WIDTH = AXI_DATA_WIDTH/8,//!总共的字节数量，= AXI_DATA_WIDTH/8
parameter AXI_BURST_WIDTH = $clog2(AXI_DATA_WIDTH/8),
parameter AXSIZE_WTH = $clog2(AXI_DATA_WIDTH/8)//!内部数据

) (

input 								            axi_clk,
input 								            rst_n,
input 								            start,//!电平有效。

input		[AXI_ADDR_WIDTH-1:0]	            start_addr,
input		[31:0]								burst_len,

output reg                                          ddr_rd_valid,
output reg [AXI_DATA_WIDTH-1:0] 					ddr_rd_data,
input 										        rd_fifo_wr_full,
output   										rd_end_flag ,

output [5:0] 									    arid,
output  reg [AXI_ADDR_WIDTH-1:0] 	                araddr = 'd0,
output  [AXI_BURST_WIDTH-1:0] 						arlen,
output  [2:0] 										arsize,
output  [1:0] 										arburst,
output  											arlock,
output  reg											arvalid,
output  											arapcmd,
output 												arqos,
input 												arready,

input [5:0] 									rid,
input [AXI_DATA_WIDTH-1:0] 						rdata,
input 											rlast,
input 											rvalid,
output  										rready,
input [1:0] 									rresp

);
localparam ADDR_SHIFT_BITS = $clog2(AXI_STRB_WIDTH);
// reg 										ddr_rd_valid;                      
// reg [AXI_DATA_WIDTH-1:0] 					ddr_rd_data;     
reg	[AXI_BURST_WIDTH-1:0]					ddr_arlen = 'd0; 
reg			[2:0]							start_sync = 'd0;
wire [AXI_ADDR_WIDTH-1:0] 					nx_ddr_addr;
wire										rd_addr_en	;
reg	[31:0]									burst_len_r = 'd0;
reg											burst_last ='d0;
reg [AXI_ADDR_WIDTH-1:0] 					start_addr_r = 'd0;
reg                                         sync_r0 = 'd0;
reg                                         sync_r1 = 'd0;
reg                                         sync_r2 = 'd0;
reg [AXI_BURST_WIDTH-1:0]                   first_burst_cnt = 'd0;
reg	[AXI_BURST_WIDTH-1:0] 			        last_burst_cnt = 'd0;
reg [31:0]                                  align_burst_num = 'd0;
reg [31:0]                                  total_burst_num = 'd0;
reg [31:0]                                  burst_cnt = 'd0;
//wire pos_start;
always @( posedge axi_clk or negedge rst_n )
begin
	if( !rst_n )			start_sync <= 'd0;
	else 				start_sync <= {start_sync[1:0],start};
end

assign pos_start = start_sync[1:0] == 2'b01;
always @( posedge axi_clk or negedge rst_n )
begin
	if( !rst_n ) begin
		sync_r0 <= 1'b0;
		sync_r1 <= 1'b0;
		sync_r2 <= 1'b0;
	end else begin 
		sync_r0 <= pos_start;
		sync_r1 <= sync_r0;
		sync_r2 <= sync_r1;
	end 
end

always @( posedge axi_clk or negedge rst_n )
begin
	if( !rst_n ) begin
			burst_len_r<= burst_len;
			start_addr_r <= start_addr;
	end else begin
			burst_len_r<= pos_start ? burst_len : burst_len_r ;
			start_addr_r <= pos_start ? start_addr:start_addr_r;
	end
end

wire [12-ADDR_SHIFT_BITS:0]     first_4k_burst_len = {1'b0,~start_addr_r[11:ADDR_SHIFT_BITS]} + 1'b1;
wire [31:0]     last_4k_burst_len  = burst_len_r - first_4k_burst_len;

always @( posedge axi_clk or negedge rst_n )
begin
        if( !rst_n ) begin
            first_burst_cnt <= 'd0;
        end else begin 
            if(sync_r0) begin
            case( BURST_LEN)
                8'd1 : first_burst_cnt <= |first_4k_burst_len[0]  ? {7'd0,first_4k_burst_len[0]}-'d1  :BURST_LEN;
                8'd3 : first_burst_cnt <= |first_4k_burst_len[1:0]? {6'd0,first_4k_burst_len[1:0]}-'d1:BURST_LEN;
                8'd7 : first_burst_cnt <= |first_4k_burst_len[2:0]? {5'd0,first_4k_burst_len[2:0]}-'d1:BURST_LEN;
                8'd15: first_burst_cnt <= |first_4k_burst_len[3:0]? {4'd0,first_4k_burst_len[3:0]}-'d1:BURST_LEN;
                8'd31: first_burst_cnt <= |first_4k_burst_len[4:0]? {3'd0,first_4k_burst_len[4:0]}-'d1:BURST_LEN;
                8'd63: first_burst_cnt <= |first_4k_burst_len[5:0]? {2'd0,first_4k_burst_len[5:0]}-'d1:BURST_LEN;
                // 8'd127:first_burst_cnt <= |first_4k_burst_len[6:0]?{1'd0,first_4k_burst_len[6:0]}-1:cfg_awlen_r;;
                // 8'd255:first_burst_cnt <= |first_4k_burst_len[7:0]?{first_4k_burst_len[7:0]}-1:cfg_awlen_r;;
                default:;
            endcase
            end 
        end 
end 
always @( posedge axi_clk or negedge rst_n  )
begin
    if( !rst_n ) begin
        last_burst_cnt <= 'd0;
    end else begin 
		if(sync_r0) begin
		case( BURST_LEN)
			8'd1 : last_burst_cnt <= |last_4k_burst_len[0]  ? {7'd0,last_4k_burst_len[0]}-'d1  :BURST_LEN;
			8'd3 : last_burst_cnt <= |last_4k_burst_len[1:0]? {6'd0,last_4k_burst_len[1:0]}-'d1:BURST_LEN;
			8'd7 : last_burst_cnt <= |last_4k_burst_len[2:0]? {5'd0,last_4k_burst_len[2:0]}-'d1:BURST_LEN;
			8'd15: last_burst_cnt <= |last_4k_burst_len[3:0]? {4'd0,last_4k_burst_len[3:0]}-'d1:BURST_LEN;
			8'd31: last_burst_cnt <= |last_4k_burst_len[4:0]? {3'd0,last_4k_burst_len[4:0]}-'d1:BURST_LEN;
			8'd63: last_burst_cnt <= |last_4k_burst_len[5:0]? {2'd0,last_4k_burst_len[5:0]}-'d1:BURST_LEN;
			default:;
		endcase
		end 
    end 
end 

always @( posedge axi_clk or negedge rst_n   )
begin 
    if( !rst_n ) begin
        align_burst_num <= 'd0;
    end else begin //w_wr_sync_r1;
	    align_burst_num <= burst_len_r - first_burst_cnt - last_burst_cnt -'d2 ;
    end 
end

always @( posedge axi_clk or negedge rst_n   )
begin
    if( !rst_n ) begin
        total_burst_num <= 'd0;
    end else begin 
		if(sync_r2) begin
		case( BURST_LEN)
			8'd1 : total_burst_num <= align_burst_num[31:1] + 'd2 ;
			8'd3 : total_burst_num <= align_burst_num[31:2] + 'd2 ;
			8'd7 : total_burst_num <= align_burst_num[31:3] + 'd2 ;
			8'd15: total_burst_num <= align_burst_num[31:4] + 'd2 ;
			8'd31: total_burst_num <= align_burst_num[31:5] + 'd2 ;
			8'd63: total_burst_num <= align_burst_num[31:6] + 'd2 ;
			default:;
		endcase
		end 
    end 
end 	
//====================================================================================
//address process
always @(posedge axi_clk or negedge rst_n) 
begin
	if (!rst_n) 									        araddr <= start_addr_r;
	else if( sync_r2 )						                araddr <= start_addr_r;
	else if (rd_addr_en) 						            araddr <= nx_ddr_addr;
    
end 
assign nx_ddr_addr =  araddr + {(ddr_arlen+1),{ADDR_SHIFT_BITS{1'b0}} };  

assign rd_addr_en = rvalid & rready & rlast;
//=====================================================================================

//ddr alen process
always @( posedge axi_clk or negedge rst_n )
begin
 	if( !rst_n )  							                burst_cnt <= 0;
 	else if(sync_r2)					                    burst_cnt <= 0;//( w_wr_sync0 )
 	else if( rd_addr_en )					                burst_cnt <= burst_cnt + 1'b1;
end 

always @( posedge axi_clk or negedge rst_n )
begin
    if( !rst_n )								            burst_last <= 1'b0;
    else if( sync_r2 )					                    burst_last <= 1'b0;	
    else if(rd_addr_en && total_burst_num == burst_cnt+2 )  burst_last <= 1'b1;
end 

always @( posedge axi_clk or negedge rst_n  )
begin
    if( !rst_n ) 							                    ddr_arlen 	<= BURST_LEN;
    else if( sync_r2 )						                    ddr_arlen 	<= first_burst_cnt;	 
    else if(rd_addr_en && total_burst_num == burst_cnt+2)		ddr_arlen	<= last_burst_cnt;//(rd_addr_en && burst_last) 
    else if( rd_addr_en )					                    ddr_arlen 	<= BURST_LEN;
end



reg arvalid_en;
reg last_addr_wr_valid = 1'b0;
wire w_last_addr_wr_valid = burst_last & arvalid & arready;
assign rd_end_flag = last_addr_wr_valid;
always @( posedge axi_clk or negedge rst_n )
begin
	if( !rst_n )
		arvalid <= 1'b0;
	else if( arvalid & arready )
		arvalid <= 1'b0;
	else if(sync_r2 || ( rd_addr_en | arvalid_en) && (~rd_fifo_wr_full) && ~(w_last_addr_wr_valid |last_addr_wr_valid))
		arvalid <= 1'b1;
end



always @( posedge axi_clk or negedge rst_n )
begin
	if( !rst_n )					last_addr_wr_valid <= 1'b0;
	else if( sync_r2 ) 				last_addr_wr_valid <= 1'b0;
	else if( w_last_addr_wr_valid) 	last_addr_wr_valid <= 1'b1;
end

always @(posedge axi_clk or negedge rst_n) begin
	if( !rst_n )
		arvalid_en <= 1'b0;
	else if( arvalid & arready )
		arvalid_en <= 1'b0;
	else if( rd_addr_en )
		arvalid_en <= 1'b1;
end




always @(posedge axi_clk or negedge rst_n )											
begin
	if( !rst_n )									ddr_rd_valid <= 1'b0;
	else											ddr_rd_valid <= rvalid & rready;				
end 			

always @( posedge axi_clk )
begin
    ddr_rd_data <= rdata;
end

assign arapcmd  = 1'b0;  
assign arlock   = 1'b0;  
assign arqos    = 1'b0; 
assign arid     = 6'h00;
assign arsize   = AXSIZE_WTH;
assign arlen	= ddr_arlen;
assign arburst  = 2'b01;
assign rready   = 1'b1;//~rd_fifo_wr_full & start ;


endmodule