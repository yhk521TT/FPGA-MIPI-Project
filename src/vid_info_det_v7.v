// 2025.2.14
// v5 :解决h_act 及frame_statble异常问题
// v6: frame_stable 时，frame_len必须要大于64x64，意在排除frame_len == 0的情况；
//   :timeout flag 防止数据frame_stable
module vid_info_det #(
	parameter CLK_FREQ = 32'd100_000_000
) (
input		wire									clk	,    
input		wire									rst_n,
input		wire									i_vs, //active hgih
input     	wire 									i_hs,
input		wire									i_de, //active high

output	reg			[23:0]							frame_cnt_o,//! frame pixel number
output	reg											frame_stable,//!frame stable flag
output	reg											neg_vs_sync,//! 1:vsync = 0; 0:vsync = 1
output  reg  										neg_hs_sync,//! 1:hsync = 0 ; 0:hsync = 1
output  reg [13:0] 									o_h_act,//! number of active pixcel of each line
output  reg   										h_active_error,
output  reg [13:0] 									o_v_act,//!number of active pixcel lines
output  reg  										v_active_error,
output  reg [13:0]  								o_v_total,
output  reg  										v_total_error,
output  reg [13:0] 									o_h_total,
output  reg  										h_total_error,
output  reg  										h_sync_error

);

  
  reg											vs_r0 = 1'b0;
  reg											de_r0 = 1'b0;
  reg											de_r1 = 1'b0;
  reg  											hs_r0 = 1'b0;
  wire 											neg_vs;
  wire											pos_vs;
  reg						[1:0]				frame_num = 'd0;  
  reg						[23:0]				frame_cnt = 'd0; 
  reg						[23:0] 				frame_len_d0 = 'd0;
  reg						[23:0] 				frame_len_d1 = 'd0; 
  reg						[23:0] 				frame_len_d2 = 'd0; 
  reg  						[13:0] 				h_cnt = 'd0;
  reg  						[13:0] 				v_cnt = 'd0;
  reg       				[13:0] 				v_total_cnt = 'd0;
  reg   					[13:0] 				h_total_cnt = 'd0;
  reg  						[13:0] 				h_sync_len = 'd0;
  reg [31:0] timeout_cnt = 'd0;
  wire timeout;
  //======================================================================================== 
  // detect sync
  //========================================================================================
  always @( posedge clk )
  begin
		if( i_de ) begin
			if( i_vs )
				neg_vs_sync <= 1'b1;
			else
				neg_vs_sync = 1'b0;
		end
  end 

  always @( posedge clk )
  begin
	 if( i_de ) begin
		if( i_hs )
			neg_hs_sync <= 1'b1;
		else 
			neg_hs_sync <= 1'b0;	
	 end
  end
  //======================================================================================== 
  // start and end hs,vs
  //========================================================================================
  always @( posedge clk )
  begin
  		vs_r0 	<= i_vs;  		
  		de_r0 	<= i_de; 
  		de_r1 	<= de_r0;
		hs_r0 	<= i_hs;
  end
  assign neg_vs = {vs_r0,i_vs} == 2'b10;   //video start
  assign pos_vs = {vs_r0,i_vs} == 2'b01;	 //video end
  assign pos_hs = {hs_r0,i_hs} == 2'b01;
  assign neg_hs = {hs_r0,i_hs} == 2'b10;
  assign pos_de = {de_r0,i_de} == 2'b01;
  assign neg_de = {de_r0,i_de} == 2'b10;
  wire vs_start = (~neg_vs_sync & neg_vs ) || (neg_vs_sync & pos_vs );
  wire vs_end   = (~neg_vs_sync & pos_vs ) || (neg_vs_sync & neg_vs );
  wire hs_start	= (~neg_hs_sync & neg_hs ) || (neg_hs_sync & pos_hs );
  wire hs_end 	= (~neg_hs_sync & pos_hs ) || (neg_hs_sync & neg_hs );

//======================================================================================== 
// frame pixcel number and stable signal
//========================================================================================

  always @( posedge clk or negedge rst_n )
  begin
		if( ~rst_n )
			frame_cnt <= 'd0;
		else if( vs_start ) 
			frame_cnt <= 'd0;
		else if( de_r1 )
			frame_cnt <= frame_cnt + 1'b1;
  					
  end

  always @( posedge clk or negedge rst_n )
  begin
  		if( ~rst_n )
			frame_cnt_o <= 'd0;
		else if( vs_end ) 
			frame_cnt_o <= frame_cnt;
  end
reg frame_end_r0 = 'd0;
reg frame_end_r1 = 'd0;
  always @( posedge clk or negedge rst_n )
  begin
		if( !rst_n ) begin
			frame_end_r0 <= 'd0;
			frame_end_r1 <= 'd0;
		end else begin
			frame_end_r0 <= vs_end ;
			frame_end_r1 <= frame_end_r0;
		end
  end

  always @( posedge clk or negedge rst_n )
  begin
  		if( !rst_n ) begin
			frame_len_d0 <= 'd0; 
			frame_len_d1 <= 'd0; 
			frame_len_d2 <= 'd0; 
  		end else if( frame_end_r0 ) begin
			frame_len_d0 <= frame_cnt_o;
			frame_len_d1 <= frame_len_d0;
			frame_len_d2 <= frame_len_d1;
  		end
  end
