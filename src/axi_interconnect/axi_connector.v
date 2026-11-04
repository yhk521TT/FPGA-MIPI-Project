

module axi_connector #(
parameter AXI_ID_WIDTH = 8      ,
parameter AXI_DATA_WIDTH = 32,
parameter AXI_ADDR_WIDTH = 32
  
)(
input           clk,
input           rst_n,
//ch0
// AXI write address channel
input   [AXI_ADDR_WIDTH-1:0]  s0_awaddr,
input   [AXI_ID_WIDTH-1:0]   	s0_awid,
input   [7:0]   							s0_awlen,
input   [2:0]   							s0_awsize ,
input   [1:0]   							s0_awburst,


input           							s0_awvalid,
output        reg  						s0_awready,

// AXI write data channel
input   [AXI_DATA_WIDTH-1:0]  s0_wdata,
input   [31:0]   							s0_wstrb,
input           							s0_wlast,
input           							s0_wvalid,
output  reg        							s0_wready,
output  reg[AXI_ID_WIDTH-1:0] s0_bid,
output  reg[1:0]   						s0_bresp,
output  reg        						s0_bvalid,
input           							s0_bready,

// AXI read address channel
input   [AXI_ADDR_WIDTH-1:0]  s0_araddr,
input   [AXI_ID_WIDTH-1:0]   	s0_arid,
input   [7:0]   							s0_arlen,   
input  [2:0] 								s0_arsize , 
input  [1:0] 								s0_arburst, 

input           							s0_arvalid,
output    reg      						s0_arready,

// AXI read data channel
output  [AXI_DATA_WIDTH-1:0]  s0_rdata,
output  [AXI_ID_WIDTH-1:0]   	s0_rid,
output  [1:0]   							s0_rresp, 


output          							s0_rlast,
output          							s0_rvalid,
input           							s0_rready,
//ch1
// AXI write address channel
input   [AXI_ADDR_WIDTH-1:0]  s1_awaddr,
input   [AXI_ID_WIDTH-1:0]   	s1_awid,
input   [7:0]   							s1_awlen,
input   [2:0]   							s1_awsize ,
input   [1:0]   							s1_awburst,
input           							s1_awvalid,
output    reg      						s1_awready,

// AXI write data channel
input   [AXI_DATA_WIDTH-1:0]  s1_wdata,
input   [31:0]   							s1_wstrb,
input           							s1_wlast,
input           							s1_wvalid,
output  reg        							s1_wready,
output  reg[AXI_ID_WIDTH-1:0]  s1_bid,
output  reg[1:0]   						s1_bresp,
output  reg        						s1_bvalid,
input           							s1_bready,

// AXI read address channel
input   [AXI_ADDR_WIDTH-1:0]  s1_araddr,
input   [AXI_ID_WIDTH-1:0]   	s1_arid,
input   [7:0]   							s1_arlen,    
input  [2:0] 								s1_arsize ,
input  [1:0] 								s1_arburst,
input           							s1_arvalid,
output   reg       						s1_arready,

// AXI read data channel
output  [AXI_DATA_WIDTH-1:0]  s1_rdata,
output  [AXI_ID_WIDTH-1:0]   	s1_rid,
output  [1:0]   							s1_rresp,
output          							s1_rlast,
output          							s1_rvalid,
input           							s1_rready,

//ch2
// AXI write address channel
input   [AXI_ADDR_WIDTH-1:0]  							s2_awaddr,
input   [AXI_ID_WIDTH-1:0]   	s2_awid,
input   [7:0]   							s2_awlen,
input   [2:0]   							s2_awsize ,
input   [1:0]   							s2_awburst,

input           							s2_awvalid,
output   reg       							s2_awready,

// AXI write data channel
input   [AXI_DATA_WIDTH-1:0]  							s2_wdata,

input   [31:0]   							s2_wstrb,
input           							s2_wlast,
input           							s2_wvalid,
output reg         							s2_wready,
output reg [AXI_ID_WIDTH-1:0]   	s2_bid,
output reg [1:0]   							s2_bresp,
output reg         							s2_bvalid,
input           							s2_bready,

// AXI read address channel
input   [AXI_ADDR_WIDTH-1:0]  	s2_araddr,
input   [AXI_ID_WIDTH-1:0]   		s2_arid,
input   [7:0]   								s2_arlen,  
input  [2:0] 									s2_arsize ,
input  [1:0] 									s2_arburst,
input           								s2_arvalid,
output  reg        							s2_arready,

// AXI read data channel
output  [AXI_DATA_WIDTH-1:0]  	s2_rdata,
output  [AXI_ID_WIDTH-1:0]   	s2_rid,
output  reg[1:0]   								s2_rresp,
output          								s2_rlast,
output          									s2_rvalid,
input           									s2_rready,


output	reg [AXI_ID_WIDTH-1:0]		m_awid,
output	reg [31:0]								m_awaddr,
output	reg [7:0]									m_awlen,
output	reg [2:0]								m_awsize ,
output	reg [1:0]									m_awburst,
output	reg 											m_awvalid = 'd0,
input													m_awready,	

// AXI write data channel                 
output   reg [AXI_DATA_WIDTH-1:0]  							m_wdata,   

output   reg [31:0]   							m_wstrb  ,   
output   reg         								m_wlast ,   
output    reg        								m_wvalid,  
input          										m_wready,  
input  [AXI_ID_WIDTH-1:0]   			m_bid,     
input  [1:0]   										m_bresp,   
input          										m_bvalid,  
output  reg m_bready, //reg       							m_bready,  		


output	 reg[AXI_ID_WIDTH-1:0]		m_arid,
output	 reg[31:0]								m_araddr,
output	 reg[7:0]									m_arlen, 
output  reg[2:0] 								m_arsize ,
output  reg[1:0] 								m_arburst,
output	 	reg										m_arvalid,
input													m_arready,

// AXI read data channel                 
input  [AXI_DATA_WIDTH-1:0]  								m_rdata,  
input  [AXI_ID_WIDTH-1:0]   	m_rid,    
input  [1:0]   								m_rresp,  
input          								m_rlast,  
input          								m_rvalid, 
output          							m_rready);

