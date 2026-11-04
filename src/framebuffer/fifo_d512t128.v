
module fifo_d512t128 #(
    parameter AXI_DATA_WIDTH = 512,
    parameter RD_FIFO_DEPTH = 512
)(
    input axi_clk,
    input o_clk,
    input rst_n,
    input fifo_rd_period,
    input ddr_rd_valid,
    output reg rd_fifo_wr_full = 'd0,
    input [AXI_DATA_WIDTH-1:0] ddr_rd_data,

    input                  rd_fifo_rden1,
    output                 rd_fifo_rdempty1,
    output [127:0]         rd_fifo_rddata1
);


 
localparam FIFO_CNT_WIDTH = $clog2(RD_FIFO_DEPTH);

wire [FIFO_CNT_WIDTH-1:0] ddr_wrdnum;
wire [FIFO_CNT_WIDTH-1:0] wrfifo_wrdnum;
wire [512-1:0] 	                                    rd_fifo_rddata	;
wire 												rd_fifo_rdempty	;
wire 												rd_fifo_rden    ; 
reg												    rd_fifo_rdvalid ;
wire                                                wrfifo_wr_en;
reg                                                wrfifo_wr_full = 'd0;
wire [127:0]                                        wrfifo_wr_data ;


DC_FIFO
# (
  	.FIFO_MODE  ( "Normal"    	    ), //"Normal"; //"ShowAhead"
    .DATA_WIDTH ( AXI_DATA_WIDTH    ),
    .FIFO_DEPTH ( RD_FIFO_DEPTH     )
  ) u_rd_fifo(   
  //System Signal
  /*i*/.Reset   (	~rst_n			    ), 
  /*i*/.WrClk   (axi_clk			    ), 
  /*i*/.WrEn    (ddr_rd_valid		  ), 
  /*o*/.WrDNum  (ddr_wrdnum       ), 
  /*o*/.WrFull  ( 	), 
  /*i*/.WrData  (ddr_rd_data 		  ), 
  /*i*/.RdClk   (o_clk      		  ), 
  /*o*/.RdDNum  (	                ), 
  /*i*/.RdEn    (rd_fifo_rden		  ),
  /*o*/.RdEmpty (rd_fifo_rdempty	), 
  /*o*/.RdData  (rd_fifo_rddata		)  
);

always @( posedge axi_clk )
begin
  if( RD_FIFO_DEPTH-128 < ddr_wrdnum)
  rd_fifo_wr_full <= 1'b1;
  else if( ddr_wrdnum <= 2)
    rd_fifo_wr_full <= 1'b0;

end

always @( posedge o_clk )
begin
    rd_fifo_rdvalid <=   rd_fifo_rden;
end


par2ser_512t128 # (
    .I_VID_WIDTH(AXI_DATA_WIDTH),
    .O_VID_WIDTH(128)
  )
  par2ser_512t128_inst (
    .clk(o_clk),
    .rst_n(rst_n),
    .rdfifo_rd_en   (rd_fifo_rden   ),
    .rdfifo_rd_empty(rd_fifo_rdempty),
    .rdfifo_rd_valid(rd_fifo_rdvalid),
    .rdfifo_rd_data (rd_fifo_rddata),
    .ena            (fifo_rd_period),
    .wrfifo_wr_en   (wrfifo_wr_en),
    .wrfifo_wr_data (wrfifo_wr_data),
    .wrfifo_wr_full (wrfifo_wr_full)
  );
  DC_FIFO
  # (
        .FIFO_MODE  ( "Normal"    	    ), //"Normal"; //"ShowAhead"
      .DATA_WIDTH ( 128    ),
      .FIFO_DEPTH ( RD_FIFO_DEPTH     )
    ) u_rd_fifo1(   
    //System Signal
    /*i*/.Reset   (	~rst_n			), 
    /*i*/.WrClk   (o_clk			), 
    /*i*/.WrEn    (wrfifo_wr_en		), 
    /*o*/.WrDNum  (wrfifo_wrdnum	    ), 
    /*o*/.WrFull  ( 	), 
    /*i*/.WrData  (wrfifo_wr_data 	), 
    /*i*/.RdClk   (o_clk      		), 
    /*i*/.RdEn    (rd_fifo_rden1	), 
    /*o*/.RdDNum  (	), 
    /*o*/.RdEmpty (rd_fifo_rdempty1	), 
    /*o*/.RdData  (rd_fifo_rddata1	)  
  );

  always @( posedge o_clk )
begin
  if( RD_FIFO_DEPTH-16 < wrfifo_wrdnum)
  wrfifo_wr_full <= 1'b1;
  else 
    wrfifo_wr_full <= 1'b0;
end



endmodule