// frame_len_d1 = d2 = d3
// frame_len > 64*64 
  always @( posedge clk or negedge rst_n )
  begin
  		if( !rst_n ) begin
			frame_stable <= 1'b0;
		end else if( timeout ) begin 
			frame_stable <= 1'b0;
		end else if( frame_end_r1 ) begin
			if( frame_len_d0 == frame_len_d1 && frame_len_d0 == frame_len_d2 &&  |frame_len_d0[23:12])
					frame_stable <= 1'b1;
			else
					frame_stable <= 1'b0;
		end
  end
  
  always @( posedge clk or negedge rst_n )
  begin
	if( !rst_n )
		timeout_cnt  <= 'd0;
	else if( pos_vs )
		timeout_cnt <= 'd0;
	else if( timeout_cnt == CLK_FREQ-1 )
		timeout_cnt <= 'd0;
	else 
		timeout_cnt <= timeout_cnt + 1'b1;
  end
  assign timeout = timeout_cnt == CLK_FREQ-1;
//============================================================================================== 
// line pixcel number count
//==============================================================================================
  always @( posedge clk or negedge rst_n )
  begin
		if( !rst_n )
			h_cnt <= 'd0;
		else if( hs_start )
			h_cnt <= 'd0;
		else if( de_r0 )
			h_cnt <= h_cnt + 1'b1;

  end

  always @( posedge clk or negedge rst_n )
  begin
		if( !rst_n )
			o_h_act <= 'd0;
		else if( hs_end )
			o_h_act <= h_cnt ;
  end 

  always @( posedge clk or negedge rst_n )
  begin
	 if( ! rst_n )
	 	h_active_error <= 1'b0;
	 else if( hs_end && o_h_act != h_cnt )
		h_active_error <= 1'b1; 
	else 
		h_active_error <= 1'b0;
  end
//============================================================================================== 
//!number of lines caculate
//==============================================================================================
localparam V_IDLE = 2'd0;
localparam V_VALID_DTEC = 2'd1;
localparam V_CNT_ADD = 2'd2;
reg [1:0] state = 'd0;
always @( posedge clk or negedge rst_n )
begin
	if( !rst_n ) begin 
		state <= V_IDLE;
		v_cnt <= 'd0;
	end else if( vs_start ) begin 
		state <= V_IDLE;
		v_cnt <= 'd0;
	end else begin
		case( state )
		V_IDLE : begin
			state <= hs_start ? V_VALID_DTEC : V_IDLE;
		end
		V_VALID_DTEC: begin
			if(hs_end  )
				state <= V_IDLE ;
			else 
				state <= de_r0 ? V_CNT_ADD : V_VALID_DTEC;
		end
		V_CNT_ADD : begin
			v_cnt <= v_cnt + 1'b1;
			state <= V_IDLE;
		end
		default :;
		endcase
			
	end
end


  always @( posedge clk or negedge rst_n )
  begin
		if( !rst_n )
			o_v_act <= 'd0;
		else if( vs_end )
			o_v_act <= v_cnt;
  end
  always @( posedge clk or negedge rst_n )
  begin
	 if( ! rst_n )
	 	v_active_error <= 1'b0;
	 else if( vs_end && o_v_act != v_cnt )
		v_active_error <= 1'b1; 
	else 
		v_active_error <= 1'b0;
  end


  always @( posedge clk or negedge rst_n )
  begin
		if( !rst_n )
			v_total_cnt <= 'd0;
		else if( vs_start )
			v_total_cnt <= 'd0;
		else if( hs_start )
			v_total_cnt <= v_total_cnt + 1'b1;
  end

  always @( posedge clk or negedge rst_n )
  begin
		if( !rst_n )
			o_v_total <= 'd0;
		else if( vs_start )
			o_v_total <= v_total_cnt;
  end 

  always @( posedge clk )
  begin
	if( vs_start && v_total_cnt != o_v_total )
			v_total_error <= 1'b1;
	else 
			v_total_error <= 1'b0;
  end
//============================================================================================== 
//
//==============================================================================================
  always @( posedge clk or negedge rst_n )
  begin
		if( !rst_n )
			h_total_cnt <= 'd0;
		else if( pos_hs )
			h_total_cnt <= 'd0;
		else  
			h_total_cnt <= h_total_cnt + 1'b1;
  end

  always @( posedge clk or negedge rst_n )
  begin
	  	if( !rst_n )
			o_h_total <= 'd0;
		else if( pos_hs )
			o_h_total <= h_total_cnt ;
  end

  always @( posedge clk )
  begin
	 if( neg_hs )
	 		h_sync_len <= h_total_cnt ;
  end
  always @( posedge clk )
  begin
	if( neg_hs && h_total_cnt != h_sync_len )
		h_sync_error <= 1'b1;
	else 
		h_sync_error <= 1'b0;
  end


  always @( posedge clk )
  begin
	if( pos_hs && h_total_cnt != o_h_total )
		h_total_error <= 1'b1;
	else 
		h_total_error <= 1'b0;
  end
//====================================================================================================== 
  
  //function entity
  function [5:0]     MSB_check ;
  input     [31:0] data_in ;
  parameter         MASK = 32'h3 ;
  integer           k ;
  begin
	  for(k=0; k<32; k=k+1) begin
		 
		  MSB_check  = data_in[k] ? k : MSB_check;  
	  end
  end
endfunction

endmodule