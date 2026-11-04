// robot_cmd_ctrl.v - myCobot 280 UART command sequencer
// UART frame format used by myCobot: FE FE LEN CMD PAYLOAD FA.
// Manual commands are decoded in top.v and passed as 1..7 command IDs here.
module robot_cmd_ctrl #(
    parameter STABLE_FRAMES = 4,
    parameter WAIT_POWER    = 32'd5000000,   // 1.0s @ 5MHz
    parameter WAIT_HOME     = 32'd6000000,   // 1.2s @ 5MHz
    parameter WAIT_MOVE     = 32'd8000000,   // 1.6s @ 5MHz
    parameter WAIT_GRIP     = 32'd3000000,   // 0.6s @ 5MHz
    parameter PICK_X10      = 16'sd1800,     // 180.0 mm
    parameter PICK_Y10      = 16'sd0,
    parameter PICK_Z10      = 16'sd900,      // 90.0 mm
    parameter PICK_RX100    = 16'sd18000,    // 180.00 deg
    parameter PICK_RY100    = 16'sd0,
    parameter PICK_RZ100    = 16'sd0,
    parameter PLACE_X10     = 16'sd2200,     // 220.0 mm
    parameter PLACE_Y10     = 16'sd0,
    parameter PLACE_Z10     = 16'sd1000,     // 100.0 mm
    parameter PLACE_RX100   = 16'sd18000,
    parameter PLACE_RY100   = 16'sd0,
    parameter PLACE_RZ100   = 16'sd0,
    parameter SPEED         = 8'd40,
    parameter GRIPPER_CLOSE = 8'd20,
    parameter GRIPPER_OPEN  = 8'd90,
    parameter GRIPPER_SPEED = 8'd70
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       enable,
    input  wire [2:0] color_id,
    input  wire [2:0] shape_id,
    input  wire [1:0] size_id,
    input  wire       auto_pick_allowed,
    input  wire       manual_mode_en,
    input  wire       manual_cmd_stb,
    input  wire [2:0] manual_cmd,
    input  wire       uart_tx_busy,
    output reg        uart_tx_start,
    output reg [7:0]  uart_tx_data,
    output reg        packet_active
);

    localparam [3:0] CMD_POWER_ON  = 4'd0;
    localparam [3:0] CMD_HOME      = 4'd1;
    localparam [3:0] CMD_PICK      = 4'd2;
    localparam [3:0] CMD_CLOSE     = 4'd3;
    localparam [3:0] CMD_PLACE     = 4'd4;
    localparam [3:0] CMD_OPEN      = 4'd5;
    localparam [3:0] CMD_RUN       = 4'd6;
    localparam [3:0] CMD_STOP      = 4'd7;

    localparam [2:0] SEQ_IDLE      = 3'd0;
    localparam [2:0] SEQ_POWER_ON  = 3'd1;
    localparam [2:0] SEQ_HOME      = 3'd2;
    localparam [2:0] SEQ_PICK      = 3'd3;
    localparam [2:0] SEQ_CLOSE     = 3'd4;
    localparam [2:0] SEQ_PLACE     = 3'd5;
    localparam [2:0] SEQ_OPEN      = 3'd6;
    localparam [2:0] SEQ_MANUAL    = 3'd7;

    reg [2:0] stable_cnt;
    reg [2:0] last_color;
    reg [2:0] last_shape;
    reg [1:0] last_size;
    reg [2:0] seq_state;
    reg [31:0] wait_cnt;
    reg [3:0] action_req;
    reg       action_valid;
    reg       action_taken;
    reg [3:0] action_sent;
    reg       manual_pending_valid;
    reg [3:0] manual_pending_cmd;

    reg [7:0] pkt [0:31];
    reg [5:0] pkt_len;
    reg [5:0] pkt_idx;
    reg       sending;

    wire is_cube = (shape_id == 3'd2);
    wire classified = (color_id != 3'd0) && (shape_id != 3'd0) && (size_id != 2'd0);
    wire pick_candidate = classified && is_cube && auto_pick_allowed;
    wire same_class = (color_id == last_color) && (shape_id == last_shape) && (size_id == last_size);
    wire stable_target = enable && pick_candidate && (stable_cnt >= STABLE_FRAMES[2:0]);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stable_cnt <= 3'd0;
            last_color <= 3'd0;
            last_shape <= 3'd0;
            last_size <= 2'd0;
        end else begin
            last_color <= color_id;
            last_shape <= shape_id;
            last_size <= size_id;
            if (!pick_candidate) begin
                stable_cnt <= 3'd0;
            end else if (same_class) begin
                if (stable_cnt != 3'd7)
                    stable_cnt <= stable_cnt + 1'b1;
            end else begin
                stable_cnt <= 3'd1;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            seq_state <= SEQ_IDLE;
            wait_cnt <= 32'd0;
            action_req <= CMD_POWER_ON;
            action_valid <= 1'b0;
            manual_pending_valid <= 1'b0;
            manual_pending_cmd <= CMD_OPEN;
        end else if (action_taken) begin
            action_valid <= 1'b0;
            case (action_sent)
                CMD_POWER_ON: wait_cnt <= WAIT_POWER;
                CMD_HOME:  wait_cnt <= WAIT_HOME;
                CMD_PICK:  wait_cnt <= WAIT_MOVE;
                CMD_CLOSE: wait_cnt <= WAIT_GRIP;
                CMD_PLACE: wait_cnt <= WAIT_MOVE;
                CMD_OPEN:  wait_cnt <= WAIT_GRIP;
                default:   wait_cnt <= 32'd0;
            endcase
        end else begin
            if (wait_cnt != 32'd0)
                wait_cnt <= wait_cnt - 1'b1;

            if (manual_cmd_stb && (manual_cmd == CMD_STOP)) begin
                seq_state <= SEQ_IDLE;
                wait_cnt <= 32'd0;
                action_valid <= 1'b0;
                manual_pending_valid <= 1'b0;
            end else if (!sending && !action_valid) begin
                if (manual_mode_en && manual_cmd_stb) begin
                    if (manual_cmd == CMD_RUN) begin
                        seq_state <= SEQ_POWER_ON;
                        action_req <= CMD_POWER_ON;
                        action_valid <= 1'b1;
                        manual_pending_valid <= 1'b0;
                    end else if (manual_cmd == CMD_POWER_ON) begin
                        seq_state <= SEQ_IDLE;
                        action_req <= CMD_POWER_ON;
                        action_valid <= 1'b1;
                        manual_pending_valid <= 1'b0;
                    end else begin
                        seq_state <= SEQ_POWER_ON;
                        action_req <= CMD_POWER_ON;
                        action_valid <= 1'b1;
                        manual_pending_valid <= 1'b1;
                        manual_pending_cmd <= manual_cmd;
                    end
                end else if (!manual_mode_en || (seq_state != SEQ_IDLE)) begin
                    case (seq_state)
                        SEQ_IDLE: begin
                            if (!manual_mode_en && stable_target) begin
                                seq_state <= SEQ_POWER_ON;
                                action_req <= CMD_POWER_ON;
                                action_valid <= 1'b1;
                            end
                        end
                        SEQ_POWER_ON: begin
                            if (wait_cnt == 32'd0) begin
                                if (manual_pending_valid) begin
                                    seq_state <= SEQ_MANUAL;
                                    action_req <= manual_pending_cmd;
                                    manual_pending_valid <= 1'b0;
                                end else begin
                                    seq_state <= SEQ_HOME;
                                    action_req <= CMD_HOME;
                                end
                                action_valid <= 1'b1;
                            end
                        end
                        SEQ_MANUAL: begin
                            if (wait_cnt == 32'd0)
                                seq_state <= SEQ_IDLE;
                        end
                        SEQ_HOME: begin
                            if (wait_cnt == 32'd0) begin
                                seq_state <= SEQ_PICK;
                                action_req <= CMD_PICK;
                                action_valid <= 1'b1;
                            end
                        end
                        SEQ_PICK: begin
                            if (wait_cnt == 32'd0) begin
                                seq_state <= SEQ_CLOSE;
                                action_req <= CMD_CLOSE;
                                action_valid <= 1'b1;
                            end
                        end
                        SEQ_CLOSE: begin
                            if (wait_cnt == 32'd0) begin
                                seq_state <= SEQ_PLACE;
                                action_req <= CMD_PLACE;
                                action_valid <= 1'b1;
                            end
                        end
                        SEQ_PLACE: begin
                            if (wait_cnt == 32'd0) begin
                                seq_state <= SEQ_OPEN;
                                action_req <= CMD_OPEN;
                                action_valid <= 1'b1;
                            end
                        end
                        SEQ_OPEN: begin
                            if (wait_cnt == 32'd0)
                                seq_state <= SEQ_IDLE;
                        end
                        default: seq_state <= SEQ_IDLE;
                    endcase
                end
            end
        end
    end

    task build_send_angles;
        begin
            pkt[0]  <= 8'hFE; pkt[1]  <= 8'hFE; pkt[2]  <= 8'h0F; pkt[3]  <= 8'h22;
            pkt[4]  <= 8'h00; pkt[5]  <= 8'h00; pkt[6]  <= 8'h00; pkt[7]  <= 8'h00;
            pkt[8]  <= 8'h00; pkt[9]  <= 8'h00; pkt[10] <= 8'h00; pkt[11] <= 8'h00;
            pkt[12] <= 8'h00; pkt[13] <= 8'h00; pkt[14] <= 8'h00; pkt[15] <= 8'h00;
            pkt[16] <= SPEED; pkt[17] <= 8'hFA; pkt_len <= 6'd18;
        end
    endtask

    task build_power_on;
        begin
            pkt[0] <= 8'hFE; pkt[1] <= 8'hFE; pkt[2] <= 8'h02; pkt[3] <= 8'h10;
            pkt[4] <= 8'hFA; pkt_len <= 6'd5;
        end
    endtask

    task build_send_coords_pick;
        begin
            pkt[0]  <= 8'hFE; pkt[1]  <= 8'hFE; pkt[2]  <= 8'h10; pkt[3]  <= 8'h25;
            pkt[4]  <= PICK_X10[15:8];   pkt[5]  <= PICK_X10[7:0];
            pkt[6]  <= PICK_Y10[15:8];   pkt[7]  <= PICK_Y10[7:0];
            pkt[8]  <= PICK_Z10[15:8];   pkt[9]  <= PICK_Z10[7:0];
            pkt[10] <= PICK_RX100[15:8]; pkt[11] <= PICK_RX100[7:0];
            pkt[12] <= PICK_RY100[15:8]; pkt[13] <= PICK_RY100[7:0];
            pkt[14] <= PICK_RZ100[15:8]; pkt[15] <= PICK_RZ100[7:0];
            pkt[16] <= SPEED; pkt[17] <= 8'h01; pkt[18] <= 8'hFA; pkt_len <= 6'd19;
        end
    endtask

    task build_send_coords_place;
        begin
            pkt[0]  <= 8'hFE; pkt[1]  <= 8'hFE; pkt[2]  <= 8'h10; pkt[3]  <= 8'h25;
            pkt[4]  <= PLACE_X10[15:8];   pkt[5]  <= PLACE_X10[7:0];
            pkt[6]  <= PLACE_Y10[15:8];   pkt[7]  <= PLACE_Y10[7:0];
            pkt[8]  <= PLACE_Z10[15:8];   pkt[9]  <= PLACE_Z10[7:0];
            pkt[10] <= PLACE_RX100[15:8]; pkt[11] <= PLACE_RX100[7:0];
            pkt[12] <= PLACE_RY100[15:8]; pkt[13] <= PLACE_RY100[7:0];
            pkt[14] <= PLACE_RZ100[15:8]; pkt[15] <= PLACE_RZ100[7:0];
            pkt[16] <= SPEED; pkt[17] <= 8'h01; pkt[18] <= 8'hFA; pkt_len <= 6'd19;
        end
    endtask

    task build_gripper;
        input [7:0] value;
        begin
            pkt[0] <= 8'hFE; pkt[1] <= 8'hFE; pkt[2] <= 8'h04; pkt[3] <= 8'h67;
            pkt[4] <= value; pkt[5] <= GRIPPER_SPEED; pkt[6] <= 8'hFA; pkt_len <= 6'd7;
        end
    endtask

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            uart_tx_start <= 1'b0;
            uart_tx_data <= 8'd0;
            packet_active <= 1'b0;
            pkt_idx <= 6'd0;
            pkt_len <= 6'd0;
            sending <= 1'b0;
            action_taken <= 1'b0;
            action_sent <= CMD_POWER_ON;
        end else begin
            uart_tx_start <= 1'b0;
            action_taken <= 1'b0;
            if (!sending && action_valid) begin
                case (action_req)
                    CMD_POWER_ON: build_power_on();
                    CMD_HOME:  build_send_angles();
                    CMD_PICK:  build_send_coords_pick();
                    CMD_CLOSE: build_gripper(GRIPPER_CLOSE);
                    CMD_PLACE: build_send_coords_place();
                    CMD_OPEN:  build_gripper(GRIPPER_OPEN);
                    default:   build_send_angles();
                endcase
                pkt_idx <= 6'd0;
                sending <= 1'b1;
                packet_active <= 1'b1;
                action_sent <= action_req;
            end else if (sending && !uart_tx_busy && !uart_tx_start) begin
                uart_tx_data <= pkt[pkt_idx];
                uart_tx_start <= 1'b1;
                if (pkt_idx == pkt_len - 1'b1) begin
                    sending <= 1'b0;
                    packet_active <= 1'b0;
                    pkt_idx <= 6'd0;
                    action_taken <= 1'b1;
                end else begin
                    pkt_idx <= pkt_idx + 1'b1;
                end
            end
        end
    end

endmodule
