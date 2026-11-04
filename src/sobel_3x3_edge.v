// sobel_3x3_edge.v - Sobel 3x3 edge detection with line buffers
// Pure Verilog-2005, no initial, no multi-driver
// Input: grayscale [7:0], Output: edge magnitude [7:0], pipeline delay = 3 lines + 3 clocks
module sobel_3x3_edge #(
    parameter H_LINE = 960
)(
    input  wire        clk,
    input  wire        rst_n,
    // input interface
    input  wire        vs_i,
    input  wire        de_i,
    input  wire [7:0]  gray_in,
    // output interface (aligned with input after pipeline)
    output wire        vs_o,
    output wire        de_o,
    output wire [7:0]  edge_out
);

    //--- 1. Extract grayscale from RGB: Y = (R*77 + G*150 + B*29) >> 8
    reg        vs_d, de_d;
    reg [7:0]  gray_d;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vs_d   <= 1'b0;
            de_d   <= 1'b0;
            gray_d <= 8'd0;
        end else begin
            vs_d   <= vs_i;
            de_d   <= de_i;
            gray_d <= gray_in;
        end
    end

    //--- 2. Line buffers for 3-line window
    wire [7:0] lb_row1, lb_row2;
    reg  [7:0] lb_row0_pipe;

    wire [$clog2(H_LINE)-1:0] rd_addr;
    reg  [$clog2(H_LINE)-1:0] wr_cnt;

    reg line_de_d;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            wr_cnt <= 0;
        else if (de_d) begin
            if (wr_cnt == H_LINE - 1)
                wr_cnt <= 0;
            else
                wr_cnt <= wr_cnt + 1'b1;
        end
    end

    reg line_buf_wr_en;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            line_buf_wr_en <= 0;
        else
            line_buf_wr_en <= de_d;
    end

    // Line buffer instance - shifts: row0 (newest), row1 (1 line ago), row2 (2 lines ago)
    sobel_line_buf #(
        .DATA_WIDTH(8),
        .H_LINE(H_LINE)
    ) u_line_buf (
        .clk       (clk),
        .rst_n     (rst_n),
        .wr_en     (line_buf_wr_en),
        .wr_data   (gray_d),
        .rd_addr   (rd_addr),
        .rd_data_0 (),          // unused direct read
        .rd_data_1 (lb_row1),   // 1 line delay
        .rd_data_2 (lb_row2)    // 2 line delay
    );

    // Read address = write address minus 1 (read previous column for kernel)
    assign rd_addr = (wr_cnt == 0) ? (H_LINE - 1) : (wr_cnt - 1'b1);

    //--- 3. 3x3 pixel window register (3 pipeline stages)
    // Row from line buffer arrives with 1 clock delay
    reg [7:0] r00, r01, r02;  // row 0 (oldest, 2 lines ago) -> from lb_row2 delayed
    reg [7:0] r10, r11, r12;  // row 1 (1 line ago) -> from lb_row1 delayed
    reg [7:0] r20, r21, r22;  // row 2 (newest) -> current input

    reg [2:0] de_pipe;
    reg [2:0] vs_pipe;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            {r00, r01, r02} <= 24'd0;
            {r10, r11, r12} <= 24'd0;
            {r20, r21, r22} <= 24'd0;
            de_pipe <= 3'd0;
            vs_pipe <= 3'd0;
        end else begin
            // Shift register chain
            r02 <= lb_row2;  r01 <= r02;  r00 <= r01;
            r12 <= lb_row1;  r11 <= r12;  r10 <= r11;
            r22 <= gray_d;   r21 <= r22;  r20 <= r21;

            de_pipe <= {de_pipe[1:0], de_d};
            vs_pipe <= {vs_pipe[1:0], vs_d};
        end
    end

    //--- 4. Sobel computation (pipeline stage 1: gradient)
    // Gx = (-r00 + r02) + (-2*r10 + 2*r12) + (-r20 + r22)
    // Gy = (-r00 - 2*r01 - r02) + (r20 + 2*r21 + r22)
    wire signed [11:0] gx = -{4'd0,r00} + {4'd0,r02}
                            - {3'd0,r10,1'b0} + {3'd0,r12,1'b0}
                            - {4'd0,r20} + {4'd0,r22};

    wire signed [11:0] gy = -{4'd0,r00} - {3'd0,r01,1'b0} - {4'd0,r02}
                            + {4'd0,r20} + {3'd0,r21,1'b0} + {4'd0,r22};

    wire [11:0] gx_abs = gx[11] ? (~gx + 12'd1) : gx;
    wire [11:0] gy_abs = gy[11] ? (~gy + 12'd1) : gy;
    wire [12:0] grad_sum = {1'b0, gx_abs} + {1'b0, gy_abs};

    // Clamp to 8 bits
    reg [7:0] edge_mag;
    reg       de_pipe2;
    reg       vs_pipe2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            edge_mag  <= 8'd0;
            de_pipe2  <= 1'b0;
            vs_pipe2  <= 1'b0;
        end else begin
            edge_mag  <= (|grad_sum[12:8]) ? 8'd255 : grad_sum[7:0];
            de_pipe2  <= de_pipe[2];
            vs_pipe2  <= vs_pipe[2];
        end
    end

    assign vs_o   = vs_pipe2;
    assign de_o   = de_pipe2;
    assign edge_out = edge_mag;

endmodule
