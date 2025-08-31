`timescale 1ns / 1ps

module pixel_gen_game_screen(
    input clk_d, // 25 MHz pixel clock
    input [9:0] pixel_x,
    input [9:0] pixel_y,
    input video_on,
    input start_screen_active, // 1 if on start screen, 0 otherwise
    input S1, S2, S3, // Score increment inputs
    output reg [3:0] red = 0,
    output reg [3:0] green = 0,
    output reg [3:0] blue = 0,
    output reg timer_done = 0, // Add timer_done output
    output [16:0] score_out // Output the current score
);

// Bonus multiplier logic
reg [1:0] multiplier = 1; // Multiplier starts at 1x, max 3x
reg [25:0] multiplier_counter = 0; // Counter for 5-second timer
reg [2:0] multiplier_seconds = 5; // 5-second timer
wire multiplier_tick = (multiplier_counter == 26'd25_000_000); // 1 second at 25 MHz

// Color cycling control for score digits
reg [27:0] color_counter = 0;
reg [3:0] digit_red, digit_green, digit_blue;
localparam COLOR_CYCLE = 28'd125_000_000; // 5 s at 25 MHz
localparam PHASE_STEP = 28'd488_281;      // 125,000,000 / 256 for 256 hue steps

always @(posedge clk_d) begin
    if (start_screen_active) begin
        multiplier <= 1; // Reset multiplier on start screen
        multiplier_seconds <= 5; // Reset timer
        multiplier_counter <= 0; // Reset counter
    end
    else if (!timer_done) begin
        // Check for score increments of 250 or 400 (S2 or S3 rising edge)
        if ((S2_stable && !S2_prev) || (S3_stable && !S3_prev)) begin
            if (multiplier < 3) begin
                multiplier <= multiplier + 1; // Increment multiplier up to 3
            end
            multiplier_seconds <= 5; // Reset timer to 5 seconds
            multiplier_counter <= 0; // Reset counter
        end
        else begin
            // Multiplier timer countdown
            if (multiplier_counter < 26'd25_000_000) begin
                multiplier_counter <= multiplier_counter + 1;
            end
            else begin
                multiplier_counter <= 0;
                if (multiplier_seconds > 0) begin
                    multiplier_seconds <= multiplier_seconds - 1;
                end
                else if (multiplier > 1) begin
                    multiplier <= multiplier - 1; // Decrease multiplier by 1
                    multiplier_seconds <= 5; // Reset timer
                end
            end
        end
    end
end

// Timer control
reg [25:0] cycle_counter = 0;
reg [7:0] seconds = 120; // Start at 2 minutes (120 seconds)
wire second_tick = (cycle_counter == 26'd25_000_000); // 1 second at 25 MHz

// Timer update logic
always @(posedge clk_d) begin
    if (start_screen_active) begin
        seconds <= 120; // Reset to 2 minutes on start screen
        cycle_counter <= 0; // Reset counter
        timer_done <= 0; // Reset timer_done
    end
    else begin
        if (cycle_counter < 26'd25_000_000) begin
            cycle_counter <= cycle_counter + 1;
        end
        else begin
            cycle_counter <= 0;
            if (seconds > 0) begin
                seconds <= seconds - 1; // Decrement every second
            end
            else begin
                timer_done <= 1; // Set timer_done when seconds reach 0
            end
        end
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


reg [16:0] score = 0;
reg [19:0] debounce_counter = 0; // 20-bit counter for ~40ms debounce at 25 MHz
reg S1_stable = 0, S2_stable = 0, S3_stable = 0; // Debounced signals
reg S1_prev = 0, S2_prev = 0, S3_prev = 0; // Previous states for edge detection

assign score_out = score;

always @(posedge clk_d) begin
    // Debouncing logic: require stable input for ~40ms (1M cycles at 25 MHz)
    if (debounce_counter < 20'd1_000_000) begin
        debounce_counter <= debounce_counter + 1;
    end
    else begin
        debounce_counter <= 0;
        S1_stable <= S1;
        S2_stable <= S2;
        S3_stable <= S3;
    end

    // Score update logic
    if (start_screen_active) begin
        score <= 0; // Reset score on start screen
        S1_prev <= 1;
        S2_prev <= 1;
        S3_prev <= 1;
    end
    else if (!timer_done) begin
        // Process each button independently
        if (S1_stable && !S1_prev) begin // btnr
            if (score <= 99999 - 100 * multiplier) begin
                score <= score + 100 * multiplier; // Increment by 100 * multiplier
            end
            else begin
                score <= 99999; // Cap at 99999
            end
        end
        if (S2_stable && !S2_prev) begin // btnl
            if (score <= 99999 - 250 * multiplier) begin
                score <= score + 250 * multiplier; // Increment by 250 * multiplier
            end
            else begin
                score <= 99999; // Cap at 99999
            end
        end
        if (S3_stable && !S3_prev) begin // btnc
            if (score <= 99999 - 400 * multiplier) begin
                score <= score + 400 * multiplier; // Increment by 400 * multiplier
            end
            else begin
                score <= 99999; // Cap at 99999
            end
        end
        // Update previous states
        S1_prev <= S1_stable;
        S2_prev <= S2_stable;
        S3_prev <= S3_stable;
    end
end

// Compute digits for MM:SS
wire [3:0] min_tens = (seconds / 60) / 10; // Always 0 for 2 minutes
wire [3:0] min_ones = (seconds / 60) % 10;
wire [3:0] sec_tens = (seconds % 60) / 10;
wire [3:0] sec_ones = (seconds % 60) % 10;

// Compute digits for score (00000 to 99999)
wire [3:0] score_ten_thousands = (score / 10000) % 10; // 0 to 9
wire [3:0] score_thousands = (score / 1000) % 10;     // 0 to 9
wire [3:0] score_hundreds = (score / 100) % 10;       // 0 to 9
wire [3:0] score_tens = (score / 10) % 10;            // 0 to 9
wire [3:0] score_ones = score % 10;                   // 0 to 9

// Pixel generation
always @(posedge clk_d) begin
    if (video_on) begin
        // Timer text and score text
        if (
            // Timer: Minutes tens (x=215 to 255, y=30 to 100)
            (pixel_x >= 215 && pixel_x <= 255 && pixel_y >= 30 && pixel_y <= 100 && (
                (min_tens == 0 && (
                    // 0
                    (pixel_x >= 226 && pixel_x <= 245 && pixel_y >= 31 && pixel_y <= 40) || // top
                    (pixel_x >= 216 && pixel_x <= 225 && pixel_y >= 41 && pixel_y <= 90) || // left
                    (pixel_x >= 226 && pixel_x <= 245 && pixel_y >= 91 && pixel_y <= 100) || // bottom
                    (pixel_x >= 246 && pixel_x <= 255 && pixel_y >= 41 && pixel_y <= 90) || // right
                    (pixel_x >= 231 && pixel_x <= 240 && pixel_y >= 61 && pixel_y <= 70)    // middle
                ))
                // min_tens is always 0 for 2 minutes
            )) ||
            // Timer: Minutes ones (x=265 to 305, y=30 to 100)
            (pixel_x >= 265 && pixel_x <= 305 && pixel_y >= 30 && pixel_y <= 100 && (
                (min_ones == 0 && (
                    // 0
                    (pixel_x >= 276 && pixel_x <= 295 && pixel_y >= 31 && pixel_y <= 40) || // top
                    (pixel_x >= 266 && pixel_x <= 275 && pixel_y >= 41 && pixel_y <= 90) || // left
                    (pixel_x >= 276 && pixel_x <= 295 && pixel_y >= 91 && pixel_y <= 100) || // bottom
                    (pixel_x >= 296 && pixel_x <= 305 && pixel_y >= 41 && pixel_y <= 90) || // right
                    (pixel_x >= 281 && pixel_x <= 290 && pixel_y >= 61 && pixel_y <= 70)    // middle
                )) ||
                (min_ones == 1 && (
                    // 1
                    (pixel_x >= 281 && pixel_x <= 290 && pixel_y >= 31 && pixel_y <= 90) || // vertical
                    (pixel_x >= 266 && pixel_x <= 305 && pixel_y >= 91 && pixel_y <= 100) || // bottom
                    (pixel_x >= 271 && pixel_x <= 280 && pixel_y >= 41 && pixel_y <= 50)    // dot
                )) ||
                (min_ones == 2 && (
                    // 2
                    (pixel_x >= 276 && pixel_x <= 295 && pixel_y >= 31 && pixel_y <= 40) || // top
                    (pixel_x >= 266 && pixel_x <= 305 && pixel_y >= 91 && pixel_y <= 100) || // bottom
                    (pixel_x >= 266 && pixel_x <= 275 && pixel_y >= 41 && pixel_y <= 50) || // left top dot
                    (pixel_x >= 266 && pixel_x <= 275 && pixel_y >= 81 && pixel_y <= 90) || // left bottom dot
                    (pixel_x >= 296 && pixel_x <= 305 && pixel_y >= 41 && pixel_y <= 70) || // vertical
                    (pixel_x >= 276 && pixel_x <= 295 && pixel_y >= 71 && pixel_y <= 80)    // middle
                ))
                // Add more digits if needed (up to 2 for minutes)
            )) ||
            // Timer: Colon (x=315 to 325, y=30 to 100, centered at x=320)
            (
                (pixel_x >= 315 && pixel_x <= 325 && pixel_y >= 51 && pixel_y <= 60) || // upper dot
                (pixel_x >= 315 && pixel_x <= 325 && pixel_y >= 71 && pixel_y <= 80)    // lower dot
            ) ||
            // Timer: Seconds tens (x=335 to 375, y=30 to 100)
            (pixel_x >= 335 && pixel_x <= 375 && pixel_y >= 30 && pixel_y <= 100 && (
                (sec_tens == 0 && (
                    // 0
                    (pixel_x >= 346 && pixel_x <= 365 && pixel_y >= 31 && pixel_y <= 40) || // top
                    (pixel_x >= 336 && pixel_x <= 345 && pixel_y >= 41 && pixel_y <= 90) || // left
                    (pixel_x >= 346 && pixel_x <= 365 && pixel_y >= 91 && pixel_y <= 100) || // bottom
                    (pixel_x >= 366 && pixel_x <= 375 && pixel_y >= 41 && pixel_y <= 90) || // right
                    (pixel_x >= 351 && pixel_x <= 360 && pixel_y >= 61 && pixel_y <= 70)    // middle
                )) ||
                (sec_tens == 1 && (
                    // 1
                    (pixel_x >= 351 && pixel_x <= 360 && pixel_y >= 31 && pixel_y <= 90) || // vertical
                    (pixel_x >= 336 && pixel_x <= 375 && pixel_y >= 91 && pixel_y <= 100) || // bottom
                    (pixel_x >= 341 && pixel_x <= 350 && pixel_y >= 41 && pixel_y <= 50)    // dot
                )) ||
                (sec_tens == 2 && (
                    // 2
                    (pixel_x >= 346 && pixel_x <= 365 && pixel_y >= 31 && pixel_y <= 40) || // top
                    (pixel_x >= 336 && pixel_x <= 375 && pixel_y >= 91 && pixel_y <= 100) || // bottom
                    (pixel_x >= 336 && pixel_x <= 345 && pixel_y >= 41 && pixel_y <= 50) || // left top dot
                    (pixel_x >= 336 && pixel_x <= 345 && pixel_y >= 81 && pixel_y <= 90) || // left bottom dot
                    (pixel_x >= 366 && pixel_x <= 375 && pixel_y >= 41 && pixel_y <= 70) || // vertical
                    (pixel_x >= 346 && pixel_x <= 365 && pixel_y >= 71 && pixel_y <= 80)    // middle
                )) ||
                (sec_tens == 3 && (
                    // 3
                    (pixel_x >= 346 && pixel_x <= 365 && pixel_y >= 31 && pixel_y <= 40) || // top
                    (pixel_x >= 346 && pixel_x <= 365 && pixel_y >= 91 && pixel_y <= 100) || // bottom
                    (pixel_x >= 336 && pixel_x <= 345 && pixel_y >= 41 && pixel_y <= 50) || // left top dot
                    (pixel_x >= 336 && pixel_x <= 345 && pixel_y >= 81 && pixel_y <= 90) || // left bottom dot
                    (pixel_x >= 356 && pixel_x <= 365 && pixel_y >= 61 && pixel_y <= 70) || // right middle dot
                    (pixel_x >= 366 && pixel_x <= 375 && pixel_y >= 41 && pixel_y <= 60) || // vertical top
                    (pixel_x >= 366 && pixel_x <= 375 && pixel_y >= 71 && pixel_y <= 90)    // vertical bottom
                )) ||
                (sec_tens == 4 && (
                    // 4
                    (pixel_x >= 336 && pixel_x <= 345 && pixel_y >= 61 && pixel_y <= 70) || // dot1
                    (pixel_x >= 346 && pixel_x <= 355 && pixel_y >= 51 && pixel_y <= 60) || // dot2
                    (pixel_x >= 356 && pixel_x <= 365 && pixel_y >= 41 && pixel_y <= 50) || // dot3
                    (pixel_x >= 366 && pixel_x <= 375 && pixel_y >= 31 && pixel_y <= 100) || // right vertical
                    (pixel_x >= 336 && pixel_x <= 375 && pixel_y >= 71 && pixel_y <= 80)    // horizontal
                )) ||
                (sec_tens == 5 && (
                    // 5
                    (pixel_x >= 336 && pixel_x <= 375 && pixel_y >= 31 && pixel_y <= 40) || // top
                    (pixel_x >= 346 && pixel_x <= 365 && pixel_y >= 91 && pixel_y <= 100) || // bottom 
                    (pixel_x >= 336 && pixel_x <= 345 && pixel_y >= 41 && pixel_y <= 60) || // left vertical
                    (pixel_x >= 366 && pixel_x <= 375 && pixel_y >= 61 && pixel_y <= 90) || // right vertical
                    (pixel_x >= 346 && pixel_x <= 365 && pixel_y >= 51 && pixel_y <= 60) || // middle
                    (pixel_x >= 336 && pixel_x <= 345 && pixel_y >= 81 && pixel_y <= 90)    // left dot
                ))
            )) ||
            // Timer: Seconds ones (x=385 to 425, y=30 to 100)
            (pixel_x >= 385 && pixel_x <= 425 && pixel_y >= 30 && pixel_y <= 100 && (
                (sec_ones == 0 && (
                    // 0
                    (pixel_x >= 396 && pixel_x <= 415 && pixel_y >= 31 && pixel_y <= 40) || // top
                    (pixel_x >= 386 && pixel_x <= 395 && pixel_y >= 41 && pixel_y <= 90) || // left
                    (pixel_x >= 396 && pixel_x <= 415 && pixel_y >= 91 && pixel_y <= 100) || // bottom
                    (pixel_x >= 416 && pixel_x <= 425 && pixel_y >= 41 && pixel_y <= 90) || // right
                    (pixel_x >= 401 && pixel_x <= 410 && pixel_y >= 61 && pixel_y <= 70)    // middle
                )) ||
                (sec_ones == 1 && (
                    // 1
                    (pixel_x >= 401 && pixel_x <= 410 && pixel_y >= 31 && pixel_y <= 90) || // vertical
                    (pixel_x >= 386 && pixel_x <= 425 && pixel_y >= 91 && pixel_y <= 100) || // bottom
                    (pixel_x >= 391 && pixel_x <= 400 && pixel_y >= 41 && pixel_y <= 50)    // dot
                )) ||
                (sec_ones == 2 && (
                    // 2
                    (pixel_x >= 396 && pixel_x <= 415 && pixel_y >= 31 && pixel_y <= 40) || // top
                    (pixel_x >= 386 && pixel_x <= 425 && pixel_y >= 91 && pixel_y <= 100) || // bottom
                    (pixel_x >= 386 && pixel_x <= 395 && pixel_y >= 41 && pixel_y <= 50) || // left top dot
                    (pixel_x >= 386 && pixel_x <= 395 && pixel_y >= 81 && pixel_y <= 90) || // left bottom dot
                    (pixel_x >= 416 && pixel_x <= 425 && pixel_y >= 41 && pixel_y <= 70) || // vertical
                    (pixel_x >= 396 && pixel_x <= 415 && pixel_y >= 71 && pixel_y <= 80)    // middle
                )) ||
                (sec_ones == 3 && (
                    // 3
                    (pixel_x >= 396 && pixel_x <= 415 && pixel_y >= 31 && pixel_y <= 40) || // top
                    (pixel_x >= 396 && pixel_x <= 415 && pixel_y >= 91 && pixel_y <= 100) || // bottom
                    (pixel_x >= 386 && pixel_x <= 395 && pixel_y >= 41 && pixel_y <= 50) || // left top dot
                    (pixel_x >= 386 && pixel_x <= 395 && pixel_y >= 81 && pixel_y <= 90) || // left bottom dot
                    (pixel_x >= 406 && pixel_x <= 415 && pixel_y >= 61 && pixel_y <= 70) || // right middle dot
                    (pixel_x >= 416 && pixel_x <= 425 && pixel_y >= 41 && pixel_y <= 60) || // vertical top
                    (pixel_x >= 416 && pixel_x <= 425 && pixel_y >= 71 && pixel_y <= 90)    // vertical bottom
                )) ||
                (sec_ones == 4 && (
                    // 4
                    (pixel_x >= 386 && pixel_x <= 395 && pixel_y >= 61 && pixel_y <= 70) || // dot1
                    (pixel_x >= 396 && pixel_x <= 405 && pixel_y >= 51 && pixel_y <= 60) || // dot2
                    (pixel_x >= 406 && pixel_x <= 415 && pixel_y >= 41 && pixel_y <= 50) || // dot3
                    (pixel_x >= 416 && pixel_x <= 425 && pixel_y >= 31 && pixel_y <= 100) || // right vertical
                    (pixel_x >= 386 && pixel_x <= 425 && pixel_y >= 71 && pixel_y <= 80)    // horizontal
                )) ||
                (sec_ones == 5 && (
                    // 5
                    (pixel_x >= 386 && pixel_x <= 425 && pixel_y >= 31 && pixel_y <= 40) || // top
                    (pixel_x >= 396 && pixel_x <= 415 && pixel_y >= 91 && pixel_y <= 100) || // bottom 
                    (pixel_x >= 386 && pixel_x <= 395 && pixel_y >= 41 && pixel_y <= 60) || // left vertical
                    (pixel_x >= 416 && pixel_x <= 425 && pixel_y >= 61 && pixel_y <= 90) || // right vertical
                    (pixel_x >= 396 && pixel_x <= 415 && pixel_y >= 51 && pixel_y <= 60) || // middle
                    (pixel_x >= 386 && pixel_x <= 395 && pixel_y >= 81 && pixel_y <= 90)    // left dot
                )) ||
                (sec_ones == 6 && (
                    // 6
                    (pixel_x >= 396 && pixel_x <= 415 && pixel_y >= 31 && pixel_y <= 40) || // top
                    (pixel_x >= 396 && pixel_x <= 415 && pixel_y >= 91 && pixel_y <= 100) || // bottom
                    (pixel_x >= 396 && pixel_x <= 415 && pixel_y >= 61 && pixel_y <= 70) || // middle
                    (pixel_x >= 386 && pixel_x <= 395 && pixel_y >= 41 && pixel_y <= 90) || // left vertical
                    (pixel_x >= 416 && pixel_x <= 425 && pixel_y >= 71 && pixel_y <= 90) || // right vertical
                    (pixel_x >= 416 && pixel_x <= 425 && pixel_y >= 41 && pixel_y <= 50)    // right dot
                )) ||
                (sec_ones == 7 && (
                    // 7
                    (pixel_x >= 416 && pixel_x <= 425 && pixel_y >= 41 && pixel_y <= 70) || // right vertical
                    (pixel_x >= 406 && pixel_x <= 415 && pixel_y >= 70 && pixel_y <= 100) || // left vertical
                    (pixel_x >= 396 && pixel_x <= 415 && pixel_y >= 31 && pixel_y <= 40) || // top
                    (pixel_x >= 386 && pixel_x <= 395 && pixel_y >= 41 && pixel_y <= 50)    // left dot
                )) ||
                (sec_ones == 8 && (
                    // 8
                    (pixel_x >= 396 && pixel_x <= 415 && pixel_y >= 31 && pixel_y <= 40) || // top
                    (pixel_x >= 396 && pixel_x <= 415 && pixel_y >= 91 && pixel_y <= 100) || // bottom
                    (pixel_x >= 396 && pixel_x <= 415 && pixel_y >= 61 && pixel_y <= 70) || // middle
                    (pixel_x >= 386 && pixel_x <= 395 && pixel_y >= 41 && pixel_y <= 60) || // left bottom vertical
                    (pixel_x >= 386 && pixel_x <= 395 && pixel_y >= 71 && pixel_y <= 90) || // left top vertical
                    (pixel_x >= 416 && pixel_x <= 425 && pixel_y >= 41 && pixel_y <= 60) || // right bottom vertical
                    (pixel_x >= 416 && pixel_x <= 425 && pixel_y >= 71 && pixel_y <= 90)    // right top vertical
                )) ||
                (sec_ones == 9 && (
                    // 9
                    (pixel_x >= 396 && pixel_x <= 415 && pixel_y >= 31 && pixel_y <= 40) || // top
                    (pixel_x >= 396 && pixel_x <= 415 && pixel_y >= 91 && pixel_y <= 100) || // bottom
                    (pixel_x >= 396 && pixel_x <= 415 && pixel_y >= 61 && pixel_y <= 70) || // middle
                    (pixel_x >= 386 && pixel_x <= 395 && pixel_y >= 81 && pixel_y <= 90) || // left dot
                    (pixel_x >= 386 && pixel_x <= 395 && pixel_y >= 41 && pixel_y <= 60) || // left top
                    (pixel_x >= 416 && pixel_x <= 425 && pixel_y >= 41 && pixel_y <= 90)    // right vertical
                ))
            )) 
        ) begin
            if (multiplier > 2) begin
                red <= digit_red;   // Cycling colors for digits
                green <= digit_green;
                blue <= digit_blue;
            end
            else begin 
                red <= 4'hF;   // Red background (#ff0000)
                green <= 4'h0;
                blue <= 4'h0;
            end
        end
        // White rectangle behind timer (10-pixel margin around timer text)
        else if (pixel_x >= 212 && pixel_x <= 428 && pixel_y >= 20 && pixel_y <= 110 ||
                 pixel_x >= 205 && pixel_x <= 435 && pixel_y >= 27 && pixel_y <= 103) begin
            red <= 4'hF;   // White rectangle (#ffffff)
            green <= 4'hF;
            blue <= 4'hF;
        end
            // Score: S (x=50 to 90, y=200 to 270)
        else if ((
                (pixel_x >= 61 && pixel_x <= 80 && pixel_y >= 201 && pixel_y <= 210) || // top
                (pixel_x >= 61 && pixel_x <= 80 && pixel_y >= 261 && pixel_y <= 270) || // bottom
                (pixel_x >= 51 && pixel_x <= 60 && pixel_y >= 211 && pixel_y <= 230) || // left top
                (pixel_x >= 81 && pixel_x <= 90 && pixel_y >= 241 && pixel_y <= 260) || // right bottom
                (pixel_x >= 61 && pixel_x <= 80 && pixel_y >= 231 && pixel_y <= 240) || // middle
                (pixel_x >= 81 && pixel_x <= 90 && pixel_y >= 211 && pixel_y <= 220) || // rightmost dot
                (pixel_x >= 51 && pixel_x <= 60 && pixel_y >= 251 && pixel_y <= 260)    // leftmost dot
            ) ||
            // Score: C (x=100 to 140, y=200 to 270)
            (
                (pixel_x >= 111 && pixel_x <= 130 && pixel_y >= 201 && pixel_y <= 210) || // top
                (pixel_x >= 111 && pixel_x <= 130 && pixel_y >= 261 && pixel_y <= 270) || // bottom
                (pixel_x >= 101 && pixel_x <= 110 && pixel_y >= 211 && pixel_y <= 260) || // left
                (pixel_x >= 131 && pixel_x <= 140 && pixel_y >= 211 && pixel_y <= 220) || // top right dot
                (pixel_x >= 131 && pixel_x <= 140 && pixel_y >= 251 && pixel_y <= 260)    // bottom right dot
            ) ||
            // Score: O (x=150 to 190, y=200 to 270)
            (
                (pixel_x >= 161 && pixel_x <= 180 && pixel_y >= 201 && pixel_y <= 210) || // top
                (pixel_x >= 161 && pixel_x <= 180 && pixel_y >= 261 && pixel_y <= 270) || // bottom
                (pixel_x >= 151 && pixel_x <= 160 && pixel_y >= 211 && pixel_y <= 260) || // left
                (pixel_x >= 181 && pixel_x <= 190 && pixel_y >= 211 && pixel_y <= 260)    // right
            ) ||
            // Score: R (x=200 to 240, y=200 to 270)
            (
                (pixel_x >= 211 && pixel_x <= 230 && pixel_y >= 201 && pixel_y <= 210) || // top
                (pixel_x >= 201 && pixel_x <= 210 && pixel_y >= 201 && pixel_y <= 270) || // left
                (pixel_x >= 211 && pixel_x <= 230 && pixel_y >= 231 && pixel_y <= 240) || // middle
                (pixel_x >= 231 && pixel_x <= 240 && pixel_y >= 211 && pixel_y <= 230) || // right top vertical
                (pixel_x >= 231 && pixel_x <= 240 && pixel_y >= 241 && pixel_y <= 270)    // right bottom vertical
            ) ||
            // Score: E (x=250 to 290, y=200 to 270)
            (
                (pixel_x >= 261 && pixel_x <= 280 && pixel_y >= 201 && pixel_y <= 210) || // top
                (pixel_x >= 261 && pixel_x <= 280 && pixel_y >= 261 && pixel_y <= 270) || // bottom
                (pixel_x >= 251 && pixel_x <= 260 && pixel_y >= 211 && pixel_y <= 260) || // left
                (pixel_x >= 261 && pixel_x <= 275 && pixel_y >= 231 && pixel_y <= 240) || // middle
                (pixel_x >= 281 && pixel_x <= 290 && pixel_y >= 211 && pixel_y <= 220) || // top right dot
                (pixel_x >= 281 && pixel_x <= 290 && pixel_y >= 251 && pixel_y <= 260)    // bottom right dot
            ) ||
               // BONUS text below SCORE (x=50 to 290, y=300 to 370)
    // B (x=50 to 90, y=300 to 370)
    (pixel_x >= 50 && pixel_x <= 90 && pixel_y >= 300 && pixel_y <= 370 && (
        (pixel_x >= 51 && pixel_x <= 80 && pixel_y >= 301 && pixel_y <= 310) || // top
        (pixel_x >= 51 && pixel_x <= 60 && pixel_y >= 311 && pixel_y <= 360) || // left
        (pixel_x >= 51 && pixel_x <= 80 && pixel_y >= 361 && pixel_y <= 370) || // bottom
        (pixel_x >= 81 && pixel_x <= 90 && pixel_y >= 311 && pixel_y <= 330) || // right top
        (pixel_x >= 81 && pixel_x <= 90 && pixel_y >= 341 && pixel_y <= 360) || // right bottom
        (pixel_x >= 61 && pixel_x <= 80 && pixel_y >= 331 && pixel_y <= 340)    // middle
    )) ||
    // O (x=100 to 140, y=300 to 370)
    (pixel_x >= 100 && pixel_x <= 140 && pixel_y >= 300 && pixel_y <= 370 && (
        (pixel_x >= 111 && pixel_x <= 130 && pixel_y >= 301 && pixel_y <= 310) || // top
        (pixel_x >= 111 && pixel_x <= 130 && pixel_y >= 361 && pixel_y <= 370) || // bottom
        (pixel_x >= 101 && pixel_x <= 110 && pixel_y >= 311 && pixel_y <= 360) || // left
        (pixel_x >= 131 && pixel_x <= 140 && pixel_y >= 311 && pixel_y <= 360)    // right
    )) ||
    // N (x=150 to 190, y=300 to 370)
    (pixel_x >= 150 && pixel_x <= 190 && pixel_y >= 300 && pixel_y <= 370 && (
        (pixel_x >= 151 && pixel_x <= 160 && pixel_y >= 301 && pixel_y <= 370) || // left
        (pixel_x >= 181 && pixel_x <= 190 && pixel_y >= 301 && pixel_y <= 370) || // right
        (pixel_x >= 161 && pixel_x <= 170 && pixel_y >= 316 && pixel_y <= 335) || // diagonal top
        (pixel_x >= 171 && pixel_x <= 180 && pixel_y >= 336 && pixel_y <= 355) 
    )) ||
    // U (x=200 to 240, y=300 to 370)
    (pixel_x >= 200 && pixel_x <= 240 && pixel_y >= 300 && pixel_y <= 370 && (
        (pixel_x >= 201 && pixel_x <= 210 && pixel_y >= 301 && pixel_y <= 360) || // left
        (pixel_x >= 231 && pixel_x <= 240 && pixel_y >= 301 && pixel_y <= 360) || // right
        (pixel_x >= 211 && pixel_x <= 230 && pixel_y >= 361 && pixel_y <= 370)    // bottom
    )) ||
    // S (x=250 to 290, y=300 to 370)
    (pixel_x >= 250 && pixel_x <= 290 && pixel_y >= 300 && pixel_y <= 370 && (
        (pixel_x >= 261 && pixel_x <= 280 && pixel_y >= 301 && pixel_y <= 310) || // top
        (pixel_x >= 261 && pixel_x <= 280 && pixel_y >= 361 && pixel_y <= 370) || // bottom
        (pixel_x >= 251 && pixel_x <= 260 && pixel_y >= 311 && pixel_y <= 330) || // left top
        (pixel_x >= 281 && pixel_x <= 290 && pixel_y >= 341 && pixel_y <= 360) || // right bottom
        (pixel_x >= 261 && pixel_x <= 280 && pixel_y >= 331 && pixel_y <= 340) || // middle
        (pixel_x >= 281 && pixel_x <= 290 && pixel_y >= 311 && pixel_y <= 320) || // right top dot
        (pixel_x >= 251 && pixel_x <= 260 && pixel_y >= 351 && pixel_y <= 360)    // left bottom dot
    )) ||
                // Bonus: X (x=490 to 535, y=300 to 370)
(pixel_x >= 490 && pixel_x <= 535 && pixel_y >= 300 && pixel_y <= 370 && (
    // Left diagonal (top-left to bottom-right, thick segment)
    // (pixel_x >= 491 && pixel_x <= 499 && pixel_y >= 301 && pixel_y <= 314) || // top-left
    // (pixel_x >= 527 && pixel_x <= 535 && pixel_y >= 301 && pixel_y <= 314) || // bottom-left
    // Right diagonal (top-right to bottom-left, thick segment)
    (pixel_x >= 500 && pixel_x <= 508 && pixel_y >= 315 && pixel_y <= 328) || // top-right
    (pixel_x >= 518 && pixel_x <= 526 && pixel_y >= 315 && pixel_y <= 328) || // bottom-right
    (pixel_x >= 509 && pixel_x <= 517 && pixel_y >= 329 && pixel_y <= 342) ||
    (pixel_x >= 500 && pixel_x <= 508 && pixel_y >= 343 && pixel_y <= 356) ||
    (pixel_x >= 518 && pixel_x <= 526 && pixel_y >= 343 && pixel_y <= 356)
    // (pixel_x >= 491 && pixel_x <= 499 && pixel_y >= 357 && pixel_y <= 370) ||
    // (pixel_x >= 527 && pixel_x <= 535 && pixel_y >= 357 && pixel_y <= 370) 
)) ||
// Multiplier: Digit (x=540 to 579, y=300 to 370)
(pixel_x >= 540 && pixel_x <= 579 && pixel_y >= 300 && pixel_y <= 370 && (
    (multiplier == 1 && (
        // 1
        (pixel_x >= 556 && pixel_x <= 564 && pixel_y >= 301 && pixel_y <= 360) || // vertical
        (pixel_x >= 541 && pixel_x <= 579 && pixel_y >= 361 && pixel_y <= 370) || // bottom
        (pixel_x >= 546 && pixel_x <= 555 && pixel_y >= 311 && pixel_y <= 320)    // dot
    )) ||
    (multiplier == 2 && (
        // 2
        (pixel_x >= 551 && pixel_x <= 569 && pixel_y >= 301 && pixel_y <= 310) || // top
        (pixel_x >= 541 && pixel_x <= 579 && pixel_y >= 361 && pixel_y <= 370) || // bottom
        (pixel_x >= 541 && pixel_x <= 550 && pixel_y >= 311 && pixel_y <= 320) || // left top dot
        (pixel_x >= 541 && pixel_x <= 550 && pixel_y >= 351 && pixel_y <= 360) || // left bottom dot
        (pixel_x >= 570 && pixel_x <= 579 && pixel_y >= 311 && pixel_y <= 340) || // vertical
        (pixel_x >= 551 && pixel_x <= 569 && pixel_y >= 341 && pixel_y <= 350)    // middle
    )) ||
    (multiplier == 3 && (
        // 3
        (pixel_x >= 551 && pixel_x <= 569 && pixel_y >= 301 && pixel_y <= 310) || // top
        (pixel_x >= 551 && pixel_x <= 569 && pixel_y >= 361 && pixel_y <= 370) || // bottom
        (pixel_x >= 541 && pixel_x <= 550 && pixel_y >= 311 && pixel_y <= 320) || // left top dot
        (pixel_x >= 541 && pixel_x <= 550 && pixel_y >= 351 && pixel_y <= 360) || // left bottom dot
        (pixel_x >= 561 && pixel_x <= 569 && pixel_y >= 331 && pixel_y <= 340) || // right middle dot
        (pixel_x >= 570 && pixel_x <= 579 && pixel_y >= 311 && pixel_y <= 330) || // vertical top
        (pixel_x >= 570 && pixel_x <= 579 && pixel_y >= 341 && pixel_y <= 360)    // vertical bottom
    ))
)) ||
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
        (pixel_x >= 341 && pixel_x <= 350 && pixel_y >= 231 && pixel_y <= 240) || // dot1
        (pixel_x >= 351 && pixel_x <= 360 && pixel_y >= 221 && pixel_y <= 230) || // dot2
        (pixel_x >= 361 && pixel_x <= 370 && pixel_y >= 211 && pixel_y <= 220) || // dot3
        (pixel_x >= 371 && pixel_x <= 380 && pixel_y >= 201 && pixel_y <= 270) || // right vertical
        (pixel_x >= 341 && pixel_x <= 380 && pixel_y >= 241 && pixel_y <= 250)    // horizontal
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
        (pixel_x >= 391 && pixel_x <= 400 && pixel_y >= 231 && pixel_y <= 240) || // dot1
        (pixel_x >= 401 && pixel_x <= 410 && pixel_y >= 221 && pixel_y <= 230) || // dot2
        (pixel_x >= 411 && pixel_x <= 420 && pixel_y >= 211 && pixel_y <= 220) || // dot3
        (pixel_x >= 421 && pixel_x <= 430 && pixel_y >= 201 && pixel_y <= 270) || // right vertical
        (pixel_x >= 391 && pixel_x <= 430 && pixel_y >= 241 && pixel_y <= 250)    // horizontal
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
        (pixel_x >= 441 && pixel_x <= 450 && pixel_y >= 231 && pixel_y <= 240) || // dot1
        (pixel_x >= 451 && pixel_x <= 460 && pixel_y >= 221 && pixel_y <= 230) || // dot2
        (pixel_x >= 461 && pixel_x <= 470 && pixel_y >= 211 && pixel_y <= 220) || // dot3
        (pixel_x >= 471 && pixel_x <= 480 && pixel_y >= 201 && pixel_y <= 270) || // right vertical
        (pixel_x >= 441 && pixel_x <= 480 && pixel_y >= 241 && pixel_y <= 250)    // horizontal
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
        (pixel_x >= 491 && pixel_x <= 500 && pixel_y >= 231 && pixel_y <= 240) || // dot1
        (pixel_x >= 501 && pixel_x <= 510 && pixel_y >= 221 && pixel_y <= 230) || // dot2
        (pixel_x >= 511 && pixel_x <= 520 && pixel_y >= 211 && pixel_y <= 220) || // dot3
        (pixel_x >= 521 && pixel_x <= 530 && pixel_y >= 201 && pixel_y <= 270) || // right vertical
        (pixel_x >= 491 && pixel_x <= 530 && pixel_y >= 241 && pixel_y <= 250)    // horizontal
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
        (pixel_x >= 541 && pixel_x <= 550 && pixel_y >= 231 && pixel_y <= 240) || // dot1
        (pixel_x >= 551 && pixel_x <= 560 && pixel_y >= 221 && pixel_y <= 230) || // dot2
        (pixel_x >= 561 && pixel_x <= 570 && pixel_y >= 211 && pixel_y <= 220) || // dot3
        (pixel_x >= 571 && pixel_x <= 580 && pixel_y >= 201 && pixel_y <= 270) || // right vertical
        (pixel_x >= 541 && pixel_x <= 580 && pixel_y >= 241 && pixel_y <= 250)    // horizontal
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
))) begin
            red <= 4'hF;   // White text (#ffffff)
            green <= 4'hF;
            blue <= 4'hF;
        end
                // White stars on red bg
        else if (
            // Small stars (5x5)
            ((pixel_x >= 28 && pixel_x <= 32 && pixel_y == 50) || (pixel_x == 30 && pixel_y >= 48 && pixel_y <= 52)) || // (30, 50)
            ((pixel_x >= 48 && pixel_x <= 52 && pixel_y == 400) || (pixel_x == 50 && pixel_y >= 398 && pixel_y <= 402)) || // (50, 400)
            // Medium stars (7x7)
            ((pixel_x >= 67 && pixel_x <= 73 && pixel_y == 100) || (pixel_x == 70 && pixel_y >= 97 && pixel_y <= 103)) || // (70, 100)
            ((pixel_x >= 27 && pixel_x <= 33 && pixel_y == 350) || (pixel_x == 30 && pixel_y >= 347 && pixel_y <= 353)) || // (30, 350)
            // Large stars (9x9)
            ((pixel_x >= 46 && pixel_x <= 54 && pixel_y == 150) || (pixel_x == 50 && pixel_y >= 146 && pixel_y <= 154)) || // (50, 150)
//            ((pixel_x >= 66 && pixel_x <= 74 && pixel_y == 300) || (pixel_x == 70 && pixel_y >= 296 && pixel_y <= 304)) ||  // (70, 300)
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
            red <= 4'hF;   // White stars (#ffffff)
            green <= 4'hF;
            blue <= 4'hF;
          end
        else begin
            if (multiplier > 2) begin
                red <= digit_red;   // Cycling colors for digits
                green <= digit_green;
                blue <= digit_blue;
            end
            else begin 
                red <= 4'hF;   // Red background (#ff0000)
                green <= 4'h0;
                blue <= 4'h0;
            end
        end
    end
    else begin
        red <= 4'h0;   // Black when video is off
        green <= 4'h0;
        blue <= 4'h0;
    end
end

endmodule