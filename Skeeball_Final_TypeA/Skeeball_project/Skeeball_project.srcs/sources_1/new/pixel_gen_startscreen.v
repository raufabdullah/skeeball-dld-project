`timescale 1ns / 1ps

module pixel_gen_start_screen(
    input clk_d, // pixel clock
    input [9:0] pixel_x,
    input [9:0] pixel_y,
    input video_on,
    output reg [3:0] red = 0,
    output reg [3:0] green = 0,
    output reg [3:0] blue = 0
);

// Blink control
reg [25:0] blink_counter = 0;
reg blink = 1;
localparam ON_TIME = 26'd18_750_000;  // 0.75 s at 25 MHz (0.75 s / 40 ns)
localparam TOTAL_CYCLE = 26'd31_250_000;  // 1.25 s at 25 MHz (1.25 s / 40 ns)

// Blink counter logic
always @(posedge clk_d) begin
    if (blink_counter < TOTAL_CYCLE - 1) begin
        blink_counter <= blink_counter + 1;
        if (blink_counter < ON_TIME) begin
            blink <= 1;  // Text on for 0.75 s
        end
        else begin
            blink <= 0;  // Text off for 0.5 s
        end
    end
    else begin
        blink_counter <= 0;
        blink <= 1;  // Restart cycle with text on
    end
end

always @(posedge clk_d) begin
    if (video_on) begin
        // Red text for "BALL" (#ff0000)
        if (blink && (
            // B (x = 325 to 365)
            (pixel_x >= 326 && pixel_x <= 335 && pixel_y >= 175 && pixel_y <= 244) || // leftmost
            (pixel_x >= 336 && pixel_x <= 355 && pixel_y >= 175 && pixel_y <= 184) || // middle1
            (pixel_x >= 336 && pixel_x <= 355 && pixel_y >= 205 && pixel_y <= 214) || // middle2
            (pixel_x >= 336 && pixel_x <= 355 && pixel_y >= 235 && pixel_y <= 244) || // middle3
            (pixel_x >= 356 && pixel_x <= 365 && pixel_y >= 185 && pixel_y <= 204) || // rightmost upper
            (pixel_x >= 356 && pixel_x <= 365 && pixel_y >= 215 && pixel_y <= 234) || // rightmost lower

            // A (x = 375 to 415)
            (pixel_x >= 386 && pixel_x <= 405 && pixel_y >= 175 && pixel_y <= 184) || // top
            (pixel_x >= 376 && pixel_x <= 385 && pixel_y >= 185 && pixel_y <= 244) || // left
            (pixel_x >= 386 && pixel_x <= 405 && pixel_y >= 215 && pixel_y <= 224) || // middle
            (pixel_x >= 406 && pixel_x <= 415 && pixel_y >= 185 && pixel_y <= 244) || // right

            // L (x = 425 to 465)
            (pixel_x >= 426 && pixel_x <= 435 && pixel_y >= 175 && pixel_y <= 234) || // vertical
            (pixel_x >= 436 && pixel_x <= 465 && pixel_y >= 235 && pixel_y <= 244) || // bottom

            // L (x = 475 to 515)
            (pixel_x >= 476 && pixel_x <= 485 && pixel_y >= 175 && pixel_y <= 234) || // vertical
            (pixel_x >= 486 && pixel_x <= 515 && pixel_y >= 235 && pixel_y <= 244)  // bottom
        )) begin
            red <= 4'hF;   // Fully red text (#ff0000)
            green <= 4'h0;
            blue <= 4'h0;
        end
        // White text for "SKEE" (#ffffff)
        else if (blink && (
            // S (x = 125 to 165)
            (pixel_x >= 136 && pixel_x <= 155 && pixel_y >= 175 && pixel_y <= 184) || // top
            (pixel_x >= 126 && pixel_x <= 135 && pixel_y >= 185 && pixel_y <= 204) || // left
            (pixel_x >= 136 && pixel_x <= 155 && pixel_y >= 205 && pixel_y <= 214) || // middle
            (pixel_x >= 156 && pixel_x <= 165 && pixel_y >= 215 && pixel_y <= 234) || // right lower
            (pixel_x >= 136 && pixel_x <= 155 && pixel_y >= 235 && pixel_y <= 244) || // bottom
            (pixel_x >= 156 && pixel_x <= 165 && pixel_y >= 185 && pixel_y <= 194) || // rightmost dot
            (pixel_x >= 126 && pixel_x <= 135 && pixel_y >= 225 && pixel_y <= 234) || // leftmost dot

            // K (x = 175 to 215)
            (pixel_x >= 176 && pixel_x <= 185 && pixel_y >= 175 && pixel_y <= 244) || // vertical
            (pixel_x >= 186 && pixel_x <= 195 && pixel_y >= 205 && pixel_y <= 214) || // middle cross
            (pixel_x >= 196 && pixel_x <= 205 && pixel_y >= 195 && pixel_y <= 204) || // upper first diagonal
            (pixel_x >= 196 && pixel_x <= 205 && pixel_y >= 215 && pixel_y <= 224) || // lower first diagonal
            (pixel_x >= 206 && pixel_x <= 213 && pixel_y >= 175 && pixel_y <= 194) || // upper second diagonal
            (pixel_x >= 206 && pixel_x <= 213 && pixel_y >= 225 && pixel_y <= 244) || // lower second diagonal

            // E (x = 225 to 265)
            (pixel_x >= 236 && pixel_x <= 255 && pixel_y >= 175 && pixel_y <= 184) || // top
            (pixel_x >= 226 && pixel_x <= 235 && pixel_y >= 185 && pixel_y <= 214) || // topleft
            (pixel_x >= 236 && pixel_x <= 250 && pixel_y >= 205 && pixel_y <= 214) || // middle
            (pixel_x >= 226 && pixel_x <= 235 && pixel_y >= 215 && pixel_y <= 234) || // bottomleft
            (pixel_x >= 236 && pixel_x <= 255 && pixel_y >= 235 && pixel_y <= 244) || // bottom
            (pixel_x >= 256 && pixel_x <= 265 && pixel_y >= 185 && pixel_y <= 194) || // top right dot
            (pixel_x >= 256 && pixel_x <= 265 && pixel_y >= 225 && pixel_y <= 234) || // bottom right dot

            // E (x = 275 to 315)
            (pixel_x >= 286 && pixel_x <= 305 && pixel_y >= 175 && pixel_y <= 184) || // top
            (pixel_x >= 276 && pixel_x <= 285 && pixel_y >= 185 && pixel_y <= 214) || // topleft
            (pixel_x >= 286 && pixel_x <= 300 && pixel_y >= 205 && pixel_y <= 214) || // middle
            (pixel_x >= 276 && pixel_x <= 285 && pixel_y >= 215 && pixel_y <= 234) || // bottomleft
            (pixel_x >= 286 && pixel_x <= 305 && pixel_y >= 235 && pixel_y <= 244) || // bottom
            (pixel_x >= 306 && pixel_x <= 315 && pixel_y >= 185 && pixel_y <= 194) || // top right dot
            (pixel_x >= 306 && pixel_x <= 315 && pixel_y >= 225 && pixel_y <= 234)   // bottom right dot
        )) begin
            red <= 4'hF;   // White text (#ffffff)
            green <= 4'hF;
            blue <= 4'hF;
        end
        else begin
            if (pixel_x <= 320) begin
                red <= 4'hF;   // White background (#ffffff)
                green <= 4'h0;
                blue <= 4'h0;
            end
            else begin
                red <= 4'hF;   // White background (#ffffff)
                green <= 4'hF;
                blue <= 4'hF;
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