
module ddr_wr_buffer#(
    parameter AXI_DATA_WIDTH = 512, //!AXI接口位宽
    parameter AXI_ADDR_WIDTH = 32,  //!AXI地址位宽
    parameter WR_FIFO_DEPTH	= 1024, //!Write fifo depth   
    parameter BURST_LEN = 'd7,
    parameter AXI_STRB_WIDTH = AXI_DATA_WIDTH/8,//!总共的字节数量，= AXI_DATA_WIDTH/8
    parameter AXSIZE_WTH = $clog2(AXI_DATA_WIDTH/8),//!内部数据
    parameter AXI_BURST_WIDTH = $clog2(AXI_DATA_WIDTH/8),
    parameter WR_USEDW_WITH = $clog2(WR_FIFO_DEPTH) //!内部数据
    
    
    )(
        
input 								        axi_clk,
input 								        rst_n,
input								        wr_start, // pulse signal 

input		[AXI_ADDR_WIDTH-1:0]	        start_addr,
input		[31:0]							burst_len,
output	wire 								wr_end_flag,

input                                       wr_fifo_rst_p,
input										wr_fifo_wrclk,
input										wr_fifo_wren,
output										wr_fifo_wrfull,
input	 [AXI_DATA_WIDTH-1:0]		        wr_fifo_wrdata, 
output [ WR_USEDW_WITH:0]			        wr_fifo_wrusedw, 

output 	[5:0] 								awid,
output  reg [AXI_ADDR_WIDTH-1:0] 	        awaddr = 'd0,
output  reg [AXI_BURST_WIDTH-1:0] 			awlen = 'd0,
output  [2:0] 					            awsize,
output  [1:0] 								awburst,
output  [3:0] 								awcache,
output  									awlock,
output  reg 								awvalid = 1'b0,
output  									awcobuf,
output  									awapcmd,
output  									awallstrb,
output reg 									awqos = 'd0,
input 										awready,

output [31:0]                               wr_fifo_rd_data_test,
output  [AXI_DATA_WIDTH-1:0] 	            wdata,  
output  [AXI_STRB_WIDTH-1:0] 	            wstrb,
output  reg									wlast,
output  									wvalid,
input 										wready,
input [5:0] 								bid,
input 										bvalid,
output reg  								bready,
output reg [15:0] test_cnt
    );
//=================================================================================

    localparam WR_ADDR_SHIFT_BITS = $clog2(AXI_DATA_WIDTH/8);
    localparam MAX_BURST_LEN = 4096/(AXI_DATA_WIDTH/8);
    //=============================================================
    //reg define 
    //=============================================================   
        
    reg	    	[1:0]							                start_sync = 'd0;
    reg [31:0]	burst_len_r   = 'd0;
   
    reg	[AXI_BURST_WIDTH-1:0] 						        last_burst_cnt = 'd0;
    reg [AXI_BURST_WIDTH-1:0]                               first_burst_cnt = 'd0;
    reg                                                     sync_r1 = 1'b0;
    reg                                                     sync_r0 = 1'b0;
    reg                                                     sync_r2 = 1'b0;
    reg                                                     sync_r3 = 1'b0;
    reg [31:0]                                              align_burst_num = 'd0;
    reg [31:0]                                              total_burst_num = 'd0;
    reg [AXI_ADDR_WIDTH-1:0]                                start_addr_r = 'd0;
    //=============================================================
    //wire define 
    //============================================================= 
    wire   [ WR_USEDW_WITH:0] 		wr_fifo_rdusedw;
wire [AXI_DATA_WIDTH-1:0]		wr_fifo_rddata;
wire							wr_fifo_rdempty;  
wire							wr_fifo_rden;
wire 							pos_sync;
wire [AXI_ADDR_WIDTH-1:0]  		nx_ddr_wr_addr;
wire axi_wr_clk = axi_clk;
//=============================================================  
//RTL                                                     
//=============================================================  

	DC_FIFO
# (
  	.FIFO_MODE  ( "Normal"    ), //"Normal"; //"ShowAhead"
    .DATA_WIDTH ( AXI_DATA_WIDTH ),
    .FIFO_DEPTH ( WR_FIFO_DEPTH   )
  ) u_wr_fifo(   
  //System Signal
  /*i*/.Reset   (wr_fifo_rst_p	|| (~rst_n) ), 
  /*i*/.WrClk   (wr_fifo_wrclk		), 
  /*i*/.WrEn    (wr_fifo_wren		), 
  /*o*/.WrDNum  (wr_fifo_wrusedw	), 
  /*o*/.WrFull  (wr_fifo_wrfull 	), 
  /*i*/.WrData  (wr_fifo_wrdata 	), 
  /*i*/.RdClk   (axi_clk			), 
  /*i*/.RdEn    (wr_fifo_rden		), 
  /*o*/.RdDNum  (wr_fifo_rdusedw	), 
  /*o*/.RdEmpty (wr_fifo_rdempty	), 
  /*o*/.RdData  (wr_fifo_rddata		)  
);

assign wr_fifo_rd_data_test =  wr_fifo_rddata[511:478];

