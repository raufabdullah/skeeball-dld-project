`timescale 1ns / 1ps

module pixel_gen_endscreen(
    input clk_d, // pixel clock
    input [9:0] pixel_x,
    input [9:0] pixel_y,
    input video_on,
    input [16:0] score,
    output reg [3:0] red = 0,
    output reg [3:0] green = 0,
    output reg [3:0] blue = 0
);

wire [3:0] score_ten_thousands, score_thousands, score_hundreds, score_tens, score_ones;
assign score_ten_thousands = score / 10000;
assign score_thousands = (score % 10000) / 1000;
assign score_hundreds = (score % 1000) / 100;
assign score_tens = (score % 100) / 10;
assign score_ones = score % 10;

// Blink control for "TIME'S UP!"
reg [25:0] blink_counter = 0;
reg blink = 1;
localparam ON_TIME = 26'd18_750_000;  // 0.75 s at 25 MHz
localparam TOTAL_CYCLE = 26'd31_250_000;  // 1.25 s at 25 MHz

// Color cycling control for score digits
reg [27:0] color_counter = 0;
reg [3:0] digit_red, digit_green, digit_blue;
localparam COLOR_CYCLE = 28'd125_000_000; // 5 s at 25 MHz
localparam PHASE_STEP = 28'd488_281;      // 125,000,000 / 256 for 256 hue steps

// Blink counter logic
always @(posedge clk_d) begin
    if (blink_counter < TOTAL_CYCLE - 1) begin
        blink_counter <= blink_counter + 1;
        if (blink_counter < ON_TIME) begin
            blink <= 1;  // Text on for 0.75 s
        end else begin
            blink <= 0;  // Text off for 0.5 s
        end
    end else begin
        blink_counter <= 0;
        blink <= 1;  // Restart cycle with text on
    end
end

// Color cycling logic
reg [7:0] hue;
always @(posedge clk_d) begin
    if (color_counter < COLOR_CYCLE - 1) begin
        color_counter <= color_counter + 1;
    end else begin
        color_counter <= 0;
    end

    // Compute hue step (0 to 255) for smooth spectrum
    
    hue = color_counter / PHASE_STEP;
    // Smooth RGB spectrum transition (red -> orange -> yellow -> green -> cyan -> blue -> magenta -> red)
    if (hue < 8'd43) begin
        // Red (F,0,0) to Orange/Yellow (F,F,0)
        digit_red <= 4'hF;
        digit_green <= (hue * 6) / 16; // Scale 0-42 to 0-F
        digit_blue <= 4'h0;
    end else if (hue < 8'd85) begin
        // Yellow (F,F,0) to Green (0,F,0)
        digit_red <= 4'hF - (((hue - 8'd43) * 6) / 16);
        digit_green <= 4'hF;
        digit_blue <= 4'h0;
    end else if (hue < 8'd128) begin
        // Green (0,F,0) to Cyan (0,F,F)
        digit_red <= 4'h0;
        digit_green <= 4'hF;
        digit_blue <= ((hue - 8'd85) * 6) / 16;
    end else if (hue < 8'd170) begin
        // Cyan (0,F,F) to Blue (0,0,F)
        digit_red <= 4'h0;
        digit_green <= 4'hF - (((hue - 8'd128) * 6) / 16);
        digit_blue <= 4'hF;
    end else if (hue < 8'd213) begin
        // Blue (0,0,F) to Magenta/Purple (F,0,F)
        digit_red <= ((hue - 8'd170) * 6) / 16;
        digit_green <= 4'h0;
        digit_blue <= 4'hF;
    end else begin
        // Magenta (F,0,F) to Red (F,0,0)
        digit_red <= 4'hF;
        digit_green <= 4'h0;
        digit_blue <= 4'hF - (((hue - 8'd213) * 6) / 16);
    end
end

always @(posedge clk_d) begin
    if (video_on) begin
        // Default: White background (#ffffff)
        red <= 4'hF;
        green <= 4'hF;
        blue <= 4'hF;
        
        // Red text for "TIME'S UP!" at top, centered (x=80 to 559, y=50 to 119)
        if (blink && (
            // T (x=100 to 140)
            (pixel_x >= 100 && pixel_x <= 139 && pixel_y >= 50 && pixel_y <= 59) || // top
            (pixel_x >= 115 && pixel_x <= 124 && pixel_y >= 60 && pixel_y <= 119) || // vertical
            // I (x=150 to 190)
            (pixel_x >= 150 && pixel_x <= 179 && pixel_y >= 50 && pixel_y <= 59) || // top
            (pixel_x >= 160 && pixel_x <= 169 && pixel_y >= 60 && pixel_y <= 109) || // vertical
            (pixel_x >= 150 && pixel_x <= 179 && pixel_y >= 110 && pixel_y <= 119) || // bottom
            // M (x=200 to 240)
            (pixel_x >= 190 && pixel_x <= 199 && pixel_y >= 50 && pixel_y <= 119) || // left
            (pixel_x >= 230 && pixel_x <= 239 && pixel_y >= 50 && pixel_y <= 119) || // right 
            (pixel_x >= 200 && pixel_x <= 209 && pixel_y >= 60 && pixel_y <= 69) || // left diagonal
            (pixel_x >= 210 && pixel_x <= 219 && pixel_y >= 70 && pixel_y <= 79) || 
            (pixel_x >= 220 && pixel_x <= 229 && pixel_y >= 60 && pixel_y <= 69) || // right diagonal
            // E (x=250 to 290)
            (pixel_x >= 260 && pixel_x <= 279 && pixel_y >= 50 && pixel_y <= 59) || // top
            (pixel_x >= 250 && pixel_x <= 259 && pixel_y >= 60 && pixel_y <= 89) || // topleft
            (pixel_x >= 260 && pixel_x <= 274 && pixel_y >= 80 && pixel_y <= 89) || // middle
            (pixel_x >= 250 && pixel_x <= 259 && pixel_y >= 90 && pixel_y <= 109) || // bottomleft
            (pixel_x >= 260 && pixel_x <= 279 && pixel_y >= 110 && pixel_y <= 119) || // bottom
            (pixel_x >= 280 && pixel_x <= 289 && pixel_y >= 60 && pixel_y <= 69) || // top right dot
            (pixel_x >= 280 && pixel_x <= 289 && pixel_y >= 100 && pixel_y <= 109) || // bottom right dot
            // Apostrophe (x=290 to 330)
            (pixel_x >= 304 && pixel_x <= 313 && pixel_y >= 50 && pixel_y <= 59) || // main
            (pixel_x >= 308 && pixel_x <= 313 && pixel_y >= 60 && pixel_y <= 69) || // small block
            // S (x=340 to 380, shifted 10 units left)
            (pixel_x >= 340 && pixel_x <= 359 && pixel_y >= 50 && pixel_y <= 59) || // top
            (pixel_x >= 330 && pixel_x <= 339 && pixel_y >= 60 && pixel_y <= 79) || // left
            (pixel_x >= 340 && pixel_x <= 359 && pixel_y >= 80 && pixel_y <= 89) || // middle
            (pixel_x >= 360 && pixel_x <= 369 && pixel_y >= 90 && pixel_y <= 109) || // right lower
            (pixel_x >= 340 && pixel_x <= 359 && pixel_y >= 110 && pixel_y <= 119) || // bottom
            (pixel_x >= 360 && pixel_x <= 369 && pixel_y >= 60 && pixel_y <= 69) || // rightmost dot
            (pixel_x >= 330 && pixel_x <= 339 && pixel_y >= 100 && pixel_y <= 109) || // leftmost dot    
            // U (x=400 to 440)
            (pixel_x >= 400 && pixel_x <= 409 && pixel_y >= 50 && pixel_y <= 109) || // left
            (pixel_x >= 430 && pixel_x <= 439 && pixel_y >= 50 && pixel_y <= 109) || // right
            (pixel_x >= 410 && pixel_x <= 429 && pixel_y >= 110 && pixel_y <= 119) || // bottom
            // P (x=450 to 490)
            (pixel_x >= 450 && pixel_x <= 459 && pixel_y >= 50 && pixel_y <= 119) || // vertical
            (pixel_x >= 460 && pixel_x <= 479 && pixel_y >= 50 && pixel_y <= 59) || // top
            (pixel_x >= 480 && pixel_x <= 489 && pixel_y >= 60 && pixel_y <= 79) || // right
            (pixel_x >= 460 && pixel_x <= 479 && pixel_y >= 80 && pixel_y <= 89) || // middle
            // ! (x=500 to 540)
            (pixel_x >= 514 && pixel_x <= 523 && pixel_y >= 50 && pixel_y <= 99) || // top
            (pixel_x >= 514 && pixel_x <= 523 && pixel_y >= 109 && pixel_y <= 119)
        )) begin
            red <= 4'hF;   // Red text (#ff0000)
            green <= 4'h0;
            blue <= 4'h0;
        end 
        // Score display (text and digits)
        else if (
            // Score: S (x=50 to 90, y=200 to 270)
            (pixel_x >= 61 && pixel_x <= 80 && pixel_y >= 201 && pixel_y <= 210) || // top
            (pixel_x >= 61 && pixel_x <= 80 && pixel_y >= 261 && pixel_y <= 270) || // bottom
            (pixel_x >= 51 && pixel_x <= 60 && pixel_y >= 211 && pixel_y <= 230) || // left top
            (pixel_x >= 81 && pixel_x <= 90 && pixel_y >= 241 && pixel_y <= 260) || // right bottom
            (pixel_x >= 61 && pixel_x <= 80 && pixel_y >= 231 && pixel_y <= 240) || // middle
            (pixel_x >= 81 && pixel_x <= 90 && pixel_y >= 211 && pixel_y <= 220) || // rightmost dot
            (pixel_x >= 51 && pixel_x <= 60 && pixel_y >= 251 && pixel_y <= 260) ||
            // Score: C (x=100 to 140, y=200 to 270)
            (pixel_x >= 111 && pixel_x <= 130 && pixel_y >= 201 && pixel_y <= 210) || // top
            (pixel_x >= 111 && pixel_x <= 130 && pixel_y >= 261 && pixel_y <= 270) || // bottom
            (pixel_x >= 101 && pixel_x <= 110 && pixel_y >= 211 && pixel_y <= 260) || // left
            (pixel_x >= 131 && pixel_x <= 140 && pixel_y >= 211 && pixel_y <= 220) || // top right dot
            (pixel_x >= 131 && pixel_x <= 140 && pixel_y >= 251 && pixel_y <= 260) ||
            // Score: O (x=150 to 190, y=200 to 270)
            (pixel_x >= 161 && pixel_x <= 180 && pixel_y >= 201 && pixel_y <= 210) || // top
            (pixel_x >= 161 && pixel_x <= 180 && pixel_y >= 261 && pixel_y <= 270) || // bottom
            (pixel_x >= 151 && pixel_x <= 160 && pixel_y >= 211 && pixel_y <= 260) || // left
            (pixel_x >= 181 && pixel_x <= 190 && pixel_y >= 211 && pixel_y <= 260) ||
            // Score: R (x=200 to 240, y=200 to 270)
            (pixel_x >= 211 && pixel_x <= 230 && pixel_y >= 201 && pixel_y <= 210) || // top
            (pixel_x >= 201 && pixel_x <= 210 && pixel_y >= 201 && pixel_y <= 270) || // left
            (pixel_x >= 211 && pixel_x <= 230 && pixel_y >= 231 && pixel_y <= 240) || // middle
            (pixel_x >= 231 && pixel_x <= 240 && pixel_y >= 211 && pixel_y <= 230) || // right top vertical
            (pixel_x >= 231 && pixel_x <= 240 && pixel_y >= 241 && pixel_y <= 270) ||
            // Score: E (x=250 to 290, y=200 to 270)
            (pixel_x >= 261 && pixel_x <= 280 && pixel_y >= 201 && pixel_y <= 210) || // top
            (pixel_x >= 261 && pixel_x <= 280 && pixel_y >= 261 && pixel_y <= 270) || // bottom
            (pixel_x >= 251 && pixel_x <= 260 && pixel_y >= 211 && pixel_y <= 260) || // left
            (pixel_x >= 261 && pixel_x <= 275 && pixel_y >= 231 && pixel_y <= 240) || // middle
            (pixel_x >= 281 && pixel_x <= 290 && pixel_y >= 211 && pixel_y <= 220) || // top right dot
            (pixel_x >= 281 && pixel_x <= 290 && pixel_y >= 251 && pixel_y <= 260)
        ) begin
            red <= 4'hF;   // Red text for "SCORE" (#ff0000)
            green <= 4'h0;
            blue <= 4'h0;
        end
        // Score digits with cycling colors
        else if (
            // Score: Ten thousands digit (x=340 to 379, y=200 to 270)
            (pixel_x >= 340 && pixel_x <= 379 && pixel_y >= 200 && pixel_y <= 270 && (
                (score_ten_thousands == 0 && (
                    // 0
                    (pixel_x >= 351 && pixel_x <= 369 && pixel_y >= 201 && pixel_y <= 210) || // top
                    (pixel_x >= 341 && pixel_x <= 350 && pixel_y >= 211 && pixel_y <= 260) || // left
                    (pixel_x >= 351 && pixel_x <= 369 && pixel_y >= 261 && pixel_y <= 270) || // bottom
                    (pixel_x >= 370 && pixel_x <= 379 && pixel_y >= 211 && pixel_y <= 260) || // right
                    (pixel_x >= 356 && pixel_x <= 364 && pixel_y >= 231 && pixel_y <= 240)    // middle
                )) ||
                (score_ten_thousands == 1 && (
                    // 1
                    (pixel_x >= 356 && pixel_x <= 364 && pixel_y >= 201 && pixel_y <= 260) || // vertical
                    (pixel_x >= 341 && pixel_x <= 379 && pixel_y >= 261 && pixel_y <= 270) || // bottom
                    (pixel_x >= 346 && pixel_x <= 355 && pixel_y >= 211 && pixel_y <= 220)    // dot
                )) ||
                (score_ten_thousands == 2 && (
                    // 2
                    (pixel_x >= 351 && pixel_x <= 369 && pixel_y >= 201 && pixel_y <= 210) || // top
                    (pixel_x >= 341 && pixel_x <= 379 && pixel_y >= 261 && pixel_y <= 270) || // bottom
                    (pixel_x >= 341 && pixel_x <= 350 && pixel_y >= 211 && pixel_y <= 220) || // left top dot
                    (pixel_x >= 341 && pixel_x <= 350 && pixel_y >= 251 && pixel_y <= 260) || // left bottom dot
                    (pixel_x >= 370 && pixel_x <= 379 && pixel_y >= 211 && pixel_y <= 240) || // vertical
                    (pixel_x >= 351 && pixel_x <= 369 && pixel_y >= 241 && pixel_y <= 250)    // middle
                )) ||
                (score_ten_thousands == 3 && (
                    // 3
                    (pixel_x >= 351 && pixel_x <= 369 && pixel_y >= 201 && pixel_y <= 210) || // top
                    (pixel_x >= 351 && pixel_x <= 369 && pixel_y >= 261 && pixel_y <= 270) || // bottom
                    (pixel_x >= 341 && pixel_x <= 350 && pixel_y >= 211 && pixel_y <= 220) || // left top dot
                    (pixel_x >= 341 && pixel_x <= 350 && pixel_y >= 251 && pixel_y <= 260) || // left bottom dot
                    (pixel_x >= 361 && pixel_x <= 369 && pixel_y >= 231 && pixel_y <= 240) || // right middle dot
                    (pixel_x >= 370 && pixel_x <= 379 && pixel_y >= 211 && pixel_y <= 230) || // vertical top
                    (pixel_x >= 370 && pixel_x <= 379 && pixel_y >= 241 && pixel_y <= 260)    // vertical bottom
                )) ||
                (score_ten_thousands == 4 && (
                    // 4
                    (pixel_x >= 341 && pixel_x <= 350 && pixel_y >= 211 && pixel_y <= 240) || // left vertical
                    (pixel_x >= 361 && pixel_x <= 369 && pixel_y >= 201 && pixel_y <= 270) || // right vertical
                    (pixel_x >= 341 && pixel_x <= 379 && pixel_y >= 241 && pixel_y <= 250)    // horizontal
                )) ||
                (score_ten_thousands == 5 && (
                    // 5
                    (pixel_x >= 341 && pixel_x <= 379 && pixel_y >= 201 && pixel_y <= 210) || // top
                    (pixel_x >= 351 && pixel_x <= 369 && pixel_y >= 261 && pixel_y <= 270) || // bottom 
                    (pixel_x >= 341 && pixel_x <= 350 && pixel_y >= 211 && pixel_y <= 230) || // left vertical
                    (pixel_x >= 370 && pixel_x <= 379 && pixel_y >= 231 && pixel_y <= 260) || // right vertical
                    (pixel_x >= 351 && pixel_x <= 369 && pixel_y >= 221 && pixel_y <= 230) || // middle
                    (pixel_x >= 341 && pixel_x <= 350 && pixel_y >= 251 && pixel_y <= 260)    // left dot
                )) ||
                (score_ten_thousands == 6 && (
                    // 6
                    (pixel_x >= 351 && pixel_x <= 369 && pixel_y >= 201 && pixel_y <= 210) || // top
                    (pixel_x >= 351 && pixel_x <= 369 && pixel_y >= 261 && pixel_y <= 270) || // bottom
                    (pixel_x >= 351 && pixel_x <= 369 && pixel_y >= 231 && pixel_y <= 240) || // middle
                    (pixel_x >= 341 && pixel_x <= 350 && pixel_y >= 211 && pixel_y <= 260) || // left vertical
                    (pixel_x >= 370 && pixel_x <= 379 && pixel_y >= 241 && pixel_y <= 260) || // right vertical
                    (pixel_x >= 370 && pixel_x <= 379 && pixel_y >= 211 && pixel_y <= 220)    // right dot
                )) ||
                (score_ten_thousands == 7 && (
                    // 7
                    (pixel_x >= 370 && pixel_x <= 379 && pixel_y >= 211 && pixel_y <= 240) || // right vertical
                    (pixel_x >= 361 && pixel_x <= 369 && pixel_y >= 240 && pixel_y <= 270) || // left vertical
                    (pixel_x >= 351 && pixel_x <= 369 && pixel_y >= 201 && pixel_y <= 210) || // top
                    (pixel_x >= 341 && pixel_x <= 350 && pixel_y >= 211 && pixel_y <= 220)    // left dot
                )) ||
                (score_ten_thousands == 8 && (
                    // 8
                    (pixel_x >= 351 && pixel_x <= 369 && pixel_y >= 201 && pixel_y <= 210) || // top
                    (pixel_x >= 351 && pixel_x <= 369 && pixel_y >= 261 && pixel_y <= 270) || // bottom
                    (pixel_x >= 351 && pixel_x <= 369 && pixel_y >= 231 && pixel_y <= 240) || // middle
                    (pixel_x >= 341 && pixel_x <= 350 && pixel_y >= 211 && pixel_y <= 230) || // left bottom vertical
                    (pixel_x >= 341 && pixel_x <= 350 && pixel_y >= 241 && pixel_y <= 260) || // left top vertical
                    (pixel_x >= 370 && pixel_x <= 379 && pixel_y >= 211 && pixel_y <= 230) || // right bottom vertical
                    (pixel_x >= 370 && pixel_x <= 379 && pixel_y >= 241 && pixel_y <= 260)    // right top vertical
                )) ||
                (score_ten_thousands == 9 && (
                    // 9
                    (pixel_x >= 351 && pixel_x <= 369 && pixel_y >= 201 && pixel_y <= 210) || // top
                    (pixel_x >= 351 && pixel_x <= 369 && pixel_y >= 261 && pixel_y <= 270) || // bottom
                    (pixel_x >= 351 && pixel_x <= 369 && pixel_y >= 231 && pixel_y <= 240) || // middle
                    (pixel_x >= 341 && pixel_x <= 350 && pixel_y >= 251 && pixel_y <= 260) || // left dot
                    (pixel_x >= 341 && pixel_x <= 350 && pixel_y >= 211 && pixel_y <= 230) || // left top
                    (pixel_x >= 370 && pixel_x <= 379 && pixel_y >= 211 && pixel_y <= 260)    // right vertical
                ))
            )) ||
            // Score: Thousands digit (x=390 to 429, y=200 to 270)
            (pixel_x >= 390 && pixel_x <= 429 && pixel_y >= 200 && pixel_y <= 270 && (
                (score_thousands == 0 && (
                    // 0
                    (pixel_x >= 401 && pixel_x <= 419 && pixel_y >= 201 && pixel_y <= 210) || // top
                    (pixel_x >= 391 && pixel_x <= 400 && pixel_y >= 211 && pixel_y <= 260) || // left
                    (pixel_x >= 401 && pixel_x <= 419 && pixel_y >= 261 && pixel_y <= 270) || // bottom
                    (pixel_x >= 420 && pixel_x <= 429 && pixel_y >= 211 && pixel_y <= 260) || // right
                    (pixel_x >= 406 && pixel_x <= 414 && pixel_y >= 231 && pixel_y <= 240)    // middle
                )) ||
                (score_thousands == 1 && (
                    // 1
                    (pixel_x >= 406 && pixel_x <= 414 && pixel_y >= 201 && pixel_y <= 260) || // vertical
                    (pixel_x >= 391 && pixel_x <= 429 && pixel_y >= 261 && pixel_y <= 270) || // bottom
                    (pixel_x >= 396 && pixel_x <= 405 && pixel_y >= 211 && pixel_y <= 220)    // dot
                )) ||
                (score_thousands == 2 && (
                    // 2
                    (pixel_x >= 401 && pixel_x <= 419 && pixel_y >= 201 && pixel_y <= 210) || // top
                    (pixel_x >= 391 && pixel_x <= 429 && pixel_y >= 261 && pixel_y <= 270) || // bottom
                    (pixel_x >= 391 && pixel_x <= 400 && pixel_y >= 211 && pixel_y <= 220) || // left top dot
                    (pixel_x >= 391 && pixel_x <= 400 && pixel_y >= 251 && pixel_y <= 260) || // left bottom dot
                    (pixel_x >= 420 && pixel_x <= 429 && pixel_y >= 211 && pixel_y <= 240) || // vertical
                    (pixel_x >= 401 && pixel_x <= 419 && pixel_y >= 241 && pixel_y <= 250)    // middle
                )) ||
                (score_thousands == 3 && (
                    // 3
                    (pixel_x >= 401 && pixel_x <= 419 && pixel_y >= 201 && pixel_y <= 210) || // top
                    (pixel_x >= 401 && pixel_x <= 419 && pixel_y >= 261 && pixel_y <= 270) || // bottom
                    (pixel_x >= 391 && pixel_x <= 400 && pixel_y >= 211 && pixel_y <= 220) || // left top dot
                    (pixel_x >= 391 && pixel_x <= 400 && pixel_y >= 251 && pixel_y <= 260) || // left bottom dot
                    (pixel_x >= 411 && pixel_x <= 419 && pixel_y >= 231 && pixel_y <= 240) || // right middle dot
                    (pixel_x >= 420 && pixel_x <= 429 && pixel_y >= 211 && pixel_y <= 230) || // vertical top
                    (pixel_x >= 420 && pixel_x <= 429 && pixel_y >= 241 && pixel_y <= 260)    // vertical bottom
                )) ||
                (score_thousands == 4 && (
                    // 4
                    (pixel_x >= 391 && pixel_x <= 400 && pixel_y >= 211 && pixel_y <= 240) || // left vertical
                    (pixel_x >= 411 && pixel_x <= 419 && pixel_y >= 201 && pixel_y <= 270) || // right vertical
                    (pixel_x >= 391 && pixel_x <= 429 && pixel_y >= 241 && pixel_y <= 250)    // horizontal
                )) ||
                (score_thousands == 5 && (
                    // 5
                    (pixel_x >= 391 && pixel_x <= 429 && pixel_y >= 201 && pixel_y <= 210) || // top
                    (pixel_x >= 401 && pixel_x <= 419 && pixel_y >= 261 && pixel_y <= 270) || // bottom 
                    (pixel_x >= 391 && pixel_x <= 400 && pixel_y >= 211 && pixel_y <= 230) || // left vertical
                    (pixel_x >= 420 && pixel_x <= 429 && pixel_y >= 231 && pixel_y <= 260) || // right vertical
                    (pixel_x >= 401 && pixel_x <= 419 && pixel_y >= 221 && pixel_y <= 230) || // middle
                    (pixel_x >= 391 && pixel_x <= 400 && pixel_y >= 251 && pixel_y <= 260)    // left dot
                )) ||
                (score_thousands == 6 && (
                    // 6
                    (pixel_x >= 401 && pixel_x <= 419 && pixel_y >= 201 && pixel_y <= 210) || // top
                    (pixel_x >= 401 && pixel_x <= 419 && pixel_y >= 261 && pixel_y <= 270) || // bottom
                    (pixel_x >= 401 && pixel_x <= 419 && pixel_y >= 231 && pixel_y <= 240) || // middle
                    (pixel_x >= 391 && pixel_x <= 400 && pixel_y >= 211 && pixel_y <= 260) || // left vertical
                    (pixel_x >= 420 && pixel_x <= 429 && pixel_y >= 241 && pixel_y <= 260) || // right vertical
                    (pixel_x >= 420 && pixel_x <= 429 && pixel_y >= 211 && pixel_y <= 220)    // right dot
                )) ||
                (score_thousands == 7 && (
                    // 7
                    (pixel_x >= 420 && pixel_x <= 429 && pixel_y >= 211 && pixel_y <= 240) || // right vertical
                    (pixel_x >= 411 && pixel_x <= 419 && pixel_y >= 240 && pixel_y <= 270) || // left vertical
                    (pixel_x >= 401 && pixel_x <= 419 && pixel_y >= 201 && pixel_y <= 210) || // top
                    (pixel_x >= 391 && pixel_x <= 400 && pixel_y >= 211 && pixel_y <= 220)    // left dot
                )) ||
                (score_thousands == 8 && (
                    // 8
                    (pixel_x >= 401 && pixel_x <= 419 && pixel_y >= 201 && pixel_y <= 210) || // top
                    (pixel_x >= 401 && pixel_x <= 419 && pixel_y >= 261 && pixel_y <= 270) || // bottom
                    (pixel_x >= 401 && pixel_x <= 419 && pixel_y >= 231 && pixel_y <= 240) || // middle
                    (pixel_x >= 391 && pixel_x <= 400 && pixel_y >= 211 && pixel_y <= 230) || // left bottom vertical
                    (pixel_x >= 391 && pixel_x <= 400 && pixel_y >= 241 && pixel_y <= 260) || // left top vertical
                    (pixel_x >= 420 && pixel_x <= 429 && pixel_y >= 211 && pixel_y <= 230) || // right bottom vertical
                    (pixel_x >= 420 && pixel_x <= 429 && pixel_y >= 241 && pixel_y <= 260)    // right top vertical
                )) ||
                (score_thousands == 9 && (
                    //  [0-9] (score_thousands == 9 && (
                    // 9
                    (pixel_x >= 401 && pixel_x <= 419 && pixel_y >= 201 && pixel_y <= 210) || // top
                    (pixel_x >= 401 && pixel_x <= 419 && pixel_y >= 261 && pixel_y <= 270) || // bottom
                    (pixel_x >= 401 && pixel_x <= 419 && pixel_y >= 231 && pixel_y <= 240) || // middle
                    (pixel_x >= 391 && pixel_x <= 400 && pixel_y >= 251 && pixel_y <= 260) || // left dot
                    (pixel_x >= 391 && pixel_x <= 400 && pixel_y >= 211 && pixel_y <= 230) || // left top
                    (pixel_x >= 420 && pixel_x <= 429 && pixel_y >= 211 && pixel_y <= 260)    // right vertical
                ))
            )) ||
            // Score: Hundreds digit (x=440 to 479, y=200 to 270)
            (pixel_x >= 440 && pixel_x <= 479 && pixel_y >= 200 && pixel_y <= 270 && (
                (score_hundreds == 0 && (
                    // 0
                    (pixel_x >= 451 && pixel_x <= 469 && pixel_y >= 201 && pixel_y <= 210) || // top
                    (pixel_x >= 441 && pixel_x <= 450 && pixel_y >= 211 && pixel_y <= 260) || // left
                    (pixel_x >= 451 && pixel_x <= 469 && pixel_y >= 261 && pixel_y <= 270) || // bottom
                    (pixel_x >= 470 && pixel_x <= 479 && pixel_y >= 211 && pixel_y <= 260) || // right
                    (pixel_x >= 456 && pixel_x <= 464 && pixel_y >= 231 && pixel_y <= 240)    // middle
                )) ||
                (score_hundreds == 1 && (
                    // 1
                    (pixel_x >= 456 && pixel_x <= 464 && pixel_y >= 201 && pixel_y <= 260) || // vertical
                    (pixel_x >= 441 && pixel_x <= 479 && pixel_y >= 261 && pixel_y <= 270) || // bottom
                    (pixel_x >= 446 && pixel_x <= 455 && pixel_y >= 211 && pixel_y <= 220)    // dot
                )) ||
                (score_hundreds == 2 && (
                    // 2
                    (pixel_x >= 451 && pixel_x <= 469 && pixel_y >= 201 && pixel_y <= 210) || // top
                    (pixel_x >= 441 && pixel_x <= 479 && pixel_y >= 261 && pixel_y <= 270) || // bottom
                    (pixel_x >= 441 && pixel_x <= 450 && pixel_y >= 211 && pixel_y <= 220) || // left top dot
                    (pixel_x >= 441 && pixel_x <= 450 && pixel_y >= 251 && pixel_y <= 260) || // left bottom dot
                    (pixel_x >= 470 && pixel_x <= 479 && pixel_y >= 211 && pixel_y <= 240) || // vertical
                    (pixel_x >= 451 && pixel_x <= 469 && pixel_y >= 241 && pixel_y <= 250)    // middle
                )) ||
                (score_hundreds == 3 && (
                    // 3
                    (pixel_x >= 451 && pixel_x <= 469 && pixel_y >= 201 && pixel_y <= 210) || // top
                    (pixel_x >= 451 && pixel_x <= 469 && pixel_y >= 261 && pixel_y <= 270) || // bottom
                    (pixel_x >= 441 && pixel_x <= 450 && pixel_y >= 211 && pixel_y <= 220) || // left top dot
                    (pixel_x >= 441 && pixel_x <= 450 && pixel_y >= 251 && pixel_y <= 260) || // left bottom dot
                    (pixel_x >= 461 && pixel_x <= 469 && pixel_y >= 231 && pixel_y <= 240) || // right middle dot
                    (pixel_x >= 470 && pixel_x <= 479 && pixel_y >= 211 && pixel_y <= 230) || // vertical top
                    (pixel_x >= 470 && pixel_x <= 479 && pixel_y >= 241 && pixel_y <= 260)    // vertical bottom
                )) ||
                (score_hundreds == 4 && (
                    // 4
                    (pixel_x >= 441 && pixel_x <= 450 && pixel_y >= 211 && pixel_y <= 240) || // left vertical
                    (pixel_x >= 461 && pixel_x <= 469 && pixel_y >= 201 && pixel_y <= 270) || // right vertical
                    (pixel_x >= 441 && pixel_x <= 479 && pixel_y >= 241 && pixel_y <= 250)    // horizontal
                )) ||
                (score_hundreds == 5 && (
                    // 5
                    (pixel_x >= 441 && pixel_x <= 479 && pixel_y >= 201 && pixel_y <= 210) || // top
                    (pixel_x >= 451 && pixel_x <= 469 && pixel_y >= 261 && pixel_y <= 270) || // bottom 
                    (pixel_x >= 441 && pixel_x <= 450 && pixel_y >= 211 && pixel_y <= 230) || // left vertical
                    (pixel_x >= 470 && pixel_x <= 479 && pixel_y >= 231 && pixel_y <= 260) || // right vertical
                    (pixel_x >= 451 && pixel_x <= 469 && pixel_y >= 221 && pixel_y <= 230) || // middle
                    (pixel_x >= 441 && pixel_x <= 450 && pixel_y >= 251 && pixel_y <= 260)    // left dot
                )) ||
                (score_hundreds == 6 && (
                    // 6
                    (pixel_x >= 451 && pixel_x <= 469 && pixel_y >= 201 && pixel_y <= 210) || // top
                    (pixel_x >= 451 && pixel_x <= 469 && pixel_y >= 261 && pixel_y <= 270) || // bottom
                    (pixel_x >= 451 && pixel_x <= 469 && pixel_y >= 231 && pixel_y <= 240) || // middle
                    (pixel_x >= 441 && pixel_x <= 450 && pixel_y >= 211 && pixel_y <= 260) || // left vertical
                    (pixel_x >= 470 && pixel_x <= 479 && pixel_y >= 241 && pixel_y <= 260) || // right vertical
                    (pixel_x >= 470 && pixel_x <= 479 && pixel_y >= 211 && pixel_y <= 220)    // right dot
                )) ||
                (score_hundreds == 7 && (
                    // 7
                    (pixel_x >= 470 && pixel_x <= 479 && pixel_y >= 211 && pixel_y <= 240) || // right vertical
                    (pixel_x >= 461 && pixel_x <= 469 && pixel_y >= 240 && pixel_y <= 270) || // left vertical
                    (pixel_x >= 451 && pixel_x <= 469 && pixel_y >= 201 && pixel_y <= 210) || // top
                    (pixel_x >= 441 && pixel_x <= 450 && pixel_y >= 211 && pixel_y <= 220)    // left dot
                )) ||
                (score_hundreds == 8 && (
                    // 8
                    (pixel_x >= 451 && pixel_x <= 469 && pixel_y >= 201 && pixel_y <= 210) || // top
                    (pixel_x >= 451 && pixel_x <= 469 && pixel_y >= 261 && pixel_y <= 270) || // bottom
                    (pixel_x >= 451 && pixel_x <= 469 && pixel_y >= 231 && pixel_y <= 240) || // middle
                    (pixel_x >= 441 && pixel_x <= 450 && pixel_y >= 211 && pixel_y <= 230) || // left bottom vertical
                    (pixel_x >= 441 && pixel_x <= 450 && pixel_y >= 241 && pixel_y <= 260) || // left top vertical
                    (pixel_x >= 470 && pixel_x <= 479 && pixel_y >= 211 && pixel_y <= 230) || // right bottom vertical
                    (pixel_x >= 470 && pixel_x <= 479 && pixel_y >= 241 && pixel_y <= 260)    // right top vertical
                )) ||
                (score_hundreds == 9 && (
                    // 9
                    (pixel_x >= 451 && pixel_x <= 469 && pixel_y >= 201 && pixel_y <= 210) || // top
                    (pixel_x >= 451 && pixel_x <= 469 && pixel_y >= 261 && pixel_y <= 270) || // bottom
                    (pixel_x >= 451 && pixel_x <= 469 && pixel_y >= 231 && pixel_y <= 240) || // middle
                    (pixel_x >= 441 && pixel_x <= 450 && pixel_y >= 251 && pixel_y <= 260) || // left dot
                    (pixel_x >= 441 && pixel_x <= 450 && pixel_y >= 211 && pixel_y <= 230) || // left top
                    (pixel_x >= 470 && pixel_x <= 479 && pixel_y >= 211 && pixel_y <= 260)    // right vertical
                ))
            )) ||
            // Score: Tens digit (x=490 to 529, y=200 to 270)
            (pixel_x >= 490 && pixel_x <= 529 && pixel_y >= 200 && pixel_y <= 270 && (
                (score_tens == 0 && (
                    // 0
                    (pixel_x >= 501 && pixel_x <= 519 && pixel_y >= 201 && pixel_y <= 210) || // top
                    (pixel_x >= 491 && pixel_x <= 500 && pixel_y >= 211 && pixel_y <= 260) || // left
                    (pixel_x >= 501 && pixel_x <= 519 && pixel_y >= 261 && pixel_y <= 270) || // bottom
                    (pixel_x >= 520 && pixel_x <= 529 && pixel_y >= 211 && pixel_y <= 260) || // right
                    (pixel_x >= 506 && pixel_x <= 514 && pixel_y >= 231 && pixel_y <= 240)    // middle
                )) ||
                (score_tens == 1 && (
                    // 1
                    (pixel_x >= 506 && pixel_x <= 514 && pixel_y >= 201 && pixel_y <= 260) || // vertical
                    (pixel_x >= 491 && pixel_x <= 529 && pixel_y >= 261 && pixel_y <= 270) || // bottom
                    (pixel_x >= 496 && pixel_x <= 505 && pixel_y >= 211 && pixel_y <= 220)    // dot
                )) ||
                (score_tens == 2 && (
                    // 2
                    (pixel_x >= 501 && pixel_x <= 519 && pixel_y >= 201 && pixel_y <= 210) || // top
                    (pixel_x >= 491 && pixel_x <= 529 && pixel_y >= 261 && pixel_y <= 270) || // bottom
                    (pixel_x >= 491 && pixel_x <= 500 && pixel_y >= 211 && pixel_y <= 220) || // left top dot
                    (pixel_x >= 491 && pixel_x <= 500 && pixel_y >= 251 && pixel_y <= 260) || // left bottom dot
                    (pixel_x >= 520 && pixel_x <= 529 && pixel_y >= 211 && pixel_y <= 240) || // vertical
                    (pixel_x >= 501 && pixel_x <= 519 && pixel_y >= 241 && pixel_y <= 250)    // middle
                )) ||
                (score_tens == 3 && (
                    // 3
                    (pixel_x >= 501 && pixel_x <= 519 && pixel_y >= 201 && pixel_y <= 210) || // top
                    (pixel_x >= 501 && pixel_x <= 519 && pixel_y >= 261 && pixel_y <= 270) || // bottom
                    (pixel_x >= 491 && pixel_x <= 500 && pixel_y >= 211 && pixel_y <= 220) || // left top dot
                    (pixel_x >= 491 && pixel_x <= 500 && pixel_y >= 251 && pixel_y <= 260) || // left bottom dot
                    (pixel_x >= 511 && pixel_x <= 519 && pixel_y >= 231 && pixel_y <= 240) || // right middle dot
                    (pixel_x >= 520 && pixel_x <= 529 && pixel_y >= 211 && pixel_y <= 230) || // vertical top
                    (pixel_x >= 520 && pixel_x <= 529 && pixel_y >= 241 && pixel_y <= 260)    // vertical bottom
                )) ||
                (score_tens == 4 && (
                    // 4
                    (pixel_x >= 491 && pixel_x <= 500 && pixel_y >= 211 && pixel_y <= 240) || // left vertical
                    (pixel_x >= 511 && pixel_x <= 519 && pixel_y >= 201 && pixel_y <= 270) || // right vertical
                    (pixel_x >= 491 && pixel_x <= 529 && pixel_y >= 241 && pixel_y <= 250)    // horizontal
                )) ||
                (score_tens == 5 && (
                    // 5
                    (pixel_x >= 491 && pixel_x <= 529 && pixel_y >= 201 && pixel_y <= 210) || // top
                    (pixel_x >= 501 && pixel_x <= 519 && pixel_y >= 261 && pixel_y <= 270) || // bottom 
                    (pixel_x >= 491 && pixel_x <= 500 && pixel_y >= 211 && pixel_y <= 230) || // left vertical
                    (pixel_x >= 520 && pixel_x <= 529 && pixel_y >= 231 && pixel_y <= 260) || // right vertical
                    (pixel_x >= 501 && pixel_x <= 519 && pixel_y >= 221 && pixel_y <= 230) || // middle
                    (pixel_x >= 491 && pixel_x <= 500 && pixel_y >= 251 && pixel_y <= 260)    // left dot
                )) ||
                (score_tens == 6 && (
                    // 6
                    (pixel_x >= 501 && pixel_x <= 519 && pixel_y >= 201 && pixel_y <= 210) || // top
                    (pixel_x >= 501 && pixel_x <= 519 && pixel_y >= 261 && pixel_y <= 270) || // bottom
                    (pixel_x >= 501 && pixel_x <= 519 && pixel_y >= 231 && pixel_y <= 240) || // middle
                    (pixel_x >= 491 && pixel_x <= 500 && pixel_y >= 211 && pixel_y <= 260) || // left vertical
                    (pixel_x >= 520 && pixel_x <= 529 && pixel_y >= 241 && pixel_y <= 260) || // right vertical
                    (pixel_x >= 520 && pixel_x <= 529 && pixel_y >= 211 && pixel_y <= 220)    // right dot
                )) ||
                (score_tens == 7 && (
                    // 7
                    (pixel_x >= 520 && pixel_x <= 529 && pixel_y >= 211 && pixel_y <= 240) || // right vertical
                    (pixel_x >= 511 && pixel_x <= 519 && pixel_y >= 240 && pixel_y <= 270) || // left vertical
                    (pixel_x >= 501 && pixel_x <= 519 && pixel_y >= 201 && pixel_y <= 210) || // top
                    (pixel_x >= 491 && pixel_x <= 500 && pixel_y >= 211 && pixel_y <= 220)    // left dot
                )) ||
                (score_tens == 8 && (
                    // 8
                    (pixel_x >= 501 && pixel_x <= 519 && pixel_y >= 201 && pixel_y <= 210) || // top
                    (pixel_x >= 501 && pixel_x <= 519 && pixel_y >= 261 && pixel_y <= 270) || // bottom
                    (pixel_x >= 501 && pixel_x <= 519 && pixel_y >= 231 && pixel_y <= 240) || // middle
                    (pixel_x >= 491 && pixel_x <= 500 && pixel_y >= 211 && pixel_y <= 230) || // left bottom vertical
                    (pixel_x >= 491 && pixel_x <= 500 && pixel_y >= 241 && pixel_y <= 260) || // left top vertical
                    (pixel_x >= 520 && pixel_x <= 529 && pixel_y >= 211 && pixel_y <= 230) || // right bottom vertical
                    (pixel_x >= 520 && pixel_x <= 529 && pixel_y >= 241 && pixel_y <= 260)    // right top vertical
                )) ||
                (score_tens == 9 && (
                    // 9
                    (pixel_x >= 501 && pixel_x <= 519 && pixel_y >= 201 && pixel_y <= 210) || // top
                    (pixel_x >= 501 && pixel_x <= 519 && pixel_y >= 261 && pixel_y <= 270) || // bottom
                    (pixel_x >= 501 && pixel_x <= 519 && pixel_y >= 231 && pixel_y <= 240) || // middle
                    (pixel_x >= 491 && pixel_x <= 500 && pixel_y >= 251 && pixel_y <= 260) || // left dot
                    (pixel_x >= 491 && pixel_x <= 500 && pixel_y >= 211 && pixel_y <= 230) || // left top
                    (pixel_x >= 520 && pixel_x <= 529 && pixel_y >= 211 && pixel_y <= 260)    // right vertical
                ))
            )) ||
            // Score: Ones digit (x=540 to 579, y=200 to 270)
            (pixel_x >= 540 && pixel_x <= 579 && pixel_y >= 200 && pixel_y <= 270 && (
                (score_ones == 0 && (
                    // 0
                    (pixel_x >= 551 && pixel_x <= 569 && pixel_y >= 201 && pixel_y <= 210) || // top
                    (pixel_x >= 541 && pixel_x <= 550 && pixel_y >= 211 && pixel_y <= 260) || // left
                    (pixel_x >= 551 && pixel_x <= 569 && pixel_y >= 261 && pixel_y <= 270) || // bottom
                    (pixel_x >= 570 && pixel_x <= 579 && pixel_y >= 211 && pixel_y <= 260) || // right
                    (pixel_x >= 556 && pixel_x <= 564 && pixel_y >= 231 && pixel_y <= 240)    // middle
                )) ||
                (score_ones == 1 && (
                    // 1
                    (pixel_x >= 556 && pixel_x <= 564 && pixel_y >= 201 && pixel_y <= 260) || // vertical
                    (pixel_x >= 541 && pixel_x <= 579 && pixel_y >= 261 && pixel_y <= 270) || // bottom
                    (pixel_x >= 546 && pixel_x <= 555 && pixel_y >= 211 && pixel_y <= 220)    // dot
                )) ||
                (score_ones == 2 && (
                    // 2
                    (pixel_x >= 551 && pixel_x <= 569 && pixel_y >= 201 && pixel_y <= 210) || // top
                    (pixel_x >= 541 && pixel_x <= 579 && pixel_y >= 261 && pixel_y <= 270) || // bottom
                    (pixel_x >= 541 && pixel_x <= 550 && pixel_y >= 211 && pixel_y <= 220) || // left top dot
                    (pixel_x >= 541 && pixel_x <= 550 && pixel_y >= 251 && pixel_y <= 260) || // left bottom dot
                    (pixel_x >= 570 && pixel_x <= 579 && pixel_y >= 211 && pixel_y <= 240) || // vertical
                    (pixel_x >= 551 && pixel_x <= 569 && pixel_y >= 241 && pixel_y <= 250)    // middle
                )) ||
                (score_ones == 3 && (
                    // 3
                    (pixel_x >= 551 && pixel_x <= 569 && pixel_y >= 201 && pixel_y <= 210) || // top
                    (pixel_x >= 551 && pixel_x <= 569 && pixel_y >= 261 && pixel_y <= 270) || // bottom
                    (pixel_x >= 541 && pixel_x <= 550 && pixel_y >= 211 && pixel_y <= 220) || // left top dot
                    (pixel_x >= 541 && pixel_x <= 550 && pixel_y >= 251 && pixel_y <= 260) || // left bottom dot
                    (pixel_x >= 561 && pixel_x <= 569 && pixel_y >= 231 && pixel_y <= 240) || // right middle dot
                    (pixel_x >= 570 && pixel_x <= 579 && pixel_y >= 211 && pixel_y <= 230) || // vertical top
                    (pixel_x >= 570 && pixel_x <= 579 && pixel_y >= 241 && pixel_y <= 260)    // vertical bottom
                )) ||
                (score_ones == 4 && (
                    // 4
                    (pixel_x >= 541 && pixel_x <= 550 && pixel_y >= 211 && pixel_y <= 240) || // left vertical
                    (pixel_x >= 561 && pixel_x <= 569 && pixel_y >= 201 && pixel_y <= 270) || // right vertical
                    (pixel_x >= 541 && pixel_x <= 579 && pixel_y >= 241 && pixel_y <= 250)    // horizontal
                )) ||
                (score_ones == 5 && (
                    // 5
                    (pixel_x >= 541 && pixel_x <= 579 && pixel_y >= 201 && pixel_y <= 210) || // top
                    (pixel_x >= 551 && pixel_x <= 569 && pixel_y >= 261 && pixel_y <= 270) || // bottom 
                    (pixel_x >= 541 && pixel_x <= 550 && pixel_y >= 211 && pixel_y <= 230) || // left vertical
                    (pixel_x >= 570 && pixel_x <= 579 && pixel_y >= 231 && pixel_y <= 260) || // right vertical
                    (pixel_x >= 551 && pixel_x <= 569 && pixel_y >= 221 && pixel_y <= 230) || // middle
                    (pixel_x >= 541 && pixel_x <= 550 && pixel_y >= 251 && pixel_y <= 260)    // left dot
                )) ||
                (score_ones == 6 && (
                    // 6
                    (pixel_x >= 551 && pixel_x <= 569 && pixel_y >= 201 && pixel_y <= 210) || // top
                    (pixel_x >= 551 && pixel_x <= 569 && pixel_y >= 261 && pixel_y <= 270) || // bottom
                    (pixel_x >= 551 && pixel_x <= 569 && pixel_y >= 231 && pixel_y <= 240) || // middle
                    (pixel_x >= 541 && pixel_x <= 550 && pixel_y >= 211 && pixel_y <= 260) || // left vertical
                    (pixel_x >= 570 && pixel_x <= 579 && pixel_y >= 241 && pixel_y <= 260) || // right vertical
                    (pixel_x >= 570 && pixel_x <= 579 && pixel_y >= 211 && pixel_y <= 220)    // right dot
                )) ||
                (score_ones == 7 && (
                    // 7
                    (pixel_x >= 570 && pixel_x <= 579 && pixel_y >= 211 && pixel_y <= 240) || // right vertical
                    (pixel_x >= 561 && pixel_x <= 569 && pixel_y >= 240 && pixel_y <= 270) || // left vertical
                    (pixel_x >= 551 && pixel_x <= 569 && pixel_y >= 201 && pixel_y <= 210) || // top
                    (pixel_x >= 541 && pixel_x <= 550 && pixel_y >= 211 && pixel_y <= 220)    // left dot
                )) ||
                (score_ones == 8 && (
                    // 8
                    (pixel_x >= 551 && pixel_x <= 569 && pixel_y >= 201 && pixel_y <= 210) || // top
                    (pixel_x >= 551 && pixel_x <= 569 && pixel_y >= 261 && pixel_y <= 270) || // bottom
                    (pixel_x >= 551 && pixel_x <= 569 && pixel_y >= 231 && pixel_y <= 240) || // middle
                    (pixel_x >= 541 && pixel_x <= 550 && pixel_y >= 211 && pixel_y <= 230) || // left bottom vertical
                    (pixel_x >= 541 && pixel_x <= 550 && pixel_y >= 241 && pixel_y <= 260) || // left top vertical
                    (pixel_x >= 570 && pixel_x <= 579 && pixel_y >= 211 && pixel_y <= 230) || // right bottom vertical
                    (pixel_x >= 570 && pixel_x <= 579 && pixel_y >= 241 && pixel_y <= 260)    // right top vertical
                )) ||
                (score_ones == 9 && (
                    // 9
                    (pixel_x >= 551 && pixel_x <= 569 && pixel_y >= 201 && pixel_y <= 210) || // top
                    (pixel_x >= 551 && pixel_x <= 569 && pixel_y >= 261 && pixel_y <= 270) || // bottom
                    (pixel_x >= 551 && pixel_x <= 569 && pixel_y >= 231 && pixel_y <= 240) || // middle
                    (pixel_x >= 541 && pixel_x <= 550 && pixel_y >= 251 && pixel_y <= 260) || // left dot
                    (pixel_x >= 541 && pixel_x <= 550 && pixel_y >= 211 && pixel_y <= 230) || // left top
                    (pixel_x >= 570 && pixel_x <= 579 && pixel_y >= 211 && pixel_y <= 260)    // right vertical
                ))
            ))
        ) begin
            red <= digit_red;   // Cycling colors for digits
            green <= digit_green;
            blue <= digit_blue;
        end
        // White stars on red semicircle
        else if (
            // Small stars (5x5)
            ((pixel_x >= 28 && pixel_x <= 32 && pixel_y == 50) || (pixel_x == 30 && pixel_y >= 48 && pixel_y <= 52)) || // (30, 50)
            ((pixel_x >= 48 && pixel_x <= 52 && pixel_y == 400) || (pixel_x == 50 && pixel_y >= 398 && pixel_y <= 402)) || // (50, 400)
            // Medium stars (7x7)
            ((pixel_x >= 67 && pixel_x <= 73 && pixel_y == 100) || (pixel_x == 70 && pixel_y >= 97 && pixel_y <= 103)) || // (70, 100)
            ((pixel_x >= 27 && pixel_x <= 33 && pixel_y == 350) || (pixel_x == 30 && pixel_y >= 347 && pixel_y <= 353)) || // (30, 350)
            // Large stars (9x9)
            ((pixel_x >= 46 && pixel_x <= 54 && pixel_y == 150) || (pixel_x == 50 && pixel_y >= 146 && pixel_y <= 154)) || // (50, 150)
            ((pixel_x >= 66 && pixel_x <= 74 && pixel_y == 300) || (pixel_x == 70 && pixel_y >= 296 && pixel_y <= 304)) ||
            // Small stars (5x5)
            ((pixel_x >= 578 && pixel_x <= 582 && pixel_y == 50) || (pixel_x == 580 && pixel_y >= 48 && pixel_y <= 52)) || // (580, 50)
            ((pixel_x >= 598 && pixel_x <= 602 && pixel_y == 400) || (pixel_x == 600 && pixel_y >= 398 && pixel_y <= 402)) || // (600, 400)
            // Medium stars (7x7)
            ((pixel_x >= 567 && pixel_x <= 573 && pixel_y == 100) || (pixel_x == 570 && pixel_y >= 97 && pixel_y <= 103)) || // (570, 100)
            ((pixel_x >= 587 && pixel_x <= 593 && pixel_y == 350) || (pixel_x == 590 && pixel_y >= 347 && pixel_y <= 353)) || // (590, 350)
            // Large stars (9x9)
            ((pixel_x >= 596 && pixel_x <= 604 && pixel_y == 150) || (pixel_x == 600 && pixel_y >= 146 && pixel_y <= 154)) || // (600, 150)
            ((pixel_x >= 576 && pixel_x <= 584 && pixel_y == 300) || (pixel_x == 580 && pixel_y >= 296 && pixel_y <= 304))   // (580, 300)
        ) begin
            red <= 4'hF;   // Red stars (#ff0000)
            green <= 4'h0;
            blue <= 4'h0;
        end
    end else begin
        // Video off: Black
        red <= 4'h0;
        green <= 4'h0;
        blue <= 4'h0;
    end
end

endmodule