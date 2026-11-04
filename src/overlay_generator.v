// overlay_generator.v - 在视频上绘制包含识别结果的文本叠加层
// 同时在检测到的物体周围绘制绿色边界框
module overlay_generator #(
    parameter HACT = 960,
    parameter VACT = 1080
)(
    input  wire        clk,
    input  wire        rst_n,
    // video input
    input  wire        vs_i,
    input  wire        de_i,
    input  wire [7:0]  r_i,
    input  wire [7:0]  g_i,
    input  wire [7:0]  b_i,
    // recognition results (latched per frame)
    input  wire [2:0]  color_id,
    input  wire [2:0]  shape_id,
    input  wire [1:0]  size_id,
    input  wire [7:0]  latency_ms,
    input  wire        pick_allowed,
    input  wire        center_near_pick,
    input  wire [10:0] pick_center_x,
    input  wire [10:0] pick_center_y,
    // pixel coordinates
    input  wire [11:0] h_cnt,
    input  wire [11:0] v_cnt,
    // blob bounding box signals (from sobel_with_blob)
    input  wire        blob_new,
    input  wire [10:0] blob_x_min,
    input  wire [10:0] blob_x_max,
    input  wire [10:0] blob_y_min,
    input  wire [10:0] blob_y_max,
    // Current pixel coordinates from sobel module (for bbox alignment)
    input  wire [10:0] h_blob,
    input  wire [10:0] v_blob,
    // video output with overlay
    output reg         vs_o,
    output reg         de_o,
    output reg  [7:0]  r_o,
    output reg  [7:0]  g_o,
    output reg  [7:0]  b_o,
    output reg         overlay_active_o
);

    // 用于识别结果的锁存寄存器
    reg [2:0] latch_color;
    reg [2:0] latch_shape;
    reg [1:0] latch_size;
    reg [7:0] latch_latency_ms;
    reg       latch_pick_allowed;
    reg       latch_center_near_pick;

    // Blob 边界框的锁存寄存器
    reg [10:0] latch_blob_x_min;
    reg [10:0] latch_blob_x_max;
    reg [10:0] latch_blob_y_min;
    reg [10:0] latch_blob_y_max;
    reg        latch_blob_valid;
    reg [10:0] latch_blob_h;
    reg [10:0] latch_blob_v;
    reg [4:0]  bbox_hold_cnt;

    // 持续跟踪识别结果。上游分类器已经
    // 保持 ID 不变，这使得 OSD 能够根据帧内边界框结果进行更新。
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            latch_color <= 3'd0;
            latch_shape <= 3'd0;
            latch_size  <= 2'd0;
            latch_latency_ms <= 8'd0;
            latch_pick_allowed <= 1'b0;
            latch_center_near_pick <= 1'b0;
        end else begin
            latch_color <= color_id;
            latch_shape <= shape_id;
            latch_size  <= size_id;
            latch_latency_ms <= latency_ms;
            latch_pick_allowed <= pick_allowed;
            latch_center_near_pick <= center_near_pick;
        end
    end

    // 在 blob_new 中锁定斑块的边界框和像素位置
    reg blob_vs_prev;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            latch_blob_x_min <= 11'd0;
            latch_blob_x_max <= 11'd0;
            latch_blob_y_min <= 11'd0;
            latch_blob_y_max <= 11'd0;
            latch_blob_valid <= 1'b0;
            latch_blob_h <= 11'd0;
            latch_blob_v <= 11'd0;
            bbox_hold_cnt <= 5'd0;
            blob_vs_prev <= 1'b0;
        end else begin
            blob_vs_prev <= vs_i;
            if (blob_new) begin
                latch_blob_x_min <= blob_x_min;
                latch_blob_x_max <= blob_x_max;
                latch_blob_y_min <= blob_y_min;
                latch_blob_y_max <= blob_y_max;
                latch_blob_valid <= 1'b1;
                latch_blob_h <= h_blob;
                latch_blob_v <= v_blob;
                bbox_hold_cnt <= 5'd20;
            end else if (vs_i && !blob_vs_prev) begin  // rising edge of vs_i - reset
                if (bbox_hold_cnt != 5'd0) begin
                    bbox_hold_cnt <= bbox_hold_cnt - 1'b1;
                end else begin
                    latch_blob_valid <= 1'b0;
                end
            end
        end
    end

    // 仅显示结果标签。避免使用全黑横幅，以确保摄像头画面清晰。
    wire in_bar = 1'b0;
    localparam [11:0] LABEL_W = 12'd688;
    localparam [11:0] LABEL_H = 12'd22;
    localparam [11:0] LABEL_X_MARGIN = 12'd6;
    localparam [11:0] LABEL_Y_MARGIN = 12'd4;
    localparam [11:0] LABEL_X_MAX = HACT - LABEL_W;

    wire [11:0] blob_x_min_12 = {1'b0, latch_blob_x_min};
    wire [11:0] blob_y_min_12 = {1'b0, latch_blob_y_min};
    wire [11:0] label_x = latch_blob_valid ?
                           ((blob_x_min_12 > LABEL_X_MAX) ? LABEL_X_MAX : blob_x_min_12) :
                           12'd20;
    wire [11:0] label_y_above = blob_y_min_12 - LABEL_H - LABEL_Y_MARGIN;
    wire [11:0] label_y_below = blob_y_min_12 + 12'd4;
    wire [11:0] label_y = latch_blob_valid ?
                           ((blob_y_min_12 > (LABEL_H + LABEL_Y_MARGIN)) ?
                            label_y_above : label_y_below) :
                           12'd16;
    wire [11:0] label_x_end = label_x + LABEL_W;
    wire [11:0] label_y_end = label_y + LABEL_H;
    wire in_label_bg = latch_blob_valid &&
                       (h_cnt >= label_x) && (h_cnt < label_x_end) &&
                       (v_cnt >= label_y) && (v_cnt < label_y_end);

    // === 边界框绘制（检测到的物体周围的绿色矩形） ===
    // 绿色框的厚度
    localparam BOX_THICK = 12'd4;

    // 边界框的上边缘
    wire in_box_top = latch_blob_valid &&
                      (v_cnt >= latch_blob_y_min) &&
                      (v_cnt < (latch_blob_y_min + BOX_THICK)) &&
                      (h_cnt >= latch_blob_x_min) &&
                      (h_cnt <= latch_blob_x_max);

    wire [10:0] box_x_max_lo = (latch_blob_x_max > BOX_THICK[10:0]) ?
                               (latch_blob_x_max - BOX_THICK[10:0]) : 11'd0;
    wire [10:0] box_y_max_lo = (latch_blob_y_max > BOX_THICK[10:0]) ?
                               (latch_blob_y_max - BOX_THICK[10:0]) : 11'd0;

    // 边界框的下边缘
    wire in_box_bottom = latch_blob_valid &&
                         (v_cnt <= latch_blob_y_max) &&
                         (v_cnt > box_y_max_lo) &&
                         (h_cnt >= latch_blob_x_min) &&
                         (h_cnt <= latch_blob_x_max);

    // 边界框的左边缘
    wire in_box_left = latch_blob_valid &&
                       (h_cnt >= latch_blob_x_min) &&
                       (h_cnt < (latch_blob_x_min + BOX_THICK)) &&
                       (v_cnt >= latch_blob_y_min) &&
                       (v_cnt <= latch_blob_y_max);

    // 边界框的右边缘
    wire in_box_right = latch_blob_valid &&
                        (h_cnt <= latch_blob_x_max) &&
                        (h_cnt > box_x_max_lo) &&
                        (v_cnt >= latch_blob_y_min) &&
                        (v_cnt <= latch_blob_y_max);

    wire in_bbox = in_box_top | in_box_bottom | in_box_left | in_box_right;

    wire [11:0] center_x = {1'b0, latch_blob_h};
    wire [11:0] center_y = {1'b0, latch_blob_v};
    wire [11:0] cross_x_min = (center_x > 12'd10) ? (center_x - 12'd10) : 12'd0;
    wire [11:0] cross_x_max = center_x + 12'd10;
    wire [11:0] cross_y_min = (center_y > 12'd10) ? (center_y - 12'd10) : 12'd0;
    wire [11:0] cross_y_max = center_y + 12'd10;
    wire [11:0] center_x_lo = (center_x > 12'd1) ? (center_x - 12'd1) : 12'd0;
    wire [11:0] center_y_lo = (center_y > 12'd1) ? (center_y - 12'd1) : 12'd0;
    wire in_cross_h = latch_blob_valid &&
                      (v_cnt >= center_y_lo) && (v_cnt <= (center_y + 12'd1)) &&
                      (h_cnt >= cross_x_min) && (h_cnt <= cross_x_max);
    wire in_cross_v = latch_blob_valid &&
                      (h_cnt >= center_x_lo) && (h_cnt <= (center_x + 12'd1)) &&
                      (v_cnt >= cross_y_min) && (v_cnt <= cross_y_max);
    wire in_cross = in_cross_h | in_cross_v;

    wire [11:0] fixed_center_x = {1'b0, pick_center_x};
    wire [11:0] fixed_center_y = {1'b0, pick_center_y};
    wire [11:0] fixed_cross_x_min = (fixed_center_x > 12'd22) ? (fixed_center_x - 12'd22) : 12'd0;
    wire [11:0] fixed_cross_x_max = fixed_center_x + 12'd22;
    wire [11:0] fixed_cross_y_min = (fixed_center_y > 12'd22) ? (fixed_center_y - 12'd22) : 12'd0;
    wire [11:0] fixed_cross_y_max = fixed_center_y + 12'd22;
    wire [11:0] fixed_center_x_lo = (fixed_center_x > 12'd2) ? (fixed_center_x - 12'd2) : 12'd0;
    wire [11:0] fixed_center_y_lo = (fixed_center_y > 12'd2) ? (fixed_center_y - 12'd2) : 12'd0;
    wire in_fixed_cross_h = (v_cnt >= fixed_center_y_lo) && (v_cnt <= (fixed_center_y + 12'd2)) &&
                            (h_cnt >= fixed_cross_x_min) && (h_cnt <= fixed_cross_x_max);
    wire in_fixed_cross_v = (h_cnt >= fixed_center_x_lo) && (h_cnt <= (fixed_center_x + 12'd2)) &&
                            (v_cnt >= fixed_cross_y_min) && (v_cnt <= fixed_cross_y_max);
    wire in_fixed_cross = in_fixed_cross_h | in_fixed_cross_v;

    // === Color indicator dots (5 dots showing detected color) ===
    wire [2:0] dot_color = latch_color;
    wire in_dot_region = 1'b0;

    // 5个位于固定x位置的彩色点
    wire in_dot1 = in_dot_region && (h_cnt >= 12'd20)  && (h_cnt < 12'd60);
    wire in_dot2 = in_dot_region && (h_cnt >= 12'd70)  && (h_cnt < 12'd110);
    wire in_dot3 = in_dot_region && (h_cnt >= 12'd120) && (h_cnt < 12'd160);
    wire in_dot4 = in_dot_region && (h_cnt >= 12'd170) && (h_cnt < 12'd210);
    wire in_dot5 = in_dot_region && (h_cnt >= 12'd220) && (h_cnt < 12'd260);

    // 点的位置颜色映射：1=白色，2=红色，3=黑色，4=蓝色，5=黄色
    reg [7:0] dot_r, dot_g, dot_b;
    always @(*) begin
        dot_r = 8'd0; dot_g = 8'd0; dot_b = 8'd0;
        case (dot_color)
            3'd1: begin dot_r = 8'd255; dot_g = 8'd255; dot_b = 8'd255; end // white
            3'd2: begin dot_r = 8'd255; dot_g = 8'd0;   dot_b = 8'd0;   end // red
            3'd3: begin dot_r = 8'd0;   dot_g = 8'd0;   dot_b = 8'd0;   end // black
            3'd4: begin dot_r = 8'd0;   dot_g = 8'd0;   dot_b = 8'd255; end // blue
            3'd5: begin dot_r = 8'd255; dot_g = 8'd255; dot_b = 8'd0;   end // yellow
            default: begin dot_r = 8'd128; dot_g = 8'd128; dot_b = 8'd128; end
        endcase
    end

    // === 形状指示条 ===
    wire in_shape_bar = 1'b0 &&
                        (h_cnt >= 12'd860) && (h_cnt < 12'd940) &&
                        (v_cnt >= 12'd20) && (v_cnt < 12'd44);

    reg [7:0] shape_r, shape_g, shape_b;
    always @(*) begin
        shape_r = 8'd128; shape_g = 8'd128; shape_b = 8'd128;
        case (latch_shape)
            3'd1: begin shape_r = 8'd0;   shape_g = 8'd200; shape_b = 8'd200; end // cylinder - cyan
            3'd2: begin shape_r = 8'd200; shape_g = 8'd100; shape_b = 8'd0;   end // cube - orange
            3'd3: begin shape_r = 8'd200; shape_g = 8'd0;   shape_b = 8'd200; end // triangle - magenta
            default: ;
        endcase
    end

    // === 尺寸指示条 ===
    wire in_size_bar = 1'b0 &&
                       (h_cnt >= 12'd320) && (h_cnt < 12'd500) &&
                       (v_cnt >= 12'd20) && (v_cnt < 12'd44);
    wire [11:0] size_bar_w = (latch_size == 2'd1) ? 12'd20 :
                             (latch_size == 2'd2) ? 12'd60 : 12'd100;
    wire in_size_fill = in_size_bar && ((h_cnt - 12'd320) < size_bar_w);

    // 顶部信息栏的条形背景
    wire [7:0] bar_r = 8'd32;
    wire [7:0] bar_g = 8'd32;
    wire [7:0] bar_b = 8'd32;

    function [7:0] hex_char;
        input [3:0] value;
        begin
            case (value)
                4'h0: hex_char = 8'h30;
                4'h1: hex_char = 8'h31;
                4'h2: hex_char = 8'h32;
                4'h3: hex_char = 8'h33;
                4'h4: hex_char = 8'h34;
                4'h5: hex_char = 8'h35;
                4'h6: hex_char = 8'h36;
                4'h7: hex_char = 8'h37;
                4'h8: hex_char = 8'h38;
                4'h9: hex_char = 8'h39;
                4'hA: hex_char = 8'h41;
                4'hB: hex_char = 8'h42;
                4'hC: hex_char = 8'h43;
                4'hD: hex_char = 8'h44;
                4'hE: hex_char = 8'h45;
                default: hex_char = 8'h46;
            endcase
        end
    endfunction

    // === 可读的OSD文本：“CLR:BLUE SHP:CYL SZ:M T:xxMS PICK” ===
    function [7:0] osd_char;
        input [5:0] idx;
        input [2:0] color;
        input [2:0] shape;
        input [1:0] size;
        input [7:0] latency;
        input       pick;
        input       near_pick;
        begin
            osd_char = 8'h20; // space
            case (idx)
                5'd0:  osd_char = 8'h43; // C
                5'd1:  osd_char = 8'h4c; // L
                5'd2:  osd_char = 8'h52; // R
                5'd3:  osd_char = 8'h3a; // :
                5'd4, 5'd5, 5'd6, 5'd7, 5'd8, 5'd9: begin
                    case (color)
                        3'd1: begin // WHITE
                            case (idx)
                                5'd4: osd_char = 8'h57; // W
                                5'd5: osd_char = 8'h48; // H
                                5'd6: osd_char = 8'h49; // I
                                5'd7: osd_char = 8'h54; // T
                                5'd8: osd_char = 8'h45; // E
                                default: osd_char = 8'h20;
                            endcase
                        end
                        3'd2: begin // RED
                            case (idx)
                                5'd4: osd_char = 8'h52; // R
                                5'd5: osd_char = 8'h45; // E
                                5'd6: osd_char = 8'h44; // D
                                default: osd_char = 8'h20;
                            endcase
                        end
                        3'd3: begin // BLACK
                            case (idx)
                                5'd4: osd_char = 8'h42; // B
                                5'd5: osd_char = 8'h4c; // L
                                5'd6: osd_char = 8'h41; // A
                                5'd7: osd_char = 8'h43; // C
                                5'd8: osd_char = 8'h4b; // K
                                default: osd_char = 8'h20;
                            endcase
                        end
                        3'd4: begin // BLUE
                            case (idx)
                                5'd4: osd_char = 8'h42; // B
                                5'd5: osd_char = 8'h4c; // L
                                5'd6: osd_char = 8'h55; // U
                                5'd7: osd_char = 8'h45; // E
                                default: osd_char = 8'h20;
                            endcase
                        end
                        3'd5: begin // YELLOW
                            case (idx)
                                5'd4: osd_char = 8'h59; // Y
                                5'd5: osd_char = 8'h45; // E
                                5'd6: osd_char = 8'h4c; // L
                                5'd7: osd_char = 8'h4c; // L
                                5'd8: osd_char = 8'h4f; // O
                                5'd9: osd_char = 8'h57; // W
                            endcase
                        end
                        default: begin // NONE
                            case (idx)
                                5'd4: osd_char = 8'h4e; // N
                                5'd5: osd_char = 8'h4f; // O
                                5'd6: osd_char = 8'h4e; // N
                                5'd7: osd_char = 8'h45; // E
                                default: osd_char = 8'h20;
                            endcase
                        end
                    endcase
                end
                5'd10: osd_char = 8'h20; // space
                5'd11: osd_char = 8'h53; // S
                5'd12: osd_char = 8'h48; // H
                5'd13: osd_char = 8'h50; // P
                5'd14: osd_char = 8'h3a; // :
                5'd15, 5'd16, 5'd17, 5'd18: begin
                    case (shape)
                        3'd1: begin // CYL
                            case (idx)
                                5'd15: osd_char = 8'h43; // C
                                5'd16: osd_char = 8'h59; // Y
                                5'd17: osd_char = 8'h4c; // L
                                default: osd_char = 8'h20;
                            endcase
                        end
                        3'd2: begin // CUBE
                            case (idx)
                                5'd15: osd_char = 8'h43; // C
                                5'd16: osd_char = 8'h55; // U
                                5'd17: osd_char = 8'h42; // B
                                5'd18: osd_char = 8'h45; // E
                            endcase
                        end
                        3'd3: begin // TRI
                            case (idx)
                                5'd15: osd_char = 8'h54; // T
                                5'd16: osd_char = 8'h52; // R
                                5'd17: osd_char = 8'h49; // I
                                default: osd_char = 8'h20;
                            endcase
                        end
                        default: begin // NONE
                            case (idx)
                                5'd15: osd_char = 8'h4e; // N
                                5'd16: osd_char = 8'h4f; // O
                                5'd17: osd_char = 8'h4e; // N
                                5'd18: osd_char = 8'h45; // E
                            endcase
                        end
                    endcase
                end
                5'd19: osd_char = 8'h20; // space
                5'd20: osd_char = 8'h53; // S
                5'd21: osd_char = 8'h5a; // Z
                5'd22: osd_char = 8'h3a; // :
                5'd23: begin
                    case (size)
                        2'd1: osd_char = 8'h53; // S
                        2'd2: osd_char = 8'h4d; // M
                        2'd3: osd_char = 8'h4c; // L
                        default: osd_char = 8'h4e; // N
                    endcase
                end
                6'd24: osd_char = 8'h20; // space
                6'd25: osd_char = 8'h54; // T
                6'd26: osd_char = 8'h3a; // :
                6'd27: osd_char = hex_char(latency[7:4]);
                6'd28: osd_char = hex_char(latency[3:0]);
                6'd29: osd_char = 8'h4d; // M
                6'd30: osd_char = 8'h53; // S
                6'd31: osd_char = 8'h20; // space
                6'd32, 6'd33, 6'd34, 6'd35: begin
                    if (pick) begin
                        case (idx)
                            6'd32: osd_char = 8'h50; // P
                            6'd33: osd_char = 8'h49; // I
                            6'd34: osd_char = 8'h43; // C
                            6'd35: osd_char = 8'h4b; // K
                            default: osd_char = 8'h20;
                        endcase
                    end else if ((shape == 3'd2) && !near_pick) begin
                        case (idx)
                            6'd32: osd_char = 8'h4d; // M
                            6'd33: osd_char = 8'h4f; // O
                            6'd34: osd_char = 8'h56; // V
                            6'd35: osd_char = 8'h45; // E
                            default: osd_char = 8'h20;
                        endcase
                    end else begin
                        case (idx)
                            6'd32: osd_char = 8'h53; // S
                            6'd33: osd_char = 8'h4b; // K
                            6'd34: osd_char = 8'h49; // I
                            6'd35: osd_char = 8'h50; // P
                            default: osd_char = 8'h20;
                        endcase
                    end
                end
                default: osd_char = 8'h20;
            endcase
        end
    endfunction

    function [4:0] font5x7;
        input [7:0] ch;
        input [2:0] row;
        begin
            font5x7 = 5'b00000;
            case (ch)
                8'h30: begin // 0
                    case (row)
                        3'd0: font5x7 = 5'b01110;
                        3'd1: font5x7 = 5'b10001;
                        3'd2: font5x7 = 5'b10011;
                        3'd3: font5x7 = 5'b10101;
                        3'd4: font5x7 = 5'b11001;
                        3'd5: font5x7 = 5'b10001;
                        3'd6: font5x7 = 5'b01110;
                    endcase
                end
                8'h31: begin // 1
                    case (row)
                        3'd0: font5x7 = 5'b00100;
                        3'd1: font5x7 = 5'b01100;
                        3'd2, 3'd3, 3'd4, 3'd5: font5x7 = 5'b00100;
                        3'd6: font5x7 = 5'b01110;
                    endcase
                end
                8'h32: begin // 2
                    case (row)
                        3'd0: font5x7 = 5'b01110;
                        3'd1: font5x7 = 5'b10001;
                        3'd2: font5x7 = 5'b00001;
                        3'd3: font5x7 = 5'b00010;
                        3'd4: font5x7 = 5'b00100;
                        3'd5: font5x7 = 5'b01000;
                        3'd6: font5x7 = 5'b11111;
                    endcase
                end
                8'h33: begin // 3
                    case (row)
                        3'd0: font5x7 = 5'b11110;
                        3'd1: font5x7 = 5'b00001;
                        3'd2: font5x7 = 5'b00001;
                        3'd3: font5x7 = 5'b01110;
                        3'd4: font5x7 = 5'b00001;
                        3'd5: font5x7 = 5'b00001;
                        3'd6: font5x7 = 5'b11110;
                    endcase
                end
                8'h34: begin // 4
                    case (row)
                        3'd0: font5x7 = 5'b00010;
                        3'd1: font5x7 = 5'b00110;
                        3'd2: font5x7 = 5'b01010;
                        3'd3: font5x7 = 5'b10010;
                        3'd4: font5x7 = 5'b11111;
                        3'd5: font5x7 = 5'b00010;
                        3'd6: font5x7 = 5'b00010;
                    endcase
                end
                8'h35: begin // 5
                    case (row)
                        3'd0: font5x7 = 5'b11111;
                        3'd1: font5x7 = 5'b10000;
                        3'd2: font5x7 = 5'b10000;
                        3'd3: font5x7 = 5'b11110;
                        3'd4: font5x7 = 5'b00001;
                        3'd5: font5x7 = 5'b00001;
                        3'd6: font5x7 = 5'b11110;
                    endcase
                end
                8'h36: begin // 6
                    case (row)
                        3'd0: font5x7 = 5'b01110;
                        3'd1: font5x7 = 5'b10000;
                        3'd2: font5x7 = 5'b10000;
                        3'd3: font5x7 = 5'b11110;
                        3'd4: font5x7 = 5'b10001;
                        3'd5: font5x7 = 5'b10001;
                        3'd6: font5x7 = 5'b01110;
                    endcase
                end
                8'h37: begin // 7
                    case (row)
                        3'd0: font5x7 = 5'b11111;
                        3'd1: font5x7 = 5'b00001;
                        3'd2: font5x7 = 5'b00010;
                        3'd3: font5x7 = 5'b00100;
                        3'd4: font5x7 = 5'b01000;
                        3'd5: font5x7 = 5'b01000;
                        3'd6: font5x7 = 5'b01000;
                    endcase
                end
                8'h38: begin // 8
                    case (row)
                        3'd0: font5x7 = 5'b01110;
                        3'd1: font5x7 = 5'b10001;
                        3'd2: font5x7 = 5'b10001;
                        3'd3: font5x7 = 5'b01110;
                        3'd4: font5x7 = 5'b10001;
                        3'd5: font5x7 = 5'b10001;
                        3'd6: font5x7 = 5'b01110;
                    endcase
                end
                8'h39: begin // 9
                    case (row)
                        3'd0: font5x7 = 5'b01110;
                        3'd1: font5x7 = 5'b10001;
                        3'd2: font5x7 = 5'b10001;
                        3'd3: font5x7 = 5'b01111;
                        3'd4: font5x7 = 5'b00001;
                        3'd5: font5x7 = 5'b00001;
                        3'd6: font5x7 = 5'b01110;
                    endcase
                end
                8'h3a: begin // :
                    case (row)
                        3'd1, 3'd2, 3'd4, 3'd5: font5x7 = 5'b00100;
                        default: font5x7 = 5'b00000;
                    endcase
                end
                8'h41: begin // A
                    case (row)
                        3'd0: font5x7 = 5'b01110;
                        3'd1: font5x7 = 5'b10001;
                        3'd2: font5x7 = 5'b10001;
                        3'd3: font5x7 = 5'b11111;
                        3'd4: font5x7 = 5'b10001;
                        3'd5: font5x7 = 5'b10001;
                        3'd6: font5x7 = 5'b10001;
                    endcase
                end
                8'h42: begin // B
                    case (row)
                        3'd0: font5x7 = 5'b11110;
                        3'd1: font5x7 = 5'b10001;
                        3'd2: font5x7 = 5'b10001;
                        3'd3: font5x7 = 5'b11110;
                        3'd4: font5x7 = 5'b10001;
                        3'd5: font5x7 = 5'b10001;
                        3'd6: font5x7 = 5'b11110;
                    endcase
                end
                8'h43: begin // C
                    case (row)
                        3'd0: font5x7 = 5'b01111;
                        3'd1: font5x7 = 5'b10000;
                        3'd2: font5x7 = 5'b10000;
                        3'd3: font5x7 = 5'b10000;
                        3'd4: font5x7 = 5'b10000;
                        3'd5: font5x7 = 5'b10000;
                        3'd6: font5x7 = 5'b01111;
                    endcase
                end
                8'h44: begin // D
                    case (row)
                        3'd0: font5x7 = 5'b11110;
                        3'd1: font5x7 = 5'b10001;
                        3'd2: font5x7 = 5'b10001;
                        3'd3: font5x7 = 5'b10001;
                        3'd4: font5x7 = 5'b10001;
                        3'd5: font5x7 = 5'b10001;
                        3'd6: font5x7 = 5'b11110;
                    endcase
                end
                8'h45: begin // E
                    case (row)
                        3'd0: font5x7 = 5'b11111;
                        3'd1: font5x7 = 5'b10000;
                        3'd2: font5x7 = 5'b10000;
                        3'd3: font5x7 = 5'b11110;
                        3'd4: font5x7 = 5'b10000;
                        3'd5: font5x7 = 5'b10000;
                        3'd6: font5x7 = 5'b11111;
                    endcase
                end
                8'h46: begin // F
                    case (row)
                        3'd0: font5x7 = 5'b11111;
                        3'd1: font5x7 = 5'b10000;
                        3'd2: font5x7 = 5'b10000;
                        3'd3: font5x7 = 5'b11110;
                        3'd4: font5x7 = 5'b10000;
                        3'd5: font5x7 = 5'b10000;
                        3'd6: font5x7 = 5'b10000;
                    endcase
                end
                8'h48: begin // H
                    case (row)
                        3'd0, 3'd1, 3'd2, 3'd4, 3'd5, 3'd6: font5x7 = 5'b10001;
                        3'd3: font5x7 = 5'b11111;
                    endcase
                end
                8'h49: begin // I
                    case (row)
                        3'd0, 3'd6: font5x7 = 5'b11111;
                        default: font5x7 = 5'b00100;
                    endcase
                end
                8'h4b: begin // K
                    case (row)
                        3'd0: font5x7 = 5'b10001;
                        3'd1: font5x7 = 5'b10010;
                        3'd2: font5x7 = 5'b10100;
                        3'd3: font5x7 = 5'b11000;
                        3'd4: font5x7 = 5'b10100;
                        3'd5: font5x7 = 5'b10010;
                        3'd6: font5x7 = 5'b10001;
                    endcase
                end
                8'h4c: begin // L
                    case (row)
                        3'd0, 3'd1, 3'd2, 3'd3, 3'd4, 3'd5: font5x7 = 5'b10000;
                        3'd6: font5x7 = 5'b11111;
                    endcase
                end
                8'h4d: begin // M
                    case (row)
                        3'd0: font5x7 = 5'b10001;
                        3'd1: font5x7 = 5'b11011;
                        3'd2: font5x7 = 5'b10101;
                        3'd3, 3'd4, 3'd5, 3'd6: font5x7 = 5'b10001;
                    endcase
                end
                8'h4e: begin // N
                    case (row)
                        3'd0: font5x7 = 5'b10001;
                        3'd1: font5x7 = 5'b11001;
                        3'd2: font5x7 = 5'b10101;
                        3'd3: font5x7 = 5'b10011;
                        3'd4, 3'd5, 3'd6: font5x7 = 5'b10001;
                    endcase
                end
                8'h4f: begin // O
                    case (row)
                        3'd0: font5x7 = 5'b01110;
                        3'd1, 3'd2, 3'd3, 3'd4, 3'd5: font5x7 = 5'b10001;
                        3'd6: font5x7 = 5'b01110;
                    endcase
                end
                8'h50: begin // P
                    case (row)
                        3'd0: font5x7 = 5'b11110;
                        3'd1: font5x7 = 5'b10001;
                        3'd2: font5x7 = 5'b10001;
                        3'd3: font5x7 = 5'b11110;
                        3'd4, 3'd5, 3'd6: font5x7 = 5'b10000;
                    endcase
                end
                8'h52: begin // R
                    case (row)
                        3'd0: font5x7 = 5'b11110;
                        3'd1: font5x7 = 5'b10001;
                        3'd2: font5x7 = 5'b10001;
                        3'd3: font5x7 = 5'b11110;
                        3'd4: font5x7 = 5'b10100;
                        3'd5: font5x7 = 5'b10010;
                        3'd6: font5x7 = 5'b10001;
                    endcase
                end
                8'h53: begin // S
                    case (row)
                        3'd0: font5x7 = 5'b01111;
                        3'd1: font5x7 = 5'b10000;
                        3'd2: font5x7 = 5'b10000;
                        3'd3: font5x7 = 5'b01110;
                        3'd4: font5x7 = 5'b00001;
                        3'd5: font5x7 = 5'b00001;
                        3'd6: font5x7 = 5'b11110;
                    endcase
                end
                8'h54: begin // T
                    case (row)
                        3'd0: font5x7 = 5'b11111;
                        default: font5x7 = 5'b00100;
                    endcase
                end
                8'h55: begin // U
                    case (row)
                        3'd0, 3'd1, 3'd2, 3'd3, 3'd4, 3'd5: font5x7 = 5'b10001;
                        3'd6: font5x7 = 5'b01110;
                    endcase
                end
                8'h56: begin // V
                    case (row)
                        3'd0, 3'd1, 3'd2, 3'd3: font5x7 = 5'b10001;
                        3'd4: font5x7 = 5'b10001;
                        3'd5: font5x7 = 5'b01010;
                        3'd6: font5x7 = 5'b00100;
                    endcase
                end
                8'h57: begin // W
                    case (row)
                        3'd0, 3'd1, 3'd2, 3'd3: font5x7 = 5'b10001;
                        3'd4: font5x7 = 5'b10101;
                        3'd5: font5x7 = 5'b11011;
                        3'd6: font5x7 = 5'b10001;
                    endcase
                end
                8'h59: begin // Y
                    case (row)
                        3'd0: font5x7 = 5'b10001;
                        3'd1: font5x7 = 5'b01010;
                        3'd2: font5x7 = 5'b00100;
                        3'd3, 3'd4, 3'd5, 3'd6: font5x7 = 5'b00100;
                    endcase
                end
                8'h5a: begin // Z
                    case (row)
                        3'd0: font5x7 = 5'b11111;
                        3'd1: font5x7 = 5'b00010;
                        3'd2: font5x7 = 5'b00100;
                        3'd3: font5x7 = 5'b01000;
                        3'd4: font5x7 = 5'b10000;
                        3'd5: font5x7 = 5'b10000;
                        3'd6: font5x7 = 5'b11111;
                    endcase
                end
                default: font5x7 = 5'b00000;
            endcase
        end
    endfunction

    wire [11:0] text_x0 = label_x + LABEL_X_MARGIN;
    wire [11:0] text_y0 = label_y + LABEL_Y_MARGIN;
    wire text_region = latch_blob_valid &&
                       (h_cnt >= text_x0) && (h_cnt < (text_x0 + 12'd640)) &&
                       (v_cnt >= text_y0) && (v_cnt < (text_y0 + 12'd14));
    wire [11:0] text_rel_x = h_cnt - text_x0;
    wire [4:0]  text_rel_y = v_cnt - text_y0;
    wire [5:0]  text_idx = text_rel_x[9:4];
    wire [3:0]  text_cell_x = text_rel_x[3:0];
    wire [2:0]  text_col = text_cell_x[3:1];
    wire [2:0]  text_row = text_rel_y[3:1];
    wire [7:0]  text_char = osd_char(text_idx, latch_color, latch_shape, latch_size,
                                      latch_latency_ms, latch_pick_allowed,
                                      latch_center_near_pick);
    wire [4:0]  text_bits = font5x7(text_char, text_row);
    wire [2:0]  text_bit_idx = 3'd4 - text_col;
    wire        text_pixel = text_region &&
                             (text_cell_x < 4'd10) &&
                             (text_rel_y < 5'd14) &&
                             (text_col < 3'd5) &&
                             text_bits[text_bit_idx];

    // 组合叠加层——边界框优先级最高（绿色边框）
    wire is_bbox      = in_bbox;
    wire is_cross     = in_cross;
    wire is_fixed_cross = in_fixed_cross;
    wire is_overlay   = in_label_bg || in_dot1 || in_dot2 || in_dot3 || in_dot4 || in_dot5 ||
                       in_shape_bar || in_size_fill || text_pixel || is_cross || is_fixed_cross;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vs_o <= 1'b0;
            de_o <= 1'b0;
            r_o  <= 8'd0;
            g_o  <= 8'd0;
            b_o  <= 8'd0;
            overlay_active_o <= 1'b0;
        end else begin
            vs_o <= vs_i;
            de_o <= de_i;
            overlay_active_o <= de_i && (is_bbox || is_overlay);
            if (de_i) begin
                // Cyan bounding box (highest priority)
                if (is_bbox) begin
                    r_o <= 8'd0;
                    g_o <= 8'd255;
                    b_o <= 8'd255;
                end else if (is_fixed_cross) begin
                    r_o <= 8'd255;
                    g_o <= 8'd32;
                    b_o <= 8'd32;
                end else if (is_cross) begin
                    r_o <= 8'd255;
                    g_o <= 8'd255;
                    b_o <= 8'd0;
                end else if (is_overlay) begin
                    if (text_pixel) begin
                        r_o <= 8'd255; g_o <= 8'd255; b_o <= 8'd255;
                    end else if (in_dot1 || in_dot2 || in_dot3 || in_dot4 || in_dot5) begin
                        r_o <= dot_r; g_o <= dot_g; b_o <= dot_b;
                    end else if (in_shape_bar) begin
                        r_o <= shape_r; g_o <= shape_g; b_o <= shape_b;
                    end else if (in_size_fill) begin
                        r_o <= 8'd0; g_o <= 8'd255; b_o <= 8'd0;
                    end else if (in_label_bg) begin
                        r_o <= 8'd0; g_o <= 8'd80; b_o <= 8'd220;
                    end else begin
                        r_o <= r_i; g_o <= g_i; b_o <= b_i;
                    end
                end else begin
                    r_o <= r_i; g_o <= g_i; b_o <= b_i;
                end
            end else begin
                r_o <= r_i; g_o <= g_i; b_o <= b_i;
            end
        end
    end

endmodule
