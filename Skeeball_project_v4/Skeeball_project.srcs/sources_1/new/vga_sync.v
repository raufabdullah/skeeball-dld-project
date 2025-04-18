module vga_sync(
    input [9:0] h_count,
    input [9:0] v_count,
    output h_sync,
    output v_sync,
    output video_on, // active area
    output [9:0] x_loc, // current pixel x- location
    output [9:0] y_loc // current pixel y-location
    );
    // horizontal
    localparam HD = 640;// Horizontal Display Area
    localparam HF = 16;// Horizontal (Front Porch) Right Border
    localparam HB = 48;// Horizontal (Back Porch) Left Border
    localparam HR = 96;// Horizontal Retrace
    // vertical
    localparam VD = 480;// Vertical Display Area
    localparam VF = 20;// Vertical (Front Porch) BottomBorder
    localparam VB = 33;// Vertical (Back Porch)Top Border
    localparam VR = 2;// Vertical Retrace
    
    assign x_loc = h_count;
    assign y_loc = v_count;
    assign h_sync = (h_count < HD + HF) || (h_count >= HD + HF + HR);
    assign v_sync = (v_count < VD + VF)|| (v_count >= VD + VF + VR);
    assign video_on = (h_count < 640) && (v_count < 480);
    
endmodule