always @( posedge axi_clk or negedge rst_n )
begin
    if( !rst_n )		start_sync <= 'd0;
    else 			start_sync <= {start_sync[0],wr_fifo_rst_p};
end

assign pos_sync = start_sync[1:0] == 2'b01;

always @( posedge axi_clk or negedge rst_n )
begin
	if( !rst_n ) begin
		sync_r0 <= 1'b0;
		sync_r1 <= 1'b0;
		sync_r2 <= 1'b0;
        sync_r3 <= 1'b0;
	end else begin 
		sync_r0 <= pos_sync;
		sync_r1 <= sync_r0;
		sync_r2 <= sync_r1;
        sync_r3 <= sync_r2;
	end 
end

always @( posedge axi_clk or negedge rst_n )
begin
	if( !rst_n ) begin
		burst_len_r   <= burst_len;//end_address - start_address
        start_addr_r <= start_addr;
	end else begin
		burst_len_r   <= pos_sync ? burst_len : burst_len_r ;
        start_addr_r <= pos_sync ? start_addr:start_addr_r;
	end
end


  
wire [12-WR_ADDR_SHIFT_BITS:0]     first_4k_burst_len = {1'b0,~start_addr_r[11:WR_ADDR_SHIFT_BITS]} + 1'b1;
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
                // 8'd127:first_burst_cnt <= |first_4k_burst_len[6:0]?{1'd0,first_4k_burst_len[6:0]}-1:BURST_LEN;;
                // 8'd255:first_burst_cnt <= |first_4k_burst_len[7:0]?{first_4k_burst_len[7:0]}-1:BURST_LEN;;
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
			8'd1 : last_burst_cnt <= |last_4k_burst_len[0]  ? {7'd0,last_4k_burst_len[0]}-1  :BURST_LEN;
			8'd3 : last_burst_cnt <= |last_4k_burst_len[1:0]? {6'd0,last_4k_burst_len[1:0]}-1:BURST_LEN;
			8'd7 : last_burst_cnt <= |last_4k_burst_len[2:0]? {5'd0,last_4k_burst_len[2:0]}-1:BURST_LEN;
			8'd15: last_burst_cnt <= |last_4k_burst_len[3:0]? {4'd0,last_4k_burst_len[3:0]}-1:BURST_LEN;
			8'd31: last_burst_cnt <= |last_4k_burst_len[4:0]? {3'd0,last_4k_burst_len[4:0]}-1:BURST_LEN;
			8'd63: last_burst_cnt <= |last_4k_burst_len[5:0]? {2'd0,last_4k_burst_len[5:0]}-1:BURST_LEN;
			default:;
		endcase
		end 
    end 
end 

always @( posedge axi_clk or negedge rst_n   )
begin 
    if( !rst_n ) begin
        align_burst_num <= 'd0;
    end else begin //sync_r1;
	    align_burst_num <= burst_len_r - first_burst_cnt - last_burst_cnt -2 ;
    end 
end

always @( posedge axi_clk or negedge rst_n   )
begin
    if( !rst_n ) begin
        total_burst_num <= 'd0;
    end else begin 
		if(sync_r2) begin
		case( BURST_LEN)
			8'd1 : total_burst_num <= align_burst_num[31:1] + 2 ;
			8'd3 : total_burst_num <= align_burst_num[31:2] + 2 ;
			8'd7 : total_burst_num <= align_burst_num[31:3] + 2 ;
			8'd15: total_burst_num <= align_burst_num[31:4] + 2 ;
			8'd31: total_burst_num <= align_burst_num[31:5] + 2 ;
			8'd63: total_burst_num <= align_burst_num[31:6] + 2 ;
			default:;
		endcase
		end 
    end 
end 		
//=======================================================================================
//address process
//=======================================================================================
wire addr_add_en;
reg addr_add_last = 'd0;
reg [31:0] burst_cnt = 'd0;
reg [1:0] state = 'd0;
assign wr_end_flag = addr_add_last;
always @(posedge axi_clk or negedge rst_n) 
begin
	if (!rst_n) 							                    awaddr      <= start_addr_r;//start_addr;
	else if(sync_r2)				                            awaddr      <= start_addr_r;//start_addr;//( pos_sync )
	else if( addr_add_en ) 				                        awaddr      <= nx_ddr_wr_addr;
