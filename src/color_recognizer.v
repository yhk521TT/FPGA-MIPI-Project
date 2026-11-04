// color_recognizer.v - Hardware RGB color classifier
// Identifies: White, Red, Black, Blue, Yellow
// Pure Verilog-2005, no initial, single driver
module color_recognizer (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       vs_i,
    input  wire       de_i,
    input  wire [7:0] r_ch,
    input  wire [7:0] g_ch,
    input  wire [7:0] b_ch,
    // pixel passthrough
    output reg        vs_o,
    output reg        de_o,
    output reg  [7:0] r_o,
    output reg  [7:0] g_o,
    output reg  [7:0] b_o,
    // color ID: 0=none, 1=white, 2=red, 3=black, 4=blue, 5=yellow
    output reg  [2:0] color_id
);

    // HSV-like threshold classification (pure combinational, registered output)
    wire [7:0] max_val = (r_ch >= g_ch && r_ch >= b_ch) ? r_ch :
                         (g_ch >= b_ch) ? g_ch : b_ch;
    wire [7:0] min_val = (r_ch <= g_ch && r_ch <= b_ch) ? r_ch :
                         (g_ch <= b_ch) ? g_ch : b_ch;
    wire [7:0] diff    = max_val - min_val;

    // Saturation = (max - min) * 255 / max (approximate with threshold)
    wire sat_high = (diff > 8'd24) && (max_val > 8'd45);
    wire sat_low  = (diff < 8'd65);

    reg [2:0] color_next;

    always @(*) begin
        color_next = 3'd0; // no color
        if ((max_val < 8'd45) && (diff < 8'd30)) begin
            // Very dark and low-saturation -> Black. Dark red/yellow/blue
            // pixels are left as none so shadows do not dominate the vote.
            color_next = 3'd3;
        end else if (sat_low && max_val > 8'd135) begin
            // Low saturation, high brightness -> White
            color_next = 3'd1;
        end else if ((r_ch > 8'd70) &&
                     (r_ch > g_ch + 8'd24) &&
                     (r_ch > b_ch + 8'd28) && sat_high) begin
            // High R, low G/B -> Red
            color_next = 3'd2;
        end else if ((b_ch > 8'd60) &&
                     (b_ch > r_ch + 8'd22) &&
                     (b_ch > g_ch + 8'd6) && sat_high) begin
            // High B, low R/G -> Blue
            color_next = 3'd4;
        end else if ((r_ch > 8'd70) && (g_ch > 8'd65) &&
                     (r_ch > b_ch + 8'd30) &&
                     (g_ch > b_ch + 8'd24) &&
                     (r_ch + 8'd30 > g_ch) &&
                     (g_ch + 8'd50 > r_ch)) begin
            // High R+G, low B -> Yellow
            color_next = 3'd5;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vs_o     <= 1'b0;
            de_o     <= 1'b0;
            r_o      <= 8'd0;
            g_o      <= 8'd0;
            b_o      <= 8'd0;
            color_id <= 3'd0;
        end else begin
            vs_o     <= vs_i;
            de_o     <= de_i;
            r_o      <= r_ch;
            g_o      <= g_ch;
            b_o      <= b_ch;
            color_id <= color_next;
        end
    end

endmodule
