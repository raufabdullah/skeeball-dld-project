
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
            if (score <= 99999 - 100) begin
                score <= score + 100; // Increment by 100
            end
            else begin
                score <= 99999; // Cap at 99999
            end
        end
        if (S2_stable && !S2_prev) begin // btnl
            if (score <= 99999 - 250) begin
                score <= score + 250; // Increment by 250
            end
            else begin
                score <= 99999; // Cap at 99999
            end
        end
        if (S3_stable && !S3_prev) begin // btnc
            if (score <= 99999 - 400) begin
                score <= score + 400; // Increment by 400
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
        // Timer text and score text (white, #ffffff)
        if (
            // Timer: Minutes tens (x=215 to 255, y=20 to 90)
            (pixel_x >= 215 && pixel_x <= 255 && pixel_y >= 20 && pixel_y <= 90 && (
                (min_tens == 0 && (
                    // 0
                    (pixel_x >= 226 && pixel_x <= 245 && pixel_y >= 21 && pixel_y <= 30) || // top
                    (pixel_x >= 216 && pixel_x <= 225 && pixel_y >= 31 && pixel_y <= 80) || // left
                    (pixel_x >= 226 && pixel_x <= 245 && pixel_y >= 81 && pixel_y <= 90) || // bottom
                    (pixel_x >= 246 && pixel_x <= 255 && pixel_y >= 31 && pixel_y <= 80) || // right
                    (pixel_x >= 231 && pixel_x <= 240 && pixel_y >= 51 && pixel_y <= 60)    // middle
                ))
                // min_tens is always 0 for 2 minutes
            )) ||
            // Timer: Minutes ones (x=265 to 305, y=20 to 90)
            (pixel_x >= 265 && pixel_x <= 305 && pixel_y >= 20 && pixel_y <= 90 && (
                (min_ones == 0 && (
                    // 0
                    (pixel_x >= 276 && pixel_x <= 295 && pixel_y >= 21 && pixel_y <= 30) || // top
                    (pixel_x >= 266 && pixel_x <= 275 && pixel_y >= 31 && pixel_y <= 80) || // left
                    (pixel_x >= 276 && pixel_x <= 295 && pixel_y >= 81 && pixel_y <= 90) || // bottom
                    (pixel_x >= 296 && pixel_x <= 305 && pixel_y >= 31 && pixel_y <= 80) || // right
                    (pixel_x >= 281 && pixel_x <= 290 && pixel_y >= 51 && pixel_y <= 60)    // middle
                )) ||
                (min_ones == 1 && (
                    // 1
                    (pixel_x >= 281 && pixel_x <= 290 && pixel_y >= 21 && pixel_y <= 80) || // vertical
                    (pixel_x >= 266 && pixel_x <= 305 && pixel_y >= 81 && pixel_y <= 90) || // bottom
                    (pixel_x >= 271 && pixel_x <= 280 && pixel_y >= 31 && pixel_y <= 40)    // dot
                )) ||
                (min_ones == 2 && (
                    // 2
                    (pixel_x >= 276 && pixel_x <= 295 && pixel_y >= 21 && pixel_y <= 30) || // top
                    (pixel_x >= 266 && pixel_x <= 305 && pixel_y >= 81 && pixel_y <= 90) || // bottom
                    (pixel_x >= 266 && pixel_x <= 275 && pixel_y >= 31 && pixel_y <= 40) || // left top dot
                    (pixel_x >= 266 && pixel_x <= 275 && pixel_y >= 71 && pixel_y <= 80) || // left bottom dot
                    (pixel_x >= 296 && pixel_x <= 305 && pixel_y >= 31 && pixel_y <= 60) || // vertical
                    (pixel_x >= 276 && pixel_x <= 295 && pixel_y >= 61 && pixel_y <= 70)    // middle
                ))
                // Add more digits if needed (up to 2 for minutes)
            )) ||
            // Timer: Colon (x=315 to 325, y=20 to 90, centered at x=320)
            (
                (pixel_x >= 315 && pixel_x <= 325 && pixel_y >= 41 && pixel_y <= 50) || // upper dot
                (pixel_x >= 315 && pixel_x <= 325 && pixel_y >= 61 && pixel_y <= 70)    // lower dot
            ) ||
            // Timer: Seconds tens (x=335 to 375, y=20 to 90)
            (pixel_x >= 335 && pixel_x <= 375 && pixel_y >= 20 && pixel_y <= 90 && (
                (sec_tens == 0 && (
                    // 0
                    (pixel_x >= 346 && pixel_x <= 365 && pixel_y >= 21 && pixel_y <= 30) || // top
                    (pixel_x >= 336 && pixel_x <= 345 && pixel_y >= 31 && pixel_y <= 80) || // left
                    (pixel_x >= 346 && pixel_x <= 365 && pixel_y >= 81 && pixel_y <= 90) || // bottom
                    (pixel_x >= 366 && pixel_x <= 375 && pixel_y >= 31 && pixel_y <= 80) || // right
                    (pixel_x >= 351 && pixel_x <= 360 && pixel_y >= 51 && pixel_y <= 60)    // middle
                )) ||
                (sec_tens == 1 && (
                    // 1
                    (pixel_x >= 351 && pixel_x <= 360 && pixel_y >= 21 && pixel_y <= 80) || // vertical
                    (pixel_x >= 336 && pixel_x <= 375 && pixel_y >= 81 && pixel_y <= 90) || // bottom
                    (pixel_x >= 341 && pixel_x <= 350 && pixel_y >= 31 && pixel_y <= 40)    // dot
                )) ||
                (sec_tens == 2 && (
                    // 2
                    (pixel_x >= 346 && pixel_x <= 365 && pixel_y >= 21 && pixel_y <= 30) || // top
                    (pixel_x >= 336 && pixel_x <= 375 && pixel_y >= 81 && pixel_y <= 90) || // bottom
                    (pixel_x >= 336 && pixel_x <= 345 && pixel_y >= 31 && pixel_y <= 40) || // left top dot
                    (pixel_x >= 336 && pixel_x <= 345 && pixel_y >= 71 && pixel_y <= 80) || // left bottom dot
                    (pixel_x >= 366 && pixel_x <= 375 && pixel_y >= 31 && pixel_y <= 60) || // vertical
                    (pixel_x >= 346 && pixel_x <= 365 && pixel_y >= 61 && pixel_y <= 70)    // middle
                )) ||
                (sec_tens == 3 && (
                    // 3
                    (pixel_x >= 346 && pixel_x <= 365 && pixel_y >= 21 && pixel_y <= 30) || // top
                    (pixel_x >= 346 && pixel_x <= 365 && pixel_y >= 81 && pixel_y <= 90) || // bottom
                    (pixel_x >= 336 && pixel_x <= 345 && pixel_y >= 31 && pixel_y <= 40) || // left top dot
                    (pixel_x >= 336 && pixel_x <= 345 && pixel_y >= 71 && pixel_y <= 80) || // left bottom dot
                    (pixel_x >= 356 && pixel_x <= 365 && pixel_y >= 51 && pixel_y <= 60) || // right middle dot
                    (pixel_x >= 366 && pixel_x <= 375 && pixel_y >= 31 && pixel_y <= 50) || // vertical top
                    (pixel_x >= 366 && pixel_x <= 375 && pixel_y >= 61 && pixel_y <= 80)    // vertical bottom
                )) ||
                (sec_tens == 4 && (
                    // 4
                    (pixel_x >= 336 && pixel_x <= 345 && pixel_y >= 51 && pixel_y <= 60) || // dot1
                    (pixel_x >= 346 && pixel_x <= 355 && pixel_y >= 41 && pixel_y <= 50) || // dot2
                    (pixel_x >= 356 && pixel_x <= 365 && pixel_y >= 31 && pixel_y <= 40) || // dot3
                    (pixel_x >= 366 && pixel_x <= 375 && pixel_y >= 21 && pixel_y <= 90) || // right vertical
                    (pixel_x >= 336 && pixel_x <= 375 && pixel_y >= 61 && pixel_y <= 70)    // horizontal
                )) ||
                (sec_tens == 5 && (
                    // 5
                    (pixel_x >= 336 && pixel_x <= 375 && pixel_y >= 21 && pixel_y <= 30) || // top
                    (pixel_x >= 346 && pixel_x <= 365 && pixel_y >= 81 && pixel_y <= 90) || // bottom 
                    (pixel_x >= 336 && pixel_x <= 345 && pixel_y >= 31 && pixel_y <= 50) || // left vertical
                    (pixel_x >= 366 && pixel_x <= 375 && pixel_y >= 51 && pixel_y <= 80) || // right vertical
                    (pixel_x >= 346 && pixel_x <= 365 && pixel_y >= 41 && pixel_y <= 50) || // middle
                    (pixel_x >= 336 && pixel_x <= 345 && pixel_y >= 71 && pixel_y <= 80)    // left dot
                ))
            )) ||
            // Timer: Seconds ones (x=385 to 425, y=20 to 90)
            (pixel_x >= 385 && pixel_x <= 425 && pixel_y >= 20 && pixel_y <= 90 && (
                (sec_ones == 0 && (
                    // 0
                    (pixel_x >= 396 && pixel_x <= 415 && pixel_y >= 21 && pixel_y <= 30) || // top
                    (pixel_x >= 386 && pixel_x <= 395 && pixel_y >= 31 && pixel_y <= 80) || // left
                    (pixel_x >= 396 && pixel_x <= 415 && pixel_y >= 81 && pixel_y <= 90) || // bottom
                    (pixel_x >= 416 && pixel_x <= 425 && pixel_y >= 31 && pixel_y <= 80) || // right
                    (pixel_x >= 401 && pixel_x <= 410 && pixel_y >= 51 && pixel_y <= 60)    // middle
                )) ||
                (sec_ones == 1 && (
                    // 1
                    (pixel_x >= 401 && pixel_x <= 410 && pixel_y >= 21 && pixel_y <= 80) || // vertical
                    (pixel_x >= 386 && pixel_x <= 425 && pixel_y >= 81 && pixel_y <= 90) || // bottom
                    (pixel_x >= 391 && pixel_x <= 400 && pixel_y >= 31 && pixel_y <= 40)    // dot
                )) ||
                (sec_ones == 2 && (
                    // 2
                    (pixel_x >= 396 && pixel_x <= 415 && pixel_y >= 21 && pixel_y <= 30) || // top
                    (pixel_x >= 386 && pixel_x <= 425 && pixel_y >= 81 && pixel_y <= 90) || // bottom
                    (pixel_x >= 386 && pixel_x <= 395 && pixel_y >= 31 && pixel_y <= 40) || // left top dot
                    (pixel_x >= 386 && pixel_x <= 395 && pixel_y >= 71 && pixel_y <= 80) || // left bottom dot
                    (pixel_x >= 416 && pixel_x <= 425 && pixel_y >= 31 && pixel_y <= 60) || // vertical
                    (pixel_x >= 396 && pixel_x <= 415 && pixel_y >= 61 && pixel_y <= 70)    // middle
                )) ||
                (sec_ones == 3 && (
                    // 3
                    (pixel_x >= 396 && pixel_x <= 415 && pixel_y >= 21 && pixel_y <= 30) || // top
                    (pixel_x >= 396 && pixel_x <= 415 && pixel_y >= 81 && pixel_y <= 90) || // bottom
                    (pixel_x >= 386 && pixel_x <= 395 && pixel_y >= 31 && pixel_y <= 40) || // left top dot
                    (pixel_x >= 386 && pixel_x <= 395 && pixel_y >= 71 && pixel_y <= 80) || // left bottom dot
                    (pixel_x >= 406 && pixel_x <= 415 && pixel_y >= 51 && pixel_y <= 60) || // right middle dot
                    (pixel_x >= 416 && pixel_x <= 425 && pixel_y >= 31 && pixel_y <= 50) || // vertical top
                    (pixel_x >= 416 && pixel_x <= 425 && pixel_y >= 61 && pixel_y <= 80)    // vertical bottom
                )) ||
                (sec_ones == 4 && (
                    // 4
                    (pixel_x >= 386 && pixel_x <= 395 && pixel_y >= 51 && pixel_y <= 60) || // dot1
                    (pixel_x >= 396 && pixel_x <= 405 && pixel_y >= 41 && pixel_y <= 50) || // dot2
                    (pixel_x >= 406 && pixel_x <= 415 && pixel_y >= 31 && pixel_y <= 40) || // dot3
                    (pixel_x >= 416 && pixel_x <= 425 && pixel_y >= 21 && pixel_y <= 90) || // right vertical
                    (pixel_x >= 386 && pixel_x <= 425 && pixel_y >= 61 && pixel_y <= 70)    // horizontal
                )) ||
                (sec_ones == 5 && (
                    // 5
                    (pixel_x >= 386 && pixel_x <= 425 && pixel_y >= 21 && pixel_y <= 30) || // top
                    (pixel_x >= 396 && pixel_x <= 415 && pixel_y >= 81 && pixel_y <= 90) || // bottom 
                    (pixel_x >= 386 && pixel_x <= 395 && pixel_y >= 31 && pixel_y <= 50) || // left vertical
                    (pixel_x >= 416 && pixel_x <= 425 && pixel_y >= 51 && pixel_y <= 80) || // right vertical
                    (pixel_x >= 396 && pixel_x <= 415 && pixel_y >= 41 && pixel_y <= 50) || // middle
                    (pixel_x >= 386 && pixel_x <= 395 && pixel_y >= 71 && pixel_y <= 80)    // left dot
                )) ||
                (sec_ones == 6 && (
                    // 6
                    (pixel_x >= 396 && pixel_x <= 415 && pixel_y >= 21 && pixel_y <= 30) || // top
                    (pixel_x >= 396 && pixel_x <= 415 && pixel_y >= 81 && pixel_y <= 90) || // bottom
                    (pixel_x >= 396 && pixel_x <= 415 && pixel_y >= 51 && pixel_y <= 60) || // middle
                    (pixel_x >= 386 && pixel_x <= 395 && pixel_y >= 31 && pixel_y <= 80) || // left vertical
                    (pixel_x >= 416 && pixel_x <= 425 && pixel_y >= 61 && pixel_y <= 80) || // right vertical
                    (pixel_x >= 416 && pixel_x <= 425 && pixel_y >= 31 && pixel_y <= 40)    // right dot
                )) ||
                (sec_ones == 7 && (
                    // 7
                    (pixel_x >= 416 && pixel_x <= 425 && pixel_y >= 31 && pixel_y <= 60) || // right vertical
                    (pixel_x >= 406 && pixel_x <= 415 && pixel_y >= 60 && pixel_y <= 90) || // left vertical
                    (pixel_x >= 396 && pixel_x <= 415 && pixel_y >= 21 && pixel_y <= 30) || // top
                    (pixel_x >= 386 && pixel_x <= 395 && pixel_y >= 31 && pixel_y <= 40)    // left dot
                )) ||
                (sec_ones == 8 && (
                    // 8
                    (pixel_x >= 396 && pixel_x <= 415 && pixel_y >= 21 && pixel_y <= 30) || // top
                    (pixel_x >= 396 && pixel_x <= 415 && pixel_y >= 81 && pixel_y <= 90) || // bottom
                    (pixel_x >= 396 && pixel_x <= 415 && pixel_y >= 51 && pixel_y <= 60) || // middle
                    (pixel_x >= 386 && pixel_x <= 395 && pixel_y >= 31 && pixel_y <= 50) || // left bottom vertical
                    (pixel_x >= 386 && pixel_x <= 395 && pixel_y >= 61 && pixel_y <= 80) || // left top vertical
                    (pixel_x >= 416 && pixel_x <= 425 && pixel_y >= 31 && pixel_y <= 50) || // right bottom vertical
                    (pixel_x >= 416 && pixel_x <= 425 && pixel_y >= 61 && pixel_y <= 80)    // right top vertical
                )) ||
                (sec_ones == 9 && (
                    // 9
                    (pixel_x >= 396 && pixel_x <= 415 && pixel_y >= 21 && pixel_y <= 30) || // top
                    (pixel_x >= 396 && pixel_x <= 415 && pixel_y >= 81 && pixel_y <= 90) || // bottom
                    (pixel_x >= 396 && pixel_x <= 415 && pixel_y >= 51 && pixel_y <= 60) || // middle
                    (pixel_x >= 386 && pixel_x <= 395 && pixel_y >= 71 && pixel_y <= 80) || // left dot
                    (pixel_x >= 386 && pixel_x <= 395 && pixel_y >= 31 && pixel_y <= 50) || // left top
                    (pixel_x >= 416 && pixel_x <= 425 && pixel_y >= 31 && pixel_y <= 80)    // right vertical
                ))
            )) ||
            // Score: S (x=50 to 90, y=200 to 270)
            (
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
                (pixel_x >= 261 && pixel_x <= 280 && pixel_y >= 231 && pixel_y <= 240) || // middle
                (pixel_x >= 281 && pixel_x <= 290 && pixel_y >= 211 && pixel_y <= 220) || // top right dot
                (pixel_x >= 281 && pixel_x <= 290 && pixel_y >= 251 && pixel_y <= 260)    // bottom right dot
            ) ||
            // Score: Ten thousands digit (x=340 to 380, y=200 to 270)
    (pixel_x >= 340 && pixel_x <= 380 && pixel_y >= 200 && pixel_y <= 270 && (
    (score_ten_thousands == 0 && (
        // 0
        (pixel_x >= 351 && pixel_x <= 370 && pixel_y >= 201 && pixel_y <= 210) || // top
        (pixel_x >= 341 && pixel_x <= 350 && pixel_y >= 211 && pixel_y <= 260) || // left
        (pixel_x >= 351 && pixel_x <= 370 && pixel_y >= 261 && pixel_y <= 270) || // bottom
        (pixel_x >= 371 && pixel_x <= 380 && pixel_y >= 211 && pixel_y <= 260) || // right
        (pixel_x >= 356 && pixel_x <= 365 && pixel_y >= 231 && pixel_y <= 240)    // middle
    )) ||
    (score_ten_thousands == 1 && (
        // 1
        (pixel_x >= 356 && pixel_x <= 365 && pixel_y >= 201 && pixel_y <= 260) || // vertical
        (pixel_x >= 341 && pixel_x <= 380 && pixel_y >= 261 && pixel_y <= 270) || // bottom
        (pixel_x >= 346 && pixel_x <= 355 && pixel_y >= 211 && pixel_y <= 220)    // dot
    )) ||
    (score_ten_thousands == 2 && (
        // 2
        (pixel_x >= 351 && pixel_x <= 370 && pixel_y >= 201 && pixel_y <= 210) || // top
        (pixel_x >= 341 && pixel_x <= 380 && pixel_y >= 261 && pixel_y <= 270) || // bottom
        (pixel_x >= 341 && pixel_x <= 350 && pixel_y >= 211 && pixel_y <= 220) || // left top dot
        (pixel_x >= 341 && pixel_x <= 350 && pixel_y >= 251 && pixel_y <= 260) || // left bottom dot
        (pixel_x >= 371 && pixel_x <= 380 && pixel_y >= 211 && pixel_y <= 240) || // vertical
        (pixel_x >= 351 && pixel_x <= 370 && pixel_y >= 241 && pixel_y <= 250)    // middle
    )) ||
    (score_ten_thousands == 3 && (
        // 3
        (pixel_x >= 351 && pixel_x <= 370 && pixel_y >= 201 && pixel_y <= 210) || // top
        (pixel_x >= 351 && pixel_x <= 370 && pixel_y >= 261 && pixel_y <= 270) || // bottom
        (pixel_x >= 341 && pixel_x <= 350 && pixel_y >= 211 && pixel_y <= 220) || // left top dot
        (pixel_x >= 341 && pixel_x <= 350 && pixel_y >= 251 && pixel_y <= 260) || // left bottom dot
        (pixel_x >= 361 && pixel_x <= 370 && pixel_y >= 231 && pixel_y <= 240) || // right middle dot
        (pixel_x >= 371 && pixel_x <= 380 && pixel_y >= 211 && pixel_y <= 230) || // vertical top
        (pixel_x >= 371 && pixel_x <= 380 && pixel_y >= 241 && pixel_y <= 260)    // vertical bottom
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
        (pixel_x >= 341 && pixel_x <= 380 && pixel_y >= 201 && pixel_y <= 210) || // top
        (pixel_x >= 351 && pixel_x <= 370 && pixel_y >= 261 && pixel_y <= 270) || // bottom 
        (pixel_x >= 341 && pixel_x <= 350 && pixel_y >= 211 && pixel_y <= 230) || // left vertical
        (pixel_x >= 371 && pixel_x <= 380 && pixel_y >= 231 && pixel_y <= 260) || // right vertical
        (pixel_x >= 351 && pixel_x <= 370 && pixel_y >= 221 && pixel_y <= 230) || // middle
        (pixel_x >= 341 && pixel_x <= 350 && pixel_y >= 251 && pixel_y <= 260)    // left dot
    )) ||
    (score_ten_thousands == 6 && (
        // 6
        (pixel_x >= 351 && pixel_x <= 370 && pixel_y >= 201 && pixel_y <= 210) || // top
        (pixel_x >= 351 && pixel_x <= 370 && pixel_y >= 261 && pixel_y <= 270) || // bottom
        (pixel_x >= 351 && pixel_x <= 370 && pixel_y >= 231 && pixel_y <= 240) || // middle
        (pixel_x >= 341 && pixel_x <= 350 && pixel_y >= 211 && pixel_y <= 260) || // left vertical
        (pixel_x >= 371 && pixel_x <= 380 && pixel_y >= 241 && pixel_y <= 260) || // right vertical
        (pixel_x >= 371 && pixel_x <= 380 && pixel_y >= 211 && pixel_y <= 220)    // right dot
    )) ||
    (score_ten_thousands == 7 && (
        // 7
        (pixel_x >= 371 && pixel_x <= 380 && pixel_y >= 211 && pixel_y <= 240) || // right vertical
        (pixel_x >= 361 && pixel_x <= 370 && pixel_y >= 240 && pixel_y <= 270) || // left vertical
        (pixel_x >= 351 && pixel_x <= 370 && pixel_y >= 201 && pixel_y <= 210) || // top
        (pixel_x >= 341 && pixel_x <= 350 && pixel_y >= 211 && pixel_y <= 220)    // left dot
    )) ||
    (score_ten_thousands == 8 && (
        // 8
        (pixel_x >= 351 && pixel_x <= 370 && pixel_y >= 201 && pixel_y <= 210) || // top
        (pixel_x >= 351 && pixel_x <= 370 && pixel_y >= 261 && pixel_y <= 270) || // bottom
        (pixel_x >= 351 && pixel_x <= 370 && pixel_y >= 231 && pixel_y <= 240) || // middle
        (pixel_x >= 341 && pixel_x <= 350 && pixel_y >= 211 && pixel_y <= 230) || // left bottom vertical
        (pixel_x >= 341 && pixel_x <= 350 && pixel_y >= 241 && pixel_y <= 260) || // left top vertical
        (pixel_x >= 371 && pixel_x <= 380 && pixel_y >= 211 && pixel_y <= 230) || // right bottom vertical
        (pixel_x >= 371 && pixel_x <= 380 && pixel_y >= 241 && pixel_y <= 260)    // right top vertical
    )) ||
    (score_ten_thousands == 9 && (
        // 9
        (pixel_x >= 351 && pixel_x <= 370 && pixel_y >= 201 && pixel_y <= 210) || // top
        (pixel_x >= 351 && pixel_x <= 370 && pixel_y >= 261 && pixel_y <= 270) || // bottom
        (pixel_x >= 351 && pixel_x <= 370 && pixel_y >= 231 && pixel_y <= 240) || // middle
        (pixel_x >= 341 && pixel_x <= 350 && pixel_y >= 251 && pixel_y <= 260) || // left dot
        (pixel_x >= 341 && pixel_x <= 350 && pixel_y >= 211 && pixel_y <= 230) || // left top
        (pixel_x >= 371 && pixel_x <= 380 && pixel_y >= 211 && pixel_y <= 260)    // right vertical
    ))
)) ||
// Score: Thousands digit (x=390 to 430, y=200 to 270)
(pixel_x >= 390 && pixel_x <= 430 && pixel_y >= 200 && pixel_y <= 270 && (
    (score_thousands == 0 && (
        // 0
        (pixel_x >= 401 && pixel_x <= 420 && pixel_y >= 201 && pixel_y <= 210) || // top
        (pixel_x >= 391 && pixel_x <= 400 && pixel_y >= 211 && pixel_y <= 260) || // left
        (pixel_x >= 401 && pixel_x <= 420 && pixel_y >= 261 && pixel_y <= 270) || // bottom
        (pixel_x >= 421 && pixel_x <= 430 && pixel_y >= 211 && pixel_y <= 260) || // right
        (pixel_x >= 406 && pixel_x <= 415 && pixel_y >= 231 && pixel_y <= 240)    // middle
    )) ||
    (score_thousands == 1 && (
        // 1
        (pixel_x >= 406 && pixel_x <= 415 && pixel_y >= 201 && pixel_y <= 260) || // vertical
        (pixel_x >= 391 && pixel_x <= 430 && pixel_y >= 261 && pixel_y <= 270) || // bottom
        (pixel_x >= 396 && pixel_x <= 405 && pixel_y >= 211 && pixel_y <= 220)    // dot
    )) ||
    (score_thousands == 2 && (
        // 2
        (pixel_x >= 401 && pixel_x <= 420 && pixel_y >= 201 && pixel_y <= 210) || // top
        (pixel_x >= 391 && pixel_x <= 430 && pixel_y >= 261 && pixel_y <= 270) || // bottom
        (pixel_x >= 391 && pixel_x <= 400 && pixel_y >= 211 && pixel_y <= 220) || // left top dot
        (pixel_x >= 391 && pixel_x <= 400 && pixel_y >= 251 && pixel_y <= 260) || // left bottom dot
        (pixel_x >= 421 && pixel_x <= 430 && pixel_y >= 211 && pixel_y <= 240) || // vertical
        (pixel_x >= 401 && pixel_x <= 420 && pixel_y >= 241 && pixel_y <= 250)    // middle
    )) ||
    (score_thousands == 3 && (
        // 3
        (pixel_x >= 401 && pixel_x <= 420 && pixel_y >= 201 && pixel_y <= 210) || // top
        (pixel_x >= 401 && pixel_x <= 420 && pixel_y >= 261 && pixel_y <= 270) || // bottom
        (pixel_x >= 391 && pixel_x <= 400 && pixel_y >= 211 && pixel_y <= 220) || // left top dot
        (pixel_x >= 391 && pixel_x <= 400 && pixel_y >= 251 && pixel_y <= 260) || // left bottom dot
        (pixel_x >= 411 && pixel_x <= 420 && pixel_y >= 231 && pixel_y <= 240) || // right middle dot
        (pixel_x >= 421 && pixel_x <= 430 && pixel_y >= 211 && pixel_y <= 230) || // vertical top
        (pixel_x >= 421 && pixel_x <= 430 && pixel_y >= 241 && pixel_y <= 260)    // vertical bottom
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
        (pixel_x >= 391 && pixel_x <= 430 && pixel_y >= 201 && pixel_y <= 210) || // top
        (pixel_x >= 401 && pixel_x <= 420 && pixel_y >= 261 && pixel_y <= 270) || // bottom 
        (pixel_x >= 391 && pixel_x <= 400 && pixel_y >= 211 && pixel_y <= 230) || // left vertical
        (pixel_x >= 421 && pixel_x <= 430 && pixel_y >= 231 && pixel_y <= 260) || // right vertical
        (pixel_x >= 401 && pixel_x <= 420 && pixel_y >= 221 && pixel_y <= 230) || // middle
        (pixel_x >= 391 && pixel_x <= 400 && pixel_y >= 251 && pixel_y <= 260)    // left dot
    )) ||
    (score_thousands == 6 && (
        // 6
        (pixel_x >= 401 && pixel_x <= 420 && pixel_y >= 201 && pixel_y <= 210) || // top
        (pixel_x >= 401 && pixel_x <= 420 && pixel_y >= 261 && pixel_y <= 270) || // bottom
        (pixel_x >= 401 && pixel_x <= 420 && pixel_y >= 231 && pixel_y <= 240) || // middle
        (pixel_x >= 391 && pixel_x <= 400 && pixel_y >= 211 && pixel_y <= 260) || // left vertical
        (pixel_x >= 421 && pixel_x <= 430 && pixel_y >= 241 && pixel_y <= 260) || // right vertical
        (pixel_x >= 421 && pixel_x <= 430 && pixel_y >= 211 && pixel_y <= 220)    // right dot
    )) ||
    (score_thousands == 7 && (
        // 7
        (pixel_x >= 421 && pixel_x <= 430 && pixel_y >= 211 && pixel_y <= 240) || // right vertical
        (pixel_x >= 411 && pixel_x <= 420 && pixel_y >= 240 && pixel_y <= 270) || // left vertical
        (pixel_x >= 401 && pixel_x <= 420 && pixel_y >= 201 && pixel_y <= 210) || // top
        (pixel_x >= 391 && pixel_x <= 400 && pixel_y >= 211 && pixel_y <= 220)    // left dot
    )) ||
    (score_thousands == 8 && (
        // 8
        (pixel_x >= 401 && pixel_x <= 420 && pixel_y >= 201 && pixel_y <= 210) || // top
        (pixel_x >= 401 && pixel_x <= 420 && pixel_y >= 261 && pixel_y <= 270) || // bottom
        (pixel_x >= 401 && pixel_x <= 420 && pixel_y >= 231 && pixel_y <= 240) || // middle
        (pixel_x >= 391 && pixel_x <= 400 && pixel_y >= 211 && pixel_y <= 230) || // left bottom vertical
        (pixel_x >= 391 && pixel_x <= 400 && pixel_y >= 241 && pixel_y <= 260) || // left top vertical
        (pixel_x >= 421 && pixel_x <= 430 && pixel_y >= 211 && pixel_y <= 230) || // right bottom vertical
        (pixel_x >= 421 && pixel_x <= 430 && pixel_y >= 241 && pixel_y <= 260)    // right top vertical
    )) ||
    (score_thousands == 9 && (
        // 9
        (pixel_x >= 401 && pixel_x <= 420 && pixel_y >= 201 && pixel_y <= 210) || // top
        (pixel_x >= 401 && pixel_x <= 420 && pixel_y >= 261 && pixel_y <= 270) || // bottom
        (pixel_x >= 401 && pixel_x <= 420 && pixel_y >= 231 && pixel_y <= 240) || // middle
        (pixel_x >= 391 && pixel_x <= 400 && pixel_y >= 251 && pixel_y <= 260) || // left dot
        (pixel_x >= 391 && pixel_x <= 400 && pixel_y >= 211 && pixel_y <= 230) || // left top
        (pixel_x >= 421 && pixel_x <= 430 && pixel_y >= 211 && pixel_y <= 260)    // right vertical
    ))
)) ||
// Score: Hundreds digit (x=440 to 480, y=200 to 270)
(pixel_x >= 440 && pixel_x <= 480 && pixel_y >= 200 && pixel_y <= 270 && (
    (score_hundreds == 0 && (
        // 0
        (pixel_x >= 451 && pixel_x <= 470 && pixel_y >= 201 && pixel_y <= 210) || // top
        (pixel_x >= 441 && pixel_x <= 450 && pixel_y >= 211 && pixel_y <= 260) || // left
        (pixel_x >= 451 && pixel_x <= 470 && pixel_y >= 261 && pixel_y <= 270) || // bottom
        (pixel_x >= 471 && pixel_x <= 480 && pixel_y >= 211 && pixel_y <= 260) || // right
        (pixel_x >= 456 && pixel_x <= 465 && pixel_y >= 231 && pixel_y <= 240)    // middle
    )) ||
    (score_hundreds == 1 && (
        // 1
        (pixel_x >= 456 && pixel_x <= 465 && pixel_y >= 201 && pixel_y <= 260) || // vertical
        (pixel_x >= 441 && pixel_x <= 480 && pixel_y >= 261 && pixel_y <= 270) || // bottom
        (pixel_x >= 446 && pixel_x <= 455 && pixel_y >= 211 && pixel_y <= 220)    // dot
    )) ||
    (score_hundreds == 2 && (
        // 2
        (pixel_x >= 451 && pixel_x <= 470 && pixel_y >= 201 && pixel_y <= 210) || // top
        (pixel_x >= 441 && pixel_x <= 480 && pixel_y >= 261 && pixel_y <= 270) || // bottom
        (pixel_x >= 441 && pixel_x <= 450 && pixel_y >= 211 && pixel_y <= 220) || // left top dot
        (pixel_x >= 441 && pixel_x <= 450 && pixel_y >= 251 && pixel_y <= 260) || // left bottom dot
        (pixel_x >= 471 && pixel_x <= 480 && pixel_y >= 211 && pixel_y <= 240) || // vertical
        (pixel_x >= 451 && pixel_x <= 470 && pixel_y >= 241 && pixel_y <= 250)    // middle
    )) ||
    (score_hundreds == 3 && (
        // 3
        (pixel_x >= 451 && pixel_x <= 470 && pixel_y >= 201 && pixel_y <= 210) || // top
        (pixel_x >= 451 && pixel_x <= 470 && pixel_y >= 261 && pixel_y <= 270) || // bottom
        (pixel_x >= 441 && pixel_x <= 450 && pixel_y >= 211 && pixel_y <= 220) || // left top dot
        (pixel_x >= 441 && pixel_x <= 450 && pixel_y >= 251 && pixel_y <= 260) || // left bottom dot
        (pixel_x >= 461 && pixel_x <= 470 && pixel_y >= 231 && pixel_y <= 240) || // right middle dot
        (pixel_x >= 471 && pixel_x <= 480 && pixel_y >= 211 && pixel_y <= 230) || // vertical top
        (pixel_x >= 471 && pixel_x <= 480 && pixel_y >= 241 && pixel_y <= 260)    // vertical bottom
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
        (pixel_x >= 441 && pixel_x <= 480 && pixel_y >= 201 && pixel_y <= 210) || // top
        (pixel_x >= 451 && pixel_x <= 470 && pixel_y >= 261 && pixel_y <= 270) || // bottom 
        (pixel_x >= 441 && pixel_x <= 450 && pixel_y >= 211 && pixel_y <= 230) || // left vertical
        (pixel_x >= 471 && pixel_x <= 480 && pixel_y >= 231 && pixel_y <= 260) || // right vertical
        (pixel_x >= 451 && pixel_x <= 470 && pixel_y >= 221 && pixel_y <= 230) || // middle
        (pixel_x >= 441 && pixel_x <= 450 && pixel_y >= 251 && pixel_y <= 260)    // left dot
    )) ||
    (score_hundreds == 6 && (
        // 6
        (pixel_x >= 451 && pixel_x <= 470 && pixel_y >= 201 && pixel_y <= 210) || // top
        (pixel_x >= 451 && pixel_x <= 470 && pixel_y >= 261 && pixel_y <= 270) || // bottom
        (pixel_x >= 451 && pixel_x <= 470 && pixel_y >= 231 && pixel_y <= 240) || // middle
        (pixel_x >= 441 && pixel_x <= 450 && pixel_y >= 211 && pixel_y <= 260) || // left vertical
        (pixel_x >= 471 && pixel_x <= 480 && pixel_y >= 241 && pixel_y <= 260) || // right vertical
        (pixel_x >= 471 && pixel_x <= 480 && pixel_y >= 211 && pixel_y <= 220)    // right dot
    )) ||
    (score_hundreds == 7 && (
        // 7
        (pixel_x >= 471 && pixel_x <= 480 && pixel_y >= 211 && pixel_y <= 240) || // right vertical
        (pixel_x >= 461 && pixel_x <= 470 && pixel_y >= 240 && pixel_y <= 270) || // left vertical
        (pixel_x >= 451 && pixel_x <= 470 && pixel_y >= 201 && pixel_y <= 210) || // top
        (pixel_x >= 441 && pixel_x <= 450 && pixel_y >= 211 && pixel_y <= 220)    // left dot
    )) ||
    (score_hundreds == 8 && (
        // 8
        (pixel_x >= 451 && pixel_x <= 470 && pixel_y >= 201 && pixel_y <= 210) || // top
        (pixel_x >= 451 && pixel_x <= 470 && pixel_y >= 261 && pixel_y <= 270) || // bottom
        (pixel_x >= 451 && pixel_x <= 470 && pixel_y >= 231 && pixel_y <= 240) || // middle
        (pixel_x >= 441 && pixel_x <= 450 && pixel_y >= 211 && pixel_y <= 230) || // left bottom vertical
        (pixel_x >= 441 && pixel_x <= 450 && pixel_y >= 241 && pixel_y <= 260) || // left top vertical
        (pixel_x >= 471 && pixel_x <= 480 && pixel_y >= 211 && pixel_y <= 230) || // right bottom vertical
        (pixel_x >= 471 && pixel_x <= 480 && pixel_y >= 241 && pixel_y <= 260)    // right top vertical
    )) ||
    (score_hundreds == 9 && (
        // 9
        (pixel_x >= 451 && pixel_x <= 470 && pixel_y >= 201 && pixel_y <= 210) || // top
        (pixel_x >= 451 && pixel_x <= 470 && pixel_y >= 261 && pixel_y <= 270) || // bottom
        (pixel_x >= 451 && pixel_x <= 470 && pixel_y >= 231 && pixel_y <= 240) || // middle
        (pixel_x >= 441 && pixel_x <= 450 && pixel_y >= 251 && pixel_y <= 260) || // left dot
        (pixel_x >= 441 && pixel_x <= 450 && pixel_y >= 211 && pixel_y <= 230) || // left top
        (pixel_x >= 471 && pixel_x <= 480 && pixel_y >= 211 && pixel_y <= 260)    // right vertical
    ))
)) ||
// Score: Tens digit (x=490 to 530, y=200 to 270)
(pixel_x >= 490 && pixel_x <= 530 && pixel_y >= 200 && pixel_y <= 270 && (
    (score_tens == 0 && (
        // 0
        (pixel_x >= 501 && pixel_x <= 520 && pixel_y >= 201 && pixel_y <= 210) || // top
        (pixel_x >= 491 && pixel_x <= 500 && pixel_y >= 211 && pixel_y <= 260) || // left
        (pixel_x >= 501 && pixel_x <= 520 && pixel_y >= 261 && pixel_y <= 270) || // bottom
        (pixel_x >= 521 && pixel_x <= 530 && pixel_y >= 211 && pixel_y <= 260) || // right
        (pixel_x >= 506 && pixel_x <= 515 && pixel_y >= 231 && pixel_y <= 240)    // middle
    )) ||
    (score_tens == 1 && (
        // 1
        (pixel_x >= 506 && pixel_x <= 515 && pixel_y >= 201 && pixel_y <= 260) || // vertical
        (pixel_x >= 491 && pixel_x <= 530 && pixel_y >= 261 && pixel_y <= 270) || // bottom
        (pixel_x >= 496 && pixel_x <= 504 && pixel_y >= 211 && pixel_y <= 220)    // dot
    )) ||
    (score_tens == 2 && (
        // 2
        (pixel_x >= 501 && pixel_x <= 520 && pixel_y >= 201 && pixel_y <= 210) || // top
        (pixel_x >= 491 && pixel_x <= 530 && pixel_y >= 261 && pixel_y <= 270) || // bottom
        (pixel_x >= 491 && pixel_x <= 500 && pixel_y >= 211 && pixel_y <= 220) || // left top dot
        (pixel_x >= 491 && pixel_x <= 500 && pixel_y >= 251 && pixel_y <= 260) || // left bottom dot
        (pixel_x >= 521 && pixel_x <= 530 && pixel_y >= 211 && pixel_y <= 240) || // vertical
        (pixel_x >= 501 && pixel_x <= 520 && pixel_y >= 241 && pixel_y <= 250)    // middle
    )) ||
    (score_tens == 3 && (
        // 3
        (pixel_x >= 501 && pixel_x <= 520 && pixel_y >= 201 && pixel_y <= 210) || // top
        (pixel_x >= 501 && pixel_x <= 520 && pixel_y >= 261 && pixel_y <= 270) || // bottom
        (pixel_x >= 491 && pixel_x <= 500 && pixel_y >= 211 && pixel_y <= 220) || // left top dot
        (pixel_x >= 491 && pixel_x <= 500 && pixel_y >= 251 && pixel_y <= 260) || // left bottom dot
        (pixel_x >= 511 && pixel_x <= 520 && pixel_y >= 231 && pixel_y <= 240) || // right middle dot
        (pixel_x >= 521 && pixel_x <= 530 && pixel_y >= 211 && pixel_y <= 230) || // vertical top
        (pixel_x >= 521 && pixel_x <= 530 && pixel_y >= 241 && pixel_y <= 260)    // vertical bottom
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
        (pixel_x >= 491 && pixel_x <= 530 && pixel_y >= 201 && pixel_y <= 210) || // top
        (pixel_x >= 501 && pixel_x <= 520 && pixel_y >= 261 && pixel_y <= 270) || // bottom 
        (pixel_x >= 491 && pixel_x <= 500 && pixel_y >= 211 && pixel_y <= 230) || // left vertical
        (pixel_x >= 521 && pixel_x <= 530 && pixel_y >= 231 && pixel_y <= 260) || // right vertical
        (pixel_x >= 501 && pixel_x <= 520 && pixel_y >= 221 && pixel_y <= 230) || // middle
        (pixel_x >= 491 && pixel_x <= 500 && pixel_y >= 251 && pixel_y <= 260)    // left dot
    )) ||
    (score_tens == 6 && (
        // 6
        (pixel_x >= 501 && pixel_x <= 520 && pixel_y >= 201 && pixel_y <= 210) || // top
        (pixel_x >= 501 && pixel_x <= 520 && pixel_y >= 261 && pixel_y <= 270) || // bottom
        (pixel_x >= 501 && pixel_x <= 520 && pixel_y >= 231 && pixel_y <= 240) || // middle
        (pixel_x >= 491 && pixel_x <= 500 && pixel_y >= 211 && pixel_y <= 260) || // left vertical
        (pixel_x >= 521 && pixel_x <= 530 && pixel_y >= 241 && pixel_y <= 260) || // right vertical
        (pixel_x >= 521 && pixel_x <= 530 && pixel_y >= 211 && pixel_y <= 220)    // right dot
    )) ||
    (score_tens == 7 && (
        // 7
        (pixel_x >= 521 && pixel_x <= 530 && pixel_y >= 211 && pixel_y <= 240) || // right vertical
        (pixel_x >= 511 && pixel_x <= 520 && pixel_y >= 240 && pixel_y <= 270) || // left vertical
        (pixel_x >= 501 && pixel_x <= 520 && pixel_y >= 201 && pixel_y <= 210) || // top
        (pixel_x >= 491 && pixel_x <= 500 && pixel_y >= 211 && pixel_y <= 220)    // left dot
    )) ||
    (score_tens == 8 && (
        // 8
        (pixel_x >= 501 && pixel_x <= 520 && pixel_y >= 201 && pixel_y <= 210) || // top
        (pixel_x >= 501 && pixel_x <= 520 && pixel_y >= 261 && pixel_y <= 270) || // bottom
        (pixel_x >= 501 && pixel_x <= 520 && pixel_y >= 231 && pixel_y <= 240) || // middle
        (pixel_x >= 491 && pixel_x <= 500 && pixel_y >= 211 && pixel_y <= 230) || // left bottom vertical
        (pixel_x >= 491 && pixel_x <= 500 && pixel_y >= 241 && pixel_y <= 260) || // left top vertical
        (pixel_x >= 521 && pixel_x <= 530 && pixel_y >= 211 && pixel_y <= 230) || // right bottom vertical
        (pixel_x >= 521 && pixel_x <= 530 && pixel_y >= 241 && pixel_y <= 260)    // right top vertical
    )) ||
    (score_tens == 9 && (
        // 9
        (pixel_x >= 501 && pixel_x <= 520 && pixel_y >= 201 && pixel_y <= 210) || // top
        (pixel_x >= 501 && pixel_x <= 520 && pixel_y >= 261 && pixel_y <= 270) || // bottom
        (pixel_x >= 501 && pixel_x <= 520 && pixel_y >= 231 && pixel_y <= 240) || // middle
        (pixel_x >= 491 && pixel_x <= 500 && pixel_y >= 251 && pixel_y <= 260) || // left dot
        (pixel_x >= 491 && pixel_x <= 500 && pixel_y >= 211 && pixel_y <= 230) || // left top
        (pixel_x >= 521 && pixel_x <= 530 && pixel_y >= 211 && pixel_y <= 260)    // right vertical
    ))
)) ||
// Score: Ones digit (x=540 to 580, y=200 to 270)
(pixel_x >= 540 && pixel_x <= 580 && pixel_y >= 200 && pixel_y <= 270 && (
    (score_ones == 0 && (
        // 0
        (pixel_x >= 551 && pixel_x <= 570 && pixel_y >= 201 && pixel_y <= 210) || // top
        (pixel_x >= 541 && pixel_x <= 550 && pixel_y >= 211 && pixel_y <= 260) || // left
        (pixel_x >= 551 && pixel_x <= 570 && pixel_y >= 261 && pixel_y <= 270) || // bottom
        (pixel_x >= 571 && pixel_x <= 580 && pixel_y >= 211 && pixel_y <= 260) || // right
        (pixel_x >= 556 && pixel_x <= 565 && pixel_y >= 231 && pixel_y <= 240)    // middle
    )) ||
    (score_ones == 1 && (
        // 1
        (pixel_x >= 556 && pixel_x <= 565 && pixel_y >= 201 && pixel_y <= 260) || // vertical
        (pixel_x >= 541 && pixel_x <= 580 && pixel_y >= 261 && pixel_y <= 270) || // bottom
        (pixel_x >= 546 && pixel_x <= 554 && pixel_y >= 211 && pixel_y <= 220)    // dot
    )) ||
    (score_ones == 2 && (
        // 2
        (pixel_x >= 551 && pixel_x <= 570 && pixel_y >= 201 && pixel_y <= 210) || // top
        (pixel_x >= 541 && pixel_x <= 580 && pixel_y >= 261 && pixel_y <= 270) || // bottom
        (pixel_x >= 541 && pixel_x <= 550 && pixel_y >= 211 && pixel_y <= 220) || // left top dot
        (pixel_x >= 541 && pixel_x <= 550 && pixel_y >= 251 && pixel_y <= 260) || // left bottom dot
        (pixel_x >= 571 && pixel_x <= 580 && pixel_y >= 211 && pixel_y <= 240) || // vertical
        (pixel_x >= 551 && pixel_x <= 570 && pixel_y >= 241 && pixel_y <= 250)    // middle
    )) ||
    (score_ones == 3 && (
        // 3
        (pixel_x >= 551 && pixel_x <= 570 && pixel_y >= 201 && pixel_y <= 210) || // top
        (pixel_x >= 551 && pixel_x <= 570 && pixel_y >= 261 && pixel_y <= 270) || // bottom
        (pixel_x >= 541 && pixel_x <= 550 && pixel_y >= 211 && pixel_y <= 220) || // left top dot
        (pixel_x >= 541 && pixel_x <= 550 && pixel_y >= 251 && pixel_y <= 260) || // left bottom dot
        (pixel_x >= 561 && pixel_x <= 570 && pixel_y >= 231 && pixel_y <= 240) || // right middle dot
        (pixel_x >= 571 && pixel_x <= 580 && pixel_y >= 211 && pixel_y <= 230) || // vertical top
        (pixel_x >= 571 && pixel_x <= 580 && pixel_y >= 241 && pixel_y <= 260)    // vertical bottom
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
        (pixel_x >= 541 && pixel_x <= 580 && pixel_y >= 201 && pixel_y <= 210) || // top
        (pixel_x >= 551 && pixel_x <= 570 && pixel_y >= 261 && pixel_y <= 270) || // bottom 
        (pixel_x >= 541 && pixel_x <= 550 && pixel_y >= 211 && pixel_y <= 230) || // left vertical
        (pixel_x >= 571 && pixel_x <= 580 && pixel_y >= 231 && pixel_y <= 260) || // right vertical
        (pixel_x >= 551 && pixel_x <= 570 && pixel_y >= 221 && pixel_y <= 230) || // middle
        (pixel_x >= 541 && pixel_x <= 550 && pixel_y >= 251 && pixel_y <= 260)    // left dot
    )) ||
    (score_ones == 6 && (
        // 6
        (pixel_x >= 551 && pixel_x <= 570 && pixel_y >= 201 && pixel_y <= 210) || // top
        (pixel_x >= 551 && pixel_x <= 570 && pixel_y >= 261 && pixel_y <= 270) || // bottom
        (pixel_x >= 551 && pixel_x <= 570 && pixel_y >= 231 && pixel_y <= 240) || // middle
        (pixel_x >= 541 && pixel_x <= 550 && pixel_y >= 211 && pixel_y <= 260) || // left vertical
        (pixel_x >= 571 && pixel_x <= 580 && pixel_y >= 241 && pixel_y <= 260) || // right vertical
        (pixel_x >= 571 && pixel_x <= 580 && pixel_y >= 211 && pixel_y <= 220)    // right dot
    )) ||
    (score_ones == 7 && (
        // 7
        (pixel_x >= 571 && pixel_x <= 580 && pixel_y >= 211 && pixel_y <= 240) || // right vertical
        (pixel_x >= 561 && pixel_x <= 570 && pixel_y >= 240 && pixel_y <= 270) || // left vertical
        (pixel_x >= 551 && pixel_x <= 570 && pixel_y >= 201 && pixel_y <= 210) || // top
        (pixel_x >= 541 && pixel_x <= 550 && pixel_y >= 211 && pixel_y <= 220)    // left dot
    )) ||
    (score_ones == 8 && (
        // 8
        (pixel_x >= 551 && pixel_x <= 570 && pixel_y >= 201 && pixel_y <= 210) || // top
        (pixel_x >= 551 && pixel_x <= 570 && pixel_y >= 261 && pixel_y <= 270) || // bottom
        (pixel_x >= 551 && pixel_x <= 570 && pixel_y >= 231 && pixel_y <= 240) || // middle
        (pixel_x >= 541 && pixel_x <= 550 && pixel_y >= 211 && pixel_y <= 230) || // left bottom vertical
        (pixel_x >= 541 && pixel_x <= 550 && pixel_y >= 241 && pixel_y <= 260) || // left top vertical
        (pixel_x >= 571 && pixel_x <= 580 && pixel_y >= 211 && pixel_y <= 230) || // right bottom vertical
        (pixel_x >= 571 && pixel_x <= 580 && pixel_y >= 241 && pixel_y <= 260)    // right top vertical
    )) ||
    (score_ones == 9 && (
        // 9
        (pixel_x >= 551 && pixel_x <= 570 && pixel_y >= 201 && pixel_y <= 210) || // top
        (pixel_x >= 551 && pixel_x <= 570 && pixel_y >= 261 && pixel_y <= 270) || // bottom
        (pixel_x >= 551 && pixel_x <= 570 && pixel_y >= 231 && pixel_y <= 240) || // middle
        (pixel_x >= 541 && pixel_x <= 550 && pixel_y >= 251 && pixel_y <= 260) || // left dot
        (pixel_x >= 541 && pixel_x <= 550 && pixel_y >= 211 && pixel_y <= 230) || // left top
        (pixel_x >= 571 && pixel_x <= 580 && pixel_y >= 211 && pixel_y <= 260)    // right vertical
    ))
))) begin
            red <= 4'hF;   // White text (#ffffff)
            green <= 4'hF;
            blue <= 4'hF;
        end
        else begin
            red <= 4'hF;   // Red background (#ff0000)
            green <= 4'h0;
            blue <= 4'h0;
        end
    end
    else begin
        red <= 4'h0;   // Black when video is off
        green <= 4'h0;
        blue <= 4'h0;
    end
end

endmodule