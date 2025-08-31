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
    
    // RGB outputs from start, game, end, and countdown screens
    wire [3:0] red_start, green_start, blue_start;
    wire [3:0] red_game, green_game, blue_game;
    wire [3:0] red_end, green_end, blue_end;
    wire [3:0] red_countdown, green_countdown, blue_countdown;
    
    // Timer and score signals
    wire timer_done;
    wire [16:0] game_score;
    
    reg [16:0] final_score = 0; // Latch final score
    reg timer_done_prev = 0; // Previous state of timer_done for edge detection
    
    // Countdown state machine
    reg [1:0] countdown_state = 0; // 0: "3", 1: "2", 2: "1", 3: "GO"
    reg countdown_active = 0; // 1 during countdown
    reg [24:0] second_counter = 0; // Counter for 1-second intervals
    reg start_prev = 0; // Previous state of start for edge detection
    
    // Latch game_score on the rising edge of timer_done
    always @(posedge clk_d) begin
        timer_done_prev <= timer_done;
        if (timer_done && !timer_done_prev && start) // Detect rising edge of timer_done
            final_score <= game_score; // Capture score at game end
        else if (!start)
            final_score <= 0; // Reset final score when game is not active
    end
    
    // Countdown logic
    always @(posedge clk_d) begin
        start_prev <= start;
        if (start && !start_prev) begin // Start rising edge
            countdown_active <= 1;
            countdown_state <= 0; // Start with "3"
            second_counter <= 0;
        end else if (countdown_active) begin
            if (second_counter == 25_000_000 - 1) begin // 1 second at 25 MHz
                second_counter <= 0;
                if (countdown_state == 0) begin
                    countdown_state <= 1; // "2"
                end else if (countdown_state == 1) begin
                    countdown_state <= 2; // "1"
                end else if (countdown_state == 2) begin
                    countdown_state <= 3; // "GO"
                end else if (countdown_state == 3) begin
                    countdown_active <= 0; // End countdown
                end
            end else begin
                second_counter <= second_counter + 1;
            end
        end else if (!start) begin
            countdown_active <= 0;
            countdown_state <= 0;
            second_counter <= 0;
        end
    end
    
    // Instantiate submodules
    clock_divider clkd(clk, clk_d);
    h_counter hc(clk_d, h_count, trig_v);
    v_counter vc(trig_v, clk_d, v_count);
    vga_sync vgas(h_count, v_count, h_sync, v_sync, video_on, x_loc, y_loc);
    pixel_gen_start_screen_hs pg_ss(clk_d, x_loc, y_loc, video_on, red_start, green_start, blue_start);
    pixel_gen_game_screen pg_gs(clk_d, x_loc, y_loc, video_on, !start || countdown_active, S1, S2, S3, 
        red_game, green_game, blue_game, timer_done, game_score);
    pixel_gen_endscreen pg_es(clk_d, x_loc, y_loc, video_on, final_score, red_end, green_end, blue_end);
    pixel_gen_countdown pg_cd(clk_d, x_loc, y_loc, video_on, countdown_state, red_countdown, green_countdown, blue_countdown);
    
    // Select RGB outputs based on start, countdown, and timer_done
    assign red = (start && timer_done) ? red_end : 
                 (start && countdown_active) ? red_countdown : 
                 (start ? red_game : red_start);
    assign green = (start && timer_done) ? green_end : 
                   (start && countdown_active) ? green_countdown : 
                   (start ? green_game : green_start);
    assign blue = (start && timer_done) ? blue_end : 
                  (start && countdown_active) ? blue_countdown : 
                  (start ? blue_game : blue_start);
    
endmodule