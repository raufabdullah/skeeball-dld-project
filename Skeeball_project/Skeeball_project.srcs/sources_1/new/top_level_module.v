`timescale 1ns / 1ps

module Top_Level_Module(
    input clk, 
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
    clock_divider clkd(clk, clk_d); 
    h_counter hc(clk_d, h_count, trig_v); 
    v_counter vc(trig_v, clk_d, v_count); 
    vga_sync vgas(h_count, v_count, h_sync, v_sync, video_on, x_loc, y_loc); 
    pixel_gen_endscreen pg(clk_d, x_loc, y_loc, video_on, red, green, blue);
endmodule
