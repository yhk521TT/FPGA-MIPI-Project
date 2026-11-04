// shape_from_blob.v - 基于斑块特征的形状识别
// 分类：圆柱体 (1)、立方体 (2)、三角锥 (3)
module shape_from_blob (
    input  wire        clk,
    input  wire        rst_n,
    // blob 输入（来自 obj_det_core）
    input  wire        blob_new,
    input  wire        blob_valid,
    input  wire [10:0] blob_x_min,
    input  wire [10:0] blob_x_max,
    input  wire [10:0] blob_y_min,
    input  wire [10:0] blob_y_max,
    input  wire [19:0] blob_area,
    input  wire [10:0] blob_h_cnt,
    input  wire [10:0] blob_v_cnt,
    // 上一帧/当前帧的边缘统计数据
    input  wire [19:0] edge_total,
    input  wire [19:0] edge_top,
    input  wire [19:0] edge_bottom,
    input  wire [19:0] edge_left,
    input  wire [19:0] edge_right,
    input  wire [19:0] edge_diag,
    // shape output
    output reg  [2:0]   shape_id      // 0=none, 1=cylinder, 2=cube, 3=triangular_pyramid
);

    // Compute blob dimensions
    wire [10:0] blob_w = blob_x_max - blob_x_min + 1'b1;
    wire [10:0] blob_h = blob_y_max - blob_y_min + 1'b1;
    // Aspect and edge checks without division.
    wire [12:0] blob_w_x4 = {blob_w, 2'b00};
    wire [12:0] blob_h_x4 = {blob_h, 2'b00};
    wire [12:0] blob_w_x3 = {1'b0, blob_w} + {1'b0, blob_w, 1'b0};
    wire [12:0] blob_h_x3 = {1'b0, blob_h} + {1'b0, blob_h, 1'b0};
    wire [13:0] blob_w_x2 = {2'd0, blob_w, 1'b0};
    wire [13:0] blob_h_x2 = {2'd0, blob_h, 1'b0};
    wire [21:0] bbox_area = blob_w * blob_h;
    wire [25:0] fill_x16 = {2'd0, blob_area, 4'b0000};
    wire [25:0] bbox_x7 = {4'd0, bbox_area} + {3'd0, bbox_area, 1'b0} +
                           {2'd0, bbox_area, 2'b00};
    wire [25:0] bbox_x5 = {4'd0, bbox_area} + {2'd0, bbox_area, 2'b00};

    wire wider_than_tall = (blob_w > blob_h + (blob_h >> 3));
    wire taller_than_wide = (blob_h > blob_w + (blob_w >> 3));
    wire roughly_square = (blob_w_x4 > blob_h_x3) && (blob_h_x4 > blob_w_x3);
    wire elongated = (blob_w_x2 > {1'b0, blob_h_x3}) ||
                     (blob_h_x2 > {1'b0, blob_w_x3});
    wire fill_high = (fill_x16 > bbox_x7); // foreground > about 44% of bbox
    wire fill_low = (fill_x16 < bbox_x5);  // foreground < about 31% of bbox

    wire lr_balanced = (edge_left > edge_right) ?
                       ((edge_left - edge_right) < (edge_total >> 3) + 20'd64) :
                       ((edge_right - edge_left) < (edge_total >> 3) + 20'd64);
    wire tb_balanced = (edge_top > edge_bottom) ?
                       ((edge_top - edge_bottom) < (edge_total >> 3) + 20'd64) :
                       ((edge_bottom - edge_top) < (edge_total >> 3) + 20'd64);
    wire edge_enough = (edge_total > 20'd24);
    wire diag_rich = edge_enough && (edge_diag > (edge_total >> 3) + (edge_total >> 4) + 20'd8);
    wire diag_very_rich = edge_enough && (edge_diag > (edge_total >> 2) + 20'd8);
    wire top_heavy = (edge_top > edge_bottom + (edge_total >> 4) + 20'd32);

    // Thresholds
    localparam AREA_SMALL = 20'd2500;
    localparam [1:0] SHAPE_CONFIRM_FRAMES = 2'd2;

    reg [2:0] shape_next;
    reg [2:0] candidate_shape_id;
    reg [1:0] candidate_shape_cnt;

    always @(*) begin
        if (blob_area < AREA_SMALL) begin
            // Too small to classify reliably
            shape_next = 3'd0;
        end else if ((diag_very_rich && !roughly_square) ||
                     (diag_rich && top_heavy && (wider_than_tall || taller_than_wide))) begin
            // Diagonal/top-heavy edge distribution -> triangular pyramid
            shape_next = 3'd3;
        end else if (roughly_square && fill_high && lr_balanced && tb_balanced) begin
            // Cube/square block: compact bbox, high fill, balanced edges.
            shape_next = 3'd2;
        end else if (elongated || fill_low ||
                     (lr_balanced && (wider_than_tall || taller_than_wide || !tb_balanced))) begin
            // Rounded/cylindrical objects tend to keep left/right balance.
            shape_next = 3'd1;
        end else if (roughly_square) begin
            // Keep square-like solids as cube when the stricter checks are marginal.
            shape_next = 3'd2;
        end else begin
            shape_next = 3'd2;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shape_id <= 3'd0;
            candidate_shape_id <= 3'd0;
            candidate_shape_cnt <= 2'd0;
        end else if (blob_new && blob_valid) begin
            if (shape_next == 3'd0) begin
                candidate_shape_id <= 3'd0;
                candidate_shape_cnt <= 2'd0;
            end else if (shape_next == candidate_shape_id) begin
                if (candidate_shape_cnt < SHAPE_CONFIRM_FRAMES)
                    candidate_shape_cnt <= candidate_shape_cnt + 1'b1;
                if (candidate_shape_cnt >= (SHAPE_CONFIRM_FRAMES - 1'b1))
                    shape_id <= shape_next;
            end else begin
                candidate_shape_id <= shape_next;
                candidate_shape_cnt <= 2'd1;
            end
        end
        // If no new blob, keep previous classification
    end

endmodule
