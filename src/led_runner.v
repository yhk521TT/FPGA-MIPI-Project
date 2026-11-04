// LED跑马灯模块
// 支持可配置数量LED的流水灯效果
module led_runner #(
    parameter LED_NUM = 20,           // LED数量
    parameter CLK_FREQ = 50_000_000,  // 时钟频率 (Hz)
    parameter SPEED_MS = 100          // 跑马灯速度 (毫秒)
)(
    input  wire clk,
    input  wire rst_n,
    input  wire enable,               // 使能信号：1=运行，0=停止
    output reg [LED_NUM-1:0] led_out
);

// 计算分频系数
localparam DIV_CNT = CLK_FREQ / 1000 * SPEED_MS;

// 分频计数器
reg [31:0] div_cnt;
reg tick;

// 跑马灯位置
reg [4:0] led_pos;  // 支持最多32个LED

// 分频产生tick信号
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        div_cnt <= 0;
        tick <= 1'b0;
    end else begin
        if (div_cnt >= DIV_CNT - 1) begin
            div_cnt <= 0;
            tick <= 1'b1;
        end else begin
            div_cnt <= div_cnt + 1;
            tick <= 1'b0;
        end
    end
end

// 跑马灯位置控制 - 只有在enable=1时才移动
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        led_pos <= 0;
    end else if (tick && enable) begin
        if (led_pos >= LED_NUM - 1)
            led_pos <= 0;
        else
            led_pos <= led_pos + 1;
    end
end

// LED输出控制 (独热码)
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        led_out <= {{(LED_NUM-1){1'b0}}, 1'b1};  // 初始第一个LED亮
    end else if (tick) begin
        led_out <= (1'b1 << led_pos);
    end
end

endmodule