end      
assign nx_ddr_wr_addr =  awaddr + {(awlen+1) ,{WR_ADDR_SHIFT_BITS{1'b0}}};  
always @( posedge axi_clk or negedge rst_n )
begin
 	if( !rst_n )  							                    burst_cnt <= 'd0;
 	else if(sync_r2)					                        burst_cnt <= 'd0;//( pos_sync )
 	else if( addr_add_en )					                    burst_cnt <= burst_cnt + 1'b1;
end 
always @( posedge axi_clk or negedge rst_n )
begin
	if( !rst_n )										        addr_add_last <= 1'b0;
	else if(sync_r2)						                    addr_add_last <= 1'b0;	//( pos_sync )	
    else if( addr_add_en && total_burst_num == burst_cnt+'d1  ) addr_add_last <= 1'b1;
end 



assign addr_add_en = wvalid & wready & wlast;//
always @( posedge axi_clk or negedge rst_n  )
begin
    if( !rst_n ) 								                awlen 	    <= first_burst_cnt;
    else if( sync_r2 )						                    awlen 	    <= first_burst_cnt;	 
    else if(addr_add_en && total_burst_num == burst_cnt+'d2 )	awlen	    <= last_burst_cnt;
    else if( addr_add_en )						                awlen 	    <= BURST_LEN;	
end
reg wdata_en = 1'b0;
reg [8:0] write_cnt = 'd0;
// always@( posedge axi_clk or negedge rst_n )
// begin
//     if( !rst_n ) begin 
//         state <= 'd0;
//         wdata_en <= 1'b0;
//         awvalid <= 1'b0;
//     end else if( sync_r2 ) begin 
//         state <= 'd0;
//         wdata_en <= 1'b0;
//         awvalid <= 1'b0;
//     end else begin
//         case( state )
//         2'd0 : begin
//             if( sync_r3)
//                 state <= 2'd1;
//         end 
//         2'd1 : begin
//             if( wr_fifo_rdusedw >= awlen+1 ) begin
//                 state <= 2'd2;
//                 awvalid <= 1'b1;
//             end 
//             wdata_en <= 1'b0;
//         end 
//         2'd2 : begin
//             if( awready )
//                 awvalid <= 1'b0;

//             if( write_cnt == awlen && wr_fifo_rden ) begin 
//                 wdata_en <= 1'b0;
//                 state <= 2'd3;
//             end else begin 
//                 wdata_en <= 1'b1;
//             end 

//         end 
//         2'd3 : begin
//             state <= awvalid ? 2'd3 : 2'd1;
//         end 
//         default:;
//         endcase
//     end 
// end 
reg first_rd = 1'b0;
always@( posedge axi_clk or negedge rst_n )
begin
    if( !rst_n ) begin 
        state <= 'd0;
        awvalid <= 1'b0;
    end else if( sync_r2 ) begin 
        state <= 'd0;
        awvalid <= 1'b0;
    end else begin
        first_rd <= 1'b0;
        case( state )
        2'd0 : begin
            // if( sync_r3)
                
            if( ~wr_fifo_rdempty) begin
                state <= 2'd1;
                first_rd <= 1'b1;
            end
        end 
        2'd1 : begin
            if( wr_fifo_rdusedw >= awlen ) begin
                state <= 2'd2;
                awvalid <= 1'b1;
            end 
        end 
        2'd2 : begin
            if( awready )
                awvalid <= 1'b0;
            if( wlast & wready ) begin 
                state <= wr_fifo_rden ? 2'd1 : 2'd0;
            end
        end 
        2'd3 : begin
            state <= awvalid ? 2'd3 : 2'd1;
        end 
        default:;
        endcase
    end 
end 

always @( posedge axi_clk or negedge rst_n )
begin
    if( !rst_n )
        test_cnt <= 'd0;
    else if( state == 2 )
        test_cnt <= test_cnt + 1'b1;
    else 
        test_cnt <= 'd0; 
end

always @( posedge axi_clk or negedge rst_n )
begin
    if( !rst_n ) begin
        write_cnt <= 'd0;
    end else if( state == 2'd2 ) begin
        if(wr_fifo_rden )//( wready & wvalid )
            write_cnt <= write_cnt + 1'b1;
    end else begin
            write_cnt <= 'd0;
    end 
end 



always @( posedge axi_clk or negedge rst_n )
begin
    if( !rst_n )
        wlast <= 1'b0;
    else if( wready & wvalid & wlast )
        wlast <= 1'b0;
    else if( state == 2'd2 ) begin
        if( awlen == 0 )
            wlast <= 1'b1;
        else if( write_cnt  == awlen-1 && wready && wvalid)
            wlast <= 1'b1;
    end 
end 

always @( posedge axi_clk or negedge rst_n )
begin
    if( !rst_n )
        wdata_en <= 1'b0;
    else if( state == 2'd2 ) begin
        wdata_en <= (wlast & wready ) ? 1'b0 : 1'b1;
    end else begin
        wdata_en <= 1'b0;
    end
end
assign wr_fifo_rden =  ( first_rd)||(wready & wdata_en & ~wr_fifo_rdempty );//
assign wvalid = wdata_en;
//=============================================================================================
//data process
//=============================================================================================

assign wdata		= wr_fifo_rddata;
assign awlock 		= 2'b00;  
assign awapcmd 		= 1'b0;  
assign awcobuf 		= 1'b0;  
assign awcache 		= 4'd0;  
assign awallstrb 	= 1'b0;
assign awburst 		= 2'b01;
assign awsize  		= AXSIZE_WTH;
assign awid 		= 6'd0;
assign wstrb 		= {AXI_STRB_WIDTH{1'b1}};  
always @( posedge axi_clk or negedge rst_n )
begin
		if( !rst_n )							bready	<= 1'b0;
		else 									bready  <= 1'b1;
end
always @( posedge axi_clk or negedge rst_n )
begin
		if( !rst_n )							awqos <= 1'b0;
		else                					awqos <= 1'b1;
end 
   


endmodule 
