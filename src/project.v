/*
 * "Drop" ASIC audio/visual demo. No CPU, no GPU, no RAM!
 * Racing the beam, straight to VGA 640x480@60Hz.
 * 3456 logic gates, 160 x 220 microns silicon area.
 * Entry to Tiny Tapeout Demoscene 2024 competition:
 *   https://tinytapeout.com/competitions/demoscene/
 *
 * Full version: https://github.com/rejunity/tt08-vga-drop
 * VGA video recording: https://youtu.be/jJBU0J2ceMM
 * Live recording from FPGA: https://youtu.be/rCupc2soGqo
 *
 * Copyright (c) 2024 Renaldas Zioma, Erik Hemming and Matthias Kampa
 * Code is based on the VGA examples by Uri Shaked
 * Inspired by "Memories" 256b demo by Desire
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_sleepwell(
  input  wire [7:0] ui_in,    // Dedicated inputs
  output wire [7:0] uo_out,   // Dedicated outputs
  input  wire [7:0] uio_in,   // IOs: Input path
  output wire [7:0] uio_out,  // IOs: Output path
  output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
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

  // Basketball parameters
  reg [9:0] ball_x = 100; // Ball X position
  reg [9:0] ball_y = 30; // Ball Y position
  reg [4:0] ball_size = 20; // Ball radius
  reg [3:0] ball_x_speed = 2; // Ball X speed
  reg [3:0] ball_y_speed = 2; // Ball Y speed
  reg ball_y_dir = 1; // Ball Y direction (1 for down, 0 for up)

  // Ball movement logic
  always @(posedge clk) begin
    if (~rst_n) begin
      ball_x <= 320;
      ball_y <= 240;
      ball_y_dir <= 1;
    end else begin
      if (x == 0 && y == 0) begin
        // Update ball position
        ball_x <= ball_x + ball_x_speed;
        if (ball_y_dir) begin
          ball_y <= ball_y + ball_y_speed;
        end else begin
          ball_y <= ball_y - ball_y_speed;
        end

        // Check for collision with screen edges
        if (ball_x < ball_size || ball_x >= (500 - ball_size))
          ball_x_speed <= -ball_x_speed;
        if (ball_y < ball_size) begin
          ball_y_dir <= 1;
        end else if (ball_y >= (480 - ball_size)) begin
          ball_y_dir <= 0;
        end
      end
    end
  end

  // Ball display logic
  wire ball_active = video_active && ((x - ball_x) * (x - ball_x) + (y - ball_y) * (y - ball_y) <= ball_size * ball_size);

  // VGA color output for basketball color (orange)
  assign {R, G, B} =
    (~video_active) ? 6'b00_00_00 :
    ball_active ? 6'b11_10_00 :  // Ball color: Orange
                  6'b00_00_00;   // Background color: Black

endmodule
