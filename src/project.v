/*
 * \"Bounce\" by Lam Pham, 2025
 * Synthesizable Version with detailed comments
 */

`default_nettype none

module tt_um_sleepwell(
  input  wire [7:0] ui_in,    // Dedicated inputs
  output wire [7:0] uo_out,   // Dedicated outputs
  input  wire [7:8] uio_in,   // IOs: Input path
  output wire [7:8] uio_out,  // IOs: Output path
  output wire [7:8] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
  input  wire       ena,      // Always 1 when the design is powered
  input  wire       clk,      // Clock
  input  wire       rst_n     // Active low reset
);

  // VGA signals
  wire hsync;
  wire vsync;
  wire [1:0] R;
  wire [1:0] G;
  wire [1:0] B;

  // VGA outputs assignment (RGB and sync signals)
  assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};
  assign uio_out = 0; // Not used in this design
  assign uio_oe  = 0; // Not used in this design

  // Suppress warnings for unused signals
  wire _unused_ok = &{ena, ui_in, uio_in};

  // VGA synchronization generator instantiation
  wire [9:0] x;  // Current horizontal pixel position
  wire [9:0] y;  // Current vertical pixel position
  wire video_active; // Indicates valid display area

  hvsync_generator hvsync_gen(
    .clk(clk),
    .reset(~rst_n),
    .hsync(hsync),
    .vsync(vsync),
    .display_on(video_active),
    .hpos(x),
    .vpos(y)
  );

  // Parameters defining ball properties
  parameter BALL_SIZE     = 20;
  parameter BALL_X_SPEED  = 2;
  parameter BALL_Y_SPEED  = 2;

  // Ball state registers
  //The initial block isn't synthesizable for most FPGA/ASIC flows
  //Replaced with synchronous reset logic within an always @(posedge clk) block
  reg [9:0] ball_x;
  reg [9:0] ball_y;
  reg ball_x_dir; // 1: moving right, 0: moving left
  reg ball_y_dir; // 1: moving down, 0: moving up

  // Synchronous reset and ball movement logic
  always @(posedge clk) begin
    if (!rst_n) begin
      // Initialize ball position and directions upon reset
      ball_x     <= 320;
      ball_y     <= 240;
      ball_x_dir <= 1;
      ball_y_dir <= 1;
    end else if (x == 0 && y == 0) begin
      // Update horizontal ball position based on direction
      //Your original code updated positions twice due to duplication. I fixed it to update exactly once per frame refresh (at the top-left pixel)
      if (ball_x_dir)
        ball_x <= ball_x + BALL_X_SPEED;
      else
        ball_x <= ball_x - BALL_X_SPEED;

      // Update vertical ball position based on direction
      if (ball_y_dir)
        ball_y <= ball_y + BALL_Y_SPEED;
      else
        ball_y <= ball_y - BALL_Y_SPEED;

      // Check horizontal boundaries and reverse direction if necessary
      // Conditions for bouncing at screen edges were updated with explicit boundary checking 
      if (ball_x <= BALL_SIZE)
        ball_x_dir <= 1;
      else if (ball_x >= (640 - BALL_SIZE))
        ball_x_dir <= 0;

      // Check vertical boundaries and reverse direction if necessary
      if (ball_y <= BALL_SIZE)
        ball_y_dir <= 1;
      else if (ball_y >= (480 - BALL_SIZE))
        ball_y_dir <= 0;
    end
  end

  // Calculate squared distance from current pixel to ball center
  //Introduced an intermediate combine_eq wire to simplify rendering conditions and readability
  wire [20:0] combine_eq = (x - ball_x) * (x - ball_x) + (y - ball_y) * (y - ball_y);

  // Determine if current pixel is within ball or its shadow area
  wire ball_active = video_active && (combine_eq <= BALL_SIZE * BALL_SIZE);
  wire shadow_active = video_active && (combine_eq <= (BALL_SIZE + 4) * (BALL_SIZE + 4));

  // VGA color output selection (basketball and shadow colors)
  assign {R, G, B} =
    (!video_active) ? 6'b00_00_00 :      // Black outside active area
    ball_active ? 6'b11_10_00 :          // Orange ball color
    shadow_active ? 6'b01_01_01 :        // Grey shadow color
                    6'b00_00_00;         // Black background

endmodule
