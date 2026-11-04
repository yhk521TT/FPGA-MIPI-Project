// size_from_blob.v - 基于斑块面积的尺寸分类
// 分类：小（1）、中（2）、大（3）
module size_from_blob (
    input  wire        clk,
    input  wire        rst_n,
    // blob input
    input  wire        blob_new,
    input  wire        blob_valid,
    input  wire [19:0] blob_area,
    // size output
    output reg  [1:0]  size_id      // 0=未知，1=小，2=中，3=大
);

    // 960x1080 分辨率的阈值（总像素数为 1,036,800）
    // 小：< 5% = ~51840 像素
    // 中：5%-30% = 51840-311040 像素
    // 大：> 30% = >311040 像素
    localparam AREA_SMALL = 20'd50000;
    localparam AREA_MEDIUM = 20'd300000;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            size_id <= 2'd0;
        end else if (blob_new && blob_valid) begin
            if (blob_area < AREA_SMALL) begin
                size_id <= 2'd1;  // small
            end else if (blob_area < AREA_MEDIUM) begin
                size_id <= 2'd2;  // medium
            end else begin
                size_id <= 2'd3;  // large
            end
        end
        // 如果没有新的斑块，则保留之前的分类
    end

endmodule