localparam STRB_WIDTH =  AXI_DATA_WIDTH/8;

localparam S0 = 4'd0;
localparam S1 = 4'd1;
localparam S2 = 4'd2;
localparam S3 = 4'd3;
localparam S4 = 4'd4;
localparam S5 = 4'd5;
localparam S6 = 4'd6;
localparam S7 = 4'd7;
localparam S8 = 4'd8;


reg	[3:0] state = S0;
reg	[9:0]	test_cnt = 'd0;

always @( posedge clk or negedge rst_n )
begin
		if( !rst_n )
				test_cnt <= 0;
		else if( state == S1 )
				test_cnt <= test_cnt + 1'b1;
		else
				test_cnt <= 'd0;
end



always @( posedge clk or negedge rst_n ) 
begin   
		if( !rst_n ) 
				state <= S0;
		else begin
				case(state )
				S0 : begin
						if( s0_awvalid & s0_awready )
								state <= S1;
						else if( ~s0_awvalid )
								state <= S3;
				end
				S1: begin
						if( m_awvalid & m_awready )
								state <= S2;
				end
				S2 : begin
						if( m_wready & m_wlast & m_wvalid )
								state <= S3;
				end
				S3 : begin
						if( s1_awvalid & s1_awready  )
								state <= S4;
						else if( ~s1_awvalid )
								state <= S6;
				end
				S4 : begin
						if(m_awvalid & m_awready )
								state <= S5;
				end
				S5 : begin
						if( m_wready & m_wlast & m_wvalid  )
								state <= S6;
				end
				S6 : begin
						if( s2_awvalid & s2_awready  )
								state <= S7;
						else  if( ~s2_awvalid )
								state <= S0;
				end
				S7 : begin
						if(m_awvalid & m_awready )
								state <= S8;
				end
				S8 : begin
						if( m_wready & m_wlast & m_wvalid  )
								state <= S0;
				end
				default:;
				endcase
		end
