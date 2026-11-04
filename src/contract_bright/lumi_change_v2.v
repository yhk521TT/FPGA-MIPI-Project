
module lumi_change_v2();
		#(
				parameter DATA_WIDTH = 8
		)(
		input	wire					clk,
		input	wire					rst_n,	
		input	wire	[95:0]	i_vid_data,	
    input	wire	[ 1:0]	i_vid_de,	
    input	wire	[ 1:0]	i_vid_hsync, 
    input	wire	[ 1:0]	i_vid_vsync, 
    input	wire	[DATA_WIDTH-1:0]	contrast,
    input	wire	[DATA_WIDTH-1:0] 	lumi_r,
    input	wire	[DATA_WIDTH-1:0]	lumi_g,
    input	wire	[DATA_WIDTH-1:0]	lumi_b,
    
    output wire	[95:0]	o_vid_data,
    output wire	[ 1:0] 	o_vid_hsync,
    output wire	[ 1:0]	o_vid_vsync,
    output wire	[ 1:0]	o_vid_de
);

  localparam MAX_DATA = 2**DATA_WIDTH-1; 
  localparam DEFAULT_VALUE = 2**(DATA_WIDTH-1);
  parameter MID_DATA = 8'd127;

		reg [DATA_WIDTH-1:0] contr_r = DEFAULT_VALUE;		
	
		
		always @( posedge clk )
		begin

				contr_r <= contrast;
		end
		reg[6*DATA_WIDTH-1:0] sub_mid_data = {6*DATA_WIDTH{1'b0}};
		//=================================================================================
		//
		//=================================================================================
		reg [1:0] de_d1		 = 2'b00;
		reg [1:0] hsync_d1 = 2'b00;
		reg [1:0] vsync_d1 = 2'b00;
		always @( posedge clk ) 
		begin 
				if(i_vid_de[0]) begin
						if( i_vid_data[15-:DATA_WIDTH] > 127 ) begin	
								sub_mid_data[DATA_WIDTH-1:0] <= i_vid_data[15-:DATA_WIDTH]- 127;
								sign_b_l <= 1'b1;
						end else begin
								sub_mid_data[DATA_WIDTH-1:0] <= 127 - i_vid_data[15-:DATA_WIDTH];
								sign_b_l <= 1'b0;
						end
						
						if( i_vid_data[31-:DATA_WIDTH] > 127 ) begin	
								sub_mid_data[2*DATA_WIDTH-1:1*DATA_WIDTH] <= i_vid_data[31-:DATA_WIDTH]- 127;
								sign_g_l <= 1'b1;
						end else begin
								sub_mid_data[2*DATA_WIDTH-1:1*DATA_WIDTH] <= 127 - i_vid_data[31-:DATA_WIDTH];
								sign_g_l <= 1'b0;
						end
						
						if( i_vid_data[47-:DATA_WIDTH] > 127 ) begin	
								sub_mid_data[3*DATA_WIDTH-1:2*DATA_WIDTH] <= i_vid_data[47-:DATA_WIDTH]- 127;
								sign_r_l <= 1'b1;
						end else begin
								sub_mid_data[3*DATA_WIDTH-1:2*DATA_WIDTH] <= 127 - i_vid_data[47-:DATA_WIDTH];
								sign_r_l <= 1'b0;
						end	
				end				
				
		end
		always @( posedge clk ) 
		begin 
				if(i_vid_de[1]) begin
						if( i_vid_data[63-:DATA_WIDTH] > 127 ) begin	
								sub_mid_data[4*DATA_WIDTH-1:3*DATA_WIDTH] <= i_vid_data[63-:DATA_WIDTH]- 127;
								sign_b_h <= 1'b1;
						end else begin
								sub_mid_data[4*DATA_WIDTH-1:3*DATA_WIDTH] <= 127 - i_vid_data[63-:DATA_WIDTH];
								sign_b_h <= 1'b0;
						end
						
						if( i_vid_data[79-:DATA_WIDTH] > 127 ) begin	
								sub_mid_data[5*DATA_WIDTH-1:4*DATA_WIDTH] <= i_vid_data[79-:DATA_WIDTH]- 127;
								sign_g_h <= 1'b1;
						end else begin
								sub_mid_data[5*DATA_WIDTH-1:4*DATA_WIDTH] <= 127 - i_vid_data[79-:DATA_WIDTH];
								sign_g_h <= 1'b0;
						end
						
						if( i_vid_data[95-:DATA_WIDTH] > 127 ) begin	
								sub_mid_data[6*DATA_WIDTH-1:5*DATA_WIDTH] <= i_vid_data[95-:DATA_WIDTH]- 127;
								sign_r_h <= 1'b1;
						end else begin
								sub_mid_data[6*DATA_WIDTH-1:5*DATA_WIDTH] <= 127 - i_vid_data[95-:DATA_WIDTH];
								sign_r_h <= 1'b0;
						end
				end
				
		end
		always @( posedge clk )
		begin
				de_d1		<= i_vid_de		   ;	    
				hsync_d1	<= i_vid_hsync   ;  
				vsync_d1	<= i_vid_vsync   ;  
				  
		end
		//=================================================================================
		//
		//=================================================================================
		reg	sign_r_h_d1 = 1'b0;
		reg	sign_g_h_d1 = 1'b0;
		reg	sign_b_h_d1 = 1'b0;
		reg	sign_r_l_d1 = 1'b0;
		reg	sign_g_l_d1 = 1'b0;
		reg	sign_b_l_d1 = 1'b0;		
		reg [2*DATA_WIDTH-1:0] r1_d;
		reg [2*DATA_WIDTH-1:0] g1_d;
		reg [2*DATA_WIDTH-1:0] b1_d; 
		reg [2*DATA_WIDTH-1:0] r0_d;
		reg [2*DATA_WIDTH-1:0] g0_d;
		reg [2*DATA_WIDTH-1:0] b0_d;  
		wire [DATA_WIDTH:0] r1_d_w;
		wire [DATA_WIDTH:0] g1_d_w;
		wire [DATA_WIDTH:0] b1_d_w;
		wire [DATA_WIDTH:0] r0_d_w;
		wire [DATA_WIDTH:0] g0_d_w;
		wire [DATA_WIDTH:0] b0_d_w;
		reg [1:0] de_d2		 = 2'b00; 
		reg [1:0] hsync_d2 = 2'b00; 
		reg [1:0] vsync_d2 = 2'b00; 
		
		always @( posedge clk )
		begin
				de_d2			<= de_d1		   ;	    
				hsync_d2	<= hsync_d1    ;  
				vsync_d2	<= vsync_d1    ;  
				  
		end
		
		always @( posedge clk ) 
		begin
				sign_r_l_d1 <= sign_r_l;
				sign_g_l_d1 <= sign_g_l;
				sign_b_l_d1 <= sign_b_l;
				
				sign_r_h_d1 <= sign_r_h;
				sign_g_h_d1 <= sign_g_h;
				sign_b_h_d1 <= sign_b_h;
		
		    r1_d <=	contr_r* sub_mid_data[6*DATA_WIDTH-1:5*DATA_WIDTH];
		    g1_d <= contr_r* sub_mid_data[5*DATA_WIDTH-1:4*DATA_WIDTH]; 
		    b1_d <= contr_r* sub_mid_data[4*DATA_WIDTH-1:3*DATA_WIDTH]; 
		                                                               
		    r0_d <= contr_r* sub_mid_data[3*DATA_WIDTH-1:2*DATA_WIDTH]; 
		    g0_d <= contr_r* sub_mid_data[2*DATA_WIDTH-1:1*DATA_WIDTH]; 
		    b0_d <= contr_r* sub_mid_data[1*DATA_WIDTH-1:0*DATA_WIDTH]; 
			
		end
		assign r1_d_w = r1_d[2*DATA_WIDTH-1:DATA_WIDTH-1] + r1_d[DATA_WIDTH-2];
		assign g1_d_w = g1_d[2*DATA_WIDTH-1:DATA_WIDTH-1] + g1_d[DATA_WIDTH-2];
		assign b1_d_w = b1_d[2*DATA_WIDTH-1:DATA_WIDTH-1] + b1_d[DATA_WIDTH-2];
		assign r0_d_w = r0_d[2*DATA_WIDTH-1:DATA_WIDTH-1] + r0_d[DATA_WIDTH-2];
		assign g0_d_w = g0_d[2*DATA_WIDTH-1:DATA_WIDTH-1] + g0_d[DATA_WIDTH-2];
		assign b0_d_w = b0_d[2*DATA_WIDTH-1:DATA_WIDTH-1] + b0_d[DATA_WIDTH-2];
		//=================================================================================
		//
		//=================================================================================
		
	reg sign_r_l_d2 = 1'b0; 
	reg sign_g_l_d2 = 1'b0; 
	reg sign_b_l_d2 = 1'b0; 
	reg sign_r_h_d2 = 1'b0; 
	reg sign_g_h_d2 = 1'b0; 
	reg sign_b_h_d2 = 1'b0;  
	reg [DATA_WIDTH+1:0] add_r1;
	reg [DATA_WIDTH+1:0] add_g1;
	reg [DATA_WIDTH+1:0] add_b1;
	reg [DATA_WIDTH+1:0] add_r0;
	reg [DATA_WIDTH+1:0] add_g0;
	reg [DATA_WIDTH+1:0] add_b0;
	  
	reg [DATA_WIDTH+1:0] sub_r1;
	reg [DATA_WIDTH+1:0] sub_g1;
	reg [DATA_WIDTH+1:0] sub_b1;
	reg [DATA_WIDTH+1:0] sub_r0;
	reg [DATA_WIDTH+1:0] sub_g0;
	reg [DATA_WIDTH+1:0] sub_b0;
	reg [1:0] de_d3		 = 2'b00; 
	reg [1:0] hsync_d3 = 2'b00; 
	reg [1:0] vsync_d3 = 2'b00; 
		
		always @( posedge clk )
		begin
				de_d3			<= de_d2		   ;	    
				hsync_d3	<= hsync_d2    ;  
				vsync_d3	<= vsync_d2    ;  
				  
		end

		always @( posedge clk )
		begin 
				sign_r_l_d2 <= sign_r_l_d1;
				sign_g_l_d2 <= sign_g_l_d1;
				sign_b_l_d2 <= sign_b_l_d1;
				                           
				sign_r_h_d2 <= sign_r_h_d1;
				sign_g_h_d2 <= sign_g_h_d1;
				sign_b_h_d2 <= sign_b_h_d1;
				
				add_r1 <= 	r1_d_w[DATA_WIDTH:0] + 127 ;
				sub_r1 <=		127- r1_d_w[DATA_WIDTH:0] ;
				add_g1 <= 	g1_d_w[DATA_WIDTH:0] + 127 ;
				sub_g1 <=		127- r1_d_w[DATA_WIDTH:0] ;
				add_b1 <= 	b1_d_w[DATA_WIDTH:0] + 127 ;
				sub_b1 <=		127- r1_d_w[DATA_WIDTH:0] ; 
				
				add_r0 <= 	r0_d_w[DATA_WIDTH:0] + 127 ;
				sub_r0 <=		127- r0_d_w[DATA_WIDTH:0] ;
				add_g0 <= 	g0_d_w[DATA_WIDTH:0] + 127 ;
				sub_g0 <=		127- g0_d_w[DATA_WIDTH:0] ;
				add_b0 <= 	b0_d_w[DATA_WIDTH:0] + 127 ;
				sub_b0 <=		127- b0_d_w[DATA_WIDTH:0] ;
		end  
		//=================================================================================		
		//                                                                                 		
		//=================================================================================		
		reg [1:0] de_d4		 = 2'b00; 
	reg [1:0] hsync_d4 = 2'b00; 
	reg [1:0] vsync_d4 = 2'b00; 
	reg	[7:0] r1_d1 = 8'd0;
	reg	[7:0] g1_d1 = 0;
	reg	[7:0] b1_d1 = 0;
	reg	[7:0] r0_d1 = 8'd0;
	reg	[7:0] g0_d1 = 0;
	reg	[7:0] b0_d1 = 0;
		
		always @( posedge clk )
		begin
				de_d4			<= de_d3		   ;	    
				hsync_d4	<= hsync_d3    ;  
				vsync_d4	<= vsync_d3    ;  
				  
		end
		
		always @( posedge clk )
		begin
				if( de_d3[1] ) begin
						if( sign_r_h_d2 ) begin
						    if(|add_r1[DATA_WIDTH+1:DATA_WIDTH]) begin
						    		r1_d1 <= 8'hff;
						    end else begin
						    		r1_d1 <= add_r1[7:0];
						    end
						end else begin
								if(|r1_d_w[DATA_WIDTH+1:DATA_WIDTH]) begin
						    		r1_d1 <= 8'h00;
						    end else begin
						    		r1_d1 <= sub_r1[7:0];
						    end
						end 
						if( sign_g_h_d2 ) begin
						    if(|add_g1[DATA_WIDTH+1:DATA_WIDTH]) begin
						    		g1_d1 <= 8'hff;
						    end else begin
						    		g1_d1 <= add_g1[7:0];
						    end
						end else begin
								if(|r1_d_w[DATA_WIDTH+1:DATA_WIDTH]) begin
						    		g1_d1 <= 8'h00;
						    end else begin
						    		g1_d1 <= sub_g1[7:0];
						    end
						end 
						if( sign_b_h_d2 ) begin
						    if(|add_b1[DATA_WIDTH+1:DATA_WIDTH]) begin
						    		b1_d1 <= 8'hff;
						    end else begin
						    		b1_d1 <= add_b1[7:0];
						    end
						end else begin
								if(|b1_d_w[DATA_WIDTH+1:DATA_WIDTH]) begin
						    		b1_d1 <= 8'h00;
						    end else begin
						    		b1_d1 <= sub_b1[7:0];
						    end
						end 
				end
				
		end

		always @( posedge clk )
		begin
				if( de_d3[0] ) begin   
						if( sign_r_l_d2 ) begin  
						    if(|add_r0[DATA_WIDTH+1:DATA_WIDTH]) begin
						    		r0_d1 <= 8'hff;
						    end else begin
						    		r0_d1 <= add_r0[7:0];
						    end
						end else begin
								if(|r0_d_w[DATA_WIDTH+1:DATA_WIDTH]) begin
						    		r0_d1 <= 8'h00;
						    end else begin
						    		r0_d1 <= sub_r0[7:0];
						    end
						end 
						if( sign_g_l_d2 ) begin
						    if(|add_g0[DATA_WIDTH+1:DATA_WIDTH]) begin
						    		g0_d1 <= 8'hff;
						    end else begin
						    		g0_d1 <= add_g0[7:0];
						    end
						end else begin
								if(|g0_d_w[DATA_WIDTH+1:DATA_WIDTH]) begin
						    		g0_d1 <= 8'h00;
						    end else begin
						    		g0_d1 <= sub_g0[7:0];
						    end
						end 
						if( sign_b_l_d2 ) begin
						    if(|add_b0[DATA_WIDTH+1:DATA_WIDTH]) begin
						    		b0_d1 <= 8'hff;
						    end else begin
						    		b0_d1 <= add_b0[7:0];
						    end
						end else begin
								if(|b0_d_w[DATA_WIDTH+1:DATA_WIDTH]) begin
						    		b0_d1 <= 8'h00;
						    end else begin
						    		b0_d1 <= sub_b0[7:0];
						    end
						end 
				end
				
		end

		output 	o_vid_data	= {r1_d1,8'h00,g1_d1,8'h00,b1_d1,8'h00,r0_d1,8'h00,g0_d1,8'h00,b0_d1,8'h00};
    output  o_vid_hsync	=	hsync_d4;
    output 	o_vid_vsync	= vsync_d4;
    output 	o_vid_de		=	de_d4;


		
endmodule

