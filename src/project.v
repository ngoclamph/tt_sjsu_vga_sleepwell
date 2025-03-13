/*
 * "Bounce" by Lam Pham, 2025
 */

`default_nettype none

module tt_um_sleepwell(
  input  wire [7:0] ui_in,    // Dedicated inputs
  output wire [7:0] uo_out,   // Dedicated outputs
  input  wire [7:8] uio_in,   // IOs: Input path
  output wire [7:8] uio_out,  // IOs: Output path
  output wire [7:8] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
  input  wire       ena,      // always 1 when the design is powered, so you can ignore it
  input  wire       clk,      // clock
  input  wire       rst_n     // reset_n - low to reset
);

  // VGA signals
  wire hsync;
  wire vsync;
  wire [1:0] R;
  wire [1:0] G;
  wire [1:0] B;

  // Assign VGA output signals
  assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};
  assign uio_out = 0;
  assign uio_oe  = 0;
  wire _unused_ok = &{ena, ui_in, uio_in};

  // VGA sync signals and coordinates
  wire [9:0] x;
  wire [9:0] y;
  wire video_active;
  hvsync_generator hvsync_gen(
    .clk(clk),
    .reset(~rst_n),
    .hsync(hsync),
    .vsync(vsync),
    .display_on(video_active),
    .hpos(x),
    .vpos(y)
  );

  // Parameters for ball properties
  parameter BALL_SIZE = 20;
  parameter BALL_X_SPEED = 2;
  parameter BALL_Y_SPEED = 2;

  // Ball properties
  reg [9:0] ball_x;
  reg [9:0] ball_y;
  reg signed [9:0] ball_x_speed;
  reg signed [9:0] ball_y_speed;
  reg ball_y_dir;
  reg ball_x_dir;

  // Initialize ball properties
  initial begin
    ball_x = 100;
    ball_y = 30;
    ball_x_speed = BALL_X_SPEED;
    ball_y_speed = BALL_Y_SPEED;
    ball_y_dir = 1;
    ball_x_dir = 1;;

  end

  // Ball movement logic
  always @(posedge clk) begin
    if (~rst_n) begin
      ball_x <= 320;
      ball_y <= 240;
      ball_x_speed <= BALL_X_SPEED;
      ball_y_speed <= BALL_Y_SPEED;
      ball_y_dir <= 1;
      ball_x_dir <= 1;
    end else begin
      if (x == 0 && y == 0) begin
        // Update ball position
        ball_x <= ball_x + ball_x_speed;
        ball_y <= ball_y + ball_y_speed;
        if (ball_x_dir) begin
          ball_x <= ball_x + ball_x_speed;
        end else begin
          ball_x <= ball_x - ball_x_speed;
        end
        if (ball_y_dir) begin
          ball_y <= ball_y + ball_y_speed;
        end else begin
          ball_y <= ball_y - ball_y_speed;
        end
        // Check for collision with screen edges
        if (ball_x < BALL_SIZE) begin
          ball_x_dir <= 1;
        end else if (ball_x >= (640 - BALL_SIZE)) begin
          ball_x_dir <= 0;
        end

        if (ball_y < BALL_SIZE) begin
          ball_y_dir <= 1;
        end else if (ball_y >= (480 - BALL_SIZE)) begin
          ball_y_dir <= 0;
        end
      end
    end
  end

  // Ball display logic
  wire ball_active = video_active && ((x - ball_x) * (x - ball_x) + (y - ball_y) * (y - ball_y) <= BALL_SIZE * BALL_SIZE);

  // VGA color output for basketball color (orange) with a simple shadow effect
  assign {R, G, B} =
    (~video_active) ? 6'b00_00_00 :
    ball_active ? 6'b11_10_00 :                        // Ball color: Orange
                  ((x - ball_x) * (x - ball_x) + (y - ball_y) * (y - ball_y) <= (BALL_SIZE + 4) * (BALL_SIZE + 4)) ? // Shadow effect
                    6'b01_01_01 :                     // Shadow color: Grey
                    6'b00_00_00;                      // Background color: Black

endmodule
