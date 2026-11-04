

module par2ser_512t128 #(
	parameter I_VID_WIDTH = 512,
	parameter O_VID_WIDTH = 32
	 
)(
input		wire										clk		,    
input		wire										rst_n	,
output      reg                                         rdfifo_rd_en,
input       wire                                        rdfifo_rd_empty,
input       wire                                        rdfifo_rd_valid,
input		wire	[I_VID_WIDTH-1:0] 					rdfifo_rd_data,
input       wire                                        ena,
input		wire										i_start	, //active hgih
input		wire										i_end	, //active high


output		reg										wrfifo_wr_en = 'd0,
output		reg	[O_VID_WIDTH-1:0]					wrfifo_wr_data = 'd0,
input       wire                                        wrfifo_wr_full



);
//==================================================================================

reg [2:0] cnt = 'd0;
wire data_en = ~(wrfifo_wr_full | rdfifo_rd_empty);
reg data_contiune = 'd0;
always @( posedge clk or negedge rst_n )
begin
    if( !rst_n ) begin 
        cnt <= 'd0;
        data_contiune <= 1'b0;
        rdfifo_rd_en <= 1'b0;
        wrfifo_wr_en <= 'd0;
    end else if( ena ) begin
        rdfifo_rd_en <= 1'b0;
        wrfifo_wr_en <= 'd0;
        case( cnt )
        3'd0 : begin
            if( data_en ) begin
                cnt <= 3'd1;
                rdfifo_rd_en <= 1'b1;
            end
        end
        3'd1 : begin
            cnt <= 3'd2;
        end
        3'd2: begin
            cnt <= 3'd3;
            wrfifo_wr_data  <= rdfifo_rd_data[511:384];
            wrfifo_wr_en    <= 1'b1;
        end
        3'd3 : begin
            wrfifo_wr_data  <= rdfifo_rd_data[383:256];
            wrfifo_wr_en    <= 1'b1;
            cnt <= 3'd4;
        end
        3'd4 : begin
            wrfifo_wr_data  <= rdfifo_rd_data[255:128];
            wrfifo_wr_en    <= 1'b1;
            rdfifo_rd_en    <= data_en;
            data_contiune   <= data_en;
            cnt <= 3'd5;
        end
        3'd5 : begin
            wrfifo_wr_data  <= rdfifo_rd_data[127:0];
            wrfifo_wr_en    <= 1'b1;
            rdfifo_rd_en    <= 1'b0;
            cnt <= data_contiune ? 3'd2 : 3'd0;
            data_contiune <= data_contiune ? 1'b0 : data_contiune;
        end

        default:;
        endcase
    end else begin
        cnt <= 'd0;
        data_contiune <= 1'b0;
        rdfifo_rd_en <= 1'b0;
        wrfifo_wr_en <= 'd0;
    end
end



endmodule

