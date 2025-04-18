`timescale 1ns / 1ps

module pixel_gen_game_screen(
    input clk_d, // 25 MHz pixel clock
    input [9:0] pixel_x,
    input [9:0] pixel_y,
    input video_on,
    output reg [3:0] red = 0,
    output reg [3:0] green = 0,
    output reg [3:0] blue = 0
);

// Timer control
reg [25:0] cycle_counter = 0;
reg [7:0] seconds = 120; // Start at 2 minutes (120 seconds)
wire second_tick = (cycle_counter == 26'd25_000_000); // 1 second at 25 MHz

// Timer update logic
always @(posedge clk_d) begin
    if (cycle_counter < 26'd25_000_000) begin
        cycle_counter <= cycle_counter + 1;
    end
    else begin
        cycle_counter <= 0;
        if (seconds > 0) begin
            seconds <= seconds - 1; // Decrement every second
        end
    end
end

// Compute digits for MM:SS
wire [3:0] min_tens = (seconds / 60) / 10; // Always 0 for 2 minutes
wire [3:0] min_ones = (seconds / 60) % 10;
wire [3:0] sec_tens = (seconds % 60) / 10;
wire [3:0] sec_ones = (seconds % 60) % 10;

// Pixel generation
always @(posedge clk_d) begin
    if (video_on) begin
        // Timer text (white, #ffffff)
        if (
            // Minutes tens (x=215 to 255, y=20 to 90)
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
            // Minutes ones (x=265 to 305, y=20 to 90)
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
            // Colon (x=315 to 325, y=20 to 90, centered at x=320)
            (
                (pixel_x >= 315 && pixel_x <= 325 && pixel_y >= 35 && pixel_y <= 45) || // upper dot
                (pixel_x >= 315 && pixel_x <= 325 && pixel_y >= 55 && pixel_y <= 65)    // lower dot
            ) ||
            // Seconds tens (x=335 to 375, y=20 to 90)
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
                    (pixel_x >= 336 && pixel_x <= 345 && pixel_y >= 31 && pixel_y <= 60) || // left vertical
                    (pixel_x >= 356 && pixel_x <= 365 && pixel_y >= 21 && pixel_y <= 90) || // right vertical
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
            // Seconds ones (x=385 to 425, y=20 to 90)
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
                    (pixel_x >= 386 && pixel_x <= 396 && pixel_y >= 31 && pixel_y <= 60) || // left vertical
                    (pixel_x >= 406 && pixel_x <= 415 && pixel_y >= 21 && pixel_y <= 90) || // right vertical
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
            ))
        ) begin
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