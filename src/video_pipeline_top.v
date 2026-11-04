// video_pipeline_top.v - 2-pixel-per-clock vision processing pipeline
// Inserts between debayer output and DSI TX input.
//
// The MIPI path keeps the original 2-pixel cadence. Recognition logic uses one
// averaged sample per 2-pixel word, so it does not drop pixels or alter DE rate.
module video_pipeline_top #(
    parameter HACT = 960,   // active samples per line, where one sample = 2 pixels
    parameter VACT = 1080,
    parameter PICK_CENTER_X = HACT / 2,
    parameter PICK_CENTER_Y = VACT / 2,
    parameter PICK_TOL_X = 80,
    parameter PICK_TOL_Y = 80
)(
    input  wire        clk,
    input  wire        rst_n,
    // input video uses the legacy project bus order. The original comments in
    // top/debayer mark this stream as {B,G,R, B,G,R}; keep display packing
    // unchanged, but remap channels for recognition below.
    input  wire        vs_i,
    input  wire        hs_i,
    input  wire        de_i,
    input  wire [47:0] rgb_datax2_i,
    // output video (to DSI TX)
    output wire        vs_o,
    output wire        hs_o,
    output wire        de_o,
    output wire [47:0] rgb_datax2_o,
    // parallel recognition results
    output wire [2:0]  o_color_id,
    output wire [2:0]  o_shape_id,
    output wire [1:0]  o_size_id,
    output wire        o_pick_allowed,
    // debug output
    output wire [19:0] o_edge_cnt
);

    localparam [10:0] H_CENTER = HACT / 2;
    localparam [10:0] V_CENTER = VACT / 2;
    localparam [10:0] MAX_BLOB_W = (HACT * 3) / 4;
    localparam [10:0] MAX_BLOB_H = (VACT * 3) / 4;
    localparam [19:0] MIN_COLOR_COUNT = 20'd32;
    localparam [19:0] MIN_BLACK_COUNT = 20'd1200;
    localparam [5:0]  ROI_HOLD_FRAMES = 6'd30;
    localparam [1:0]  COLOR_CONFIRM_FRAMES = 2'd2;
    localparam [10:0] PICK_CENTER_X_11 = PICK_CENTER_X;
    localparam [10:0] PICK_CENTER_Y_11 = PICK_CENTER_Y;
    localparam [10:0] PICK_TOL_X_11 = PICK_TOL_X;
    localparam [10:0] PICK_TOL_Y_11 = PICK_TOL_Y;

    //======================================================
    // Unpack two pixels and build one recognition sample.
    // Keep the legacy channel order used by the existing DSI path.
    //======================================================
    wire [7:0] r_bus0 = rgb_datax2_i[7:0];
    wire [7:0] g_bus0 = rgb_datax2_i[15:8];
    wire [7:0] b_bus0 = rgb_datax2_i[23:16];
    wire [7:0] r_bus1 = rgb_datax2_i[31:24];
    wire [7:0] g_bus1 = rgb_datax2_i[39:32];
    wire [7:0] b_bus1 = rgb_datax2_i[47:40];

    // Mild fixed white balance for the demo camera/display path. The board
    // image is visibly green-biased, so reduce G a little and lift R/B.
    wire [8:0] r0_boost = {1'b0, r_bus0} + {4'd0, r_bus0[7:3]};
    wire [8:0] r1_boost = {1'b0, r_bus1} + {4'd0, r_bus1[7:3]};
    wire [8:0] b0_boost = {1'b0, b_bus0} + {5'd0, b_bus0[7:4]};
    wire [8:0] b1_boost = {1'b0, b_bus1} + {5'd0, b_bus1[7:4]};
    wire [7:0] r0_corr = r0_boost[8] ? 8'd255 : r0_boost[7:0];
    wire [7:0] r1_corr = r1_boost[8] ? 8'd255 : r1_boost[7:0];
    wire [7:0] g0_corr = g_bus0 - {3'd0, g_bus0[7:3]};
    wire [7:0] g1_corr = g_bus1 - {3'd0, g_bus1[7:3]};
    wire [7:0] b0_corr = b0_boost[8] ? 8'd255 : b0_boost[7:0];
    wire [7:0] b1_corr = b1_boost[8] ? 8'd255 : b1_boost[7:0];
    wire [47:0] rgb_datax2_corr = {b1_corr, g1_corr, r1_corr,
                                   b0_corr, g0_corr, r0_corr};

    // Recognition channels use actual RGB after BGR bus remap. Do not use the
    // display white-balance boost here; thresholds should see raw camera color.
    wire [8:0] r_sum = {1'b0, r_bus0} + {1'b0, r_bus1};
    wire [8:0] g_sum = {1'b0, g_bus0} + {1'b0, g_bus1};
    wire [8:0] b_sum = {1'b0, b_bus0} + {1'b0, b_bus1};
    wire [7:0] r_avg = r_sum[8:1];
    wire [7:0] g_avg = g_sum[8:1];
    wire [7:0] b_avg = b_sum[8:1];

    wire [15:0] y_r = {8'd0, r_avg} * 8'd77;
    wire [15:0] y_g = {8'd0, g_avg} * 8'd150;
    wire [15:0] y_b = {8'd0, b_avg} * 8'd29;
    wire [17:0] y_sum = {2'd0, y_r} + {2'd0, y_g} + {2'd0, y_b};
    wire [7:0]  gray = y_sum[15:8];

    //======================================================
    // H/V counter in sample coordinates.
    //======================================================
    reg [10:0] h_cnt;
    reg [10:0] v_cnt;
    reg        vs_prev_cnt;

    reg [10:0] h_cnt_d1;
    reg [10:0] v_cnt_d1;
    reg [47:0] rgb_datax2_d1;
    reg [47:0] rgb_datax2_d2;
    reg        hs_d1;
    reg        hs_d2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            h_cnt <= 11'd0;
            v_cnt <= 11'd0;
            vs_prev_cnt <= 1'b0;
            h_cnt_d1 <= 11'd0;
            v_cnt_d1 <= 11'd0;
            rgb_datax2_d1 <= 48'd0;
            rgb_datax2_d2 <= 48'd0;
            hs_d1 <= 1'b0;
            hs_d2 <= 1'b0;
        end else begin
            vs_prev_cnt <= vs_i;

            // One-clock delay aligns with color_recognizer outputs.
            h_cnt_d1 <= h_cnt;
            v_cnt_d1 <= v_cnt;
            rgb_datax2_d1 <= rgb_datax2_corr;
            rgb_datax2_d2 <= rgb_datax2_d1;
            hs_d1 <= hs_i;
            hs_d2 <= hs_d1;

            if (vs_i && !vs_prev_cnt) begin
                h_cnt <= 11'd0;
                v_cnt <= 11'd0;
            end else if (de_i) begin
                if (h_cnt == HACT - 1) begin
                    h_cnt <= 11'd0;
                    if (v_cnt == VACT - 1)
                        v_cnt <= 11'd0;
                    else
                        v_cnt <= v_cnt + 1'b1;
                end else begin
                    h_cnt <= h_cnt + 1'b1;
                end
            end
        end
    end

    //======================================================
    // Motion/object bbox and Sobel edge statistics.
    //======================================================
    wire        vs_obj;
    wire        de_obj;
    wire [7:0]  motion_pixel;
    wire        blob_new;
    wire [10:0] blob_x_min;
    wire [10:0] blob_x_max;
    wire [10:0] blob_y_min;
    wire [10:0] blob_y_max;
    wire [19:0] blob_area;
    wire [10:0] blob_h_cnt;
    wire [10:0] blob_v_cnt;
    wire        blob_valid;
    wire [19:0] motion_pixel_cnt;

    obj_det_core #(
        .H_LINE(HACT),
        .V_LINE(VACT)
    ) u_obj_det (
        .clk              (clk),
        .rst_n            (rst_n),
        .vs_i             (vs_i),
        .de_i             (de_i),
        .gray_in          (gray),
        .vs_o             (vs_obj),
        .de_o             (de_obj),
        .motion_out       (motion_pixel),
        .blob_new         (blob_new),
        .blob_x_min       (blob_x_min),
        .blob_x_max       (blob_x_max),
        .blob_y_min       (blob_y_min),
        .blob_y_max       (blob_y_max),
        .blob_area        (blob_area),
        .blob_h_cnt       (blob_h_cnt),
        .blob_v_cnt       (blob_v_cnt),
        .blob_valid       (blob_valid),
        .ext_h_cnt        (h_cnt),
        .ext_v_cnt        (v_cnt),
        .motion_pixel_cnt (motion_pixel_cnt)
    );

    wire        bg_blob_new;
    wire        bg_blob_valid;
    wire [10:0] bg_blob_x_min;
    wire [10:0] bg_blob_x_max;
    wire [10:0] bg_blob_y_min;
    wire [10:0] bg_blob_y_max;
    wire [19:0] bg_blob_area;
    wire [10:0] bg_blob_center_x;
    wire [10:0] bg_blob_center_y;

    bg_roi_detector #(
        .H_LINE(HACT),
        .V_LINE(VACT),
        .MIN_AREA(20'd600),
        .MIN_W(11'd20),
        .MIN_H(11'd20)
    ) u_bg_roi (
        .clk           (clk),
        .rst_n         (rst_n),
        .vs_i          (vs_i),
        .de_i          (de_i),
        .r_i           (r_avg),
        .g_i           (g_avg),
        .b_i           (b_avg),
        .h_cnt         (h_cnt),
        .v_cnt         (v_cnt),
        .blob_new      (bg_blob_new),
        .blob_valid    (bg_blob_valid),
        .blob_x_min    (bg_blob_x_min),
        .blob_x_max    (bg_blob_x_max),
        .blob_y_min    (bg_blob_y_min),
        .blob_y_max    (bg_blob_y_max),
        .blob_area     (bg_blob_area),
        .blob_center_x (bg_blob_center_x),
        .blob_center_y (bg_blob_center_y)
    );

    wire [10:0] motion_blob_w = blob_x_max - blob_x_min + 1'b1;
    wire [10:0] motion_blob_h = blob_y_max - blob_y_min + 1'b1;
    wire        motion_blob_accept = blob_new && blob_valid &&
                                     (blob_area > 20'd600) &&
                                     (motion_blob_w > 11'd20) &&
                                     (motion_blob_h > 11'd20) &&
                                     (motion_blob_w < MAX_BLOB_W) &&
                                     (motion_blob_h < MAX_BLOB_H);
    wire [10:0] bg_blob_w = bg_blob_x_max - bg_blob_x_min + 1'b1;
    wire [10:0] bg_blob_h = bg_blob_y_max - bg_blob_y_min + 1'b1;
    wire        bg_blob_accept = bg_blob_new && bg_blob_valid &&
                                 (bg_blob_w < MAX_BLOB_W) &&
                                 (bg_blob_h < MAX_BLOB_H);
    wire        use_bg_blob = bg_blob_accept;
    wire        blob_accept = bg_blob_accept || motion_blob_accept;
    wire [10:0] det_blob_x_min = use_bg_blob ? bg_blob_x_min : blob_x_min;
    wire [10:0] det_blob_x_max = use_bg_blob ? bg_blob_x_max : blob_x_max;
    wire [10:0] det_blob_y_min = use_bg_blob ? bg_blob_y_min : blob_y_min;
    wire [10:0] det_blob_y_max = use_bg_blob ? bg_blob_y_max : blob_y_max;
    wire [19:0] det_blob_area  = use_bg_blob ? bg_blob_area  : blob_area;
    wire [10:0] det_blob_center_x = use_bg_blob ? bg_blob_center_x :
                                     (blob_x_min + (motion_blob_w >> 1));
    wire [10:0] det_blob_center_y = use_bg_blob ? bg_blob_center_y :
                                     (blob_y_min + (motion_blob_h >> 1));

    wire [10:0] raw_blob_w = det_blob_x_max - det_blob_x_min + 1'b1;
    wire [10:0] raw_blob_h = det_blob_y_max - det_blob_y_min + 1'b1;

    // For shape/color analysis, use the upper/left object-heavy region of the
    // motion bbox. Hand-held demos often include fingers in the lower/right
    // part of the bbox, which would otherwise dominate shape edges.
    wire [10:0] shape_blob_x_min = det_blob_x_min + (raw_blob_w >> 4);
    wire [10:0] shape_blob_y_min = det_blob_y_min + (raw_blob_h >> 4);
    wire [10:0] shape_blob_x_max = det_blob_x_min + raw_blob_w - (raw_blob_w >> 3);
    wire [10:0] shape_blob_y_max = det_blob_y_min + raw_blob_h - (raw_blob_h >> 2);
    wire [10:0] shape_blob_w = shape_blob_x_max - shape_blob_x_min + 1'b1;
    wire [10:0] shape_blob_h = shape_blob_y_max - shape_blob_y_min + 1'b1;
    wire [19:0] shape_blob_area = shape_blob_w * shape_blob_h;

    wire       vs_edge;
    wire       de_edge;
    wire [7:0] edge_pixel;

    sobel_3x3_edge #(
        .H_LINE(HACT)
    ) u_sobel (
        .clk      (clk),
        .rst_n    (rst_n),
        .vs_i     (vs_i),
        .de_i     (de_i),
        .gray_in  (gray),
        .vs_o     (vs_edge),
        .de_o     (de_edge),
        .edge_out (edge_pixel)
    );

    reg [10:0] edge_h_cnt;
    reg [10:0] edge_v_cnt;
    reg        edge_vs_prev;
    reg [19:0] edge_total_cnt;
    reg [19:0] edge_top_cnt;
    reg [19:0] edge_bottom_cnt;
    reg [19:0] edge_left_cnt;
    reg [19:0] edge_right_cnt;
    reg [19:0] edge_diag_cnt;
    reg [19:0] edge_total_latched;
    reg [19:0] edge_top_latched;
    reg [19:0] edge_bottom_latched;
    reg [19:0] edge_left_latched;
    reg [19:0] edge_right_latched;
    reg [19:0] edge_diag_latched;

    reg        shape_roi_valid;
    reg [10:0] shape_roi_x_min;
    reg [10:0] shape_roi_x_max;
    reg [10:0] shape_roi_y_min;
    reg [10:0] shape_roi_y_max;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shape_roi_valid <= 1'b0;
            shape_roi_x_min <= 11'd0;
            shape_roi_x_max <= 11'd0;
            shape_roi_y_min <= 11'd0;
            shape_roi_y_max <= 11'd0;
        end else if (blob_accept) begin
            shape_roi_valid <= 1'b1;
            shape_roi_x_min <= shape_blob_x_min;
            shape_roi_x_max <= shape_blob_x_max;
            shape_roi_y_min <= shape_blob_y_min;
            shape_roi_y_max <= shape_blob_y_max;
        end
    end

    wire [10:0] shape_roi_w = shape_roi_x_max - shape_roi_x_min + 1'b1;
    wire [10:0] shape_roi_h = shape_roi_y_max - shape_roi_y_min + 1'b1;
    wire [10:0] shape_roi_mid_x = shape_roi_x_min + (shape_roi_w >> 1);
    wire [10:0] shape_roi_mid_y = shape_roi_y_min + (shape_roi_h >> 1);
    wire edge_in_shape_roi = shape_roi_valid &&
                             (edge_h_cnt >= shape_roi_x_min) &&
                             (edge_h_cnt <= shape_roi_x_max) &&
                             (edge_v_cnt >= shape_roi_y_min) &&
                             (edge_v_cnt <= shape_roi_y_max);

    wire edge_valid = de_edge && edge_in_shape_roi && (edge_pixel > 8'd56);
    wire [10:0] edge_x_rel = edge_h_cnt - shape_roi_x_min;
    wire [10:0] edge_y_rel = edge_v_cnt - shape_roi_y_min;
    wire [10:0] edge_diag1_diff = (edge_x_rel > edge_y_rel) ?
                                   (edge_x_rel - edge_y_rel) :
                                   (edge_y_rel - edge_x_rel);
    wire [11:0] edge_diag2_sum = {1'b0, edge_x_rel} + {1'b0, edge_y_rel};
    wire [11:0] edge_diag2_tgt = {1'b0, shape_roi_w};
    wire [11:0] edge_diag2_diff = (edge_diag2_sum > edge_diag2_tgt) ?
                                   (edge_diag2_sum - edge_diag2_tgt) :
                                   (edge_diag2_tgt - edge_diag2_sum);
    wire [11:0] shape_roi_sum = {1'b0, shape_roi_w} + {1'b0, shape_roi_h};
    wire [10:0] edge_diag_tol = shape_roi_sum[11:5] + 11'd12;
    wire edge_near_diag = (edge_diag1_diff < edge_diag_tol) ||
                          (edge_diag2_diff[10:0] < edge_diag_tol);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            edge_h_cnt <= 11'd0;
            edge_v_cnt <= 11'd0;
            edge_vs_prev <= 1'b0;
            edge_total_cnt <= 20'd0;
            edge_top_cnt <= 20'd0;
            edge_bottom_cnt <= 20'd0;
            edge_left_cnt <= 20'd0;
            edge_right_cnt <= 20'd0;
            edge_diag_cnt <= 20'd0;
            edge_total_latched <= 20'd0;
            edge_top_latched <= 20'd0;
            edge_bottom_latched <= 20'd0;
            edge_left_latched <= 20'd0;
            edge_right_latched <= 20'd0;
            edge_diag_latched <= 20'd0;
        end else begin
            edge_vs_prev <= vs_edge;
            if (vs_edge && !edge_vs_prev) begin
                edge_total_latched <= edge_total_cnt;
                edge_top_latched <= edge_top_cnt;
                edge_bottom_latched <= edge_bottom_cnt;
                edge_left_latched <= edge_left_cnt;
                edge_right_latched <= edge_right_cnt;
                edge_diag_latched <= edge_diag_cnt;
                edge_h_cnt <= 11'd0;
                edge_v_cnt <= 11'd0;
                edge_total_cnt <= 20'd0;
                edge_top_cnt <= 20'd0;
                edge_bottom_cnt <= 20'd0;
                edge_left_cnt <= 20'd0;
                edge_right_cnt <= 20'd0;
                edge_diag_cnt <= 20'd0;
            end else if (de_edge) begin
                if (edge_valid) begin
                    edge_total_cnt <= edge_total_cnt + 1'b1;
                    if (edge_v_cnt < shape_roi_mid_y)
                        edge_top_cnt <= edge_top_cnt + 1'b1;
                    else
                        edge_bottom_cnt <= edge_bottom_cnt + 1'b1;
                    if (edge_h_cnt < shape_roi_mid_x)
                        edge_left_cnt <= edge_left_cnt + 1'b1;
                    else
                        edge_right_cnt <= edge_right_cnt + 1'b1;
                    if (edge_near_diag)
                        edge_diag_cnt <= edge_diag_cnt + 1'b1;
                end

                if (edge_h_cnt == HACT - 1) begin
                    edge_h_cnt <= 11'd0;
                    if (edge_v_cnt == VACT - 1)
                        edge_v_cnt <= 11'd0;
                    else
                        edge_v_cnt <= edge_v_cnt + 1'b1;
                end else begin
                    edge_h_cnt <= edge_h_cnt + 1'b1;
                end
            end
        end
    end

    //======================================================
    // One-cycle hardware color classification.
    //======================================================
    wire        vs_color;
    wire        de_color;
    wire [7:0]  r_color;
    wire [7:0]  g_color;
    wire [7:0]  b_color;
    wire [2:0]  color_id;

    color_recognizer u_color (
        .clk      (clk),
        .rst_n    (rst_n),
        .vs_i     (vs_i),
        .de_i     (de_i),
        .r_ch     (r_avg),
        .g_ch     (g_avg),
        .b_ch     (b_avg),
        .vs_o     (vs_color),
        .de_o     (de_color),
        .r_o      (r_color),
        .g_o      (g_color),
        .b_o      (b_color),
        .color_id (color_id)
    );

    reg        roi_valid;
    reg [10:0] roi_x_min;
    reg [10:0] roi_x_max;
    reg [10:0] roi_y_min;
    reg [10:0] roi_y_max;
    reg [5:0]  roi_hold_cnt;
    reg        vs_prev_roi;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            roi_valid <= 1'b0;
            roi_x_min <= 11'd0;
            roi_x_max <= 11'd0;
            roi_y_min <= 11'd0;
            roi_y_max <= 11'd0;
            roi_hold_cnt <= 6'd0;
            vs_prev_roi <= 1'b0;
        end else begin
            vs_prev_roi <= vs_color;
            if (blob_accept) begin
                roi_valid <= 1'b1;
                roi_x_min <= det_blob_x_min;
                roi_x_max <= det_blob_x_max;
                roi_y_min <= det_blob_y_min;
                roi_y_max <= det_blob_y_max;
                roi_hold_cnt <= ROI_HOLD_FRAMES;
            end else if (vs_color && !vs_prev_roi) begin
                if (roi_hold_cnt != 6'd0)
                    roi_hold_cnt <= roi_hold_cnt - 1'b1;
                else
                    roi_valid <= 1'b0;
            end
        end
    end

    wire [10:0] roi_w = roi_x_max - roi_x_min + 1'b1;
    wire [10:0] roi_h = roi_y_max - roi_y_min + 1'b1;
    wire [10:0] roi_sample_x_min = roi_x_min + (roi_w >> 4);
    wire [10:0] roi_sample_x_max = roi_x_min + (roi_w >> 1) + (roi_w >> 2);
    wire [10:0] roi_sample_y_min = roi_y_min + (roi_h >> 4);
    wire [10:0] roi_sample_y_max = roi_y_min + (roi_h >> 1) + (roi_h >> 3);
    wire in_roi = roi_valid &&
                  (h_cnt_d1 >= roi_sample_x_min) && (h_cnt_d1 <= roi_sample_x_max) &&
                  (v_cnt_d1 >= roi_sample_y_min) && (v_cnt_d1 <= roi_sample_y_max);
    wire color_vote_en = de_color && (color_id != 3'd0) &&
                         roi_valid && in_roi;

    reg [19:0] white_cnt;
    reg [19:0] red_cnt;
    reg [19:0] black_cnt;
    reg [19:0] blue_cnt;
    reg [19:0] yellow_cnt;
    reg [2:0]  candidate_color_id;
    reg [1:0]  candidate_color_cnt;
    reg [2:0]  no_color_cnt;
    reg [2:0]  stable_color_id;
    reg        vs_prev_color_vote;

    wire [20:0] non_black_cnt = {1'b0, white_cnt} + {1'b0, red_cnt} +
                                {1'b0, blue_cnt} + {1'b0, yellow_cnt};
    wire        white_winner = (white_cnt > MIN_COLOR_COUNT) &&
                               (white_cnt >= red_cnt) &&
                               (white_cnt >= blue_cnt) &&
                               (white_cnt >= yellow_cnt);
    wire        red_winner = (red_cnt > MIN_COLOR_COUNT) &&
                             (red_cnt >= white_cnt) &&
                             (red_cnt >= blue_cnt) &&
                             (red_cnt >= yellow_cnt);
    wire        blue_winner = (blue_cnt > MIN_COLOR_COUNT) &&
                              (blue_cnt >= white_cnt) &&
                              (blue_cnt >= red_cnt) &&
                              (blue_cnt >= yellow_cnt);
    wire        yellow_winner = (yellow_cnt > MIN_COLOR_COUNT) &&
                                (yellow_cnt >= white_cnt) &&
                                (yellow_cnt >= red_cnt) &&
                                (yellow_cnt >= blue_cnt);
    wire        black_winner = (black_cnt > MIN_BLACK_COUNT) &&
                               (non_black_cnt < 21'd160) &&
                               ({1'b0, black_cnt} > non_black_cnt + (non_black_cnt << 1) + 21'd512);
    wire [2:0]  frame_color_id = red_winner    ? 3'd2 :
                                 yellow_winner ? 3'd5 :
                                 blue_winner   ? 3'd4 :
                                 white_winner  ? 3'd1 :
                                 black_winner  ? 3'd3 : 3'd0;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            white_cnt <= 20'd0;
            red_cnt <= 20'd0;
            black_cnt <= 20'd0;
            blue_cnt <= 20'd0;
            yellow_cnt <= 20'd0;
            candidate_color_id <= 3'd0;
            candidate_color_cnt <= 2'd0;
            no_color_cnt <= 3'd0;
            stable_color_id <= 3'd0;
            vs_prev_color_vote <= 1'b0;
        end else begin
            vs_prev_color_vote <= vs_color;
            if (vs_color && !vs_prev_color_vote) begin
                if (!roi_valid) begin
                    candidate_color_id <= 3'd0;
                    candidate_color_cnt <= 2'd0;
                    no_color_cnt <= 3'd0;
                    stable_color_id <= 3'd0;
                end else if (frame_color_id != 3'd0) begin
                    no_color_cnt <= 3'd0;
                    if (frame_color_id == candidate_color_id) begin
                        if (candidate_color_cnt < COLOR_CONFIRM_FRAMES)
                            candidate_color_cnt <= candidate_color_cnt + 1'b1;
                        if (candidate_color_cnt >= (COLOR_CONFIRM_FRAMES - 1'b1))
                            stable_color_id <= frame_color_id;
                    end else begin
                        candidate_color_id <= frame_color_id;
                        candidate_color_cnt <= 2'd1;
                    end
                end else begin
                    if (no_color_cnt < 3'd7)
                        no_color_cnt <= no_color_cnt + 1'b1;
                    if (no_color_cnt >= 3'd3) begin
                        candidate_color_id <= 3'd0;
                        candidate_color_cnt <= 2'd0;
                        stable_color_id <= 3'd0;
                    end
                end

                white_cnt <= 20'd0;
                red_cnt <= 20'd0;
                black_cnt <= 20'd0;
                blue_cnt <= 20'd0;
                yellow_cnt <= 20'd0;
            end else if (color_vote_en) begin
                case (color_id)
                    3'd1: white_cnt <= white_cnt + 1'b1;
                    3'd2: red_cnt <= red_cnt + 1'b1;
                    3'd3: black_cnt <= black_cnt + 1'b1;
                    3'd4: blue_cnt <= blue_cnt + 1'b1;
                    3'd5: yellow_cnt <= yellow_cnt + 1'b1;
                    default: ;
                endcase
            end
        end
    end

    wire [2:0] display_color_id = stable_color_id;

    //======================================================
    // Shape and size classification.
    //======================================================
    wire [2:0] shape_id;
    wire [1:0] size_id;

    shape_from_blob u_shape (
        .clk           (clk),
        .rst_n         (rst_n),
        .blob_new      (blob_accept),
        .blob_valid    (blob_accept),
        .blob_x_min    (shape_blob_x_min),
        .blob_x_max    (shape_blob_x_max),
        .blob_y_min    (shape_blob_y_min),
        .blob_y_max    (shape_blob_y_max),
        .blob_area     (det_blob_area),
        .blob_h_cnt    (shape_blob_x_min),
        .blob_v_cnt    (shape_blob_y_min),
        .edge_total    (edge_total_latched),
        .edge_top      (edge_top_latched),
        .edge_bottom   (edge_bottom_latched),
        .edge_left     (edge_left_latched),
        .edge_right    (edge_right_latched),
        .edge_diag     (edge_diag_latched),
        .shape_id      (shape_id)
    );

    size_from_blob u_size (
        .clk        (clk),
        .rst_n      (rst_n),
        .blob_new   (blob_accept),
        .blob_valid (blob_accept),
        .blob_area  (det_blob_area),
        .size_id    (size_id)
    );

    reg        latency_active;
    reg        vs_prev_latency;
    reg [3:0]  latency_frame_cnt;
    reg [7:0]  latency_ms;
    wire       result_ready = (display_color_id != 3'd0) &&
                              (shape_id != 3'd0) &&
                              (size_id != 2'd0);
    wire [7:0] latency_frame_ms = {latency_frame_cnt, 4'b0000};
    wire [10:0] pick_center_x = PICK_CENTER_X_11;
    wire [10:0] pick_center_y = PICK_CENTER_Y_11;
    wire [10:0] center_dx = (det_blob_center_x > pick_center_x) ?
                            (det_blob_center_x - pick_center_x) :
                            (pick_center_x - det_blob_center_x);
    wire [10:0] center_dy = (det_blob_center_y > pick_center_y) ?
                            (det_blob_center_y - pick_center_y) :
                            (pick_center_y - det_blob_center_y);
    wire       center_near_pick_calc = (center_dx <= PICK_TOL_X_11) &&
                                       (center_dy <= PICK_TOL_Y_11);
    reg        target_center_near_pick;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            target_center_near_pick <= 1'b0;
        end else if (blob_accept) begin
            target_center_near_pick <= center_near_pick_calc;
        end else if (!roi_valid) begin
            target_center_near_pick <= 1'b0;
        end
    end
    wire       pick_allowed = result_ready && (shape_id == 3'd2) && target_center_near_pick;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            latency_active <= 1'b0;
            vs_prev_latency <= 1'b0;
            latency_frame_cnt <= 4'd0;
            latency_ms <= 8'd0;
        end else begin
            vs_prev_latency <= vs_i;
            if (blob_accept) begin
                latency_active <= 1'b1;
                latency_frame_cnt <= 4'd0;
                latency_ms <= 8'd0;
            end else if (latency_active && result_ready) begin
                latency_active <= 1'b0;
                latency_ms <= latency_frame_ms;
            end else if (latency_active && vs_i && !vs_prev_latency) begin
                if (latency_frame_cnt != 4'd15)
                    latency_frame_cnt <= latency_frame_cnt + 1'b1;
            end
        end
    end

    //======================================================
    // Overlay generator. It computes one overlay color per 2-pixel sample;
    // when active, the same overlay color is applied to both pixels.
    //======================================================
    wire        vs_ov;
    wire        de_ov;
    wire [7:0]  r_ov;
    wire [7:0]  g_ov;
    wire [7:0]  b_ov;
    wire        overlay_active;

    overlay_generator #(
        .HACT(HACT),
        .VACT(VACT)
    ) u_overlay (
        .clk              (clk),
        .rst_n            (rst_n),
        .vs_i             (vs_color),
        .de_i             (de_color),
        .r_i              (r_color),
        .g_i              (g_color),
        .b_i              (b_color),
        .color_id         (display_color_id),
        .shape_id         (shape_id),
        .size_id          (size_id),
        .latency_ms       (latency_ms),
        .pick_allowed     (pick_allowed),
        .center_near_pick (target_center_near_pick),
        .pick_center_x    (pick_center_x),
        .pick_center_y    (pick_center_y),
        .h_cnt            ({1'b0, h_cnt_d1}),
        .v_cnt            ({1'b0, v_cnt_d1}),
        .blob_new         (blob_accept),
        .blob_x_min       (det_blob_x_min),
        .blob_x_max       (det_blob_x_max),
        .blob_y_min       (det_blob_y_min),
        .blob_y_max       (det_blob_y_max),
        .h_blob           (det_blob_center_x),
        .v_blob           (det_blob_center_y),
        .vs_o             (vs_ov),
        .de_o             (de_ov),
        .r_o              (r_ov),
        .g_o              (g_ov),
        .b_o              (b_ov),
        .overlay_active_o (overlay_active)
    );

    assign rgb_datax2_o = overlay_active ?
                          {b_ov, g_ov, r_ov, b_ov, g_ov, r_ov} :
                          rgb_datax2_d2;
    assign vs_o = vs_ov;
    assign hs_o = hs_d2;
    assign de_o = de_ov;

    assign o_color_id = display_color_id;
    assign o_shape_id = shape_id;
    assign o_size_id  = size_id;
    assign o_pick_allowed = pick_allowed;
    assign o_edge_cnt = edge_total_latched;

endmodule
