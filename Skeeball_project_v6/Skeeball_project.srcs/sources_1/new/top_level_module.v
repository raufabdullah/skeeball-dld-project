`timescale 1ns / 1ps

module Top_Level_Module(
    input clk, 
    input start,
    input S1, S2, S3, // Score increment inputs
    output h_sync, 
    output v_sync, 
    output [3:0] red, 
    output [3:0] green, 
    output [3:0] blue
); 
    wire clk_d; 
    wire trig_v; 
    wire video_on;
    wire [9:0] h_count;
    wire [9:0] v_count; 
    wire [9:0] x_loc; 
    wire [9:0] y_loc;
    
    // RGB outputs from start, game, and end screen pixel generators
    wire [3:0] red_start, green_start, blue_start;
    wire [3:0] red_game, green_game, blue_game;
    wire [3:0] red_end, green_end, blue_end;
    
    // Timer done signal
    wire timer_done;
    wire [16:0] game_score;
    
    reg [16:0] final_score = 0; // Latch final score
    reg timer_done_prev = 0; // Previous state of timer_done for edge detection   // Latch game_score when timer_done asserts
    
    // Latch game_score on the rising edge of timer_done
    always @(posedge clk_d) begin
        timer_done_prev <= timer_done;
        if (timer_done && !timer_done_prev && start) // Detect rising edge of timer_done
            final_score <= game_score; // Capture score at game end
        else if (!start)
            final_score <= 0; // Reset final score when game is not active
    end
    
    // Instantiate submodules
    clock_divider clkd(clk, clk_d);
    h_counter hc(clk_d, h_count, trig_v);
    v_counter vc(trig_v, clk_d, v_count);
    vga_sync vgas(h_count, v_count, h_sync, v_sync, video_on, x_loc, y_loc);
    pixel_gen_start_screen_hs pg_ss(clk_d, x_loc, y_loc, video_on, red_start, green_start, blue_start);
    pixel_gen_game_screen pg_gs(clk_d, x_loc, y_loc, video_on, !start, S1, S2, S3, 
    red_game, green_game, blue_game, timer_done, game_score);
    pixel_gen_endscreen pg_es(clk_d, x_loc, y_loc, video_on, final_score, red_end, green_end, blue_end);
    
    
    // Select RGB outputs based on start and timer_done
    assign red = (start && timer_done) ? red_end : (start ? red_game : red_start);
    assign green = (start && timer_done) ? green_end : (start ? green_game : green_start);
    assign blue = (start && timer_done) ? blue_end : (start ? blue_game : blue_start);    
endmodule