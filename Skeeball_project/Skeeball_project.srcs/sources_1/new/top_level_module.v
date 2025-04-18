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
    
    // Instantiate submodules
    clock_divider clkd(clk, clk_d);
    h_counter hc(clk_d, h_count, trig_v);
    v_counter vc(trig_v, clk_d, v_count);
    vga_sync vgas(h_count, v_count, h_sync, v_sync, video_on, x_loc, y_loc);
    pixel_gen_start_screen pg_ss(clk_d, x_loc, y_loc, video_on, red_start, green_start, blue_start);
    pixel_gen_game_screen pg_gs(clk_d, x_loc, y_loc, video_on, red_game, green_game, blue_game);
    pixel_gen_endscreen pg_es(clk_d, x_loc, y_loc, video_on, red_end, green_end, blue_end);
    
    // Select RGB outputs based on start and timer_done
    assign red = (start == 0) ? red_start : (timer_done ? red_end : red_game);
    assign green = (start == 0) ? green_start : (timer_done ? green_end : green_game);
    assign blue = (start == 0) ? blue_start : (timer_done ? blue_end : blue_game);
    
endmodule