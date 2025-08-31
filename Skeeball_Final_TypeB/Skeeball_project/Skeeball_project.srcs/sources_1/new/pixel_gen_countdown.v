`timescale 1ns / 1ps

module pixel_gen_countdown(
    input clk_d,
    input [9:0] pixel_x,
    input [9:0] pixel_y,
    input video_on,
    input [1:0] countdown_state, // 0: "3", 1: "2", 2: "1", 3: "GO"
    output reg [3:0] red = 0,
    output reg [3:0] green = 0,
    output reg [3:0] blue = 0
);

always @(posedge clk_d) begin
    if (video_on) begin
        // Default colors based on countdown_state
        if (countdown_state == 0 || countdown_state == 2) begin // "3" or "1": Red background
            red <= 4'hF;
            green <= 4'h0;
            blue <= 4'h0;
        end else begin // "2" or "GO": White background
            red <= 4'hF;
            green <= 4'hF;
            blue <= 4'hF;
        end

        // Draw numbers, "GO", and hollow rings
        if (countdown_state == 0) begin // "3" (white text, centered at x=290-349, y=182-287, scaled up)
            if (
                (pixel_x >= 306 && pixel_x <= 339 && pixel_y >= 182 && pixel_y <= 197) || // top
                (pixel_x >= 306 && pixel_x <= 339 && pixel_y >= 272 && pixel_y <= 287) || // bottom
                (pixel_x >= 290 && pixel_x <= 305 && pixel_y >= 198 && pixel_y <= 213) || // left top dot
                (pixel_x >= 290 && pixel_x <= 305 && pixel_y >= 256 && pixel_y <= 271) || // left bottom dot
                (pixel_x >= 325 && pixel_x <= 339 && pixel_y >= 227 && pixel_y <= 242) || // right middle dot
                (pixel_x >= 340 && pixel_x <= 355 && pixel_y >= 198 && pixel_y <= 227) || // vertical top
                (pixel_x >= 340 && pixel_x <= 355 && pixel_y >= 242 && pixel_y <= 271)    // vertical bottom
            ) begin
                red <= 4'hF;
                green <= 4'hF;
                blue <= 4'hF;
            end
            // Hollow rings (white, manually defined, same style as text)
            // Small ring 1 (10x10, top-left of "3")
            if ((pixel_x == 250 || pixel_x == 259) && pixel_y >= 150 && pixel_y <= 159 ||
                (pixel_y == 150 || pixel_y == 159) && pixel_x >= 250 && pixel_x <= 259) begin
                red <= 4'hF;
                green <= 4'hF;
                blue <= 4'hF;
            end
            // Small ring 2 (10x10, bottom-right of "3")
            if ((pixel_x == 380 || pixel_x == 389) && pixel_y >= 300 && pixel_y <= 309 ||
                (pixel_y == 300 || pixel_y == 309) && pixel_x >= 380 && pixel_x <= 389) begin
                red <= 4'hF;
                green <= 4'hF;
                blue <= 4'hF;
            end
            // Medium ring (16x16, top-right of "3")
            if ((pixel_x == 360 || pixel_x == 375) && pixel_y >= 120 && pixel_y <= 135 ||
                (pixel_y == 120 || pixel_y == 135) && pixel_x >= 360 && pixel_x <= 375) begin
                red <= 4'hF;
                green <= 4'hF;
                blue <= 4'hF;
            end
        end else if (countdown_state == 1) begin // "2" (red text, centered at x=290-349, y=182-287)
            if (
                (pixel_x >= 306 && pixel_x <= 339 && pixel_y >= 182 && pixel_y <= 197) || // top
                (pixel_x >= 290 && pixel_x <= 355 && pixel_y >= 272 && pixel_y <= 287) || // bottom
                (pixel_x >= 290 && pixel_x <= 305 && pixel_y >= 198 && pixel_y <= 213) || // left top dot
                (pixel_x >= 290 && pixel_x <= 305 && pixel_y >= 256 && pixel_y <= 271) || // left bottom dot
                (pixel_x >= 340 && pixel_x <= 355 && pixel_y >= 198 && pixel_y <= 240) || // vertical
                (pixel_x >= 306 && pixel_x <= 339 && pixel_y >= 241 && pixel_y <= 255)   // middle
            ) begin
                red <= 4'hF;
                green <= 4'h0;
                blue <= 4'h0;
            end
            // Hollow rings (red, manually defined, same style as text)
            // Small ring 1 (10x10, top-left of "2")
            if ((pixel_x == 250 || pixel_x == 259) && pixel_y >= 150 && pixel_y <= 159 ||
                (pixel_y == 150 || pixel_y == 159) && pixel_x >= 250 && pixel_x <= 259) begin
                red <= 4'hF;
                green <= 4'h0;
                blue <= 4'h0;
            end
            // Small ring 2 (10x10, bottom-right of "2")
            if ((pixel_x == 380 || pixel_x == 389) && pixel_y >= 300 && pixel_y <= 309 ||
                (pixel_y == 300 || pixel_y == 309) && pixel_x >= 380 && pixel_x <= 389) begin
                red <= 4'hF;
                green <= 4'h0;
                blue <= 4'h0;
            end
            // Medium ring (16x16, bottom-left of "2")
            if ((pixel_x == 240 || pixel_x == 255) && pixel_y >= 320 && pixel_y <= 335 ||
                (pixel_y == 320 || pixel_y == 335) && pixel_x >= 240 && pixel_x <= 255) begin
                red <= 4'hF;
                green <= 4'h0;
                blue <= 4'h0;
            end
        end else if (countdown_state == 2) begin // "1" (white text, centered at x=290-349, y=182-287)
            if (
                (pixel_x >= 313 && pixel_x <= 327 && pixel_y >= 182 && pixel_y <= 271) || // vertical
                (pixel_x >= 290 && pixel_x <= 349 && pixel_y >= 272 && pixel_y <= 287) || // bottom
                (pixel_x >= 300 && pixel_x <= 313 && pixel_y >= 198 && pixel_y <= 213)    // dot
            ) begin
                red <= 4'hF;
                green <= 4'hF;
                blue <= 4'hF;
            end
            // Hollow rings (white, manually defined, same style as text)
            // Small ring 1 (10x10, top-left of "1")
            if ((pixel_x == 250 || pixel_x == 259) && pixel_y >= 150 && pixel_y <= 159 ||
                (pixel_y == 150 || pixel_y == 159) && pixel_x >= 250 && pixel_x <= 259) begin
                red <= 4'hF;
                green <= 4'hF;
                blue <= 4'hF;
            end
            // Medium ring (16x16, top-right of "1")
            if ((pixel_x == 360 || pixel_x == 375) && pixel_y >= 120 && pixel_y <= 135 ||
                (pixel_y == 120 || pixel_y == 135) && pixel_x >= 360 && pixel_x <= 375) begin
                red <= 4'hF;
                green <= 4'hF;
                blue <= 4'hF;
            end
            // Medium ring (16x16, bottom-right of "1")
            if ((pixel_x == 380 || pixel_x == 395) && pixel_y >= 300 && pixel_y <= 315 ||
                (pixel_y == 300 || pixel_y == 315) && pixel_x >= 380 && pixel_x <= 395) begin
                red <= 4'hF;
                green <= 4'hF;
                blue <= 4'hF;
            end
        end else if (countdown_state == 3) begin // "GO" (white text, centered at x=260-379, y=182-287)
            if (
                // G (x=244 to 303, shifted left by 16)
                (pixel_x >= 260 && pixel_x <= 293 && pixel_y >= 182 && pixel_y <= 197) || // top
                (pixel_x >= 260 && pixel_x <= 293 && pixel_y >= 272 && pixel_y <= 287) || // bottom
                (pixel_x >= 249 && pixel_x <= 259 && pixel_y >= 198 && pixel_y <= 271) || // left
                (pixel_x >= 294 && pixel_x <= 303 && pixel_y >= 241 && pixel_y <= 271) || // right bottom
                (pixel_x >= 275 && pixel_x <= 293 && pixel_y >= 241 && pixel_y <= 255) || // middle
                (pixel_x >= 294 && pixel_x <= 303 && pixel_y >= 198 && pixel_y <= 213) || // right top dot
                // O (x=314 to 364, shifted left by 16)
                (pixel_x >= 325 && pixel_x <= 353 && pixel_y >= 182 && pixel_y <= 197) || // top
                (pixel_x >= 325 && pixel_x <= 353 && pixel_y >= 272 && pixel_y <= 287) || // bottom
                (pixel_x >= 314 && pixel_x <= 324 && pixel_y >= 198 && pixel_y <= 271) || // left
                (pixel_x >= 354 && pixel_x <= 364 && pixel_y >= 198 && pixel_y <= 271) || // right
                // ! (x=484 to 494, shifted left by 16)
                (pixel_x >= 386 && pixel_x <= 396 && pixel_y >= 182 && pixel_y <= 261) || // top
                (pixel_x >= 386 && pixel_x <= 396 && pixel_y >= 272 && pixel_y <= 287)
            ) begin
                red <= 4'hF;
                green <= 4'h0;
                blue <= 4'h0;
            end
            // Hollow rings (white, manually defined, same style as text)
            // Small ring 1 (10x10, top-left of "GO")
            if ((pixel_x == 220 || pixel_x == 229) && pixel_y >= 150 && pixel_y <= 159 ||
                (pixel_y == 150 || pixel_y == 159) && pixel_x >= 220 && pixel_x <= 229) begin
                red <= 4'hF;
                green <= 4'h0;
                blue <= 4'h0;
            end
            // Medium ring (16x16, top-right of "GO")
            if ((pixel_x == 400 || pixel_x == 415) && pixel_y >= 120 && pixel_y <= 135 ||
                (pixel_y == 120 || pixel_y == 135) && pixel_x >= 400 && pixel_x <= 415) begin
                red <= 4'hF;
                green <= 4'h0;
                blue <= 4'h0;
            end
            // Small ring 2 (10x10, bottom-right of "GO")
            if ((pixel_x == 400 || pixel_x == 409) && pixel_y >= 300 && pixel_y <= 309 ||
                (pixel_y == 300 || pixel_y == 309) && pixel_x >= 400 && pixel_x <= 409) begin
                red <= 4'hF;
                green <= 4'h0;
                blue <= 4'h0;
            end
        end
    end else begin
        // Video off: Black
        red <= 4'h0;
        green <= 4'h0;
        blue <= 4'h0;
    end
end

endmodule