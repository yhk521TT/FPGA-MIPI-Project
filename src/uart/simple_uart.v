// 简单可靠的UART模块 - 115200 8N1
module simple_uart #(
    parameter CLK_FREQ = 25000000,  // 时钟频率
    parameter BAUD_RATE = 115200     // 波特率
)(
    input wire clk,
    input wire rst_n,
    input wire rx,
    output reg tx,
    output reg [7:0] rx_data,
    output reg rx_valid,
    input wire [7:0] tx_data,
    input wire tx_start,
    output reg tx_busy
);

localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;

// RX状态机
localparam RX_IDLE = 2'd0;
localparam RX_START = 2'd1;
localparam RX_DATA = 2'd2;
localparam RX_STOP = 2'd3;

reg [1:0] rx_state;
reg [15:0] rx_clk_count;
reg [2:0] rx_bit_index;
reg [7:0] rx_byte;

// RX同步
reg [2:0] rx_sync;
wire rx_sync_bit = rx_sync[2];

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        rx_sync <= 3'b111;
    else
        rx_sync <= {rx_sync[1:0], rx};
end

// RX接收逻辑
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rx_state <= RX_IDLE;
        rx_clk_count <= 0;
        rx_bit_index <= 0;
        rx_byte <= 0;
        rx_data <= 0;
        rx_valid <= 0;
    end else begin
        rx_valid <= 0;
        
        case (rx_state)
            RX_IDLE: begin
                rx_clk_count <= 0;
                rx_bit_index <= 0;
                if (rx_sync_bit == 0) begin  // 检测到起始位
                    rx_state <= RX_START;
                end
            end
            
            RX_START: begin
                if (rx_clk_count == (CLKS_PER_BIT - 1) / 2) begin
                    if (rx_sync_bit == 0) begin  // 确认起始位
                        rx_clk_count <= 0;
                        rx_state <= RX_DATA;
                    end else begin
                        rx_state <= RX_IDLE;
                    end
                end else begin
                    rx_clk_count <= rx_clk_count + 1;
                end
            end
            
            RX_DATA: begin
                if (rx_clk_count < CLKS_PER_BIT - 1) begin
                    rx_clk_count <= rx_clk_count + 1;
                end else begin
                    rx_clk_count <= 0;
                    rx_byte[rx_bit_index] <= rx_sync_bit;
                    
                    if (rx_bit_index < 7) begin
                        rx_bit_index <= rx_bit_index + 1;
                    end else begin
                        rx_bit_index <= 0;
                        rx_state <= RX_STOP;
                    end
                end
            end
            
            RX_STOP: begin
                if (rx_clk_count < CLKS_PER_BIT - 1) begin
                    rx_clk_count <= rx_clk_count + 1;
                end else begin
                    rx_clk_count <= 0;
                    rx_data <= rx_byte;
                    rx_valid <= 1;
                    rx_state <= RX_IDLE;
                end
            end
            
            default: rx_state <= RX_IDLE;
        endcase
    end
end

// TX状态机
localparam TX_IDLE = 2'd0;
localparam TX_START = 2'd1;
localparam TX_DATA = 2'd2;
localparam TX_STOP = 2'd3;

reg [1:0] tx_state;
reg [15:0] tx_clk_count;
reg [2:0] tx_bit_index;
reg [7:0] tx_byte;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tx_state <= TX_IDLE;
        tx_clk_count <= 0;
        tx_bit_index <= 0;
        tx_byte <= 0;
        tx <= 1;
        tx_busy <= 0;
    end else begin
        case (tx_state)
            TX_IDLE: begin
                tx <= 1;
                tx_clk_count <= 0;
                tx_bit_index <= 0;
                tx_busy <= 0;
                
                if (tx_start) begin
                    tx_byte <= tx_data;
                    tx_busy <= 1;
                    tx_state <= TX_START;
                end
            end
            
            TX_START: begin
                tx <= 0;  // 起始位
                
                if (tx_clk_count < CLKS_PER_BIT - 1) begin
                    tx_clk_count <= tx_clk_count + 1;
                end else begin
                    tx_clk_count <= 0;
                    tx_state <= TX_DATA;
                end
            end
            
            TX_DATA: begin
                tx <= tx_byte[tx_bit_index];
                
                if (tx_clk_count < CLKS_PER_BIT - 1) begin
                    tx_clk_count <= tx_clk_count + 1;
                end else begin
                    tx_clk_count <= 0;
                    
                    if (tx_bit_index < 7) begin
                        tx_bit_index <= tx_bit_index + 1;
                    end else begin
                        tx_bit_index <= 0;
                        tx_state <= TX_STOP;
                    end
                end
            end
            
            TX_STOP: begin
                tx <= 1;  // 停止位
                
                if (tx_clk_count < CLKS_PER_BIT - 1) begin
                    tx_clk_count <= tx_clk_count + 1;
                end else begin
                    tx_clk_count <= 0;
                    tx_state <= TX_IDLE;
                end
            end
            
            default: tx_state <= TX_IDLE;
        endcase
    end
end

endmodule
