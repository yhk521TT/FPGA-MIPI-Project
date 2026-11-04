`timescale 1ns/100ps

module DC_FIFO
# (
  	parameter     FIFO_MODE     = "Normal"            , //"Normal"; //"ShowAhead"
    parameter     DATA_WIDTH    = 128                 ,
    parameter     FIFO_DEPTH    = 128                 ,

    parameter     AW_C          = $clog2(FIFO_DEPTH)  ,   
    parameter     DW_C          = DATA_WIDTH          ,
    parameter     DD_C          = 2**AW_C         
  )
(   
  //System Signal
  input                 Reset   , //System Reset
  //Write Signal                             
  input                 WrClk   , //(I)Wirte Clock
  input                 WrEn    , //(I)Write Enable
  output  [AW_C  :0]    WrDNum  , //(O)Write Data Number In Fifo
  output                WrFull  , //(O)Write Full 
  input   [DW_C -1:0]   WrData  , //(I)Write Data
  //Read Signal                            
  input                 RdClk   , //(I)Read Clock
  input                 RdEn    , //(I)Read Enable
  output  [AW_C  :0]    RdDNum  , //(O)Radd Data Number In Fifo
  output                RdEmpty , //(O)Read FifoEmpty
  output                DataVal , //(O)Data Valid 
  output  [DW_C-1 :0]   RdData    //(O)Read Data
);

assign RdDNum[AW_C] = 1'b0;
assign WrDNum[AW_C] = 1'b0;

elt_dcfifo
#(
.NUM_WORDS          (FIFO_DEPTH     ),     
.WIDTH              (DATA_WIDTH     ),
.ALMOST_FULL_VALUE  (FIFO_DEPTH-1   ),
.ALMOST_EMPTY_VALUE (1              ),
.OVERFLOW_CHECKING  (1              ),
.UNDERFLOW_CHECKING (1              )            
)
DC_FIFO_inst
(
.aclr           (Reset              ),
.wrclk          (WrClk              ),
.wrreq          (WrEn               ),
.data           (WrData             ),
.wrempty        (                   ),
.wrfull         (WrFull             ),
.wr_almost_empty(                   ),
.wr_almost_full (                   ),
.wrusedw        (WrDNum[AW_C-1:0]   ),
.rdclk          (RdClk              ),
.rdreq          (RdEn               ),
.q              (RdData             ),
.rdempty        (RdEmpty            ),
.rdfull         (                   ),
.rd_almost_empty(                   ),    
.rd_almost_full (                   ),    
.rdusedw        (RdDNum[AW_C-1:0]   )
);
endmodule

module elt_dcfifo
#(
    parameter NUM_WORDS            = 128              ,     
    parameter WIDTH                = 128              ,
    
    parameter ALMOST_FULL_VALUE    = 120              ,
    parameter ALMOST_EMPTY_VALUE   = 8                ,    
    parameter OVERFLOW_CHECKING    = 1                , 
    parameter UNDERFLOW_CHECKING   = 1                ,
    
    parameter LOG_DEPTH            = $clog2(NUM_WORDS)    

)
(
    input                          aclr               ,
    
    input                          wrclk              ,
    input                          wrreq              ,
    input      [WIDTH-1:0]         data               ,
    output reg                     wrempty            ,
    output reg                     wrfull             ,
    output reg                     wr_almost_empty    ,
    output reg                     wr_almost_full     ,
    output     [LOG_DEPTH-1:0]     wrusedw            ,
    
    input                          rdclk              ,
    input                          rdreq              ,
    output     [WIDTH-1:0]         q                  ,
    output reg                     rdempty            ,
    output reg                     rdfull             ,
    output reg                     rd_almost_empty    ,    
    output reg                     rd_almost_full     ,    
    output     [LOG_DEPTH-1:0]     rdusedw
);
       
/* initial begin        
    if ((ALMOST_FULL_VALUE > 2 ** LOG_DEPTH - 1) || (ALMOST_FULL_VALUE < 1))
        $error("Incorrect parameter value: ALMOST_FULL_VALUE = %0d; valid range is 0 < ALMOST_FULL_VALUE < %0d", 
            ALMOST_FULL_VALUE, 2 ** LOG_DEPTH);     

    if ((ALMOST_EMPTY_VALUE > 2 ** LOG_DEPTH - 1) || (ALMOST_EMPTY_VALUE < 1))
        $error("Incorrect parameter value: ALMOST_EMPTY_VALUE = %0d; valid range is 0 < ALMOST_EMPTY_VALUE < %0d", 
            ALMOST_EMPTY_VALUE, 2 ** LOG_DEPTH);  

    if ((NUM_WORDS > 2 ** LOG_DEPTH - 1) || (NUM_WORDS < 1))
        $error("Incorrect parameter value: NUM_WORDS = %0d; valid range is 0 < NUM_WORDS < %0d", 
            NUM_WORDS, 2 ** LOG_DEPTH);  
end
 */
 
(* syn_extract_enable="false" *) reg [LOG_DEPTH-1:0] write_addr = 0;
(* syn_extract_enable="false" *) reg [LOG_DEPTH-1:0] read_addr = 0;
reg [LOG_DEPTH-1:0] wrcapacity = 0;
reg [LOG_DEPTH-1:0] rdcapacity = 0;

wire [LOG_DEPTH-1:0] wrcapacity_w;
wire [LOG_DEPTH-1:0] rdcapacity_w;

wire [LOG_DEPTH-1:0] rd_write_addr;
wire [LOG_DEPTH-1:0] wr_read_addr;

wire wrreq_safe;
wire rdreq_safe;
assign wrreq_safe = OVERFLOW_CHECKING ? wrreq & ~wrfull : wrreq;
assign rdreq_safe = UNDERFLOW_CHECKING ? rdreq & ~rdempty : rdreq;

initial begin 
    write_addr = 0;
    read_addr = 0;
    wrempty = 1;
    wrfull = 0;
    rdempty = 1;
    rdfull = 0;
    wrcapacity = 0;
    rdcapacity = 0;    
    rd_almost_empty = 1;
    rd_almost_full = 0;
    wr_almost_empty = 1;
    wr_almost_full = 0;
end


// ------------------ Write -------------------------

add_a_b_s0_s1 #(LOG_DEPTH) wr_adder(
    .a(write_addr),
    .b(~wr_read_addr),
    .s0(wrreq_safe),
    .s1(1'b1),
    .out(wrcapacity_w)
);

always @(posedge wrclk or posedge aclr) begin

    if (aclr) begin
        write_addr <= 0;
        wrcapacity <= 0;
        wrempty <= 1;
        wrfull <= 0;
        wr_almost_full <= 0;
        wr_almost_empty <= 1;
    end else begin
        write_addr <= write_addr + wrreq_safe;
        wrcapacity <= wrcapacity_w;
        wrempty <= (wrcapacity == 0) && (wrreq == 0);
//        wrfull <= (wrcapacity == NUM_WORDS) || (wrcapacity == NUM_WORDS - 1) && (wrreq == 1);
        wrfull <= (wrcapacity == NUM_WORDS -1 ) || (wrcapacity == NUM_WORDS - 2) && (wrreq == 1);        
        wr_almost_empty <=
            (wrcapacity < (ALMOST_EMPTY_VALUE-1)) || 
            (wrcapacity == (ALMOST_EMPTY_VALUE-1)) && (wrreq == 0);
        
        wr_almost_full <= 
            (wrcapacity >= ALMOST_FULL_VALUE) ||
            (wrcapacity == ALMOST_FULL_VALUE - 1) && (wrreq == 1);    
    end
end

assign wrusedw = wrcapacity;

// ------------------ Read -------------------------

add_a_b_s0_s1 #(LOG_DEPTH) rd_adder(
    .a(rd_write_addr),
    .b(~read_addr),
    .s0(1'b0),
    .s1(~rdreq_safe),
    .out(rdcapacity_w)
);

always @(posedge rdclk or posedge aclr) begin
    if (aclr) begin
        read_addr <= 0;
        rdcapacity <= 0;
        rdempty <= 1;
        rdfull <= 0;    
        rd_almost_empty <= 1;
        rd_almost_full <= 0;
    end else begin
        read_addr <= read_addr + rdreq_safe;
        rdcapacity <= rdcapacity_w;
        rdempty <= (rdcapacity == 0) || (rdcapacity == 1) && (rdreq == 1);
        
//        rdfull <= (rdcapacity == NUM_WORDS) && (rdreq == 0);  
        rdfull <= (rdcapacity == NUM_WORDS -1 ) && (rdreq == 0);   
        
        rd_almost_empty <= 
            (rdcapacity < ALMOST_EMPTY_VALUE) || 
            (rdcapacity == ALMOST_EMPTY_VALUE) && (rdreq == 1);
            
        rd_almost_full <= 
            (rdcapacity > ALMOST_FULL_VALUE) ||
            (rdcapacity == ALMOST_FULL_VALUE) && (rdreq == 0);                
    end
end

assign rdusedw = rdcapacity;

// ---------------- Synchronizers --------------------

wire [LOG_DEPTH-1:0] gray_read_addr;
wire [LOG_DEPTH-1:0] wr_gray_read_addr;
wire [LOG_DEPTH-1:0] gray_write_addr;
wire [LOG_DEPTH-1:0] rd_gray_write_addr;

binary_to_gray #(.WIDTH(LOG_DEPTH)) rd_b2g (.clock(rdclk), .aclr(aclr), .din(read_addr), .dout(gray_read_addr));
synchronizer_ff_r2 #(.WIDTH(LOG_DEPTH)) rd2wr (.din_clk(rdclk), .rst_p(aclr), .din(gray_read_addr), .dout_clk(wrclk), .dout(wr_gray_read_addr));
gray_to_binary #(.WIDTH(LOG_DEPTH)) rd_g2b (.clock(wrclk), .aclr(aclr), .din(wr_gray_read_addr), .dout(wr_read_addr));


binary_to_gray #(.WIDTH(LOG_DEPTH)) wr_b2g (.clock(wrclk), .aclr(aclr), .din(write_addr), .dout(gray_write_addr));
synchronizer_ff_r2 #(.WIDTH(LOG_DEPTH)) wr2rd (.din_clk(wrclk), .rst_p(aclr), .din(gray_write_addr), .dout_clk(rdclk), .dout(rd_gray_write_addr));
gray_to_binary #(.WIDTH(LOG_DEPTH)) wr_g2b (.clock(rdclk), .aclr(aclr), .din(rd_gray_write_addr), .dout(rd_write_addr));

// ------------------ MEM ---------------------------

generic_mem_dc #(.WIDTH(WIDTH), .ADDR_WIDTH(LOG_DEPTH)) mlab_inst (
    .rclk(rdclk),
    .wclk(wrclk),
    .rst_p(aclr),
    .din(data),
    .waddr(write_addr),
    .we(wrreq_safe),//1'b1),
    .re(rdreq_safe),//1'b1),
    .raddr(read_addr),
    .dout(q)
);

endmodule

module add_a_b_s0_s1 #(
    parameter SIZE = 5
)(
    input [SIZE-1:0] a,
    input [SIZE-1:0] b,
    input s0,
    input s1,
    output [SIZE-1:0] out
);
    wire [SIZE:0] left;
    wire [SIZE:0] right;
    wire temp;
    
    assign left = {a ^ b, s0};
    assign right = {a[SIZE-2:0] & b[SIZE-2:0], s1, s0};
    assign {out, temp} = left + right;
    
endmodule

module binary_to_gray #(
    parameter WIDTH = 5
) (
    input clock,
    input aclr,
    input [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout
);

    always @(posedge clock or posedge aclr) begin
         if (aclr)
              dout <= 0;
         else
              dout <= din ^ (din >> 1);
    end

endmodule

module gray_to_binary #(
    parameter WIDTH = 5
) (
    input clock,
    input aclr,
    input [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout
);

    wire [WIDTH-1:0] dout_w;

    genvar i;
    generate
         for (i = 0; i < WIDTH; i=i+1) begin : loop
              assign dout_w[i] = ^(din[WIDTH-1:i]);
         end
    endgenerate

    always @(posedge clock or posedge aclr) begin
         if (aclr)
              dout <= 0;
         else
              dout <= dout_w;
    end

endmodule

module generic_mem_dc #(
    parameter WIDTH = 8,
    parameter ADDR_WIDTH = 5
)(
    input rclk,
    input wclk,
    input rst_p,
    input [WIDTH-1:0] din,
    input [ADDR_WIDTH-1:0] waddr,
    input we,
    input re,
    input [ADDR_WIDTH-1:0] raddr,
    output [WIDTH-1:0] dout
);

    localparam DEPTH = 1 << ADDR_WIDTH;
    reg [WIDTH-1:0] mem[0:DEPTH-1];

    reg [WIDTH-1:0] dout_r;
    always @(posedge wclk ) begin
        if (we)
            mem[waddr] <= din;
    end
    always @(posedge rclk  ) begin
        if (re)
            dout_r <= mem[raddr];
    end
    assign dout = dout_r;

endmodule


module synchronizer_ff_r2 #(
    parameter WIDTH = 8
)(
    input din_clk,
    input rst_p,
    input [WIDTH-1:0] din,
    input dout_clk,
    output [WIDTH-1:0] dout
);

    (* async_reg = "true" *) reg [WIDTH-1:0] ff_launch = {WIDTH {1'b0}} ;
    always @(posedge din_clk or posedge rst_p ) begin
        if( rst_p )
            ff_launch <= 'd0;
        else 
            ff_launch <= din;
    end

    (* async_reg = "true" *) reg [WIDTH-1:0] ff_meta = {WIDTH {1'b0}} ;
    always @(posedge dout_clk  or posedge rst_p ) begin
        if( rst_p )
            ff_meta <= 'd0;
        else 
            ff_meta <= ff_launch;
    end

    (* async_reg = "true" *) reg [WIDTH-1:0] ff_sync = {WIDTH {1'b0}} ;
    always @(posedge dout_clk or posedge rst_p ) begin
         if( rst_p )
            ff_sync <= 'd0;
         else 
            ff_sync <= ff_meta;
    end

    assign dout = ff_sync;
endmodule