end 	
		
	//address process	
		always @( posedge clk or negedge rst_n )
		begin
				if( !rst_n )
						s0_awready <= 1'b0;
				else if( s0_awvalid & s0_awready )
						s0_awready <= 1'b0;
				else if( s0_awvalid && state == S0 )
						s0_awready <= 1'b1;
						
		end
		
		always @( posedge clk or negedge rst_n )
		begin    
				if( !rst_n )
						s1_awready <= 1'b0; 
				else if( s1_awvalid & s1_awready )   
						s1_awready <= 1'b0;
				else if( s1_awvalid && state == S3 )
						s1_awready <= 1'b1;
						
		end
		
		always @( posedge clk or negedge rst_n )
		begin
				
				if( !rst_n )
						s2_awready <= 1'b0; 
				else if( s2_awvalid & s2_awready )
						s2_awready <= 1'b0;
				else if( s2_awvalid && state == S6 )
						s2_awready <= 1'b1;
						
		end
		
		always @( posedge clk or negedge rst_n )
		begin
				if( !rst_n )
						m_awvalid <= 1'b0;
				else if( m_awvalid & m_awready )     
						m_awvalid <= 1'b0;
				else if( (s0_awvalid && s0_awready)||(s1_awvalid && s1_awready)||(s2_awvalid && s2_awready) )
						m_awvalid <= 1'b1;   

		end
		
		always @( posedge clk )
		begin 
				if( s0_awvalid && state == S0 ) begin
						m_awaddr 	<= s0_awaddr;         
						m_awid 		<= s0_awid	;   
						m_awlen 	<= s0_awlen	;    
						m_awsize  <= s0_awsize ;   
						m_awburst  <= s0_awburst;
				end else if( state == S3 ) begin
						m_awaddr 	<= s1_awaddr	;         
						m_awid 		<= s1_awid		;   
						m_awlen 	<= s1_awlen	;  
						m_awsize  <= s1_awsize ;   
						m_awburst  <= s1_awburst;
				end else if( state == S6 ) begin
						m_awaddr 	<= s2_awaddr	;         
						m_awid 		<= s2_awid		;   
						m_awlen 	<= s2_awlen	;  
						m_awsize  <= s2_awsize ;   
						m_awburst  <= s2_awburst;
				end
				
				
		end
		//============================================
		//data process
		//============================================

		always @( *)
		begin
				if(  state == S2 ) begin
						m_wdata = s0_wdata;
						m_wlast = s0_wlast;  
						m_wstrb = s0_wstrb;   
						m_wvalid = s0_wvalid; 
						m_bready  = s0_bready;   
						s0_wready = m_wready;
						s1_wready = 1'b0;
						s2_wready = 1'b0;
				end else if( state == S5 ) begin  
						m_wdata = s1_wdata;
						m_wlast = s1_wlast;  
						m_wstrb = s1_wstrb;  
						m_wvalid = s1_wvalid; 
						m_bready  = s1_bready  ;   
						s1_wready = m_wready;    
						s0_wready = 1'b0; 
						s2_wready = 1'b0; 
				end else if( state == S8 ) begin
						m_wdata = s2_wdata;
						m_wlast = s2_wlast;  
						m_wstrb = s2_wstrb;
						m_wvalid = s2_wvalid;  
						m_bready  = s2_bready; 
						s2_wready = m_wready;
						s1_wready = 1'b0; 
						s0_wready = 1'b0; 
				end else begin
						m_wdata =  'd0;
						m_wlast =  'd0;
						m_wstrb =  'd0;
						m_wvalid = 'd0;
						s2_wready = 'd0;
						s1_wready = 1'b0;    
						s0_wready = 1'b0;    
				end
				
		end

		//==================================================================

localparam RD_S0 = 4'd0;
localparam RD_S1 = 4'd1;
localparam RD_S2 = 4'd2;
localparam RD_S3 = 4'd3;
localparam RD_S4 = 4'd4;
localparam RD_S5 = 4'd5;	
localparam RD_S6 = 4'd6;
localparam RD_S7 = 4'd7;
localparam RD_S8 = 4'd8;
reg	[3:0] rd_state = RD_S0;		
always @( posedge clk or negedge rst_n ) 
begin   
		if( !rst_n ) 
				rd_state <= RD_S0;
		else begin
				case(rd_state )
				RD_S0 : begin
						if( s0_arvalid & s0_arready )
								rd_state <= RD_S1;
						else if( ~s0_arvalid )
								rd_state <= RD_S3;
				end     
				RD_S1 : begin
						if( m_arvalid & m_arready )
								rd_state <= RD_S2;
				end
				RD_S2 : begin
						if( s0_rready & s0_rlast & s0_rvalid )
								rd_state <= RD_S3;
				end
				//=============================
				RD_S3 : begin
						if( s1_arvalid & s1_arready  )
								rd_state <= RD_S4;
						else if( ~s1_arvalid )
								rd_state <= RD_S6;
				end
				RD_S4 : begin
						if( m_arvalid & m_arready )
								rd_state <= RD_S5;
				end
				RD_S5 : begin
						if( s1_rready & s1_rlast & s1_rvalid )
								rd_state <= RD_S6;
				end
				//===========================
				RD_S6 : begin
						if( s2_arvalid & s2_arready  )
								rd_state <= RD_S7;
						else  if( ~s2_arvalid )
								rd_state <= RD_S0;
				end
				RD_S7 : begin
						if( m_arvalid & m_arready )
								rd_state <= RD_S8;
				end
				S8 : begin
						if( s2_rready & s2_rlast & s2_rvalid )
								rd_state <= RD_S0;
				end
				default:;
				endcase
		end
