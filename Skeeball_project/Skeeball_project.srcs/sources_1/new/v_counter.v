`timescale 1ns / 1ps

module v_counter(
    input enable_v,
    input clk,
    output reg [9:0] v_count
    );
    //reg [9:0] v_count;
    initial v_count = 0;
    always @ (posedge clk) begin
        if (enable_v == 1 && v_count < 524) begin
            v_count <= v_count + 1;
        end
        else if (enable_v ==1) begin
            v_count <= 0;
        end
    end
endmodule
