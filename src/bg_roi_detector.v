// bg_roi_detector.v - 用于单对象演示的绿色背景 ROI 检测器。
// 坐标采用管道采样网格：一个采样点代表两个像素。
module bg_roi_detector #(
    parameter H_LINE = 960,
    parameter V_LINE = 1080,
    parameter MIN_AREA = 20'd600,
    parameter MIN_W = 11'd20,
    parameter MIN_H = 11'd20
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        vs_i,
    input  wire        de_i,
    input  wire [7:0]  r_i,
    input  wire [7:0]  g_i,
    input  wire [7:0]  b_i,
    input  wire [10:0] h_cnt,
    input  wire [10:0] v_cnt,
    output reg         blob_new,
    output reg         blob_valid,
    output reg  [10:0] blob_x_min,
    output reg  [10:0] blob_x_max,
    output reg  [10:0] blob_y_min,
    output reg  [10:0] blob_y_max,
    output reg  [19:0] blob_area,
    output reg  [10:0] blob_center_x,
    output reg  [10:0] blob_center_y
);

    reg        vs_prev;
    reg        frame_has_target;
    reg [10:0] frame_x_min;
    reg [10:0] frame_x_max;
    reg [10:0] frame_y_min;
    reg [10:0] frame_y_max;
    reg [19:0] frame_area;

    wire [8:0] g_margin_r = {1'b0, r_i} + 9'd26;
    wire [8:0] g_margin_b = {1'b0, b_i} + 9'd18;
    wire       green_bg = (g_i > 8'd55) &&
                          ({1'b0, g_i} > g_margin_r) &&
                          ({1'b0, g_i} > g_margin_b);
    wire       visible_sample = (r_i > 8'd12) || (g_i > 8'd12) || (b_i > 8'd12);
    wire       target_sample = de_i && visible_sample && !green_bg;
    wire [10:0] frame_w = frame_x_max - frame_x_min + 1'b1;
    wire [10:0] frame_h = frame_y_max - frame_y_min + 1'b1;
    wire        frame_valid = frame_has_target &&
                              (frame_area > MIN_AREA) &&
                              (frame_w > MIN_W) &&
                              (frame_h > MIN_H) &&
                              (frame_x_max < H_LINE[10:0]) &&
                              (frame_y_max < V_LINE[10:0]);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vs_prev <= 1'b0;
            frame_has_target <= 1'b0;
            frame_x_min <= 11'd0;
            frame_x_max <= 11'd0;
            frame_y_min <= 11'd0;
            frame_y_max <= 11'd0;
            frame_area <= 20'd0;
            blob_new <= 1'b0;
            blob_valid <= 1'b0;
            blob_x_min <= 11'd0;
            blob_x_max <= 11'd0;
            blob_y_min <= 11'd0;
            blob_y_max <= 11'd0;
            blob_area <= 20'd0;
            blob_center_x <= 11'd0;
            blob_center_y <= 11'd0;
        end else begin
            vs_prev <= vs_i;
            blob_new <= 1'b0;

            if (vs_i && !vs_prev) begin
                blob_new <= 1'b1;
                blob_valid <= frame_valid;
                if (frame_valid) begin
                    blob_x_min <= frame_x_min;
                    blob_x_max <= frame_x_max;
                    blob_y_min <= frame_y_min;
                    blob_y_max <= frame_y_max;
                    blob_area <= frame_area;
                    blob_center_x <= frame_x_min + (frame_w >> 1);
                    blob_center_y <= frame_y_min + (frame_h >> 1);
                end

                frame_has_target <= 1'b0;
                frame_x_min <= 11'd0;
                frame_x_max <= 11'd0;
                frame_y_min <= 11'd0;
                frame_y_max <= 11'd0;
                frame_area <= 20'd0;
            end else if (target_sample) begin
                frame_area <= frame_area + 1'b1;
                if (!frame_has_target) begin
                    frame_has_target <= 1'b1;
                    frame_x_min <= h_cnt;
                    frame_x_max <= h_cnt;
                    frame_y_min <= v_cnt;
                    frame_y_max <= v_cnt;
                end else begin
                    if (h_cnt < frame_x_min)
                        frame_x_min <= h_cnt;
                    if (h_cnt > frame_x_max)
                        frame_x_max <= h_cnt;
                    if (v_cnt < frame_y_min)
                        frame_y_min <= v_cnt;
                    if (v_cnt > frame_y_max)
                        frame_y_max <= v_cnt;
                end
            end
        end
    end

endmodule
