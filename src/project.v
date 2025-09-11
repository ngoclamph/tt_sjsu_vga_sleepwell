/*
 * \"Sleepwell\" by Lam Pham, 2025
 * Synthesizable Version with detailed comments
 */

`default_nettype none
`include "hvsync_generator.v"
module tt_um_sleepwell(
  input  wire [7:0] ui_in,    // Dedicated inputs
  output wire [7:0] uo_out,   // Dedicated outputs
  input  wire [7:0] uio_in,   // IOs: Input path
  output wire [7:0] uio_out,  // IOs: Output path
  output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
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
  // Zero-extend the 10-bit positions to 21 bits to avoid signed math and warnings
wire [20:0] combine_eq = ( {11'b0, x} - {11'b0, ball_x} ) * ( {11'b0, x} - {11'b0, ball_x} ) +
                         ( {11'b0, y} - {11'b0, ball_y} ) * ( {11'b0, y} - {11'b0, ball_y} );
  // Determine if current pixel is within ball or its shadow area
  wire ball_active = video_active && (combine_eq <= BALL_SIZE * BALL_SIZE);
  wire shadow_active = video_active && (combine_eq <= (BALL_SIZE + 4) * (BALL_SIZE + 4));

  // SJSU Text Display Parameters
  parameter LETTER_WIDTH = 30;
  parameter LETTER_HEIGHT = 50;
  parameter LETTER_COLOR = 6'b11_11_00; // Yellow letters
  parameter BG_COLOR = 6'b00_00_10; // Darker blue 
  
  // Letter positions (centered)
  localparam S1_X = 184;
  localparam J_X  = 253;
  localparam S2_X = 322;
  localparam U_X  = 391;
  localparam LETTER_Y = 220;

  // Letter ROM (simplified patterns)
  reg [29:0] letter_rom [0:199];
  initial begin
    // Letter S (first)
    letter_rom[0]   = 30'b000001111111111111111111100000;
    letter_rom[1]   = 30'b000011111111111111111111110000;
    letter_rom[2]   = 30'b000111111000000000000001111000;
    letter_rom[3]   = 30'b000111100000000000000000111000;
    letter_rom[4]   = 30'b000111000000000000000000011100;
    letter_rom[5]   = 30'b000111000000000000000000011100;
    letter_rom[6]   = 30'b000000000000000000000000011100;
    letter_rom[7]   = 30'b000000000000000000000000011100;
    letter_rom[8]   = 30'b000000000000000000000000111100;
    letter_rom[9]   = 30'b000000011111111111111111111000;
    letter_rom[10]  = 30'b000001111111111111111111110000;
    letter_rom[11]  = 30'b000011111111111111111111100000;
    letter_rom[12]  = 30'b000111110000000000000000000000;
    letter_rom[13]  = 30'b000111100000000000000000000000;
    letter_rom[14]  = 30'b000111000000000000000000000000;
    letter_rom[15]  = 30'b000111000000000000000000011100;
    letter_rom[16]  = 30'b000111000000000000000000011100;
    letter_rom[17]  = 30'b000111100000000000000000111000;
    letter_rom[18]  = 30'b000111111000000000000001111000;
    letter_rom[19]  = 30'b000011111111111111111111110000;
    letter_rom[20]  = 30'b000001111111111111111111100000;
    // ... (fill all 50 rows for S)
    letter_rom[21]  = 0;
    letter_rom[22]  = 0;
    letter_rom[23]  = 0;
    letter_rom[24]  = 0;
    letter_rom[25]  = 0;
    letter_rom[26]  = 0;
    letter_rom[27]  = 0;
    letter_rom[28]  = 0;
    letter_rom[29]  = 0;
    letter_rom[30]  = 0;
    letter_rom[31]  = 0;
    letter_rom[32]  = 0;
    letter_rom[33]  = 0;
    letter_rom[34]  = 0;
    letter_rom[35]  = 0;
    letter_rom[36]  = 0;
    letter_rom[37]  = 0;
    letter_rom[38]  = 0;
    letter_rom[39]  = 0;
    letter_rom[40]  = 0;
    letter_rom[41]  = 0;
    letter_rom[42]  = 0;
    letter_rom[43]  = 0;
    letter_rom[44]  = 0;
    letter_rom[45]  = 0;
    letter_rom[46]  = 0;
    letter_rom[47]  = 0;
    letter_rom[48]  = 0;
    letter_rom[49]  = 0;

    // Letter J
    letter_rom[50]  = 30'b000000000000000000000000000000;
    letter_rom[51]  = 30'b000000000000000000000000000000;
    letter_rom[52]  = 30'b000000000000000000000000000000;
    letter_rom[53]  = 30'b000000000000000000000000000000;
    letter_rom[54]  = 30'b000111000000000000000000000000;
    letter_rom[55]  = 30'b000111000000000000000000000000;
    letter_rom[56]  = 30'b000111000000000000000000000000;
    letter_rom[57]  = 30'b000111000000000000000000000000;
    letter_rom[58]  = 30'b000111000000000000000000000000;
    letter_rom[59]  = 30'b000111000000000000000000000000;
    letter_rom[60]  = 30'b000111000000000000000000000000;
    letter_rom[61]  = 30'b000111000000000000000000000000;
    letter_rom[62]  = 30'b000111000000000000000000000000;
    letter_rom[63]  = 30'b000111000000000000000000000000;
    letter_rom[64]  = 30'b000111000000000000000000000000;
    letter_rom[65]  = 30'b000111000000000000000000011100;
    letter_rom[66]  = 30'b000111000000000000000000011100;
    letter_rom[67]  = 30'b000111100000000000000000111000;
    letter_rom[68]  = 30'b000011111111111111111111110000;
    letter_rom[69]  = 30'b000001111111111111111111100000;
    // ... (fill all 50 rows for J)
    letter_rom[70]  = 0;
    letter_rom[71]  = 0;
    letter_rom[72]  = 0;
    letter_rom[73]  = 0;
    letter_rom[74]  = 0;
    letter_rom[75]  = 0;
    letter_rom[76]  = 0;
    letter_rom[77]  = 0;
    letter_rom[78]  = 0;
    letter_rom[79] = 0;
    letter_rom[80] = 0;
    letter_rom[81] = 0;
    letter_rom[82] = 0;
    letter_rom[83] = 0;
    letter_rom[84] = 0;
    letter_rom[85] = 0;
    letter_rom[86] = 0;
    letter_rom[87] = 0;
    letter_rom[88] = 0;
    letter_rom[89] = 0;
    letter_rom[90] = 0;
    letter_rom[91] = 0;
    letter_rom[92] = 0;
    letter_rom[93] = 0;
    letter_rom[94] = 0;
    letter_rom[95] = 0;
    letter_rom[96] = 0;
    letter_rom[97] = 0;
    letter_rom[98] = 0;
    letter_rom[99] = 0;

    // Letter S (second) - same as first S
    for (int i=0; i<50; i=i+1) letter_rom[100+i] = letter_rom[i];
    
    // Letter U
    letter_rom[150] = 30'b000111000000000000000000111000;
    letter_rom[151] = 30'b000111000000000000000000111000;
    letter_rom[152] = 30'b000111000000000000000000111000;
    letter_rom[153] = 30'b000111000000000000000000111000;
    letter_rom[154] = 30'b000111000000000000000000111000;
    letter_rom[155] = 30'b000111000000000000000000111000;
    letter_rom[156] = 30'b000111000000000000000000111000;
    letter_rom[157] = 30'b000111000000000000000000111000;
    letter_rom[158] = 30'b000111000000000000000000111000;
    letter_rom[159] = 30'b000111000000000000000000111000;
    letter_rom[160] = 30'b000111000000000000000000111000;
    letter_rom[161] = 30'b000111000000000000000000111000;
    letter_rom[162] = 30'b000111000000000000000000111000;
    letter_rom[163] = 30'b000111000000000000000000111000;
    letter_rom[164] = 30'b000111000000000000000000111000;
    letter_rom[165] = 30'b000111100000000000000001111000;
    letter_rom[166] = 30'b000011111111111111111111110000;
    letter_rom[167] = 30'b000001111111111111111111100000;
    // ... (fill all 50 rows for U)
    letter_rom[168] = 0;
    letter_rom[169] = 0;
    letter_rom[170] = 0;
    letter_rom[171] = 0;
    letter_rom[172] = 0;
    letter_rom[173] = 0;
    letter_rom[174] = 0;
    letter_rom[175] = 0;
    letter_rom[176] = 0;
    letter_rom[177] = 0;
    letter_rom[178] = 0;
    letter_rom[179] = 0;
    letter_rom[180] = 0;
    letter_rom[181] = 0;
    letter_rom[182] = 0;
    letter_rom[183] = 0;
    letter_rom[184] = 0;
    letter_rom[185] = 0;
    letter_rom[186] = 0;
    letter_rom[187] = 0;
    letter_rom[188] = 0;
    letter_rom[189] = 0;
    letter_rom[190] = 0;
    letter_rom[191] = 0;
    letter_rom[192] = 0;
    letter_rom[193] = 0;
    letter_rom[194] = 0;
    letter_rom[195] = 0;
    letter_rom[196] = 0;
    letter_rom[197] = 0;
    letter_rom[198] = 0;
    letter_rom[199] = 0;

  end

// Letter rendering
wire in_s1 = (x >= S1_X) && (x < S1_X + LETTER_WIDTH) && 
             (y >= LETTER_Y) && (y < LETTER_Y + LETTER_HEIGHT);
wire in_j  = (x >= J_X)  && (x < J_X + LETTER_WIDTH) && 
             (y >= LETTER_Y) && (y < LETTER_Y + LETTER_HEIGHT);
wire in_s2 = (x >= S2_X) && (x < S2_X + LETTER_WIDTH) && 
             (y >= LETTER_Y) && (y < LETTER_Y + LETTER_HEIGHT);
wire in_u  = (x >= U_X)  && (x < U_X + LETTER_WIDTH) && 
             (y >= LETTER_Y) && (y < LETTER_Y + LETTER_HEIGHT);

// Calculate the full, 10-bit column offset
wire [9:0] pixel_col_full = x - (in_s1 ? S1_X :
                            in_j  ? J_X  :
                            in_s2 ? S2_X :
                                    U_X);

// The ROM address needs 8 bits to hold values from 0 to 199.
// Use 8-bit constants (like 8'd50) to keep the addition within 8 bits.
// The conditionals (in_s1, etc.) ensure y-LETTER_Y is always <= 49, so
// (y-LETTER_Y) + 8'd150 will never exceed 199, which fits in 8 bits.
wire [7:0] rom_addr = 
    in_s1 ? (y - LETTER_Y) :               // Range: 0 to 49
    in_j  ? (y - LETTER_Y) + 8'd50 :       // Range: 50 to 99
    in_s2 ? (y - LETTER_Y) + 8'd100 :      // Range: 100 to 149
            (y - LETTER_Y) + 8'd150;       // Range: 150 to 199

// The final column index for the ROM is just the lower 5 bits of the full calculation
wire [4:0] pixel_col = pixel_col_full[4:0];

wire letter_pixel = (in_s1 || in_j || in_s2 || in_u) ? 
                   letter_rom[rom_addr][pixel_col] : 1'b0;

  // Final output with priority: Ball > Shadow > Text > Background
  assign {R, G, B} =
    (!video_active) ? 6'b00_00_00 :      // Black outside active area
    ball_active    ? 6'b11_10_00 :       // Orange ball (highest priority)
    shadow_active  ? 6'b01_01_01 :       // Grey shadow
    letter_pixel   ? LETTER_COLOR :      // Yellow text
                     BG_COLOR;          // Blue background

endmodule
