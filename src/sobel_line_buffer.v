// line_buffer.v - Dual-port RAM based line buffer for Sobel 3x3
// Verilog-2005 synthesizable
module sobel_line_buf #(
    parameter DATA_WIDTH = 8,
    parameter H_LINE     = 960
)(
    input  wire                    clk,
    input  wire                    rst_n,
    // write port
    input  wire                    wr_en,
    input  wire [DATA_WIDTH-1:0]   wr_data,
    // read port (read 3 pixels apart for 3x3 window)
    input  wire [9:0]              rd_addr,
    output reg  [DATA_WIDTH-1:0]   rd_data_0,  // current line
    output reg  [DATA_WIDTH-1:0]   rd_data_1,  // 1 line delay
    output reg  [DATA_WIDTH-1:0]   rd_data_2   // 2 lines delay
);

    reg [DATA_WIDTH-1:0] mem0 [0:H_LINE-1];
    reg [DATA_WIDTH-1:0] mem1 [0:H_LINE-1];

    reg [$clog2(H_LINE)-1:0] wr_ptr;

    always @(posedge clk) begin
        if (wr_en) begin
            mem0[wr_ptr] <= wr_data;
        end
    end

    always @(posedge clk) begin
        if (wr_en) begin
            mem1[wr_ptr] <= mem0[wr_ptr];
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            wr_ptr <= 0;
        else if (wr_en) begin
            if (wr_ptr == H_LINE - 1)
                wr_ptr <= 0;
            else
                wr_ptr <= wr_ptr + 1'b1;
        end
    end

    always @(posedge clk) begin
        rd_data_1 <= mem1[rd_addr];
        rd_data_2 <= mem0[rd_addr];
    end

    // rd_data_0 is registered externally (current input pixel)

endmodule
