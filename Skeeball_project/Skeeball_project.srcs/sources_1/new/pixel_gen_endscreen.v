module pixel_gen_endscreen(
    input clk_d, // pixel clock
    input [9:0] pixel_x,
    input [9:0] pixel_y,
    input video_on,
    output reg [3:0] red = 0,
    output reg [3:0] green = 0,
    output reg [3:0] blue = 0
);
// Display "SKEEBALL" at top middle, starting at y=50
// Each letter is now 10x14 pixels, with 2-pixel spacing
// Total width: 8 letters * 10 + 7 gaps * 2 = 94 pixels
// Center at x=320 (640/2), so x ranges from 273 to 367

// Display "SCORE" and "HIGHEST MULTIPLIER" aligned left at x=50
// "SCORE" at y=150, "HIGHEST MULTIPLIER" at y=250
// "SCORE" width: 5 letters * 10 + 4 gaps * 2 = 58 pixels
// "HIGHEST MULTIPLIER" width: 16 chars * 10 + 15 gaps * 2 = 190 pixels

always @(posedge clk_d)
begin
    if (video_on &&
        (
        // SKEEBALL at y=50 to 78, x=273 to 367
        // S (x=273 to 282, y=50 to 78)
        (pixel_x >= 273 && pixel_x <= 282 && pixel_y >= 50 && pixel_y <= 53) || // top (4 pixels thick)
        (pixel_x >= 273 && pixel_x <= 276 && pixel_y >= 50 && pixel_y <= 60) || // left upper (4 pixels wide)
        (pixel_x >= 273 && pixel_x <= 282 && pixel_y >= 58 && pixel_y <= 61) || // middle
        (pixel_x >= 279 && pixel_x <= 282 && pixel_y >= 62 && pixel_y <= 78) || // right lower
        (pixel_x >= 273 && pixel_x <= 282 && pixel_y >= 75 && pixel_y <= 78) || // bottom

        // K (x=285 to 294, y=50 to 78)
        (pixel_x >= 285 && pixel_x <= 288 && pixel_y >= 50 && pixel_y <= 78) || // vertical
        (pixel_x >= 289 && pixel_x <= 294 && pixel_y >= 58 && pixel_y <= 61) || // middle cross
        (pixel_x >= 291 && pixel_x <= 294 && pixel_y >= 50 && pixel_y <= 60) || // upper diagonal
        (pixel_x >= 291 && pixel_x <= 294 && pixel_y >= 62 && pixel_y <= 78) || // lower diagonal

        // E (x=297 to 306, y=50 to 78)
        (pixel_x >= 297 && pixel_x <= 306 && pixel_y >= 50 && pixel_y <= 53) || // top
        (pixel_x >= 297 && pixel_x <= 300 && pixel_y >= 50 && pixel_y <= 78) || // left
        (pixel_x >= 297 && pixel_x <= 306 && pixel_y >= 58 && pixel_y <= 61) || // middle
        (pixel_x >= 297 && pixel_x <= 306 && pixel_y >= 75 && pixel_y <= 78) || // bottom

        // E (x=309 to 318, y=50 to 78)
        (pixel_x >= 309 && pixel_x <= 318 && pixel_y >= 50 && pixel_y <= 53) ||
        (pixel_x >= 309 && pixel_x <= 312 && pixel_y >= 50 && pixel_y <= 78) ||
        (pixel_x >= 309 && pixel_x <= 318 && pixel_y >= 58 && pixel_y <= 61) ||
        (pixel_x >= 309 && pixel_x <= 318 && pixel_y >= 75 && pixel_y <= 78) ||

        // B (x=321 to 330, y=50 to 78)
        (pixel_x >= 321 && pixel_x <= 330 && pixel_y >= 50 && pixel_y <= 53) || // top
        (pixel_x >= 321 && pixel_x <= 324 && pixel_y >= 50 && pixel_y <= 78) || // left
        (pixel_x >= 327 && pixel_x <= 330 && pixel_y >= 50 && pixel_y <= 60) || // upper right
        (pixel_x >= 321 && pixel_x <= 330 && pixel_y >= 58 && pixel_y <= 61) || // middle
        (pixel_x >= 327 && pixel_x <= 330 && pixel_y >= 62 && pixel_y <= 78) || // lower right
        (pixel_x >= 321 && pixel_x <= 330 && pixel_y >= 75 && pixel_y <= 78) || // bottom

        // A (x=333 to 342, y=50 to 78)
        (pixel_x >= 333 && pixel_x <= 342 && pixel_y >= 50 && pixel_y <= 53) || // top
        (pixel_x >= 333 && pixel_x <= 336 && pixel_y >= 50 && pixel_y <= 78) || // left
        (pixel_x >= 339 && pixel_x <= 342 && pixel_y >= 50 && pixel_y <= 78) || // right
        (pixel_x >= 333 && pixel_x <= 342 && pixel_y >= 58 && pixel_y <= 61) || // middle

        // L (x=345 to 354, y=50 to 78)
        (pixel_x >= 345 && pixel_x <= 348 && pixel_y >= 50 && pixel_y <= 78) || // vertical
        (pixel_x >= 345 && pixel_x <= 354 && pixel_y >= 75 && pixel_y <= 78) || // bottom

        // L (x=357 to 366, y=50 to 78)
        (pixel_x >= 357 && pixel_x <= 360 && pixel_y >= 50 && pixel_y <= 78) ||
        (pixel_x >= 357 && pixel_x <= 366 && pixel_y >= 75 && pixel_y <= 78) ||

        // SCORE at y=150 to 178, x=50 to 108
        // S (x=50 to 59, y=150 to 178)
        (pixel_x >= 50 && pixel_x <= 59 && pixel_y >= 150 && pixel_y <= 153) ||
        (pixel_x >= 50 && pixel_x <= 53 && pixel_y >= 150 && pixel_y <= 160) ||
        (pixel_x >= 50 && pixel_x <= 59 && pixel_y >= 158 && pixel_y <= 161) ||
        (pixel_x >= 56 && pixel_x <= 59 && pixel_y >= 162 && pixel_y <= 178) ||
        (pixel_x >= 50 && pixel_x <= 59 && pixel_y >= 175 && pixel_y <= 178) ||

        // C (x=62 to 71, y=150 to 178)
        (pixel_x >= 62 && pixel_x <= 71 && pixel_y >= 150 && pixel_y <= 153) ||
        (pixel_x >= 62 && pixel_x <= 65 && pixel_y >= 150 && pixel_y <= 178) ||
        (pixel_x >= 62 && pixel_x <= 71 && pixel_y >= 175 && pixel_y <= 178) ||

        // O (x=74 to 83, y=150 to 178)
        (pixel_x >= 74 && pixel_x <= 83 && pixel_y >= 150 && pixel_y <= 153) ||
        (pixel_x >= 74 && pixel_x <= 77 && pixel_y >= 150 && pixel_y <= 178) ||
        (pixel_x >= 80 && pixel_x <= 83 && pixel_y >= 150 && pixel_y <= 178) ||
        (pixel_x >= 74 && pixel_x <= 83 && pixel_y >= 175 && pixel_y <= 178) ||

        // R (x=86 to 95, y=150 to 178)
        (pixel_x >= 86 && pixel_x <= 95 && pixel_y >= 150 && pixel_y <= 153) ||
        (pixel_x >= 86 && pixel_x <= 89 && pixel_y >= 150 && pixel_y <= 178) ||
        (pixel_x >= 92 && pixel_x <= 95 && pixel_y >= 150 && pixel_y <= 161) ||
        (pixel_x >= 86 && pixel_x <= 95 && pixel_y >= 158 && pixel_y <= 161) ||
        (pixel_x >= 92 && pixel_x <= 95 && pixel_y >= 162 && pixel_y <= 178) ||

        // E (x=98 to 107, y=150 to 178)
        (pixel_x >= 98 && pixel_x <= 107 && pixel_y >= 150 && pixel_y <= 153) ||
        (pixel_x >= 98 && pixel_x <= 101 && pixel_y >= 150 && pixel_y <= 178) ||
        (pixel_x >= 98 && pixel_x <= 107 && pixel_y >= 158 && pixel_y <= 161) ||
        (pixel_x >= 98 && pixel_x <= 107 && pixel_y >= 175 && pixel_y <= 178) ||

        // HIGHEST MULTIPLIER at y=250 to 278, x=50 to 240
        // H (x=50 to 59, y=250 to 278)
        (pixel_x >= 50 && pixel_x <= 53 && pixel_y >= 250 && pixel_y <= 278) ||
        (pixel_x >= 56 && pixel_x <= 59 && pixel_y >= 250 && pixel_y <= 278) ||
        (pixel_x >= 50 && pixel_x <= 59 && pixel_y >= 258 && pixel_y <= 261) ||

        // I (x=62 to 71, y=250 to 278)
        (pixel_x >= 62 && pixel_x <= 71 && pixel_y >= 250 && pixel_y <= 253) ||
        (pixel_x >= 66 && pixel_x <= 69 && pixel_y >= 250 && pixel_y <= 278) ||
        (pixel_x >= 62 && pixel_x <= 71 && pixel_y >= 275 && pixel_y <= 278) ||

        // G (x=74 to 83, y=250 to 278)
        (pixel_x >= 74 && pixel_x <= 83 && pixel_y >= 250 && pixel_y <= 253) ||
        (pixel_x >= 74 && pixel_x <= 77 && pixel_y >= 250 && pixel_y <= 278) ||
        (pixel_x >= 80 && pixel_x <= 83 && pixel_y >= 258 && pixel_y <= 278) ||
        (pixel_x >= 74 && pixel_x <= 83 && pixel_y >= 275 && pixel_y <= 278) ||
        (pixel_x >= 80 && pixel_x <= 83 && pixel_y >= 258 && pixel_y <= 261) ||

        // H (x=86 to 95, y=250 to 278)
        (pixel_x >= 86 && pixel_x <= 89 && pixel_y >= 250 && pixel_y <= 278) ||
        (pixel_x >= 92 && pixel_x <= 95 && pixel_y >= 250 && pixel_y <= 278) ||
        (pixel_x >= 86 && pixel_x <= 95 && pixel_y >= 258 && pixel_y <= 261) ||

        // E (x=98 to 107, y=250 to 278)
        (pixel_x >= 98 && pixel_x <= 107 && pixel_y >= 250 && pixel_y <= 253) ||
        (pixel_x >= 98 && pixel_x <= 101 && pixel_y >= 250 && pixel_y <= 278) ||
        (pixel_x >= 98 && pixel_x <= 107 && pixel_y >= 258 && pixel_y <= 261) ||
        (pixel_x >= 98 && pixel_x <= 107 && pixel_y >= 275 && pixel_y <= 278) ||

        // S (x=110 to 119, y=250 to 278)
        (pixel_x >= 110 && pixel_x <= 119 && pixel_y >= 250 && pixel_y <= 253) ||
        (pixel_x >= 110 && pixel_x <= 113 && pixel_y >= 250 && pixel_y <= 260) ||
        (pixel_x >= 110 && pixel_x <= 119 && pixel_y >= 258 && pixel_y <= 261) ||
        (pixel_x >= 116 && pixel_x <= 119 && pixel_y >= 262 && pixel_y <= 278) ||
        (pixel_x >= 110 && pixel_x <= 119 && pixel_y >= 275 && pixel_y <= 278) ||

        // T (x=122 to 131, y=250 to 278)
        (pixel_x >= 122 && pixel_x <= 131 && pixel_y >= 250 && pixel_y <= 253) ||
        (pixel_x >= 126 && pixel_x <= 129 && pixel_y >= 250 && pixel_y <= 278) ||

        // Space (x=134 to 143)

        // M (x=146 to 155, y=250 to 278)
        (pixel_x >= 146 && pixel_x <= 149 && pixel_y >= 250 && pixel_y <= 278) ||
        (pixel_x >= 152 && pixel_x <= 155 && pixel_y >= 250 && pixel_y <= 278) ||
        (pixel_x >= 146 && pixel_x <= 155 && pixel_y >= 250 && pixel_y <= 253) ||
        (pixel_x >= 150 && pixel_x <= 151 && pixel_y >= 250 && pixel_y <= 260) ||

        // U (x=158 to 167, y=250 to 278)
        (pixel_x >= 158 && pixel_x <= 161 && pixel_y >= 250 && pixel_y <= 278) ||
        (pixel_x >= 164 && pixel_x <= 167 && pixel_y >= 250 && pixel_y <= 278) ||
        (pixel_x >= 158 && pixel_x <= 167 && pixel_y >= 275 && pixel_y <= 278) ||

        // L (x=170 to 179, y=250 to 278)
        (pixel_x >= 170 && pixel_x <= 173 && pixel_y >= 250 && pixel_y <= 278) ||
        (pixel_x >= 170 && pixel_x <= 179 && pixel_y >= 275 && pixel_y <= 278) ||

        // T (x=182 to 191, y=250 to 278)
        (pixel_x >= 182 && pixel_x <= 191 && pixel_y >= 250 && pixel_y <= 253) ||
        (pixel_x >= 186 && pixel_x <= 189 && pixel_y >= 250 && pixel_y <= 278) ||

        // I (x=194 to 203, y=250 to 278)
        (pixel_x >= 194 && pixel_x <= 203 && pixel_y >= 250 && pixel_y <= 253) ||
        (pixel_x >= 198 && pixel_x <= 201 && pixel_y >= 250 && pixel_y <= 278) ||
        (pixel_x >= 194 && pixel_x <= 203 && pixel_y >= 275 && pixel_y <= 278) ||

        // P (x=206 to 215, y=250 to 278)
        (pixel_x >= 206 && pixel_x <= 215 && pixel_y >= 250 && pixel_y <= 253) ||
        (pixel_x >= 206 && pixel_x <= 209 && pixel_y >= 250 && pixel_y <= 278) ||
        (pixel_x >= 212 && pixel_x <= 215 && pixel_y >= 250 && pixel_y <= 261) ||
        (pixel_x >= 206 && pixel_x <= 215 && pixel_y >= 258 && pixel_y <= 261) ||

        // L (x=218 to 227, y=250 to 278)
        (pixel_x >= 218 && pixel_x <= 221 && pixel_y >= 250 && pixel_y <= 278) ||
        (pixel_x >= 218 && pixel_x <= 227 && pixel_y >= 275 && pixel_y <= 278) ||

        // I (x=230 to 239, y=250 to 278)
        (pixel_x >= 230 && pixel_x <= 239 && pixel_y >= 250 && pixel_y <= 253) ||
        (pixel_x >= 234 && pixel_x <= 237 && pixel_y >= 250 && pixel_y <= 278) ||
        (pixel_x >= 230 && pixel_x <= 239 && pixel_y >= 275 && pixel_y <= 278) ||

        // E (x=246 to 255, y=250 to 278)
        (pixel_x >= 246 && pixel_x <= 255 && pixel_y >= 250 && pixel_y <= 253) ||
        (pixel_x >= 246 && pixel_x <= 249 && pixel_y >= 250 && pixel_y <= 278) ||
        (pixel_x >= 246 && pixel_x <= 255 && pixel_y >= 258 && pixel_y <= 261) ||
        (pixel_x >= 246 && pixel_x <= 255 && pixel_y >= 275 && pixel_y <= 278) ||

        // R (x=258 to 267, y=250 to 278)
        (pixel_x >= 258 && pixel_x <= 267 && pixel_y >= 250 && pixel_y <= 253) ||
        (pixel_x >= 258 && pixel_x <= 261 && pixel_y >= 250 && pixel_y <= 278) ||
        (pixel_x >= 264 && pixel_x <= 267 && pixel_y >= 250 && pixel_y <= 261) ||
        (pixel_x >= 258 && pixel_x <= 267 && pixel_y >= 258 && pixel_y <= 261) ||
        (pixel_x >= 264 && pixel_x <= 267 && pixel_y >= 262 && pixel_y <= 278)
        ))
    begin
        red <= 4'hF;   // White text
        green <= 4'hF;
        blue <= 4'hF;
    end
    else
    begin
        red <= 4'h0;   // Black background
        green <= 4'h0;
        blue <= 4'h0;
    end
end
endmodule