end 			

always @( posedge clk or negedge rst_n )
		begin
				if( !rst_n )
						s0_arready <= 1'b0;
				else if( s0_arvalid & s0_arready )
						s0_arready <= 1'b0;
				else if( s0_arvalid && rd_state == RD_S0 )
						s0_arready <= 1'b1;
						
		end
		
		always @( posedge clk or negedge rst_n )
		begin    
				if( !rst_n )
						s1_arready <= 1'b0; 
				else if( s1_arvalid & s1_arready )   
						s1_arready <= 1'b0;
				else if( s1_arvalid && rd_state == RD_S3 )
						s1_arready <= 1'b1;
						
		end
		
		always @( posedge clk or negedge rst_n )
		begin
				
				if( !rst_n )
						s2_arready <= 1'b0; 
				else if( s2_arvalid & s2_arready )
						s2_arready <= 1'b0;
				else if( s2_arvalid && rd_state == RD_S6 )
						s2_arready <= 1'b1;
						
		end
		
		always @( posedge clk or negedge rst_n )
		begin
				if( !rst_n )
						m_arvalid <= 1'b0;
				else if( m_arvalid & m_arready )     
						m_arvalid <= 1'b0;
				else if( s0_arvalid && s0_arready )
						m_arvalid <= 1'b1;   
				else if( s1_arvalid && s1_arready )
						m_arvalid <= 1'b1;
				else if( s2_arvalid && s2_arready )
						m_arvalid <= 1'b1;

		end
		
		always @( posedge clk )
		begin 
				if( s0_arvalid && rd_state == RD_S0 ) begin
						m_araddr 	<= s0_araddr;         
						m_arid 		<= s0_arid	;   
						m_arlen 	<= s0_arlen	;    
						
						m_arsize 	 <= s0_arsize ;  
						m_arburst	 <= s0_arburst;
				end else if( rd_state == RD_S3 ) begin    
						m_arsize 	 <= s1_arsize ; 
						m_arburst	 <= s1_arburst; 
						m_araddr 	<= s1_araddr	;         
						m_arid 		<= s1_arid		;   
						m_arlen 	<= s1_arlen	;  
				end else if( rd_state == RD_S6 ) begin    
						m_arsize 	 <= s2_arsize ; 
						m_arburst	 <= s2_arburst; 
						m_araddr 	<= s2_araddr	;         
						m_arid 		<= s2_arid		;   
						m_arlen 	<= s2_arlen	;  
				end
		end
		
		assign s2_rdata = m_rdata;
		assign s1_rdata = m_rdata;
		assign s0_rdata = m_rdata;
		assign s0_rid 	= m_rid;
		assign s1_rid 	= m_rid;
		assign s2_rid 	= m_rid;     
		
		
		
		
		
		
		
		assign s0_rlast = ( rd_state == RD_S2 ) ? m_rlast : 1'b0;
		assign s1_rlast = (rd_state == RD_S5 ) ? m_rlast : 1'b0;
		assign s2_rlast = (rd_state == RD_S8 ) ? m_rlast : 1'b0;
		assign s0_rvalid = (rd_state == RD_S2 ) ? m_rvalid : 1'b0;
		assign s1_rvalid = (rd_state == RD_S5 ) ? m_rvalid : 1'b0;
		assign s2_rvalid = (rd_state == RD_S8 ) ? m_rvalid : 1'b0;
		assign m_rready =  (rd_state == RD_S2 ) ? s0_rready :(
												(rd_state == RD_S5 ) ?s1_rready :(
												(rd_state == RD_S8 ) ?s2_rready:0 ));
 
 
 
 
endmodule